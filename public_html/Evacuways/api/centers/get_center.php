<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_center.php - Get center details
$center_id = isset($_GET['center_id']) ? intval($_GET['center_id']) : null;

if(!$center_id) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Center ID is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_centers WHERE center_id = :center_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':center_id', $center_id);
    $stmt->execute();
    
    if($stmt->rowCount() > 0) {
        $center = $stmt->fetch(PDO::FETCH_ASSOC);
        http_response_code(200);
        echo json_encode($center);
    } else {
        http_response_code(404);
        echo json_encode(["success" => false, "message" => "Center not found"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
