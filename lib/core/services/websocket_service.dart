import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_constants.dart';
import 'storage_service.dart';

/// WebSocket event types
enum WebSocketEvent {
  orderCreated,
  orderUpdated,
  orderCompleted,
  paymentCompleted,
  paymentFailed,
  inventoryLowStock,
  inventoryOutOfStock,
}

/// WebSocket message model
class WebSocketMessage {
  final WebSocketEvent event;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  WebSocketMessage({
    required this.event,
    required this.data,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();
}

/// WebSocket connection state
enum WebSocketState { disconnected, connecting, connected, error }

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return WebSocketService(storage);
});

/// Real-time WebSocket service for live updates
class WebSocketService {
  final StorageService _storage;

  io.Socket? _socket;
  WebSocketState _state = WebSocketState.disconnected;
  String? _currentRoom;

  final _stateController = StreamController<WebSocketState>.broadcast();
  final _messageController = StreamController<WebSocketMessage>.broadcast();

  // Event-specific streams
  final _orderEventsController = StreamController<WebSocketMessage>.broadcast();
  final _paymentEventsController =
      StreamController<WebSocketMessage>.broadcast();
  final _inventoryEventsController =
      StreamController<WebSocketMessage>.broadcast();

  WebSocketService(this._storage);

  /// Get current connection state
  WebSocketState get state => _state;

  /// Check if connected
  bool get isConnected => _state == WebSocketState.connected;

  /// State stream
  Stream<WebSocketState> get stateStream => _stateController.stream;

  /// All messages stream
  Stream<WebSocketMessage> get messageStream => _messageController.stream;

  /// Order events stream
  Stream<WebSocketMessage> get orderEvents => _orderEventsController.stream;

  /// Payment events stream
  Stream<WebSocketMessage> get paymentEvents => _paymentEventsController.stream;

  /// Inventory events stream
  Stream<WebSocketMessage> get inventoryEvents =>
      _inventoryEventsController.stream;

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_state == WebSocketState.connecting ||
        _state == WebSocketState.connected) {
      return;
    }

    _updateState(WebSocketState.connecting);

    try {
      final token = await _storage.getAccessToken();

      _socket = io.io(
        ApiConstants.wsUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .build(),
      );

      _setupEventListeners();
      _socket!.connect();
    } catch (e) {
      _updateState(WebSocketState.error);
    }
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentRoom = null;
    _updateState(WebSocketState.disconnected);
  }

  /// Join a branch room for receiving updates
  Future<void> joinBranchRoom(String branchId) async {
    if (!isConnected) {
      await connect();
    }

    // Leave current room if different
    if (_currentRoom != null && _currentRoom != branchId) {
      _socket?.emit('leave', {'room': 'branch:$_currentRoom'});
    }

    _socket?.emit('join', {'room': 'branch:$branchId'});
    _currentRoom = branchId;
  }

  /// Leave current room
  void leaveRoom() {
    if (_currentRoom != null) {
      _socket?.emit('leave', {'room': 'branch:$_currentRoom'});
      _currentRoom = null;
    }
  }

  void _setupEventListeners() {
    _socket?.onConnect((_) {
      _updateState(WebSocketState.connected);

      // Rejoin room if we had one
      if (_currentRoom != null) {
        _socket?.emit('join', {'room': 'branch:$_currentRoom'});
      }
    });

    _socket?.onDisconnect((_) {
      _updateState(WebSocketState.disconnected);
    });

    _socket?.onConnectError((error) {
      _updateState(WebSocketState.error);
    });

    _socket?.onError((error) {
      _updateState(WebSocketState.error);
    });

    // Order events
    _socket?.on('order:created', (data) {
      _handleMessage(WebSocketEvent.orderCreated, data);
    });

    _socket?.on('order:updated', (data) {
      _handleMessage(WebSocketEvent.orderUpdated, data);
    });

    _socket?.on('order:completed', (data) {
      _handleMessage(WebSocketEvent.orderCompleted, data);
    });

    // Payment events
    _socket?.on('payment:completed', (data) {
      _handleMessage(WebSocketEvent.paymentCompleted, data);
    });

    _socket?.on('payment:failed', (data) {
      _handleMessage(WebSocketEvent.paymentFailed, data);
    });

    // Inventory events
    _socket?.on('inventory:low_stock', (data) {
      _handleMessage(WebSocketEvent.inventoryLowStock, data);
    });

    _socket?.on('inventory:out_of_stock', (data) {
      _handleMessage(WebSocketEvent.inventoryOutOfStock, data);
    });
  }

  void _handleMessage(WebSocketEvent event, dynamic data) {
    final message = WebSocketMessage(
      event: event,
      data: data is Map<String, dynamic> ? data : {'data': data},
    );

    _messageController.add(message);

    // Route to specific streams
    switch (event) {
      case WebSocketEvent.orderCreated:
      case WebSocketEvent.orderUpdated:
      case WebSocketEvent.orderCompleted:
        _orderEventsController.add(message);
        break;
      case WebSocketEvent.paymentCompleted:
      case WebSocketEvent.paymentFailed:
        _paymentEventsController.add(message);
        break;
      case WebSocketEvent.inventoryLowStock:
      case WebSocketEvent.inventoryOutOfStock:
        _inventoryEventsController.add(message);
        break;
    }
  }

  void _updateState(WebSocketState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
    _orderEventsController.close();
    _paymentEventsController.close();
    _inventoryEventsController.close();
  }
}
