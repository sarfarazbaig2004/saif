import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';

class LoginProductHeader extends StatelessWidget {
  const LoginProductHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: zBlueSoft,
            border: Border.all(color: zBorder),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: zText,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'by Genzprotech',
                style: TextStyle(
                  color: zMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              SizedBox(height: 7),
              Divider(height: 1, color: zBorder),
              SizedBox(height: 7),
              Text(
                'Aman Infra Developer Workspace',
                style: TextStyle(
                  color: zText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
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
    return Row(
      children: [
        Checkbox(
          value: rememberMe,
          activeColor: zBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          visualDensity: VisualDensity.compact,
          onChanged: onRememberChanged,
        ),
        const Text(
          'Remember me',
          style: TextStyle(
            fontSize: 13.5,
            color: zText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onForgotPassword,
          child: const Text(
            'Forgot password?',
            style: TextStyle(
              fontSize: 13.5,
              color: zBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
      height: 44,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: zBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class JoinWorkspaceButton extends StatelessWidget {
  final VoidCallback onPressed;

  const JoinWorkspaceButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: zBorder),
          foregroundColor: zBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: const Text(
          'Join Existing Workspace',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
