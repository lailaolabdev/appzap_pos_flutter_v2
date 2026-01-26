# INVENTORY & MENU INTEGRATION - TESTING GUIDE

## Issues Fixed:

1. **Menu Item Edit Form**: Fixed low stock and initial stock fields not showing when editing
2. **Inventory Creation**: Fixed automatic inventory item creation when menu items with stock tracking are created
3. **Backend Integration**: Improved error handling and logging to identify backend issues

## Step-by-Step Testing

### Test 1: Create Menu Item with Stock Tracking

1. **Go to Menu Screen**
   - Navigate to Menu section in your app
   - Click "Add Item" or "+" button

2. **Fill in Menu Item Details**
   ```
   Name: Test Coca Cola
   Category: Select any category
   Base Price: 8000
   Cost Price: 6000 (IMPORTANT: Must be filled for inventory)
   Track Stock: ✅ Enable this checkbox
   Low Stock Threshold: 10
   Initial Stock: 50
   ```

3. **Save the Item**
   - Click "Save" or "Add Item"
   - You should see success message: "Menu item created successfully! Inventory entry will be created automatically."

4. **Check Console Logs**
   Look for these logs in your Flutter console:
   ```
   🔄 Creating inventory item for menu item: Test Coca Cola
      Restaurant ID: 694e610a507efc4cb5d9fcf3
      Branch ID: 694e610a507efc4cb5d9fcf5
      Track Stock: true
      Cost Price: 6000.0
   ✅ Auto-created inventory item for menu item: Test Coca Cola
   ```

5. **Check Inventory Screen**
   - Wait 2-3 seconds (for backend processing)
   - Go to Inventory screen
   - Should see "Test Coca Cola" with quantity 50

### Test 2: Check Backend Logs

When you create a menu item with stock tracking, check your backend console for:

1. **Menu Item Creation Log**:
   ```
   [MenuItemController] Creating menu item: Test Coca Cola
   ```

2. **Inventory Creation Log**:
   ```
   [InventoryItemController] Auto-creating inventory item for menu item
   ```

### Test 3: Edit Menu Item

1. **Go to Menu Screen**
2. **Click Edit on existing item**
3. **Verify Fields Show Correctly**:
   - Low Stock Threshold should show actual value (not empty)
   - Initial Stock should show current stock value
   - Track Stock checkbox should reflect actual setting

### Debugging Backend Issues

Based on your backend log showing 0 inventory items, here are the likely issues:

#### Issue 1: Menu Item Creation Not Triggering Inventory Creation

**Check your backend menu item creation endpoint** (`POST /api/v1/menu-items`):

1. Does it have logic to auto-create inventory items when `trackStock: true`?
2. Are the required fields (restaurantId, branchId, costPrice) being passed correctly?

#### Issue 2: Database Collection Issues

Check your MongoDB collections:
```javascript
// Check menu items collection
db.menuItems.find({restaurantId: ObjectId("694e610a507efc4cb5d9fcf3")})

// Check inventory items collection  
db.inventoryItems.find({restaurantId: ObjectId("694e610a507efc4cb5d9fcf3")})
```

#### Issue 3: API Endpoint Mismatch

Verify your backend has these endpoints:
- `POST /api/v1/inventory/items` - Create inventory items
- `GET /api/v1/inventory/items` - Get inventory items

### Frontend Debug Commands

Add these debug prints to verify data flow:

1. **In Menu Service** (`menu_service.dart` line ~95):
   ```dart
   print('🔍 Menu item creation request:');
   print('   trackStock: $trackStock');
   print('   costPrice: $costPrice');
   print('   restaurantId: $restaurantId');
   print('   branchId: $branchId');
   ```

2. **In Inventory API Service** (`inventory_api_service.dart` line ~70):
   ```dart
   print('🔍 Inventory creation request:');
   print('   data: ${jsonEncode(data)}');
   print('   endpoint: ${ApiConstants.inventoryItems}');
   ```

### Expected Backend Behavior

When you create a menu item with `trackStock: true`, your backend should:

1. **Create the menu item** in `menuItems` collection
2. **Automatically create inventory item** in `inventoryItems` collection with:
   ```javascript
   {
     name: "Test Coca Cola",
     itemId: "menu_item_id_here", 
     itemType: "menu_item",
     restaurantId: ObjectId("694e610a507efc4cb5d9fcf3"),
     branchId: ObjectId("694e610a507efc4cb5d9fcf5"),
     currentStock: 50,
     minStockLevel: 10,
     costPerUnit: 6000,
     sellingPrice: 8000,
     category: "finished_good",
     status: "active",
     trackStock: true
   }
   ```

3. **Return success** for both operations

### Common Backend Issues & Fixes

#### Issue: Backend Menu Creation Doesn't Create Inventory
**Solution**: Add inventory creation logic to your menu item creation endpoint:

```javascript
// In your menu item controller
if (menuItemData.inventory?.trackStock) {
  await InventoryService.createInventoryItem({
    name: menuItemData.name,
    itemId: createdMenuItem._id,
    itemType: 'menu_item',
    restaurantId: menuItemData.restaurantId,
    branchId: menuItemData.branchId,
    currentStock: 0, // or initial stock from request
    costPerUnit: menuItemData.pricing.costPrice,
    // ... other fields
  });
}
```

#### Issue: Inventory Service Not Creating Items
**Check**: 
- Is your inventory creation endpoint receiving the request?
- Are all required fields present?
- Is the database connection working?
- Are there validation errors?

### Next Steps

1. **Test with new menu item** following Test 1 above
2. **Check both frontend and backend logs** for errors
3. **Verify database contents** manually
4. **If still not working**, share your backend menu item creation code

The frontend changes are now correct and should work with a properly configured backend that automatically creates inventory entries when menu items with stock tracking are created.