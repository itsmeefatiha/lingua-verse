import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../../shell/presentation/pages/main_shell_page.dart';
import '../providers/auth_provider.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  final _formKey = GlobalKey<FormState>();
  String? _nativeLanguage;
  String? _targetLanguage;

  static const _languages = <String>[
    'English',
    'French',
    'Spanish',
    'German',
    'Arabic',
    'Italian',
    'Portuguese',
    'Chinese',
    'Japanese',
  ];

  static const Map<String, String> _localeToLanguage = {
    'en': 'English',
    'fr': 'French',
    'es': 'Spanish',
    'de': 'German',
    'ar': 'Arabic',
    'it': 'Italian',
    'pt': 'Portuguese',
    'zh': 'Chinese',
    'ja': 'Japanese',
  };

  @override
  void initState() {
    super.initState();
    final detected = _detectNativeLanguage();
    _nativeLanguage = detected;
    _targetLanguage ??= _languages.firstWhere(
      (language) => language != detected,
      orElse: () => 'English',
    );
  }

  String _detectNativeLanguage() {
    final locale = kIsWeb
        ? WidgetsBinding.instance.platformDispatcher.locale
        : WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = locale.languageCode.toLowerCase();
    return _localeToLanguage[languageCode] ?? 'English';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subdued = scheme.onSurface.withOpacity(0.8);
    final borderColor = theme.dividerColor.withOpacity(0.5);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Illustration
              Center(
                child: Image.asset(
                  'assets/images/illustration.png',
                  height: 240,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),

              // Title
              Text(
                "Speak the World's\nLanguages",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                "Break down barriers. Connect with the world\nthrough smart AI tutoring and real-world AR\nvocabulary.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: subdued,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 50),

              // Language Selection Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Native Language Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _nativeLanguage,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Native Language',
                        labelStyle: TextStyle(color: subdued),
                        filled: true,
                        fillColor: scheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
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
                          borderSide: const BorderSide(
                            color: Color(0xFF00D1C1),
                            width: 2,
                          ),
                        ),
                      ),
                      items: _languages
                          .map(
                            (language) => DropdownMenuItem(
                              value: language,
                              child: Text(
                                language,
                                style: TextStyle(color: subdued),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _nativeLanguage = value),
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Target Language Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _targetLanguage,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Language you want to learn',
                        labelStyle: TextStyle(color: subdued),
                        filled: true,
                        fillColor: scheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
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
                          borderSide: const BorderSide(
                            color: Color(0xFF00D1C1),
                            width: 2,
                          ),
                        ),
                      ),
                      items: _languages
                          .map(
                            (language) => DropdownMenuItem(
                              value: language,
                              child: Text(
                                language,
                                style: TextStyle(color: subdued),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _targetLanguage = value),
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 40),

                    // Start Learning Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }

                                // Prevent users from choosing the same language for both
                                if (_nativeLanguage == _targetLanguage) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Native language and target language cannot be the same.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  await auth.updateUserLanguages(
                                    _nativeLanguage!,
                                    _targetLanguage!,
                                  );
                                  if (!context.mounted) return;

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MainShellPage(),
                                    ),
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        auth.error ??
                                            'Could not update languages',
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D1C1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: auth.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Start Learning',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
