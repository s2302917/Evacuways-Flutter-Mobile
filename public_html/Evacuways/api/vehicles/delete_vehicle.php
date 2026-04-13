<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// DELETE delete_vehicle.php - Delete vehicle
$vehicle_id = isset($_GET['vehicle_id']) ? intval($_GET['vehicle_id']) : null;

if(!$vehicle_id) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Vehicle ID is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "DELETE FROM evacuways_vehicles WHERE vehicle_id = :vehicle_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':vehicle_id', $vehicle_id);
    
    if($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["success" => true, "message" => "Vehicle deleted"]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to delete vehicle"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
