<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// Get JSON input
$data = json_decode(file_get_contents("php://input"));

// Map credentials from input
$contact_number = isset($data->contact_number) ? htmlspecialchars(strip_tags($data->contact_number)) : null;
$password_input = isset($data->password) ? htmlspecialchars(strip_tags($data->password)) : null;

// Basic validation
if(empty($contact_number) || empty($password_input)){
    http_response_code(400); // Bad request
    echo json_encode(["success" => false, "message" => "Contact number and password are required."]);
    exit();
}

try {
    // Instantiate the Database class provided by the user
    $database = new Database();
    $conn = $database->connect();
    
    if ($conn === null) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database connection failed! Check your database.php credentials."]);
        exit();
    }
    
    // Note: The example data shows passwords stored as plain text "123". 
    // In production, these should be securely hashed (e.g., password_hash/password_verify).
    // The query below searches for the user using the exact text match since the DB has plain text passwords currently.
    // Normalize contact number for lookup
    $clean_number = ltrim($contact_number, '+'); // remove leading +
    if (substr($clean_number, 0, 2) === '63') {
        $base_number = substr($clean_number, 2); // get part after 63
    } elseif (substr($clean_number, 0, 1) === '0') {
        $base_number = substr($clean_number, 1); // get part after 0
    } else {
        $base_number = $clean_number;
    }
    
    $format1 = '0' . $base_number;
    $format2 = '+63' . $base_number;
    $format3 = '63' . $base_number;

    $query = "SELECT * FROM evacuways_users WHERE (contact_number = :f1 OR contact_number = :f2 OR contact_number = :f3) LIMIT 1";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(":f1", $format1);
    $stmt->bindParam(":f2", $format2);
    $stmt->bindParam(":f3", $format3);
    $stmt->execute();
    
    if($stmt->rowCount() > 0) {
        $user = $stmt->fetch();
        
        // Support both hashed and plain text passwords (for legacy support during migration)
        $is_valid = false;
        
        // Check for password_hash first (new standard)
        if (!empty($user['password_hash'])) {
            if (password_verify($password_input, $user['password_hash'])) {
                $is_valid = true;
            } elseif ($password_input === $user['password_hash']) {
                $is_valid = true;
            }
        } 
        // Fallback for older code that might still have it in "password" (though we renamed it in SQL)
        elseif (!empty($user['password'])) {
            if (password_verify($password_input, $user['password'])) {
                $is_valid = true;
            } elseif ($password_input === $user['password']) {
                $is_valid = true;
            }
        }

        if ($is_valid) {
            // Remove sensitive data from JSON response
            unset($user['password_hash']);
            unset($user['password']);

            // Success response
            http_response_code(200);
            echo json_encode([
                "success" => true,
                "message" => "Login successful",
                "user" => $user
            ]);
            exit();
        } else {
            http_response_code(401);
            echo json_encode(["success" => false, "message" => "Invalid contact number or password."]);
        }
    } else {
        // User not found
        http_response_code(401); // Unauthorized
        echo json_encode(["success" => false, "message" => "Invalid contact number."]);
    }

} catch(PDOException $e) {
    // Database error
    http_response_code(500); // Server error
    echo json_encode(["success" => false, "message" => "System error. Please try again later."]);
}
?>
