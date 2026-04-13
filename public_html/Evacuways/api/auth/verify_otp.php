<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if(empty($data->contact_number) || empty($data->otp)) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Contact number and OTP are required."]);
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

    // Normalize contact number for lookup
    $clean_number = ltrim($data->contact_number, '+');
    if (substr($clean_number, 0, 2) === '63') {
        $base_number = substr($clean_number, 2);
    } elseif (substr($clean_number, 0, 1) === '0') {
        $base_number = substr($clean_number, 1);
    } else {
        $base_number = $clean_number;
    }
    
    $f1 = '0' . $base_number;
    $f2 = '+63' . $base_number;
    $f3 = '63' . $base_number;

    // Check if OTP matches device_token
    $query = "SELECT user_id FROM evacuways_users WHERE (contact_number = :f1 OR contact_number = :f2 OR contact_number = :f3) AND device_token = :otp LIMIT 1";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(":f1", $f1);
    $stmt->bindParam(":f2", $f2);
    $stmt->bindParam(":f3", $f3);
    $stmt->bindParam(":otp", $data->otp);
    $stmt->execute();

    if ($stmt->rowCount() > 0) {
        echo json_encode(["success" => true, "message" => "OTP verified successfully."]);
    } else {
        http_response_code(401);
        echo json_encode(["success" => false, "message" => "Invalid OTP."]);
    }

} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "System error."]);
}
?>
