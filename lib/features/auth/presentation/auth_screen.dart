import 'package:flutter/material.dart';

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
    final scope = AppScope.of(context);
    final authRepository = scope.authRepository;
    if (authRepository == null) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (_isLogin) {
        await authRepository.signInWithEmail(
          email: email,
          password: password,
        );
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
      final msg = _friendlyAuthError(error.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFDC2626),
        ),
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
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google 로그인 중 문제가 발생했습니다.\n$error'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyAuthError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('wrong-password')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (raw.contains('email-already-in-use')) {
      return '이미 사용 중인 이메일입니다. 로그인을 시도해 보세요.';
    }
    if (raw.contains('network-request-failed')) {
      return '네트워크 연결을 확인해 주세요.';
    }
    return '로그인 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 브랜드 영역 ──────────────────────────────────
                  _BrandHeader(isLogin: _isLogin),
                  const SizedBox(height: 32),

                  // ── 폼 카드 ──────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 회원가입 전용 필드
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: '이름',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                                validator: (value) {
                                  if (!_isLogin &&
                                      (value ?? '').trim().isEmpty) {
                                    return '이름을 입력해 주세요.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nicknameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: '닉네임 (선택)',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // 이메일
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: '이메일',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return '이메일을 입력해 주세요.';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value!.trim())) {
                                  return '올바른 이메일 형식이 아닙니다.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // 비밀번호
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: '비밀번호',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '').length < 6) {
                                  return '비밀번호는 6자 이상이어야 합니다.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // 로그인/가입 버튼
                            FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _isLoading
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? '로그인' : '회원가입',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── 구분선 ────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '또는',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Google 로그인 ────────────────────────────────
                  OutlinedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                  text: 'G',
                                  style:
                                      TextStyle(color: Color(0xFF4285F4))),
                              TextSpan(
                                  text: 'o',
                                  style:
                                      TextStyle(color: Color(0xFFEA4335))),
                              TextSpan(
                                  text: 'o',
                                  style:
                                      TextStyle(color: Color(0xFFFBBC05))),
                              TextSpan(
                                  text: 'g',
                                  style:
                                      TextStyle(color: Color(0xFF4285F4))),
                              TextSpan(
                                  text: 'l',
                                  style:
                                      TextStyle(color: Color(0xFF34A853))),
                              TextSpan(
                                  text: 'e',
                                  style:
                                      TextStyle(color: Color(0xFFEA4335))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('로 계속하기'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── 전환 + 비밀번호 재설정 ───────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? '계정이 없으신가요?' : '이미 계정이 있으신가요?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () =>
                                setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? '회원가입' : '로그인',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),

                  if (_isLogin)
                    Center(
                      child: TextButton(
                        onPressed: null, // TODO: 비밀번호 재설정
                        child: Text(
                          '비밀번호를 잊으셨나요?',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                        ),
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

/// 로그인 화면 상단 브랜드 헤더
class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isLogin});

  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 로고 아이콘
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 지지선/저항선을 상징하는 라인 아이콘
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399), // 지지 초록
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B), // 앰버 포인트
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF87171), // 저항 빨강
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 앱 이름
        Text(
          '지지저항Lab',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 6),

        // 태그라인
        Text(
          isLogin
              ? '지지선 기반 매매 전략을 받아보세요'
              : '가입하면 종목 알림을 바로 받을 수 있어요',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
