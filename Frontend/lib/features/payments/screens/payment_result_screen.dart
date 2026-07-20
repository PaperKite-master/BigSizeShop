import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/payment_providers.dart';

class PaymentResultScreen extends ConsumerStatefulWidget {
  const PaymentResultScreen({
    super.key,
    this.orderId,
    this.startPayment = false,
  });

  final String? orderId;
  final bool startPayment;

  @override
  ConsumerState<PaymentResultScreen> createState() =>
      _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderId = widget.orderId;
      if (!mounted || orderId == null || orderId.isEmpty) {
        return;
      }
      final controller = ref.read(paymentControllerProvider.notifier);
      final current = ref.read(paymentControllerProvider);
      if (widget.startPayment) {
        controller.startPayment(orderId);
      } else if (current.orderId != orderId ||
          current.phase == PaymentFlowPhase.idle) {
        controller.checkStatus(orderId);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    final paymentState = ref.read(paymentControllerProvider);
    final orderId = paymentState.orderId ?? widget.orderId;
    if (orderId != null &&
        paymentState.phase == PaymentFlowPhase.awaitingReturn) {
      ref.read(paymentControllerProvider.notifier).checkStatus(orderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentControllerProvider);
    final orderId = state.orderId ?? widget.orderId;
    final presentation = _presentationFor(state);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VNPay Payment'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        presentation.icon,
                        size: 72,
                        color: presentation.color,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        presentation.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.message ?? presentation.message,
                        textAlign: TextAlign.center,
                      ),
                      if (orderId != null && orderId.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SelectableText(
                          'Order: $orderId',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (state.phase == PaymentFlowPhase.creatingPayment ||
                          state.phase == PaymentFlowPhase.verifying) ...[
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                      ],
                      const SizedBox(height: 28),
                      if (orderId != null &&
                          (state.phase == PaymentFlowPhase.unpaid ||
                              state.phase == PaymentFlowPhase.error))
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => ref
                                .read(paymentControllerProvider.notifier)
                                .startPayment(orderId),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry payment'),
                          ),
                        ),
                      if (orderId != null &&
                          state.phase != PaymentFlowPhase.paid) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => ref
                                .read(paymentControllerProvider.notifier)
                                .checkStatus(orderId),
                            icon: const Icon(Icons.verified_outlined),
                            label: const Text('Check payment status'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go('/orders'),
                          child: const Text('View my orders'),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Return to home'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _PaymentPresentation _presentationFor(PaymentFlowState state) {
    switch (state.phase) {
      case PaymentFlowPhase.creatingPayment:
        return const _PaymentPresentation(
          Icons.open_in_browser,
          Colors.blue,
          'Opening VNPay',
          'Preparing a secure VNPay Sandbox payment page.',
        );
      case PaymentFlowPhase.awaitingReturn:
        return const _PaymentPresentation(
          Icons.hourglass_top,
          Colors.orange,
          'Waiting for payment',
          'Complete payment in your browser, then return here. Your order is already created.',
        );
      case PaymentFlowPhase.verifying:
        return const _PaymentPresentation(
          Icons.verified_user_outlined,
          Colors.blue,
          'Verifying payment',
          'Confirming the final payment status with the server.',
        );
      case PaymentFlowPhase.paid:
        return const _PaymentPresentation(
          Icons.check_circle,
          Colors.green,
          'Payment successful',
          'VNPay payment has been confirmed.',
        );
      case PaymentFlowPhase.unpaid:
        return const _PaymentPresentation(
          Icons.cancel_outlined,
          Colors.red,
          'Payment not completed',
          'The server has not confirmed payment for this order.',
        );
      case PaymentFlowPhase.error:
        return const _PaymentPresentation(
          Icons.error_outline,
          Colors.red,
          'Payment needs attention',
          'Unable to continue this payment.',
        );
      case PaymentFlowPhase.idle:
        return const _PaymentPresentation(
          Icons.info_outline,
          Colors.blueGrey,
          'Payment details unavailable',
          'Open an order or retry checkout to continue.',
        );
    }
  }
}

class _PaymentPresentation {
  const _PaymentPresentation(this.icon, this.color, this.title, this.message);

  final IconData icon;
  final Color color;
  final String title;
  final String message;
}
