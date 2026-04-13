<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// PUT update_status.php - Update vehicle status
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['vehicle_id']) || !isset($data['status'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Vehicle ID and status are required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $vehicle_id = $data['vehicle_id'];
    $status = $data['status'];
    
    $query = "UPDATE evacuways_vehicles SET status = :status WHERE vehicle_id = :vehicle_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':vehicle_id', $vehicle_id);
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
