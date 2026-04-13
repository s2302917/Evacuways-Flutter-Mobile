<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_alerts.php - Fetch all active alerts
try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_alerts WHERE status = 'Active' ORDER BY created_at DESC";
    
    $stmt = $conn->prepare($query);
    $stmt->execute();
    
    $alerts = $stmt->fetchAll(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($alerts);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
