<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;

if ($user_id) {
    try {
        $database = new Database();
        $db = $database->connect();

        $query = "SELECT resource_type, resource_id, headcount FROM evacuways_user_presences WHERE user_id = :user_id LIMIT 1";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        $presence = $stmt->fetch(PDO::FETCH_ASSOC);

        http_response_code(200);
        if ($presence) {
            echo json_encode(["success" => true, "presence" => $presence]);
        } else {
            echo json_encode(["success" => true, "presence" => null]);
        }

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "User ID required."]);
}
?>
