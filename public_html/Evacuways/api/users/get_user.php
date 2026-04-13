<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_user.php - Fetch user profile by ID
$request_method = $_SERVER['REQUEST_METHOD'];
$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : null;

if(!$user_id) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "User ID is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT user_id, family_id, first_name, last_name, password, gender, birth_date, 
              contact_number, city_id, barangay_id, device_token, created_at, region_code, 
              city_code, barangay_code, center_id, headcount, is_family, missing_count, 
              rescue_status, assigned_vehicle_id, assigned_center_id, latitude, longitude 
              FROM evacuways_users WHERE user_id = :user_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->execute();
    
    if($stmt->rowCount() > 0) {
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        // Remove password for security
        unset($user['password']);
        http_response_code(200);
        echo json_encode($user);
    } else {
        http_response_code(404);
        echo json_encode(["success" => false, "message" => "User not found"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
