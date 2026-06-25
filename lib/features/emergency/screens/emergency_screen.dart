import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/models/vital_model.dart';
import '../../../data/repositories/medicine_repository.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../data/repositories/vital_repository.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../widgets/sos_button.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final UserProfileRepository _profileRepo = UserProfileRepository();
  final VitalRepository _vitalRepo = VitalRepository();
  final MedicineRepository _medRepo = MedicineRepository();

  UserProfileModel? _profile;
  VitalModel? _latestVital;
  List<MedicineModel> _medicines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final profile = await _profileRepo.getProfile();
    final vital = await _vitalRepo.getLatestVital();
    final meds = await _medRepo.getActiveMedicines();
    if (mounted) {
      setState(() {
        _profile = profile;
        _latestVital = vital;
        _medicines = meds;
        _loading = false;
      });
    }
  }

  Future<void> _callEmergencyContact() async {
    final phone = _profile?.emergencyContactPhone;
    if (phone == null || phone.isEmpty) {
      _showNoContactDialog();
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone call to $phone')),
        );
      }
    }
  }

  void _showNoContactDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('No Emergency Contact'),
        content: const Text(
          'Please set up your emergency contact in the profile settings first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditContactDialog() {
    final nameController = TextEditingController(text: _profile?.emergencyContactName ?? '');
    final phoneController = TextEditingController(text: _profile?.emergencyContactPhone ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.contact_phone, color: Color(0xFFE53935)),
              SizedBox(width: 8),
              Text('Emergency Contact'),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Contact Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: kIsWeb
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.contacts_outlined, color: Color(0xFFE53935)),
                                tooltip: 'Select from Phone Contacts',
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  try {
                                    if (await FlutterContacts.requestPermission(readonly: true)) {
                                      final contact = await FlutterContacts.openExternalPick();
                                      if (contact != null) {
                                        String name = contact.displayName;
                                        String phone = '';
                                        if (contact.phones.isNotEmpty) {
                                          phone = contact.phones.first.number;
                                        }
                                        setDialogState(() {
                                          nameController.text = name;
                                          phoneController.text = phone;
                                        });
                                      }
                                    } else {
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Contacts permission denied. Please enter details manually.'),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Failed to pick contact: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please fill out both name and phone number')),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                
                final baseProfile = _profile ?? UserProfileModel(
                  name: 'User',
                  createdAt: DateTime.now().toIso8601String(),
                );
                
                final updated = baseProfile.copyWith(
                  emergencyContactName: name,
                  emergencyContactPhone: phone,
                );
                
                await _profileRepo.upsertProfile(updated);
                await _loadData();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emergency contact saved successfully.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _buildHealthSummary() {
    final buffer = StringBuffer();
    buffer.writeln('🏥 MediTrack Emergency Health Summary');
    buffer.writeln('Generated: ${AppDateUtils.formatDisplayWithTime(AppDateUtils.nowString())}');
    buffer.writeln();

    if (_profile != null) {
      buffer.writeln('👤 Patient Information');
      buffer.writeln('Name: ${_profile!.name}');
      if (_profile!.age != null) buffer.writeln('Age: ${_profile!.age}');
      if (_profile!.bloodGroup != null &&
          _profile!.bloodGroup!.isNotEmpty) {
        buffer.writeln('Blood Group: ${_profile!.bloodGroup}');
      }
      if (_profile!.conditions != null &&
          _profile!.conditions!.isNotEmpty) {
        buffer.writeln('Conditions: ${_profile!.conditions}');
      }
      if (_profile!.allergies != null && _profile!.allergies!.isNotEmpty) {
        buffer.writeln('Allergies: ${_profile!.allergies}');
      }
      buffer.writeln();
    }

    if (_latestVital != null) {
      final v = _latestVital!;
      buffer.writeln('❤️ Latest Vitals (${AppDateUtils.formatDisplay(v.recordedAt)})');
      if (v.systolic != null && v.diastolic != null) {
        buffer.writeln(
            'Blood Pressure: ${v.systolic!.toInt()}/${v.diastolic!.toInt()} mmHg');
      }
      if (v.heartRate != null) {
        buffer.writeln('Heart Rate: ${v.heartRate!.toInt()} bpm');
      }
      if (v.oxygenSaturation != null) {
        buffer.writeln('SpO₂: ${v.oxygenSaturation!.toInt()}%');
      }
      if (v.temperature != null) {
        buffer.writeln('Temperature: ${v.temperature!.toStringAsFixed(1)}°C');
      }
      if (v.bloodGlucose != null) {
        buffer.writeln('Blood Glucose: ${v.bloodGlucose!.toInt()} mg/dL');
      }
      buffer.writeln();
    }

    if (_medicines.isNotEmpty) {
      buffer.writeln('💊 Current Medications');
      for (final m in _medicines) {
        buffer.writeln(
            '• ${m.name}${m.dosage != null ? " (${m.dosage})" : ""} — ${m.frequency}');
      }
    }

    return buffer.toString();
  }

  Future<void> _shareHealthSummary() async {
    final summary = _buildHealthSummary();
    await SharePlus.instance.share(
      ShareParams(text: summary, subject: 'MediTrack Emergency Health Summary'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(
        title: 'Emergency',
        showBack: true,
        backgroundColor: Colors.white,
      ),
      body: _loading
          ? const LoadingIndicator(message: 'Loading emergency info...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // SOS section
                  _sosCard(),
                  const SizedBox(height: 16),

                  // Emergency contact card
                  _emergencyContactCard(),
                  const SizedBox(height: 16),

                  // Latest vitals card
                  if (_latestVital != null) ...[
                    _vitalsCard(),
                    const SizedBox(height: 16),
                  ],

                  // Current medicines card
                  if (_medicines.isNotEmpty) ...[
                    _medicinesCard(),
                    const SizedBox(height: 16),
                  ],

                  // Share button
                  _shareButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _sosCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF5F5), Color(0xFFFFEBEE)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Emergency SOS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFFB71C1C),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hold the button for 3 seconds to call your emergency contact',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFFE57373)),
          ),
          const SizedBox(height: 28),
          SosButton(onTriggered: _callEmergencyContact),
        ],
      ),
    );
  }

  Widget _emergencyContactCard() {
    final hasContact = _profile?.emergencyContactName != null &&
        _profile!.emergencyContactName!.isNotEmpty;
    final hasPhone = _profile?.emergencyContactPhone != null &&
        _profile!.emergencyContactPhone!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.contacts_outlined,
                  color: Color(0xFFE53935), size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Emergency Contact',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (hasContact || hasPhone)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFE53935)),
                onPressed: _showEditContactDialog,
                tooltip: 'Edit Emergency Contact',
              ),
          ]),
          const SizedBox(height: 14),
          if (!hasContact && !hasPhone) ...[
            const Text(
              'No emergency contact set up yet.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showEditContactDialog,
                icon: const Icon(Icons.add_call, size: 18),
                label: const Text('Add Contact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]
          else ...[
            if (hasContact)
              _infoRow(Icons.person_outline, 'Name',
                  _profile!.emergencyContactName!),
            if (hasPhone) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.phone_outlined, 'Phone',
                  _profile!.emergencyContactPhone!),
            ],
            if (hasPhone) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _callEmergencyContact,
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: const Text('Call Now'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                    side: const BorderSide(color: Color(0xFFE53935)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _vitalsCard() {
    final v = _latestVital!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.monitor_heart_outlined,
                  color: Color(0xFF1D9E75), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Latest Vitals',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(
                    AppDateUtils.formatDisplayWithTime(v.recordedAt),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (v.systolic != null && v.diastolic != null)
                _vitalChip('BP',
                    '${v.systolic!.toInt()}/${v.diastolic!.toInt()} mmHg'),
              if (v.heartRate != null)
                _vitalChip('HR', '${v.heartRate!.toInt()} bpm'),
              if (v.oxygenSaturation != null)
                _vitalChip('SpO₂', '${v.oxygenSaturation!.toInt()}%'),
              if (v.temperature != null)
                _vitalChip('Temp', '${v.temperature!.toStringAsFixed(1)}°C'),
              if (v.bloodGlucose != null)
                _vitalChip(
                    'Glucose', '${v.bloodGlucose!.toInt()} mg/dL'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _medicinesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF5C6BC0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medication_outlined,
                  color: Color(0xFF5C6BC0), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Current Medicines (${_medicines.length})',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: 12),
          ..._medicines.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const Icon(Icons.circle, size: 6,
                      color: Color(0xFF5C6BC0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${m.name}${m.dosage != null ? " — ${m.dosage}" : ""}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    m.frequency,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ]),
              )),
        ],
      ),
    );
  }

  Widget _shareButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _shareHealthSummary,
        icon: const Icon(Icons.share_outlined, size: 18),
        label: const Text('Share Health Summary'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5C6BC0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 14, color: const Color(0xFF6B7280)),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF6B7280))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    ]);
  }

  Widget _vitalChip(String label, String value) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1D9E75).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFF1D9E75).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: Color(0xFF6B7280))),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D9E75))),
        ],
      ),
    );
  }
}
