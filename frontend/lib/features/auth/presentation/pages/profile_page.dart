import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _imagePicker = ImagePicker();
  Uint8List? _selectedAvatarBytes;
  String _avatarUrl = '';
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
    _avatarUrl = user.avatarUrl;
    _selectedAvatarBytes = _avatarBytesFromStoredValue(user.avatarUrl);
    _sourceLanguage = _normalizeLanguage(user.sourceLanguage, fallback: 'fr');
    _targetLanguage = _normalizeLanguage(user.targetLanguage, fallback: 'en');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- SAVE PROFILE LOGIC ---
  Future<void> _handleSave(AuthProvider auth) async {
    try {
      await auth.updateProfile(
        fullName: _nameController.text.trim(),
        avatarUrl: _avatarUrl.trim(),
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Profile update failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subdued = scheme.onSurface.withOpacity(0.8);
    final borderColor = theme.dividerColor.withOpacity(0.5);

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Please log in to view your profile.')),
      );
    }

    // Shared Input Decoration to match previous screens
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        actions: [
          // Save Button aligned with "Profile" title
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: auth.isLoading ? null : () => _handleSave(auth),
              child: auth.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00D1C1),
                      ),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              // Avatar with Edit Pencil Icon
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.surface,
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: _buildAvatarImage(_avatarUrl.trim()) == null
                          ? Center(
                              child: Text(
                                user.fullName.isEmpty
                                    ? 'U'
                                    : user.fullName
                                          .substring(0, 1)
                                          .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: subdued,
                                ),
                              ),
                            )
                          : ClipOval(
                              child: Image(
                                image: _buildAvatarImage(_avatarUrl.trim())!,
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
                            color: const Color(0xFF00D1C1), // Teal edit button
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats directly under profile picture
              _ProfileStatsRow(),
              const SizedBox(height: 40),

              // Full Name Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Full Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: subdued,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: inputDecoration.copyWith(
                      hintText: 'Enter your name',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Native/Source Language Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Native Language',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: subdued,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _sourceLanguage,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey,
                    ),
                    decoration: inputDecoration,
                    items: languages
                        .map(
                          (lang) => DropdownMenuItem(
                            value: lang.code,
                            child: Text(lang.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _sourceLanguage = value ?? 'fr'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Target Language Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning Language',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: subdued,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _targetLanguage,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey,
                    ),
                    decoration: inputDecoration,
                    items: languages
                        .map(
                          (lang) => DropdownMenuItem(
                            value: lang.code,
                            child: Text(lang.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _targetLanguage = value ?? 'en'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Dark Mode Toggle
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  title: const Text(
                    'Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  activeColor: const Color(0xFF00D1C1),
                  value: auth.themeMode == ThemeMode.dark,
                  onChanged: auth.toggleTheme,
                ),
              ),
              const SizedBox(height: 40),

              // Logout Button (Styled)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton.icon(
                  onPressed: () {
                    auth.logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Methods (Remain Unchanged)
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
        const SnackBar(
          content: Text('Could not pick image on this device/browser.'),
        ),
      );
    }
  }

  ImageProvider<Object>? _buildAvatarImage(String avatarValue) {
    if (_selectedAvatarBytes != null && _selectedAvatarBytes!.isNotEmpty) {
      return MemoryImage(_selectedAvatarBytes!);
    }
    final trimmed = avatarValue.trim();
    if (trimmed.isEmpty) return null;

    final dataUriBytes = _avatarBytesFromStoredValue(trimmed);
    if (dataUriBytes != null) return MemoryImage(dataUriBytes);

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }

    final rawBase64Bytes = _avatarBytesFromRawBase64(trimmed);
    if (rawBase64Bytes != null) return MemoryImage(rawBase64Bytes);

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

  Uint8List? _avatarBytesFromRawBase64(String raw) {
    final normalized = raw.replaceAll(RegExp(r'\s+'), '');
    if (normalized.length < 64) return null;
    if (!RegExp(r'^[A-Za-z0-9+/=_-]+$').hasMatch(normalized)) return null;

    final padded = _padBase64(normalized);
    try {
      return base64Decode(padded);
    } catch (_) {
      try {
        return base64Url.decode(padded);
      } catch (_) {
        return null;
      }
    }
  }

  String _padBase64(String value) {
    final remainder = value.length % 4;
    if (remainder == 0) {
      return value;
    }
    return value + '=' * (4 - remainder);
  }
}

class _LanguageOption {
  const _LanguageOption({required this.code, required this.label});
  final String code;
  final String label;
}

// Re-styled Stats Row
class _ProfileStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = theme.dividerColor.withOpacity(0.5);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const _StatItem(label: 'Progress', value: '68%'),
          Container(height: 40, width: 1, color: borderColor),
          const _StatItem(label: 'Time Spent', value: '12h'),
          Container(height: 40, width: 1, color: borderColor),
          const _StatItem(label: 'Words', value: '320'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
