<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if(empty($data->first_name) || empty($data->last_name) || empty($data->contact_number) || empty($data->password)){
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Required fields are missing."]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    if ($conn === null) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database connection failed!"]);
        exit();
    }

    // Normalize contact number for lookup
    $clean_number = ltrim($data->contact_number, '+');
    if (substr($clean_number, 0, 2) === '63') {
        $base_number = substr($clean_number, 2);
    } elseif (substr($clean_number, 0, 1) === '0') {
        $base_number = substr($clean_number, 1);
    } else {
        $base_number = $clean_number;
    }
    
    $f1 = '0' . $base_number;
    $f2 = '+63' . $base_number;
    $f3 = '63' . $base_number;

    // Check if contact number is already registered
    $check_query = "SELECT user_id FROM evacuways_users WHERE contact_number = :f1 OR contact_number = :f2 OR contact_number = :f3 LIMIT 1";
    $check_stmt = $conn->prepare($check_query);
    $check_stmt->bindParam(":f1", $f1);
    $check_stmt->bindParam(":f2", $f2);
    $check_stmt->bindParam(":f3", $f3);
    $check_stmt->execute();

    if ($check_stmt->rowCount() > 0) {
        http_response_code(409); // Conflict
        echo json_encode(["success" => false, "message" => "Contact number already registered."]);
        exit();
    }

    $query = "INSERT INTO evacuways_users (
                first_name, last_name, role, password_hash, gender, birth_date,
                contact_number, region_code, city_code, barangay_code, 
                latitude, longitude, created_at
              ) VALUES (
                :first_name, :last_name, :role, :password, :gender, :birth_date,
                :contact_number, :region_code, :city_code, :barangay_code,
                :latitude, :longitude, CURRENT_TIMESTAMP
              )";

    $stmt = $conn->prepare($query);
    
    // Binding parameters safely
    $first_name = htmlspecialchars(strip_tags($data->first_name));
    $last_name = htmlspecialchars(strip_tags($data->last_name));
    $role = !empty($data->role) ? htmlspecialchars(strip_tags($data->role)) : 'user';
    $raw_password = trim((string)($data->password ?? ''));
    $password = password_hash($raw_password, PASSWORD_DEFAULT);
    $contact_number = htmlspecialchars(strip_tags($data->contact_number));

    $stmt->bindParam(":first_name", $first_name);
    $stmt->bindParam(":last_name", $last_name);
    $stmt->bindParam(":role", $role);
    $stmt->bindParam(":password", $password);
    $stmt->bindParam(":gender", $data->gender);
    $stmt->bindParam(":birth_date", $data->birth_date);
    $stmt->bindParam(":contact_number", $contact_number);
    
    $stmt->bindParam(":region_code", $data->region_code);
    $stmt->bindParam(":city_code", $data->city_code);
    $stmt->bindParam(":barangay_code", $data->barangay_code);
    
    $stmt->bindParam(":latitude", $data->latitude);
    $stmt->bindParam(":longitude", $data->longitude);

    if($stmt->execute()) {
        $user_id = $conn->lastInsertId();
        
        // Fetch new user to return it
        $fetch_stmt = $conn->prepare("SELECT * FROM evacuways_users WHERE user_id = :id");
        $fetch_stmt->bindParam(":id", $user_id);
        $fetch_stmt->execute();
        $user = $fetch_stmt->fetch();
        unset($user['password']);

        http_response_code(201); // Created
        echo json_encode(["success" => true, "message" => "User registered successfully.", "user" => $user]);
    } else {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Unable to register user."]);
    }

} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "System error. " . $e->getMessage()]);
}
?>
