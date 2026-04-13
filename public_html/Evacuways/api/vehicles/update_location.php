<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// PUT update_location.php - Update vehicle location
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['vehicle_id']) || !isset($data['latitude']) || !isset($data['longitude'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Vehicle ID, latitude, and longitude are required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $vehicle_id = $data['vehicle_id'];
    $latitude = floatval($data['latitude']);
    $longitude = floatval($data['longitude']);
    
    $query = "UPDATE evacuways_vehicles SET latitude = :latitude, longitude = :longitude WHERE vehicle_id = :vehicle_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':vehicle_id', $vehicle_id);
    $stmt->bindParam(':latitude', $latitude);
    $stmt->bindParam(':longitude', $longitude);
    
    if($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["success" => true, "message" => "Location updated"]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to update location"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
