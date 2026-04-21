<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . "/../../controllers/SOSController.php";
$controller = new SOSController();

// Handle actions
$controller->handleRequest();

// Get data
$statusFilter = $_GET['status'] ?? null;
$requests = $controller->index($statusFilter);
$allRequests = $controller->index(); // For the "All-Seeing" map
$stats = $controller->stats();

// Get latest ID for polling
$latestId = 0;
if (!empty($allRequests)) {
    foreach($allRequests as $r) {
        if ($r['request_id'] > $latestId && $r['source'] === 'support') $latestId = $r['request_id'];
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Emergency SOS | Evacuways Admin</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Sharp" />
    <link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css" />
    <link rel="stylesheet" href="../../../public/css/style.css?v=<?php echo time(); ?>">
    <style>
        :root {
            /* Fallbacks for older variables if style.css is missing some */
            --sos-danger: #ff7782;
            --sos-success: #41f1b6;
        }

        .container {
            display: grid;
            width: 96%;
            margin: 0 auto;
            gap: 1.8rem;
            grid-template-columns: 14rem auto 23rem;
        }

        main { margin-top: 1.4rem; width: 100%; }
        
        #sosMapContainer {
            height: 450px;
            width: 100%;
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            margin-bottom: 2rem;
            position: relative;
            overflow: hidden;
            background: #eee;
            z-index: 10;
        }

        .sos-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 1.5rem;
            margin-top: 1rem;
        }

        /* Insights Cards */
        .insights {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 1.6rem;
            margin-bottom: 2rem;
        }

        .insights > div {
            background: var(--card-bg);
            padding: 1.5rem;
            border-radius: var(--radius);
            margin-top: 1rem;
            box-shadow: var(--shadow);
            transition: all 300ms ease;
        }

        .insights > div:hover { box-shadow: none; }

        .sos-card {
            background: var(--card-bg);
            padding: 1.5rem;
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            transition: all 0.3s ease;
            position: relative;
            border-top: 6px solid #ccc;
        }

        .sos-card.support { border-top-color: #ff7782; }
        .sos-card.report { border-top-color: #7380ec; }
        .sos-card.missing { border-top-color: #bb6bd9; }

        .source-badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 0.6rem;
            text-transform: uppercase;
            margin-bottom: 5px;
            font-weight: bold;
        }
        .source-badge.support { background: rgba(255, 119, 130, 0.2); color: #ff7782; }
        .source-badge.report { background: rgba(115, 128, 236, 0.2); color: #7380ec; }
        .source-badge.missing { background: rgba(187, 107, 217, 0.2); color: #bb6bd9; }

        .btn-delete { background: rgba(255, 119, 130, 0.1); color: #ff7782; font-size: 0.8rem; padding: 5px; }
        .btn-delete:hover { background: #ff7782; color: white; }
        .btn-edit { background: rgba(115, 128, 236, 0.1); color: #7380ec; font-size: 0.8rem; padding: 5px; }
        .btn-edit:hover { background: #7380ec; color: white; }

        /* Restoration of UI Elements */
        .btn-action {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 10px;
            border-radius: var(--radius-sm);
            cursor: pointer;
            border: none;
            font-weight: 600;
            font-family: inherit;
            transition: 0.2s;
            text-decoration: none;
        }

        .btn-locate { background: var(--primary); color: white; }
        .btn-directions { background: var(--warning); color: white; }
        .btn-resolve { background: var(--success); color: white; width: 100%; margin-top: 15px; }
        .btn-resolve:hover { filter: brightness(0.9); }

        .type-tag {
            display: inline-block;
            background: var(--bg);
            padding: 3px 10px;
            border-radius: 5px;
            font-size: 0.75rem;
            margin-right: 5px;
            margin-top: 5px;
            border: 1px solid var(--border);
        }

        .status-badge {
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.7rem;
            font-weight: 700;
            float: right;
        }
        .status-badge.pending { background: rgba(239, 83, 80, 0.1); color: var(--danger); }
        .status-badge.resolved { background: rgba(76, 175, 80, 0.1); color: var(--success); }

        .sos-popup {
            position: fixed;
            top: 30px;
            right: -450px;
            width: 380px;
            background: var(--card-bg);
            border-radius: var(--radius);
            box-shadow: 0 1rem 3rem rgba(0,0,0,0.3);
            z-index: 10000;
            padding: 20px;
            transition: all 0.6s cubic-bezier(0.68, -0.55, 0.265, 1.55);
            border-left: 10px solid var(--danger);
        }
        .sos-popup.active { right: 30px; }

        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 20000;
            left: 0; top: 0; width: 100%; height: 100%;
            background: rgba(0,0,0,0.5);
            backdrop-filter: blur(5px);
        }
        .modal-content {
            background: var(--card-bg);
            margin: 10% auto;
            padding: 2rem;
            width: 500px;
            border-radius: var(--radius);
            box-shadow: 0 2rem 3rem rgba(0,0,0,0.4);
        }
        .form-group { margin-bottom: 1rem; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: 600; }
        .form-group input, .form-group textarea {
            width: 100%; padding: 10px; border-radius: 5px; border: 1px solid var(--border);
            background: var(--bg); color: var(--text);
        }
    </style>
</head>
<body class="dark-theme-variables">

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
            <a href="../../views/dashboard/dashboard.php"><span class="material-symbols-sharp">grid_view</span><h3>Dashboard</h3></a>
            <a href="../alerts/alerts.php"><span class="material-symbols-sharp">warning</span><h3>Emergency Alerts</h3></a>
            <a href="sos.php" class="active"><span class="material-symbols-sharp">emergency</span><h3>Emergency SOS</h3></a>
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
        <h1>Rescue Operations Dashboard</h1>

        <div class="insights">
            <div>
                <span class="material-symbols-sharp danger pulse" style="background:#ef53501a; padding:10px; border-radius:50%;">wifi_tethering</span>
                <div class="middle">
                    <div class="left">
                        <h3>Pending SOS</h3>
                        <h1><?= $stats['pending'] ?? 0 ?></h1>
                    </div>
                </div>
                <small class="text-muted">Requires Immediate Response</small>
            </div>

            <div>
                <span class="material-symbols-sharp success" style="background:#4caf501a; padding:10px; border-radius:50%;">check_circle</span>
                <div class="middle">
                    <div class="left">
                        <h3>Resolved Case</h3>
                        <h1><?= $stats['resolved'] ?? 0 ?></h1>
                    </div>
                </div>
                <small class="text-muted">Successfully rescued</small>
            </div>

            <div>
                <span class="material-symbols-sharp info" style="background:#29b6f61a; padding:10px; border-radius:50%;">history</span>
                <div class="middle">
                    <div class="left">
                        <h3>Total SOS</h3>
                        <h1><?= $stats['total'] ?? 0 ?></h1>
                    </div>
                </div>
                <small class="text-muted">Total lifecycle reports</small>
            </div>
        </div>

        <div id="sosMapContainer"></div>

        <div class="recent-orders">
            <h2>Incident Management List</h2>
            <div class="sos-grid">
                <?php if (empty($requests)): ?>
                    <p style="padding: 20px;">No SOS requests found in the database.</p>
                <?php else: ?>
                    <?php foreach ($requests as $sos): ?>
                        <div class="sos-card <?= $sos['source'] ?> <?= strtolower($sos['status']) ?>">
                            <div style="display: flex; justify-content: space-between; align-items: start;">
                                <div class="source-badge <?= $sos['source'] ?>"><?= $sos['source'] ?></div>
                                <div style="display: flex; gap: 5px;">
                                    <button onclick="openEditModal('<?= $sos['request_id'] ?>', '<?= $sos['source'] ?>', '<?= addslashes($sos['message']) ?>', '<?= addslashes($sos['request_type']) ?>')" 
                                            class="btn-action btn-edit" title="Edit">
                                        <span class="material-symbols-sharp">edit</span>
                                    </button>
                                    <a href="sos.php?delete_id=<?= $sos['request_id'] ?>&source=<?= $sos['source'] ?>" 
                                       class="btn-action btn-delete" onclick="return confirm('Delete this record?')" title="Delete">
                                        <span class="material-symbols-sharp">delete</span>
                                    </a>
                                </div>
                            </div>

                            <span class="status-badge <?= strtolower($sos['status'] === 'Reported' ? 'pending' : $sos['status']) ?>">
                                <?= $sos['status'] ?>
                            </span>

                            <h3 style="margin-top: 5px;"><?= htmlspecialchars(($sos['first_name'] ?? 'Guest') . ' ' . ($sos['last_name'] ?? 'User')) ?></h3>
                            <p><span class="material-symbols-sharp" style="font-size: 1rem; vertical-align: middle;">location_on</span> barangay ID: <?= htmlspecialchars($sos['barangay_id'] ?? 'Unknown') ?></p>
                            
                            <div style="margin: 1rem 0;">
                                <?php if (!empty($sos['subject']) && $sos['source'] !== 'support'): ?>
                                    <div style="font-weight: 700; margin-bottom: 5px; color: var(--primary);"><?= htmlspecialchars($sos['subject']) ?></div>
                                <?php endif; ?>
                                <?php foreach(explode(',', $sos['request_type']) as $type): ?>
                                    <span class="type-tag"><?= trim($type) ?></span>
                                <?php endforeach; ?>
                            </div>

                            <?php if(!empty($sos['message'])): ?>
                                <div style="background:var(--bg); padding:10px; border-radius:8px; margin-bottom:1rem; font-size:0.9rem; border-left: 3px solid var(--primary);">
                                    "<?= htmlspecialchars($sos['message']) ?>"
                                </div>
                            <?php endif; ?>

                            <div style="display:grid; grid-template-columns:1fr 1fr; gap:10px;">
                                <?php if (floatval($sos['latitude'] ?? 0) != 0 && floatval($sos['longitude'] ?? 0) != 0): ?>
                                    <button class="btn-action btn-locate" 
                                            onclick="centerMap(<?= $sos['latitude'] ?>, <?= $sos['longitude'] ?>, '<?= addslashes($sos['first_name'] ?? 'User') ?>')">
                                        <span class="material-symbols-sharp">my_location</span> Locate
                                    </button>
                                    <a href="https://www.google.com/maps/dir/?api=1&destination=<?= $sos['latitude'] ?>,<?= $sos['longitude'] ?>" 
                                       target="_blank" class="btn-action btn-directions">
                                        <span class="material-symbols-sharp">navigation</span> Directions
                                    </a>
                                <?php else: ?>
                                    <button class="btn-action" disabled style="background:#eee; color:#aaa; cursor:default;">No Location</button>
                                    <button class="btn-action" disabled style="background:#eee; color:#aaa; cursor:default;">No Directions</button>
                                <?php endif; ?>
                            </div>

                            <?php if ($sos['status'] === 'Pending' || $sos['status'] === 'Reported'): ?>
                                <a href="sos.php?resolve_id=<?= $sos['request_id'] ?>&source=<?= $sos['source'] ?>" 
                                   class="btn-action btn-resolve" onclick="return confirm('Mark as resolved?')">
                                    <span class="material-symbols-sharp">done_all</span> Mark Resolved
                                </a>
                            <?php endif; ?>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>
    </main>
</div>

<!-- Edit Modal -->
<div id="editModal" class="modal">
    <div class="modal-content">
        <h2 style="margin-bottom:1.5rem;">Edit Incident Details</h2>
        <form action="sos.php" method="POST">
            <input type="hidden" name="action" value="edit">
            <input type="hidden" name="request_id" id="edit_id">
            <input type="hidden" name="source" id="edit_source">
            
            <div class="form-group">
                <label>Incident Type</label>
                <input type="text" name="request_type" id="edit_type" required>
            </div>
            
            <div class="form-group">
                <label>Message / Details</label>
                <textarea name="message" id="edit_message" rows="4"></textarea>
            </div>
            
            <div style="display:flex; gap:10px; margin-top:2rem;">
                <button type="submit" class="btn-action btn-locate" style="width:100%;">Save Changes</button>
                <button type="button" onclick="closeEditModal()" class="btn-action" style="background:#eee; color:#333; width:100%;">Cancel</button>
            </div>
        </form>
    </div>
</div>

<!-- Real-time Popup Alert -->
<div id="sosAlertToast" class="sos-popup">
    <div style="display:flex; align-items:center; gap:15px; margin-bottom:15px;">
        <span class="material-symbols-sharp danger" style="font-size:3rem;">warning</span>
        <div>
            <h4 style="color:var(--danger); margin:0;">NEW EMERGENCY SOS!</h4>
            <p id="alertUserName" style="margin:5px 0; font-weight:700; font-size:1.1rem;">Victim Name</p>
        </div>
    </div>
    <div id="alertTypeWrap"></div>
    <button onclick="window.location.reload()" class="btn-action btn-locate" style="width:100%; margin-top:20px;">
        VIEW ON MAP
    </button>
</div>

<audio id="sosSiren" preload="auto">
    <source src="https://assets.mixkit.co/active_storage/sfx/1000/1000-preview.mp3" type="audio/mpeg">
</audio>

<script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>
<script src="../../../public/js/script.js"></script>

<script>
    // UNIQUE VARIABLE NAMES relative to globals in script.js
    let sosMapInstance = null;
    const sosMarkersMap = {};
    let sosLastSeenId = <?= $latestId ?>;

    function initSOSMap() {
        const container = document.getElementById('sosMapContainer');
        if (!container) {
            console.error("Map container not found");
            return;
        }

        console.log("Initializing SOS Map...");
        
        // Center on a general area (Bacolod region)
        sosMapInstance = L.map('sosMapContainer').setView([10.6747, 122.9566], 13);
        
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; OpenStreetMap'
        }).addTo(sosMapInstance);

        const data = <?= json_encode($allRequests) ?>;
        console.log("SOS Map Data received:", data);
        
        data.forEach(item => {
            const lat = parseFloat(item.latitude);
            const lng = parseFloat(item.longitude);
            
            if (!isNaN(lat) && !isNaN(lng) && lat !== 0) {
                console.log(`Rendering marker for ${item.first_name}: ${lat}, ${lng}`);
                const isResolved = (item.status === 'Resolved');
                const isPending = !isResolved;
                
                let mColor = '#ef5350'; // Default Danger Red
                if (isResolved) {
                    mColor = '#4caf50'; // Success Green
                } else if (item.source === 'report') {
                    mColor = '#7380ec'; // Report Blue
                } else if (item.source === 'missing') {
                    mColor = '#bb6bd9'; // Missing Purple
                }
                
                const m = L.circleMarker([lat, lng], {
                    radius: isPending ? 14 : 10,
                    fillColor: mColor,
                    color: isPending ? '#fff' : '#ccc',
                    weight: isPending ? 3 : 1,
                    opacity: 1,
                    fillOpacity: 0.8
                }).addTo(sosMapInstance);

                m.bindPopup(`
                    <div style="color:#333; min-width: 150px;">
                        <span class="source-badge ${item.source}" style="display:inline-block; margin-bottom:5px;">${item.source.toUpperCase()}</span>
                        <b style="display:block; font-size:1.1rem; margin-bottom:5px;">${item.first_name} ${item.last_name}</b>
                        <div style="margin-bottom:8px;">
                            ${item.request_type.split(',').map(t => `<span class="type-tag">${t.trim()}</span>`).join('')}
                        </div>
                        <div style="font-size:0.8rem; margin-bottom:10px; color:#666;">
                            Status: <b style="color:${mColor}">${item.status}</b>
                        </div>
                        <div style="display:flex; gap:5px;">
                            <a href="https://www.google.com/maps/dir/?api=1&destination=${item.latitude},${item.longitude}" 
                               target="_blank" style="background:var(--primary); color:white; padding:5px 10px; border-radius:4px; font-size:0.7rem; text-decoration:none;">Directions</a>
                            <button onclick="centerMap(${item.latitude}, ${item.longitude})" 
                                    style="background:#eee; color:#333; padding:5px 10px; border-radius:4px; font-size:0.7rem; cursor:pointer; border:none;">Center</button>
                        </div>
                    </div>
                `);

                sosMarkersMap[item.source + '_' + item.request_id] = m;
            }
        });
        
        console.log("Loaded " + data.length + " SOS items onto map.");
    }

    function centerMap(lat, lng, name) {
        if (!sosMapInstance) return;
        sosMapInstance.setView([lat, lng], 17);
        // Find marker
        for (let id in sosMarkersMap) {
            const p = sosMarkersMap[id].getLatLng();
            if (p.lat == lat && p.lng == lng) {
                sosMarkersMap[id].openPopup();
                break;
            }
        }
    }

    function checkForNewSOS() {
        fetch('sos.php?action=check&last_id=' + sosLastSeenId)
            .then(r => r.json())
            .then(data => {
                if (data.new_found) {
                    // Show Popup
                    const toast = document.getElementById('sosAlertToast');
                    document.getElementById('alertUserName').innerText = data.name;
                    toast.classList.add('active');

                    // Play Sound
                    const siren = document.getElementById('sosSiren');
                    siren.play().catch(e => console.log("Sound check required interaction"));

                    sosLastSeenId = data.latest_id;
                    
                    // Update Title
                    document.title = "🚨 EMERGENCY SOS ALERT 🚨";
                }
            })
            .catch(err => console.error("Poll fail:", err));
    }

    // Run on load
    window.addEventListener('load', () => {
        initSOSMap();
        setInterval(checkForNewSOS, 10000);
    });

    // Sound activation check
    document.addEventListener('click', () => {
        document.getElementById('sosSiren').load();
    }, {once: true});
    // Edit Modal Logic
    function openEditModal(id, source, message, type) {
        document.getElementById('edit_id').value = id;
        document.getElementById('edit_source').value = source;
        document.getElementById('edit_message').value = message;
        document.getElementById('edit_type').value = type;
        document.getElementById('editModal').style.display = 'block';
    }

    function closeEditModal() {
        document.getElementById('editModal').style.display = 'none';
    }

    // Close modal when clicking outside
    window.onclick = function(event) {
        let modal = document.getElementById('editModal');
        if (event.target == modal) {
            closeEditModal();
        }
    }
</script>
</body>
</html>
