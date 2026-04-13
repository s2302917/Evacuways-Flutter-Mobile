<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if(empty($data->contact_number)) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Contact number is required."]);
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

    // Check if user exists
    $query = "SELECT user_id, first_name FROM evacuways_users WHERE contact_number = :f1 OR contact_number = :f2 OR contact_number = :f3 LIMIT 1";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(":f1", $f1);
    $stmt->bindParam(":f2", $f2);
    $stmt->bindParam(":f3", $f3);
    $stmt->execute();

    if ($stmt->rowCount() > 0) {
        $user = $stmt->fetch();
        $firstName = $user['first_name'];
        
        // Generate 6-digit OTP
        $otp = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
        
        // Save OTP to device_token as requested
        $update_query = "UPDATE evacuways_users SET device_token = :otp WHERE contact_number = :contact_number";
        $update_stmt = $conn->prepare($update_query);
        $update_stmt->bindParam(":otp", $otp);
        $update_stmt->bindParam(":contact_number", $data->contact_number);
        $update_stmt->execute();

        // Send SMS via PhilSMS API
        $phone = $data->contact_number; // e.g., 09171234567
        
        // Normalize to +63 format for PhilSMS
        // Remove spaces or dashes if any
        $phone = str_replace([' ', '-', '+'], '', $phone);
        
        // If it starts with 0, replace with 63
        if (substr($phone, 0, 1) === '0') {
            $phone = '63' . substr($phone, 1);
        }
        
        // Ensure it has +63 prefix
        if (substr($phone, 0, 2) === '63') {
            $phone = '+' . $phone;
        } else {
            $phone = '+63' . $phone;
        }

        $token = "1791|Cf5rB26DndraywKMyo974uwE1rq8tUSSKK9W7lIA";
        
        $send_data = [
            'sender_id' => 'PhilSMS', 
            'recipient' => $phone,
            'message' => "EvacuWays: Your OTP for password reset is $otp. Do not share this with anyone."
        ];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, "https://app.philsms.com/api/v3/sms/send");
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($send_data));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false); // Bypass SSL verification if server has issues
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            "Content-Type: application/json",
            "Authorization: Bearer $token"
        ]);

        $response_raw = curl_exec($ch);
        $curl_error = curl_error($ch);
        $http_status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($curl_error) {
            echo json_encode(["success" => false, "message" => "CURL Error: " . $curl_error]);
            exit();
        }

        $response = json_decode($response_raw, true);

        if ($http_status == 200 && isset($response['status']) && $response['status'] == 'success') {
            echo json_encode(["success" => true, "message" => "OTP sent successfully to $phone."]);
        } else {
            // Include formatted phone in debug
            echo json_encode([
                "success" => false, 
                "message" => "Failed to send SMS via PhilSMS.", 
                "debug_phone" => $phone,
                "debug_response" => $response,
                "http_status" => $http_status
            ]);
        }
    } else {
        http_response_code(404);
        echo json_encode(["success" => false, "message" => "Contact number not registered."]);
    }

} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "System error. " . $e->getMessage()]);
}
?>
