<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_available_capacity.php - Get available capacity for centers
$center_id = isset($_GET['center_id']) ? intval($_GET['center_id']) : null;

if(!$center_id) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Center ID is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT center_id, center_name, max_capacity, current_individuals, 
              (max_capacity - current_individuals) as available_capacity 
              FROM evacuways_centers WHERE center_id = :center_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':center_id', $center_id);
    $stmt->execute();
    
    if($stmt->rowCount() > 0) {
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        http_response_code(200);
        echo json_encode($result);
    } else {
        http_response_code(404);
        echo json_encode(["success" => false, "message" => "Center not found"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
