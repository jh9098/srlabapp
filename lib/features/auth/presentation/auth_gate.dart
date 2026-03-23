import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../user/domain/user_profile.dart';
import 'auth_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<UserProfile>? _ensureProfileFuture;
  String? _lastEnsuredUid;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final authRepository = scope.authRepository;
    final profileRepository = scope.userProfileRepository;

    if (scope.config.useFirebaseOnly && (!scope.config.isFirebaseConfigured || authRepository == null || profileRepository == null)) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Firebase 인증 설정이 없어 로그인 화면을 열 수 없습니다.\nFirebase dart-define 값을 먼저 확인하세요.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!scope.config.isFirebaseConfigured || authRepository == null || profileRepository == null) {
      return widget.child;
    }

    return StreamBuilder<User?>(
      stream: authRepository.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen(message: '로그인 상태를 확인하고 있습니다.');
        }

        final user = authSnapshot.data;
        if (user == null) {
          _ensureProfileFuture = null;
          _lastEnsuredUid = null;
          return const AuthScreen();
        }

        if (_lastEnsuredUid != user.uid) {
          _lastEnsuredUid = user.uid;
          final pendingSeed = authRepository.takePendingUserProfileSeed(user.uid);
          // 사용자 프로필 보정 책임은 AuthGate 한 곳에서만 맡아
          // 로그인 직후 라우팅 진입 전에 1회만 실행한다.
          _ensureProfileFuture = profileRepository.ensureUserProfile(
            user: user,
            nickname: pendingSeed?.nickname ?? '',
            fullName: pendingSeed?.fullName ?? '',
            gender: pendingSeed?.gender ?? '',
            birthDate: pendingSeed?.birthDate ?? '',
            phoneNumber: pendingSeed?.phoneNumber ?? '',
          );
        }
        return FutureBuilder<UserProfile>(
          future: _ensureProfileFuture,
          builder: (context, ensureSnapshot) {
            if (ensureSnapshot.connectionState != ConnectionState.done) {
              return const _AuthLoadingScreen(message: '사용자 프로필을 준비하고 있습니다.');
            }
            if (ensureSnapshot.hasError) {
              return _AuthErrorScreen(error: ensureSnapshot.error.toString());
            }
            return StreamBuilder<UserProfile?>(
              stream: profileRepository.watchProfile(user.uid),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return const _AuthLoadingScreen(message: '권한 정보를 불러오고 있습니다.');
                }
                if (profileSnapshot.hasError) {
                  return _AuthErrorScreen(error: profileSnapshot.error.toString());
                }
                if (!profileSnapshot.hasData) {
                  return const _AuthLoadingScreen(message: 'users/{uid} 문서를 기다리고 있습니다.');
                }
                return widget.child;
              },
            );
          },
        );
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final authRepository = AppScope.of(context).authRepository;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              const Text('인증 초기화 중 문제가 발생했습니다.'),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: authRepository == null ? null : authRepository.signOut,
                child: const Text('다시 로그인하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
