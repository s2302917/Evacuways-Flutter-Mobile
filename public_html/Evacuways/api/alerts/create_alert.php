<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// POST create_alert.php - Create new alert
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['title']) || !isset($data['message'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Title and message are required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $title = $data['title'];
    $message = $data['message'];
    $alert_type = $data['alert_type'] ?? null;
    $severity_level = $data['severity_level'] ?? 'Warning';
    $city_id = $data['city_id'] ?? null;
    $barangay_id = $data['barangay_id'] ?? null;
    $barangay_code = $data['barangay_code'] ?? null;
    $barangay_name = $data['barangay_name'] ?? null;
    $created_by = $data['created_by'] ?? null;
    $status = $data['status'] ?? 'Active';
    
    $query = "INSERT INTO evacuways_alerts 
              (title, message, alert_type, severity_level, city_id, barangay_id, 
               barangay_code, barangay_name, created_by, created_at, status) 
              VALUES (:title, :message, :alert_type, :severity_level, :city_id, :barangay_id, 
                      :barangay_code, :barangay_name, :created_by, NOW(), :status)";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':title', $title);
    $stmt->bindParam(':message', $message);
    $stmt->bindParam(':alert_type', $alert_type);
    $stmt->bindParam(':severity_level', $severity_level);
    $stmt->bindParam(':city_id', $city_id);
    $stmt->bindParam(':barangay_id', $barangay_id);
    $stmt->bindParam(':barangay_code', $barangay_code);
    $stmt->bindParam(':barangay_name', $barangay_name);
    $stmt->bindParam(':created_by', $created_by);
    $stmt->bindParam(':status', $status);
    
    if($stmt->execute()) {
        $alert_id = $conn->lastInsertId();
        http_response_code(201);
        echo json_encode(["success" => true, "message" => "Alert created", "alert_id" => $alert_id]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to create alert"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
