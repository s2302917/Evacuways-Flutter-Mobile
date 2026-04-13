<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_request.php - Get specific request details
$request_id = isset($_GET['request_id']) ? intval($_GET['request_id']) : null;

if(!$request_id) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Request ID is required"]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_support_requests WHERE request_id = :request_id";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':request_id', $request_id);
    $stmt->execute();
    
    if($stmt->rowCount() > 0) {
        $request = $stmt->fetch(PDO::FETCH_ASSOC);
        http_response_code(200);
        echo json_encode($request);
    } else {
        http_response_code(404);
        echo json_encode(["success" => false, "message" => "Request not found"]);
    }
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
