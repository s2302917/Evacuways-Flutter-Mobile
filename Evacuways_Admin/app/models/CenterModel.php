<?php
class CenterModel {
    private $conn;
    private $table = "evacuways_centers";

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create($center_name, $capacity, $barangay_name, $status, $contact_person, $contact_number) {
        $query = "INSERT INTO " . $this->table . " 
                  (center_name, capacity, barangay_name, status, contact_person, contact_number) 
                  VALUES (:center_name, :capacity, :barangay_name, :status, :contact_person, :contact_number)";
        
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([
            ':center_name' => $center_name,
            ':capacity' => $capacity,
            ':barangay_name' => $barangay_name,
            ':status' => $status,
            ':contact_person' => $contact_person,
            ':contact_number' => $contact_number
        ]);
    }

    public function update($id, $center_name, $capacity, $barangay_name, $status, $contact_person, $contact_number) {
        $query = "UPDATE " . $this->table . " 
                  SET center_name = :center_name, 
                      capacity = :capacity, 
                      barangay_name = :barangay_name, 
                      status = :status,
                      contact_person = :contact_person,
                      contact_number = :contact_number
                  WHERE center_id = :id";
        
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([
            ':id' => $id,
            ':center_name' => $center_name,
            ':capacity' => $capacity,
            ':barangay_name' => $barangay_name,
            ':status' => $status,
            ':contact_person' => $contact_person,
            ':contact_number' => $contact_number
        ]);
    }

    public function getAll() {
        $query = "SELECT * FROM " . $this->table . " ORDER BY created_at DESC, center_id DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getStatusStats() {
        $query = "SELECT status, COUNT(*) as count FROM " . $this->table . " GROUP BY status";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function delete($id) {
        $query = "DELETE FROM " . $this->table . " WHERE center_id = :id";
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([':id' => $id]);
    }
}