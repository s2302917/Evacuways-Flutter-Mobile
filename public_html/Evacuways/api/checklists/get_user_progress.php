<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_user_progress.php - Get user's checklist completion progress
$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : null;

if(!$user_id) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "User ID is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT 
              COUNT(*) as total_checklists,
              SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed_checklists,
              ROUND((SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) as completion_percentage
              FROM evacuways_checklists WHERE user_id = :user_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->execute();
    
    $progress = $stmt->fetch(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($progress);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
