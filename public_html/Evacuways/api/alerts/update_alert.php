<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// PUT update_alert.php - Update alert status
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['alert_id']) || !isset($data['status'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Alert ID and status are required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $alert_id = $data['alert_id'];
    $status = $data['status'];
    
    $query = "UPDATE evacuways_alerts SET status = :status WHERE alert_id = :alert_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':alert_id', $alert_id);
    $stmt->bindParam(':status', $status);
    
    if($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["success" => true, "message" => "Alert updated"]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to update alert"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
