import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    bool rememberMe = true;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 50),

            // Logo
            Center(
              child: Column(
                children: [
                  // You can replace this with your own image asset
                  const Icon(Icons.handyman, size: 80, color: Colors.teal),
                  const SizedBox(height: 10),
                  const Text(
                    'Lalalab',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Old English Text MT', // Optional
                    ),
                  ),
                  const Text(
                    'Service with dedication',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Form
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NHẬP THÔNG TIN TÀI KHOẢN',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Tài khoản
                TextField(
                  controller: usernameController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Tài khoản',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Mật khẩu
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Nhớ tài khoản
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (value) {
                        // Handle state in StatefulWidget if needed
                      },
                    ),
                    const Text('Nhớ tài khoản'),
                  ],
                ),
                const SizedBox(height: 10),

                // Nút đăng nhập
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Xử lý đăng nhập
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    child: const Text('Đăng nhập'),
                  ),
                ),

                const SizedBox(height: 10),

                // Đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Bạn chưa có tài khoản? "),
                    GestureDetector(
                      onTap: () {
                        // Điều hướng sang trang đăng ký
                      },
                      child: const Text(
                        'Đăng ký',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Center(child: Text("Version V1.0.0")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
