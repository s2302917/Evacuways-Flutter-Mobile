<?php
if (function_exists('opcache_reset')) {
    opcache_reset(); 
}

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php'; 
require_once __DIR__ . '/../models/MessageModel.php';

class MessageController {
    private $messageModel;
    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->connect(); 
        $this->messageModel = new MessageModel($this->db);
    }

    public function getContacts($search = '') {
        return $this->messageModel->getContacts($search);
    }

    public function getChat($adminId, $userId) {
        return $this->messageModel->getConversation($adminId, $userId);
    }

    public function handleRequest() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            
            if (isset($_POST['send_message'])) {
                // Ensure this matches your admin session variable name
                $adminId = $_SESSION['admin_id'] ?? 1; 
                $receiverId = $_POST['receiver_id'];
                $messageText = trim($_POST['message_text']);
                $imagePath = null;

                if (isset($_FILES['chat_image']) && $_FILES['chat_image']['error'] === UPLOAD_ERR_OK) {
                    $fileTmpPath = $_FILES['chat_image']['tmp_name'];
                    $fileName    = $_FILES['chat_image']['name'];
                    $fileType    = mime_content_type($fileTmpPath);

                    $allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];

                    if (in_array($fileType, $allowedTypes)) {
                        // Upload to the SAME folder as the Flutter mobile app so both sides
                        // can read each other's images through the shared Evacuways URL.
                        $uploadDir = __DIR__ . '/../../../public_html/Evacuways/uploads/messages/';

                        if (!is_dir($uploadDir)) {
                            mkdir($uploadDir, 0777, true);
                        }

                        $newFileName = time() . '_' . basename($fileName);
                        $destPath    = $uploadDir . $newFileName;

                        if (move_uploaded_file($fileTmpPath, $destPath)) {
                            // Store the same path format the mobile API uses:
                            // "uploads/messages/<filename>" — resolved against the Evacuways base URL.
                            $imagePath = 'uploads/messages/' . $newFileName;
                        }
                    } else {
                        $this->redirect("messages.php?user_id=$receiverId&error=invalid_file");
                    }
                }

                if (!empty($messageText) || $imagePath !== null) {
                    $this->messageModel->sendMessage($adminId, $receiverId, $messageText, $imagePath);
                }

                $this->redirect("messages.php?user_id=$receiverId");
            }
        }
    }

    private function redirect($url) {
        header("Location: $url");
        exit();
    }
}
?>