import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _imagePicker = ImagePicker();
  Uint8List? _selectedAvatarBytes;
  String _avatarUrl = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      return;
    }
    _avatarUrl = user.avatarUrl;
    _selectedAvatarBytes = _avatarBytesFromStoredValue(user.avatarUrl);
  }

  Future<void> _pickAvatarImage() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final base64Avatar = base64Encode(bytes);

      setState(() {
        _selectedAvatarBytes = bytes;
        _avatarUrl = 'data:image/png;base64,$base64Avatar';
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick image on this device/browser.')),
      );
    }
  }

  Future<void> _saveAvatar(AuthProvider auth) async {
    final user = auth.user;
    if (user == null) {
      return;
    }

    try {
      await auth.updateProfile(
        fullName: user.fullName,
        avatarUrl: _avatarUrl.trim(),
        sourceLanguage: user.sourceLanguage,
        targetLanguage: user.targetLanguage,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated successfully')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Avatar update failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Please log in to view your profile.')),
      );
    }

    final avatarImage = _buildAvatarImage(_avatarUrl.trim());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Admin Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF8F9FA),
                        border: Border.all(color: Colors.black12, width: 2),
                      ),
                      child: avatarImage == null
                          ? Center(
                              child: Text(
                                user.fullName.isEmpty ? 'A' : user.fullName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black54),
                              ),
                            )
                          : ClipOval(
                              child: Image(
                                image: avatarImage,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAvatarImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D1C1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(user.fullName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Role'),
                subtitle: Text(user.role),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: auth.isLoading ? null : () => _saveAvatar(auth),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00D1C1)),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Avatar'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00D1C1)),
                  onPressed: () {
                    context.read<AuthProvider>().logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider<Object>? _buildAvatarImage(String avatarValue) {
    if (_selectedAvatarBytes != null && _selectedAvatarBytes!.isNotEmpty) {
      return MemoryImage(_selectedAvatarBytes!);
    }
    if (avatarValue.isEmpty) return null;

    final dataUriBytes = _avatarBytesFromStoredValue(avatarValue);
    if (dataUriBytes != null) return MemoryImage(dataUriBytes);

    if (avatarValue.startsWith('http://') || avatarValue.startsWith('https://')) {
      return NetworkImage(avatarValue);
    }
    return null;
  }

  Uint8List? _avatarBytesFromStoredValue(String raw) {
    if (!raw.startsWith('data:image')) return null;
    final commaIndex = raw.indexOf(',');
    if (commaIndex < 0 || commaIndex + 1 >= raw.length) return null;
    final encoded = raw.substring(commaIndex + 1);
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}
