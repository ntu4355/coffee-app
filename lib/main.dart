import 'package:coffee_app/admin/admin_home.dart';
import 'package:coffee_app/admin/admin_page_frame.dart';
import 'package:coffee_app/admin/add_product.dart';
import 'package:coffee_app/admin/all_orders.dart';
import 'package:coffee_app/admin/delivery_history.dart';
import 'package:coffee_app/admin/manage_products.dart';
import 'package:coffee_app/admin/manage_users.dart';
import 'package:coffee_app/pages/admin_login.dart';
import 'package:coffee_app/pages/home.dart';
import 'package:coffee_app/pages/login.dart';
import 'package:coffee_app/pages/order.dart';
import 'package:coffee_app/pages/profile.dart';
import 'package:coffee_app/pages/signup.dart';
import 'package:coffee_app/pages/wallet.dart';
import 'package:coffee_app/pages/bottomnav.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coffee_app/service/user_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e) {
    // If initialization fails, show a helpful error UI instead of crashing.
    runApp(ErrorApp(error: e.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final message =
        '''Firebase failed to initialize.

Reason: $error

Ensure you generated and registered Firebase
options (firebase_options.dart) using the FlutterFire CLI, or provide
FirebaseOptions to Firebase.initializeApp().

Docs: https://firebase.flutter.dev/docs/overview#initializing-flutterfire''';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Initialization error')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(child: Text(message)),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QDT Coffee',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        scaffoldBackgroundColor: const Color(0xFFf4eee3),
        useMaterial3: true,
      ),
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LogIn(),
        '/signup': (_) => const SignUp(),
        '/home': (_) => const Home(),
        '/order': (_) => const OrderPage(),
        '/wallet': (_) => const WalletPage(),
        '/profile': (_) => const ProfilePage(),
        '/adminlogin': (_) => const AdminPageFrame(child: AdminLogin()),
        '/adminhome': (_) => const AdminPageFrame(child: AdminHome()),
        '/manage_users': (_) => const AdminPageFrame(child: ManageUsers()),
        '/all_orders': (_) => const AdminPageFrame(child: AllOrders()),
        '/delivery_history': (_) =>
            const AdminPageFrame(child: DeliveryHistory()),
        '/manage_products': (_) =>
            const AdminPageFrame(child: ManageProducts()),
        '/add_product': (_) => const AdminPageFrame(child: AddProduct()),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _loadingUid;
  Future<void>? _userLoadFuture;

  Future<void> _loadUserData(String uid) {
    if (_loadingUid != uid) {
      _loadingUid = uid;
      _userLoadFuture = UserService.instance.loadUserData();
    }
    return _userLoadFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          _loadingUid = null;
          _userLoadFuture = null;
          return const LogIn();
        }

        return FutureBuilder<void>(
          key: ValueKey(user.uid),
          future: _loadUserData(user.uid),
          builder: (context, userLoadSnapshot) {
            if (userLoadSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return const BottomNav();
          },
        );
      },
    );
  }
}
