<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// POST create_report.php - Create evacuation report
$data = json_decode(file_get_contents("php://input"), true);

if(!isset($data['admin_id']) || !isset($data['report_title'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Admin ID and report title are required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $admin_id = intval($data['admin_id']);
    $report_title = strip_tags($data['report_title']);
    $report_content = strip_tags($data['report_content'] ?? null);
    $report_type = htmlspecialchars($data['report_type'] ?? 'General');
    $region_code = $data['region_code'] ?? null;
    
    $query = "INSERT INTO evacuways_reports 
              (admin_id, report_title, report_content, report_type, region_code, created_at) 
              VALUES (:admin_id, :report_title, :report_content, :report_type, :region_code, NOW())";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':admin_id', $admin_id);
    $stmt->bindParam(':report_title', $report_title);
    $stmt->bindParam(':report_content', $report_content);
    $stmt->bindParam(':report_type', $report_type);
    $stmt->bindParam(':region_code', $region_code);
    
    if($stmt->execute()) {
        $report_id = $conn->lastInsertId();
        http_response_code(201);
        echo json_encode(["success" => true, "message" => "Report created", "report_id" => $report_id]);
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Failed to create report"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
