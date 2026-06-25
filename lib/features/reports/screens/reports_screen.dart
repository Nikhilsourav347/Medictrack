// lib/features/reports/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/vital_model.dart';
import '../../../data/models/symptom_model.dart';
import '../../../data/models/doctor_visit_model.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/repositories/vital_repository.dart';
import '../../../data/repositories/symptom_repository.dart';
import '../../../data/repositories/doctor_visit_repository.dart';
import '../../../data/repositories/medicine_repository.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../shared/utils/date_utils.dart';
import '../widgets/date_range_picker_widget.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedFilter = 'week';
  String _startDate = '';
  String _endDate = '';

  List<VitalModel> _vitals = [];
  List<SymptomModel> _symptoms = [];
  List<DoctorVisitModel> _visits = [];
  int _activeMedicinesCount = 0;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = _formatDate(now.subtract(const Duration(days: 7)));
    _endDate = _formatDate(now);
    _loadData();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final vitals = await VitalRepository().getVitalsByDateRange(_startDate, _endDate);
      final symptoms = await SymptomRepository().getSymptomsByDateRange(_startDate, _endDate);
      final visits = await DoctorVisitRepository().getVisitsByDateRange(_startDate, _endDate);
      final activeMeds = await MedicineRepository().getActiveMedicines();

      setState(() {
        _vitals = vitals;
        _symptoms = symptoms;
        _visits = visits;
        _activeMedicinesCount = activeMeds.length;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports data: $e')),
        );
      }
    }
  }

  void _onFilterChanged(String filter, String start, String end) {
    if (filter == 'custom') {
      _showCustomRangePicker();
    } else {
      setState(() {
        _selectedFilter = filter;
        _startDate = start;
        _endDate = end;
      });
      _loadData();
    }
  }

  Future<void> _showCustomRangePicker() async {
    final initialStart = DateTime.tryParse(_startDate) ?? DateTime.now();
    final initialEnd = DateTime.tryParse(_endDate) ?? DateTime.now();

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1D9E75),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _selectedFilter = 'custom';
        _startDate = _formatDate(pickedRange.start);
        _endDate = _formatDate(pickedRange.end);
      });
      _loadData();
    }
  }

  Future<void> _exportPdfReport() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating your health report...'),
        duration: Duration(seconds: 2),
      ),
    );

    setState(() => _loading = true);

    try {
      final vitals = await VitalRepository().getVitalsByDateRange(_startDate, _endDate);
      final symptoms = await SymptomRepository().getSymptomsByDateRange(_startDate, _endDate);
      final visits = await DoctorVisitRepository().getVisitsByDateRange(_startDate, _endDate);
      final List<MedicineModel> activeMedicines = await MedicineRepository().getActiveMedicines();
      final UserProfileModel? userProfile = await UserProfileRepository().getProfile();

      final pdf = pw.Document();

      pw.Widget buildPdfTable(List<String> headers, List<List<String>> rows) {
        return pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1D9E75)),
              children: headers.map((h) => pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  h,
                  style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              )).toList(),
            ),
            ...List.generate(rows.length, (index) {
              final row = rows[index];
              final isEven = index % 2 == 0;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : PdfColors.grey100),
                children: row.map((cell) => pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    cell,
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                )).toList(),
              );
            }),
          ],
        );
      }

      pw.Widget buildPdfFooter() {
        return pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Generated by MediTrack — Personal Health Companion',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ),
          ],
        );
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('MediTrack Health Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                if (userProfile != null) ...[
                  pw.Text('Patient: ${userProfile.name} (Age: ${userProfile.age ?? "N/A"}, Blood Group: ${userProfile.bloodGroup ?? "N/A"})',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                ],
                pw.Text('Report period: $_startDate to $_endDate', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                pw.Text('Generated on: ${DateTime.now().toString().split('.').first}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey400, thickness: 0.5),
                pw.SizedBox(height: 12),

                pw.Text('Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Bullet(text: 'Total vitals logged: ${vitals.length}', style: const pw.TextStyle(fontSize: 9)),
                pw.Bullet(text: 'Total symptoms recorded: ${symptoms.length}', style: const pw.TextStyle(fontSize: 9)),
                pw.Bullet(text: 'Total doctor visits: ${visits.length}', style: const pw.TextStyle(fontSize: 9)),
                pw.Bullet(text: 'Active medicines: ${activeMedicines.length}', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 16),

                pw.Text('Vitals Log', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                if (vitals.isEmpty)
                  pw.Text('No vitals logged in this period.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
                else
                  buildPdfTable(
                    ['Date', 'BP (Sys/Dia)', 'Sugar', 'Temp', 'SpO2', 'Weight'],
                    vitals.map((v) => [
                      v.recordedAt.split(' ').first,
                      v.systolic != null && v.diastolic != null ? '${v.systolic!.toInt()}/${v.diastolic!.toInt()}' : '-',
                      v.bloodSugar != null ? v.bloodSugar!.toStringAsFixed(1) : '-',
                      v.temperature != null ? '${v.temperature!.toStringAsFixed(1)}°C' : '-',
                      v.spo2 != null ? '${v.spo2!.toInt()}%' : '-',
                      v.weight != null ? '${v.weight!.toStringAsFixed(1)}kg' : '-',
                    ]).toList(),
                  ),
                
                pw.Spacer(),
                buildPdfFooter(),
              ],
            );
          },
        ),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Active Medicines', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                if (activeMedicines.isEmpty)
                  pw.Text('No active medicines.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
                else
                  buildPdfTable(
                    ['Medicine Name', 'Dosage', 'Frequency', 'Status'],
                    activeMedicines.map((m) => [
                      m.name,
                      m.dosage ?? '-',
                      m.frequency,
                      m.isActive ? 'Active' : 'Inactive',
                    ]).toList(),
                  ),
                pw.SizedBox(height: 16),

                pw.Text('Symptoms Log', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                if (symptoms.isEmpty)
                  pw.Text('No symptoms recorded in this period.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
                else
                  buildPdfTable(
                    ['Date', 'Symptom', 'Severity'],
                    symptoms.map((s) => [
                      s.recordedAt.split(' ').first,
                      s.symptomName,
                      '${s.severity}/10',
                    ]).toList(),
                  ),
                pw.SizedBox(height: 16),

                pw.Text('Doctor Visits', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                if (visits.isEmpty)
                  pw.Text('No doctor visits in this period.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
                else
                  buildPdfTable(
                    ['Date', 'Doctor', 'Diagnosis', 'Follow-up'],
                    visits.map((v) => [
                      v.visitDate.split(' ').first,
                      v.doctorName,
                      v.diagnosis ?? '-',
                      v.followUpDate != null ? v.followUpDate!.split(' ').first : '-',
                    ]).toList(),
                  ),

                pw.Spacer(),
                buildPdfFooter(),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      await Printing.layoutPdf(onLayout: (_) async => bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report ready to save or share')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildSummaryCard(
          label: 'Vitals Logged',
          value: '${_vitals.length}',
          icon: Icons.favorite,
          color: Colors.green,
        ),
        _buildSummaryCard(
          label: 'Medicines Active',
          value: '$_activeMedicinesCount',
          icon: Icons.medication,
          color: Colors.blue,
        ),
        _buildSummaryCard(
          label: 'Symptoms Recorded',
          value: '${_symptoms.length}',
          icon: Icons.edit_note,
          color: Colors.orange,
        ),
        _buildSummaryCard(
          label: 'Doctor Visits',
          value: '${_visits.length}',
          icon: Icons.local_hospital,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsTrendSection() {
    final bpVitals = _vitals.where((v) => v.systolic != null).toList();
    final trendVitals = bpVitals.take(7).toList().reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Blood Pressure Trend (Systolic)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (trendVitals.isEmpty)
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: Center(
              child: Text(
                'No blood pressure data for this period',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
          )
        else
          Container(
            height: 180,
            padding: const EdgeInsets.only(top: 24, right: 16, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 0.5),
            ),
            child: CustomPaint(
              size: const Size(double.infinity, 150),
              painter: BPTrendPainter(trendVitals),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentVitalsList() {
    final recentVitals = _vitals.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Vitals',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (recentVitals.isEmpty)
          const Text('No recent vitals logged in this period.', style: TextStyle(color: Colors.grey, fontSize: 13))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentVitals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final vital = recentVitals[index];
              return _buildVitalCard(vital);
            },
          ),
      ],
    );
  }

  Widget _buildVitalCard(VitalModel vital) {
    final chips = <Widget>[];

    if (vital.systolic != null && vital.diastolic != null) {
      final color = _getBPColor(vital.systolic!);
      chips.add(_buildVitalChip('BP: ${vital.systolic!.toInt()}/${vital.diastolic!.toInt()}', color));
    }
    if (vital.bloodSugar != null) {
      final color = _getSugarColor(vital.bloodSugar!);
      chips.add(_buildVitalChip('Sugar: ${vital.bloodSugar!.toStringAsFixed(1)}', color));
    }
    if (vital.temperature != null) {
      final color = _getTempColor(vital.temperature!);
      chips.add(_buildVitalChip('Temp: ${vital.temperature!.toStringAsFixed(1)}°C', color));
    }
    if (vital.spo2 != null) {
      final color = _getSpO2Color(vital.spo2!);
      chips.add(_buildVitalChip('SpO2: ${vital.spo2!.toInt()}%', color));
    }
    if (vital.weight != null) {
      chips.add(_buildVitalChip('Weight: ${vital.weight!.toStringAsFixed(1)} kg', Colors.blue));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Entry #${vital.id ?? ""}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                AppDateUtils.formatDisplayWithTime(vital.recordedAt),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
        ],
      ),
    );
  }

  Color _getBPColor(double systolic) {
    if (systolic < 120) return Colors.green;
    if (systolic < 140) return Colors.amber;
    return Colors.red;
  }

  Color _getSugarColor(double sugar) {
    if (sugar < 100) return Colors.green;
    if (sugar < 126) return Colors.amber;
    return Colors.red;
  }

  Color _getTempColor(double temp) {
    if (temp >= 36.1 && temp <= 37.2) return Colors.green;
    if (temp > 37.2 && temp <= 38.0) return Colors.amber;
    return Colors.red;
  }

  Color _getSpO2Color(double spo2) {
    if (spo2 >= 95) return Colors.green;
    if (spo2 >= 90) return Colors.amber;
    return Colors.red;
  }

  Widget _buildVitalChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildRecentSymptomsList() {
    final recentSymptoms = _symptoms.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Symptoms',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (recentSymptoms.isEmpty)
          const Text('No recent symptoms logged in this period.', style: TextStyle(color: Colors.grey, fontSize: 13))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentSymptoms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final symptom = recentSymptoms[index];
              return _buildSymptomCard(symptom);
            },
          ),
      ],
    );
  }

  Widget _buildSymptomCard(SymptomModel symptom) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                symptom.symptomName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                AppDateUtils.formatDisplay(symptom.recordedAt),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Severity: ${symptom.severity}/10',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth * (symptom.severity / 10.0);
                    return Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: width,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getSeverityColor(symptom.severity),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (symptom.notes != null && symptom.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              symptom.notes!,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSeverityColor(int severity) {
    if (severity <= 3) return Colors.green;
    if (severity <= 6) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Health Reports'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleTextStyle: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF1D9E75),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DateRangePickerWidget(
                      selectedFilter: _selectedFilter,
                      startDate: _startDate,
                      endDate: _endDate,
                      onFilterChanged: _onFilterChanged,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryGrid(),
                    const SizedBox(height: 20),
                    _buildVitalsTrendSection(),
                    const SizedBox(height: 20),
                    _buildRecentVitalsList(),
                    const SizedBox(height: 20),
                    _buildRecentSymptomsList(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _exportPdfReport,
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        label: const Text(
                          'Export PDF Report',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D9E75),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

class BPTrendPainter extends CustomPainter {
  final List<VitalModel> vitals;
  BPTrendPainter(this.vitals);

  @override
  void paint(Canvas canvas, Size size) {
    if (vitals.isEmpty) return;

    final paintLine = Paint()
      ..color = const Color(0xFF1D9E75)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = const Color(0xFF1D9E75)
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    const double paddingX = 40.0;
    const double paddingY = 30.0;

    final chartWidth = size.width - paddingX - 10;
    final chartHeight = size.height - paddingY - 10;

    double maxVal = vitals.map((v) => v.systolic!).reduce((a, b) => a > b ? a : b);
    double minVal = vitals.map((v) => v.systolic!).reduce((a, b) => a < b ? a : b);
    if (maxVal == minVal) {
      maxVal += 20;
      minVal -= 20;
    } else {
      final range = maxVal - minVal;
      maxVal += range * 0.15;
      minVal -= range * 0.15;
    }
    if (minVal < 0) minVal = 0;

    final points = <Offset>[];
    final count = vitals.length;

    for (int i = 0; i < count; i++) {
      final val = vitals[i].systolic!;
      final double x = paddingX + (count > 1 ? i * (chartWidth / (count - 1)) : chartWidth / 2);
      final double y = size.height - paddingY - ((val - minVal) / (maxVal - minVal) * chartHeight);
      points.add(Offset(x, y));
    }

    for (int i = 0; i <= 3; i++) {
      final double y = size.height - paddingY - (i * (chartHeight / 3));
      canvas.drawLine(Offset(paddingX, y), Offset(size.width - 10, y), paintGrid);

      final double gridVal = minVal + (i * ((maxVal - minVal) / 3));
      final textPainter = TextPainter(
        text: TextSpan(
          text: gridVal.toStringAsFixed(0),
          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }

    if (count > 1) {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < count; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paintLine);
    }

    for (int i = 0; i < count; i++) {
      final pt = points[i];
      final val = vitals[i].systolic!;
      canvas.drawCircle(pt, 5, paintDot);

      final valPainter = TextPainter(
        text: TextSpan(
          text: val.toStringAsFixed(0),
          style: const TextStyle(color: Color(0xFF1D9E75), fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      valPainter.paint(canvas, Offset(pt.dx - valPainter.width / 2, pt.dy - valPainter.height - 4));

      final dateStr = _formatDateLabel(vitals[i].recordedAt);
      final datePainter = TextPainter(
        text: TextSpan(
          text: dateStr,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      datePainter.paint(canvas, Offset(pt.dx - datePainter.width / 2, size.height - paddingY + 6));
    }
  }

  String _formatDateLabel(String recordedAt) {
    try {
      final dt = DateTime.parse(recordedAt);
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  bool shouldRepaint(covariant BPTrendPainter oldDelegate) {
    return oldDelegate.vitals != vitals;
  }
}
