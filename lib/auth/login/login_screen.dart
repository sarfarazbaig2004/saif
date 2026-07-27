// FILE: lib/auth/login/login_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/auth/login/login_brand_panel.dart';
import 'package:QUIK/auth/login/login_form_card.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/administration/company/screen_join_company.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = true;

  void _clearSnackBars() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.clearSnackBars();
  }

  void _toast(String msg, {bool err = false, SnackBarAction? action}) {
    if (!mounted) return;
    _clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? Colors.red : zSuccess,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Work email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return 'Enter a valid work email';
    return null;
  }

  String? _validatePassword(String? value) {
    final pass = value ?? '';
    if (pass.isEmpty) return 'Password is required';
    if (pass.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _toast('Please correct the highlighted fields', err: true);
      return;
    }

    final email = _email.text.trim().toLowerCase();
    final pass = _pass.text;
    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      _clearSnackBars();
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => 'No account found for this email.',
        'wrong-password' => 'Incorrect password.',
        'invalid-email' => 'Invalid email format.',
        'invalid-credential' => 'Invalid email or password.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Please wait and try again.',
        _ => e.message ?? 'Sign in failed.',
      };

      _toast(
        msg,
        err: true,
        action: SnackBarAction(
          label: 'Reset password',
          textColor: Colors.white,
          onPressed: () => _sendPasswordReset(email),
        ),
      );
    } catch (e) {
      _toast('Sign in failed: $e', err: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim().toLowerCase();
    if (email.isEmpty) {
      _toast('Enter your work email first', err: true);
      return;
    }

    final emailError = _validateEmail(email);
    if (emailError != null) {
      _toast(emailError, err: true);
      return;
    }

    await _sendPasswordReset(email);
  }

  void _createWorkspace() {
    _toast(
      'New workspace setup is managed by Genzprotech. Contact your administrator.',
    );
  }

  Future<void> _sendPasswordReset(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      _toast('Enter your work email first', err: true);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: normalizedEmail,
      );
      _toast('Password reset link sent to $normalizedEmail');
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Unable to send password reset email.', err: true);
    } catch (e) {
      _toast('Failed: $e', err: true);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isWide = media.size.width >= 1040;
    final compactHeight = media.size.height < 760;

    return Scaffold(
      backgroundColor: zLoginBg,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)),
              child: child,
            ),
          ),
          child: isWide
              ? Row(
                  children: [
                    const Expanded(flex: 59, child: LoginBrandPanel()),
                    Expanded(
                      flex: 41,
                      child: _LoginFormPane(
                        child: _buildFormCard(
                          compactHeight: compactHeight,
                          showProductHeader: false,
                        ),
                      ),
                    ),
                  ],
                )
              : _MobileLoginLayout(
                  bottomInset: media.viewInsets.bottom,
                  child: _buildFormCard(
                    compactHeight: compactHeight,
                    showProductHeader: true,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required bool compactHeight,
    required bool showProductHeader,
  }) {
    return LoginFormCard(
      formKey: _formKey,
      emailController: _email,
      passwordController: _pass,
      compactHeight: compactHeight,
      showProductHeader: showProductHeader,
      obscurePassword: _obscure,
      loading: _loading,
      rememberMe: _rememberMe,
      validateEmail: _validateEmail,
      validatePassword: _validatePassword,
      onTogglePassword: () => setState(() => _obscure = !_obscure),
      onRememberChanged: (value) {
        setState(() => _rememberMe = value ?? false);
      },
      onForgotPassword: _loading ? null : _forgot,
      onLogin: _loading ? null : _login,
      onCreateWorkspace: _createWorkspace,
      onJoinWorkspace: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScreenJoinCompany()),
      ),
    );
  }
}

class _LoginFormPane extends StatelessWidget {
  const _LoginFormPane({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4F6F9), Color(0xFFDCE5F1)],
          ),
        ),
      ),
      const Positioned(
        right: -160,
        bottom: -180,
        child: _AmbientCircle(size: 520),
      ),
      const Positioned(left: -170, top: -220, child: _AmbientCircle(size: 460)),
      SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 30),
            child: child,
          ),
        ),
      ),
    ],
  );
}

class _MobileLoginLayout extends StatelessWidget {
  const _MobileLoginLayout({required this.bottomInset, required this.child});

  final double bottomInset;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const LoginBrandPanel(compact: true),
      Container(color: const Color(0xFF0F172A).withValues(alpha: 0.42)),
      SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 24, 18, bottomInset + 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 48,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    ],
  );
}

class _AmbientCircle extends StatelessWidget {
  const _AmbientCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      gradient: RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0),
        ],
      ),
    ),
  );
}
