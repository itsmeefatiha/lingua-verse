import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/network/session_store.dart';
import 'features/admin/data/repositories/admin_repository.dart';
import 'features/admin/presentation/providers/admin_content_provider.dart';
import 'features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'features/admin/presentation/providers/admin_user_provider.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/gamification/data/repositories/gamification_repository.dart';
import 'features/gamification/presentation/providers/gamification_provider.dart';
import 'features/learning/data/repositories/learning_repository.dart';
import 'features/learning/presentation/providers/learning_provider.dart';
import 'features/progress/data/repositories/progress_repository.dart';
import 'features/progress/presentation/providers/progress_provider.dart';
import 'features/shell/presentation/providers/shell_provider.dart';

void main() {
  final sessionStore = SessionStore();
  final apiClient = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    sessionStore: sessionStore,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionStore>.value(value: sessionStore),
        Provider(create: (_) => AuthRepository(apiClient)),
        Provider(create: (_) => AdminRepository(apiClient)),
        Provider(create: (_) => LearningRepository(apiClient)),
        Provider(create: (_) => ProgressRepository(apiClient)),
        Provider(create: (_) => GamificationRepository(apiClient)),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            context.read<AuthRepository>(),
            sessionStore,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AdminDashboardProvider(context.read<AdminRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AdminContentProvider(context.read<AdminRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AdminUserProvider(context.read<AdminRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => LearningProvider(context.read<LearningRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ProgressProvider(context.read<ProgressRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              GamificationProvider(context.read<GamificationRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => ShellProvider()),
      ],
      child: const LinguaVerseApp(),
    ),
  );
}
