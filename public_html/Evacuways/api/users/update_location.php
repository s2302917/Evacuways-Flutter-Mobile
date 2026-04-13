<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// PUT update_location.php - Update user GPS location
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['user_id']) || !isset($data['latitude']) || !isset($data['longitude'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "User ID, latitude, and longitude are required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $user_id = $data['user_id'];
    $latitude = floatval($data['latitude']);
    $longitude = floatval($data['longitude']);
    
    // Update user location
    $query = "UPDATE evacuways_users SET latitude = :latitude, longitude = :longitude WHERE user_id = :user_id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->bindParam(':latitude', $latitude);
    $stmt->bindParam(':longitude', $longitude);
    
    if($stmt->execute()) {
        // Also insert into user_locations table for history
        $locationQuery = "INSERT INTO evacuways_user_locations (user_id, latitude, longitude, timestamp) 
                         VALUES (:user_id, :latitude, :longitude, NOW())";
        $locStmt = $conn->prepare($locationQuery);
        $locStmt->bindParam(':user_id', $user_id);
        $locStmt->bindParam(':latitude', $latitude);
        $locStmt->bindParam(':longitude', $longitude);
        $locStmt->execute();
        
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
