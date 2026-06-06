import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';

class DigitalPrescriptionScreen extends StatefulWidget {
  const DigitalPrescriptionScreen({super.key, this.record});
  final HealthRecord? record;

  @override
  State<DigitalPrescriptionScreen> createState() => _DigitalPrescriptionScreenState();
}

class _DigitalPrescriptionScreenState extends State<DigitalPrescriptionScreen> {
  Future<Prescription>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future != null) return;
    final appState = AppScope.of(context);
    final record = widget.record ?? (appState.records.isEmpty ? null : appState.records.first);
    if (record != null) _future = appState.getPrescriptionForRecord(record);
  }

  // ─── Real PDF Generation ──────────────────────────────────────────────────

  Future<void> _downloadPdf(Prescription rx) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Rx',
                      style: pw.TextStyle(
                        fontSize: 40,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Qurexa Digital Prescription',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        pw.Text(
                          _formatDate(rx.date),
                          style: pw.TextStyle(color: PdfColors.grey300, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // ── Patient & Doctor Info ────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue200),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  children: [
                    _rxInfoRow('Doctor', rx.doctorName),
                    pw.SizedBox(height: 6),
                    _rxInfoRow('Patient', rx.patientName),
                    pw.SizedBox(height: 6),
                    _rxInfoRow('Diagnosis', rx.diagnosis),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // ── Medicines ────────────────────────────────────────────────
              pw.Text(
                'PRESCRIBED MEDICATIONS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.blue100),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(3),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                    children: [
                      _tableHeader('Medicine'),
                      _tableHeader('Dose'),
                      _tableHeader('Frequency'),
                      _tableHeader('Duration'),
                    ],
                  ),
                  ...rx.medicines.map(
                    (m) => pw.TableRow(
                      children: [
                        _tableCell(m.name),
                        _tableCell(m.dose.isNotEmpty ? m.dose : '—'),
                        _tableCell(m.frequency.isNotEmpty ? m.frequency : '—'),
                        _tableCell(m.duration.isNotEmpty ? m.duration : '—'),
                      ],
                    ),
                  ),
                ],
              ),

              if (rx.notes.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'DOCTOR\'S NOTES',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text(rx.notes, style: const pw.TextStyle(fontSize: 11)),
                ),
              ],

              pw.Spacer(),

              // ── Footer ───────────────────────────────────────────────────
              pw.Divider(color: PdfColors.blue200),
              pw.Text(
                'Generated by Qurexa — Digital Health Platform | ${_formatDate(DateTime.now())}',
                style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'prescription_${rx.patientName.replaceAll(' ', '_')}_${_formatDate(rx.date)}.pdf',
    );
  }

  pw.Widget _rxInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(color: PdfColors.grey700, fontSize: 11),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
        ),
      ],
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 14),
              decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Digital Prescription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('View & manage your prescriptions', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.description_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _future == null
                  ? const EmptyStateView(
                      title: 'No prescription found',
                      message: 'No prescription record is available.',
                      icon: Icons.description_rounded,
                    )
                  : FutureBuilder<Prescription>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final rx = snapshot.data!;
                        return ListView(
                          padding: const EdgeInsets.all(AppTheme.space4),
                          children: <Widget>[
                            // Rx header card
                            MediQCard(
                              gradient: AppTheme.primaryGradient,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      const Text(
                                        'Rx',
                                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, fontStyle: FontStyle.italic),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            const Text('Qurexa Digital Prescription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                            Text(formatDate(rx.date), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _RxRow(label: 'Doctor', value: rx.doctorName),
                                  _RxRow(label: 'Patient', value: rx.patientName),
                                  _RxRow(label: 'Diagnosis', value: rx.diagnosis),
                                ],
                              ),
                            ),
                            // Medicines
                            const SectionHeading(title: 'Medications'),
                            ...rx.medicines.map((med) => MediQCard(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primarySoft,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    ),
                                    child: const Icon(Icons.medication_rounded, color: AppTheme.accentBlue, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(med.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                        if (med.dose.isNotEmpty || med.frequency.isNotEmpty)
                                          Text(
                                            [med.dose, med.frequency, med.duration]
                                                .where((s) => s.isNotEmpty)
                                                .join(' • '),
                                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            // Notes
                            if (rx.notes.isNotEmpty) ...<Widget>[
                              const SectionHeading(title: 'Doctor Notes'),
                              MediQCard(
                                child: Text(rx.notes, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                              ),
                            ],
                            const SizedBox(height: 8),
                            PrimaryActionButton(
                              label: 'Set Medicine Reminders',
                              icon: Icons.alarm_rounded,
                              onPressed: () => Navigator.of(context).pushNamed(AppRouter.medicationReminders),
                            ),
                            const SizedBox(height: 10),
                            SecondaryActionButton(
                              label: 'Download PDF',
                              icon: Icons.download_rounded,
                              onPressed: () => _downloadPdf(rx),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RxRow extends StatelessWidget {
  const _RxRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Text('$label: ', style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))),
        ],
      ),
    );
  }
}
