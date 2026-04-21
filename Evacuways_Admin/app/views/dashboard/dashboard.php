<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
session_start();

// 1. Security check
if (!isset($_SESSION['admin_id'])) {
    header("Location: ../../../index.php");
    exit();
}

// 2. Bridge to the Controller
require_once __DIR__ . "/../../controllers/DashboardController.php";
$controller = new DashboardController();
$data = $controller->index();

/**
 * DATA PREPARATION
 * Ensuring coordinates exist before rendering to prevent the "Stuck Modal" issue.
 */
$adminLat = $data['adminCoords']['latitude'] ?? '';
$adminLng = $data['adminCoords']['longitude'] ?? '';

// Check if location is fully set to control modal visibility
$hasLocation = (!empty($adminLat) && !empty($adminLng));
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard | EvacuWays Admin</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Sharp" />
    <link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css" />
    <link rel="stylesheet" href="../../../public/css/style.css">
</head>
<body>

<div class="container">
    <aside>
        <div class="top">
            <div class="logo">
                <img src="../../../public/images/logo.png" alt="Logo">
                <h2>EvacuWays <span class="danger">Admin</span></h2>
            </div>
            <div class="close" id="close_btn"><span class="material-symbols-sharp">close</span></div>
        </div>

       <div class="sidebar">
            <a href="dashboard.php" class="active"><span class="material-symbols-sharp">grid_view</span><h3>Dashboard</h3></a>
            <a href="../alerts/alerts.php"><span class="material-symbols-sharp">warning</span><h3>Emergency Alerts</h3></a>
            <a href="../sos/sos.php"><span class="material-symbols-sharp">emergency</span><h3>Emergency SOS</h3></a>
            <a href="../vechicles/vehicles.php"><span class="material-symbols-sharp">airport_shuttle</span><h3>Evacuation Vehicles</h3></a>
            <a href="../centers/centers.php"><span class="material-symbols-sharp">location_city</span><h3>Evacuation Centers</h3></a>
            <a href="../families/families.php"><span class="material-symbols-sharp">groups</span><h3>Registered Families</h3></a>
            <a href="../checklists/checklists.php"><span class="material-symbols-sharp">assignment_turned_in</span><h3>Safety Checklists</h3></a>
            <a href="../volunteers/volunteers.php"><span class="material-symbols-sharp">volunteer_activism</span><h3>Volunteers</h3></a>
            <a href="../messages/messages.php"><span class="material-symbols-sharp">mail</span><h3>Messages</h3></a>
            <a href="../settings/settings.php"><span class="material-symbols-sharp">settings</span><h3>Settings</h3></a>
            <a href="../../auth/logout.php"><span class="material-symbols-sharp">logout</span><h3>Logout</h3></a>
        </div>
    </aside>

    <main>
        <h1>Disaster Response Dashboard</h1>

        <div class="insights">
            <div class="card">
                <span class="material-symbols-sharp">warning</span>
                <h3>Active Alerts</h3>
                <h1><?= htmlspecialchars($data['alertCount'] ?? 0) ?></h1>
                <small>Action Required</small>
            </div>
            <div class="card">
                <span class="material-symbols-sharp">airport_shuttle</span>
                <h3>Total Vehicles</h3>
                <h1><?= htmlspecialchars($data['vehicleCount'] ?? 0) ?></h1>
                <small>Total Fleet</small>
            </div>
            <div class="card">
                <span class="material-symbols-sharp">location_city</span>
                <h3>Open Centers</h3>
                <h1><?= htmlspecialchars($data['cityCount'] ?? 0) ?></h1>
                <small>Active Sectors</small>
            </div>
        </div>

        <div class="chart-container-full">
            <h2>Live User Map</h2>
            <div id="userMap"></div>
        </div>

        <div class="charts-grid">
            <div class="chart-box">
                <h2>User Registration Trend</h2>
                <canvas id="evacuationChart"></canvas>
            </div>
            <div class="chart-box">
                <h2>Rescue Status</h2>
                <canvas id="rescueChart"></canvas>
            </div>
        </div>

        <div class="recent_alerts">
            <h2>Recent Emergency Alerts</h2>
            <table>
                <thead>
                    <tr><th>Title</th><th>Type</th><th>Status</th><th>Date</th></tr>
                </thead>
                <tbody>
                    <?php if(empty($data['recentAlerts'])): ?>
                        <tr><td colspan="4">No active alerts found.</td></tr>
                    <?php else: ?>
                        <?php foreach($data['recentAlerts'] as $alert): ?>
                            <tr>
                                <td><?= htmlspecialchars($alert['title']) ?></td>
                                <td><?= htmlspecialchars($alert['alert_type']) ?></td>
                                <td class="danger"><?= htmlspecialchars($alert['status']) ?></td>
                                <td><?= date('M d', strtotime($alert['created_at'])) ?></td>
                            </tr>
                        <?php endforeach; ?>
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
            <h2>Real-time Stats</h2>
            <div class="stat">
                <span class="material-symbols-sharp">groups</span>
                <div><h3>Registered</h3><p><b><?= htmlspecialchars($data['totalUsers'] ?? 0) ?></b></p></div>
            </div>
            <div class="stat">
                <span class="material-symbols-sharp">check_circle</span>
                <div><h3>Evacuated</h3><p><b><?= htmlspecialchars($data['evacuatedCount'] ?? 0) ?></b></p></div>
            </div>
        </div>
    </div>
</div>

<div id="locationModal" class="modal-overlay" style="display: none;">
    <div class="modal-content">
        <h2>Set Admin Headquarters</h2>
        <p>Please provide your location to initialize the disaster map.</p>
        <div class="form-group">
            <select id="regionSelect" onchange="LocationHandler.loadCities(this.value, 'citySelect')">
                <option value="">Select Region</option>
            </select>
            <select id="citySelect" onchange="LocationHandler.loadBarangays(this.value, 'brgySelect')">
                <option value="">Select City/Municipality</option>
            </select>
            <select id="brgySelect">
                <option value="">Select Barangay</option>
            </select>
        </div>
        <button id="saveLocationBtn" class="btn-submit">Initialize Map & Save</button>
    </div>
</div>

<div id="dashboard-data" 
     style="display:none;" 
     data-has-location="<?= (!empty($adminLat) && !empty($adminLng)) ? 'true' : 'false' ?>"
     data-admin-lat="<?= htmlspecialchars($adminLat) ?>"
     data-admin-lng="<?= htmlspecialchars($adminLng) ?>"
     data-total="<?= (int)($data['totalUsers'] ?? 0) ?>"
     data-evacuated="<?= (int)($data['evacuatedCount'] ?? 0) ?>">
</div>

<script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script src="../../../public/js/location_handler.js"></script> 
<script src="../../../public/js/script.js"></script>
</body>
</html>