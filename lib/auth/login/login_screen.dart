// FILE: lib/auth/login/login_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: label,
      prefixIcon: Icon(icon, color: zMuted, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: zBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: zBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: zBlue, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      labelStyle: const TextStyle(
        color: zMuted,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: zMuted, fontSize: 13.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final isWide = screen.width > 1120;
    final compactHeight = screen.height < 780;

    return Scaffold(
      backgroundColor: zLoginBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned(
            top: -70,
            left: -50,
            child: _BgGlow(size: 280, color: Color(0x442563EB)),
          ),
          const Positioned(
            bottom: -130,
            right: -40,
            child: _BgGlow(size: 340, color: Color(0x331D4ED8)),
          ),
          const Positioned(
            top: 120,
            right: 140,
            child: _BgGlow(size: 170, color: Color(0x2216A34A)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: isWide ? 28 : 18,
                    right: isWide ? 28 : 18,
                    top: compactHeight ? 14 : 22,
                    bottom: media.viewInsets.bottom + 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight - (compactHeight ? 28 : 42),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (isWide) ...[
                            const Expanded(
                              flex: 6,
                              child: _LoginSideBranding(),
                            ),
                            const SizedBox(width: 28),
                          ],
                          Expanded(
                            flex: isWide ? 5 : 1,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isWide ? 455 : 460,
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(
                                    compactHeight ? 22 : 28,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: zBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.07,
                                        ),
                                        blurRadius: 30,
                                        offset: const Offset(0, 16),
                                      ),
                                    ],
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 54,
                                              height: 54,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                color: zBlueSoft,
                                                border: Border.all(
                                                  color: zBorder,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Image.asset(
                                                  'assets/images/logo.png',
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(
                                                        Icons.business,
                                                        size: 28,
                                                        color: zBlue,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    kAppName,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: zText,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    kAppTagline,
                                                    style: TextStyle(
                                                      color: zMuted,
                                                      fontSize: 13,
                                                      height: 1.35,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: compactHeight ? 14 : 20,
                                        ),
                                        TextFormField(
                                          controller: _email,
                                          textInputAction: TextInputAction.next,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          autofillHints: const [
                                            AutofillHints.username,
                                            AutofillHints.email,
                                          ],
                                          validator: _validateEmail,
                                          decoration: _input(
                                            'Work email',
                                            Icons.email_outlined,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: _pass,
                                          obscureText: _obscure,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          validator: _validatePassword,
                                          onFieldSubmitted: (_) => _login(),
                                          decoration:
                                              _input(
                                                'Password',
                                                Icons.lock_outline,
                                              ).copyWith(
                                                suffixIcon: IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _obscure = !_obscure;
                                                    });
                                                  },
                                                  icon: Icon(
                                                    _obscure
                                                        ? Icons
                                                              .visibility_off_outlined
                                                        : Icons
                                                              .visibility_outlined,
                                                    color: zMuted,
                                                  ),
                                                ),
                                              ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _rememberMe,
                                              activeColor: zBlue,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onChanged: (v) {
                                                setState(() {
                                                  _rememberMe = v ?? false;
                                                });
                                              },
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
                                              onPressed: _loading
                                                  ? null
                                                  : _forgot,
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
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 48,
                                          child: FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: zBlue,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              elevation: 0,
                                            ),
                                            onPressed: _loading ? null : _login,
                                            child: _loading
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Text(
                                                    'Sign In',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          height: 44,
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: zBorder,
                                              ),
                                              foregroundColor: zBlue,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const ScreenJoinCompany(),
                                              ),
                                            ),
                                            child: const Text(
                                              'Join Existing Workspace',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Use your AMAN Infra account credentials. New users are created by the AMAN Infra administrator.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: zMuted,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            height: 1.45,
                                          ),
                                        ),
                                        SizedBox(
                                          height: compactHeight ? 12 : 18,
                                        ),
                                        const Text(
                                          'QUIK ERP for AMAN Infra production, inventory, finance and team operations',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: zMuted,
                                            fontSize: 12,
                                            height: 1.45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BgGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _BgGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}

class _LoginSideBranding extends StatelessWidget {
  const _LoginSideBranding();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF7FAFF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: zBorder),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 38, vertical: 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Run AMAN Infra operations in one secure ERP workspace.',
              style: TextStyle(
                fontSize: 34,
                height: 1.16,
                fontWeight: FontWeight.w900,
                color: zText,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Manage production, inventory, purchase, dispatch, finance, users and daily operations from one dedicated workspace.',
              style: TextStyle(
                fontSize: 15,
                height: 1.65,
                color: zMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
