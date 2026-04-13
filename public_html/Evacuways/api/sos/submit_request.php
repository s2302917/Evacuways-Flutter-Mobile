<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->user_id) && !empty($data->request_type)) {
    try {
        $database = new Database();
        $db = $database->connect();

        $query = "INSERT INTO evacuways_support_requests (user_id, subject, message, request_type, status) 
                  VALUES (:user_id, :subject, :message, :request_type, 'Pending')";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(':user_id', $data->user_id);
        $stmt->bindParam(':subject', $data->subject);
        $stmt->bindParam(':message', $data->message);
        $stmt->bindParam(':request_type', $data->request_type);

        if ($stmt->execute()) {
            $newId = $db->lastInsertId();
            http_response_code(201);
            echo json_encode([
                "success" => true,
                "message" => "SOS Request submitted successfully.",
                "request_id" => $newId
            ]);
        } else {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => "Failed to submit request."]);
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
