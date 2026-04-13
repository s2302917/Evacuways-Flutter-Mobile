# Family Feature Documentation

## Overview
The Family Feature enables users to create and manage family groups for coordinated emergency evacuation. Users can add family members, track their rescue status, and report missing members to administrators.

## Architecture

### Frontend (Flutter)

#### 1. **FamilyController** (`lib/controllers/family_controller.dart`)
Central controller managing all family-related API operations.

**Methods:**
- `createFamily(userId, familyName, primaryContact)` - Creates new family
- `getFamiliesForUser(userId)` - Gets families current user belongs to
- `getFamilyMembers(familyId)` - Gets all members of a family
- `searchUsersForFamily(query, familyId, page)` - Searches users to add (pagination: 10/page)
- `addUserToFamily(familyId, userId)` - Adds user to family
- `leaveFamily(familyId, userId)` - User leaves family
- `reportMissingMember(familyId, missingUserId, reason)` - Reports missing member

**Logging:** All methods include `debugPrint()` for development debugging

---

#### 2. **CreateFamilyScreen** (`lib/screens/create_family_screen.dart`)
Two-step form for creating family groups and adding members.

**Features:**
- **Step 1: Create Family**
  - Input: Family name (e.g., "Semiller's Family")
  - Input: Primary contact number
  - Submit to create_family.php

- **Step 2: Add Members**
  - Real-time search by name or phone
  - Pagination: 10 users per page
  - Previous/Next navigation
  - Add button per user

**State Management:**
- Tracks current step (1 or 2)
- Manages search results
- Handles pagination state

---

#### 3. **FamilyListScreen** (`lib/screens/family_list_screen.dart`)
Displays families and their members with management options.

**Features:**
- Expandable family cards
- Member list with:
  - Name and contact
  - Rescue status (Rescued/Pending)
  - Missing count badge
  - Report Missing button (per member)
- Leave Family button
- Empty state when no families

**Interactions:**
- Tap card to expand/collapse
- Report Missing opens dialog with reason input
- Leave Family shows confirmation
- All actions update state from API

---

#### 4. **ChecklistScreen Integration** (`lib/screens/checklist_screen.dart`)
Family feature integrated at bottom of checklist page.

**Active Family Section:**
- Shows family name and member count
- Displays members with status badges
- "View Full Family" button → FamilyListScreen
- "Add Member" button → member search dialog
- "Report Missing Member" for emergency alerts

**Create Family Section (when no family):**
- Text input for family name
- "Create Family Group" button
- Transitions to active family section after creation

---

### Backend (PHP API)

#### Base URL
```
https://5zu.758.mytemp.website/Evacuways/api/families/
```

#### Endpoints

##### 1. **create_family.php** (POST)
Creates a new family group.

```bash
POST /families/create_family.php
Content-Type: application/json

{
  "user_id": 1,
  "family_name": "Semiller's Family",
  "primary_contact": "+1-234-567-8900"
}

Response:
{
  "success": true,
  "message": "Family created successfully",
  "family_id": 42
}
```

---

##### 2. **get_families.php** (GET)
Gets all families for a user.

```bash
GET /families/get_families.php?user_id=1

Response:
{
  "success": true,
  "families": [
    {
      "family_id": 42,
      "family_name": "Semiller's Family",
      "primary_contact": "+1-234-567-8900",
      "rescue_status": "Pending",
      "headcount": 4,
      "created_at": "2024-01-15 10:30:00"
    }
  ]
}
```

---

##### 3. **get_family_members.php** (GET)
Gets all members of a specific family.

```bash
GET /families/get_family_members.php?family_id=42

Response:
{
  "success": true,
  "members": [
    {
      "user_id": 1,
      "first_name": "John",
      "last_name": "Doe",
      "contact_number": "+1-234-567-8900",
      "rescue_status": "Rescued",
      "missing_count": 0,
      "gender": "M",
      "birth_date": "1990-05-15"
    },
    {
      "user_id": 2,
      "first_name": "Jane",
      "last_name": "Doe",
      "contact_number": "+1-234-567-8901",
      "rescue_status": "Pending",
      "missing_count": 1,
      "gender": "F",
      "birth_date": "1992-08-20"
    }
  ]
}
```

---

##### 4. **search_users.php** (GET)
Searches for users to add to family with pagination.

```bash
GET /families/search_users.php?query=john&family_id=42&page=1&limit=10

Query Parameters:
- query: Search term (name or phone)
- family_id: Family ID to exclude already-added users
- page: Page number (1-based)
- limit: Results per page (default: 10)

Response:
{
  "success": true,
  "users": [
    {
      "user_id": 5,
      "first_name": "John",
      "last_name": "Smith",
      "contact_number": "+1-345-678-9012",
      "is_family": 0
    }
  ],
  "total": 15,
  "page": 1,
  "limit": 10
}
```

---

##### 5. **add_member.php** (POST)
Adds a user to a family.

```bash
POST /families/add_member.php
Content-Type: application/json

{
  "family_id": 42,
  "user_id": 5
}

Response:
{
  "success": true,
  "message": "User added to family successfully"
}
```

---

##### 6. **leave_family.php** (POST)
User leaves a family.

```bash
POST /families/leave_family.php
Content-Type: application/json

{
  "family_id": 42,
  "user_id": 1
}

Response:
{
  "success": true,
  "message": "Successfully left the family"
}
```

---

##### 7. **report_missing.php** (POST)
Reports a family member as missing.

```bash
POST /families/report_missing.php
Content-Type: application/json

{
  "family_id": 42,
  "missing_member_id": 2,
  "reason": "Last seen at evacuation center at 3 PM"
}

Response:
{
  "success": true,
  "message": "Missing person reported to admin",
  "support_request_id": 123
}
```

**Notifies Admin:**
- Creates `evacuways_support_requests` with type='Missing Person'
- Increments `users.missing_count`
- Email notification (if configured)

---

### Database Schema

```sql
-- Family Groups
CREATE TABLE evacuways_families (
  family_id INT PRIMARY KEY AUTO_INCREMENT,
  family_name VARCHAR(255) NOT NULL,
  primary_contact VARCHAR(20),
  rescue_status ENUM('Pending', 'Partially Rescued', 'Rescued') DEFAULT 'Pending',
  headcount INT DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User-Family Relationship
ALTER TABLE evacuways_users ADD COLUMN family_id INT DEFAULT NULL;
ALTER TABLE evacuways_users ADD FOREIGN KEY (family_id) REFERENCES evacuways_families(family_id);

-- Missing Member Tracking
ALTER TABLE evacuways_users ADD COLUMN missing_count INT DEFAULT 0;

-- Support Requests (for missing person reports)
CREATE TABLE evacuways_support_requests (
  request_id INT PRIMARY KEY AUTO_INCREMENT,
  family_id INT,
  missing_member_id INT,
  type VARCHAR(50), -- 'Missing Person', 'Medical', etc.
  reason TEXT,
  status ENUM('Open', 'In Progress', 'Resolved') DEFAULT 'Open',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (family_id) REFERENCES evacuways_families(family_id),
  FOREIGN KEY (missing_member_id) REFERENCES evacuways_users(user_id)
);
```

---

## User Workflows

### Creating a Family
1. User navigates to Checklist Screen
2. Sees "Group As Family" section
3. Enters family name (e.g., "Semiller's Family")
4. Clicks "CREATE FAMILY GROUP"
5. Transitioned to add members step
6. Searches and adds family members
7. Family is created and displayed in active section

### Adding Members
1. Click "Add Member" from active family section (OR)
2. Click "ADD MEMBERS" in create family step 2
3. Search by name or phone number
4. Select users from results
5. Click "Add" button next to user
6. Member is added to family

### Viewing Family
1. Click "VIEW FULL FAMILY" button
2. FamilyListScreen opens
3. Shows all families user belongs to
4. Tap family to expand
5. See all members with rescue status
6. Can report members missing or leave family

### Reporting Missing
1. Expand family in FamilyListScreen
2. Click "Report Missing" on member card
3. Enter additional details
4. Click "Report"
5. Admin receives notification
6. Member's missing count increments

---

## API Error Handling

All endpoints return standardized JSON responses:

```json
{
  "success": false,
  "message": "Error description here"
}
```

**Common errors:**
- Missing user_id → "User not found"
- Invalid family_id → "Family not found"
- User already in family → "User is already in this family"
- Duplicate name → "Family name already exists"

---

## Security Considerations

1. **Authentication:** All endpoints verify user_id matches current session
2. **Authorization:** Users can only manage families they belong to
3. **Data Validation:**
   - Phone format validation
   - Family name sanitization
   - SQL injection prevention (prepared statements)
4. **Rate Limiting:** Consider adding for search endpoint

---

## Performance Notes

- **Search Pagination:** 10 users per page to optimize API response
- **Family Members:** Loaded on-demand when family expanded
- **Database Indexes:** Recommend index on `users.family_id` and `families.family_name`

---

## Testing Checklist

- [ ] Create family with 2+ members
- [ ] Search adds correct users
- [ ] Report missing member creates support request
- [ ] Leave family removes user from family
- [ ] Pagination works with 10+ users
- [ ] Error messages display correctly
- [ ] Navigation between screens works
- [ ] Rescue status updates reflected
- [ ] Missing count increments on report

---

## Future Enhancements

1. **Family Photo:** Add family group image
2. **Location Sharing:** Real-time family member locations
3. **Messaging:** In-family chat for coordination
4. **Emergency Contacts:** Additional contacts per family
5. **Family Events:** Timeline of evacuation events
6. **Admin Dashboard:** Review missing person reports
7. **Notifications:** Push notifications for family updates
