import 'package:flutter/material.dart';
import 'package:coffee_app/service/widget_support.dart';
import '../service/order_service.dart';
import '../model/order_model.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  static const _statuses = [
    OrderStatus.receiving,
    OrderStatus.shipping,
    OrderStatus.delivered,
  ];

  @override
  void initState() {
    super.initState();
    OrderService.instance.loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    const coffeeBrown = Color(0xFF6B4F35);

    return DefaultTabController(
      length: _statuses.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: coffeeBrown,
          foregroundColor: Colors.white,
          title: const Text(
            'Đơn hàng',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          bottom: const TabBar(
            labelPadding: EdgeInsets.zero,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFE8DCCB),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
            tabs: [
              Tab(
                child: Text(
                  'Đang tiếp nhận',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              Tab(
                child: Text(
                  'Đang giao',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              Tab(
                child: Text(
                  'Đã giao',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        body: ValueListenableBuilder<List<OrderModel>>(
          valueListenable: OrderService.instance.ordersNotifier,
          builder: (context, orders, _) {
            final sortedOrders = List<OrderModel>.of(orders)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return TabBarView(
              children: _statuses
                  .map(
                    (status) => _buildStatusOrders(
                      orders,
                      sortedOrders
                          .where((order) => order.status == status)
                          .toList(),
                      status,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusOrders(
    List<OrderModel> allOrders,
    List<OrderModel> statusOrders,
    OrderStatus status,
  ) {
    if (statusOrders.isEmpty) {
      return Center(
        child: Text(
          allOrders.isEmpty
              ? 'Chưa có đơn hàng nào'
              : 'Không có đơn hàng ${status.label.toLowerCase()}',
          style: AppWidget.boldTextFieldStyle(),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: statusOrders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = statusOrders[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: _buildOrderImage(order),
            title: Text(order.name ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Số lượng: ${order.quantity}'),
                const SizedBox(height: 4),
                Text('Tổng: ${order.computedTotalPrice.toStringAsFixed(0)}k'),
                const SizedBox(height: 4),
                Text(
                  'Trạng thái: ${status.label}',
                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            trailing: status == OrderStatus.receiving
                ? IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    color: Colors.redAccent,
                    tooltip: 'Hủy đơn hàng',
                    onPressed: () {
                      final originalIndex = allOrders.indexOf(order);
                      if (originalIndex >= 0) {
                        OrderService.instance.cancelOrderAt(originalIndex);
                      }
                    },
                  )
                : Icon(
                    status == OrderStatus.shipping
                        ? Icons.local_shipping_outlined
                        : Icons.check_circle_outline,
                    color: _statusColor(status),
                  ),
          ),
        );
      },
    );
  }

  Widget? _buildOrderImage(OrderModel order) {
    final image = order.image;
    if (image == null || image.isEmpty) return null;

    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    }

    return Image.asset(
      image,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image),
    );
  }

  Color _statusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.receiving => Colors.orange.shade700,
      OrderStatus.shipping => Colors.blue.shade700,
      OrderStatus.delivered => Colors.green.shade700,
    };
  }
}
