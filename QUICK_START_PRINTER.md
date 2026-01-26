# Quick Start Guide - Printer Connectivity

## What Was Implemented

✅ **Bluetooth Printer Connectivity**
- Scan and connect to paired Bluetooth thermal printers
- Permission handling for Android
- Real-time connection status

✅ **WiFi/Network Printer Connectivity**
- Connect via IP address and port
- Direct socket connection to network printers
- Manual configuration support

✅ **Printer Management Features**
- Connection status monitoring
- Test print functionality
- Receipt printing with ESC/POS commands
- Connection persistence across app restarts
- Disconnect/reconnect capabilities

## Files Created/Modified

### New Files:
1. `lib/core/services/printer_service.dart` - Core printer connectivity service
2. `lib/features/settings/screens/printer_connection_screen.dart` - Connection UI
3. `PRINTER_CONNECTIVITY_GUIDE.md` - Comprehensive documentation

### Modified Files:
1. `pubspec.yaml` - Added printer dependencies
2. `lib/features/settings/providers/settings_provider.dart` - Added connection type support
3. `lib/features/settings/widgets/printer_settings_card.dart` - Updated UI
4. `android/app/src/main/AndroidManifest.xml` - Added permissions

## How to Use

### Step 1: Test the App
```bash
flutter run
```

### Step 2: Connect Bluetooth Printer

1. **Pair your DKT-E830 printer in Android Bluetooth settings**
2. Open the app → Settings → Printer tab
3. Tap "Connect Printer"
4. Select "Bluetooth" tab
5. Tap "Scan for Devices"
6. Select your printer and tap "Connect"
7. Tap "Test Print" to verify

### Step 3: Connect WiFi Printer

1. **Configure your printer's network settings** (see printer manual)
2. Note the printer's IP address
3. Open the app → Settings → Printer tab
4. Tap "Connect Printer"
5. Select "WiFi" tab
6. Enter IP address (e.g., `192.168.1.100`)
7. Enter port (usually `9100`)
8. Tap "Connect to Printer"
9. Tap "Test Print" to verify

## Printer Configuration for DKT-E830

### Finding Printer IP Address:

**Method 1: Print Configuration**
- Most thermal printers can print their network config
- Press and hold the feed button while turning on
- Look for the IP address on the printed receipt

**Method 2: Router Admin Panel**
- Log into your router
- Check connected devices
- Look for "DKT-E830" or similar device name

**Method 3: Network Scanner App**
- Use a network scanner app on your phone
- Scan for devices on port 9100
- Look for thermal printer devices

### Setting Static IP (Recommended):

1. Access printer web interface (use default IP from manual)
2. Go to Network Settings
3. Set static IP address (e.g., 192.168.1.100)
4. Save and restart printer
5. Use this IP in the app

## Permissions

The app will request these permissions on Android:
- ✓ Bluetooth access
- ✓ Bluetooth scanning
- ✓ Bluetooth connection
- ✓ Location (required for Bluetooth on Android)
- ✓ Network access

**Important**: Make sure to grant all permissions when prompted!

## Troubleshooting

### "No devices found" when scanning Bluetooth
→ Make sure printer is paired in Android Bluetooth settings first

### "Failed to connect" via Bluetooth
→ Try unpairing and re-pairing the printer in Android settings

### "Connection timeout" via WiFi
→ Check that printer and phone are on same network
→ Verify IP address is correct
→ Try pinging the printer IP from another device

### Test print doesn't work
→ Check printer has paper loaded
→ Verify printer is powered on and not in error state
→ Check printer connection LED

### Nothing prints
→ Ensure printer supports ESC/POS commands (DKT-E830 does)
→ Try restarting the printer
→ Check printer settings via web interface

## Next Steps

1. **Test with your actual printer**
   - Connect your DKT-E830
   - Run test print
   - Verify output

2. **Integrate with checkout**
   - Use `printerService.printReceipt()` in your checkout flow
   - Pass order items and total
   - Handle print failures gracefully

3. **Customize receipts**
   - Modify header/footer in settings
   - Add business logo (future enhancement)
   - Customize layout in `printer_service.dart`

## Code Example: Print Receipt from Order

```dart
// In your checkout completion code:
final printerService = ref.read(settingsProvider.notifier).printerService;
final settings = ref.read(settingsProvider);

if (printerService.isConnected && settings.enableReceiptPrinting) {
  await printerService.printReceipt(
    header: settings.receiptHeader,
    items: orderItems.map((item) => {
      'name': item.name,
      'quantity': item.quantity,
      'price': item.price,
    }).toList(),
    total: orderTotal,
    footer: settings.receiptFooter,
  );
}
```

## Support

- See [PRINTER_CONNECTIVITY_GUIDE.md](PRINTER_CONNECTIVITY_GUIDE.md) for detailed documentation
- Check printer manual for network configuration
- Test with simple receipt first before production use

## Dependencies Added

```yaml
flutter_bluetooth_serial: ^0.4.0  # Bluetooth connectivity
permission_handler: ^11.3.1        # Permission management
network_info_plus: ^5.0.3          # Network information
```

---

**Status**: ✅ Ready for testing
**Printer Model**: DKT-E830 (80mm thermal receipt printer)
**Supported Connections**: Bluetooth, WiFi/Network
**Print Format**: ESC/POS commands
