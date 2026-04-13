<?php
class AlertModel {
    private $conn;
    private $table = "evacuways_alerts";

    public function __construct($db) {
        $this->conn = $db;
    }

    /**
     * Resolves a City Code or ID into the actual integer Primary Key city_id.
     * This ensures we don't violate Foreign Key constraints on city_id.
     */
    private function resolveCityId($identifier) {
        if (empty($identifier)) return $this->getFallbackCityId();
        
        $query = "SELECT city_id FROM evacuways_cities WHERE city_id = :id OR city_code = :code LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->execute([':id' => $identifier, ':code' => $identifier]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        
        return $row ? (int)$row['city_id'] : $this->getFallbackCityId();
    }

    private function getFallbackCityId() {
        $query = "SELECT city_id FROM evacuways_cities LIMIT 1";
        $stmt = $this->conn->query($query);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row ? (int)$row['city_id'] : null;
    }

    /**
     * Create Alert: Saves everything directly to the alerts table.
     * No longer attempts to sync with evacuways_barangays table.
     */
    public function create($title, $message, $alert_type, $severity_level, $status, $city_ident, $brgy_code, $brgy_name, $created_by = null) {
        $actual_city_id = $this->resolveCityId($city_ident);

        $query = "INSERT INTO " . $this->table . " 
                  (title, message, alert_type, severity_level, status, city_id, barangay_code, barangay_name, created_by, created_at) 
                  VALUES (:title, :message, :alert_type, :severity_level, :status, :city_id, :barangay_code, :barangay_name, :created_by, NOW())";
        
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([
            ':title' => $title,
            ':message' => $message,
            ':alert_type' => $alert_type,
            ':severity_level' => $severity_level,
            ':status' => $status,
            ':city_id' => $actual_city_id,
            ':barangay_code' => $brgy_code,
            ':barangay_name' => $brgy_name,
            ':created_by' => $created_by
        ]);
    }

    /**
     * Update Alert: Updates the alert info including the manually synced barangay name.
     */
    public function update($alert_id, $title, $message, $alert_type, $severity_level, $status, $city_ident, $brgy_code, $brgy_name) {
        $actual_city_id = $this->resolveCityId($city_ident);

        $query = "UPDATE " . $this->table . " 
                  SET title = :title, 
                      message = :message, 
                      alert_type = :alert_type, 
                      severity_level = :severity_level, 
                      status = :status, 
                      city_id = :city_id, 
                      barangay_code = :barangay_code,
                      barangay_name = :barangay_name
                  WHERE alert_id = :alert_id";
        
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([
            ':alert_id' => $alert_id,
            ':title' => $title,
            ':message' => $message,
            ':alert_type' => $alert_type,
            ':severity_level' => $severity_level,
            ':status' => $status,
            ':city_id' => $actual_city_id,
            ':barangay_code' => $brgy_code,
            ':barangay_name' => $brgy_name
        ]);
    }

    /**
     * Fetches alerts. Now relies on the direct 'barangay_name' column 
     * in the alerts table instead of joining the barangays table.
     */
    public function getAll() {
        $query = "SELECT a.*, c.city_name
                  FROM " . $this->table . " a
                  LEFT JOIN evacuways_cities c ON a.city_id = c.city_id
                  ORDER BY a.created_at DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getAlertsPerMonth() {
        $query = "SELECT DATE_FORMAT(created_at, '%b') as month, COUNT(*) as count 
                  FROM " . $this->table . " 
                  GROUP BY MONTH(created_at), month
                  ORDER BY MIN(created_at) ASC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getAlertsByType() {
        $query = "SELECT alert_type as type, COUNT(*) as count FROM " . $this->table . " GROUP BY alert_type";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function delete($alert_id) {
        $query = "DELETE FROM " . $this->table . " WHERE alert_id = :alert_id";
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([':alert_id' => $alert_id]);
    }
}