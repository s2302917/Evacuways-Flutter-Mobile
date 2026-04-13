<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_cities.php - Get cities by region
$region_code = isset($_GET['region_code']) ? htmlspecialchars($_GET['region_code']) : null;

if(!$region_code) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Region code is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_cities WHERE region_code = :region_code ORDER BY city_name ASC";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':region_code', $region_code);
    $stmt->execute();
    
    $cities = $stmt->fetchAll(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($cities);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
