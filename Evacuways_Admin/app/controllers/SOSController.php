<?php
require_once __DIR__ . "/../models/SOSModel.php";

class SOSController {
    private $model;

    public function __construct() {
        $this->model = new SOSModel();
    }

    /**
     * Main index for the SOS page
     */
    public function index($statusFilter = null) {
        return $this->model->getSOSRequests($statusFilter);
    }

    /**
     * Get stats for the SOS dashboard header
     */
    public function stats() {
        return $this->model->getCounts();
    }

    /**
     * Handle incoming status update requests
     */
    public function handleRequest() {
        // Handle AJAX polling for new SOS
        if (isset($_GET['action']) && $_GET['action'] === 'check') {
            header('Content-Type: application/json');
            $lastId = isset($_GET['last_id']) ? intval($_GET['last_id']) : 0;
            echo json_encode($this->checkNewSOS($lastId));
            exit();
        }

        // Handle Resolve action
        if (isset($_GET['resolve_id'])) {
            $id = $_GET['resolve_id'];
            $source = $_GET['source'] ?? 'support';
            if ($this->model->updateStatus($id, 'Resolved', $source)) {
                header("Location: sos.php?success=Incident marked as Resolved");
                exit();
            }
        }

        // Handle Delete action
        if (isset($_GET['delete_id'])) {
            $id = $_GET['delete_id'];
            $source = $_GET['source'] ?? 'support';
            if ($this->model->deleteSOS($id, $source)) {
                header("Location: sos.php?success=Incident deleted successfully");
                exit();
            } else {
                header("Location: sos.php?error=Failed to delete incident");
                exit();
            }
        }

        // Handle POST updates
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            // Handle Status Update
            if (isset($_POST['update_status']) && isset($_POST['request_id'])) {
                $id = $_POST['request_id'];
                $status = $_POST['update_status'];
                $source = $_POST['source'] ?? 'support';
                if ($this->model->updateStatus($id, $status, $source)) {
                    header("Location: sos.php?success=Status updated to $status");
                    exit();
                }
            }

            // Handle Edit (Message/Type)
            if (isset($_POST['action']) && $_POST['action'] === 'edit' && isset($_POST['request_id'])) {
                $id = $_POST['request_id'];
                $source = $_POST['source'] ?? 'support';
                $data = [
                    'message' => $_POST['message'] ?? null,
                    'request_type' => $_POST['request_type'] ?? null,
                    'subject' => $_POST['subject'] ?? null
                ];
                if ($this->model->editSOS($id, $data, $source)) {
                    header("Location: sos.php?success=Incident details updated");
                    exit();
                } else {
                    header("Location: sos.php?error=No changes made or update failed");
                    exit();
                }
            }
        }
    }

    /**
     * AJAX endpoint for polling new SOS requests
     */
    public function checkNewSOS($lastSeenId) {
        $latestId = $this->model->getLatestPendingId();
        if ($latestId > $lastSeenId) {
            // Fetch the details of the latest one for the popup
            $all = $this->model->getSOSRequests('Pending');
            $latest = !empty($all) ? $all[0] : null;
            
            return [
                'new_found' => true,
                'latest_id' => (int)$latestId,
                'name' => $latest ? ($latest['first_name'] . ' ' . $latest['last_name']) : 'Unknown victim',
                'type' => $latest ? $latest['request_type'] : 'SOS'
            ];
        }
        return ['new_found' => false, 'latest_id' => (int)$lastSeenId];
    }
}
?>
