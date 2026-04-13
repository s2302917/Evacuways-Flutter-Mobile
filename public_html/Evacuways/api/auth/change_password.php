<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if(empty($data->user_id) || empty($data->new_password)) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Missing required fields."]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->connect();
    
    if ($conn === null) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database connection failed!"]);
        exit();
    }

    // Hash the new password using BCRYPT
    $hashed_password = password_hash($data->new_password, PASSWORD_BCRYPT);

    // Update password_hash and clear must_change_password flag
    $query = "UPDATE evacuways_users SET password_hash = :password, must_change_password = 0 WHERE user_id = :user_id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(":password", $hashed_password);
    $stmt->bindParam(":user_id", $data->user_id);
    
    if($stmt->execute()) {
        echo json_encode(["success" => true, "message" => "Password updated successfully."]);
    } else {
        echo json_encode(["success" => false, "message" => "Failed to update password."]);
    }

} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "System error."]);
}
?>
