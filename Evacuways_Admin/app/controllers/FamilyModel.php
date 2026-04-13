<?php
class FamilyModel {
    private $conn;
    private $table = "evacuways_users";

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create($firstName, $lastName, $contact, $barangay, $headcount, $missingCount, $lat, $lng) {
        $query = "INSERT INTO " . $this->table . " 
                  (first_name, last_name, contact_number, barangay_name, headcount, missing_count, latitude, longitude, is_family, rescue_status) 
                  VALUES (:fname, :lname, :contact, :brgy, :headcount, :missing, :lat, :lng, 1, 'Pending Rescue')";
        
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([
            ':fname' => $firstName,
            ':lname' => $lastName,
            ':contact' => $contact,
            ':brgy' => $barangay,
            ':headcount' => $headcount,
            ':missing' => $missingCount,
            ':lat' => empty($lat) ? null : $lat,
            ':lng' => empty($lng) ? null : $lng
        ]);
    }

    public function update($id, $rescueStatus, $missingCount, $vehicleId, $centerId) {
        $query = "UPDATE " . $this->table . " 
                  SET rescue_status = :status, 
                      missing_count = :missing, 
                      assigned_vehicle_id = :vehicle,
                      assigned_center_id = :center
                  WHERE user_id = :id";
        
        $stmt = $this->conn->prepare($query);
        
        $vehicleId = empty($vehicleId) ? null : $vehicleId;
        $centerId = empty($centerId) ? null : $centerId;

        return $stmt->execute([
            ':id' => $id,
            ':status' => $rescueStatus,
            ':missing' => $missingCount,
            ':vehicle' => $vehicleId,
            ':center' => $centerId
        ]);
    }

    public function getAll() {
        $query = "SELECT u.*, v.plate_number, v.vehicle_type 
                  FROM " . $this->table . " u 
                  LEFT JOIN evacuways_vehicles v ON u.assigned_vehicle_id = v.vehicle_id 
                  WHERE u.is_family = 1 
                  ORDER BY u.created_at DESC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getStatusStats() {
        $query = "SELECT rescue_status, COUNT(*) as count 
                  FROM " . $this->table . " 
                  WHERE is_family = 1 
                  GROUP BY rescue_status";
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC); 
    }

    public function delete($id) {
        $query = "DELETE FROM " . $this->table . " WHERE user_id = :id";
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([':id' => $id]);
    }
}
?>