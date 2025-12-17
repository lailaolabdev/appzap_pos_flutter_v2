# 🧪 Self-Service Onboarding - Testing Guide

**Quick Reference for Testing the New Self-Service Registration Flow**

---

## ✅ Prerequisites

- Backend API running with updated auth flow
- Flutter app compiled with latest changes
- Backend in development mode (OTP in console)

---

## 📱 Test Scenario 1: New User Registration (Main Feature!)

### **Goal:** Test complete self-service signup

```bash
# Step 1: Start App
flutter run

# Step 2: Login Screen
✓ Enter phone: 020 99999999 (not in database)
✓ Tap "Send OTP"

# Step 3: Check Backend Console
Look for:
============================================================
🔢 OTP Code: 123456
============================================================

# Step 4: OTP Screen
✓ Enter OTP: 123456
✓ Tap "Verify"

# Step 5: Registration Screen Appears! ⭐
✓ Should see: "Almost there!"
✓ Should see: "Phone verified: +85620199999999" with green checkmark
✓ Should see: 3 input fields

# Step 6: Fill Form
✓ Name: "Test User"
✓ Restaurant: "Test Coffee Shop"
✓ (Optional) Check "Yes, setup PIN now"
✓ (Optional) PIN: "1234"

# Step 7: Submit
✓ Tap "Create Account & Start Selling" (with rocket icon)
✓ Should show loading spinner

# Expected Results:
✅ Welcome message: "Welcome to AppZap POS! 🎉"
✅ Navigates to POS screen
✅ User is logged in
✅ Can see products, create orders, etc.

# Verify in Backend:
✅ New restaurant created: "Test Coffee Shop"
✅ New branch created: "Main Branch"
✅ New user created with role "owner"
✅ User has all permissions
```

**✅ PASS if:** User can create account and start using POS immediately

---

## 📱 Test Scenario 2: Existing User Login

### **Goal:** Ensure existing users still login normally

```bash
# Step 1: Login Screen
✓ Enter phone: 020 12345678 (existing user in database)
✓ Tap "Send OTP"

# Step 2: Check Backend Console
Look for OTP code

# Step 3: OTP Screen
✓ Enter OTP: 123456
✓ Tap "Verify"

# Expected Results:
✅ NO registration screen (directly to POS)
✅ User logged in immediately
✅ Can access all features
✅ (Optional) PIN setup suggestion if no PIN
```

**✅ PASS if:** Existing users login without seeing registration

---

## 📱 Test Scenario 3: PIN Login (Fast)

### **Goal:** Test fast PIN login

```bash
# Prerequisites: User has PIN set up

# Step 1: Login Screen
✓ Enter phone: 020 12345678
✓ Tap "Login with PIN instead" (lightning icon)

# Step 2: PIN Login Screen
✓ Enter PIN: 1234
✓ Tap "Login"

# Expected Results:
✅ Login in ~2 seconds
✅ Navigate to POS screen
✅ Fully authenticated
```

**✅ PASS if:** PIN login works and is fast

---

## 📱 Test Scenario 4: Registration with PIN Setup

### **Goal:** Test optional PIN during registration

```bash
# Follow Test Scenario 1, but:

# At Step 6 (Fill Form):
✓ Name: "PIN Test User"
✓ Restaurant: "PIN Test Shop"
✓ CHECK "Yes, setup PIN now" ⭐
✓ PIN: "5678"

# After Submit:
✅ Account created with PIN
✅ Can logout and login with PIN immediately

# Verify PIN Works:
1. Logout from settings
2. Login screen → "Login with PIN instead"
3. Phone: [the new user's phone]
4. PIN: 5678
5. Should login successfully
```

**✅ PASS if:** PIN is set during registration and works immediately

---

## 📱 Test Scenario 5: Registration without PIN

### **Goal:** Test that PIN is truly optional

```bash
# Follow Test Scenario 1, but:

# At Step 6 (Fill Form):
✓ Name: "No PIN User"
✓ Restaurant: "No PIN Shop"
✓ DO NOT check PIN checkbox
✓ Submit

# After Login:
✅ Account created successfully
✅ User logged in
✅ Can use app fully

# Later (optional):
✅ Can setup PIN from settings
✅ Can always login with OTP
```

**✅ PASS if:** Registration works without PIN requirement

---

## 🔴 Error Test Scenarios

### **Test E1: Invalid OTP**

```bash
# Step 1-2: Send OTP
# Step 3: Enter WRONG OTP
✓ Enter: 999999

# Expected:
❌ Error: "Invalid OTP. 2 attempts remaining."
❌ OTP field cleared
✓ Can retry
```

---

### **Test E2: Empty Registration Fields**

```bash
# In Registration Screen:
✓ Leave name empty
✓ Tap Submit

# Expected:
❌ Error under name field: "Please enter your name"
❌ Form not submitted
✓ Can correct and retry
```

---

### **Test E3: Short Name/Restaurant**

```bash
# In Registration Screen:
✓ Name: "A" (too short)
✓ Tap Submit

# Expected:
❌ Error: "Name must be at least 2 characters"
```

---

### **Test E4: Invalid PIN**

```bash
# In Registration Screen:
✓ Check "Yes, setup PIN now"
✓ PIN: "12" (only 2 digits)
✓ Tap Submit

# Expected:
❌ Error: "PIN must be exactly 4 digits"
```

---

## 📊 Visual Verification Checklist

### **Login Screen:**
- [ ] Clean, modern design
- [ ] "Send OTP" button visible
- [ ] "Login with PIN instead" link visible
- [ ] Phone input with +856 prefix

### **OTP Screen:**
- [ ] Countdown timer visible
- [ ] 6-digit OTP input
- [ ] Resend OTP button
- [ ] Clear error messages

### **Registration Screen:**
- [ ] "Almost there!" heading
- [ ] Green checkmark with verified phone
- [ ] 3 input fields (name, restaurant, PIN optional)
- [ ] Orange card for PIN setup
- [ ] Benefits card at bottom
- [ ] Rocket icon on submit button
- [ ] Terms and privacy text

### **Success State:**
- [ ] POS screen loads
- [ ] Welcome snackbar shows
- [ ] Products visible
- [ ] User can navigate

---

## 🎯 Acceptance Criteria

### **Must Pass:**
✅ New users can self-register  
✅ Only 3 required fields (name, restaurant, phone)  
✅ PIN is optional  
✅ Account created automatically  
✅ User logged in after registration  
✅ Restaurant and branch created  
✅ Owner role assigned  
✅ Full permissions granted  
✅ Existing users login normally  
✅ PIN login works  
✅ Error handling works  
✅ Form validation works  
✅ No crashes or freezes  

### **Should Work:**
✅ OTP resend after expiry  
✅ Change phone number  
✅ Back navigation  
✅ Keyboard handling  
✅ Loading states  
✅ Success animations  

---

## 🐛 Known Issues to Check

- [ ] Registration token expiration (15 min)
- [ ] Network errors during registration
- [ ] Duplicate phone registration attempt
- [ ] Special characters in name/restaurant
- [ ] Very long names (>50 chars)
- [ ] Rapid tap on submit button
- [ ] App kill during registration

---

## 📸 Screenshots to Capture

1. **Login Screen** - Clean state
2. **OTP Screen** - With countdown
3. **Registration Screen** - Empty form
4. **Registration Screen** - Filled form
5. **Registration Screen** - PIN setup checked
6. **Success Screen** - POS after registration
7. **Welcome Message** - Snackbar
8. **Error States** - Validation errors

---

## ⏱️ Performance Benchmarks

| Flow | Target | Actual | Status |
|------|--------|--------|--------|
| OTP Send | <2s | ___s | __ |
| OTP Verify (existing) | <1s | ___s | __ |
| OTP Verify (new) | <1s | ___s | __ |
| Registration Submit | <3s | ___s | __ |
| PIN Login | <1s | ___s | __ |
| Total (new user) | <60s | ___s | __ |

---

## 🎉 Success Criteria

**✅ READY FOR PRODUCTION if:**

1. All test scenarios pass
2. No crashes or errors
3. Performance meets targets
4. UI looks professional
5. Error messages are clear
6. Happy path is smooth
7. Edge cases handled
8. Backend integration works
9. Security maintained
10. User experience is excellent

---

## 📝 Test Report Template

```
Date: _______________
Tester: _______________
Build: _______________

Test Results:
[ ] Scenario 1: New User Registration
[ ] Scenario 2: Existing User Login  
[ ] Scenario 3: PIN Login
[ ] Scenario 4: Registration with PIN
[ ] Scenario 5: Registration without PIN
[ ] Error Test E1
[ ] Error Test E2
[ ] Error Test E3
[ ] Error Test E4

Issues Found:
1. _______________
2. _______________
3. _______________

Overall Status: [ ] PASS  [ ] FAIL
Notes: _______________
```

---

## 🚀 Ready to Test?

1. ✅ Backend running
2. ✅ Development mode enabled
3. ✅ App compiled with changes
4. ✅ Test phone numbers ready
5. ✅ This guide open

**Let's test! 🧪**

---

**Quick Test Command:**
```bash
# Run app
flutter run

# Test new user registration
# Phone: 020 99999999
# Name: Test User
# Restaurant: Test Shop
# PIN: Optional

# Should complete in ~60 seconds!
```

---

**END OF TESTING GUIDE**

*For detailed implementation info, see: `SELF_SERVICE_ONBOARDING_COMPLETE.md`*

