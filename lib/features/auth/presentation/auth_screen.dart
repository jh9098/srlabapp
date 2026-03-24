import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../app/app_scope.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authRepository = AppScope.of(context).authRepository;
    if (authRepository == null) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (_isLogin) {
        await authRepository.signInWithEmail(email: email, password: password);
      } else {
        await authRepository.signUpWithEmail(
          email: email,
          password: password,
          displayName: _nameController.text.trim(),
          nickname: _nicknameController.text.trim(),
          fullName: _nameController.text.trim(),
        );
      }
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyAuthError(error.toString())), backgroundColor: const Color(0xFFDC2626)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    final authRepository = AppScope.of(context).authRepository;
    if (authRepository == null) return;

    setState(() => _isLoading = true);
    try {
      await authRepository.signInWithGoogle();
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google 로그인 중 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyAuthError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('wrong-password')) return '이메일 또는 비밀번호가 올바르지 않습니다.';
    if (raw.contains('email-already-in-use')) return '이미 사용 중인 이메일입니다. 로그인을 시도해 보세요.';
    if (raw.contains('network-request-failed')) return '네트워크 연결을 확인해 주세요.';
    return '로그인 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BrandHeader(isLogin: _isLogin),
                  const SizedBox(height: AppSpacing.section),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('로그인')),
                      ButtonSegment(value: false, label: Text('회원가입')),
                    ],
                    selected: {_isLogin},
                    onSelectionChanged: _isLoading ? null : (v) => setState(() => _isLogin = v.first),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!_isLogin) ...[
                                TextFormField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  decoration: const InputDecoration(labelText: '이름', prefixIcon: Icon(Icons.person_outline_rounded)),
                                  validator: (value) => !_isLogin && (value ?? '').trim().isEmpty ? '이름을 입력해 주세요.' : null,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _nicknameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(labelText: '닉네임 (선택)', prefixIcon: Icon(Icons.badge_outlined)),
                                ),
                                const SizedBox(height: 10),
                              ],
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(labelText: '이메일', prefixIcon: Icon(Icons.mail_outline_rounded)),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) return '이메일을 입력해 주세요.';
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!.trim())) return '올바른 이메일 형식이 아닙니다.';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: '비밀번호',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (value) => (value ?? '').length < 6 ? '비밀번호는 6자 이상이어야 합니다.' : null,
                              ),
                              const SizedBox(height: 18),
                              FilledButton(
                                onPressed: _isLoading ? null : _submit,
                                child: _isLoading
                                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text(_isLogin ? '로그인' : '회원가입'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Google로 계속하기'),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _isLogin ? '가입하면 관심종목/알림 기능을 바로 사용할 수 있어요.' : '가입 후 바로 관심종목과 알림을 설정해 보세요.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => setState(() => _isLogin = !_isLogin),
                      child: Text(_isLogin ? '계정이 없으신가요? 회원가입' : '이미 계정이 있으신가요? 로그인'),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: null,
                      child: Text('비밀번호 재설정 (준비 중)', style: TextStyle(color: Colors.grey.shade500)),
                    ),
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isLogin});

  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.show_chart_rounded, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text('지지저항Lab', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          isLogin ? '지지선 기반 관찰 신호를 빠르게 확인하세요' : '가입하면 관심종목/알림 관리가 가능합니다',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
