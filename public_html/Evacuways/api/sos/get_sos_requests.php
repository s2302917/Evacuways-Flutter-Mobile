<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$user_id = $_GET['user_id'] ?? null;

if (empty($user_id)) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Missing user_id."]);
    exit;
}

try {
    $database = new Database();
    $db = $database->connect();

    $query = "SELECT * FROM evacuways_support_requests 
              WHERE user_id = :user_id 
              ORDER BY created_at DESC 
              LIMIT 20";

    $stmt = $db->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->execute();

    $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(["success" => true, "requests" => $requests]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
}
?>
