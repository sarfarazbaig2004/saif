import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:QUIK/config/firebase_options.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/modules/providers/module_access_provider.dart';
import 'package:QUIK/auth/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TenantContext>(
          create: (_) => TenantContext(
            selectedTenantId: '',
            allowedTenantIds: const [],
            isPlatformAdmin: false,
          ),
        ),
        ChangeNotifierProvider<ModuleAccessController>(
          create: (_) => ModuleAccessController(),
        ),
      ],
      child: const QuikApp(),
    ),
  );
}

class QuikApp extends StatelessWidget {
  const QuikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildQuikTheme(),
      home: const AuthWrapper(),
    );
  }
}
