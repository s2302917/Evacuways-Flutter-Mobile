<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// DELETE delete_alert.php - Delete alert
$alert_id = isset($_GET['alert_id']) ? intval($_GET['alert_id']) : null;

if(!$alert_id) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Alert ID is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "DELETE FROM evacuways_alerts WHERE alert_id = :alert_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':alert_id', $alert_id);
    
    if($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["success" => true, "message" => "Alert deleted"]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to delete alert"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
