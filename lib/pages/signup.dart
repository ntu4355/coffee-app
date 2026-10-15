import 'package:coffee_app/service/widget_support.dart';
import 'package:flutter/material.dart';
import 'package:coffee_app/service/registration_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Đăng ký',
                        style: AppWidget.boldTextFieldStyle().copyWith(
                          fontSize: 26.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22.0),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(22.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Tạo tài khoản mới',
                              style: AppWidget.boldTextFieldStyle().copyWith(
                                fontSize: 22.0,
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            Text(
                              'Nhập thông tin để tạo tài khoản QDT Coffee của bạn.',
                              style: TextStyle(
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 22.0),
                            _buildInputField(
                              controller: fullNameController,
                              label: 'Họ và tên',
                              hintText: 'Nhập họ và tên',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16.0),
                            _buildInputField(
                              controller: usernameController,
                              label: 'Tên đăng nhập',
                              hintText: 'Nhập tên đăng nhập',
                              icon: Icons.account_circle_outlined,
                            ),
                            const SizedBox(height: 16.0),
                            _buildInputField(
                              controller: emailController,
                              label: 'Email',
                              hintText: 'Nhập email',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16.0),
                            _buildInputField(
                              controller: addressController,
                              label: 'Địa chỉ',
                              hintText: 'Nhập địa chỉ',
                              icon: Icons.location_on_outlined,
                              keyboardType: TextInputType.streetAddress,
                            ),
                            const SizedBox(height: 16.0),
                            _buildPasswordField(
                              controller: passwordController,
                              label: 'Mật khẩu',
                              hintText: 'Nhập mật khẩu',
                              obscureText: obscurePassword,
                              onToggle: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Tối thiểu 8 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            _buildPasswordField(
                              controller: confirmPasswordController,
                              label: 'Nhập lại mật khẩu',
                              hintText: 'Xác nhận mật khẩu',
                              obscureText: obscureConfirmPassword,
                              onToggle: () {
                                setState(() {
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword;
                                });
                              },
                            ),
                            const SizedBox(height: 24.0),
                            ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      final fullName = fullNameController.text
                                          .trim();
                                      final username = usernameController.text
                                          .trim();
                                      final email = emailController.text.trim();
                                      final address = addressController.text
                                          .trim();
                                      final password = passwordController.text;
                                      final confirm =
                                          confirmPasswordController.text;

                                      if (fullName.isEmpty ||
                                          email.isEmpty ||
                                          password.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Vui lòng nhập đầy đủ thông tin',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      if (!RegistrationValidator.isValidEmail(
                                        email,
                                      )) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Vui lòng nhập địa chỉ email hợp lệ.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final passwordError =
                                          RegistrationValidator.passwordError(
                                            password,
                                          );
                                      if (passwordError != null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(passwordError),
                                          ),
                                        );
                                        return;
                                      }

                                      if (password != confirm) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Mật khẩu không khớp',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() => isLoading = true);
                                      final focusScope = FocusScope.of(context);
                                      final navigator = Navigator.of(context);
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      try {
                                        final cred = await FirebaseAuth.instance
                                            .createUserWithEmailAndPassword(
                                              email: email,
                                              password: password,
                                            );
                                        final uid = cred.user?.uid;
                                        if (uid == null) {
                                          throw StateError(
                                            'Firebase không trả về tài khoản vừa tạo.',
                                          );
                                        }
                                        String? profileSaveError;
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(uid)
                                              .set({
                                                'fullName': fullName,
                                                'username': username,
                                                'email': email,
                                                'address': address,
                                                'createdAt':
                                                    FieldValue.serverTimestamp(),
                                              });
                                        } on FirebaseException catch (error) {
                                          profileSaveError =
                                              error.message ?? error.code;
                                        }

                                        if (!mounted) return;
                                        focusScope.unfocus();
                                        navigator.popUntil(
                                          (route) => route.isFirst,
                                        );
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              profileSaveError == null
                                                  ? 'Đăng ký tài khoản thành công!'
                                                  : 'Tài khoản đã tạo nhưng chưa lưu được hồ sơ: $profileSaveError',
                                            ),
                                            backgroundColor:
                                                profileSaveError == null
                                                ? Colors.green
                                                : Colors.deepOrange,
                                            duration: Duration(
                                              seconds: profileSaveError == null
                                                  ? 3
                                                  : 8,
                                            ),
                                          ),
                                        );
                                      } on FirebaseAuthException catch (e) {
                                        _showError(
                                          e.message ?? 'Lỗi khi tạo tài khoản',
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
                                      'Đăng ký',
                                      style: AppWidget.whiteTextFieldStyle()
                                          .copyWith(fontSize: 18.0),
                                    ),
                            ),
                            const SizedBox(height: 18.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Bạn đã có tài khoản?',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/login',
                                    );
                                  },
                                  child: Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      color: coffeeBrown,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
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
              prefixIcon: Icon(icon, color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
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
        ),
      ],
    );
  }
}
