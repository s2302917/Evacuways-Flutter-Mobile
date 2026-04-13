<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_alerts_by_severity.php - Fetch alerts by severity level
$severity = isset($_GET['severity']) ? htmlspecialchars($_GET['severity']) : null;

if(!$severity) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Severity level is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_alerts 
              WHERE severity_level = :severity AND status = 'Active' 
              ORDER BY created_at DESC";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':severity', $severity);
    $stmt->execute();
    
    $alerts = $stmt->fetchAll(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($alerts);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
