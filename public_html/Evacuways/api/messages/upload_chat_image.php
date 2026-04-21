<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// Set upload directory — shared with admin panel so both sides can see each other's images
$target_dir = "../../uploads/messages/";
if (!file_exists($target_dir)) {
    mkdir($target_dir, 0777, true);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['image'])) {
    $file_name = time() . "_" . basename($_FILES["image"]["name"]);
    $target_file = $target_dir . $file_name;

    // Check if image file is an actual image or fake image
    $check = getimagesize($_FILES["image"]["tmp_name"]);
    if($check !== false) {
        if (move_uploaded_file($_FILES["image"]["tmp_name"], $target_file)) {
            // Set file permissions to ensure web accessibility (resolves 403 Forbidden / "corruption" issues)
            chmod($target_file, 0644);

            header('Content-Type: application/json');
            echo json_encode([
                "success" => true,
                "message" => "The file " . htmlspecialchars($file_name) . " has been uploaded.",
                "image_path" => "uploads/messages/" . $file_name
            ]);
        } else {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => "Sorry, there was an error uploading your file."]);
        }
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "File is not an image."]);
    }
} else {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "No image file provided."]);
}
?>

