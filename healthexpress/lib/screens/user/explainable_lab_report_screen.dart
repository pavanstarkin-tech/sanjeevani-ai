import 'package:flutter/material.dart';
import '../../services/explainable_clinical_ai_service.dart';

/// Screen displaying Explainable Clinical AI, Plain-Language Lab Report
/// Interpretation, ICD-10 / SNOMED coding, and Drug-Drug Interaction Warnings.
class ExplainableLabReportScreen extends StatefulWidget {
  const ExplainableLabReportScreen({super.key});

  @override
  State<ExplainableLabReportScreen> createState() => _ExplainableLabReportScreenState();
}

class _ExplainableLabReportScreenState extends State<ExplainableLabReportScreen> {
  final ExplainableClinicalAiService _aiService = ExplainableClinicalAiService();

  final TextEditingController _hba1cController = TextEditingController(text: '7.2');
  final TextEditingController _creatinineController = TextEditingController(text: '1.5');
  final TextEditingController _plateletsController = TextEditingController(text: '95000');
  final TextEditingController _newDrugController = TextEditingController(text: 'Aspirin');

  final List<String> _currentMeds = ['Warfarin 5mg', 'Metformin 500mg', 'Telmisartan 40mg'];
  final String _selectedCondition = 'Type 2 Diabetes & Viral Fever';

  late ExplainableClinicalAssessment _assessment;

  @override
  void initState() {
    super.initState();
    _recalculateAssessment();
  }

  void _recalculateAssessment() {
    final hba1c = double.tryParse(_hba1cController.text) ?? 6.5;
    final creat = double.tryParse(_creatinineController.text) ?? 1.1;
    final plat = double.tryParse(_plateletsController.text) ?? 180000;

    setState(() {
      _assessment = _aiService.generateAssessment(
        condition: _selectedCondition,
        labValues: {
          'hba1c': hba1c,
          'creatinine': creat,
          'platelets': plat,
        },
        currentMedications: _currentMeds,
        newMedication: _newDrugController.text.trim().isNotEmpty ? _newDrugController.text.trim() : null,
      );
    });
  }

  @override
  void dispose() {
    _hba1cController.dispose();
    _creatinineController.dispose();
    _plateletsController.dispose();
    _newDrugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explainable Clinical AI & Labs',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Plain-Language Decoding & DDI Safety',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Diagnostic Transparency Card (Confidence % & Clinical Reasoning)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology_alt_rounded, color: Color(0xFF38BDF8), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            _assessment.patientCondition,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Text(
                          '${_assessment.diagnosticConfidencePercent.toStringAsFixed(1)}% Certainty',
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Standardized Medical Codes (ICD-10 & SNOMED CT)
                  Row(
                    children: [
                      _codeBadge('ICD-10: ${_assessment.standardCode.icd10Code}', const Color(0xFF38BDF8)),
                      const SizedBox(width: 8),
                      _codeBadge('SNOMED: ${_assessment.standardCode.snomedCode}', const Color(0xFF8B5CF6)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Step-by-Step Clinical Reasoning (Explainability):',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ..._assessment.diagnosticStepByStepReasoning.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 14)),
                          Expanded(
                            child: Text(
                              step,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Drug-Drug Interaction (DDI) Safety Checker
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131D33),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _assessment.drugInteractions.isNotEmpty
                      ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                      : Colors.white12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.medication_liquid_rounded, color: Color(0xFFF59E0B), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Drug-Drug Interaction Checker',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (_assessment.drugInteractions.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _assessment.drugInteractions.isNotEmpty ? 'CONFLICT DETECTED' : 'SAFE COMBINATION',
                          style: TextStyle(
                            color: _assessment.drugInteractions.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Active Medications: ${_currentMeds.join(', ')}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                  ),
                  const SizedBox(height: 10),

                  // Input for new drug
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newDrugController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Test New Medicine',
                            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          onChanged: (_) => _recalculateAssessment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E60F6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _recalculateAssessment,
                        child: const Text('Check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  // Interaction Warning Banners
                  if (_assessment.drugInteractions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._assessment.drugInteractions.map(
                      (alert) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF450A0A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${alert.severity}: ${alert.drugA} + ${alert.drugB}',
                                  style: const TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold, fontSize: 12.5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.clinicalEffect,
                              style: const TextStyle(color: Colors.white, fontSize: 11.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Advice: ${alert.actionAdvice}',
                              style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Plain-Language Lab Values Decoder
            const Text(
              'Decoded Laboratory Reports (Plain Language)',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ..._assessment.labParameters.map((param) => _buildLabCard(param)),
          ],
        ),
      ),
    );
  }

  Widget _buildLabCard(InterpretedLabParam param) {
    Color statusColor;
    if (param.status == 'NORMAL') {
      statusColor = const Color(0xFF10B981);
    } else if (param.status == 'BORDERLINE') {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFFEF4444);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  param.testName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  '${param.value} ${param.unit} (${param.status})',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Normal Reference: ${param.normalRange}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
          ),
          const SizedBox(height: 8),

          // Plain English Explanation
          Text(
            param.plainLanguageExplanation,
            style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 6),

          // Regional Telugu / Hindi Translation
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.translate_rounded, color: Color(0xFF38BDF8), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    param.regionalTranslation,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Dietary / Lifestyle Advice
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: param.dietaryRecommendations.map((r) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('🥗 $r', style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _codeBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
