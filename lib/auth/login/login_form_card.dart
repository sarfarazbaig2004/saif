import 'package:flutter/material.dart';

import 'package:QUIK/auth/login/login_form_sections.dart';
import 'package:QUIK/core/theme/app_theme.dart';

class LoginFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final bool compactHeight;
  final bool obscurePassword;
  final bool loading;
  final bool rememberMe;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onLogin;
  final VoidCallback onJoinWorkspace;

  const LoginFormCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.validateEmail,
    required this.validatePassword,
    required this.compactHeight,
    required this.obscurePassword,
    required this.loading,
    required this.rememberMe,
    required this.onTogglePassword,
    required this.onRememberChanged,
    required this.onForgotPassword,
    required this.onLogin,
    required this.onJoinWorkspace,
  });

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: label,
      prefixIcon: Icon(icon, color: zMuted, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: _border(zBorder),
      enabledBorder: _border(zBorder),
      focusedBorder: _border(zBlue, width: 1.2),
      errorBorder: _border(Colors.red),
      focusedErrorBorder: _border(Colors.red, width: 1.2),
      labelStyle: const TextStyle(
        color: zMuted,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: zMuted, fontSize: 13.5),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 455),
      child: Container(
        padding: EdgeInsets.all(compactHeight ? 22 : 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: zBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LoginProductHeader(),
              SizedBox(height: compactHeight ? 14 : 20),
              TextFormField(
                controller: emailController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                validator: validateEmail,
                decoration: _input('Work email', Icons.email_outlined),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: validatePassword,
                onFieldSubmitted: (_) => onLogin?.call(),
                decoration: _input('Password', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    onPressed: onTogglePassword,
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: zMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              LoginOptions(
                rememberMe: rememberMe,
                onRememberChanged: onRememberChanged,
                onForgotPassword: onForgotPassword,
              ),
              const SizedBox(height: 8),
              SignInButton(loading: loading, onLogin: onLogin),
              const SizedBox(height: 10),
              JoinWorkspaceButton(onPressed: onJoinWorkspace),
              const SizedBox(height: 12),
              const Text(
                'Sign in to the Aman Infra client workspace. New users are '
                'provisioned by the workspace administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: zMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
