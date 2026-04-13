<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$data = json_decode(file_get_contents("php://input"));

$request_id = $data->request_id ?? null;
$user_id    = $data->user_id ?? null;

if (empty($request_id) || empty($user_id)) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Missing required fields."]);
    exit;
}

try {
    $database = new Database();
    $db = $database->connect();

    $query = "UPDATE evacuways_support_requests 
              SET status = 'Cancelled' 
              WHERE request_id = :request_id 
                AND user_id = :user_id 
                AND status = 'Pending'";

    $stmt = $db->prepare($query);
    $stmt->bindParam(':request_id', $request_id);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->execute();

    if ($stmt->rowCount() > 0) {
        echo json_encode(["success" => true, "message" => "SOS request cancelled."]);
    } else {
        echo json_encode(["success" => false, "message" => "Request not found or already processed."]);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
}
?>
