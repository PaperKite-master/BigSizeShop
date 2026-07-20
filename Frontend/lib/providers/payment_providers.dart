import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/payment_model.dart';
import '../services/payment_service.dart';
import 'app_providers.dart';
import 'order_providers.dart';

enum PaymentFlowPhase {
  idle,
  creatingPayment,
  awaitingReturn,
  verifying,
  paid,
  unpaid,
  error,
}

class PaymentFlowState {
  const PaymentFlowState({
    this.phase = PaymentFlowPhase.idle,
    this.orderId,
    this.status,
    this.message,
    this.responseCode,
    this.fromDeepLink = false,
    this.linkEvent = 0,
  });

  final PaymentFlowPhase phase;
  final String? orderId;
  final PaymentStatusModel? status;
  final String? message;
  final String? responseCode;
  final bool fromDeepLink;
  final int linkEvent;

  PaymentFlowState copyWith({
    PaymentFlowPhase? phase,
    String? orderId,
    PaymentStatusModel? status,
    String? message,
    String? responseCode,
    bool? fromDeepLink,
    int? linkEvent,
  }) {
    return PaymentFlowState(
      phase: phase ?? this.phase,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      message: message,
      responseCode: responseCode ?? this.responseCode,
      fromDeepLink: fromDeepLink ?? this.fromDeepLink,
      linkEvent: linkEvent ?? this.linkEvent,
    );
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref.watch(apiClientProvider));
});

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentFlowState>((ref) {
      return PaymentController(ref);
    });

class PaymentController extends StateNotifier<PaymentFlowState> {
  PaymentController(this._ref)
    : _appLinks = AppLinks(),
      super(const PaymentFlowState()) {
    _listenForLinks();
    _ref.listen(authControllerProvider, (previous, next) {
      final pendingOrderId = _pendingVerificationOrderId;
      if (pendingOrderId != null && next.valueOrNull != null) {
        _pendingVerificationOrderId = null;
        unawaited(checkStatus(pendingOrderId, fromDeepLink: true));
      }
    });
  }

  final Ref _ref;
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastHandledLink;
  String? _pendingVerificationOrderId;

  PaymentService get _paymentService => _ref.read(paymentServiceProvider);

  void _listenForLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleLink,
      onError: (_) {
        state = state.copyWith(
          phase: PaymentFlowPhase.error,
          message: 'Could not read the payment return link.',
          fromDeepLink: true,
          linkEvent: state.linkEvent + 1,
        );
      },
    );
    _ref.onDispose(() => _linkSubscription?.cancel());
    unawaited(_readInitialLink());
  }

  Future<void> _readInitialLink() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await _handleLink(initialLink);
      }
    } catch (_) {
      state = state.copyWith(
        phase: PaymentFlowPhase.error,
        message: 'Could not read the payment return link.',
        fromDeepLink: true,
        linkEvent: state.linkEvent + 1,
      );
    }
  }

  Future<void> _handleLink(Uri uri) async {
    if (uri.scheme != 'bigsize-shop' || uri.host != 'payment-result') {
      return;
    }
    if (_lastHandledLink == uri.toString()) {
      return;
    }
    _lastHandledLink = uri.toString();

    final result = PaymentResultLink.tryParse(uri);
    if (result == null) {
      state = PaymentFlowState(
        phase: PaymentFlowPhase.error,
        message: 'The payment return link is incomplete or malformed.',
        fromDeepLink: true,
        linkEvent: state.linkEvent + 1,
      );
      return;
    }

    state = PaymentFlowState(
      phase: PaymentFlowPhase.verifying,
      orderId: result.orderId,
      responseCode: result.responseCode,
      fromDeepLink: true,
      linkEvent: state.linkEvent + 1,
    );

    final authState = _ref.read(authControllerProvider);
    if (authState.isLoading) {
      _pendingVerificationOrderId = result.orderId;
      return;
    }
    if (authState.valueOrNull == null) {
      state = state.copyWith(
        phase: PaymentFlowPhase.error,
        message: 'Sign in to verify this payment.',
      );
      return;
    }
    await checkStatus(result.orderId, fromDeepLink: true);
  }

  Future<void> startPayment(String orderId) async {
    state = PaymentFlowState(
      phase: PaymentFlowPhase.creatingPayment,
      orderId: orderId,
    );
    try {
      final paymentUrl = await _paymentService.createVnPayUrl(orderId);
      state = state.copyWith(phase: PaymentFlowPhase.awaitingReturn);
      final launched = await launchUrl(
        paymentUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        state = state.copyWith(
          phase: PaymentFlowPhase.error,
          message: 'Could not open VNPay. You can retry this payment.',
        );
      }
    } catch (error) {
      state = state.copyWith(
        phase: PaymentFlowPhase.error,
        message: error.toString(),
      );
    }
  }

  Future<void> checkStatus(String orderId, {bool fromDeepLink = false}) async {
    state = state.copyWith(
      phase: PaymentFlowPhase.verifying,
      orderId: orderId,
      fromDeepLink: fromDeepLink || state.fromDeepLink,
    );
    try {
      final status = await _paymentService.getOrderPaymentStatus(orderId);
      state = state.copyWith(
        phase: status.isPaid ? PaymentFlowPhase.paid : PaymentFlowPhase.unpaid,
        status: status,
        message: status.isPaid
            ? null
            : 'Payment is not confirmed. You can retry VNPay for this order.',
      );
      _ref.read(ordersProvider.notifier).fetchOrders();
    } catch (error) {
      state = state.copyWith(
        phase: PaymentFlowPhase.error,
        message: 'Could not verify payment status: $error',
      );
    }
  }
}
