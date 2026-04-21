<?php
require_once __DIR__ . "/../../config/database.php";

$database = new Database();
$db = $database->connect();

try {
    // Clear existing checklists and items to start fresh (templates only)
    $db->exec("DELETE FROM evacuways_checklist_items");
    $db->exec("DELETE FROM evacuways_checklists WHERE user_id = 0 OR user_id IS NULL");

    // Sample Checklists Data
    $checklists = [
        [1, 'Typhoon Preparedness', 'Essential preparations before typhoon season hits', 0, 0, 0, 'Family'],
        [2, 'Medical Kit Essentials', 'Complete medical kit for emergency situations', 0, 0, 0, 'Family'],
        [3, 'Elderly Care Protocol', 'Special care requirements for elderly family members', 0, 1, 0, 'Family'],
        [4, 'PWD (Persons with Disabilities) Care', 'Support and equipment needed for PWD members', 0, 0, 1, 'Family'],
        [5, 'Children Safety Pack', 'Safety items and documents for children', 1, 0, 0, 'Family'],
        [6, 'Family Emergency Kit', 'General family emergency supplies', 0, 0, 0, 'Family'],
        [7, 'Pet Safety Guide', 'Pet protection during disasters', 0, 0, 0, 'Family'],
        [8, 'Document Backup Protocol', 'Important documents to secure', 0, 0, 0, 'Family']
    ];

    $checkStmt = $db->prepare("INSERT INTO evacuways_checklists (checklist_id, checklist_name, description, for_children, for_elderly, for_pwd, target_role, user_id) VALUES (?, ?, ?, ?, ?, ?, ?, 0)");

    foreach ($checklists as $c) {
        $checkStmt->execute($c);
    }

    // Sample Items Data
    $items = [
        [1, 1, 'Secure windows and doors - Check for cracks and ensure locks work'],
        [2, 1, 'Clear drainages - Remove debris from gutters and storm drains'],
        [3, 1, 'Charge power banks - Ensure all portable chargers are full'],
        [4, 1, 'Prepare emergency bag - Include food, water, and medicine'],
        [5, 1, 'Identify evacuation route - Know at least 2 exits from your area'],
        [6, 1, 'Stock up on drinking water - 1 liter per person per day'],
        [7, 1, 'Prepare non-perishable food - Canned goods, biscuits'],
        [8, 1, 'Check flashlights and batteries - Replace old batteries'],
        [9, 1, 'Secure outdoor items - Remove or tie down loose objects'],
        [10, 1, 'Backup important documents - Keep originals in waterproof bag'],
        [11, 2, 'First aid kit - Bandages, gauze, medical tape, antiseptic'],
        [12, 2, 'Pain relievers - Ibuprofen, acetaminophen for fever'],
        [13, 2, 'Antihistamines - For allergies and severe itching'],
        [14, 2, 'Antacid - For stomach upset and indigestion'],
        [15, 2, 'Antibacterial ointment - For wound care and infections'],
        [16, 2, 'Thermometer - Digital or mercury thermometer'],
        [17, 2, 'CPR face shield - For CPR if needed'],
        [18, 2, 'Medical gloves - Latex or nitrile medical gloves'],
        [19, 2, 'Prescription medications - Keep 7-day supply in original container'],
        [20, 2, 'Medical history document - List of allergies, medications'],
        [21, 3, 'Collect prescription medications - 7-day supply in organizers'],
        [22, 3, 'Prepare mobility aids - Wheelchairs, canes, walkers'],
        [23, 3, 'Medical alert document - Heart conditions, diabetes details'],
        [24, 3, 'Hearing aid batteries - Stock up on extra batteries'],
        [25, 3, 'Eyeglasses spare pairs - Keep backup glasses in safe place']
    ];

    $itemStmt = $db->prepare("INSERT INTO evacuways_checklist_items (item_id, checklist_id, item_description) VALUES (?, ?, ?)");
    foreach ($items as $i) {
        $itemStmt->execute($i);
    }

    echo "Successfully seeded " . count($checklists) . " checklists and " . count($items) . " items.";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
