<?php
class FamilyModel {
    private $conn;
    private $userTable = "evacuways_users";
    private $familyTable = "evacuways_families";

    public function __construct($db) {
        $this->conn = $db;
    }

    // --- INDIVIDUAL USER METHODS ---

    public function create($firstName, $lastName, $contact, $barangay, $headcount, $missingCount) {
    // Removed latitude and longitude from both the column list and values
    $query = "INSERT INTO " . $this->userTable . " 
              (first_name, last_name, contact_number, barangay_code, headcount, missing_count, is_family, rescue_status) 
              VALUES (:fname, :lname, :contact, :brgy, :headcount, :missing, 1, 'Pending Rescue')";
    
    $stmt = $this->conn->prepare($query);
    
    return $stmt->execute([
        ':fname'     => $firstName,
        ':lname'     => $lastName,
        ':contact'   => $contact,
        ':brgy'      => $barangay,
        ':headcount' => $headcount,
        ':missing'   => $missingCount
    ]);
}

    public function getAll() {
        // Shows everyone regardless of is_family status
        $query = "SELECT u.*, 
                         v.plate_number, v.vehicle_type, 
                         c.center_name 
                  FROM " . $this->userTable . " u 
                  LEFT JOIN evacuways_vehicles v ON u.assigned_vehicle_id = v.vehicle_id 
                  LEFT JOIN evacuways_centers c ON u.assigned_center_id = c.center_id
                  ORDER BY u.created_at DESC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function update($id, $rescueStatus, $missingCount, $vehicleId, $centerId) {
        $query = "UPDATE " . $this->userTable . " 
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

    public function convertToFamily($id, $headcount) {
        $query = "UPDATE " . $this->userTable . " 
                  SET is_family = 1, 
                      headcount = :headcount,
                      rescue_status = 'Pending Rescue' 
                  WHERE user_id = :id";
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([
            ':id' => $id,
            ':headcount' => $headcount
        ]);
    }

    public function delete($id) {
        $query = "DELETE FROM " . $this->userTable . " WHERE user_id = :id";
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([':id' => $id]);
    }

    // --- BATCH FAMILY GROUPING METHODS ---

    /**
     * Create the "Family Card" metadata in evacuways_families
     */
    public function createFamilyGroup($data) {
        $query = "INSERT INTO " . $this->familyTable . " 
                  (family_name, primary_contact, rescue_status, headcount) 
                  VALUES (:name, :contact, :status, :count)";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':name', $data['family_name']);
        $stmt->bindParam(':contact', $data['family_contact']);
        $stmt->bindParam(':status', $data['family_status']);
        $stmt->bindParam(':count', $data['headcount']);
        
        if($stmt->execute()) {
            return $this->conn->lastInsertId();
        }
        return false;
    }

    /**
     * Link the selected users to that new Family ID in evacuways_users
     */
    public function updateUsersFamily($userIds, $familyId) {
        // Clean and prepare the IDs for an IN() clause
        $ids = implode(',', array_map('intval', $userIds));
        $query = "UPDATE " . $this->userTable . " SET family_id = :family_id WHERE user_id IN ($ids)";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':family_id', $familyId);
        return $stmt->execute();
    }

    public function getAllFamilies() {
        $query = "SELECT * FROM " . $this->familyTable . " ORDER BY created_at DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}