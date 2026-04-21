<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// PUT update_user.php - Update user profile
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['user_id'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "User ID is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $user_id = $data['user_id'];
    $first_name = $data['first_name'] ?? null;
    $last_name = $data['last_name'] ?? null;
    $gender = $data['gender'] ?? null;
    $birth_date = $data['birth_date'] ?? null;
    $contact_number = $data['contact_number'] ?? null;
    $city_id = $data['city_id'] ?? null;
    $barangay_id = $data['barangay_id'] ?? null;
    $region_code = $data['region_code'] ?? null;
    $city_code = $data['city_code'] ?? null;
    $barangay_code = $data['barangay_code'] ?? null;
    $device_token = $data['device_token'] ?? null;
    $headcount = $data['headcount'] ?? 1;
    $is_family = $data['is_family'] ?? 0;
    $missing_count = $data['missing_count'] ?? 0;
    $assigned_vehicle_id = $data['assigned_vehicle_id'] ?? null;
    $assigned_center_id = $data['assigned_center_id'] ?? null;
    $latitude = $data['latitude'] ?? null;
    $longitude = $data['longitude'] ?? null;
    
    $query = "UPDATE evacuways_users SET 
              first_name = :first_name,
              last_name = :last_name,
              gender = :gender,
              birth_date = :birth_date,
              contact_number = :contact_number,
              city_id = :city_id,
              barangay_id = :barangay_id,
              region_code = :region_code,
              city_code = :city_code,
              barangay_code = :barangay_code,
              device_token = :device_token,
              headcount = :headcount,
              is_family = :is_family,
              missing_count = :missing_count,
              assigned_vehicle_id = :assigned_vehicle_id,
              assigned_center_id = :assigned_center_id,
              latitude = :latitude,
              longitude = :longitude
              WHERE user_id = :user_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->bindParam(':first_name', $first_name);
    $stmt->bindParam(':last_name', $last_name);
    $stmt->bindParam(':gender', $gender);
    $stmt->bindParam(':birth_date', $birth_date);
    $stmt->bindParam(':contact_number', $contact_number);
    $stmt->bindParam(':city_id', $city_id);
    $stmt->bindParam(':barangay_id', $barangay_id);
    $stmt->bindParam(':region_code', $region_code);
    $stmt->bindParam(':city_code', $city_code);
    $stmt->bindParam(':barangay_code', $barangay_code);
    $stmt->bindParam(':device_token', $device_token);
    $stmt->bindParam(':headcount', $headcount);
    $stmt->bindParam(':is_family', $is_family);
    $stmt->bindParam(':missing_count', $missing_count);
    $stmt->bindParam(':assigned_vehicle_id', $assigned_vehicle_id);
    $stmt->bindParam(':assigned_center_id', $assigned_center_id);
    $stmt->bindParam(':latitude', $latitude);
    $stmt->bindParam(':longitude', $longitude);
    
    if($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["success" => true, "message" => "User updated successfully"]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to update user"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
