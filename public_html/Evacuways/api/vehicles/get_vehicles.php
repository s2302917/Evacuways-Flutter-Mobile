<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_vehicles.php - Fetch all vehicles
try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_vehicles ORDER BY created_at DESC";
    
    $stmt = $conn->prepare($query);
    $stmt->execute();
    
    $vehicles = $stmt->fetchAll(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($vehicles);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
