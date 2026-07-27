import 'dart:ui';

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
  final bool showProductHeader;
  final bool obscurePassword;
  final bool loading;
  final bool rememberMe;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onLogin;
  final VoidCallback onCreateWorkspace;
  final VoidCallback onJoinWorkspace;

  const LoginFormCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.validateEmail,
    required this.validatePassword,
    required this.compactHeight,
    required this.showProductHeader,
    required this.obscurePassword,
    required this.loading,
    required this.rememberMe,
    required this.onTogglePassword,
    required this.onRememberChanged,
    required this.onForgotPassword,
    required this.onLogin,
    required this.onCreateWorkspace,
    required this.onJoinWorkspace,
  });

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 19),
      border: _border(const Color(0xFFD7E0EB)),
      enabledBorder: _border(const Color(0xFFD7E0EB)),
      focusedBorder: _border(zAccent, width: 1.4),
      errorBorder: _border(Colors.red),
      focusedErrorBorder: _border(Colors.red, width: 1.2),
      hintStyle: const TextStyle(
        color: Color(0xFF91A2B9),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 570),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: showProductHeader
                  ? 24
                  : compactHeight
                  ? 40
                  : 60,
              vertical: compactHeight ? 32 : 58,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB).withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(38),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.13),
                  blurRadius: 70,
                  offset: const Offset(0, 30),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showProductHeader) ...[
                    const LoginProductHeader(),
                    SizedBox(height: compactHeight ? 22 : 30),
                  ],
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      color: zText,
                      fontSize: 30,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter your credentials to access your workspace.',
                    style: TextStyle(
                      color: zMuted,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: compactHeight ? 26 : 42),
                  TextFormField(
                    controller: emailController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    validator: validateEmail,
                    decoration: _input('name@company.com'),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: validatePassword,
                    onFieldSubmitted: (_) => onLogin?.call(),
                    decoration: _input('Password').copyWith(
                      suffixIcon: IconButton(
                        onPressed: onTogglePassword,
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF91A2B9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  LoginOptions(
                    rememberMe: rememberMe,
                    onRememberChanged: onRememberChanged,
                    onForgotPassword: onForgotPassword,
                  ),
                  const SizedBox(height: 22),
                  SignInButton(loading: loading, onLogin: onLogin),
                  const SizedBox(height: 24),
                  LoginWorkspaceLinks(
                    onCreateWorkspace: onCreateWorkspace,
                    onJoinWorkspace: onJoinWorkspace,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
