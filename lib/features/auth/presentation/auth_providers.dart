import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';
import '../data/user_model.dart';

// Provide AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Provide AuthState changes
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

// Fetch user profile dynamically based on auth state
final userProfileProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return null;
  final repo = ref.watch(authRepositoryProvider);
  return await repo.getProfile(authState.uid);
});

// Theme Mode Provider (Light / Dark) - Default is system/light
final isDarkModeProvider = StateProvider<bool>((ref) => false);

// Active Season Filter Provider for Laporan/Dashboard
final selectedSeasonIdProvider = StateProvider<String?>((ref) => null);

// AuthController for managing login, register, and signout actions
class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(const AsyncData(null));

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final cred = await _repo.loginWithEmailAndPassword(email: email, password: password);
      final profile = await _repo.getProfile(cred.user!.uid);
      state = AsyncData(profile);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber,
    required String role,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        phoneNumber: phoneNumber,
        role: role,
      );
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    try {
      final user = await _repo.loginWithGoogle();
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> silentSignIn() async {
    state = const AsyncLoading();
    try {
      final user = await _repo.loginWithGoogleSilently();
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    try {
      await _repo.sendPasswordResetEmail(email);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _repo.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateProfile(AppUser updatedUser) async {
    state = const AsyncLoading();
    try {
      await _repo.updateProfile(updatedUser);
      state = AsyncData(updatedUser);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<AppUser?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
