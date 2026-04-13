<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_barangays.php - Get barangays by city
$city_code = isset($_GET['city_code']) ? htmlspecialchars($_GET['city_code']) : null;

if(!$city_code) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "City code is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_barangays WHERE city_code = :city_code ORDER BY barangay_name ASC";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':city_code', $city_code);
    $stmt->execute();
    
    $barangays = $stmt->fetchAll(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($barangays);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
