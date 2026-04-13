<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . "/../../../app/controllers/SettingController.php";
$settingController = new SettingController();

// Handle form submission
$settingController->handleRequest();

// Get active admin data
$adminId = $_SESSION['admin_id'] ?? 1;
$adminData = $settingController->getAdmin($adminId);

// Default coordinates (Bacolod) if none are set
$lat = $adminData['latitude'] ?? 10.6762;
$lng = $adminData['longitude'] ?? 122.9568;
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Settings | Evacuways Admin</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Sharp" />
    <link rel="stylesheet" href="../../../public/css/style.css?v=<?php echo time(); ?>">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <style>
        .map-container { display: flex; gap: 2rem; }
        .map-section { flex: 1; }
        .form-section { flex: 1; }
        
        /* Style for the search bar and locate button */
        .search-location { 
            display: flex; gap: 0.5rem; margin-bottom: 1rem; align-items: center; 
        }
        .search-location input { 
            flex: 1; padding: 0.8rem; border-radius: var(--border-radius-1, 8px); 
            border: 1px solid var(--color-info-light, #dce1eb); background: var(--color-background, #f6f6f9); 
            color: var(--color-dark, #363949); 
        }
        
        /* Fixed button visibility */
        .btn-locate { 
            background-color: var(--color-primary, #7380ec); 
            color: #ffffff; border: none; border-radius: var(--border-radius-1, 8px); 
            padding: 0.8rem; display: flex; align-items: center; justify-content: center; 
            cursor: pointer; transition: all 300ms ease; flex-shrink: 0; 
            min-width: 45px; min-height: 45px;
        }
        .btn-locate:hover { box-shadow: 0 0.5rem 1rem var(--color-primary-light, rgba(115, 128, 236, 0.4)); }
        .btn-locate:disabled { opacity: 0.7; cursor: not-allowed; }
        .btn-locate .material-symbols-sharp { font-size: 1.5rem; }
    </style>
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
            <a href="../volunteers/volunteers.php"><span class="material-symbols-sharp">volunteer_activism</span><h3>Volunteers</h3></a>
            <a href="../messages/messages.php"><span class="material-symbols-sharp">mail</span><h3>Messages</h3></a>
            <a href="settings.php" class="active"><span class="material-symbols-sharp">settings</span><h3>Settings</h3></a>
            <a href="../../auth/logout.php"><span class="material-symbols-sharp">logout</span><h3>Logout</h3></a>
        </div>
    </aside>

    <main style="width: 100%;">
        <h1>Account Settings</h1>
        
        <?php if(isset($_GET['success'])): ?>
            <div style="background: var(--color-success-light, #d4edda); color: var(--color-success, #155724); padding: 1rem; border-radius: var(--border-radius-1); margin-bottom: 1rem;">
                Settings updated successfully!
            </div>
        <?php endif; ?>

        <?php if(isset($_GET['error']) && $_GET['error'] === 'invalid_password'): ?>
            <div style="background: #f8d7da; color: #721c24; padding: 1rem; border-radius: var(--border-radius-1); margin-bottom: 1rem; border: 1px solid #f5c6cb;">
                <strong>Security Alert:</strong> The current password you entered is incorrect. Changes were not saved.
            </div>
        <?php elseif(isset($_GET['error']) && $_GET['error'] === 'update_failed'): ?>
            <div style="background: #f8d7da; color: #721c24; padding: 1rem; border-radius: var(--border-radius-1); margin-bottom: 1rem; border: 1px solid #f5c6cb;">
                An error occurred while updating your settings. Please try again.
            </div>
        <?php endif; ?>

        <div class="form-container" style="margin-top: 1.5rem;">
            <form action="settings.php" method="POST" class="form-group-wrapper">
                
                <div class="map-container">
                    <div class="form-section">
                        <h3>Profile Information</h3>
                        <div class="grid-2-col" style="margin-top: 1rem;">
                            <div class="input-box">
                                <p>Full Name</p>
                                <input type="text" name="full_name" value="<?= htmlspecialchars($adminData['full_name'] ?? '') ?>" required>
                            </div>
                            <div class="input-box">
                                <p>Email Address</p>
                                <input type="email" name="email" value="<?= htmlspecialchars($adminData['email'] ?? '') ?>" required>
                            </div>
                            
                            <div class="input-box" style="grid-column: span 2; border-top: 1px solid #ccc; padding-top: 1rem; margin-top: 0.5rem;">
                                <p style="font-weight: bold;">Current Password <span style="color: red;">*</span> <span style="font-weight: normal; font-size: 0.85rem; color: #666;">(Required to save any changes)</span></p>
                                <input type="password" name="old_password" placeholder="Verify your current password..." required style="border-color: #ff9800;">
                            </div>

                            <div class="input-box" style="grid-column: span 2;">
                                <p>New Password (leave blank to keep current)</p>
                                <input type="password" name="password" placeholder="Enter new password...">
                            </div>
                        </div>

                        <h3 style="margin-top: 2rem;">Location Settings</h3>
                        <div class="grid-2-col" style="margin-top: 1rem;">
                            <div class="input-box">
                                <p>Region</p>
                                <select name="region_code" id="region_dropdown" required>
                                    <option value="" disabled selected>Loading Regions...</option>
                                </select>
                            </div>
                            <div class="input-box">
                                <p>City / Municipality</p>
                                <select name="city_code" id="city_dropdown" required disabled>
                                    <option value="" disabled selected>Select Region First</option>
                                </select>
                            </div>
                            <div class="input-box" style="grid-column: span 2;">
                                <p>Barangay</p>
                                <select name="barangay_code" id="barangay_dropdown" required disabled>
                                    <option value="" disabled selected>Select City First</option>
                                </select>
                            </div>
                        </div>
                        
                        <div class="grid-2-col" style="margin-top: 1rem;">
                            <div class="input-box">
                                <p>Latitude</p>
                                <input type="text" name="latitude" id="lat_input" value="<?= $lat ?>" readonly>
                            </div>
                            <div class="input-box">
                                <p>Longitude</p>
                                <input type="text" name="longitude" id="lng_input" value="<?= $lng ?>" readonly>
                            </div>
                        </div>

                        <button type="submit" name="update_settings" class="btn-submit" style="margin-top: 2rem;">Save Settings</button>
                    </div>

                    <div class="map-section">
                        <h3>Pin Your Location</h3>
                        <p class="text-muted" style="margin-bottom: 1rem; font-size: 0.9rem;">Search, click the map, or use the GPS button to set your exact coordinates.</p>
                        
                        <div class="search-location">
                            <input type="text" id="mapSearchInput" placeholder="Search a place (e.g. Bacolod City)">
                            <button type="button" id="mapSearchBtn" class="btn-submit" style="width: auto; padding: 0.8rem 1.5rem;">Search</button>
                            <button type="button" id="locateMeBtn" class="btn-locate" title="Find My Location">
                                <span class="material-symbols-sharp">my_location</span>
                            </button>
                        </div>

                        <div id="adminMap" style="height: 450px; width: 100%; border-radius: var(--border-radius-1); z-index: 1; border: 2px solid var(--color-light);"></div>
                    </div>
                </div>

            </form>
        </div>
    </main>
</div>

<script>
    // --- 1. LEAFLET MAP & SEARCH LOGIC ---
    document.addEventListener("DOMContentLoaded", function() {
        const initialLat = <?= $lat ?>;
        const initialLng = <?= $lng ?>;
        const latInput = document.getElementById('lat_input');
        const lngInput = document.getElementById('lng_input');
        
        // Buttons and Inputs
        const searchInput = document.getElementById('mapSearchInput');
        const searchBtn = document.getElementById('mapSearchBtn');
        const locateMeBtn = document.getElementById('locateMeBtn');

        // Initialize map
        const map = L.map('adminMap').setView([initialLat, initialLng], 14);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);
        
        // Add draggable marker
        let marker = L.marker([initialLat, initialLng], {draggable: true}).addTo(map);

        // Fix map rendering issues inside flex/hidden containers
        setTimeout(function() {
            map.invalidateSize();
        }, 100);

        // Update inputs when marker is dragged
        marker.on('dragend', function(e) {
            const position = marker.getLatLng();
            latInput.value = position.lat.toFixed(7);
            lngInput.value = position.lng.toFixed(7);
        });

        // Move marker and update inputs when map is clicked
        map.on('click', function(e) {
            marker.setLatLng(e.latlng);
            latInput.value = e.latlng.lat.toFixed(7);
            lngInput.value = e.latlng.lng.toFixed(7);
        });

        // --- Handle Map Search ---
        searchBtn.addEventListener('click', function() {
            const query = searchInput.value.trim();
            if (!query) return;

            const originalText = searchBtn.textContent;
            searchBtn.textContent = '...';
            searchBtn.disabled = true;

            fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&countrycodes=ph`)
                .then(response => response.json())
                .then(data => {
                    if (data && data.length > 0) {
                        const newLat = parseFloat(data[0].lat);
                        const newLng = parseFloat(data[0].lon);

                        map.setView([newLat, newLng], 15);
                        marker.setLatLng([newLat, newLng]);

                        latInput.value = newLat.toFixed(7);
                        lngInput.value = newLng.toFixed(7);
                    } else {
                        alert("Location not found in the Philippines.");
                    }
                })
                .catch(err => {
                    console.error("Geocoding error:", err);
                    alert("An error occurred while searching.");
                })
                .finally(() => {
                    searchBtn.textContent = originalText;
                    searchBtn.disabled = false;
                });
        });

        searchInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                searchBtn.click();
            }
        });

        // --- Handle GPS "Locate Me" ---
        locateMeBtn.addEventListener('click', function() {
            if (navigator.geolocation) {
                const icon = locateMeBtn.querySelector('span');
                icon.textContent = 'hourglass_empty';
                locateMeBtn.disabled = true;

                navigator.geolocation.getCurrentPosition(
                    function(position) {
                        const newLat = position.coords.latitude;
                        const newLng = position.coords.longitude;

                        map.setView([newLat, newLng], 16);
                        marker.setLatLng([newLat, newLng]);

                        latInput.value = newLat.toFixed(7);
                        lngInput.value = newLng.toFixed(7);

                        icon.textContent = 'my_location';
                        locateMeBtn.disabled = false;
                    },
                    function(error) {
                        console.error("Geolocation error:", error);
                        let msg = "An error occurred trying to find your location.";
                        if (error.code === 1) msg = "Location access denied. Please allow permissions in your browser.";
                        else if (error.code === 2) msg = "Location unavailable. Please check your GPS or network.";
                        else if (error.code === 3) msg = "Location request timed out.";
                        
                        alert(msg);
                        icon.textContent = 'my_location';
                        locateMeBtn.disabled = false;
                    },
                    { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
                );
            } else {
                alert("Geolocation is not supported by your browser.");
            }
        });
    });

    // --- 2. PSGC API DROPDOWN LOGIC ---
    document.addEventListener("DOMContentLoaded", async function() {
        const regionDrop = document.getElementById('region_dropdown');
        const cityDrop = document.getElementById('city_dropdown');
        const barangayDrop = document.getElementById('barangay_dropdown');

        const savedRegion = "<?= $adminData['region_code'] ?? '' ?>";
        const savedCity = "<?= $adminData['city_code'] ?? '' ?>";
        const savedBarangay = "<?= $adminData['barangay_code'] ?? '' ?>";

        try {
            const res = await fetch('https://psgc.gitlab.io/api/regions/');
            const regions = await res.json();
            regionDrop.innerHTML = '<option value="" disabled>Select Region</option>';
            
            regions.sort((a,b) => a.name.localeCompare(b.name)).forEach(r => {
                const selected = r.code === savedRegion ? 'selected' : '';
                regionDrop.innerHTML += `<option value="${r.code}" ${selected}>${r.name}</option>`;
            });

            if (savedRegion) loadCities(savedRegion, savedCity);

        } catch (error) { console.error("Error loading regions:", error); }

        regionDrop.addEventListener('change', function() { loadCities(this.value, null); });
        cityDrop.addEventListener('change', function() { loadBarangays(this.value, null); });

        async function loadCities(regionCode, cityToSelect) {
            cityDrop.disabled = false;
            cityDrop.innerHTML = '<option value="" disabled selected>Loading Cities...</option>';
            barangayDrop.disabled = true;
            barangayDrop.innerHTML = '<option value="" disabled selected>Select City First</option>';

            try {
                const res = await fetch(`https://psgc.gitlab.io/api/regions/${regionCode}/cities-municipalities/`);
                const cities = await res.json();
                cityDrop.innerHTML = '<option value="" disabled>Select City / Municipality</option>';

                cities.sort((a,b) => a.name.localeCompare(b.name)).forEach(c => {
                    const selected = c.code === cityToSelect ? 'selected' : '';
                    cityDrop.innerHTML += `<option value="${c.code}" ${selected}>${c.name}</option>`;
                });

                if (cityToSelect) loadBarangays(cityToSelect, savedBarangay);
            } catch (error) { console.error("Error loading cities:", error); }
        }

        async function loadBarangays(cityCode, brgyToSelect) {
            barangayDrop.disabled = false;
            barangayDrop.innerHTML = '<option value="" disabled selected>Loading Barangays...</option>';

            try {
                const res = await fetch(`https://psgc.gitlab.io/api/cities-municipalities/${cityCode}/barangays/`);
                const barangays = await res.json();
                barangayDrop.innerHTML = '<option value="" disabled>Select Barangay</option>';

                barangays.sort((a,b) => a.name.localeCompare(b.name)).forEach(b => {
                    const selected = b.code === brgyToSelect ? 'selected' : '';
                    barangayDrop.innerHTML += `<option value="${b.code}" ${selected}>${b.name}</option>`;
                });
            } catch (error) { console.error("Error loading barangays:", error); }
        }
    });
</script>
</body>
</html>