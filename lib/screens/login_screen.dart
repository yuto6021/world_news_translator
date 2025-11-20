import 'package:flutter/material.dart';
import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await UserService.instance
          .login(_emailController.text.trim(), _passwordController.text);
      if (user == null) {
        throw Exception('認証に失敗しました');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ようこそ ${user.displayName}')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'メールを入力してください';
    final pattern = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!pattern.hasMatch(v.trim())) return 'メール形式が不正です';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'パスワードを入力してください';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('アカウントにログイン', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('登録済みメールとパスワードを入力してください', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'メールアドレス',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: 'パスワード',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 24),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _loading ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(Icons.login),
                            label: Text(_loading ? 'ログイン中...' : 'ログイン'),
                            onPressed: _loading ? null : _login,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ),
      ),
    );
  }
}
