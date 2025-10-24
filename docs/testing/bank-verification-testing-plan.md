# Bank Verification UI Feedback - Testing Plan

## Overview
This document outlines the testing procedures for the bank verification requirement feature. The feature enforces that taskers must verify their bank accounts before applying for tasks.

## Test Environment Setup

### Prerequisites
- Flutter development environment running
- Supabase backend accessible
- Test user account with tasker role
- Admin access to Supabase database (for manual status changes)

### Database Access
To manually change verification status for testing:
```sql
-- Change to unverified
UPDATE taskaway_profiles
SET bank_verification_status = 'unverified'
WHERE id = 'YOUR_USER_ID';

-- Change to pending
UPDATE taskaway_profiles
SET bank_verification_status = 'pending'
WHERE id = 'YOUR_USER_ID';

-- Change to rejected
UPDATE taskaway_profiles
SET bank_verification_status = 'rejected'
WHERE id = 'YOUR_USER_ID';

-- Change to verified
UPDATE taskaway_profiles
SET bank_verification_status = 'verified'
WHERE id = 'YOUR_USER_ID';
```

## Test Cases

### Test Case 1: Unverified State (Default)

**Setup:**
1. Set user's `bank_verification_status` to `'unverified'` in database
2. Hot reload the app (press `r` in terminal)

**Expected Behavior:**

#### 1.1 Tasker Home Screen (`tasker_home_screen.dart`)
- [ ] Orange banner displayed at top of task list
- [ ] Banner shows warning icon (⚠️)
- [ ] Banner title: "Bank Verification Required"
- [ ] Banner message: "Add your bank details to start applying for tasks and receive payments."
- [ ] Status badge: "Status: Unverified" (orange background)
- [ ] Action button: "Add Bank Details" (orange)
- [ ] Clicking button navigates to `/profile/bank-details`

#### 1.2 Task Details Screen (`task_details_screen.dart`)
**When viewing an open task (not posted by user):**
- [ ] "Make an Offer" button is disabled (grayed out)
- [ ] Orange info box displayed below button
- [ ] Info box shows info icon
- [ ] Info box message: "Bank verification required to apply for tasks"
- [ ] "Verify Now" link present in info box
- [ ] Clicking "Verify Now" navigates to `/profile/bank-details`
- [ ] Clicking disabled button does nothing

#### 1.3 Apply Task Screen (`apply_task_screen.dart`)
**Attempt to bypass UI and submit offer:**
1. Somehow access the apply screen (e.g., through deep link)
2. Fill in offer amount and message
3. Click "Submit Offer"

**Expected:**
- [ ] Form validation passes
- [ ] Loading indicator appears briefly
- [ ] Error message displayed: "Bank account verification required. Please verify your bank account in your profile settings to submit offers."
- [ ] Alert dialog appears with title "Bank Verification Required"
- [ ] Dialog content explains verification requirement
- [ ] Dialog has "Cancel" and "Verify Now" buttons
- [ ] "Verify Now" navigates to `/profile/bank-details`
- [ ] Offer is NOT submitted to database

#### 1.4 Backend Validation (`application_controller.dart`)
**Verify server-side protection:**
- [ ] Check Supabase logs for validation error
- [ ] Confirm no new application record created in `taskaway_applications` table
- [ ] Error state properly set in controller

---

### Test Case 2: Pending State

**Setup:**
1. Set user's `bank_verification_status` to `'pending'` in database
2. Hot reload the app

**Expected Behavior:**

#### 2.1 Tasker Home Screen
- [ ] Blue banner displayed at top of task list
- [ ] Banner shows hourglass icon (⏳)
- [ ] Banner title: "Bank Verification in Progress"
- [ ] Banner message: "We're reviewing your bank account details. You'll receive a notification once approved (typically within 24-48 hours)."
- [ ] Status badge: "Status: Pending Approval" (blue background)
- [ ] Action button: "View Status" (blue)
- [ ] Clicking button navigates to `/profile/bank-details`

#### 2.2 Task Details Screen
**Same as unverified state:**
- [ ] "Make an Offer" button is disabled
- [ ] Orange info box displayed
- [ ] "Verify Now" link present (allows user to check status)

#### 2.3 Apply Task Screen
**Same behavior as unverified state:**
- [ ] Pre-submission check blocks offer
- [ ] Dialog appears with verification requirement
- [ ] Offer is NOT submitted

#### 2.4 Backend Validation
- [ ] Server-side validation blocks the offer
- [ ] No application record created

---

### Test Case 3: Rejected State

**Setup:**
1. Set user's `bank_verification_status` to `'rejected'` in database
2. Hot reload the app

**Expected Behavior:**

#### 3.1 Tasker Home Screen
- [ ] Red banner displayed at top of task list
- [ ] Banner shows error icon (⚠️)
- [ ] Banner title: "Bank Verification Failed"
- [ ] Banner message: "Your bank verification was rejected. Please update your details and resubmit for verification."
- [ ] Status badge: "Status: Rejected" (red background)
- [ ] Action button: "Update Details" (red)
- [ ] Clicking button navigates to `/profile/bank-details`

#### 3.2 Task Details Screen
**Same as unverified state:**
- [ ] "Make an Offer" button is disabled
- [ ] Orange info box displayed
- [ ] "Verify Now" link present

#### 3.3 Apply Task Screen
**Same behavior as unverified state:**
- [ ] Pre-submission check blocks offer
- [ ] Dialog appears with verification requirement
- [ ] Offer is NOT submitted

#### 3.4 Backend Validation
- [ ] Server-side validation blocks the offer
- [ ] No application record created

---

### Test Case 4: Verified State (Success Path)

**Setup:**
1. Set user's `bank_verification_status` to `'verified'` in database
2. Hot reload the app

**Expected Behavior:**

#### 4.1 Tasker Home Screen
- [ ] **NO banner displayed** (banner hidden for verified users)
- [ ] Task list displayed normally
- [ ] No verification warnings anywhere

#### 4.2 Task Details Screen
**When viewing an open task (not posted by user):**
- [ ] "Make an Offer" button is **ENABLED** (not grayed out)
- [ ] **NO info box** displayed below button
- [ ] Button has normal styling (yellow background)
- [ ] Clicking button opens offer form (numpad appears)
- [ ] Can proceed with making offer

#### 4.3 Apply Task Screen
**Complete offer submission flow:**
1. Enter valid offer amount (e.g., 150.00)
2. Enter valid message (at least 10 characters)
3. Click "Submit Offer"

**Expected:**
- [ ] No bank verification error
- [ ] Loading indicator appears
- [ ] Offer successfully submitted
- [ ] Success snackbar: "Offer submitted successfully!"
- [ ] Navigation returns to previous screen
- [ ] New record created in `taskaway_applications` table
- [ ] Application status is 'pending'

#### 4.4 Backend Validation
- [ ] Server-side validation passes
- [ ] Application record created successfully
- [ ] Notification sent to task poster

---

### Test Case 5: Edge Cases

#### 5.1 Null/Missing Verification Status
**Setup:**
```sql
UPDATE taskaway_profiles
SET bank_verification_status = NULL
WHERE id = 'YOUR_USER_ID';
```

**Expected:**
- [ ] Banner NOT displayed (treated as unverified or hidden)
- [ ] Button disabled on task details screen
- [ ] Pre-submission check blocks offer
- [ ] Backend validation blocks offer

#### 5.2 Invalid Verification Status
**Setup:**
```sql
UPDATE taskaway_profiles
SET bank_verification_status = 'invalid_status'
WHERE id = 'YOUR_USER_ID';
```

**Expected:**
- [ ] System treats as unverified (default case)
- [ ] Banner uses orange warning style
- [ ] All validations block offer submission

#### 5.3 User Tries to Apply to Own Task
**Setup:**
1. Set verification status to 'verified'
2. Navigate to a task posted by the same user

**Expected:**
- [ ] "Make an Offer" button NOT displayed (existing logic)
- [ ] Bank verification is irrelevant for own tasks
- [ ] No verification banner or warnings

#### 5.4 Guest Users (Not Logged In)
**Expected:**
- [ ] Cannot access tasker home screen
- [ ] Cannot view task details that require offers
- [ ] Redirect to authentication screens

---

## Regression Tests

### Verify Existing Functionality Still Works

#### RT-1: Verified Users Can Still Apply for Tasks
- [ ] Verified user can browse tasks
- [ ] Verified user can click "Make an Offer"
- [ ] Verified user can submit offer successfully
- [ ] Task poster receives notification

#### RT-2: Self-Accept Prevention Still Works
- [ ] Poster cannot see "Make an Offer" on their own tasks
- [ ] Backend still prevents self-acceptance
- [ ] Error message clear if attempted via API

#### RT-3: Navigation Still Works
- [ ] `/profile/bank-details` route exists and loads
- [ ] GoRouter properly navigates from all "Verify Now" buttons
- [ ] Back navigation works correctly
- [ ] Deep links still function

#### RT-4: Profile Loading
- [ ] `currentProfileProvider` loads correctly
- [ ] Profile data includes `bankVerificationStatus` field
- [ ] UI handles loading states properly
- [ ] UI handles error states properly

---

## Performance Tests

### PT-1: Database Query Performance
- [ ] Bank verification check adds minimal latency
- [ ] Single query per offer submission (no N+1 queries)
- [ ] Profile data properly cached by Riverpod

### PT-2: UI Responsiveness
- [ ] Banner renders without layout shifts
- [ ] Button state changes immediately on status update
- [ ] No unnecessary rebuilds when status unchanged

---

## Accessibility Tests

### A11y-1: Screen Reader Support
- [ ] Banner content readable by screen readers
- [ ] Button disabled state announced
- [ ] Error messages announced
- [ ] Dialog content accessible

### A11y-2: Color Contrast
- [ ] Orange banner text readable (contrast ratio ≥ 4.5:1)
- [ ] Blue banner text readable
- [ ] Red banner text readable
- [ ] Disabled button state visually clear

---

## Test Execution Log

| Test ID | Date | Tester | Status | Notes |
|---------|------|--------|--------|-------|
| TC-1.1  |      |        | ⏳ Pending |       |
| TC-1.2  |      |        | ⏳ Pending |       |
| TC-1.3  |      |        | ⏳ Pending |       |
| TC-1.4  |      |        | ⏳ Pending |       |
| TC-2.1  |      |        | ⏳ Pending |       |
| TC-2.2  |      |        | ⏳ Pending |       |
| TC-2.3  |      |        | ⏳ Pending |       |
| TC-2.4  |      |        | ⏳ Pending |       |
| TC-3.1  |      |        | ⏳ Pending |       |
| TC-3.2  |      |        | ⏳ Pending |       |
| TC-3.3  |      |        | ⏳ Pending |       |
| TC-3.4  |      |        | ⏳ Pending |       |
| TC-4.1  |      |        | ⏳ Pending |       |
| TC-4.2  |      |        | ⏳ Pending |       |
| TC-4.3  |      |        | ⏳ Pending |       |
| TC-4.4  |      |        | ⏳ Pending |       |
| TC-5.*  |      |        | ⏳ Pending |       |
| RT-*    |      |        | ⏳ Pending |       |
| PT-*    |      |        | ⏳ Pending |       |
| A11y-*  |      |        | ⏳ Pending |       |

---

## Known Issues

Document any issues found during testing here:

1. **Issue**: [Description]
   - **Severity**: Critical / High / Medium / Low
   - **Steps to Reproduce**:
   - **Expected**:
   - **Actual**:
   - **Fix**:

---

## Sign-off

- [ ] All test cases passed
- [ ] No critical or high severity issues
- [ ] Documentation updated
- [ ] Ready for production deployment

**Tester Name**: ___________________
**Date**: ___________________
**Signature**: ___________________
