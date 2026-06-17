import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/shared_widgets.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }

    try {
      setState(() => _loading = true);
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Login failed');
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const AppLogo(height: 96),
            const SizedBox(height: 16),
            AppSectionTitle('Login with credentials'),
            const SizedBox(height: 48),
            AppTextField(controller: _emailCtrl, hint: 'Email or Username'),
            const SizedBox(height: 20),
            AppTextField(
              controller: _passCtrl,
              hint: 'Password',
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: AppTheme.grey,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 40),
            AppButton(
              onPressed: _loading ? null : _login,
              text: 'Login',
              loading: _loading,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No account? ', style: GoogleFonts.montserrat(fontSize: 13)),
                GestureDetector(
                  onTap: () => context.push('/signup'),
                  child: Text(
                    'SignUp',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              '© STYLEE INTERNATIONAL',
              style: GoogleFonts.montserrat(fontSize: 10, color: AppTheme.grey, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}