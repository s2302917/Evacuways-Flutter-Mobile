<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// PUT update_occupancy.php - Update center occupancy
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['center_id']) || !isset($data['current_occupancy'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Center ID and occupancy are required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $center_id = $data['center_id'];
    $current_occupancy = intval($data['current_occupancy']);
    
    $query = "UPDATE evacuways_centers SET current_individuals = :occupancy WHERE center_id = :center_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':center_id', $center_id);
    $stmt->bindParam(':occupancy', $current_occupancy);
    
    if($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["success" => true, "message" => "Occupancy updated"]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to update occupancy"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
