import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  // AFTER
  Future<void> _signup() async {
    final name     = _nameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final confirm  = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }

    if (password != confirm) {
      _showSnack('Passwords do not match');
      return;
    }

    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(name, email, password);

    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        context.go('/home');
      } else {
        _showSnack(auth.error ?? 'Signup failed');
      }
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
            AppSectionTitle('Create account'),
            const SizedBox(height: 36),
            AppTextField(controller: _nameCtrl, hint: 'Name'),
            const SizedBox(height: 16),
            AppTextField(controller: _emailCtrl, hint: 'Email or Username'),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passCtrl,
              hint: 'Password',
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                    size: 18,
                    color: AppTheme.grey),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
                controller: _confirmCtrl,
                hint: 'Confirm Password',
                obscure: true),
            const SizedBox(height: 40),
            AppButton(
                onPressed: _loading ? null : _signup,
                text: 'SignUp',
                loading: _loading),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ',
                    style: GoogleFonts.montserrat(fontSize: 13)),
                GestureDetector(
                    onTap: () => context.pop(),
                    child: Text('Login',
                        style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline))),
              ],
            ),
            const SizedBox(height: 40),
            Text('© STYLEE INTERNATIONAL',
                style: GoogleFonts.montserrat(
                    fontSize: 10, color: AppTheme.grey, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}