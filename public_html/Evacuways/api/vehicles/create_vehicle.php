<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// POST create_vehicle.php - Create new vehicle
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['vehicle_type']) || !isset($data['plate_number'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Vehicle type and plate number are required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $vehicle_type = $data['vehicle_type'];
    $plate_number = $data['plate_number'];
    $capacity = $data['capacity'] ?? null;
    $status = $data['status'] ?? 'Standby';
    $driver_name = $data['driver_name'] ?? null;
    $driver_contact = $data['driver_contact'] ?? null;
    $barangay_name = $data['barangay_name'] ?? null;
    $landmark = $data['landmark'] ?? null;
    $latitude = $data['latitude'] ?? null;
    $longitude = $data['longitude'] ?? null;
    
    $query = "INSERT INTO evacuways_vehicles 
              (vehicle_type, plate_number, capacity, status, driver_name, driver_contact, 
               barangay_name, landmark, latitude, longitude, created_at) 
              VALUES (:vehicle_type, :plate_number, :capacity, :status, :driver_name, 
                      :driver_contact, :barangay_name, :landmark, :latitude, :longitude, NOW())";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':vehicle_type', $vehicle_type);
    $stmt->bindParam(':plate_number', $plate_number);
    $stmt->bindParam(':capacity', $capacity);
    $stmt->bindParam(':status', $status);
    $stmt->bindParam(':driver_name', $driver_name);
    $stmt->bindParam(':driver_contact', $driver_contact);
    $stmt->bindParam(':barangay_name', $barangay_name);
    $stmt->bindParam(':landmark', $landmark);
    $stmt->bindParam(':latitude', $latitude);
    $stmt->bindParam(':longitude', $longitude);
    
    if($stmt->execute()) {
        $vehicle_id = $conn->lastInsertId();
        http_response_code(201);
        echo json_encode(["success" => true, "message" => "Vehicle created", "vehicle_id" => $vehicle_id]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to create vehicle"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
