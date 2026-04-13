<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php'; 
require_once __DIR__ . '/../models/AlertModel.php';

class AlertController {
    private $alertModel;
    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->connect(); 
        $this->alertModel = new AlertModel($this->db);
    }

    /**
     * Fetches all alerts for the table view
     */
    public function index() {
        return $this->alertModel->getAll();
    }

    /**
     * Prepares data for Monthly Alerts Chart (Line Chart)
     */
    public function getMonthlyStats() {
        $data = $this->alertModel->getAlertsPerMonth();
        $months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        $chartData = array_fill_keys($months, 0);

        foreach($data as $row) {
            if (isset($chartData[$row['month']])) {
                $chartData[$row['month']] = (int)$row['count'];
            }
        }

        return [
            'labels' => array_keys($chartData),
            'values' => array_values($chartData)
        ];
    }
    
    /**
     * Prepares data for Alert Type Distribution Chart (Doughnut Chart)
     */
    public function getTypeStats() {
        $data = $this->alertModel->getAlertsByType();
        $labels = [];
        $values = [];
        
        foreach($data as $row) {
            $labels[] = $row['type'];
            $values[] = (int)$row['count'];
        }

        return [
            'labels' => $labels,
            'values' => $values
        ];
    }

    /**
     * Resolves the current admin's city code for UI display/LocationHandler
     */
    public function getAdminCityCode() {
        if (!empty($_SESSION['city_code'])) {
            return $_SESSION['city_code'];
        }

        if (!empty($_SESSION['city_id'])) {
            $query = "SELECT city_code FROM evacuways_cities WHERE city_id = :city_id LIMIT 1";
            $stmt = $this->db->prepare($query);
            $stmt->execute([':city_id' => $_SESSION['city_id']]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            return $row ? $row['city_code'] : '';
        }

        return '';
    }

    /**
     * Core Request Handler for Create, Update, and Delete actions
     */
    public function handleRequest() {
        $admin_id = $_SESSION['admin_id'] ?? null; 
        $admin_city_id = $_SESSION['city_id'] ?? $_SESSION['city_code'] ?? null; 

        // Handle Create Alert
        if (isset($_POST['create_alert'])) {
            // Safety fallback if JS didn't capture the name
            $brgyName = !empty($_POST['barangay_name']) ? $_POST['barangay_name'] : 'Selected Barangay';

            $this->alertModel->create(
                $_POST['title'], 
                $_POST['message'], 
                $_POST['alert_type'], 
                $_POST['severity_level'],
                $_POST['status'],
                $admin_city_id, 
                $_POST['barangay_id'],   // PSGC Code
                $brgyName,               // Saved as Text
                $admin_id
            );
            $this->redirect('alerts.php');
        }

        // Handle Update Alert
        if (isset($_POST['update_alert'])) {
            // Safety fallback if JS didn't capture the name
            $brgyName = !empty($_POST['barangay_name']) ? $_POST['barangay_name'] : 'Updated Barangay';

            $this->alertModel->update(
                $_POST['alert_id'], 
                $_POST['title'], 
                $_POST['message'], 
                $_POST['alert_type'], 
                $_POST['severity_level'],
                $_POST['status'],
                $admin_city_id, 
                $_POST['barangay_id'],    // PSGC Code
                $brgyName                 // Updated Text
            );
            $this->redirect('alerts.php');
        }

        // Handle Delete Alert
        if (isset($_GET['delete'])) {
            $this->alertModel->delete($_GET['delete']);
            $this->redirect('alerts.php');
        }
    }

    /**
     * Helper for redirection
     */
    private function redirect($url) {
        header("Location: $url");
        exit();
    }
}