import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/user_profile_repository.dart';

class AuthHelper extends ChangeNotifier {
  static final AuthHelper _instance = AuthHelper._internal();
  factory AuthHelper() => _instance;

  AuthHelper._internal();

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyAcceptedPrecautions = 'accepted_precautions';

  final UserProfileRepository _profileRepo = UserProfileRepository();
  SharedPreferences? _prefs;

  bool _initialized = false;
  bool _isLoggedInState = false;
  bool _onboardingCompletedState = false;
  bool _acceptedPrecautionsState = false;
  String? _userEmailState;

  bool get isLoggedIn => _isLoggedInState;
  bool get isAdmin => false;
  bool get onboardingCompleted => _onboardingCompletedState;
  bool get acceptedPrecautions => _acceptedPrecautionsState;
  String? get userEmail => _userEmailState;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isLoggedInState = _prefs?.getBool(_keyIsLoggedIn) ?? false;
    _onboardingCompletedState = _prefs?.getBool(_keyOnboardingCompleted) ?? false;
    _acceptedPrecautionsState = _prefs?.getBool(_keyAcceptedPrecautions) ?? false;
    _userEmailState = _prefs?.getString(_keyUserEmail);
    _initialized = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await init();
    await _prefs?.setBool(_keyOnboardingCompleted, true);
    _onboardingCompletedState = true;
    notifyListeners();
  }

  Future<void> acceptPrecautions() async {
    await init();
    await _prefs?.setBool(_keyAcceptedPrecautions, true);
    _acceptedPrecautionsState = true;
    notifyListeners();
  }

  Future<bool> login(String email, String name, {
    int? age,
    String? bloodGroup,
    int syncStatus = 1,
  }) async {
    await init();
    
    // Save to shared preferences
    await _prefs?.setBool(_keyIsLoggedIn, true);
    await _prefs?.setString(_keyUserEmail, email);
    
    _isLoggedInState = true;
    _userEmailState = email;

    // Save/Upsert Profile in DB
    final profile = UserProfileModel(
      name: name,
      age: age ?? 78, // default fallback
      bloodGroup: bloodGroup ?? 'O+', // default fallback
      createdAt: DateTime.now().toIso8601String(),
      userId: email,
      syncStatus: syncStatus,
    );
    await _profileRepo.upsertProfile(profile);

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await init();
    
    await _prefs?.remove(_keyIsLoggedIn);
    await _prefs?.remove(_keyUserEmail);
    
    _isLoggedInState = false;
    _userEmailState = null;
    
    notifyListeners();
  }

  Future<UserProfileModel?> getCurrentProfile() async {
    return await _profileRepo.getProfile(userId: _userEmailState);
  }
}
