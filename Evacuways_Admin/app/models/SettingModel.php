<?php
class SettingModel {
    private $conn;
    private $adminTable = "evacuways_admins";

    public function __construct($db) {
        $this->conn = $db;
    }

    // Fetch the current admin's information
    public function getAdminData($adminId) {
        $query = "SELECT * FROM " . $this->adminTable . " WHERE admin_id = :admin_id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->execute([':admin_id' => $adminId]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Update the admin's profile and location
    public function updateAdminProfile($adminId, $data) {
        // Base query
        $query = "UPDATE " . $this->adminTable . " 
                  SET full_name = :full_name, 
                      email = :email, 
                      latitude = :latitude, 
                      longitude = :longitude, 
                      region_code = :region_code, 
                      city_code = :city_code, 
                      barangay_code = :barangay_code";

        // If a NEW password is provided, append it to the update query
        if (!empty($data['password_hash'])) {
            $query .= ", password_hash = :password_hash";
        }

        $query .= " WHERE admin_id = :admin_id";

        $stmt = $this->conn->prepare($query);

        // Bind parameters
        $stmt->bindValue(':full_name', $data['full_name']);
        $stmt->bindValue(':email', $data['email']);
        $stmt->bindValue(':latitude', $data['latitude']);
        $stmt->bindValue(':longitude', $data['longitude']);
        $stmt->bindValue(':region_code', $data['region_code']);
        $stmt->bindValue(':city_code', $data['city_code']);
        $stmt->bindValue(':barangay_code', $data['barangay_code']);
        $stmt->bindValue(':admin_id', $adminId);

        if (!empty($data['password_hash'])) {
            $stmt->bindValue(':password_hash', $data['password_hash']);
        }

        return $stmt->execute();
    }
}
?>