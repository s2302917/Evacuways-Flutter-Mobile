<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// PUT mark_completed.php - Mark checklist as completed
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['checklist_id']) || !isset($data['user_id'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Checklist ID and user ID are required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $checklist_id = intval($data['checklist_id']);
    $user_id = intval($data['user_id']);
    
    $query = "UPDATE evacuways_checklists SET is_completed = 1, completed_at = NOW() 
              WHERE checklist_id = :checklist_id AND user_id = :user_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':checklist_id', $checklist_id);
    $stmt->bindParam(':user_id', $user_id);
    
    if($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["success" => true, "message" => "Checklist marked as completed"]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to update checklist"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
