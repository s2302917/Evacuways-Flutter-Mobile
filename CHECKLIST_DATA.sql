-- ===================================================================
-- CHECKLIST DATA INSERT STATEMENTS
-- Copy and paste these into your phpMyAdmin SQL window
-- ===================================================================

-- ===================================================================
-- 1. INSERT CHECKLISTS (Main categories)
-- ===================================================================
INSERT INTO `evacuways_checklists` (`checklist_id`, `checklist_name`, `description`, `for_children`, `for_elderly`, `for_pwd`) VALUES
(1, 'Typhoon Preparedness', 'Essential preparations before typhoon season hits', 0, 0, 0),
(2, 'Medical Kit Essentials', 'Complete medical kit for emergency situations', 0, 0, 0),
(3, 'Elderly Care Protocol', 'Special care requirements for elderly family members', 0, 1, 0),
(4, 'PWD (Persons with Disabilities) Care', 'Support and equipment needed for PWD members', 0, 0, 1),
(5, 'Children Safety Pack', 'Safety items and documents for children', 1, 0, 0),
(6, 'Family Emergency Kit', 'General family emergency supplies', 0, 0, 0),
(7, 'Pet Safety Guide', 'Pet protection during disasters', 0, 0, 0),
(8, 'Document Backup Protocol', 'Important documents to secure', 0, 0, 0);

-- ===================================================================
-- 2. INSERT CHECKLIST ITEMS (Individual tasks for each checklist)
-- ===================================================================

-- TYPHOON PREPAREDNESS ITEMS (checklist_id: 1)
INSERT INTO `evacuways_checklist_items` (`item_id`, `checklist_id`, `item_description`) VALUES
(1, 1, 'Secure windows and doors - Check for cracks and ensure all latches are reinforced'),
(2, 1, 'Clear drainages - Remove debris from gutters and surroundings to prevent flooding'),
(3, 1, 'Charge power banks - Ensure all portable chargers are at 100% capacity'),
(4, 1, 'Prepare emergency bag - Include food, water, and medicines for 3 days'),
(5, 1, 'Identify evacuation route - Know at least 2 exits from your home'),
(6, 1, 'Stock up on drinking water - 1 liter per person per day for at least 3 days'),
(7, 1, 'Prepare non-perishable food - Canned goods, biscuits, bread, etc'),
(8, 1, 'Check flashlights and batteries - Replace old batteries with new ones'),
(9, 1, 'Secure outdoor items - Remove or tie down loose outdoor furniture'),
(10, 1, 'Backup important documents - Keep originals in waterproof containers');

-- MEDICAL KIT ESSENTIALS ITEMS (checklist_id: 2)
INSERT INTO `evacuways_checklist_items` (`item_id`, `checklist_id`, `item_description`) VALUES
(11, 2, 'First aid kit - Bandages, gauze, medical tape, antiseptic wipes'),
(12, 2, 'Pain relievers - Ibuprofen, acetaminophen for fever and pain'),
(13, 2, 'Antihistamines - For allergies and severe itching'),
(14, 2, 'Antacid - For stomach upset and indigestion'),
(15, 2, 'Antibacterial ointment - For wound care and infection prevention'),
(16, 2, 'Thermometer - Digital or mercury thermometer'),
(17, 2, 'CPR face shield - For CPR if needed'),
(18, 2, 'Medical gloves - Latex or nitrile medical gloves'),
(19, 2, 'Prescription medications - Keep 7-day supply in original bottles'),
(20, 2, 'Medical history document - List of allergies, medications, conditions');

-- ELDERLY CARE PROTOCOL ITEMS (checklist_id: 3)
INSERT INTO `evacuways_checklist_items` (`item_id`, `checklist_id`, `item_description`) VALUES
(21, 3, 'Collect prescription medications - 7-day supply in original labeled bottles'),
(22, 3, 'Prepare mobility aids - Wheelchairs, canes, walkers batteries charged'),
(23, 3, 'Medical alert document - Heart conditions, diabetes, hypertension info'),
(24, 3, 'Hearing aid batteries - Stock up on extra batteries'),
(25, 3, 'Eyeglasses spare pairs - Keep backup glasses in safe location'),
(26, 3, 'Incontinence supplies - Adult diapers and related supplies'),
(27, 3, 'Easy-to-eat foods - Soft foods that dont require much chewing'),
(28, 3, 'Comfort items - Familiar comfort items like photos or blankets'),
(29, 3, 'Emergency contact list - Large print phone numbers'),
(30, 3, 'Designate caregiver - Assign responsible family member');

-- PWD CARE ITEMS (checklist_id: 4)
INSERT INTO `evacuways_checklist_items` (`item_id`, `checklist_id`, `item_description`) VALUES
(31, 4, 'Check mobility equipment - Wheelchairs, crutches, prosthetics in working order'),
(32, 4, 'Backup power supplies - For battery-operated medical devices'),
(33, 4, 'Medications and supplements - Keep 7-10 day supply'),
(34, 4, 'Accessible route plan - Ensure evacuation route is wheelchair/mobility friendly'),
(35, 4, 'Medical device documentation - Manuals and power requirements'),
(36, 4, 'Communication aids - Speech devices, sign language interpreter contacts'),
(37, 4, 'Service animal supplies - Food, water, and medical supplies for service animals'),
(38, 4, 'Accessibility needs list - Document all accessibility requirements'),
(39, 4, 'Emergency contact notification - Inform authorities of special needs'),
(40, 4, 'Transportation arrangement - Plan for accessible transport to evacuation center');

-- CHILDREN SAFETY PACK ITEMS (checklist_id: 5)
INSERT INTO `evacuways_checklist_items` (`item_id`, `checklist_id`, `item_description`) VALUES
(41, 5, 'Recent photos of each child - For identification if separated'),
(42, 5, 'Birth certificates copies - Important for identification'),
(43, 5, 'Vaccination records - Medical history and immunization status'),
(44, 5, 'Children comfort items - Favorite toys, blankets, stuffed animals'),
(45, 5, 'Age-appropriate food - Baby formula, snacks children like'),
(46, 5, 'Change of clothes - Extra clothes in different sizes'),
(47, 5, 'Personal hygiene items - Diapers, wipes, soap, toothbrush'),
(48, 5, 'School documents - Identity cards, academic records'),
(49, 5, 'Emergency contact cards - Child ID with your photo and contact info'),
(50, 5, 'Medications for children - Specific to each childs health needs');

-- FAMILY EMERGENCY KIT ITEMS (checklist_id: 6)
INSERT INTO `evacuways_checklist_items` (`item_id`, `checklist_id`, `item_description`) VALUES
(51, 6, 'Cash and credit cards - Keep P2000-5000 in small denominations'),
(52, 6, 'Important documents - IDs, insurance, property deeds in waterproof bag'),
(53, 6, 'Phone chargers - USB cables and portable power banks'),
(54, 6, 'Emergency numbers - Written list of important contacts'),
(55, 6, 'Matches and lighter - Waterproof matches and lighters'),
(56, 6, 'Rope and duct tape - 20-30 meters of rope and 2-3 rolls of duct tape'),
(57, 6, 'Knife and multi-tool - Sharp knife and portable multi-tool'),
(58, 6, 'Blankets or sleeping bag - For warmth during evacuation'),
(59, 6, 'Whistle - Signal for rescue help 3-4 whistles'),
(60, 6, 'Trash bags - Large bags for waste and water collection');

-- PET SAFETY GUIDE ITEMS (checklist_id: 7)
INSERT INTO `evacuways_checklist_items` (`item_id`, `checklist_id`, `item_description`) VALUES
(61, 7, 'Pet carrier or crate - Secure carrier for transport'),
(62, 7, 'Pet food - 2 weeks supply of regular pet food'),
(63, 7, 'Fresh water - 1 liter per pet per day for 2 weeks'),
(64, 7, 'Pet medications - Regular medications in original bottles'),
(65, 7, 'Litter box or pads - Portable litter box or training pads'),
(66, 7, 'Toys and comfort items - Familiar items to reduce stress'),
(67, 7, 'Recent pet photos - For identification if pet is lost'),
(68, 7, 'Vaccination records - Proof of vaccinations for evacuation center'),
(69, 7, 'Pet microchip info - Registration and microchip number'),
(70, 7, 'Collar with ID tag - Current name and phone number on tag');

-- DOCUMENT BACKUP PROTOCOL ITEMS (checklist_id: 8)
INSERT INTO `evacuways_checklist_items` (`item_id`, `checklist_id`, `item_description`) VALUES
(71, 8, 'Scan government IDs - National ID, drivers license, passport'),
(72, 8, 'Scan titles and deeds - Property papers in waterproof storage'),
(73, 8, 'Insurance documents - Homeowners, car, life insurance copies'),
(74, 8, 'Medical records backup - Hospital and clinic records digitally'),
(75, 8, 'Bank account information - Account numbers and bank contacts'),
(76, 8, 'Will and testament - Legal documents stored safely'),
(77, 8, 'Educational certificates - School and university credentials'),
(78, 8, 'Vehicle registration - Car and motorcycle documents'),
(79, 8, 'Business documents - Relevant if self-employed'),
(80, 8, 'Cloud backup - Upload copies to Google Drive, OneDrive, or iCloud');

-- ===================================================================
-- 3. INSERT USER CHECKLISTS (Track which users are working on which checklists)
-- ===================================================================
-- Users completing Typhoon Preparedness
INSERT INTO `evacuways_user_checklists` (`user_checklist_id`, `user_id`, `checklist_id`, `completed`, `updated_at`) VALUES
(1, 6, 1, 0, NOW()),
(2, 7, 1, 0, NOW()),
(3, 8, 1, 0, NOW()),
(4, 9, 1, 0, NOW()),
(5, 10, 1, 0, NOW());

-- Users completing Medical Kit Essentials
INSERT INTO `evacuways_user_checklists` (`user_checklist_id`, `user_id`, `checklist_id`, `completed`, `updated_at`) VALUES
(6, 6, 2, 0, NOW()),
(7, 7, 2, 0, NOW()),
(8, 8, 2, 0, NOW()),
(9, 9, 2, 0, NOW()),
(10, 10, 2, 0, NOW());

-- Users completing Elderly Care
INSERT INTO `evacuways_user_checklists` (`user_checklist_id`, `user_id`, `checklist_id`, `completed`, `updated_at`) VALUES
(11, 7, 3, 0, NOW()),
(12, 10, 3, 0, NOW());

-- Users completing PWD Care
INSERT INTO `evacuways_user_checklists` (`user_checklist_id`, `user_id`, `checklist_id`, `completed`, `updated_at`) VALUES
(13, 9, 4, 0, NOW());

-- Users completing Children Safety Pack
INSERT INTO `evacuways_user_checklists` (`user_checklist_id`, `user_id`, `checklist_id`, `completed`, `updated_at`) VALUES
(14, 7, 5, 0, NOW()),
(15, 10, 5, 0, NOW());

-- All users have Family Emergency Kit
INSERT INTO `evacuways_user_checklists` (`user_checklist_id`, `user_id`, `checklist_id`, `completed`, `updated_at`) VALUES
(16, 6, 6, 0, NOW()),
(17, 7, 6, 0, NOW()),
(18, 8, 6, 0, NOW()),
(19, 9, 6, 0, NOW()),
(20, 10, 6, 0, NOW());

-- ===================================================================
-- END OF CHECKLIST DATA
-- ===================================================================
