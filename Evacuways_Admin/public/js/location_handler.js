/**
 * Universal Philippine Location Handler
 * Fetches data from the PSGC API and populates select elements.
 */
const BASE_URL = 'https://psgc.gitlab.io/api';

const LocationHandler = {
    // Helper to clear and set loading state
    setLoading: (elementId, message = "Loading...") => {
        const select = document.getElementById(elementId);
        if (select) select.innerHTML = `<option value="">${message}</option>`;
    },

    loadRegions: async (elementId) => {
        try {
            LocationHandler.setLoading(elementId);
            const response = await fetch(`${BASE_URL}/regions/`);
            const regions = await response.json();
            const select = document.getElementById(elementId);
            select.innerHTML = '<option value="">Select Region</option>';
            
            regions.sort((a, b) => a.name.localeCompare(b.name)).forEach(reg => {
                let opt = new Option(reg.name, reg.code);
                select.add(opt);
            });
        } catch (error) {
            console.error("Error loading regions:", error);
        }
    },

    loadCities: async (regionCode, elementId) => {
        if (!regionCode) return;
        try {
            LocationHandler.setLoading(elementId);
            const response = await fetch(`${BASE_URL}/regions/${regionCode}/cities-municipalities/`);
            const cities = await response.json();
            const select = document.getElementById(elementId);
            select.innerHTML = '<option value="">Select City/Municipality</option>';
            
            cities.sort((a, b) => a.name.localeCompare(b.name)).forEach(city => {
                let opt = new Option(city.name, city.code);
                select.add(opt);
            });
        } catch (error) {
            console.error("Error loading cities:", error);
        }
    },

    loadBarangays: async (cityCode, elementId) => {
    if (!cityCode) return [];
    try {
        LocationHandler.setLoading(elementId);
        const response = await fetch(`${BASE_URL}/cities-municipalities/${cityCode}/barangays/`);
        const brgys = await response.json();
        const select = document.getElementById(elementId);
        select.innerHTML = '<option value="">Select Barangay</option>';
        
        brgys.sort((a, b) => a.name.localeCompare(b.name)).forEach(brgy => {
            let opt = new Option(brgy.name, brgy.code);
            select.add(opt);
        });
        return brgys; // Return the data to signal completion
    } catch (error) {
        console.error("Error loading barangays:", error);
        return [];
    }
}
};

/**
 * AUTO-SYNC LOGIC
 * Automatically updates hidden name fields when a dropdown changes.
 */
document.addEventListener('change', (e) => {
    // Check if the changed element is a barangay select
    if (e.target && (e.target.id === 'brgySelect' || e.target.id === 'update_brgySelect')) {
        const select = e.target;
        const selectedText = select.options[select.selectedIndex].text;
        
        // Find the hidden input in the same form
        const form = select.closest('form');
        const hiddenInput = form.querySelector('input[name="barangay_name"]');
        
        if (hiddenInput) {
            hiddenInput.value = (select.value === "") ? "" : selectedText;
        }
    }
});