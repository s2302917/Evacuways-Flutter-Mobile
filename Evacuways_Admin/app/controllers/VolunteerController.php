<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php'; 
require_once __DIR__ . '/../models/VolunteerModel.php';
require_once __DIR__ . '/../models/UserModel.php';

class VolunteerController {
    private $volunteerModel;
    private $userModel;
    private $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->connect(); 
        $this->volunteerModel = new VolunteerModel($this->db);
        $this->userModel = new UserModel();
    }

    public function index() {
        return $this->volunteerModel->getAll();
    }

    public function handleRequest() {
        if (isset($_POST['create_volunteer'])) {
            $firstName = $_POST['first_name'];
            $lastName = $_POST['last_name'];
            $contactNumber = $_POST['contact_number'];
            $skills = $_POST['skills'];

            // 1. Create a user account first
            $this->userModel->createAccount($contactNumber, 'Volunteer', $firstName, $lastName);

            // 2. Fetch the user_id for the newly created user
            $query = "SELECT user_id FROM evacuways_users WHERE contact_number = :contact_number LIMIT 1";
            $stmt = $this->db->prepare($query);
            $stmt->execute([':contact_number' => $contactNumber]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($user) {
                // 3. Create the volunteer record
                $this->volunteerModel->create($user['user_id'], $skills);
            }

            $this->redirect('volunteers.php');
        }

        if (isset($_GET['delete'])) {
            $this->volunteerModel->delete($_GET['delete']);
            $this->redirect('volunteers.php');
        }
    }

    private function redirect($url) {
        header("Location: $url");
        exit();
    }
}
?>
