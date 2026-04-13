<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET search_users.php - Search users by name or contact
$query_str = isset($_GET['q']) ? htmlspecialchars($_GET['q']) : '';

if(strlen($query_str) < 2) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Search query must be at least 2 characters"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $search_term = "%$query_str%";
    
    $query = "SELECT user_id, family_id, first_name, last_name, gender, birth_date, 
              contact_number, city_id, barangay_id, device_token, created_at, region_code, 
              city_code, barangay_code, center_id, headcount, is_family, missing_count, 
              rescue_status, assigned_vehicle_id, assigned_center_id, latitude, longitude 
              FROM evacuways_users 
              WHERE first_name LIKE :search OR last_name LIKE :search OR contact_number LIKE :search 
              LIMIT 50";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':search', $search_term);
    $stmt->execute();
    
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($users);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
