/**
 * Dashboard & Global Admin Script - Final Compiled Version
 * Features: 
 * - Environment-Aware Initialization (Works on Dashboard & Alerts pages)
 * - Theme Toggle with LocalStorage Persistence & Chart Sync
 * - Permanent Red Admin HQ Marker (Leaflet)
 * - Live User Polling (Every 10 seconds)
 * - Dynamic Chart.js Integration with Theme Support
 * - Admin Location Initialization via GPS & Modal
 */

// Global Instances
let registrationChartInstance = null;
let rescueChartInstance = null;
let map = null;      
let markers = [];    
let hqMarker = null; 

document.addEventListener("DOMContentLoaded", () => {
    // --- 0. SELECTORS & SAFETY CHECKS ---
    const dataBridge = document.getElementById("dashboard-data");
    const themeToggler = document.querySelector(".theme-toggler");
    
    // Helper to get CSS variables for Chart colors
    const getThemeColor = (v) => getComputedStyle(document.body).getPropertyValue(v).trim();

    // --- 1. THEME ENGINE (Global) ---
    const applySavedTheme = () => {
        const currentTheme = localStorage.getItem("theme");
        const isDark = currentTheme === "dark";
        
        if (isDark) {
            document.body.classList.add("dark-theme-variables");
        } else {
            document.body.classList.remove("dark-theme-variables");
        }

        if (themeToggler) {
            const lightIcon = themeToggler.querySelector("span:nth-child(1)");
            const darkIcon = themeToggler.querySelector("span:nth-child(2)");
            
            if (isDark) {
                lightIcon?.classList.remove("active");
                darkIcon?.classList.add("active");
            } else {
                lightIcon?.classList.add("active");
                darkIcon?.classList.remove("active");
            }
        }
    };

    // --- 2. DATA PREPARATION (Dashboard Specific) ---
    let adminLat, adminLng, hasLocAttr, totalFamilies, evacuated, remaining;
    
    if (dataBridge) {
        adminLat      = parseFloat(dataBridge.getAttribute('data-admin-lat'));
        adminLng      = parseFloat(dataBridge.getAttribute('data-admin-lng'));
        hasLocAttr    = dataBridge.getAttribute('data-has-location') === 'true';
        totalFamilies = Number(dataBridge.dataset.total || 0);
        evacuated     = Number(dataBridge.dataset.evacuated || 0);
        remaining     = Math.max(0, totalFamilies - evacuated);
    }

    // --- 3. MODAL & GPS LOGIC ---
    const checkAdminLocation = () => {
        const modal = document.getElementById('locationModal');
        if (!modal || !dataBridge) return;
        
        if (hasLocAttr || (!isNaN(adminLat) && !isNaN(adminLng))) {
            modal.style.setProperty('display', 'none', 'important');
            return; 
        }

        modal.style.display = 'flex';
        if (typeof LocationHandler !== 'undefined') {
            LocationHandler.loadRegions('regionSelect');
        }
    };

    document.getElementById('saveLocationBtn')?.addEventListener('click', function() {
        const btn = this;
        const region = document.getElementById('regionSelect')?.value;
        const city = document.getElementById('citySelect')?.value;
        const brgy = document.getElementById('brgySelect')?.value;

        if (!region || !city || !brgy) {
            alert("Please select your Region, City, and Barangay first.");
            return;
        }

        if (navigator.geolocation) {
            btn.innerText = "Getting GPS...";
            btn.disabled = true;

            navigator.geolocation.getCurrentPosition(async (position) => {
                const payload = {
                    lat: position.coords.latitude,
                    lng: position.coords.longitude,
                    region, city, brgy
                };

                try {
                    const response = await fetch('dashboard.php', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(payload)
                    });

                    if (response.ok) location.reload(); 
                    else throw new Error("Failed to save");
                } catch (err) {
                    btn.disabled = false;
                    btn.innerText = "Initialize Map & Save";
                    alert("Error saving location.");
                }
            }, () => {
                alert("GPS access denied.");
                btn.disabled = false;
            });
        }
    });

    // --- 4. LIVE MAP LOGIC ---
    const initMap = () => {
        const container = document.getElementById("userMap");
        if (!container || map || !dataBridge) return;

        const isValidCoords = !isNaN(adminLat) && !isNaN(adminLng);
        const centerCoords = isValidCoords ? [adminLat, adminLng] : [10.6762, 122.9568];
        
        map = L.map("userMap").setView(centerCoords, 15);
        L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
            attribution: '© OpenStreetMap'
        }).addTo(map);

        if (isValidCoords) {
            const redIcon = L.icon({
                iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
                shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
                iconSize: [25, 41], iconAnchor: [12, 41], popupAnchor: [1, -34], shadowSize: [41, 41]
            });

            hqMarker = L.marker([adminLat, adminLng], { icon: redIcon, zIndexOffset: 1000 })
                .addTo(map)
                .bindPopup("<b>Admin HQ</b>")
                .openPopup();
        }

        fetchUserLocations();
        setInterval(fetchUserLocations, 10000); 
    };

    const fetchUserLocations = async () => {
        if (!map) return;
        try {
            const response = await fetch('api/get_live_locations.php');
            const newLocations = await response.json();
            markers.forEach(m => map.removeLayer(m));
            markers = [];
            newLocations.forEach(loc => {
                const m = L.marker([loc.latitude, loc.longitude]).addTo(map);
                markers.push(m);
            });
        } catch (err) { console.error("Map update failed"); }
    };

    // --- 5. CHARTING ENGINE ---
    const renderCharts = () => {
        const textColor = getThemeColor("--text-light") || "#6b7280";

        // Dashboard: Registration Bar Chart
        const evacCtx = document.getElementById("evacuationChart")?.getContext("2d");
        if (evacCtx && dataBridge) {
            if (registrationChartInstance) registrationChartInstance.destroy();
            registrationChartInstance = new Chart(evacCtx, {
                type: "bar",
                data: {
                    labels: ["Database Records"],
                    datasets: [{
                        label: "Total Registered Families",
                        data: [totalFamilies],
                        backgroundColor: "#fd626c", 
                        borderRadius: 8, barThickness: 50
                    }]
                },
                options: {
                    responsive: true, maintainAspectRatio: false,
                    plugins: { legend: { labels: { color: textColor } } },
                    scales: {
                        y: { ticks: { color: textColor }, grid: { display: false } },
                        x: { ticks: { color: textColor }, grid: { display: false } }
                    }
                }
            });
        }

        // Dashboard: Rescue Doughnut Chart
        const rescueCtx = document.getElementById("rescueChart")?.getContext("2d");
        if (rescueCtx && dataBridge) {
            if (rescueChartInstance) rescueChartInstance.destroy();
            const isEmpty = totalFamilies === 0;
            rescueChartInstance = new Chart(rescueCtx, {
                type: "doughnut",
                data: {
                    labels: isEmpty ? ["No Data"] : ["Evacuated", "Pending"],
                    datasets: [{
                        data: isEmpty ? [1] : [evacuated, remaining],
                        backgroundColor: isEmpty ? ["#e5e7eb"] : ["#4caf50", "#ef5350"],
                        borderWidth: 0
                    }]
                },
                options: {
                    responsive: true, maintainAspectRatio: false, cutout: "75%",
                    plugins: { legend: { position: 'bottom', labels: { color: textColor } } }
                }
            });
        }

        // NOTE: For charts inside Alerts.php, ensure you handle them 
        // if you want them to update on theme toggle.
    };

    // --- 6. INITIALIZATION ---
    applySavedTheme();
    checkAdminLocation();
    initMap();
    renderCharts();

    // Theme Toggler Event
    if (themeToggler) {
        themeToggler.addEventListener("click", () => {
            document.body.classList.toggle("dark-theme-variables");
            const isDark = document.body.classList.contains("dark-theme-variables");
            localStorage.setItem("theme", isDark ? "dark" : "light");
            
            // UI Sync
            const lightIcon = themeToggler.querySelector("span:nth-child(1)");
            const darkIcon = themeToggler.querySelector("span:nth-child(2)");
            lightIcon?.classList.toggle("active", !isDark);
            darkIcon?.classList.toggle("active", isDark);

            // Re-render local charts
            setTimeout(renderCharts, 300);
            
            // Dispatch event so charts in Alert.php can listen if they want
            window.dispatchEvent(new Event('themeChanged'));
        });
    }

    window.addEventListener('resize', renderCharts);
});