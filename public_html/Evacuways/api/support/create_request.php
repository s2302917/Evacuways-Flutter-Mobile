<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// POST create_request.php - Create support request
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['user_id']) || !isset($data['request_type']) || !isset($data['description'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "User ID, request type, and description are required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $user_id = intval($data['user_id']);
    $request_type = htmlspecialchars($data['request_type']);
    $description = strip_tags($data['description']);
    $status = $data['status'] ?? 'Pending';
    $priority = $data['priority'] ?? 'Normal';
    
    $query = "INSERT INTO evacuways_support_requests 
              (user_id, request_type, description, status, priority, created_at) 
              VALUES (:user_id, :request_type, :description, :status, :priority, NOW())";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->bindParam(':request_type', $request_type);
    $stmt->bindParam(':description', $description);
    $stmt->bindParam(':status', $status);
    $stmt->bindParam(':priority', $priority);
    
    if($stmt->execute()) {
        $request_id = $conn->lastInsertId();
        http_response_code(201);
        echo json_encode(["success" => true, "message" => "Request created", "request_id" => $request_id]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to create request"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
