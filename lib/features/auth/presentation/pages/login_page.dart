import 'package:flutter/material.dart';
import 'package:huystore/features/auth/data/services/auth_services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final respose = await AuthService().login(username, password);

      if (respose.statusCode == 200) {
        _showMessage('Đăng nhập thành công');
        Navigator.pushReplacementNamed(
          context,
          '/home',
        ); 
      } 
      else if(respose.statusMessage!=null && respose.statusMessage.toString().isNotEmpty){
        _showMessage(respose.statusMessage.toString());
      }
      else {
        _showMessage('Đăng nhập thất bại');
      }
    } catch (e) {
      _showMessage('Lỗi khi đăng nhập: $e');
    }

    setState(() => _isLoading = false);
  } 
  void _loginAsGuest() { 
    Navigator.pushReplacementNamed(
      context,
     '/guest_home'
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea( 
        child: SingleChildScrollView( 
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column( 
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [ 
                  const SizedBox(height: 50), 
                  Image.asset('assets/images/logo-store.png', height: 120),
                  const SizedBox(height: 24),
                  const Text(
                    'Đăng nhập',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24), 
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Tài khoản',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 20), 
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                            )
                          : const Text('Đăng nhập'),
                    ),
                  ),
                  
                  const SizedBox(height: 16), 
                  TextButton( 
                    onPressed: _isLoading ? null : _loginAsGuest,
                    child: const Text(
                      'Bỏ qua Đăng nhập', 
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  
                  // ĐĂNG KÝ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản? '),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/register'),
                        child: const Text(
                          'Đăng ký',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ), 
                  const SizedBox(height: 50), 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}