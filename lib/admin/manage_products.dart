import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffee_app/admin/admin_page_frame.dart';
import 'package:coffee_app/admin/edit_product.dart';
import 'package:coffee_app/service/widget_support.dart';
import 'package:flutter/material.dart';

class ManageProducts extends StatefulWidget {
  const ManageProducts({super.key});

  @override
  State<ManageProducts> createState() => _ManageProductsState();
}

class _ManageProductsState extends State<ManageProducts> {
  final Color coffeeBrown = const Color(0xFF6B4F35);

  Widget _displayImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return const Icon(Icons.coffee);

    // Nếu là link web (Firebase Storage)
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    }

    // Nếu là link asset cục bộ
    return Image.asset(imagePath, width: 50, height: 50, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf4eee3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFf4eee3),
        elevation: 0,
        title: Text("Quản lý sản phẩm", style: AppWidget.boldTextFieldStyle()),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined, color: coffeeBrown),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: coffeeBrown,
        onPressed: () {
          Navigator.pushNamed(context, '/add_product');
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _displayImage(data['image']),
                  ),
                  title: Text(
                    data['name'] ?? '',
                    style: AppWidget.boldTextFieldStyle().copyWith(
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    data['price'] is num
                        ? "${(data['price'] as num).toStringAsFixed(0)}k"
                        : (data['price']?.toString() ?? ''),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminPageFrame(
                                child: EditProduct(
                                  id: docs[index].id,
                                  data: data,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(docs[index].id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc muốn xóa sản phẩm này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(id)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
