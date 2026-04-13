# Family Feature - Database Schema Mismatch Analysis Report

**Date:** March 30, 2026  
**Status:** ⚠️ CRITICAL ISSUES FOUND  
**Severity:** Medium (Functional but Over-Specified)

---

## Executive Summary

The Flutter family management screens and controllers **mostly align** with the documented database schema, but there are **significant mismatches** in the `FamilyModel` class. The model tries to map database fields that **do not exist in the schema**, and the screens use untyped JSON for family member data, creating potential runtime errors.

**Critical Finding:** The `FamilyModel` expects `assigned_vehicle_id`, `assigned_center_id`, and `missing_status` fields that are NOT defined in the `evacuways_families` table schema.

---

## Database Schema Reference

### evacuways_families Table

```sql
CREATE TABLE evacuways_families (
  family_id INT PRIMARY KEY AUTO_INCREMENT,
  family_name VARCHAR(255) NOT NULL,
  primary_contact VARCHAR(20),
  rescue_status ENUM('Pending', 'Partially Rescued', 'Rescued') DEFAULT 'Pending',
  headcount INT DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Fields:** 6 total
- `family_id` - Primary Key
- `family_name` - Family group name
- `primary_contact` - Contact number (20 chars)
- `rescue_status` - Rescue state (Pending, Partially Rescued, Rescued)
- `headcount` - Number of members
- `created_at` - Creation timestamp

### evacuways_users Table (Modified)

```sql
ALTER TABLE evacuways_users ADD COLUMN family_id INT DEFAULT NULL;
ALTER TABLE evacuways_users ADD COLUMN missing_count INT DEFAULT 0;
ALTER TABLE evacuways_users ADD FOREIGN KEY (family_id) REFERENCES evacuways_families(family_id);
```

**Relevant Fields:**
- `user_id` - Primary Key
- `first_name` - First name
- `last_name` - Last name
- `contact_number` - Contact number
- `rescue_status` - User's rescue status
- `missing_count` - Number of times reported missing
- `family_id` - Foreign Key to families table
- Plus: gender, birth_date, region_code, city_code, barangay_code, center_id, etc.

### evacuways_support_requests Table (For Missing Reports)

```sql
CREATE TABLE evacuways_support_requests (
  request_id INT PRIMARY KEY AUTO_INCREMENT,
  family_id INT,
  missing_member_id INT,
  type VARCHAR(50),
  reason TEXT,
  status ENUM('Open', 'In Progress', 'Resolved') DEFAULT 'Open',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (family_id) REFERENCES evacuways_families(family_id),
  FOREIGN KEY (missing_member_id) REFERENCES evacuways_users(user_id)
);
```

---

## File Analysis

### 1. FamilyModel (`lib/models/family_model.dart`) ⚠️ CRITICAL MISMATCH

**Current Implementation:**

```dart
class FamilyModel {
  final int familyId;
  final String familyName;
  final String primaryContact;
  final String rescueStatus;
  final int? assignedVehicleId;          // ❌ NOT IN SCHEMA
  final int? assignedCenterId;           // ❌ NOT IN SCHEMA
  final int headcount;
  final DateTime createdAt;
  final String missingStatus;            // ❌ NOT IN SCHEMA
  final int missingCount;
  // ...
}
```

**Database Server Fields:**
1. ✅ `family_id` → `familyId`
2. ✅ `family_name` → `familyName`
3. ✅ `primary_contact` → `primaryContact`
4. ✅ `rescue_status` → `rescueStatus`
5. ❌ **`assignedVehicleId`** - Field does NOT exist in `evacuways_families` table
6. ❌ **`assignedCenterId`** - Field does NOT exist in `evacuways_families` table
7. ✅ `headcount` → `headcount`
8. ✅ `created_at` → `createdAt`
9. ❌ **`missingStatus`** - Field does NOT exist in `evacuways_families` table
10. ✅ `missing_count` → `missingCount` (stored on user, not family)

**Issues:**

| Field | Expected | Actual | Status |
|-------|----------|--------|--------|
| family_id | ✅ In schema | ✅ In model | CORRECT |
| family_name | ✅ In schema | ✅ In model | CORRECT |
| primary_contact | ✅ In schema | ✅ In model | CORRECT |
| rescue_status | ✅ In schema | ✅ In model | CORRECT |
| assigned_vehicle_id | ❌ NOT in schema | ❌ In model | **MISMATCH** |
| assigned_center_id | ❌ NOT in schema | ❌ In model | **MISMATCH** |
| headcount | ✅ In schema | ✅ In model | CORRECT |
| created_at | ✅ In schema | ✅ In model | CORRECT |
| missing_status | ❌ NOT in schema | ❌ In model | **MISMATCH** |
| missing_count | ⚠️ On user table | ✅ In model | QUESTIONABLE |

**What Happens When API Returns Data:**
- If the API returns these extra fields → FamilyModel will attempt to map them (may be NULL)
- If API doesn't return them → `fromJson()` silently treats them as NULL (no error)
- If another API tries to return these fields → Code expects them to exist

**Risk:** Runtime error if API response doesn't include these fields or if null checking isn't done properly.

---

### 2. CreateFamilyScreen (`lib/screens/create_family_screen.dart`) ✅ CORRECT

**Purpose:** Two-step form to create family and add members

**Step 1 - Create Family:**
- Input: `family_name` (text field) → Maps to schema ✅
- Input: `primary_contact` (text field) → Maps to schema ✅
- API Call: `FamilyController.createFamily(familyName, primaryContact, userId)`
- Returns: `family_id` for next step

**Step 2 - Add Members:**
- Search users by name/phone → `FamilyController.searchUsersForFamily()`
- Displays: `first_name`, `last_name`, `contact_number`
- Adds user to family → `FamilyController.addUserToFamily(familyId, userId)`

**Schema Alignment:**
```
User Input          → Database Field    → Status
family_name         → evacuways_families.family_name     ✅
primary_contact     → evacuways_families.primary_contact ✅
user_id             → evacuways_users.user_id             ✅
first_name          → evacuways_users.first_name          ✅
last_name           → evacuways_users.last_name           ✅
contact_number      → evacuways_users.contact_number      ✅
```

**Verdict:** No mismatches detected. All collected fields match schema.

---

### 3. FamilyListScreen (`lib/screens/family_list_screen.dart`) ⚠️ TYPE SAFETY ISSUE

**Purpose:** Display user's families with expandable member lists

**Family Card Displays:**
```dart
family['family_id']       ✅ Matches schema
family['family_name']     ✅ Matches schema
family['primary_contact'] ✅ Matches schema
```

**Member Card Displays:**
```dart
member['user_id']         ✅ Matches schema
member['first_name']      ✅ Matches schema
member['last_name']       ✅ Matches schema
member['contact_number']  ✅ Matches schema
member['rescue_status']   ✅ Matches schema
member['missing_count']   ✅ Matches schema (on users table)
```

**Critical Issue - Type Safety:**

```dart
Future<List<dynamic>> getFamilyMembers(int familyId)  // ❌ Returns untyped List
```

The `getFamilyMembers()` method returns `List<dynamic>`, then screens access fields using string keys:

```dart
member['first_name']  // ❌ No type checking - could return null or wrong type
```

**Better Approach:**
```dart
Future<List<UserModel>> getFamilyMembers(int familyId)  // ✅ Type-safe

// Then use:
member.firstName  // ✅ Type-safe property access
```

**Risk:** 
- If API returns different structure → Runtime error only when accessed
- If field is null → Widget might crash without null coalescing
- No autocomplete/IDE support for accessing member fields

**Verdict:** Functionally works but lacks type safety. Should use `UserModel` instead of `dynamic`.

---

### 4. ProfileScreen (`lib/screens/profile_screen.dart`) ✅ CORRECT

**Purpose:** Display user profile with family info

**Family Section Displays:**
- `_myFamily?.familyName` ✅ Correct field
- Status text: "Active Coordination Group"
- Create button if no family

**Schema Alignment:**
```
Display              → Database Field        → Status
family_name          → evacuways_families.family_name ✅
```

**Data Loading:**
```dart
final result = await _userController.getFamily(user.userId);
if (result['success']) {
  _myFamily = result['family'];  // Expects FamilyModel
}
```

**Verdict:** Correct usage. Displays only needed fields.

---

### 5. FamilyController (`lib/controllers/family_controller.dart`) ⚠️ PARTIAL ISSUES

#### createFamily()
```dart
// Request
{
  'family_name': familyName,        ✅
  'primary_contact': primaryContact, ✅
  'user_id': userId                 ✅
}

// Expected Response
{
  'success': true,
  'family_id': 42
}
```
**Status:** ✅ Correct - matches schema

#### getFamiliesForUser()
```dart
// Maps raw JSON to FamilyModel
families = data.map((json) => FamilyModel.fromJson(json)).toList();
```
**Status:** ⚠️ Problem - FamilyModel expects non-existent fields

**What API actually returns (per documentation):**
```json
{
  "family_id": 42,
  "family_name": "Semiller's Family",
  "primary_contact": "+1-234-567-8900",
  "rescue_status": "Pending",
  "headcount": 4,
  "created_at": "2024-01-15 10:30:00"
}
```

**What FamilyModel.fromJson() tries to map:**
```json
{
  "family_id": 42,          ✅
  "family_name": "...",     ✅
  "primary_contact": "...", ✅
  "rescue_status": "...",   ✅
  "assigned_vehicle_id": ?,   // 🔍 May not be in response
  "assigned_center_id": ?,    // 🔍 May not be in response
  "headcount": 4,           ✅
  "created_at": "...",      ✅
  "missing_status": ?,        // 🔍 May not be in response
  "missing_count": ?          // 🔍 May not be in response
}
```

**Risk:** If API response doesn't include these extra fields, they'll be NULL. Code may crash if not null-checked.

#### getFamilyMembers()
```dart
final List<dynamic> data = jsonDecode(response.body);
return data;  // ❌ Returns raw untyped data
```
**Status:** ⚠️ Type safety issue

#### searchUsersForFamily()
```dart
availableUsers = data.map((json) => UserModel.fromJson(json)).toList();
return availableUsers ?? [];
```
**Status:** ✅ Correct - uses UserModel

#### addUserToFamily()
```dart
{
  'family_id': familyId, ✅
  'user_id': userId      ✅
}
```
**Status:** ✅ Correct

#### leaveFamily()
```dart
{
  'family_id': familyId, ✅
  'user_id': userId      ✅
}
```
**Status:** ✅ Correct

#### reportMissingMember()
```dart
{
  'family_id': familyId,           ✅
  'missing_member_id': missingMemberId, ✅
  'reason': reason                 ✅
}
```
**Status:** ✅ Correct

**Verdict:** Most methods correct, but `getFamiliesForUser()` has potential issues with FamilyModel over-specification.

---

## Issues Summary

### 🔴 Critical Issues (Breaks Functionality)
None - App will still work but may have runtime errors

### 🟠 Serious Issues (Poor Data Handling)
1. **FamilyModel expects non-existent database fields** → Over-specification causes potential NULL issues
2. **getFamilyMembers() returns untyped data** → No type safety for accessing user properties

### 🟡 Medium Issues (Poor Practices)
3. **Missing null safety in screenaccess to dynamic fields** → Could cause null reference errors
4. **API documentation vs. code mismatch** → assigned_vehicle_id, assigned_center_id not documented in API responses

---

## Detailed Recommendations

### Fix #1: Clean Up FamilyModel (HIGH PRIORITY)

**Before:**
```dart
class FamilyModel {
  final int familyId;
  final String familyName;
  final String primaryContact;
  final String rescueStatus;
  final int? assignedVehicleId;      // ❌ Remove
  final int? assignedCenterId;       // ❌ Remove
  final int headcount;
  final DateTime createdAt;
  final String missingStatus;        // ❌ Remove
  final int missingCount;
  
  FamilyModel({
    required this.familyId,
    required this.familyName,
    required this.primaryContact,
    this.rescueStatus = 'Pending Rescue',
    this.assignedVehicleId,          // ❌ Remove
    this.assignedCenterId,           // ❌ Remove
    this.headcount = 0,
    required this.createdAt,
    this.missingStatus = 'None',    // ❌ Remove
    this.missingCount = 0,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      familyId: json['family_id'] ?? 0,
      familyName: json['family_name'] ?? '',
      primaryContact: json['primary_contact'] ?? '',
      rescueStatus: json['rescue_status'] ?? 'Pending Rescue',
      assignedVehicleId: json['assigned_vehicle_id'],  // ❌ Remove
      assignedCenterId: json['assigned_center_id'],    // ❌ Remove
      headcount: json['headcount'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      missingStatus: json['missing_status'] ?? 'None',  // ❌ Remove
      missingCount: json['missing_count'] ?? 0,
    );
  }
}
```

**After - Option A (Remove Extra Fields):**
```dart
class FamilyModel {
  final int familyId;
  final String familyName;
  final String primaryContact;
  final String rescueStatus;
  final int headcount;
  final DateTime createdAt;

  FamilyModel({
    required this.familyId,
    required this.familyName,
    required this.primaryContact,
    this.rescueStatus = 'Pending',
    this.headcount = 1,
    required this.createdAt,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      familyId: json['family_id'] ?? 0,
      familyName: json['family_name'] ?? '',
      primaryContact: json['primary_contact'] ?? '',
      rescueStatus: json['rescue_status'] ?? 'Pending',
      headcount: json['headcount'] ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'family_id': familyId,
    'family_name': familyName,
    'primary_contact': primaryContact,
    'rescue_status': rescueStatus,
    'headcount': headcount,
    'created_at': createdAt.toIso8601String(),
  };
}
```

**After - Option B (Keep but Make Optional with Comments):**
```dart
class FamilyModel {
  final int familyId;
  final String familyName;
  final String primaryContact;
  final String rescueStatus;
  final int headcount;
  final DateTime createdAt;
  
  // Fields returned by some API endpoints but not stored in families table
  final int? assignedVehicleId;      // May be returned by some APIs
  final int? assignedCenterId;       // May be returned by some APIs
  final String? missingStatus;       // May be returned by some APIs
  final int? missingCount;           // May be returned by some APIs (from users table)

  FamilyModel({
    required this.familyId,
    required this.familyName,
    required this.primaryContact,
    this.rescueStatus = 'Pending',
    this.headcount = 1,
    required this.createdAt,
    this.assignedVehicleId,
    this.assignedCenterId,
    this.missingStatus,
    this.missingCount,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      familyId: json['family_id'] as int? ?? 0,
      familyName: json['family_name'] as String? ?? '',
      primaryContact: json['primary_contact'] as String? ?? '',
      rescueStatus: json['rescue_status'] as String? ?? 'Pending',
      headcount: json['headcount'] as int? ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      assignedVehicleId: json['assigned_vehicle_id'] as int?,
      assignedCenterId: json['assigned_center_id'] as int?,
      missingStatus: json['missing_status'] as String?,
      missingCount: json['missing_count'] as int?,
    );
  }
}
```

**Recommendation:** Use **Option B** - keeps flexibility if APIs return these fields, but makes it clear they're not in the main schema.

---

### Fix #2: Add Type Safety to getFamilyMembers() (HIGH PRIORITY)

**Current Code (lib/controllers/family_controller.dart):**
```dart
Future<List<dynamic>> getFamilyMembers(int familyId) async {
  try {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/families/get_family_members.php?family_id=$familyId',
      ),
    );

    debugPrint('GET MEMBERS STATUS: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);  // ❌ Untyped
      return data;
    }
    return [];
  } catch (e) {
    debugPrint('Error fetching members: $e');
    return [];
  }
}
```

**Improved Version:**
```dart
Future<List<UserModel>> getFamilyMembers(int familyId) async {
  try {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/families/get_family_members.php?family_id=$familyId',
      ),
    );

    debugPrint('GET MEMBERS STATUS: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // ✅ Map to UserModel for type safety
      return data
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  } catch (e) {
    debugPrint('Error fetching members: $e');
    return [];
  }
}
```

**Update FamilyListScreen accordingly:**
```dart
// Before
FutureBuilder<List<dynamic>>(
  future: _familyController.getFamilyMembers(family['family_id']),
  builder: (context, snapshot) {
    final members = snapshot.data ?? [];
    return Column(
      children: [
        ...members.map((member) {
          final missingCount = member['missing_count'] ?? 0;  // ❌ Untyped access
```

**After:**
```dart
// After
FutureBuilder<List<UserModel>>(
  future: _familyController.getFamilyMembers(family['family_id']),
  builder: (context, snapshot) {
    final members = snapshot.data ?? [];
    return Column(
      children: [
        ...members.map((member) {
          final missingCount = member.missingCount;  // ✅ Type-safe access
```

---

### Fix #3: Add Null Safety in FamilyListScreen (MEDIUM PRIORITY)

**Current problematic code:**
```dart
Text(
  '${member['first_name']} ${member['last_name']}',
  // If these are null, will display "null null"
),
```

**Better approach:**
```dart
Text(
  '${member['first_name'] ?? 'Unknown'} ${member['last_name'] ?? ''}',
),

// Or with typed UserModel:
Text(
  '${member.firstName} ${member.lastName}',
),
```

---

### Fix #4: Align API Documentation with Code (MEDIUM PRIORITY)

**Issue:** API endpoints should document whether they return:
- `assigned_vehicle_id`
- `assigned_center_id`  
- `missing_status`
- `missing_count`

**Action:** Update [FAMILY_FEATURE_DOCUMENTATION.md](FAMILY_FEATURE_DOCUMENTATION.md) to clarify which fields each endpoint actually returns:

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
      "created_at": "2024-01-15 10:30:00",
      // Optional fields (if returned by your API):
      "assigned_vehicle_id": null,
      "assigned_center_id": null,
      "missing_count": 0
    }
  ]
}
```

---

## Implementation Checklist

### Immediate (Before Testing)
- [ ] Verify what fields `get_families.php` actually returns
  - Does it return `assigned_vehicle_id`, `assigned_center_id`, `missing_status`, `missing_count`?
  - Or only database schema fields?
- [ ] Decide on FamilyModel approach (Option A or Option B)
- [ ] Test with real API responses
  
### Short Term (This Sprint)
- [ ] Update FamilyModel to match decision
- [ ] Add type safety to `getFamilyMembers()` method
- [ ] Update FamilyListScreen to use typed UserModel
- [ ] Add null safety checks for all string concatenations

### Longer Term
- [ ] Document all API response fields clearly
- [ ] Add API integration tests
- [ ] Consider creating separate models for API responses vs. domain models

---

## Testing Recommendations

1. **Test API Response Parsing:**
   ```dart
   // Verify FamilyModel can parse actual API response
   final json = await getActualAPIResponse();
   final family = FamilyModel.fromJson(json);
   print(family.familyId);  // Should work without null reference
   ```

2. **Test with Missing Fields:**
   ```dart
   // Test FamilyModel with minimal response
   final minimalJson = {
     'family_id': 1,
     'family_name': 'Test',
     'primary_contact': '123',
     'rescue_status': 'Pending',
     'headcount': 1,
     'created_at': '2024-01-01'
   };
   final family = FamilyModel.fromJson(minimalJson);
   // Should not crash if assigned_vehicle_id is missing
   ```

3. **Test FamilyListScreen with Real Data:**
   - Verify member names display correctly
   - Check missing_count displays properly
   - Test with users that have null fields

---

## Files Requiring Changes

| File | Change Type | Priority | Status |
|------|-------------|----------|--------|
| [lib/models/family_model.dart](lib/models/family_model.dart) | Fix field mapping | HIGH | ⏳ Pending |
| [lib/controllers/family_controller.dart](lib/controllers/family_controller.dart) | Add type safety to getFamilyMembers | HIGH | ⏳ Pending |
| [lib/screens/family_list_screen.dart](lib/screens/family_list_screen.dart) | Update to use typed UserModel | HIGH | ⏳ Pending |
| [FAMILY_FEATURE_DOCUMENTATION.md](FAMILY_FEATURE_DOCUMENTATION.md) | Clarify API response fields | MEDIUM | ⏳ Pending |
| [lib/screens/profile_screen.dart](lib/screens/profile_screen.dart) | Add null safety checks | LOW | ✅ OK |
| [lib/screens/create_family_screen.dart](lib/screens/create_family_screen.dart) | Add null safety checks | LOW | ✅ OK |

---

## Summary

| Component | Schema Match | Type Safety | Risk Level |
|-----------|--------------|-------------|-----------|
| CreateFamilyScreen | ✅ Correct | ✅ Good | 🟢 Low |
| FamilyListScreen | ✅ Correct* | ⚠️ Dynamic types | 🟡 Medium |
| ProfileScreen | ✅ Correct | ✅ Good | 🟢 Low |
| FamilyController | ⚠️ Partial issues | ⚠️ Some untyped | 🟡 Medium |
| FamilyModel | ❌ Over-specified | ⚠️ Extra fields | 🟠 Serious |

**Overall Risk:** 🟡 **MEDIUM** - Functional but needs cleanup before production

**Estimated Fix Time:** 2-3 hours for all fixes

**Recommendation:** Implement Fix #1 and Fix #2 before merging to main branch.
