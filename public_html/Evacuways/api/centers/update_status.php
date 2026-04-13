<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// PUT update_status.php - Update center status
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['center_id']) || !isset($data['status'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Center ID and status are required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $center_id = $data['center_id'];
    $status = htmlspecialchars($data['status']);
    
    $query = "UPDATE evacuways_centers SET status = :status WHERE center_id = :center_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':center_id', $center_id);
    $stmt->bindParam(':status', $status);
    
    if($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["success" => true, "message" => "Status updated"]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to update status"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
