import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '277554551041-m6j3t9c2vsdo3hbggop09ldst2q2qg18.apps.googleusercontent.com' : null,
  );

  // Stream of current user's Auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user ID
  String? get currentUid => _auth.currentUser?.uid;

  // Fetch AppUser profile from Firestore
  Future<AppUser?> getProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Register with Email and Password
  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final user = credential.user!;
    final appUser = AppUser(
      uid: user.uid,
      email: email,
      displayName: displayName,
      phoneNumber: phoneNumber,
      photoUrl: '',
      address: '',
      role: role,
      createdAt: DateTime.now(),
    );

    // Save profile to Firestore
    await _db.collection('users').doc(user.uid).set(appUser.toMap());
    return appUser;
  }

  // Login with Email and Password
  Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Login with Google
  Future<AppUser?> loginWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final User? user = userCredential.user;
    if (user == null) return null;

    // Check if user profile already exists
    AppUser? existingUser = await getProfile(user.uid);
    if (existingUser != null) {
      return existingUser;
    }

    // Create a new user profile
    final newUser = AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Petani AgriFarm',
      phoneNumber: user.phoneNumber ?? '',
      photoUrl: user.photoURL ?? '',
      address: '',
      role: 'Owner', // Default role is Owner when logging in via Google first time
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(user.uid).set(newUser.toMap());
    return newUser;
  }

  // Silent Google Sign In
  Future<AppUser?> loginWithGoogleSilently() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) return null;

      return await getProfile(user.uid);
    } catch (e) {
      return null;
    }
  }

  // Forgot password email send
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Update profile
  Future<void> updateProfile(AppUser user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }

  // Update Password dengan reautentikasi password lama
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception("User tidak terautentikasi atau email tidak ditemukan.");
    }
    // Reautentikasi
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );
    await user.reauthenticateWithCredential(credential);
    // Perbarui password
    await user.updatePassword(newPassword);
  }
}
