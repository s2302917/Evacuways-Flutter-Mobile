<?php
// --- FORCE SERVER TO CLEAR CACHE ---
if (function_exists('opcache_reset')) {
    opcache_reset(); 
}
// -----------------------------------

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php'; 
require_once __DIR__ . '/../models/FamilyModel.php';

class FamilyController {
    private $familyModel;
    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->connect(); 
        $this->familyModel = new FamilyModel($this->db);
    }

    public function index() {
        return $this->familyModel->getAll();
    }

    public function getCenters() {
        $stmt = $this->db->query("SELECT center_id, center_name, barangay_name, capacity, current_individuals, status FROM evacuways_centers WHERE status = 'Open'");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getVehicles() {
        $stmt = $this->db->query("SELECT vehicle_id, vehicle_type, plate_number, capacity, status FROM evacuways_vehicles");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function handleRequest() {
        // --- GET REQUESTS ---
        if (isset($_GET['delete'])) {
            $this->familyModel->delete($_GET['delete']);
            $this->redirect('families.php');
        }

        // --- POST REQUESTS ---
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            
            // 1. Create Individual Family/User
            if (isset($_POST['create_family'])) {
                $firstName = $_POST['first_name'] ?? '';
                $lastName = $_POST['last_name'] ?? '';

                $this->familyModel->create(
                    $firstName, 
                    $lastName, 
                    $_POST['contact_number'], 
                    $_POST['barangay_code'], 
                    $_POST['headcount'],
                    $_POST['missing_count'],
                    $_POST['latitude'] ?? null,
                    $_POST['longitude'] ?? null
                );
                $this->redirect('families.php');
            }

            // 2. Update Existing Record
            if (isset($_POST['update_family'])) {
                $this->familyModel->update(
                    $_POST['user_id'], 
                    $_POST['rescue_status'], 
                    $_POST['missing_count'], 
                    $_POST['assigned_vehicle_id'] ?? null,
                    $_POST['assigned_center_id'] ?? null
                );
                $this->redirect('families.php');
            }

            // 3. Convert Single Individual to Family
            if (isset($_POST['mark_as_family'])) {
                $userId = $_POST['user_id'];
                $headcount = $_POST['headcount'];
                
                if ($this->familyModel->convertToFamily($userId, $headcount)) {
                    header("Location: families.php?success=converted");
                    exit();
                }
            }

            // 4. BATCH GROUPING: Create Family Group from selected users
            if (isset($_POST['create_batch_family'])) {
                // selected_user_ids comes from the hidden input in your "Group Builder" modal
                $userIds = explode(',', $_POST['selected_user_ids']); 
                
                $familyData = [
                    'family_name' => $_POST['family_name'],
                    'family_contact' => $_POST['family_contact'],
                    'family_status' => $_POST['family_status'],
                    'headcount' => count($userIds)
                ];

                // Note: using $this->familyModel as defined in __construct
                $newFamilyId = $this->familyModel->createFamilyGroup($familyData);
                
                if ($newFamilyId) {
                    $this->familyModel->updateUsersFamily($userIds, $newFamilyId);
                    header("Location: families.php?success=GroupCreated");
                    exit();
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