<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// PUT update_admin_profile.php - Update admin profile
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['admin_id'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Admin ID is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $admin_id = intval($data['admin_id']);
    $first_name = $data['first_name'] ?? null;
    $last_name = $data['last_name'] ?? null;
    $contact_number = $data['contact_number'] ?? null;
    $email = $data['email'] ?? null;
    
    $query = "UPDATE evacuways_admins SET ";
    $updates = [];
    
    if($first_name) {
        $updates[] = "first_name = :first_name";
    }
    if($last_name) {
        $updates[] = "last_name = :last_name";
    }
    if($contact_number) {
        $updates[] = "contact_number = :contact_number";
    }
    if($email) {
        $updates[] = "email = :email";
    }
    
    if(empty($updates)) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "No fields to update"]);
        exit();
    }
    
    $query .= implode(", ", $updates) . " WHERE admin_id = :admin_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':admin_id', $admin_id);
    
    if($first_name) {
        $stmt->bindParam(':first_name', $first_name);
    }
    if($last_name) {
        $stmt->bindParam(':last_name', $last_name);
    }
    if($contact_number) {
        $stmt->bindParam(':contact_number', $contact_number);
    }
    if($email) {
        $stmt->bindParam(':email', $email);
    }
    
    if($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["success" => true, "message" => "Admin profile updated"]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to update profile"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
