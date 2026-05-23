import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_tabung/features/auth/view/sign_in_page.dart';
import 'package:i_tabung/features/goal_planner/model/goal_planner_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, required this.role});

  final UserRole role;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _familyCodeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _familyCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isChild = widget.role == UserRole.child;

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
                child: Text('Create new account', style: TextStyle(fontSize: 26, color: Color(0xFF034C4B))),
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
              const SizedBox(height: 22),
              const Text('Confirm Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _textField(
                'Enter your confirm password',
                controller: _confirmPasswordController,
                obscure: _hideConfirmPassword,
                suffix: IconButton(
                  onPressed: () => setState(() => _hideConfirmPassword = !_hideConfirmPassword),
                  icon: Icon(_hideConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                ),
              ),
              if (isChild) ...[
                const SizedBox(height: 22),
                const Text('Family Code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _textField('Enter family code', controller: _familyCodeController),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005A57),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: Text(_isLoading ? 'Signing up...' : 'Sign up', style: const TextStyle(fontSize: 24, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('other way to sign in', style: TextStyle(fontSize: 20, color: Color(0xFF767676)))),
              const SizedBox(height: 16),
              const Center(child: CircleAvatar(radius: 32, backgroundColor: Colors.white, child: Text('G', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))))),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SignInPage(role: widget.role))),
                  child: const Text('Already have an account? Back to Sign In', style: TextStyle(fontSize: 18, color: Color(0xFF034C4B))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final familyCode = _familyCodeController.text.trim().toUpperCase();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _toast('Please fill all required fields.');
      return;
    }
    if (password != confirm) {
      _toast('Password and confirm password do not match.');
      return;
    }
    if (widget.role == UserRole.child && familyCode.isEmpty) {
      _toast('Please enter family code.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = _resolveClient();
      if (client.auth.currentSession != null) {
        await client.auth.signOut();
      }
      final auth = await client.auth.signUp(email: email, password: password);
      final userId = auth.user?.id;
      if (userId == null) {
        throw Exception('Sign up completed, but user profile is not available yet.');
      }

      // If email confirmation is enabled, Supabase may not return an active session yet.
      // In that case, RLS-protected inserts (profiles/families/family_members) will fail.
      final activeUserId = client.auth.currentUser?.id;
      if (auth.session == null || activeUserId == null || activeUserId != userId) {
        if (!mounted) return;
        _toast('Account created. Please verify your email, then sign in to complete setup.');
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SignInPage(role: widget.role)));
        return;
      }

      if (widget.role == UserRole.parent) {
        final rpcResult = await client.rpc(
          'register_parent_account',
          params: {
            'p_full_name': email.split('@').first,
            'p_email': email,
            'p_family_name': '${email.split('@').first} Family',
          },
        );
        final inserted = (rpcResult as List).first as Map<String, dynamic>;

        if (!mounted) return;
        await _showFamilyCodeDialog(inserted['invite_code'] as String);
      } else {
        await client.rpc(
          'register_child_account',
          params: {
            'p_full_name': email.split('@').first,
            'p_email': email,
            'p_invite_code': familyCode,
          },
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SignInPage(role: widget.role)));
    } on PostgrestException catch (e) {
      _toast('Sign up failed: ${e.message}');
    } catch (e) {
      _toast('Sign up failed: $e');
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

  Future<void> _showFamilyCodeDialog(String code) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Family Code Created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share this code with your child:'),
              const SizedBox(height: 12),
              SelectableText(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!context.mounted) return;
                Navigator.of(context).pop();
                _toast('Family code copied.');
              },
              child: const Text('Copy'),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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



