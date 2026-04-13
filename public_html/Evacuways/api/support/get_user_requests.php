<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_user_requests.php - Get user's support requests
$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : null;

if(!$user_id) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "User ID is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_support_requests WHERE user_id = :user_id ORDER BY created_at DESC";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->execute();
    
    $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($requests);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
