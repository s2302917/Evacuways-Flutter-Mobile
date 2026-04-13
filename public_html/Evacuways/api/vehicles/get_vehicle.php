<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_vehicle.php - Get vehicle details
$vehicle_id = isset($_GET['vehicle_id']) ? intval($_GET['vehicle_id']) : null;

if(!$vehicle_id) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Vehicle ID is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_vehicles WHERE vehicle_id = :vehicle_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':vehicle_id', $vehicle_id);
    $stmt->execute();
    
    if($stmt->rowCount() > 0) {
        $vehicle = $stmt->fetch(PDO::FETCH_ASSOC);
        http_response_code(200);
        echo json_encode($vehicle);
    } else {
        http_response_code(404);
        echo json_encode(["success" => false, "message" => "Vehicle not found"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
