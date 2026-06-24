import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_indicator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserProfileRepository _profileRepo = UserProfileRepository();

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  String? _selectedBloodGroup;
  bool _loading = true;
  bool _saving = false;
  UserProfileModel? _existingProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _conditionsCtrl.dispose();
    _allergiesCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final profile = await _profileRepo.getProfile();
    if (profile != null && mounted) {
      setState(() {
        _existingProfile = profile;
        _nameCtrl.text = profile.name;
        _ageCtrl.text = profile.age != null ? profile.age.toString() : '';
        _conditionsCtrl.text = profile.conditions ?? '';
        _allergiesCtrl.text = profile.allergies ?? '';
        _emergencyNameCtrl.text = profile.emergencyContactName ?? '';
        _emergencyPhoneCtrl.text = profile.emergencyContactPhone ?? '';
        if (AppConstants.bloodGroups.contains(profile.bloodGroup)) {
          _selectedBloodGroup = profile.bloodGroup;
        }
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ageInt = _ageCtrl.text.isNotEmpty ? int.tryParse(_ageCtrl.text) : null;
    final now = AppDateUtils.nowString();

    final profile = _existingProfile != null
        ? _existingProfile!.copyWith(
            name: _nameCtrl.text.trim(),
            age: ageInt,
            bloodGroup: _selectedBloodGroup,
            conditions: _conditionsCtrl.text.trim().isNotEmpty ? _conditionsCtrl.text.trim() : '',
            allergies: _allergiesCtrl.text.trim().isNotEmpty ? _allergiesCtrl.text.trim() : '',
            emergencyContactName: _emergencyNameCtrl.text.trim().isNotEmpty ? _emergencyNameCtrl.text.trim() : '',
            emergencyContactPhone: _emergencyPhoneCtrl.text.trim().isNotEmpty ? _emergencyPhoneCtrl.text.trim() : '',
            lastUpdated: now,
            syncStatus: 0,
          )
        : UserProfileModel(
            name: _nameCtrl.text.trim(),
            age: ageInt,
            bloodGroup: _selectedBloodGroup,
            conditions: _conditionsCtrl.text.trim().isNotEmpty ? _conditionsCtrl.text.trim() : '',
            allergies: _allergiesCtrl.text.trim().isNotEmpty ? _allergiesCtrl.text.trim() : '',
            emergencyContactName: _emergencyNameCtrl.text.trim().isNotEmpty ? _emergencyNameCtrl.text.trim() : '',
            emergencyContactPhone: _emergencyPhoneCtrl.text.trim().isNotEmpty ? _emergencyPhoneCtrl.text.trim() : '',
            createdAt: now,
            lastUpdated: now,
            syncStatus: 0,
          );

    await _profileRepo.upsertProfile(profile);

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  Widget _card(List<Widget> children) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(title: 'My Profile', showBack: true),
      body: _loading
          ? const LoadingIndicator(message: 'Loading profile data...')
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar display and top header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2), width: 2),
                            ),
                            child: Icon(Icons.person_rounded, size: 48, color: theme.primaryColor),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Personal Health Profile',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Used by AI assistant and emergency SOS to personalize support',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 1: Basic Information
                    const Text(
                      'Basic Information',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    _card([
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'e.g. John Doe',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Age',
                                hintText: 'e.g. 65',
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v != null && v.isNotEmpty) {
                                  final age = int.tryParse(v);
                                  if (age == null || age <= 0 || age > 150) {
                                    return 'Invalid age';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedBloodGroup,
                              decoration: const InputDecoration(
                                labelText: 'Blood Group',
                                prefixIcon: Icon(Icons.bloodtype_outlined),
                              ),
                              items: AppConstants.bloodGroups.map((bg) {
                                return DropdownMenuItem<String>(
                                  value: bg,
                                  child: Text(bg),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedBloodGroup = v),
                            ),
                          ),
                        ],
                      ),
                    ]),

                    // Section 2: Medical Conditions
                    const Text(
                      'Medical Details',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    _card([
                      TextFormField(
                        controller: _conditionsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Existing Conditions',
                          hintText: 'e.g. Hypertension, Diabetes (comma separated)',
                          prefixIcon: Icon(Icons.medical_information_outlined),
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _allergiesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Allergies',
                          hintText: 'e.g. Penicillin, Peanuts (comma separated)',
                          prefixIcon: Icon(Icons.warning_amber_rounded),
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ]),

                    // Section 3: Emergency Contact
                    const Text(
                      'Emergency Contact',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    _card([
                      TextFormField(
                        controller: _emergencyNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Contact Name',
                          hintText: 'e.g. Daughter / Son Name',
                          prefixIcon: Icon(Icons.contact_phone_outlined),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emergencyPhoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Contact Phone Number',
                          hintText: 'e.g. +1234567890',
                          prefixIcon: Icon(Icons.phone_iphone_rounded),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ]),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF1D9E75),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Save Profile Details'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
