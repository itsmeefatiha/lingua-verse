import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _imagePicker = ImagePicker();
  Uint8List? _selectedAvatarBytes;
  String _sourceLanguage = 'fr';
  String _targetLanguage = 'en';

  static const languages = [
    _LanguageOption(code: 'fr', label: 'French'),
    _LanguageOption(code: 'en', label: 'English'),
    _LanguageOption(code: 'es', label: 'Spanish'),
    _LanguageOption(code: 'de', label: 'German'),
    _LanguageOption(code: 'ar', label: 'Arabic'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      return;
    }
    _nameController.text = user.fullName;
    _avatarUrlController.text = user.avatarUrl;
    _selectedAvatarBytes = _avatarBytesFromStoredValue(user.avatarUrl);
    _sourceLanguage = _normalizeLanguage(user.sourceLanguage, fallback: 'fr');
    _targetLanguage = _normalizeLanguage(user.targetLanguage, fallback: 'en');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your profile.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 44,
            backgroundImage: _buildAvatarImage(_avatarUrlController.text.trim()),
            child: _buildAvatarImage(_avatarUrlController.text.trim()) == null
                ? Text(
                    user.fullName.isEmpty ? 'U' : user.fullName.substring(0, 1),
                    style: Theme.of(context).textTheme.headlineSmall,
                  )
                : null,
          ),
          TextButton.icon(
            onPressed: _pickAvatarImage,
            icon: const Icon(Icons.photo_camera_back_outlined),
            label: const Text('Choose photo'),
          ),
          TextField(
            controller: _avatarUrlController,
            decoration: const InputDecoration(
              labelText: 'Avatar URL',
              hintText: 'https://.../avatar.jpg',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _sourceLanguage,
            items: languages
                .map((lang) => DropdownMenuItem(value: lang.code, child: Text(lang.label)))
                .toList(),
            onChanged: (value) => setState(() => _sourceLanguage = value ?? 'fr'),
            decoration: const InputDecoration(labelText: 'Source language'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _targetLanguage,
            items: languages
                .map((lang) => DropdownMenuItem(value: lang.code, child: Text(lang.label)))
                .toList(),
            onChanged: (value) => setState(() => _targetLanguage = value ?? 'en'),
            decoration: const InputDecoration(labelText: 'Target language'),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark mode'),
            value: auth.themeMode == ThemeMode.dark,
            onChanged: auth.toggleTheme,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: auth.isLoading
                ? null
                : () async {
                    try {
                      await auth.updateProfile(
                        fullName: _nameController.text.trim(),
                        avatarUrl: _avatarUrlController.text.trim(),
                        sourceLanguage: _sourceLanguage,
                        targetLanguage: _targetLanguage,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated')),
                      );
                    } catch (_) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(auth.error ?? 'Profile update failed')),
                      );
                    }
            },
            child: const Text('Save profile'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: auth.logout,
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  static String _normalizeLanguage(String value, {required String fallback}) {
    final normalized = value.trim().toLowerCase();
    final supportedCodes = languages.map((option) => option.code).toSet();
    if (supportedCodes.contains(normalized)) {
      return normalized;
    }

    switch (normalized) {
      case 'french':
        return 'fr';
      case 'english':
        return 'en';
      case 'spanish':
        return 'es';
      case 'german':
        return 'de';
      case 'arabic':
        return 'ar';
      default:
        return fallback;
    }
  }

  Future<void> _pickAvatarImage() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();
      final base64Avatar = base64Encode(bytes);

      // Persist the selected image as a data URI so backend can store it in avatar_url.
      setState(() {
        _selectedAvatarBytes = bytes;
        _avatarUrlController.text = 'data:image/png;base64,$base64Avatar';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick image on this device/browser.')),
      );
    }
  }

  ImageProvider<Object>? _buildAvatarImage(String avatarValue) {
    if (_selectedAvatarBytes != null && _selectedAvatarBytes!.isNotEmpty) {
      return MemoryImage(_selectedAvatarBytes!);
    }

    if (avatarValue.isEmpty) {
      return null;
    }

    final dataUriBytes = _avatarBytesFromStoredValue(avatarValue);
    if (dataUriBytes != null) {
      return MemoryImage(dataUriBytes);
    }

    if (avatarValue.startsWith('http://') || avatarValue.startsWith('https://')) {
      return NetworkImage(avatarValue);
    }

    return null;
  }

  Uint8List? _avatarBytesFromStoredValue(String raw) {
    if (!raw.startsWith('data:image')) {
      return null;
    }

    final commaIndex = raw.indexOf(',');
    if (commaIndex < 0 || commaIndex + 1 >= raw.length) {
      return null;
    }

    final encoded = raw.substring(commaIndex + 1);
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}

class _LanguageOption {
  const _LanguageOption({required this.code, required this.label});

  final String code;
  final String label;
}
