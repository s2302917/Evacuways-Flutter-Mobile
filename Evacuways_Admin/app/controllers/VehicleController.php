<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php'; 
require_once __DIR__ . '/../models/VehicleModel.php';
require_once __DIR__ . '/../models/UserModel.php';

class VehicleController {
    private $vehicleModel;
    private $userModel;
    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->connect(); 
        $this->vehicleModel = new VehicleModel($this->db);
        $this->userModel = new UserModel();
    }

    public function index() {
        return $this->vehicleModel->getAll();
    }

    public function getStatusStats() {
        $data = $this->vehicleModel->getStatusStats();
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
        if (isset($_POST['create_vehicle'])) {
            $this->vehicleModel->create(
                $_POST['vehicle_type'], 
                $_POST['plate_number'], 
                $_POST['capacity'], 
                $_POST['barangay_name'],
                $_POST['landmark'],
                $_POST['status'],
                $_POST['driver_name'],
                $_POST['driver_contact'],
                $_POST['latitude'] ?? null,
                $_POST['longitude'] ?? null
            );

            // Automatically create a user account for the driver
            $this->userModel->createAccount(
                $_POST['driver_contact'], 
                'Driver',
                $_POST['driver_name'],
                $_POST['vehicle_type'] . " (" . $_POST['plate_number'] . ")"
            );

            $this->redirect('vehicles.php');
        }

        if (isset($_POST['update_vehicle'])) {
            $this->vehicleModel->update(
                $_POST['vehicle_id'], 
                $_POST['vehicle_type'], 
                $_POST['plate_number'], 
                $_POST['capacity'], 
                $_POST['barangay_name'],
                $_POST['landmark'],
                $_POST['status'],
                $_POST['driver_name'],
                $_POST['driver_contact'],
                $_POST['latitude'] ?? null,
                $_POST['longitude'] ?? null
            );
            $this->redirect('vehicles.php');
        }

        if (isset($_GET['delete'])) {
            $this->vehicleModel->delete($_GET['delete']);
            $this->redirect('vehicles.php');
        }
    }

    private function redirect($url) {
        header("Location: $url");
        exit();
    }
}