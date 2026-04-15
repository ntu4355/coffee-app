import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class Transaction {
  final String customerName;
  final String coffeeType;
  final int quantity;
  final double totalPrice;

  Transaction({
    required this.customerName,
    required this.coffeeType,
    required this.quantity,
    required this.totalPrice,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng Đặt hàng Cà phê',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: const CoffeeOrderPage(),
    );
  }
}

class CoffeeOrderPage extends StatefulWidget {
  const CoffeeOrderPage({super.key});

  @override
  State<CoffeeOrderPage> createState() => _CoffeeOrderPageState();
}

class _CoffeeOrderPageState extends State<CoffeeOrderPage> {
  // Các biến liên quan đến ứng dụng đặt hàng cà phê
  List<String> coffeeTypes = ['Espresso', 'Latte', 'Cappuccino', 'Americano'];
  String selectedCoffee = '';
  int quantity = 1;
  double pricePerCup = 25; // Giá mỗi ly cà phê
  String customerName = '';
  List<Transaction> orderHistory = []; // Lịch sử đơn hàng

  void _placeOrder() {
    if (selectedCoffee.isNotEmpty && customerName.isNotEmpty) {
      double totalPrice = quantity * pricePerCup;
      Transaction order = Transaction(
        customerName: customerName,
        coffeeType: selectedCoffee,
        quantity: quantity,
        totalPrice: totalPrice,
      );
      setState(() {
        orderHistory.add(order);
        // Reset sau khi đặt hàng
        selectedCoffee = '';
        quantity = 1;
        customerName = '';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đơn hàng đã được đặt: ${order.customerName}, ${order.coffeeType}, ${order.quantity}, ${order.totalPrice.toStringAsFixed(0)}K')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn cà phê và nhập tên khách hàng'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt hàng Cà phê'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn loại cà phê:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: selectedCoffee.isEmpty ? null : selectedCoffee,
              hint: const Text('Chọn cà phê'),
              items: coffeeTypes.map((String coffee) {
                return DropdownMenuItem<String>(
                  value: coffee,
                  child: Text(coffee),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedCoffee = newValue!;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Số lượng:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (quantity > 1) {
                      setState(() {
                        quantity--;
                      });
                    }
                  },
                  icon: const Icon(Icons.remove),
                ),
                Text('$quantity'),
                IconButton(
                  onPressed: () {
                    setState(() {
                      quantity++;
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tên khách hàng',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                customerName = value;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _placeOrder,
              child: const Text('Đặt hàng'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lịch sử đơn hàng:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Khách hàng')),
                    DataColumn(label: Text('Cà phê')),
                    DataColumn(label: Text('Số lượng')),
                    DataColumn(label: Text('Tổng tiền')),
                  ],
                  rows: orderHistory.map((transaction) {
                    return DataRow(cells: [
                      DataCell(Text(transaction.customerName)),
                      DataCell(Text(transaction.coffeeType)),
                      DataCell(Text(transaction.quantity.toString())),
                      DataCell(Text('${transaction.totalPrice.toStringAsFixed(0)}K')),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
