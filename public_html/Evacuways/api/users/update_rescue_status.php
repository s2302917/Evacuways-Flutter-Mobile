<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// PUT update_rescue_status.php - Update user rescue status
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['user_id']) || !isset($data['rescue_status'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "User ID and rescue status are required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $user_id = $data['user_id'];
    $rescue_status = $data['rescue_status'];
    
    $query = "UPDATE evacuways_users SET rescue_status = :rescue_status WHERE user_id = :user_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->bindParam(':rescue_status', $rescue_status);
    
    if($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["success" => true, "message" => "Rescue status updated"]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to update status"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
