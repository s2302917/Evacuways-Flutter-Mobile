<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_regions.php - Get all regions
try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_regions ORDER BY region_name ASC";
    
    $stmt = $conn->prepare($query);
    $stmt->execute();
    
    $regions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($regions);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
