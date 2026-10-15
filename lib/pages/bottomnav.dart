import 'package:flutter/material.dart';
import 'package:coffee_app/pages/home.dart';
import 'package:coffee_app/pages/order.dart';
import 'package:coffee_app/pages/wallet.dart';
import 'package:coffee_app/pages/profile.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int currentIndex = 0;

  // Danh sách các trang để giữ trạng thái
  late List<Widget> pages;
  late Home homepage;
  late OrderPage order;
  late WalletPage wallet;
  late ProfilePage profile;

  @override
  void initState() {
    homepage = const Home();
    order = const OrderPage();
    wallet = const WalletPage();
    profile = const ProfilePage();
    pages = [homepage, order, wallet, profile];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const coffeeBrown = Color(0xFF6B4F35);
    const navigationBackground = Color(0xFFFFFCF7);
    const screenBackground = Color(0xFFf4eee3);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final panelRadius = isWide
                ? BorderRadius.circular(24)
                : BorderRadius.zero;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: screenBackground,
                      borderRadius: panelRadius,
                      boxShadow: isWide
                          ? [
                              BoxShadow(
                                color: coffeeBrown.withOpacity(0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: panelRadius,
                      child: Column(
                        children: [
                          Expanded(
                            child: IndexedStack(
                              index: currentIndex,
                              children: pages,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: navigationBackground,
                              border: Border(
                                top: BorderSide(
                                  color: coffeeBrown.withOpacity(0.08),
                                ),
                              ),
                            ),
                            child: NavigationBar(
                              height: 68,
                              selectedIndex: currentIndex,
                              onDestinationSelected: (index) {
                                setState(() {
                                  currentIndex = index;
                                });
                              },
                              backgroundColor: Colors.transparent,
                              indicatorColor: const Color(0xFFEDE2D2),
                              indicatorShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              labelBehavior:
                                  NavigationDestinationLabelBehavior.alwaysShow,
                              animationDuration: const Duration(
                                milliseconds: 250,
                              ),
                              destinations: const [
                                NavigationDestination(
                                  icon: Icon(Icons.home_outlined),
                                  selectedIcon: Icon(Icons.home_rounded),
                                  label: 'Trang chủ',
                                ),
                                NavigationDestination(
                                  icon: Icon(Icons.receipt_long_outlined),
                                  selectedIcon: Icon(
                                    Icons.receipt_long_rounded,
                                  ),
                                  label: 'Đơn hàng',
                                ),
                                NavigationDestination(
                                  icon: Icon(
                                    Icons.account_balance_wallet_outlined,
                                  ),
                                  selectedIcon: Icon(
                                    Icons.account_balance_wallet_rounded,
                                  ),
                                  label: 'Số dư',
                                ),
                                NavigationDestination(
                                  icon: Icon(Icons.person_outline_rounded),
                                  selectedIcon: Icon(Icons.person_rounded),
                                  label: 'Cá nhân',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
