<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// POST create_center.php - Create new evacuation center
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['center_name']) || !isset($data['barangay_name'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Center name and barangay name are required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $center_name = strip_tags($data['center_name']);
    $barangay_name = strip_tags($data['barangay_name']);
    $address = $data['address'] ?? null;
    $latitude = $data['latitude'] ?? null;
    $longitude = $data['longitude'] ?? null;
    $max_capacity = $data['max_capacity'] ?? null;
    $current_individuals = $data['current_individuals'] ?? 0;
    $status = $data['status'] ?? 'Available';
    $barangay_code = $data['barangay_code'] ?? null;
    $city_code = $data['city_code'] ?? null;
    $region_code = $data['region_code'] ?? null;
    $facility_type = $data['facility_type'] ?? null;
    
    $query = "INSERT INTO evacuways_centers 
              (center_name, barangay_name, address, latitude, longitude, max_capacity, 
               current_individuals, status, barangay_code, city_code, region_code, facility_type, created_at) 
              VALUES (:center_name, :barangay_name, :address, :latitude, :longitude, :max_capacity, 
                      :current_individuals, :status, :barangay_code, :city_code, :region_code, :facility_type, NOW())";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':center_name', $center_name);
    $stmt->bindParam(':barangay_name', $barangay_name);
    $stmt->bindParam(':address', $address);
    $stmt->bindParam(':latitude', $latitude);
    $stmt->bindParam(':longitude', $longitude);
    $stmt->bindParam(':max_capacity', $max_capacity);
    $stmt->bindParam(':current_individuals', $current_individuals);
    $stmt->bindParam(':status', $status);
    $stmt->bindParam(':barangay_code', $barangay_code);
    $stmt->bindParam(':city_code', $city_code);
    $stmt->bindParam(':region_code', $region_code);
    $stmt->bindParam(':facility_type', $facility_type);
    
    if($stmt->execute()) {
        $center_id = $conn->lastInsertId();
        http_response_code(201);
        echo json_encode(["success" => true, "message" => "Center created", "center_id" => $center_id]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to create center"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
