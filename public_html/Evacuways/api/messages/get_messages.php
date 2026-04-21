<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;
$other_user_id = isset($_GET['other_user_id']) ? $_GET['other_user_id'] : null;

if (!empty($user_id)) {
    try {
        $database = new Database();
        $db = $database->connect();

        $other_user_type = isset($_GET['other_user_type']) ? $_GET['other_user_type'] : 'user';

        if (!empty($other_user_id)) {
            // Fetch messages between two specific entities
            $query = "SELECT m.*, 
                             COALESCE(CONCAT(u_s.first_name, ' ', u_s.last_name), a_s.full_name) as sender_name,
                             COALESCE(CONCAT(u_r.first_name, ' ', u_r.last_name), a_r.full_name) as receiver_name
                      FROM evacuways_messages m
                      LEFT JOIN evacuways_users u_s ON m.sender_id = u_s.user_id AND m.sender_type = 'user'
                      LEFT JOIN evacuways_admins a_s ON m.sender_id = a_s.admin_id AND m.sender_type = 'admin'
                      LEFT JOIN evacuways_users u_r ON m.receiver_id = u_r.user_id AND m.receiver_type = 'user'
                      LEFT JOIN evacuways_admins a_r ON m.receiver_id = a_r.admin_id AND m.receiver_type = 'admin'
                      WHERE (
                          (m.sender_id = :user_id AND m.sender_type = 'user' AND m.receiver_id = :other_id AND m.receiver_type = :other_type AND m.deleted_by_sender = 0)
                          OR 
                          (m.sender_id = :other_id AND m.sender_type = :other_type AND m.receiver_id = :user_id AND m.receiver_type = 'user' AND m.deleted_by_receiver = 0)
                      )
                      ORDER BY m.sent_at ASC";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':user_id', $user_id);
            $stmt->bindParam(':other_id', $other_user_id);
            $stmt->bindParam(':other_type', $other_user_type);
        } else {
            // Fetch all messages for a user (conversation list view)
            $query = "SELECT m.*, 
                             COALESCE(CONCAT(u_s.first_name, ' ', u_s.last_name), a_s.full_name) as sender_name,
                             COALESCE(CONCAT(u_r.first_name, ' ', u_r.last_name), a_r.full_name) as receiver_name
                      FROM evacuways_messages m
                      LEFT JOIN evacuways_users u_s ON m.sender_id = u_s.user_id AND m.sender_type = 'user'
                      LEFT JOIN evacuways_admins a_s ON m.sender_id = a_s.admin_id AND m.sender_type = 'admin'
                      LEFT JOIN evacuways_users u_r ON m.receiver_id = u_r.user_id AND m.receiver_type = 'user'
                      LEFT JOIN evacuways_admins a_r ON m.receiver_id = a_r.admin_id AND m.receiver_type = 'admin'
                      WHERE (m.sender_id = :user_id AND m.sender_type = 'user' AND m.deleted_by_sender = 0) 
                         OR (m.receiver_id = :user_id AND m.receiver_type = 'user' AND m.deleted_by_receiver = 0)
                      ORDER BY m.sent_at ASC";
            $stmt = $db->prepare($query);
            $stmt->bindParam(':user_id', $user_id);
        }

        $stmt->execute();
        $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

        http_response_code(200);
        echo json_encode(["success" => true, "messages" => $messages]);

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Incomplete data."]);
}
?>