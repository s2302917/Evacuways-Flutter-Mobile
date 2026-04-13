<?php
class VolunteerModel {
    private $conn;
    private $table = "evacuways_volunteers";

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create($user_id, $skills, $status = 'Active') {
        $query = "INSERT INTO " . $this->table . " 
                  (user_id, skills, availability_status) 
                  VALUES (:user_id, :skills, :status)";
        
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([
            ':user_id' => $user_id,
            ':skills' => $skills,
            ':status' => $status
        ]);
    }

    public function getAll() {
        // Join with users to get names and contact info
        $query = "SELECT v.*, u.first_name, u.last_name, u.contact_number, u.role
                  FROM " . $this->table . " v
                  JOIN evacuways_users u ON v.user_id = u.user_id
                  ORDER BY v.volunteer_id DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function delete($id) {
        $query = "DELETE FROM " . $this->table . " WHERE volunteer_id = :id";
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([':id' => $id]);
    }
}
?>
