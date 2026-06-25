import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
  String? _profileImagePath;

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
        _profileImagePath = profile.profileImagePath;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    // Show bottom sheet to select source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1D9E75)),
                title: const Text('Photo Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFF1D9E75)),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        String finalPath = pickedFile.path;
        
        // On non-web platform, copy to app's document directory to ensure persistence
        if (!kIsWeb) {
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = 'profile_pic_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
          final savedFile = File(pickedFile.path);
          final savedImage = await savedFile.copy('${appDir.path}/$fileName');
          finalPath = savedImage.path;
        }

        setState(() {
          _profileImagePath = finalPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  Future<void> _pickContact() async {
    if (kIsWeb) return;
    try {
      if (await FlutterContacts.requestPermission(readonly: true)) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null && mounted) {
          String name = contact.displayName;
          String phone = '';
          if (contact.phones.isNotEmpty) {
            phone = contact.phones.first.number;
          }
          setState(() {
            _emergencyNameCtrl.text = name;
            _emergencyPhoneCtrl.text = phone;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacts permission denied. Please enter details manually.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick contact: $e')),
        );
      }
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
            profileImagePath: _profileImagePath,
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
            profileImagePath: _profileImagePath,
          );

    await _profileRepo.upsertProfile(profile);

    if (mounted) {
      setState(() {
        _saving = false;
        _existingProfile = profile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
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
      appBar: const CustomAppBar(title: 'My Profile', showBack: false),
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
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.primaryColor.withValues(alpha: 0.2),
                                      width: 3,
                                    ),
                                    image: _profileImagePath != null
                                        ? DecorationImage(
                                            image: kIsWeb
                                                ? NetworkImage(_profileImagePath!) as ImageProvider
                                                : FileImage(File(_profileImagePath!)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: _profileImagePath == null
                                      ? Icon(
                                          Icons.person_rounded,
                                          size: 60,
                                          color: theme.primaryColor,
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
                        decoration: InputDecoration(
                          labelText: 'Contact Phone Number',
                          hintText: 'e.g. +1234567890',
                          prefixIcon: const Icon(Icons.phone_iphone_rounded),
                          suffixIcon: kIsWeb
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.contacts_outlined, color: Color(0xFF1D9E75)),
                                  tooltip: 'Select from Phone Contacts',
                                  onPressed: _pickContact,
                                ),
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
