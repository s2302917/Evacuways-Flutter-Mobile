<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$data = json_decode(file_get_contents("php://input"));

$user_id = $data->user_id ?? null;
$other_user_id = $data->other_user_id ?? null;
$other_user_type = $data->other_user_type ?? 'user';

if (!empty($user_id) && !empty($other_user_id)) {
    try {
        $database = new Database();
        $db = $database->connect();

        // Mark all messages FROM other user TO current user as read
        $query = "UPDATE evacuways_messages 
                  SET is_read = 1 
                  WHERE sender_id = :other_id 
                  AND sender_type = :other_type 
                  AND receiver_id = :user_id 
                  AND receiver_type = 'user' 
                  AND is_read = 0";

        $stmt = $db->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->bindParam(':other_id', $other_user_id);
        $stmt->bindParam(':other_type', $other_user_type);
        $stmt->execute();

        http_response_code(200);
        echo json_encode(["success" => true, "message" => "Messages marked as read."]);

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Incomplete data."]);
}
?>
