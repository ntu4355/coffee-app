import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:coffee_app/model/category_model.dart';
import 'package:coffee_app/pages/detail_page.dart';
import 'package:coffee_app/service/category_data.dart';
import 'package:coffee_app/service/user_service.dart';
import 'package:coffee_app/model/user_model.dart';
import 'package:coffee_app/model/product_model.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<CategoryModel> categories = [];
  int selectedCategoryIndex = 0;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    categories = getCategories();
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng,';
    if (hour < 18) return 'Chào buổi chiều,';
    return 'Chào buổi tối,';
  }

  // Dữ liệu banner giả định
  final List<Map<String, String>> promos = [
    {
      'title': 'Mua 1 Tặng 1',
      'subtitle': 'Áp dụng cho Cafe Lạnh',
      'color': '0xFF6B4F35',
    },
    {
      'title': 'Giảm 20%',
      'subtitle': 'Khi nạp ví trên 200k',
      'color': '0xFF8D6E63',
    },
    {
      'title': 'Món Mới!',
      'subtitle': 'Trà Đào Cam Sả đã có mặt',
      'color': '0xFF5D4037',
    },
  ];

  Widget _buildProductGrid(Color coffeeBrown) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'products',
    );

    // Nếu không phải "Tất cả", thực hiện lọc theo danh mục
    if (selectedCategoryIndex != 0) {
      query = query.where(
        'category',
        isEqualTo: categories[selectedCategoryIndex].name,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Đã xảy ra lỗi'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data?.docs ?? [];

        // Lọc theo từ khóa tìm kiếm (Client-side filtering)
        if (searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();
        }

        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text('Không tìm thấy sản phẩm nào'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Thực đơn", coffeeBrown),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - 16) / 2;
                final tileHeight = (tileWidth * 1.7).clamp(260.0, 320.0);
                final imageHeight = (tileWidth * 0.85).clamp(105.0, 140.0);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: tileHeight,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final product = ProductModel.fromMap(
                      data,
                      id: docs[index].id,
                    );
                    return FoodTile(
                      context,
                      product.name ?? '',
                      product.image ?? '',
                      product.price,
                      product.description ?? '',
                      coffeeBrown,
                      imageHeight: imageHeight,
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPromoSlider(Color coffeeBrown) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Giới hạn chiều rộng card để không bị quá to trên màn hình lớn
    double cardWidth = screenWidth > 600 ? 400 : screenWidth * 0.85;

    return SizedBox(
      height: 160,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: promos.length,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 10),
          itemBuilder: (context, index) {
            return Container(
              width: cardWidth,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Color(int.parse(promos[index]['color']!)),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(
                      int.parse(promos[index]['color']!),
                    ).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.coffee,
                      size: 100,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          promos[index]['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promos[index]['subtitle']!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Khám phá",
                            style: TextStyle(
                              color: coffeeBrown,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color coffeeBrown) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: coffeeBrown,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final background = const Color(0xFFf4eee3);
    final coffeeBrown = const Color(0xFF6B4F35);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ), // Giữ giao diện gọn gàng trên màn hình lớn
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              children: [
                // Header: Greeting and Profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên thương hiệu ở bên trái
                    Text(
                      'QDT COFFEE',
                      style: TextStyle(
                        color: coffeeBrown,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Lời chào và Profile ở bên phải
                    Row(
                      children: [
                        ValueListenableBuilder<UserModel?>(
                          valueListenable: UserService.instance.userNotifier,
                          builder: (context, user, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: TextStyle(
                                    color: coffeeBrown.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  user?.fullName != null &&
                                          user!.fullName!.isNotEmpty
                                      ? user.fullName!.split(' ').last
                                      : 'Bạn',
                                  style: TextStyle(
                                    color: coffeeBrown,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/profile'),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: coffeeBrown,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm cà phê...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF6B4F35),
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                searchController.clear();
                                setState(() {
                                  searchQuery = "";
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Promo Slider
                _buildPromoSlider(coffeeBrown),
                const SizedBox(height: 24),
                // Categories Header
                _buildSectionHeader("Danh mục", coffeeBrown),
                const SizedBox(height: 12),
                // Category Horizontal List
                SizedBox(
                  height: 45,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final bool selected = selectedCategoryIndex == index;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => selectedCategoryIndex = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? coffeeBrown : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              categories[index].name ?? '',
                              style: TextStyle(
                                color: selected ? Colors.white : coffeeBrown,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Product Grid via StreamBuilder
                _buildProductGrid(coffeeBrown),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget FoodTile(
  BuildContext context,
  String name,
  String image,
  dynamic price,
  String description,
  Color coffeeBrown, {
  required double imageHeight,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailPage(
              image: image,
              name: name,
              price: price,
              description: description,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: image,
              child: Container(
                width: double.infinity,
                height: imageHeight,
                decoration: const BoxDecoration(
                  color: Color(0xFFf4eee3),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: image.startsWith('http')
                      ? Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        )
                      : Image.asset(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: coffeeBrown,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price is num
                            ? "${price.toStringAsFixed(0)}k"
                            : price.toString(),
                        style: TextStyle(
                          color: coffeeBrown,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: coffeeBrown,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
