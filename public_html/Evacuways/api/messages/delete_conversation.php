<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$data = json_decode(file_get_contents("php://input"));

$user_id       = $data->user_id ?? null;
$other_user_id = $data->other_user_id ?? null;
$other_user_type = $data->other_user_type ?? 'user';

if (empty($user_id) || empty($other_user_id)) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Missing required fields."]);
    exit;
}

try {
    $database = new Database();
    $db = $database->connect();

    $query = "DELETE FROM evacuways_messages 
              WHERE (sender_id = :user_id AND sender_type = 'user' AND receiver_id = :other_id AND receiver_type = :other_type)
              OR (sender_id = :other_id AND sender_type = :other_type AND receiver_id = :user_id AND receiver_type = 'user')";

    $stmt = $db->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->bindParam(':other_id', $other_user_id);
    $stmt->bindParam(':other_type', $other_user_type);
    $stmt->execute();

    http_response_code(200);
    echo json_encode(["success" => true, "message" => "Conversation deleted."]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
}
?>
