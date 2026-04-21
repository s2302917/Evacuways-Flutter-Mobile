<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . "/../../../app/controllers/VolunteerController.php";
$volunteerController = new VolunteerController();

$volunteerController->handleRequest();
$volunteers = $volunteerController->index();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Volunteer Management | Evacuways Admin</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Sharp" />
    <link rel="stylesheet" href="../../../public/css/style.css?v=<?php echo time(); ?>">
</head>
<body>

<div class="container">
    <aside>
        <div class="top">
            <div class="logo">
                <img src="../../../public/images/logo.png" alt="Evacuways Logo" class="logo-img">
                <h2>Evacuways Admin</h2>
            </div>
            <div class="close" id="close_btn">
                <span class="material-symbols-sharp">close</span>
            </div>
        </div>

        <div class="sidebar">
            <a href="../../views/dashboard/dashboard.php"><span class="material-symbols-sharp">grid_view</span><h3>Dashboard</h3></a>
            <a href="../alerts/alerts.php"><span class="material-symbols-sharp">warning</span><h3>Emergency Alerts</h3></a>
            <a href="../vechicles/vehicles.php"><span class="material-symbols-sharp">airport_shuttle</span><h3>Evacuation Vehicles</h3></a>
            <a href="../centers/centers.php"><span class="material-symbols-sharp">location_city</span><h3>Evacuation Centers</h3></a>
            <a href="../families/families.php"><span class="material-symbols-sharp">groups</span><h3>Registered Families</h3></a>
            <a href="../checklists/checklists.php"><span class="material-symbols-sharp">assignment_turned_in</span><h3>Safety Checklists</h3></a>
            <a href="volunteers.php" class="active"><span class="material-symbols-sharp">volunteer_activism</span><h3>Volunteers</h3></a>
            <a href="../messages/messages.php"><span class="material-symbols-sharp">mail</span><h3>Messages</h3></a>
            <a href="../settings/settings.php"><span class="material-symbols-sharp">settings</span><h3>Settings</h3></a>
            <a href="../../auth/logout.php"><span class="material-symbols-sharp">logout</span><h3>Logout</h3></a>
        </div>
    </aside>

    <main>
        <h1>Volunteer Management</h1>
        
        <div class="form-container">
            <h3>Register New Volunteer</h3>
            <form action="volunteers.php" method="POST" class="form-group-wrapper">
                
                <div class="grid-3-col">
                    <div class="input-box">
                        <p>First Name</p>
                        <input type="text" name="first_name" placeholder="John" required>
                    </div>
                    <div class="input-box">
                        <p>Last Name</p>
                        <input type="text" name="last_name" placeholder="Doe" required>
                    </div>
                    <div class="input-box">
                        <p>Contact Number</p>
                        <input type="text" name="contact_number" placeholder="e.g. 09123456789" required>
                    </div>
                </div>

                <div class="grid-1-col">
                    <div class="input-box">
                        <p>Skills / Expertise</p>
                        <textarea name="skills" placeholder="e.g. First Aid, Search & Rescue, Logistics" required style="width: 100%; padding: 1rem; border-radius: 8px; border: 1px solid #ddd;"></textarea>
                    </div>
                </div>

                <button type="submit" name="create_volunteer" class="btn-submit">Add Volunteer</button>
            </form>
        </div>

        <div class="recent_alerts">
            <h2>Active Volunteers List</h2>
            <table>
                <thead>
                    <tr>
                        <th>Volunteer Name</th>
                        <th>Contact info</th>
                        <th>Skills</th>
                        <th>Account Status</th>
                        <th class="text-center">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (!empty($volunteers)): ?>
                        <?php foreach($volunteers as $volunteer): ?>
                        <tr>
                            <td>
                                <b><?= htmlspecialchars($volunteer['first_name'] . ' ' . $volunteer['last_name']) ?></b>
                            </td>
                            <td>
                                <?= htmlspecialchars($volunteer['contact_number']) ?>
                            </td>
                            <td>
                                <small class="text-muted"><?= htmlspecialchars($volunteer['skills']) ?></small>
                            </td>
                            <td>
                                <span class="success"><b>Active</b></span>
                            </td>
                            <td class="table-actions">
                                <a href="volunteers.php?delete=<?= $volunteer['volunteer_id'] ?>" class="btn-icon delete" onclick="return confirm('Are you sure you want to remove this volunteer?')">
                                    <span class="material-symbols-sharp">delete</span>
                                </a>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    <?php else: ?>
                        <tr>
                            <td colspan="5" class="empty-table">No volunteers registered yet.</td>
                        </tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </main>

    <div class="right">
        <div class="top">
            <button id="menu_bar"><span class="material-symbols-sharp">menu</span></button>
            <div class="theme-toggler">
                <span class="material-symbols-sharp active">light_mode</span>
                <span class="material-symbols-sharp">dark_mode</span>
            </div>
        </div>
        
        <div class="statistics">
            <h2>Volunteer Summary</h2>
            <div class="stat">
                <span class="material-symbols-sharp">volunteer_activism</span>
                <div>
                    <h3>Total Volunteers</h3>
                    <p><b><?= count($volunteers) ?></b></p>
                </div>
            </div>
        </div>
    </div>
</div>

<script src="../../../public/js/script.js"></script>
</body>
</html>
