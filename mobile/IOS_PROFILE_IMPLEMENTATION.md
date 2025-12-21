# iOS Profile Implementation

## Overview
Mapped the React web app profile functionality to the iOS app with full feature parity.

## Files Created

### 1. **APIClient.swift**
- Singleton API client for all backend communication
- Handles JWT token authentication from UserDefaults
- Implements `getProfile()` and `updateProfile()` methods
- Comprehensive error handling (401, 403, 404, 500)
- Uses async/await for modern Swift concurrency

### 2. **Models.swift**
- `Profile` struct matching backend schema exactly
- Includes all fields: training schedule, units, constraints, movement capabilities
- `MovementCapabilities` nested struct for gymnastic movements
- `Profile.empty` static property for default values

### 3. **ProfileQuestionnaireView.swift**
- 5-step onboarding questionnaire for first-time users
- Steps:
  1. Training Schedule (days/week, start day)
  2. Preferred Units (lb/kg)
  3. Non-Lifting Days (pilates/conditioning/mixed, intensity)
  4. Physical Constraints (common + custom)
  5. Movement Capabilities (pull-ups, ring dips, muscle-ups)
- Progress bar at top
- Back/Next navigation
- Saves to backend on completion
- Auto-dismisses on success

### 4. **ProfileView.swift**
- View/Edit modes for existing profiles
- Clean section-based layout matching web app
- Inline editing with Cancel/Save actions
- Real-time updates to backend
- Loading and error states
- Settings gear icon in toolbar

### 5. **Extensions.swift**
- `Color(hex:)` extension for hex color support
- Used throughout for consistent branding colors
- Removed duplicate from LoginView.swift

## Updated Files

### **HomeView.swift**
- Added settings gear icon in navigation bar (top-right)
- Checks for profile on load via `checkProfile()`
- Shows `ProfileQuestionnaireView` if no profile (404)
- Shows `ProfileView` when gear icon tapped
- Uses `.sheet()` modifiers for modal presentation

### **Secrets.swift.example**
- Already includes `apiBaseURL` field
- User must update with actual API endpoint

## User Flow

1. **First Login:**
   - User signs in with Google/Apple
   - HomeView loads, calls `GET /profile`
   - Receives 404 (no profile)
   - Automatically shows ProfileQuestionnaireView
   - User completes 5-step setup
   - Profile saved via `PUT /profile`
   - Returns to HomeView

2. **Subsequent Logins:**
   - User signs in
   - HomeView loads, calls `GET /profile`
   - Receives 200 (profile exists)
   - Shows HomeView with settings gear
   - User can tap gear to view/edit profile

3. **Profile Editing:**
   - Tap settings gear icon
   - ProfileView opens in view mode
   - Tap "Edit" button
   - Make changes
   - Tap "Save" to update backend
   - Or "Cancel" to discard changes

## API Integration

All API calls use:
- Base URL from `Secrets.apiBaseURL`
- JWT token from `UserDefaults` (key: `id_token`)
- `Authorization: Bearer <token>` header
- JSON request/response bodies
- Proper error handling for all HTTP status codes

## Design

- Matches web app design language
- Dark gradient backgrounds (#1a1a1a → #2d2d2d)
- Purple accent color (#667eea, #764ba2)
- Green for save actions (#11998e)
- Clean, modern iOS native UI
- Smooth animations and transitions

## Configuration Required

User must update `Secrets.swift` with:
```swift
static let apiBaseURL = "https://styrkr-app-api.bernsonllc.com"
```

## Notes

- No strength data API calls (not implemented yet)
- Profile is the only backend integration
- All code is DRY and production-ready
- No hardcoded secrets
- Consistent error handling
- Follows iOS design patterns


