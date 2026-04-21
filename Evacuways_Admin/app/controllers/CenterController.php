<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php'; 
require_once __DIR__ . '/../models/CenterModel.php';
require_once __DIR__ . '/../models/UserModel.php';

class CenterController {
    private $centerModel;
    private $userModel;
    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->connect(); 
        $this->centerModel = new CenterModel($this->db);
        $this->userModel = new UserModel();
    }

    public function index() {
        return $this->centerModel->getAll();
    }

    public function getStatusStats() {
        $data = $this->centerModel->getStatusStats();
        $labels = [];
        $values = [];
        
        foreach($data as $row) {
            $labels[] = $row['status'];
            $values[] = (int)$row['count'];
        }

        return [
            'labels' => $labels,
            'values' => $values
        ];
    }

    public function handleRequest() {
        if (isset($_POST['create_center'])) {
            // Smart fallback: Check for 'center_name', if missing, grab 'name' from the cached form
            $centerName = $_POST['center_name'] ?? $_POST['name'] ?? '';

            $this->centerModel->create(
                $centerName, 
                $_POST['capacity'], 
                $_POST['barangay_name'],
                $_POST['status'],
                $_POST['contact_person'],
                $_POST['contact_number'],
                $_POST['latitude'] ?? null,
                $_POST['longitude'] ?? null
            );

            // Automatically create a user account for the center
            $this->userModel->createAccount(
                $_POST['contact_number'], 
                'Center',
                $_POST['contact_person'],
                $centerName // Use center name as last name or similar
            );

            $this->redirect('centers.php');
        }

        if (isset($_POST['update_center'])) {
            // Smart fallback for update as well
            $centerName = $_POST['center_name'] ?? $_POST['name'] ?? '';

            $this->centerModel->update(
                $_POST['center_id'], 
                $centerName, 
                $_POST['capacity'], 
                $_POST['barangay_name'],
                $_POST['status'],
                $_POST['contact_person'],
                $_POST['contact_number'],
                $_POST['latitude'] ?? null,
                $_POST['longitude'] ?? null
            );
            $this->redirect('centers.php');
        }

        if (isset($_GET['delete'])) {
            $this->centerModel->delete($_GET['delete']);
            $this->redirect('centers.php');
        }
    }

    private function redirect($url) {
        header("Location: $url");
        exit();
    }
}