import 'package:flutter/material.dart';
import 'package:i_tabung/features/auth/view/sign_up_page.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.role});

  final UserRole role;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _hidePassword = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7E7E7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Center(child: Image(image: AssetImage('assets/images/auth/jar.png'), width: 96, height: 96)),
              const Center(
                child: Text('I-Tabung', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w700, color: Color(0xFF034C4B))),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text('Sign in to your account', style: TextStyle(fontSize: 26, color: Color(0xFF034C4B))),
              ),
              const SizedBox(height: 28),
              const Text('Email Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _textField('Enter your email address', controller: _emailController),
              const SizedBox(height: 22),
              const Text('Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _textField(
                'Enter your password',
                controller: _passwordController,
                obscure: _hidePassword,
                suffix: IconButton(
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('Forgot password?', style: TextStyle(fontSize: 20, color: Color(0xFF707070))),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005A57),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: Text(_isLoading ? 'Signing in...' : 'Sign in', style: const TextStyle(fontSize: 24, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('other way to sign in', style: TextStyle(fontSize: 20, color: Color(0xFF767676)))),
              const SizedBox(height: 16),
              const Center(child: CircleAvatar(radius: 32, backgroundColor: Colors.white, child: Text('G', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))))),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SignUpPage(role: widget.role)));
                  },
                  child: const Text('Don’t have an account? Create Account', style: TextStyle(fontSize: 18, color: Color(0xFF034C4B))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final client = _resolveClient();
      await client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign in failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  SupabaseClient _resolveClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw Exception('Supabase is not initialized. Restart app and try again.');
    }
  }

  Widget _textField(String hint, {required TextEditingController controller, bool obscure = false, Widget? suffix}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB9B9B9), fontSize: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF1F1F1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFC5C5C5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFC5C5C5))),
      ),
    );
  }
}

