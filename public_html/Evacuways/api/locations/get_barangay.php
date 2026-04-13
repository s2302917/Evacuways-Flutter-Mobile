<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_barangay.php - Get barangay details
$barangay_code = isset($_GET['barangay_code']) ? htmlspecialchars($_GET['barangay_code']) : null;

if(!$barangay_code) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Barangay code is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_barangays WHERE barangay_code = :barangay_code";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':barangay_code', $barangay_code);
    $stmt->execute();
    
    if($stmt->rowCount() > 0) {
        $barangay = $stmt->fetch(PDO::FETCH_ASSOC);
        http_response_code(200);
        echo json_encode($barangay);
    } else {
        http_response_code(404);
        echo json_encode(["success" => false, "message" => "Barangay not found"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
