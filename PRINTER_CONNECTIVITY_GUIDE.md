# Printer Connectivity Implementation Guide

## Overview
This document describes the implementation of Bluetooth and WiFi printer connectivity for the AppZap POS Flutter application, specifically designed for the **DKT-E830 Thermal Receipt Printer**.

## Printer Specifications
- **Model**: DKT-E830
- **Interfaces**: USB/LAN/WiFi
- **Paper Width**: 80mm
- **Print Speed**: 300mm/s
- **Power Input**: 24V ~2.0A
- **Default Network Port**: 9100

## Features Implemented

### 1. Bluetooth Connectivity
- Scan for paired Bluetooth printers
- Connect to Bluetooth thermal printers
- Automatic device filtering (looks for printer-related devices)
- Permission handling for Android 12+

### 2. WiFi/Network Connectivity
- Manual IP address entry
- Configurable port (default: 9100)
- Direct network connection to printer
- Connection status monitoring

### 3. Printer Management
- Save printer configurations
- Connection type selection (Bluetooth/WiFi)
- Test print functionality
- Receipt printing capabilities
- Auto-reconnection support

## File Structure

```
lib/
├── core/
│   └── services/
│       └── printer_service.dart          # Core printer service
├── features/
│   └── settings/
│       ├── providers/
│       │   └── settings_provider.dart    # Updated with printer types
│       ├── screens/
│       │   ├── settings_screen.dart      # Main settings screen
│       │   └── printer_connection_screen.dart  # NEW: Connection UI
│       └── widgets/
│           └── printer_settings_card.dart # Updated printer settings
```

## Dependencies Added

```yaml
# Thermal Printer
esc_pos_printer: ^4.1.0
esc_pos_utils: ^1.1.0

# Bluetooth
flutter_bluetooth_serial: ^0.4.0

# Permissions
permission_handler: ^11.3.1

# Network Info
network_info_plus: ^5.0.3
```

## Usage Guide

### For End Users

#### Connecting via Bluetooth:

1. **Pair Your Printer First**:
   - Go to Android Settings → Bluetooth
   - Turn on Bluetooth
   - Pair with your DKT-E830 printer (usually shows as "DKT-E830" or "Thermal Printer")

2. **Connect in App**:
   - Open AppZap POS
   - Navigate to Settings
   - Go to Printer tab
   - Tap "Connect Printer"
   - Select "Bluetooth" tab
   - Tap "Scan for Devices"
   - Select your printer from the list
   - Tap "Connect"

#### Connecting via WiFi:

1. **Configure Printer's WiFi** (refer to printer manual):
   - Connect printer to your network
   - Note down the printer's IP address
   - Default port is 9100

2. **Connect in App**:
   - Open AppZap POS
   - Navigate to Settings
   - Go to Printer tab
   - Tap "Connect Printer"
   - Select "WiFi" tab
   - Enter printer's IP address (e.g., 192.168.1.100)
   - Enter port (usually 9100)
   - Tap "Connect to Printer"

#### Test Printing:

- After connecting, tap "Test Print" button
- Printer should print a test receipt with connection details

### For Developers

#### Using Printer Service:

```dart
// Get printer service
final printerService = ref.read(printerServiceProvider);

// Scan for Bluetooth devices
final devices = await printerService.scanBluetoothDevices();

// Connect to Bluetooth printer
final success = await printerService.connectBluetooth(device);

// Connect to WiFi printer
final success = await printerService.connectWiFi('192.168.1.100', port: 9100);

// Print test receipt
await printerService.testPrint();

// Print actual receipt
await printerService.printReceipt(
  header: 'My Shop Name',
  items: [
    {'name': 'Coffee', 'quantity': 2, 'price': 15000},
    {'name': 'Cake', 'quantity': 1, 'price': 25000},
  ],
  total: 55000,
  footer: 'Thank you!',
);

// Disconnect
await printerService.disconnect();
```

#### Listening to Connection Status:

```dart
printerService.connectionStatus.listen((isConnected) {
  print('Printer connected: $isConnected');
});
```

## Installation Steps

1. **Install Dependencies**:
```bash
flutter pub get
```

2. **Update Android Configuration**:
The AndroidManifest.xml has been updated with required permissions.

3. **Build and Run**:
```bash
flutter run
```

## Permissions Required

### Android:
- `BLUETOOTH` - Basic Bluetooth functionality
- `BLUETOOTH_ADMIN` - Bluetooth management
- `BLUETOOTH_CONNECT` - Connect to Bluetooth devices (Android 12+)
- `BLUETOOTH_SCAN` - Scan for Bluetooth devices (Android 12+)
- `ACCESS_FINE_LOCATION` - Required for Bluetooth scanning
- `ACCESS_COARSE_LOCATION` - Location access
- `INTERNET` - Network connectivity
- `ACCESS_NETWORK_STATE` - Network state
- `ACCESS_WIFI_STATE` - WiFi state

## Troubleshooting

### Bluetooth Issues:

**Problem**: "Bluetooth permissions not granted"
- **Solution**: Grant location and Bluetooth permissions in app settings

**Problem**: "No devices found"
- **Solution**: 
  1. Make sure printer is powered on
  2. Pair printer in Android Bluetooth settings first
  3. Printer must be within range

**Problem**: "Failed to connect"
- **Solution**:
  1. Unpair and re-pair the printer
  2. Restart the printer
  3. Clear app cache and try again

### WiFi Issues:

**Problem**: "Failed to connect to printer"
- **Solution**:
  1. Verify printer and device are on same network
  2. Check IP address is correct
  3. Ping the printer IP from another device
  4. Check printer's network settings

**Problem**: "Invalid IP address format"
- **Solution**: Use format like `192.168.1.100` (4 numbers separated by dots)

**Problem**: "Connection timeout"
- **Solution**:
  1. Check firewall settings
  2. Verify port number (usually 9100)
  3. Restart printer's network interface

### General Issues:

**Problem**: "Test print fails"
- **Solution**:
  1. Check printer has paper loaded
  2. Verify printer is not in error state
  3. Check printer's paper sensor
  4. Restart the printer

**Problem**: "Print quality issues"
- **Solution**:
  1. Clean printer head
  2. Use recommended thermal paper (80mm)
  3. Check printer settings in manual

## DKT-E830 Specific Notes

### Network Configuration:
1. Access printer's web interface (check manual for default IP)
2. Configure WiFi settings
3. Set static IP for reliable connection
4. Note the IP address for app configuration

### Paper Loading:
- Use 80mm thermal paper
- Load paper correctly (check printer label for direction)
- Ensure paper is not jammed

### Maintenance:
- Clean thermal print head regularly
- Keep printer in dry environment
- Use quality thermal paper to avoid residue

## Testing Checklist

- [ ] Bluetooth permissions granted
- [ ] Bluetooth pairing successful
- [ ] Bluetooth device scan works
- [ ] Bluetooth connection successful
- [ ] WiFi connection with correct IP works
- [ ] Test print produces readable output
- [ ] Receipt printing with items works
- [ ] Printer disconnection works
- [ ] Reconnection after disconnect works
- [ ] Settings persist after app restart

## Future Enhancements

1. **Auto-discovery**: Implement mDNS/Bonjour for WiFi printer discovery
2. **USB Support**: Add USB printer connectivity
3. **Multiple Printers**: Support for multiple printer configurations
4. **Print Queue**: Implement print job queue for reliability
5. **Offline Mode**: Cache print jobs when printer disconnected
6. **Print Templates**: Customizable receipt templates
7. **Barcode Support**: Enhanced barcode/QR code printing
8. **Logo Printing**: Support for business logo on receipts

## API Reference

### PrinterService

#### Methods:
- `Future<bool> requestBluetoothPermissions()` - Request Bluetooth permissions
- `Future<bool> isBluetoothEnabled()` - Check if Bluetooth is enabled
- `Future<bool> enableBluetooth()` - Enable Bluetooth
- `Future<List<PrinterDevice>> scanBluetoothDevices()` - Scan for Bluetooth printers
- `Future<bool> connectBluetooth(PrinterDevice device)` - Connect to Bluetooth printer
- `Future<List<PrinterDevice>> scanWiFiPrinters()` - Scan for WiFi printers
- `Future<bool> connectWiFi(String ipAddress, {int port})` - Connect to WiFi printer
- `Future<void> disconnect()` - Disconnect from printer
- `Future<bool> testPrint()` - Print test page
- `Future<bool> printReceipt({...})` - Print receipt

#### Properties:
- `PrinterDevice? connectedDevice` - Currently connected device
- `bool isConnected` - Connection status
- `Stream<bool> connectionStatus` - Connection status stream

### PrinterDevice

#### Properties:
- `String id` - Device ID
- `String name` - Device name
- `String address` - Device address (MAC or IP:PORT)
- `PrinterConnectionType type` - Connection type (bluetooth/wifi/usb)
- `bool isConnected` - Connection status

### PrinterConnectionType (Enum)
- `bluetooth` - Bluetooth connection
- `wifi` - WiFi/Network connection
- `usb` - USB connection (not yet implemented)

## Support

For issues or questions:
1. Check this documentation
2. Review printer manual
3. Check Flutter package documentation:
   - [esc_pos_printer](https://pub.dev/packages/esc_pos_printer)
   - [flutter_bluetooth_serial](https://pub.dev/packages/flutter_bluetooth_serial)
4. Contact development team

## License

This implementation is part of the AppZap POS application.

---

**Last Updated**: January 19, 2026
**Version**: 1.0.0
**Printer Model**: DKT-E830
