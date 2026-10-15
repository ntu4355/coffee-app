import 'package:coffee_app/service/widget_support.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coffeeBrown = const Color(0xFF6B4F35);

    return Scaffold(
      backgroundColor: const Color(0xFFf4eee3),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 18.0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.coffee_outlined,
                          color: coffeeBrown,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QDT Coffee',
                            style: AppWidget.boldTextFieldStyle().copyWith(
                              fontSize: 24.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28.0),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18.0,
                          vertical: 24.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Chào mừng quý khách',
                              style: AppWidget.boldTextFieldStyle().copyWith(
                                fontSize: 22.0,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Đăng nhập bằng tài khoản của bạn để tiếp tục đặt hàng.',
                              style: TextStyle(
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            Text(
                              'Email',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            _buildTextField(
                              controller: emailController,
                              hintText: 'Nhập email',
                              prefixIcon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              'Mật khẩu',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            _buildPasswordField(
                              controller: passwordController,
                              hintText: 'Nhập mật khẩu',
                              obscureText: obscurePassword,
                              onToggle: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                            const SizedBox(height: 16.0),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Quên mật khẩu?',
                                  style: TextStyle(color: coffeeBrown),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      final email = emailController.text.trim();
                                      final password = passwordController.text;

                                      if (email.isEmpty || password.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Vui lòng nhập đầy đủ email và mật khẩu',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final navigator = Navigator.of(context);
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      setState(() => isLoading = true);
                                      try {
                                        await FirebaseAuth.instance
                                            .signInWithEmailAndPassword(
                                              email: email,
                                              password: password,
                                            );
                                        if (!mounted) return;
                                        navigator.popUntil(
                                          (route) => route.isFirst,
                                        );
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Đăng nhập thành công!',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } on FirebaseAuthException catch (e) {
                                        _showError(
                                          e.message ?? 'Đăng nhập thất bại',
                                        );
                                      } catch (e) {
                                        _showError('Có lỗi xảy ra: $e');
                                      } finally {
                                        if (mounted) {
                                          setState(() => isLoading = false);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: coffeeBrown,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Đăng nhập',
                                      style: AppWidget.whiteTextFieldStyle()
                                          .copyWith(fontSize: 18.0),
                                    ),
                            ),
                            const SizedBox(height: 22.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Bạn chưa có tài khoản?',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/signup');
                                  },
                                  child: Text(
                                    'Đăng ký',
                                    style: TextStyle(
                                      color: coffeeBrown,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12.0),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/adminlogin');
                                },
                                child: Text(
                                  'Đăng nhập với tư cách Quản trị viên',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: coffeeBrown.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFececf8),
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          prefixIcon: Icon(prefixIcon, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFececf8),
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          prefixIcon: const Icon(
            Icons.password_outlined,
            color: Colors.black54,
          ),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
