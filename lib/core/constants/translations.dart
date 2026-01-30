class Translations {
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // Common
      'app_name': 'AppZap POS',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',

      // Settings
      'settings': 'Settings',
      'printer': 'Printer',
      'language': 'Language',
      'english': 'English',
      'lao': 'Lao',
      'language_changed': 'Language changed to:',
      'language_note': 'Language changes will be applied after app restart.',

      // Printer
      'printer_settings': 'Printer Settings',
      'printer_config': 'Printer Config',
      'receipt_config': 'Receipt Config',
      'printer_connected': 'Printer Connected',
      'printer_disconnected': 'Printer Disconnected',
      'no_printer_configured': 'No printer configured',
      'test_print': 'Test Print',
      'configure_your_printer': 'Configure Your Printer',
      'configure_your_receipt': 'Configure Your Receipt',
      'printer_configuration': 'Printer Configuration',
      'receipt_configuration': 'Receipt Configuration',
      'connect_printer': 'Connect Printer',
      'bluetooth': 'Bluetooth',
      'wifi': 'WiFi',
      'pair_bluetooth_first':
          'Pair your Bluetooth printer in your device settings first, then scan for devices.',
      'scan_for_devices': 'Scan for Devices',
      'scanning': 'Scanning...',
      'no_devices_found': 'No devices found',
      'tap_scan_to_start': 'Tap "Scan for Devices" to start',
      'connect': 'Connect',
      'enter_ip_address': 'Enter your printer\'s IP address and port',
      'find_info_in_settings':
          'You can find this information in your printer\'s network settings or configuration page.',
      'ip_address': 'IP Address',
      'ip_hint': '192.168.1.100',
      'port': 'Port',
      'port_hint': '9100',
      'connecting': 'Connecting...',
      'connection_tips': 'Connection Tips',
      'same_wifi_network':
          '• Make sure your printer and device are on the same WiFi network',
      'default_port_9100':
          '• Default port for thermal printers is usually 9100',
      'check_manual':
          '• Check your printer\'s manual for network configuration',
      'dkt_e830_tips':
          '• For DKT-E830: Access printer settings via web interface',
      'connected': 'Connected',
      'not_connected': 'Not Connected',
      'printer_name': 'Printer Name',
      'printer_name_hint': 'e.g., Kitchen Printer, Receipt Printer',
      'enable_receipt_printing': 'Enable Receipt Printing',
      'print_receipts_auto': 'Print receipts automatically after checkout',
      'enable_barcode_printing': 'Enable Barcode Printing',
      'print_barcodes_receipts': 'Print barcodes on receipts',
      'save_settings': 'Save Settings',
      'printer_settings_saved': 'Printer settings saved successfully',
      'receipt_customization': 'Receipt Customization',
      'receipt_header': 'Receipt Header',
      'receipt_header_hint': 'Restaurant Name\nAddress\nPhone Number',
      'receipt_header_helper': 'Text to appear at the top of receipts',
      'receipt_footer': 'Receipt Footer',
      'receipt_footer_hint': 'Thank you for your business!\nVisit us again!',
      'receipt_footer_helper': 'Text to appear at the bottom of receipts',
      'receipt_footer_required': 'Please enter a receipt footer',
      'receipt_preview': 'Receipt Preview',
      'receipt_sample_date': 'Order #12345\nDate: Jan 6, 2026 10:30 AM',
      'receipt_sample_items':
          'Item 1        \$10.00\nItem 2        \$15.00\n-------------------\nTotal         \$25.00',
      'save_receipt_settings': 'Save Receipt Settings',
      'receipt_settings_saved': 'Receipt settings saved successfully',

      // Navigation
      'home': 'Home',
      'menu': 'Menu',
      'orders': 'Orders',
      'customers': 'Customers',
      'inventory': 'Inventory',
      'reports': 'Reports',
      'transactions': 'Transactions',
      'pos': 'POS',

      // Order
      'order_id': 'Order ID',
      'table_number': 'Table Number',
      'server': 'Server',
      'items': 'Items',
      'total': 'Total',
      'subtotal': 'Subtotal',
      'discount': 'Discount',
      'tax': 'Tax',

      // Payment
      'payment': 'Payment',
      'cash': 'Cash',
      'card': 'Card',
      'amount': 'Amount',
      'change': 'Change',
      'checkout': 'Checkout',

      // Inventory
      'inventory_items': 'Inventory Items',
      'product': 'Product',
      'price': 'Price',
      'quantity': 'Quantity',
      'stock': 'Stock',
      'category': 'Category',

      // Reports
      'daily_sales': 'Daily Sales',
      'monthly_sales': 'Monthly Sales',
      'sales_report': 'Sales Report',
      'payment_report': 'Payment Report',
    },
    'lo': {
      // Common
      'app_name': 'AppZap ໄປສ',
      'cancel': 'ຍົກເລີກ',
      'save': 'ບັນທຶກ',
      'delete': 'ລຶບ',
      'edit': 'ແກ້ໄຂ',
      'add': 'ເພີ່ມ',
      'search': 'ຊອກຫາ',
      'loading': 'ກຳລັງໂຫລດ...',
      'error': 'ຜິດພາດ',
      'success': 'ສຳເລັດ',

      // Settings
      'settings': 'ການຕັ້ງຄ່າ',
      'printer': 'ເຄື່ອງພິມ',
      'language': 'ພາສາ',
      'english': 'ພາສາອັງກິດ',
      'lao': 'ພາສາລາວ',
      'language_changed': 'ພາສາປ່ຽນເປັນ:',
      'language_note': 'ການປ່ຽນພາສາຈະຖືກນຳໃຊ້ຫຼັງຈາກລີສະຕາດແອັບແລ້ວ',

      // Printer
      'printer_settings': 'ການຕັ້ງຄ່າເຄື່ອງພິມ',
      'printer_config': 'ການຕັ້ງຄ່າເຄື່ອງພິມ',
      'receipt_config': 'ການຕັ້ງຄ່າໃບບິນ',
      'printer_connected': 'ເຄື່ອງພິມເຊື່ອມຕໍ່ແລ້ວ',
      'printer_disconnected': 'ເຄື່ອງພິມບໍ່ທັນເຊື່ອມຕໍ່',
      'no_printer_configured': 'ບໍ່ມີເຄື່ອງພິມທີ່ຖືກກຳນົດ',
      'test_print': 'ທົດສອບການພິມ',
      'configure_your_printer': 'ກຳນົດຄ່າເຄື່ອງພິມຂອງທ່ານ',
      'configure_your_receipt': 'ກຳນົດຄ່າໃບບິນຂອງທ່ານ',
      'printer_configuration': 'ການຕັ້ງຄ່າເຄື່ອງພິມ',
      'receipt_configuration': 'ການຕັ້ງຄ່າໃບບິນ',
      'connect_printer': 'ເຊື່ອມຕໍ່ເຄື່ອງພິມ',
      'bluetooth': 'Bluetooth',
      'wifi': 'WiFi',
      'pair_bluetooth_first':
          'ຈັບຄູ່ເຄື່ອງພິມ Bluetooth ຂອງທ່ານຜ່ານການຕັ້ງຄ່າອຸປະກອນກ່ອນ ຈາກນັ້ນສະແກນອຸປະກອນ',
      'scan_for_devices': 'ສະແກນອຸປະກອນ',
      'scanning': 'ກຳລັງສະແກນ...',
      'no_devices_found': 'ບໍ່ພົບອຸປະກອນ',
      'tap_scan_to_start': 'ແຕະ "ສະແກນອຸປະກອນ" ເພື່ອເລີ່ມຕົ້ນ',
      'connect': 'ເຊື່ອມຕໍ່',
      'enter_ip_address': 'ໃສ່ທີ່ຢູ່ IP ແລະພอດຂອງເຄື່ອງພິມຂອງທ່ານ',
      'find_info_in_settings':
          'ທ່ານສາມາດຊອກຫາຂໍ້ມູນນີ້ໃນການຕັ້ງຄ່າເຄືອຂ່າຍຂອງເຄື່ອງພິມ ຫຼືໜ້າຕັ້ງຄ່າ',
      'ip_address': 'ທີ່ຢູ່ IP',
      'ip_hint': '192.168.1.100',
      'port': 'ພອດ',
      'port_hint': '9100',
      'connecting': 'ກຳລັງເຊື່ອມຕໍ່...',
      'connection_tips': 'ຄຳແນະນຳການເຊື່ອມຕໍ່',
      'same_wifi_network':
          '• ໝັ້ນໃຈວ່າເຄື່ອງພິມ ແລະອຸປະກອນຂອງທ່ານຢູ່ໃນເຄືອຂ່າຍ WiFi ດຽວກັນ',
      'default_port_9100':
          '• ພອດເລີ່ມຕົ້ນສໍາລັບເຄື່ອງພິມ thermal ໂດຍປົກກະຕິແມ່ນ 9100',
      'check_manual': '• ກວດເບິ່ງຄູ່ມືເຄື່ອງພິມຂອງທ່ານສໍາລັບການຕັ້ງຄ່າເຄືອຂ່າຍ',
      'dkt_e830_tips':
          '• ສໍາລັບ DKT-E830: ເຂົ້າໄປໃນການຕັ້ງຄ່າເຄື່ອງພິມຜ່ານຕົວเລືອກເວບ',
      'connected': 'ເຊື່ອມຕໍ່ແລ້ວ',
      'not_connected': 'ບໍ່ທັນເຊື່ອມຕໍ່',
      'printer_name': 'ຊື່ເຄື່ອງພິມ',
      'printer_name_hint': 'ເຊັ່ນ: ເຄື່ອງພິມໄກ່, ເຄື່ອງພິມໃບບິນ',
      'enable_receipt_printing': 'ເປີດການພິມໃບບິນ',
      'print_receipts_auto': 'ພິມໃບບິນໂດຍອັດຕະໂນມັດຫຼັງຈາກທຳການຊໍາລະ',
      'enable_barcode_printing': 'ເປີດການພິມບາໂຄດ',
      'print_barcodes_receipts': 'ພິມບາໂຄດໃນໃບບິນ',
      'save_settings': 'ບັນທຶກການຕັ້ງຄ່າ',
      'printer_settings_saved': 'ບັນທຶກການຕັ້ງຄ່າເຄື່ອງພິມສຳເລັດ',
      'receipt_customization': 'ກຳນົດຄ່າໃບບິນ',
      'receipt_header': 'ສ່ວນຫົວໃບບິນ',
      'receipt_header_hint': 'ຊື່ຮ້ານອາຫານ\nທີ່ຢູ່\nເບີໂທ',
      'receipt_header_helper': 'ຂໍ້ຄວາມທີ່ປາກົດຢູ່ດ້ານເທິງຂອງໃບບິນ',
      'receipt_footer': 'ສ່ວນລຸ່ມໃບບິນ',
      'receipt_footer_hint':
          'ຂອບໃຈທີ່ໃຫ້ການສະໜັບສະໜູນ!\nມາເບິ່ງຢ້ຽມຊຳອີກເທື່ອ!',
      'receipt_footer_helper': 'ຂໍ້ຄວາມທີ່ປາກົດຢູ່ດ້ານລຸ່ມຂອງໃບບິນ',
      'receipt_footer_required': 'ກະລຸນາໃສ່ກະບົາງລ່າງໃບບິນ',
      'receipt_preview': 'ສະແດງຕົວຢ່າງໃບບິນ',
      'receipt_sample_date': 'ສັ່ງຊື້ #12345\nວັນທີ: Jan 6, 2026 10:30 AM',
      'receipt_sample_items':
          'ສິນຄ້າ 1        \$10.00\nສິນຄ້າ 2        \$15.00\n-------------------\nລວມທັງໝົດ         \$25.00',
      'save_receipt_settings': 'ບັນທຶກການຕັ້ງຄ່າໃບບິນ',
      'receipt_settings_saved': 'ບັນທຶກການຕັ້ງຄ່າໃບບິນສຳເລັດ',
      // Navigation
      'home': 'ໜ້າຫຼັກ',
      'menu': 'ເມນູ',
      'orders': 'ສັ່ງຊື້',
      'customers': 'ລູກຄ້າ',
      'inventory': 'ສິນຄ້າ',
      'reports': 'ລາຍງານ',
      'transactions': 'ທຸລະກໍາ',
      'pos': 'ເຖົ້າ​ໂຕະ',

      // Order
      'order_id': 'ລະຫັດສັ່ງຊື້',
      'table_number': 'ເລກໂຕະ',
      'server': 'ພະນັກງານ',
      'items': 'ລາຍການ',
      'total': 'ທັງໝົດ',
      'subtotal': 'ລວມຍ່ອຍ',
      'discount': 'ສ່ວນຫຼຸດ',
      'tax': 'ອາກອນ',

      // Payment
      'payment': 'ການຈ່າຍເງິນ',
      'cash': 'ເງິນສົດ',
      'card': 'ບັດ',
      'amount': 'ຈໍານວນ',
      'change': 'ເງິນທອນ',
      'checkout': 'ຊໍາລະ',

      // Inventory
      'inventory_items': 'ລາຍການສິນຄ້າ',
      'product': 'ສິນຄ້າ',
      'price': 'ລາຄາ',
      'quantity': 'ຈໍານວນ',
      'stock': 'ສະ​ຕ໋ັກ',
      'category': 'ປະເພດ',

      // Reports
      'daily_sales': 'ຍອດຂາຍປະຈໍາວັນ',
      'monthly_sales': 'ຍອດຂາຍປະຈໍາເດືອນ',
      'sales_report': 'ລາຍງານຍອດຂາຍ',
      'payment_report': 'ລາຍງານການຈ່າຍເງິນ',
    },
  };

  static String get(String key, String languageCode) {
    return _translations[languageCode]?[key] ??
        _translations['en']![key] ??
        key;
  }

  static List<String> get supportedLanguages => ['en', 'lo'];
  static String getLanguageName(String code) {
    return code == 'lo' ? 'ພາສາລາວ (Lao)' : 'English';
  }
}
