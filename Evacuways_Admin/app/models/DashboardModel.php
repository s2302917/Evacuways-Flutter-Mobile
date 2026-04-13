<?php

class DashboardModel {
    private $db;

    public function __construct($pdo) {
        $this->db = $pdo;
    }

    /**
     * Fetches actual coordinates for the Admin HQ.
     * Required for the Leaflet Map initialization.
     */
    public function getAdminCoords($adminId) {
        $stmt = $this->db->prepare("
            SELECT latitude, longitude 
            FROM evacuways_admins 
            WHERE admin_id = ? 
            LIMIT 1
        ");
        $stmt->execute([$adminId]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);

        return [
            'latitude'  => $result['latitude'] ?? '',
            'longitude' => $result['longitude'] ?? ''
        ];
    }

    /**
     * Retrieves the 10 most recent actions for the activity timeline.
     */
    public function getTimeline($adminId) {
        $stmt = $this->db->prepare("
            SELECT action, details, created_at 
            FROM evacuways_admin_logs 
            WHERE admin_id = ? 
            ORDER BY created_at DESC 
            LIMIT 10
        ");
        $stmt->execute([$adminId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Retrieves counts for the dashboard statistics cards safely.
     * Crash-proofed to prevent PDO "fetchColumn() on bool" fatal errors.
     */
    public function getCounts() {
        // Initialize default safe values
        $counts = [
            'alerts'    => 0,
            'vehicles'  => 0,
            'cities'    => 0,
            'users'     => 0,
            'evacuated' => 0
        ];

        try {
            // 1. Alerts
            $stmt = $this->db->query("SELECT COUNT(*) FROM evacuways_alerts WHERE status = 'active'");
            if ($stmt) $counts['alerts'] = $stmt->fetchColumn() ?: 0;

            // 2. Vehicles - Cleaned up to simply count ALL vehicles
            $stmt = $this->db->query("SELECT COUNT(*) FROM evacuways_vehicles");
            if ($stmt) $counts['vehicles'] = $stmt->fetchColumn() ?: 0;

            // 3. Cities
            $stmt = $this->db->query("SELECT COUNT(*) FROM evacuways_cities");
            if ($stmt) $counts['cities'] = $stmt->fetchColumn() ?: 0;

            // 4. Users
            $stmt = $this->db->query("SELECT COUNT(*) FROM evacuways_users");
            if ($stmt) $counts['users'] = $stmt->fetchColumn() ?: 0;

            // 5. Evacuated
            $stmt = $this->db->query("SELECT COUNT(*) FROM evacuways_user_checklists WHERE completed = 1");
            if ($stmt) $counts['evacuated'] = $stmt->fetchColumn() ?: 0;

        } catch (PDOException $e) {
            // If the database complains, it will silently log here instead of crashing your dashboard
            error_log("Dashboard Counts Error: " . $e->getMessage());
        }

        return $counts;
    }

    /**
     * Gets the latest user pings for the Leaflet map.
     */
    public function getMapLocations() {
        $stmt = $this->db->query("
            SELECT latitude, longitude, timestamp 
            FROM evacuways_user_locations 
            ORDER BY timestamp DESC 
            LIMIT 50
        ");
        return $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];
    }

    /**
     * Gets recent alerts for the dashboard table.
     */
    public function getRecentAlerts() {
        $stmt = $this->db->query("
            SELECT title, alert_type, status, created_at 
            FROM evacuways_alerts 
            ORDER BY created_at DESC 
            LIMIT 5
        ");
        return $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];
    }

    /**
     * Checks if the Admin HQ has been initialized.
     */
    public function checkAdminLocation($adminId) {
        $stmt = $this->db->prepare("
            SELECT latitude, region_code 
            FROM evacuways_admins 
            WHERE admin_id = ? 
            LIMIT 1
        ");
        $stmt->execute([$adminId]);
        $admin = $stmt->fetch(PDO::FETCH_ASSOC);
        
        return ($admin && !empty($admin['latitude']) && !empty($admin['region_code']));
    }
}