import 'package:coffee_app/pages/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('top-up QR dialog is visible and tappable on a phone screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 160);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const TopUpQrDialog(
                  amount: 50000,
                  transferReference: 'QDT1234567890123',
                ),
              ),
              child: const Text('Open QR'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open QR'));
    await tester.pumpAndSettle();

    final qrRect = tester.getRect(find.byType(QrImageView));
    final closeRect = tester.getRect(find.text('Đóng'));
    expect(qrRect.top, greaterThanOrEqualTo(0));
    expect(qrRect.bottom, lessThanOrEqualTo(320));
    expect(closeRect.top, greaterThanOrEqualTo(0));
    expect(closeRect.bottom, lessThanOrEqualTo(320));
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(find.text('Open QR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmed payment closes the QR dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final paid = await showDialog<bool>(
                  context: context,
                  builder: (_) => TopUpQrDialog(
                    amount: 50000,
                    transferReference: 'QDT1234567890123',
                    monitorPayment: true,
                    paymentStatusChecker: (_) async => 'paid',
                  ),
                );
                if (context.mounted && paid == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment received')),
                  );
                }
              },
              child: const Text('Open QR'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open QR'));
    await tester.pumpAndSettle();

    expect(find.byType(TopUpQrDialog), findsNothing);
    expect(find.text('Payment received'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
