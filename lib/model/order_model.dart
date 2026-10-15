import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { receiving, shipping, delivered }

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.receiving:
        return 'Đang tiếp nhận';
      case OrderStatus.shipping:
        return 'Đang giao';
      case OrderStatus.delivered:
        return 'Đã giao';
    }
  }
}

class OrderModel {
  String? id;
  String? name;
  String? image;
  String? userName;
  double? price;
  int quantity;
  double? totalPrice;
  OrderStatus status;
  DateTime createdAt;

  // Tự động tính tổng tiền nếu totalPrice bị null
  double get computedTotalPrice {
    if (totalPrice != null) return totalPrice!;
    return (price ?? 0) * quantity;
  }

  OrderModel({
    this.id,
    this.name,
    this.image,
    this.userName,
    this.price,
    this.quantity = 1,
    this.totalPrice,
    this.status = OrderStatus.receiving,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'userName': userName,
      'price': price,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'status': status.name,
      'createdAt':
          createdAt, // Sẽ được OrderService ghi đè bằng ServerTimestamp
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, {String? id}) {
    // Hàm hỗ trợ chuyển đổi an toàn từ dynamic sang double
    double? parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final numericString = RegExp(r'[0-9.]+').stringMatch(value) ?? '0';
        return double.tryParse(numericString);
      }
      return null;
    }

    // Xử lý createdAt có thể là Timestamp hoặc String
    DateTime? createdAt;
    final raw = map['createdAt'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw);
    }

    return OrderModel(
      id: id,
      name: map['name'] as String?,
      image: map['image'] as String?,
      userName: map['userName'] as String?,
      price: parseDouble(map['price']),
      quantity: map['quantity'] as int? ?? 1,
      totalPrice: parseDouble(map['totalPrice']),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? ''),
        orElse: () => OrderStatus.receiving,
      ),
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}
