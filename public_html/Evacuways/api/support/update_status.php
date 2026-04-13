<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// PUT update_status.php - Update support request status
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['request_id']) || !isset($data['status'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Request ID and status are required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $request_id = intval($data['request_id']);
    $status = htmlspecialchars($data['status']);
    $resolution_notes = $data['resolution_notes'] ?? null;
    
    $query = "UPDATE evacuways_support_requests SET status = :status";
    
    if($resolution_notes) {
        $query .= ", resolution_notes = :resolution_notes, resolved_at = NOW()";
    }
    
    $query .= " WHERE request_id = :request_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':request_id', $request_id);
    $stmt->bindParam(':status', $status);
    if($resolution_notes) {
        $stmt->bindParam(':resolution_notes', $resolution_notes);
    }
    
    if($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["success" => true, "message" => "Status updated"]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to update status"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
