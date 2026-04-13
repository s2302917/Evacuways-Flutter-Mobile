<?php
class MessageModel {
    private $conn;
    private $userTable = "evacuways_users";
    private $messageTable = "evacuways_messages";

    public function __construct($db) {
        $this->conn = $db;
    }

    // Fetch all users for the sidebar search
    public function getContacts($search = '') {
        $query = "SELECT user_id, first_name, last_name, contact_number 
                  FROM " . $this->userTable;
        
        if (!empty($search)) {
            $query .= " WHERE first_name LIKE :search OR last_name LIKE :search";
        }
        
        $query .= " ORDER BY first_name ASC";
        $stmt = $this->conn->prepare($query);
        
        if (!empty($search)) {
            $stmt->bindValue(':search', '%' . $search . '%');
        }
        
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Fetch conversation between Admin and User
    public function getConversation($adminId, $userId) {
        // Updated to use both sender_type and receiver_type
        $query = "SELECT * FROM " . $this->messageTable . " 
                  WHERE (sender_type = 'admin' AND sender_id = :adminId AND receiver_type = 'user' AND receiver_id = :userId) 
                     OR (sender_type = 'user' AND sender_id = :userId AND receiver_type = 'admin' AND receiver_id = :adminId) 
                  ORDER BY sent_at ASC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute([
            ':adminId' => $adminId,
            ':userId' => $userId
        ]);
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Save a new message from Admin to User
    public function sendMessage($adminId, $receiverId, $messageText, $imagePath = null) {
        // Updated to insert 'user' into receiver_type
        $query = "INSERT INTO " . $this->messageTable . " 
                  (sender_type, sender_id, receiver_type, receiver_id, message_text, image_path, sent_at) 
                  VALUES ('admin', :sender_id, 'user', :receiver_id, :message_text, :image_path, NOW())";
        
        $stmt = $this->conn->prepare($query);
        
        return $stmt->execute([
            ':sender_id' => $adminId,
            ':receiver_id' => $receiverId,
            ':message_text' => $messageText,
            ':image_path' => $imagePath
        ]);
    }
}
?>