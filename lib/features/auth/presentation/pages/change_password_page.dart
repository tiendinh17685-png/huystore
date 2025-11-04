import 'package:flutter/material.dart';
import 'package:huystore/core/layouts/main_layout.dart';
import 'package:huystore/core/services/api_service.dart';
import 'package:huystore/core/services/token_storage.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ApiService _apiService = ApiService();

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mật khẩu xác nhận không khớp")),
        );
        return;
      }

      final data = {
        "oldPassword": _oldPasswordController.text,
        "newPassword": _newPasswordController.text,
      };

      try {
        final result = await _apiService.put('accounts/changepassword',data: data);
        // Xóa token/session cũ
        if (result.statusCode == 200) {
          // final resulChang = result["data"];
          // if (resulChang.statusCode == 200) {
          await TokenStorage.clear();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đổi mật khẩu thành công, vui lòng đăng nhập lại"),
            ),
          );

          // Điều hướng sang màn Login
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
          // }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đổi mật khẩu thất bại.")),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Đổi mật khẩu",
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _oldPasswordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu cũ'),
                obscureText: true,
              ),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                obscureText: true,
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _changePassword,
                child: const Text("Cập nhật"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
