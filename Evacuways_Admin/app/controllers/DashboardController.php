<?php
/**
 * Dashboard Controller - Compiled Version
 * Handles data aggregation for the dashboard view and AJAX updates.
 */

if (session_status() === PHP_SESSION_NONE) { 
    session_start(); 
}

require_once dirname(__DIR__) . "/models/DashboardModel.php";
require_once dirname(__DIR__) . "/config/database.php";

class DashboardController {
    private $model;
    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->connect(); 
        $this->model = new DashboardModel($this->db);
    }

    /**
     * Primary entry point.
     * Serves all dashboard data or handles POST location updates.
     */
    public function index() {
        // --- 1. HANDLE AJAX SAVING (POST Request) ---
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $this->handleLocationUpdate();
            exit;
        }

        // --- 2. REGULAR PAGE LOAD (GET Request) ---
        $adminId = $_SESSION['admin_id'] ?? 0;
        
        // Fetch data from Model
        $counts = $this->model->getCounts();
        $adminData = $this->model->getAdminCoords($adminId);
        $timeline = $this->model->getTimeline($adminId);

        // Return the compiled data array to the view
        return [
            'alertCount'     => $counts['alerts'] ?? 0,
            'vehicleCount'   => $counts['vehicles'] ?? 0,
            'cityCount'      => $counts['cities'] ?? 0,
            'totalUsers'     => $counts['users'] ?? 0,
            'evacuatedCount' => $counts['evacuated'] ?? 0,
            'recentAlerts'   => $this->model->getRecentAlerts() ?? [],
            'timeline'       => $timeline ?? [], // New activity log data
            'adminCoords'    => [
                'latitude'  => $adminData['latitude'] ?? '',
                'longitude' => $adminData['longitude'] ?? ''
            ]
        ];
    }

    /**
     * Internal helper to process JSON location payload
     */
    private function handleLocationUpdate() {
        header('Content-Type: application/json');
        $adminId = $_SESSION['admin_id'] ?? null;
        
        if (!$adminId) { 
            echo json_encode(['status' => 'error', 'message' => 'Unauthorized']); 
            return; 
        }

        $json = file_get_contents('php://input');
        $data = json_decode($json, true);

        if (!$data || !isset($data['lat'], $data['lng'])) { 
            echo json_encode(['status' => 'error', 'message' => 'Invalid data']); 
            return; 
        }

        try {
            $query = "UPDATE evacuways_admins SET 
                        latitude = ?, 
                        longitude = ?, 
                        region_code = ?, 
                        city_code = ?, 
                        barangay_code = ? 
                      WHERE admin_id = ?";
                      
            $stmt = $this->db->prepare($query);
            $success = $stmt->execute([
                $data['lat'], 
                $data['lng'], 
                $data['region'] ?? null, 
                $data['city'] ?? null, 
                $data['brgy'] ?? null, 
                $adminId
            ]);

            echo json_encode(['status' => $success ? 'success' : 'error']);
        } catch (PDOException $e) {
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
    }
}