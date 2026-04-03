import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/order.dart';
import '../../../core/models/payment.dart' as payment_models;
import '../../../core/services/checkout_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Payment state
enum PaymentProcessState {
  idle,
  creatingOrder,
  processingPayment,
  waitingForPayment,
  completed,
  failed,
}

/// Payment state model
class PaymentState {
  final PaymentProcessState processState;
  final CheckoutResponse? checkoutResponse;
  final payment_models.PhayPayPayment? phayPayPayment;
  final payment_models.PhayPayStatus? phayPayStatus;
  final String? error;
  final Duration? remainingTime;

  const PaymentState({
    this.processState = PaymentProcessState.idle,
    this.checkoutResponse,
    this.phayPayPayment,
    this.phayPayStatus,
    this.error,
    this.remainingTime,
  });

  PaymentState copyWith({
    PaymentProcessState? processState,
    CheckoutResponse? checkoutResponse,
    payment_models.PhayPayPayment? phayPayPayment,
    payment_models.PhayPayStatus? phayPayStatus,
    String? error,
    Duration? remainingTime,
  }) {
    return PaymentState(
      processState: processState ?? this.processState,
      checkoutResponse: checkoutResponse ?? this.checkoutResponse,
      phayPayPayment: phayPayPayment ?? this.phayPayPayment,
      phayPayStatus: phayPayStatus ?? this.phayPayStatus,
      error: error,
      remainingTime: remainingTime ?? this.remainingTime,
    );
  }

  bool get isProcessing =>
      processState == PaymentProcessState.creatingOrder ||
      processState == PaymentProcessState.processingPayment ||
      processState == PaymentProcessState.waitingForPayment;

  bool get isCompleted => processState == PaymentProcessState.completed;
  bool get isFailed => processState == PaymentProcessState.failed;

  // Helper getters for backward compatibility
  Order? get order =>
      checkoutResponse != null
          ? Order(
            id: checkoutResponse!.order.id,
            orderId: checkoutResponse!.order.orderId,
            qNumber: int.tryParse(checkoutResponse!.order.qNumber) ?? 0,
            orderType: OrderType.fromString(checkoutResponse!.order.orderType),
            status: OrderStatus.fromString(checkoutResponse!.order.orderStatus),
            items: [],
            pricing: OrderPricing(
              subtotal: 0,
              subtotalAfterDiscount: 0,
              tax: 0,
              discountTotal: 0,
              total: checkoutResponse!.pricing.totalAmount,
              currency: 'LAK',
            ),
            createdAt: DateTime.parse(checkoutResponse!.order.createdAt),
          )
          : null;

  payment_models.PaymentResult? get paymentResult =>
      checkoutResponse != null
          ? payment_models.PaymentResult(
            transactionId: checkoutResponse!.transaction.transactionId,
            paymentId: checkoutResponse!.order.orderId,
            orderId: checkoutResponse!.order.orderId,
            status:
                checkoutResponse!.transaction.transactionStatus == 'completed'
                    ? payment_models.PaymentStatus.completed
                    : payment_models.PaymentStatus.pending,
            paymentMethod: payment_models.PaymentMethod.cash,
            amount: payment_models.PaymentAmount(
              total: checkoutResponse!.pricing.totalAmount,
            ),
            completedAt: DateTime.parse(checkoutResponse!.order.createdAt),
          )
          : null;
}

/// Payment notifier
class PaymentNotifier extends StateNotifier<PaymentState> {
  final CheckoutService _checkoutService;
  final String? _branchId;
  StreamSubscription<payment_models.PhayPayStatus>? _phayPaySubscription;
  Timer? _countdownTimer;

  PaymentNotifier(this._checkoutService, this._branchId)
    : super(const PaymentState());

  @override
  void dispose() {
    _phayPaySubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Process cash payment (NEW UNIFIED FLOW)
  Future<bool> processCashPayment({
    required double total,
    required double tendered,
    required dynamic cart,
  }) async {
    if (_branchId == null) {
      state = state.copyWith(
        processState: PaymentProcessState.failed,
        error: 'Branch not configured',
      );
      return false;
    }

    try {
      // Process payment using unified checkout endpoint
      state = state.copyWith(
        processState: PaymentProcessState.processingPayment,
      );

      final checkoutResponse = await _checkoutService
          .processCashPaymentFromCart(cart: cart, tenderedAmount: tendered);

      state = state.copyWith(
        processState: PaymentProcessState.completed,
        checkoutResponse: checkoutResponse,
      );

      return true;
    } catch (e, stackTrace) {
      state = state.copyWith(
        processState: PaymentProcessState.failed,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Process PhayPay payment
  /// Note: PhayPay uses old flow (create QR first, then poll for payment)
  /// This is different from cash payment which uses unified checkout
  Future<bool> processPhayPayPayment({
    required double amount,
    required payment_models.PhayPayBankMethod bankMethod,
    required dynamic cart,
  }) async {
    if (_branchId == null) {
      state = state.copyWith(
        processState: PaymentProcessState.failed,
        error: 'Branch not configured',
      );
      return false;
    }

    try {
      // For PhayPay, we still need to create the order first
      // because the QR generation needs an orderId
      state = state.copyWith(processState: PaymentProcessState.creatingOrder);

      // TODO: For now, use the old createOrder API for PhayPay
      // In future, backend should support PhayPay in unified checkout
      // For now, this is a limitation that requires 2 steps

      // Create PhayPay payment (assuming order will be created by backend)
      state = state.copyWith(
        processState: PaymentProcessState.processingPayment,
      );

      // Note: This is placeholder - PhayPay integration needs backend update
      // to support unified checkout flow
      state = state.copyWith(
        processState: PaymentProcessState.failed,
        error:
            'PhayPay payment requires backend implementation for unified checkout',
      );

      return false;
    } catch (e) {
      state = state.copyWith(
        processState: PaymentProcessState.failed,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Cancel current payment
  void cancelPayment() {
    _phayPaySubscription?.cancel();
    _countdownTimer?.cancel();
    state = const PaymentState();
  }

  /// Reset state
  void reset() {
    _phayPaySubscription?.cancel();
    _countdownTimer?.cancel();
    state = const PaymentState();
  }
}

/// Payment provider
final paymentProvider =
    StateNotifierProvider.autoDispose<PaymentNotifier, PaymentState>((ref) {
      final checkoutService = ref.watch(checkoutServiceProvider);
      final branchId = ref.watch(currentBranchIdProvider);
      return PaymentNotifier(checkoutService, branchId);
    });
