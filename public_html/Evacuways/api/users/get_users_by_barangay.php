<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_users_by_barangay.php - Fetch all users in a barangay
$barangay_code = isset($_GET['barangay_code']) ? htmlspecialchars($_GET['barangay_code']) : null;

if(!$barangay_code) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Barangay code is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT user_id, family_id, first_name, last_name, gender, birth_date, 
              contact_number, city_id, barangay_id, device_token, created_at, region_code, 
              city_code, barangay_code, center_id, headcount, is_family, missing_count, 
              rescue_status, assigned_vehicle_id, assigned_center_id, latitude, longitude 
              FROM evacuways_users WHERE barangay_code = :barangay_code ORDER BY first_name ASC";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':barangay_code', $barangay_code);
    $stmt->execute();
    
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($users);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
