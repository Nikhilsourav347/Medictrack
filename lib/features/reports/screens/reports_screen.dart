import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/vital_model.dart';
import '../../../data/models/symptom_model.dart';
import '../../../data/models/doctor_visit_model.dart';
import '../../../data/repositories/vital_repository.dart';
import '../../../data/repositories/symptom_repository.dart';
import '../../../data/repositories/doctor_visit_repository.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../widgets/date_range_picker_widget.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final VitalRepository _vitalRepo = VitalRepository();
  final SymptomRepository _symptomRepo = SymptomRepository();
  final DoctorVisitRepository _visitRepo = DoctorVisitRepository();

  DateRangeOption _rangeOption = DateRangeOption.last7Days;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  List<VitalModel> _vitals = [];
  List<SymptomModel> _symptoms = [];
  List<DoctorVisitModel> _visits = [];

  bool _loading = false;
  bool _generatingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final start = _dateString(_startDate);
    final end = _dateString(_endDate);

    final vitals = await _vitalRepo.getVitalsBetween(start, end);
    final symptoms = await _symptomRepo.getSymptomsBetween(start, end);
    final visits = await _visitRepo.getVisitsBetween(start, end);

    if (mounted) {
      setState(() {
        _vitals = vitals;
        _symptoms = symptoms;
        _visits = visits;
        _loading = false;
      });
    }
  }

  String _dateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  void _onRangeOptionChanged(DateRangeOption option) {
    setState(() {
      _rangeOption = option;
      final now = DateTime.now();
      if (option == DateRangeOption.last7Days) {
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        _loadData();
      } else if (option == DateRangeOption.last30Days) {
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
        _loadData();
      }
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1D9E75)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _rangeOption = DateRangeOption.custom;
      });
      _loadData();
    }
  }

  Future<void> _generatePdf() async {
    setState(() => _generatingPdf = true);
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Row(children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('MediTrack Health Report',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${AppDateUtils.formatDisplay(_dateString(_startDate))}  –  ${AppDateUtils.formatDisplay(_dateString(_endDate))}',
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Generated on ${AppDateUtils.formatDisplay(AppDateUtils.todayString())}',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey500),
                  ),
                ],
              ),
            ]),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 16),

            // Summary stats
            pw.Row(children: [
              _pdfStatBox('Vital Records', '${_vitals.length}'),
              pw.SizedBox(width: 16),
              _pdfStatBox('Symptoms', '${_symptoms.length}'),
              pw.SizedBox(width: 16),
              _pdfStatBox('Doctor Visits', '${_visits.length}'),
            ]),
            pw.SizedBox(height: 20),

            // Vitals section
            if (_vitals.isNotEmpty) ...[
              _pdfSectionHeader('Vital Signs'),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'BP (mmHg)', 'HR (bpm)', 'SpO₂ (%)', 'Temp (°C)', 'Glucose'],
                data: _vitals.map((v) => [
                  AppDateUtils.formatDisplay(v.recordedAt),
                  v.systolic != null && v.diastolic != null
                      ? '${v.systolic!.toInt()}/${v.diastolic!.toInt()}'
                      : '—',
                  v.heartRate != null ? '${v.heartRate!.toInt()}' : '—',
                  v.oxygenSaturation != null ? '${v.oxygenSaturation!.toInt()}' : '—',
                  v.temperature != null ? v.temperature!.toStringAsFixed(1) : '—',
                  v.bloodGlucose != null ? '${v.bloodGlucose!.toInt()}' : '—',
                ]).toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1D9E75)),
                headerAlignment: pw.Alignment.center,
                cellAlignment: pw.Alignment.center,
                border: pw.TableBorder.all(color: PdfColors.grey300),
              ),
              pw.SizedBox(height: 16),
            ],

            // Symptoms section
            if (_symptoms.isNotEmpty) ...[
              _pdfSectionHeader('Symptoms'),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Symptom', 'Severity', 'Notes'],
                data: _symptoms.map((s) => [
                  AppDateUtils.formatDisplay(s.recordedAt),
                  s.symptomName,
                  '${s.severity}/10',
                  s.notes ?? '—',
                ]).toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1D9E75)),
                border: pw.TableBorder.all(color: PdfColors.grey300),
              ),
              pw.SizedBox(height: 16),
            ],

            // Doctor visits section
            if (_visits.isNotEmpty) ...[
              _pdfSectionHeader('Doctor Visits'),
              pw.SizedBox(height: 8),
              ..._visits.map((v) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Text('Doctor: ',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text(v.doctorName,
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Spacer(),
                      pw.Text(AppDateUtils.formatDisplay(v.visitDate),
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey600)),
                    ]),
                    if (v.diagnosis != null && v.diagnosis!.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.RichText(
                        text: pw.TextSpan(children: [
                          pw.TextSpan(
                              text: 'Diagnosis: ',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9)),
                          pw.TextSpan(
                              text: v.diagnosis!,
                              style: const pw.TextStyle(fontSize: 9)),
                        ]),
                      ),
                    ],
                    if (v.prescription != null &&
                        v.prescription!.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.RichText(
                        text: pw.TextSpan(children: [
                          pw.TextSpan(
                              text: 'Prescription: ',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9)),
                          pw.TextSpan(
                              text: v.prescription!,
                              style: const pw.TextStyle(fontSize: 9)),
                        ]),
                      ),
                    ],
                  ],
                ),
              )),
            ],

            if (_vitals.isEmpty && _symptoms.isEmpty && _visits.isEmpty) ...[
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text(
                  'No health data recorded for this date range.',
                  style: const pw.TextStyle(
                      fontSize: 14, color: PdfColors.grey500),
                ),
              ),
            ],
          ],
        ),
      );

      final bytes = await pdf.save();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  pw.Widget _pdfStatBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFF0FBF7),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(
              color: const PdfColor.fromInt(0xFF1D9E75), width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF1D9E75))),
            pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF1D9E75),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
          color: PdfColors.white,
        ),
      ),
    );
  }

  int get _totalRecords =>
      _vitals.length + _symptoms.length + _visits.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Health Reports',
        actions: [
          if (!_loading)
            TextButton.icon(
              onPressed: _generatingPdf ? null : _generatePdf,
              icon: _generatingPdf
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF1D9E75)))
                  : const Icon(Icons.picture_as_pdf_outlined,
                      size: 18),
              label: const Text('PDF'),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1D9E75)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Date range picker
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DateRangePickerWidget(
              selected: _rangeOption,
              startDate: _startDate,
              endDate: _endDate,
              onOptionChanged: _onRangeOptionChanged,
              onPickCustomRange: _pickCustomRange,
            ),
          ),

          const SizedBox(height: 12),

          // Summary counts
          if (!_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                _countBadge('${_vitals.length}', 'Vitals',
                    Icons.monitor_heart_outlined, const Color(0xFF1D9E75)),
                const SizedBox(width: 8),
                _countBadge('${_symptoms.length}', 'Symptoms',
                    Icons.sick_outlined, const Color(0xFFFFC107)),
                const SizedBox(width: 8),
                _countBadge('${_visits.length}', 'Visits',
                    Icons.local_hospital_outlined, const Color(0xFF5C6BC0)),
              ]),
            ),

          const SizedBox(height: 12),

          // Content
          Expanded(
            child: _loading
                ? const LoadingIndicator(message: 'Fetching health data...')
                : _totalRecords == 0
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: const Color(0xFF1D9E75),
                        onRefresh: _loadData,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          children: [
                            if (_vitals.isNotEmpty) ...[
                              _sectionHeader('Vital Signs',
                                  Icons.monitor_heart_outlined,
                                  const Color(0xFF1D9E75)),
                              ..._vitals.map((v) => _VitalSummaryRow(vital: v)),
                              const SizedBox(height: 16),
                            ],
                            if (_symptoms.isNotEmpty) ...[
                              _sectionHeader('Symptoms',
                                  Icons.sick_outlined,
                                  const Color(0xFFFFC107)),
                              ..._symptoms.map((s) => _SymptomSummaryRow(symptom: s)),
                              const SizedBox(height: 16),
                            ],
                            if (_visits.isNotEmpty) ...[
                              _sectionHeader('Doctor Visits',
                                  Icons.local_hospital_outlined,
                                  const Color(0xFF5C6BC0)),
                              ..._visits.map((v) => _VisitSummaryRow(visit: v)),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),

      // Generate PDF FAB
      floatingActionButton: _totalRecords > 0
          ? FloatingActionButton.extended(
              onPressed: _generatingPdf ? null : _generatePdf,
              backgroundColor: const Color(0xFF1D9E75),
              icon: _generatingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(_generatingPdf ? 'Generating...' : 'Generate PDF'),
            )
          : null,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1D9E75).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assessment_outlined,
                size: 36,
                color: const Color(0xFF1D9E75).withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          const Text('No data for this period',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Try a wider date range or start logging your health data.',
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade500, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _countBadge(
      String count, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label,
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color)),
      ]),
    );
  }
}

// ── Summary row widgets ────────────────────────────────────────────────────

class _VitalSummaryRow extends StatelessWidget {
  final VitalModel vital;
  const _VitalSummaryRow({required this.vital});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (vital.systolic != null && vital.diastolic != null) {
      parts.add('BP ${vital.systolic!.toInt()}/${vital.diastolic!.toInt()} mmHg');
    }
    if (vital.heartRate != null) parts.add('HR ${vital.heartRate!.toInt()} bpm');
    if (vital.oxygenSaturation != null) parts.add('SpO₂ ${vital.oxygenSaturation!.toInt()}%');
    if (vital.temperature != null) parts.add('Temp ${vital.temperature!.toStringAsFixed(1)}°C');
    if (vital.bloodGlucose != null) parts.add('Glucose ${vital.bloodGlucose!.toInt()} mg/dL');

    return _SummaryRowBase(
      icon: Icons.monitor_heart_outlined,
      iconColor: const Color(0xFF1D9E75),
      title: parts.join('  ·  '),
      subtitle: AppDateUtils.formatDisplayWithTime(vital.recordedAt),
    );
  }
}

class _SymptomSummaryRow extends StatelessWidget {
  final SymptomModel symptom;
  const _SymptomSummaryRow({required this.symptom});

  @override
  Widget build(BuildContext context) {
    final color = symptom.severity >= 7
        ? const Color(0xFFE53935)
        : symptom.severity >= 4
            ? const Color(0xFFFFC107)
            : const Color(0xFF1D9E75);
    return _SummaryRowBase(
      icon: Icons.sick_outlined,
      iconColor: const Color(0xFFFFC107),
      title: symptom.symptomName,
      subtitle: AppDateUtils.formatDisplayWithTime(symptom.recordedAt),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${symptom.severity}/10',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }
}

class _VisitSummaryRow extends StatelessWidget {
  final DoctorVisitModel visit;
  const _VisitSummaryRow({required this.visit});

  @override
  Widget build(BuildContext context) {
    return _SummaryRowBase(
      icon: Icons.local_hospital_outlined,
      iconColor: const Color(0xFF5C6BC0),
      title: visit.doctorName,
      subtitle: '${AppDateUtils.formatDisplay(visit.visitDate)}'
          '${visit.diagnosis != null ? "  ·  ${visit.diagnosis}" : ""}',
    );
  }
}

class _SummaryRowBase extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SummaryRowBase({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}
