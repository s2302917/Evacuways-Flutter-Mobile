<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_centers_by_barangay.php - Get centers by barangay
$barangay_code = isset($_GET['barangay_code']) ? htmlspecialchars($_GET['barangay_code']) : null;

if(!$barangay_code) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Barangay code is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_centers WHERE barangay_code = :barangay_code ORDER BY created_at DESC";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':barangay_code', $barangay_code);
    $stmt->execute();
    
    $centers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($centers);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
