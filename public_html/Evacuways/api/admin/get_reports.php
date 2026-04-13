<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_reports.php - Get evacuation reports
try {
    $database = new Database();
    $conn = $database->connect();
    
    $report_type = isset($_GET['type']) ? htmlspecialchars($_GET['type']) : null;
    $region_code = isset($_GET['region_code']) ? htmlspecialchars($_GET['region_code']) : null;
    
    $query = "SELECT * FROM evacuways_reports WHERE 1=1";
    
    if($report_type) {
        $query .= " AND report_type = :report_type";
    }
    if($region_code) {
        $query .= " AND region_code = :region_code";
    }
    
    $query .= " ORDER BY created_at DESC LIMIT 100";
    
    $stmt = $conn->prepare($query);
    
    if($report_type) {
        $stmt->bindParam(':report_type', $report_type);
    }
    if($region_code) {
        $stmt->bindParam(':region_code', $region_code);
    }
    
    $stmt->execute();
    
    $reports = $stmt->fetchAll(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($reports);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
