<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET search_locations.php - Search locations by query
$query_param = isset($_GET['query']) ? htmlspecialchars($_GET['query']) : null;

if(!$query_param || strlen($query_param) < 2) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Query must be at least 2 characters"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $search = "%$query_param%";
    
    $query = "SELECT 'region' as type, region_code as code, region_name as name FROM evacuways_regions WHERE region_name LIKE :search
              UNION
              SELECT 'city' as type, city_code as code, city_name as name FROM evacuways_cities WHERE city_name LIKE :search
              UNION
              SELECT 'barangay' as type, barangay_code as code, barangay_name as name FROM evacuways_barangays WHERE barangay_name LIKE :search
              LIMIT 50";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':search', $search);
    $stmt->execute();
    
    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($results);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
