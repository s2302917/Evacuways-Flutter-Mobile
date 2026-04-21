<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->sender_id) && !empty($data->receiver_id) && !empty($data->message_text)) {
    try {
        $database = new Database();
        $db = $database->connect();

        $query = "INSERT INTO evacuways_messages (request_id, sender_type, sender_id, receiver_type, receiver_id, message_text, latitude, longitude, sender_role, image_path, is_read) 
                  VALUES (:request_id, :sender_type, :sender_id, :receiver_type, :receiver_id, :message_text, :latitude, :longitude, :sender_role, :image_path, 0)";
        
        $sender_type = $data->sender_type ?? 'user';
        $receiver_type = $data->receiver_type ?? 'user';

        $stmt = $db->prepare($query);
        $stmt->bindParam(':request_id', $data->request_id);
        $stmt->bindParam(':sender_type', $sender_type);
        $stmt->bindParam(':sender_id', $data->sender_id);
        $stmt->bindParam(':receiver_type', $receiver_type);
        $stmt->bindParam(':receiver_id', $data->receiver_id);
        $stmt->bindParam(':message_text', $data->message_text);
        $stmt->bindParam(':latitude', $data->latitude);
        $stmt->bindParam(':longitude', $data->longitude);
        $stmt->bindParam(':sender_role', $data->sender_role);
        $stmt->bindParam(':image_path', $data->image_path);

        if ($stmt->execute()) {
            http_response_code(201);
            echo json_encode(["success" => true, "message" => "Message sent successfully."]);
        } else {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => "Failed to send message."]);
        }

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Incomplete data."]);
}
?>
