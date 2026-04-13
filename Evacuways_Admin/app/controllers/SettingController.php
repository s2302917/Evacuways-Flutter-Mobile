<?php
if (function_exists('opcache_reset')) {
    opcache_reset(); 
}

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php'; 
require_once __DIR__ . '/../models/SettingModel.php';

class SettingController {
    private $settingModel;
    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->connect(); 
        $this->settingModel = new SettingModel($this->db);
    }

    // Fetch admin data for the view
    public function getAdmin($adminId) {
        return $this->settingModel->getAdminData($adminId);
    }

    public function handleRequest() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            
            if (isset($_POST['update_settings'])) {
                // Using session admin_id or fallback to 1 for testing
                $adminId = $_SESSION['admin_id'] ?? 1; 

                // --- NEW SECURITY CHECK: Verify Current Password ---
                $oldPassword = $_POST['old_password'] ?? '';
                $currentAdmin = $this->settingModel->getAdminData($adminId);

                // If admin doesn't exist or password doesn't match the hash in the DB
                if (!$currentAdmin || !password_verify($oldPassword, $currentAdmin['password_hash'])) {
                    $this->redirect("settings.php?error=invalid_password");
                }
                // --- END SECURITY CHECK ---

                $data = [
                    'full_name' => trim($_POST['full_name']),
                    'email' => trim($_POST['email']),
                    'latitude' => $_POST['latitude'],
                    'longitude' => $_POST['longitude'],
                    'region_code' => $_POST['region_code'],
                    'city_code' => $_POST['city_code'],
                    'barangay_code' => $_POST['barangay_code'],
                    'password_hash' => null
                ];

                // Check if admin wants to update their password to a NEW one
                if (!empty($_POST['password'])) {
                    $data['password_hash'] = password_hash($_POST['password'], PASSWORD_DEFAULT);
                }

                if ($this->settingModel->updateAdminProfile($adminId, $data)) {
                    $this->redirect("settings.php?success=1");
                } else {
                    $this->redirect("settings.php?error=update_failed");
                }
            }
        }
    }

    private function redirect($url) {
        header("Location: $url");
        exit();
    }
}
?>