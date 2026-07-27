import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';

class LoginProductHeader extends StatelessWidget {
  const LoginProductHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.business, size: 28, color: zBlue),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUIK ERP',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: zText,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Modern Business Management Platform',
                style: TextStyle(
                  color: zMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LoginOptions extends StatelessWidget {
  final bool rememberMe;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback? onForgotPassword;

  const LoginOptions({
    super.key,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final remember = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: rememberMe,
          activeColor: zAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          visualDensity: VisualDensity.compact,
          onChanged: onRememberChanged,
        ),
        const Text(
          'Remember me',
          style: TextStyle(
            fontSize: 14.5,
            color: Color(0xFF43546B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
    final forgot = TextButton(
      onPressed: onForgotPassword,
      child: const Text(
        'Forgot password?',
        style: TextStyle(
          fontSize: 14.5,
          color: Color(0xFF5B6C82),
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              remember,
              Align(alignment: Alignment.centerRight, child: forgot),
            ],
          );
        }
        return Row(children: [remember, const Spacer(), forgot]);
      },
    );
  }
}

class SignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onLogin;

  const SignInButton({super.key, required this.loading, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: zPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        onPressed: onLogin,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}

class LoginWorkspaceLinks extends StatelessWidget {
  final VoidCallback onCreateWorkspace;
  final VoidCallback onJoinWorkspace;

  const LoginWorkspaceLinks({
    super.key,
    required this.onCreateWorkspace,
    required this.onJoinWorkspace,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 7,
    runSpacing: 4,
    children: [
      TextButton(
        onPressed: onCreateWorkspace,
        child: const Text(
          'Create Workspace',
          style: TextStyle(
            color: zAccent,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const Text('•', style: TextStyle(color: Color(0xFF9BA9BA))),
      TextButton(
        onPressed: onJoinWorkspace,
        child: const Text(
          'Join Company',
          style: TextStyle(
            color: zAccent,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}
