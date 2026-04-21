<?php
require_once __DIR__ . "/../models/ChecklistModel.php";

class ChecklistController {
    private $model;

    public function __construct() {
        $this->model = new ChecklistModel();
    }

    public function handleRequest() {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            
            // Create New Checklist
            if (isset($_POST['create_checklist'])) {
                $name = $_POST['checklist_name'] ?? '';
                $desc = $_POST['description'] ?? '';
                $target = $_POST['target_role'] ?? 'Family';
                $children = isset($_POST['for_children']) ? 1 : 0;
                $elderly = isset($_POST['for_elderly']) ? 1 : 0;
                $pwd = isset($_POST['for_pwd']) ? 1 : 0;

                if (!empty($name)) {
                    $this->model->createChecklist($name, $desc, $target, $children, $elderly, $pwd);
                    header("Location: checklists.php?success=Checklist created");
                    exit();
                }
            }

            // Update Checklist
            if (isset($_POST['edit_checklist'])) {
                $id = $_POST['update_checklist_id'] ?? 0;
                $name = $_POST['checklist_name'] ?? '';
                $desc = $_POST['description'] ?? '';
                $target = $_POST['target_role'] ?? 'Family';
                $children = isset($_POST['for_children']) ? 1 : 0;
                $elderly = isset($_POST['for_elderly']) ? 1 : 0;
                $pwd = isset($_POST['for_pwd']) ? 1 : 0;

                if ($id && !empty($name)) {
                    $this->model->updateChecklist($id, $name, $desc, $target, $children, $elderly, $pwd);
                    header("Location: checklists.php?success=Protocol Updated");
                    exit();
                }
            }

            // Update Item
            if (isset($_POST['update_item_id'])) {
                $itemId = $_POST['update_item_id'] ?? 0;
                $description = $_POST['item_description'] ?? '';

                if ($itemId && !empty($description)) {
                    $this->model->updateItem($itemId, $description);
                    header("Location: checklists.php?success=Step Updated");
                    exit();
                }
            }

            // Add Item to Checklist
            if (isset($_POST['add_item'])) {
                $checklistId = $_POST['checklist_id'] ?? 0;
                $itemDesc = $_POST['item_description'] ?? '';

                if ($checklistId && !empty($itemDesc)) {
                    $this->model->addItem($checklistId, $itemDesc);
                    header("Location: checklists.php?success=Item added");
                    exit();
                }
            }
        }

        // Delete Checklist
        if (isset($_GET['delete_checklist'])) {
            $id = intval($_GET['delete_checklist']);
            if ($id) {
                $this->model->deleteChecklist($id);
                header("Location: checklists.php?success=Checklist deleted");
                exit();
            }
        }

        // Delete Item
        if (isset($_GET['delete_item'])) {
            $id = intval($_GET['delete_item']);
            if ($id) {
                $this->model->deleteItem($id);
                header("Location: checklists.php?success=Item deleted");
                exit();
            }
        }
    }

    public function index($search = '') {
        return $this->model->getTemplates($search);
    }

    public function getItems($id) {
        return $this->model->getChecklistItems($id);
    }

    public function stats() {
        return $this->model->getCompletionStats();
    }
}
?>
