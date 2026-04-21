<?php
if (function_exists('opcache_reset')) {
    opcache_reset();
}

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/MessageModel.php';

// Base URL of the Evacuways API — used for cURL upload and for building image display URLs.
define('EVACUWAYS_API_URL',  'https://5zu.758.mytemp.website/Evacuways/api');
define('EVACUWAYS_BASE_URL', 'https://5zu.758.mytemp.website/Evacuways');

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
                $adminId     = $_SESSION['admin_id'] ?? 1;
                $receiverId  = $_POST['receiver_id'];
                $messageText = trim($_POST['message_text']);
                $imagePath   = null;

                // ── Image upload ──────────────────────────────────────────────────────────
                if (isset($_FILES['chat_image']) && $_FILES['chat_image']['error'] === UPLOAD_ERR_OK) {
                    $fileTmpPath = $_FILES['chat_image']['tmp_name'];
                    $fileName    = $_FILES['chat_image']['name'];
                    $fileType    = mime_content_type($fileTmpPath);

                    $allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];

                    if (!in_array($fileType, $allowedTypes)) {
                        $this->redirect("messages.php?user_id=$receiverId&error=invalid_file");
                    }

                    // Forward the file to the EXACT same upload endpoint the Flutter app uses.
                    // This ensures:
                    //   • The file lands in public_html/Evacuways/uploads/messages/ (shared folder)
                    //   • The returned image_path is "uploads/messages/<filename>" — the same
                    //     format both the admin view and Flutter use to build the display URL.
                    $uploadEndpoint = EVACUWAYS_API_URL . '/messages/upload_chat_image.php';
                    $cfile = new CURLFile($fileTmpPath, $fileType, $fileName);

                    $ch = curl_init($uploadEndpoint);
                    curl_setopt($ch, CURLOPT_POST,           true);
                    curl_setopt($ch, CURLOPT_POSTFIELDS,     ['image' => $cfile]);
                    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false); // safe for shared hosting
                    curl_setopt($ch, CURLOPT_TIMEOUT,        30);
                    $response  = curl_exec($ch);
                    $curlError = curl_error($ch);
                    curl_close($ch);

                    if ($response !== false && empty($curlError)) {
                        // Trim the response to remove any unexpected whitespace/BOM that could break json_decode
                        $result = json_decode(trim($response), true);
                        if (!empty($result['success']) && !empty($result['image_path'])) {
                            // e.g. "uploads/messages/1716000000_photo.jpg"
                            $imagePath = $result['image_path'];
                        }
                    }

                    // If upload failed for any reason, redirect with error — don't save a
                    // broken/empty image_path to the database.
                    if ($imagePath === null) {
                        $this->redirect("messages.php?user_id=$receiverId&error=upload_failed");
                    }
                }
                // ─────────────────────────────────────────────────────────────────────────

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