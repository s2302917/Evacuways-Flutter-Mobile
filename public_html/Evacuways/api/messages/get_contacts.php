<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_contacts.php - Fetch categories of messageable users
$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;

try {
    $database = new Database();
    $db = $database->connect();

    // Query to get all users from evacuways_users + admins from evacuways_admins
    $query = "
        (SELECT user_id, first_name, last_name, role, barangay_code, created_at 
         FROM evacuways_users 
         WHERE user_id != :uid)
        UNION ALL
        (SELECT admin_id as user_id, full_name as first_name, '' as last_name, 'admin' as role, NULL as barangay_code, created_at 
         FROM evacuways_admins)
        ORDER BY role ASC, first_name ASC";
    
    $stmt = $db->prepare($query);
    if (isset($user_id)) {
        $stmt->bindParam(':uid', $user_id);
    } else {
        $dummy = 0;
        $stmt->bindParam(':uid', $dummy);
    }
    $stmt->execute();
    
    $contacts = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Grouping logic for the UI
    $grouped = [
        "admins" => [],
        "volunteers" => [],
        "drivers" => [],
        "personnel" => [],
        "community" => []
    ];

    foreach ($contacts as $contact) {
        $role = strtolower($contact['role'] ?? '');
        if ($role === 'admin') {
            $grouped['admins'][] = $contact;
        } elseif ($role === 'volunteer') {
            $grouped['volunteers'][] = $contact;
        } elseif ($role === 'vehicle driver' || $role === 'driver') {
            $grouped['drivers'][] = $contact;
        } elseif ($role === 'personnel') {
            $grouped['personnel'][] = $contact;
        } else {
            $grouped['community'][] = $contact;
        }
    }

    http_response_code(200);
    echo json_encode(["success" => true, "contacts" => $grouped]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
}
?>
