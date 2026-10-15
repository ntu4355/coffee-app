import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vietqr_gen/vietqr_generator.dart';
import '../service/wallet_service.dart';
import '../service/topup_api_service.dart';
import '../model/transaction_model.dart';

const _coffeeBrown = Color(0xFF6B4F35);

String _formatVnd(int amount) {
  final digits = amount.toString();
  final formatted = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      formatted.write('.');
    }
    formatted.write(digits[i]);
  }
  return '$formattedđ';
}

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WalletService.instance.loadWalletData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _showTopupDialog() async {
    _amountController.clear();
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Nạp tiền'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: 50000',
                    suffixText: 'đ',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  final parsedAmount = int.tryParse(
                    _amountController.text.trim(),
                  );
                  if (parsedAmount == null ||
                      parsedAmount < 1000 ||
                      parsedAmount % 1000 != 0) {
                    setDialogState(
                      () => errorText =
                          'Nhập số tiền từ 1.000đ, theo bội số 1.000đ.',
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, parsedAmount);
                },
                child: const Text('Tiếp tục'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || amount == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận nạp tiền'),
        content: Text(
          'Bạn muốn tạo mã QR để chuyển ${_formatVnd(amount)} vào ví chứ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    late final TopUpIntent intent;
    try {
      intent = await TopUpApiService.instance.createIntent(amount);
    } catch (error) {
      if (!mounted) return;
      final message = error is TopUpConfigurationException
          ? '$error Hãy deploy Worker rồi chạy lại app với '
                '--dart-define=TOPUP_API_BASE_URL=https://<worker-url>.workers.dev.'
          : 'Không thể tạo yêu cầu nạp tiền: $error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    final paymentReceived = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TopUpQrDialog(
        amount: amount,
        transferReference: intent.reference,
        expiresAt: intent.expiresAt,
        monitorPayment: true,
      ),
    );
    if (paymentReceived != true || !mounted) return;

    try {
      await WalletService.instance.loadWalletData(rethrowErrors: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã xác nhận thanh toán nhưng không tải được số dư ví: $error',
          ),
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã nhận thanh toán và cập nhật số dư ví.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coffeeBrown = _coffeeBrown;
    return Scaffold(
      appBar: AppBar(title: const Text('Số dư'), backgroundColor: coffeeBrown),
      body: ValueListenableBuilder<double>(
        valueListenable: WalletService.instance.balanceNotifier,
        builder: (context, balance, _) {
          return Column(
            children: [
              // Balance Card
              Container(
                margin: const EdgeInsets.all(20.0),
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Số dư hiện tại',
                      style: TextStyle(color: Colors.grey, fontSize: 14.0),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      WalletService.instance.formatCurrency(balance),
                      style: TextStyle(
                        color: coffeeBrown,
                        fontSize: 36.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Top-up Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showTopupDialog,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Nạp tiền'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: coffeeBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28.0),

              // Transaction History Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Text(
                      'Lịch sử giao dịch',
                      style: TextStyle(
                        color: coffeeBrown,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12.0),

              // Transaction List
              Expanded(
                child: ValueListenableBuilder<List<TransactionModel>>(
                  valueListenable: WalletService.instance.transactionsNotifier,
                  builder: (context, transactions, _) {
                    if (transactions.isEmpty) {
                      return Center(
                        child: Text(
                          'Chưa có giao dịch nào',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14.0,
                          ),
                        ),
                      );
                    }

                    // Sắp xếp giao dịch mới nhất lên đầu
                    final displayTransactions = List<TransactionModel>.from(
                      transactions,
                    )..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: displayTransactions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8.0),
                      itemBuilder: (context, index) {
                        final transaction = displayTransactions[index];
                        final isIncome =
                            transaction.type == TransactionType.topup ||
                            transaction.type == TransactionType.refund;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 48.0,
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: isIncome
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Center(
                                child: Text(
                                  transaction.type.icon,
                                  style: const TextStyle(fontSize: 24.0),
                                ),
                              ),
                            ),
                            title: Text(transaction.type.label),
                            subtitle: Text(
                              transaction.description ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.0),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'}${WalletService.instance.formatCurrency(transaction.amount)}',
                                  style: TextStyle(
                                    color: isIncome ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.0,
                                  ),
                                ),
                                Text(
                                  _formatDate(transaction.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Hôm nay ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (date == yesterday) {
      return 'Hôm qua ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class TopUpQrDialog extends StatefulWidget {
  const TopUpQrDialog({
    super.key,
    required this.amount,
    required this.transferReference,
    this.expiresAt,
    this.monitorPayment = false,
    this.paymentStatusChecker,
  });

  final int amount;
  final String transferReference;
  final DateTime? expiresAt;
  final bool monitorPayment;
  final Future<String> Function(String reference)? paymentStatusChecker;

  @override
  State<TopUpQrDialog> createState() => _TopUpQrDialogState();
}

class _TopUpQrDialogState extends State<TopUpQrDialog> {
  static const _validity = Duration(minutes: 10);
  late final DateTime _expiresAt =
      widget.expiresAt ?? DateTime.now().add(_validity);
  Timer? _countdownTimer;
  Timer? _statusTimer;
  Duration _remaining = _validity;
  String _paymentStatus = 'pending';
  String? _statusError;
  bool _checkingStatus = false;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    if (widget.monitorPayment) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateCountdown();
      });
      _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (!mounted || _paymentStatus == 'paid') {
          timer.cancel();
          return;
        }
        await _checkPaymentStatus();
      });
      _checkPaymentStatus();
    }
  }

  void _updateCountdown() {
    final remaining = _expiresAt.difference(DateTime.now());
    if (!mounted) return;
    setState(() {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_checkingStatus || !mounted || _paymentStatus == 'paid') return;
    _checkingStatus = true;
    try {
      final status =
          await (widget.paymentStatusChecker ??
              TopUpApiService.instance.getStatus)(widget.transferReference);
      if (!mounted) return;
      setState(() {
        _paymentStatus = status;
        _statusError = null;
      });
      if (status == 'paid') {
        _countdownTimer?.cancel();
        _statusTimer?.cancel();
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _statusError =
              'Chưa thể kiểm tra giao dịch: $error. Đang tự thử lại...';
        });
      }
    } finally {
      _checkingStatus = false;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  String get _qrPayload => VietQR.generate(
    bank: Bank.mbBank,
    accountNumber: '0332038511',
    amount: widget.amount.toDouble(),
    message: widget.transferReference,
  );

  String get _countdownLabel {
    final minutes = _remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining == Duration.zero && _paymentStatus != 'paid';
    final isPaid = _paymentStatus == 'paid';
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.vertical;
    final qrSize = (availableHeight * 0.38).clamp(120.0, 220.0).toDouble();

    return AlertDialog(
      scrollable: true,
      title: const Text('Quét mã để nạp tiền'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: qrSize,
            child: isPaid
                ? Icon(
                    Icons.check_circle_outline,
                    size: qrSize * 0.52,
                    color: Colors.green,
                  )
                : isExpired
                ? Icon(
                    Icons.timer_off_outlined,
                    size: qrSize * 0.42,
                    color: Colors.grey,
                  )
                : QrImageView(
                    data: _qrPayload,
                    version: QrVersions.auto,
                    size: qrSize,
                    backgroundColor: Colors.white,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            'Số tiền: ${_formatVnd(widget.amount)}',
            style: const TextStyle(
              color: _coffeeBrown,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _paymentStatus == 'paid'
                ? 'Đã nhận thanh toán và cộng tiền vào ví.'
                : _paymentStatus == 'expired'
                ? 'Yêu cầu đã hết hạn hiển thị mã QR. Nếu đã chuyển khoản, vui lòng liên hệ admin.'
                : isExpired
                ? 'Mã QR đã hết thời gian hiển thị.'
                : 'Mã QR sẽ được ẩn sau $_countdownLabel',
            style: TextStyle(
              color: _paymentStatus == 'paid'
                  ? Colors.green
                  : isExpired
                  ? Colors.red
                  : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_statusError != null) ...[
            const SizedBox(height: 8),
            Text(
              _statusError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.deepOrange, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          const SelectableText(
            'MB Bank · 0332038511\nNguyễn Văn Tú',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          SelectableText(
            'Nội dung chuyển khoản: ${widget.transferReference}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chỉ chuyển đúng số tiền hiển thị. Tiền sẽ được cộng tự động sau khi SePay xác nhận giao dịch. QR được ẩn sau 10 phút; nếu đã chuyển khoản nhưng chưa thấy cập nhật, vui lòng liên hệ admin và cung cấp nội dung chuyển khoản.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
