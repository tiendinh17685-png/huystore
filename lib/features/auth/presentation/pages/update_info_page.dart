import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:huystore/core/layouts/main_layout.dart';
import 'package:huystore/core/services/api_service.dart';
import 'package:huystore/global.dart'; 
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';

class LocationItem {
  final int id;
  final String name;

  LocationItem({required this.id, required this.name});
  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(id: json['id'], name: json['name']);
  }

  @override
  String toString() => name; // để hiển thị tên trong dropdown_search
}

class UpdateInfoPage extends StatefulWidget {
  const UpdateInfoPage({Key? key}) : super(key: key);

  @override
  State<UpdateInfoPage> createState() => _UpdateInfoPageState();
}

class _UpdateInfoPageState extends State<UpdateInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;

  List<LocationItem> _provinces = [];
  List<LocationItem> _wards = [];
  LocationItem? _selectedProvince;
  LocationItem? _selectedWard;

  File? _avatarFile;
  String? _avatarUrl;

  final ApiService _api = ApiService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> loadProvince() async {
    final provRes = await _api.get('diccombo/getlistcombo?table=Province');
    final listProv = provRes.data;
    setState(() {
      _provinces = (listProv as List)
          .map((e) => LocationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  Future<void> loadWard(int provinceId) async {
    final wardsRes = await _api.get(
      'diccombo/getlistcombo?table=Ward&shopId=-1&provinceId=$provinceId',
    );
    final warsList = wardsRes.data;
    if (warsList != null) {
      setState(() {
        _wards = (warsList as List)
            .map((e) => LocationItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get('user/getcurrentuser');
      final result = response.data;
      if (result['statusCode'] == 200) {
        final user = result['data'];
        _fullNameController.text = user['fullName'] ?? '';
        _emailController.text = user['email'] ?? '';
        _phoneController.text = user['phoneNumber'] ?? '';
        _addressController.text = user['address'] ?? '';

        final dob = user['dateOfBirth'];
        if (dob != null && dob.toString().isNotEmpty) {
          _selectedDate = DateTime.parse(dob.toString());
        }
        _selectedGender = user['gender'];
        _avatarUrl = (dotenv.env['FILE_URL'] ?? "") + user['avatarUrl'];

        await loadProvince();
        final provinceId = user['provinceId'];
        if (provinceId != null) {
          try {
            _selectedProvince = _provinces.firstWhere(
              (p) => p.id == provinceId,
            );
          } catch (_) {
            _selectedProvince = null;
          }

          if (_selectedProvince != null) {
            await loadWard(provinceId);
            final wardId = user['wardId'];
            if (wardId != null) {
              try {
                _selectedWard = _wards.firstWhere((w) => w.id == wardId);
              } catch (_) {
                _selectedWard = null;
              }
            }
          }
        }
      }
    } catch (err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi load dữ liệu: $err')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
        _avatarUrl = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final data = {
        "fullName": _fullNameController.text.trim(),
        "email": _emailController.text.trim(),
        "phoneNumber": _phoneController.text.trim(),
        "dateOfBirth": _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : null,
        "gender": _selectedGender,
        "provinceId": _selectedProvince?.id,
        "wardId": _selectedWard?.id,
        "address": _addressController.text.trim(),
      };

      if (_avatarFile != null) {
        final avatarUrl = await _api.uploadFile(
          'files/upload',
          _avatarFile!.path,
          'avatar',
        );
        if (avatarUrl.statusCode == 200) {
          String urlAvatar = avatarUrl.data['url'];
          data['avatarUrl'] = urlAvatar;
          _updateAvatarOnAppBar((dotenv.env['FILE_URL'] ?? "") + urlAvatar);
        }
      }

      await _api.put('/accounts/updateinfo/', data: data);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));
    } catch (err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lưu thất bại: $err')));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _updateAvatarOnAppBar(String? url) {
    globalAvatarUrl.value = url;
  }

  InputDecoration _decoration(String label) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: theme.primaryColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Cập nhật thông tin',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _avatarFile != null
                                ? FileImage(_avatarFile!)
                                : (_avatarUrl != null
                                      ? NetworkImage(_avatarUrl!)
                                            as ImageProvider
                                      : null),
                            child: (_avatarFile == null && _avatarUrl == null)
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickAvatar,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Text fields
                    ...[
                      ['Họ và tên', _fullNameController],
                      ['Email', _emailController],
                      ['Số điện thoại', _phoneController],
                    ].map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: entry[1] as TextEditingController,
                          decoration: _decoration(entry[0] as String),
                          validator: (val) =>
                              val!.isEmpty ? 'Không để trống' : null,
                        ),
                      ),
                    ),

                    // Date of birth
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime(1995, 1, 1),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => _selectedDate = d);
                      },
                      child: InputDecorator(
                        decoration: _decoration('Ngày sinh'),
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                              : 'Chọn ngày',
                          style: TextStyle(
                            color: _selectedDate != null
                                ? Colors.black
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: _decoration('Giới tính'),
                      items: const [
                        DropdownMenuItem(value: "male", child: Text("Nam")),
                        DropdownMenuItem(value: "female", child: Text("Nữ")),
                        DropdownMenuItem(value: "other", child: Text("Khác")),
                      ],
                      onChanged: (v) => setState(() => _selectedGender = v),
                    ),
                    const SizedBox(height: 16),

                    // Province with search
                    DropdownSearch<LocationItem>(
                      items: _provinces,
                      selectedItem: _selectedProvince,
                      itemAsString: (item) => item.name,
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: _decoration('Tỉnh/Thành phố'),
                      ),
                      popupProps: PopupProps.dialog(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: const InputDecoration(
                            labelText: 'Tìm tỉnh/thành',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      onChanged: (v) async {
                        setState(() {
                          _selectedProvince = v;
                          _selectedWard = null;
                          _wards = [];
                        });
                        if (v != null) {
                          await loadWard(v.id);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Ward with search
                    DropdownSearch<LocationItem>(
                      items: _wards,
                      selectedItem: _selectedWard,
                      itemAsString: (item) => item.name,
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: _decoration('Xã/Phường'),
                      ),
                      popupProps: PopupProps.dialog(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: const InputDecoration(
                            labelText: 'Tìm xã/phường',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        setState(() => _selectedWard = v);
                      },
                    ),

                    // Address detail
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      child: TextFormField(
                        controller: _addressController,
                        decoration: _decoration('Địa chỉ chi tiết'),
                      ),
                    ),

                    const SizedBox(height: 24, width: 150),
                    ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: const Text('Lưu'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
