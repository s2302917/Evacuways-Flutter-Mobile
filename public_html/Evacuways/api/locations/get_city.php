<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_city.php - Get city details
$city_code = isset($_GET['city_code']) ? htmlspecialchars($_GET['city_code']) : null;

if(!$city_code) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "City code is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_cities WHERE city_code = :city_code";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':city_code', $city_code);
    $stmt->execute();
    
    if($stmt->rowCount() > 0) {
        $city = $stmt->fetch(PDO::FETCH_ASSOC);
        http_response_code(200);
        echo json_encode($city);
    } else {
        http_response_code(404);
        echo json_encode(["success" => false, "message" => "City not found"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
