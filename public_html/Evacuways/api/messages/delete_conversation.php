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

    // Soft delete: Mark messages as deleted for the requesting user
    // 1. Where user is sender
    $q1 = "UPDATE evacuways_messages 
           SET deleted_by_sender = 1 
           WHERE sender_id = :user_id AND sender_type = 'user' 
             AND receiver_id = :other_id AND receiver_type = :other_type";
    $s1 = $db->prepare($q1);
    $s1->bindParam(':user_id', $user_id);
    $s1->bindParam(':other_id', $other_user_id);
    $s1->bindParam(':other_type', $other_user_type);
    $s1->execute();

    // 2. Where user is receiver
    $q2 = "UPDATE evacuways_messages 
           SET deleted_by_receiver = 1 
           WHERE receiver_id = :user_id AND receiver_type = 'user' 
             AND sender_id = :other_id AND sender_type = :other_type";
    $s2 = $db->prepare($q2);
    $s2->bindParam(':user_id', $user_id);
    $s2->bindParam(':other_id', $other_user_id);
    $s2->bindParam(':other_type', $other_user_type);
    $s2->execute();

    http_response_code(200);
    echo json_encode(["success" => true, "message" => "Conversation hidden for you."]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
}
?>
