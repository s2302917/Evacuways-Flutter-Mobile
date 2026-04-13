<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_requests_by_status.php - Get requests by status
$status = isset($_GET['status']) ? htmlspecialchars($_GET['status']) : null;

if(!$status) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Status is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_support_requests WHERE status = :status ORDER BY created_at DESC";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':status', $status);
    $stmt->execute();
    
    $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($requests);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
