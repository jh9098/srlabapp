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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final scope = AppScope.of(context);
    final authRepository = scope.authRepository;
    final profileRepository = scope.userProfileRepository;
    if (authRepository == null || profileRepository == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (_isLogin) {
        final credential = await authRepository.signInWithEmail(
          email: email,
          password: password,
        );
        if (credential.user != null) {
          await profileRepository.ensureUserProfile(user: credential.user!);
        }
      } else {
        final credential = await authRepository.signUpWithEmail(
          email: email,
          password: password,
          displayName: _nameController.text.trim(),
        );
        if (credential.user != null) {
          await profileRepository.ensureUserProfile(
            user: credential.user!,
            nickname: _nicknameController.text.trim(),
            fullName: _nameController.text.trim(),
          );
        }
      }
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증 처리 중 오류가 발생했습니다.\n$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final scope = AppScope.of(context);
    final authRepository = scope.authRepository;
    final profileRepository = scope.userProfileRepository;
    if (authRepository == null || profileRepository == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await authRepository.signInWithGoogle();
      if (credential.user != null) {
        await profileRepository.ensureUserProfile(user: credential.user!);
      }
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google 로그인 중 오류가 발생했습니다.\n$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '지지저항Lab',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isLogin
                        ? '같은 Firebase 계정으로 웹과 앱을 함께 사용합니다.'
                        : '가입 즉시 users/{uid} 문서를 만들고 기본 role은 guest로 시작합니다.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: '이름'),
                                validator: (value) {
                                  if (!_isLogin && (value ?? '').trim().isEmpty) {
                                    return '이름을 입력해주세요.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nicknameController,
                                decoration: const InputDecoration(labelText: '닉네임'),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: '이메일'),
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return '이메일을 입력해주세요.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: '비밀번호'),
                              validator: (value) {
                                if ((value ?? '').length < 6) {
                                  return '비밀번호는 6자 이상이어야 합니다.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              child: Text(_isLogin ? '이메일 로그인' : '회원가입'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Google 로그인'),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => setState(() => _isLogin = !_isLogin),
                              child: Text(_isLogin ? '회원가입으로 이동' : '이미 계정이 있어요'),
                            ),
                            if (_isLoading) ...[
                              const SizedBox(height: 12),
                              const CircularProgressIndicator(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.blueGrey.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '비밀번호 재설정은 현재 웹 구조와 맞추기 위해 아직 넣지 않았습니다.\n'
                        '이번 단계는 로그인/회원가입/users 문서 유지까지 먼저 맞추는 범위입니다.',
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
