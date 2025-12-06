import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/order.dart';
import '../../../core/models/payment.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/payment_service.dart';
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
  final Order? order;
  final PaymentResult? paymentResult;
  final PhayPayPayment? phayPayPayment;
  final PhayPayStatus? phayPayStatus;
  final String? error;
  final Duration? remainingTime;

  const PaymentState({
    this.processState = PaymentProcessState.idle,
    this.order,
    this.paymentResult,
    this.phayPayPayment,
    this.phayPayStatus,
    this.error,
    this.remainingTime,
  });

  PaymentState copyWith({
    PaymentProcessState? processState,
    Order? order,
    PaymentResult? paymentResult,
    PhayPayPayment? phayPayPayment,
    PhayPayStatus? phayPayStatus,
    String? error,
    Duration? remainingTime,
  }) {
    return PaymentState(
      processState: processState ?? this.processState,
      order: order ?? this.order,
      paymentResult: paymentResult ?? this.paymentResult,
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
}

/// Payment notifier
class PaymentNotifier extends StateNotifier<PaymentState> {
  final OrderService _orderService;
  final PaymentService _paymentService;
  final String? _branchId;
  StreamSubscription<PhayPayStatus>? _phayPaySubscription;
  Timer? _countdownTimer;

  PaymentNotifier(this._orderService, this._paymentService, this._branchId)
    : super(const PaymentState());

  @override
  void dispose() {
    _phayPaySubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Process cash payment
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
      // Create order
      state = state.copyWith(processState: PaymentProcessState.creatingOrder);
      final order = await _orderService.createOrder(
        branchId: _branchId,
        cart: cart,
      );
      state = state.copyWith(order: order);

      // Process payment
      state = state.copyWith(
        processState: PaymentProcessState.processingPayment,
      );
      final paymentResult = await _paymentService.processCashPayment(
        orderId: order.id,
        branchId: _branchId,
        total: total,
        tendered: tendered,
      );

      state = state.copyWith(
        processState: PaymentProcessState.completed,
        paymentResult: paymentResult,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        processState: PaymentProcessState.failed,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Process PhayPay payment
  Future<bool> processPhayPayPayment({
    required double amount,
    required PhayPayBankMethod bankMethod,
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
      // Create order
      state = state.copyWith(processState: PaymentProcessState.creatingOrder);
      final order = await _orderService.createOrder(
        branchId: _branchId,
        cart: cart,
      );
      state = state.copyWith(order: order);

      // Create PhayPay payment
      state = state.copyWith(
        processState: PaymentProcessState.processingPayment,
      );
      final phayPayPayment = await _paymentService.createPhayPayPayment(
        orderId: order.id,
        branchId: _branchId,
        amount: amount,
        bankMethod: bankMethod,
        description: 'Order #${order.orderId}',
      );

      state = state.copyWith(
        processState: PaymentProcessState.waitingForPayment,
        phayPayPayment: phayPayPayment,
      );

      // Start countdown timer
      _startCountdownTimer(phayPayPayment.expiresAt);

      // Start polling for payment status
      _phayPaySubscription?.cancel();
      _phayPaySubscription = _paymentService
          .watchPhayPayPayment(phayPayPayment.paymentId)
          .listen((status) {
            state = state.copyWith(phayPayStatus: status);

            if (status.isCompleted) {
              _countdownTimer?.cancel();
              state = state.copyWith(
                processState: PaymentProcessState.completed,
                paymentResult: PaymentResult(
                  transactionId: status.transactionId ?? '',
                  paymentId: phayPayPayment.paymentId,
                  orderId: order.orderId,
                  status: PaymentStatus.completed,
                  paymentMethod: PaymentMethod.phayPay,
                  amount: PaymentAmount(total: amount),
                  completedAt: status.paidAt,
                ),
              );
            } else if (status.isFailed || status.isExpired) {
              _countdownTimer?.cancel();
              state = state.copyWith(
                processState: PaymentProcessState.failed,
                error:
                    status.isFailed
                        ? 'Payment failed'
                        : 'Payment expired. Please try again.',
              );
            }
          });

      return true;
    } catch (e) {
      state = state.copyWith(
        processState: PaymentProcessState.failed,
        error: e.toString(),
      );
      return false;
    }
  }

  void _startCountdownTimer(DateTime? expiresAt) {
    if (expiresAt == null) return;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = expiresAt.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        state = state.copyWith(remainingTime: Duration.zero);
      } else {
        state = state.copyWith(remainingTime: remaining);
      }
    });
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
      final orderService = ref.watch(orderServiceProvider);
      final paymentService = ref.watch(paymentServiceProvider);
      final branchId = ref.watch(currentBranchIdProvider);
      return PaymentNotifier(orderService, paymentService, branchId);
    });
