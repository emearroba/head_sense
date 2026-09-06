import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'interventions_model.dart';
export 'interventions_model.dart';

// Settings > Interventions: a repository of medications (with common doses)
// and diet types the user can add to their own profile, so those can later
// feed into the same kind of pattern analysis as symptoms/weather.
class InterventionsWidget extends StatefulWidget {
  const InterventionsWidget({super.key});

  static String routeName = 'Interventions';
  static String routePath = '/interventions';

  @override
  State<InterventionsWidget> createState() => _InterventionsWidgetState();
}

class _InterventionsWidgetState extends State<InterventionsWidget> {
  late InterventionsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const _seedMedications = [
    // (name, category, commonDoses, order)
    ('Ibuprofen', 'NSAID', ['200mg', '400mg', '600mg'], 0),
    ('Paracetamol (Acetaminophen)', 'Analgesic', ['500mg', '650mg', '1000mg'],
        1),
    ('Naproxen', 'NSAID', ['220mg', '500mg'], 2),
    ('Aspirin', 'NSAID', ['300mg', '325mg'], 3),
    ('Sumatriptan', 'Triptan', ['25mg', '50mg', '100mg'], 4),
    ('Rizatriptan', 'Triptan', ['5mg', '10mg'], 5),
    ('Zolmitriptan', 'Triptan', ['2.5mg', '5mg'], 6),
    ('Propranolol', 'Preventive', ['10mg', '20mg', '40mg', '80mg'], 7),
    ('Topiramate', 'Preventive', ['25mg', '50mg', '100mg'], 8),
    ('Amitriptyline', 'Preventive', ['10mg', '25mg', '50mg'], 9),
    ('Candesartan', 'Preventive', ['8mg', '16mg'], 10),
    ('Erenumab', 'CGRP inhibitor', ['70mg', '140mg'], 11),
    ('Rimegepant', 'CGRP inhibitor', ['75mg'], 12),
  ];

  static const _seedDietTypes = [
    // (name, description, order)
    ('Low-tyramine diet',
        'Limits aged, fermented, and cured foods often linked to migraine triggers.',
        0),
    ('Elimination diet',
        'Removes suspected trigger foods, then reintroduces them one at a time.',
        1),
    ('Anti-inflammatory diet',
        'Emphasizes whole foods, omega-3s, and produce; limits processed sugar.',
        2),
    ('Mediterranean diet',
        'Vegetables, whole grains, fish, and olive oil as dietary staples.', 3),
    ('Ketogenic diet',
        'Very low-carbohydrate, high-fat diet, sometimes used for migraine.', 4),
    ('Gluten-free diet', 'Excludes wheat, barley, and rye.', 5),
    ('Low-FODMAP diet',
        'Limits fermentable carbs that can trigger gastrointestinal symptoms.',
        6),
    ('Intermittent fasting',
        'Cycles between defined eating and fasting windows.', 7),
  ];

  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InterventionsModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedCatalogsIfEmpty());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // The catalogs are reference data, not user data - seed them once if
  // nobody has yet, same idea as any other one-time content migration.
  Future<void> _seedCatalogsIfEmpty() async {
    if (_seeded) return;
    _seeded = true;
    final medsCount = await queryMedicationsRecordCount();
    if (medsCount == 0) {
      final batch = FirebaseFirestore.instance.batch();
      for (final m in _seedMedications) {
        batch.set(
          MedicationsRecord.collection.doc(),
          createMedicationsRecordData(
            name: m.$1,
            category: m.$2,
            order: m.$4,
            isActive: true,
          )..addAll({'commonDoses': m.$3}),
        );
      }
      await batch.commit();
    }
    final dietsCount = await queryDietTypesRecordCount();
    if (dietsCount == 0) {
      final batch = FirebaseFirestore.instance.batch();
      for (final d in _seedDietTypes) {
        batch.set(
          DietTypesRecord.collection.doc(),
          createDietTypesRecordData(
            name: d.$1,
            description: d.$2,
            order: d.$3,
            isActive: true,
          ),
        );
      }
      await batch.commit();
    }
  }

  Future<void> _setMedicationDose(
    String medicationId,
    String? dose, {
    bool hadStartDate = false,
  }) async {
    if (currentUserReference == null) return;
    await currentUserReference!.update({
      'medicationDoses.$medicationId':
          dose == null ? FieldValue.delete() : dose,
      // Only stamp a start date the first time this medication is added -
      // editing the dose on an already-active medication shouldn't reset
      // the comparison date used by Patterns > Interventions.
      if (dose != null && !hadStartDate)
        'medicationStartedAt.$medicationId': DateTime.now(),
      if (dose == null) 'medicationStartedAt.$medicationId': FieldValue.delete(),
    });
  }

  Future<void> _setDietType(String dietId, bool selected) async {
    if (currentUserReference == null) return;
    await currentUserReference!.update({
      'dietTypeKeys': selected
          ? FieldValue.arrayUnion([dietId])
          : FieldValue.arrayRemove([dietId]),
      if (selected) 'dietStartedAt.$dietId': DateTime.now(),
      if (!selected) 'dietStartedAt.$dietId': FieldValue.delete(),
    });
  }

  Future<void> _setMedicationStartDate(
      String medicationId, DateTime date) async {
    if (currentUserReference == null) return;
    await currentUserReference!.update({
      'medicationStartedAt.$medicationId': date,
    });
  }

  Future<void> _setDietStartDate(String dietId, DateTime date) async {
    if (currentUserReference == null) return;
    await currentUserReference!.update({
      'dietStartedAt.$dietId': date,
    });
  }

  Future<void> _pickStartDate(
    BuildContext context,
    DateTime? current,
    ValueChanged<DateTime> onPicked,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _pickDose(
    BuildContext context,
    MedicationsRecord medication,
    String? currentDose,
  ) async {
    final theme = FlutterFlowTheme.of(context);
    final controller = TextEditingController(
      text: medication.commonDoses.contains(currentDose) ? '' : currentDose,
    );
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medication.name,
                style: theme.titleSmall
                    .override(fontWeight: FontWeight.w600, color: theme.primaryText),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Choose the dose you take.',
                style: theme.labelSmall.override(
                  font: GoogleFonts.inter(),
                  color: theme.secondaryText,
                ),
              ),
              const SizedBox(height: 16.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  for (final dose in medication.commonDoses)
                    InkWell(
                      onTap: () => Navigator.pop(sheetContext, dose),
                      borderRadius: BorderRadius.circular(20.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: dose == currentDose
                              ? const Color(0xFF123C45)
                              : const Color(0xFF1A2A33),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: dose == currentDose
                                ? theme.primary
                                : Colors.transparent,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          dose,
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: dose == currentDose
                                ? theme.primary
                                : theme.primaryText,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Custom dose',
                  hintText: 'e.g. "75mg"',
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.pop(sheetContext, value.trim());
                  }
                },
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (currentDose != null)
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext, ''),
                      child: Text('Remove',
                          style: TextStyle(color: theme.error)),
                    ),
                  const SizedBox(width: 8.0),
                  FilledButton(
                    onPressed: () {
                      final custom = controller.text.trim();
                      if (custom.isNotEmpty) {
                        Navigator.pop(sheetContext, custom);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    if (chosen.isEmpty) {
      await _setMedicationDose(medication.reference.id, null);
    } else {
      await _setMedicationDose(
        medication.reference.id,
        chosen,
        hadStartDate: currentDose != null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        title: Text(
          'Interventions',
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(
                fontWeight: theme.headlineMedium.fontWeight),
            color: theme.primaryText,
            fontSize: 22.0,
          ),
        ),
        elevation: 0.0,
      ),
      body: SafeArea(
        child: StreamBuilder<UsersRecord>(
          stream: UsersRecord.getDocument(currentUserReference!),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                ),
              );
            }
            final user = userSnapshot.data!;
            final doses = user.medicationDoses;
            final dietKeys = user.dietTypeKeys.toSet();
            final medStartedAt = user.medicationStartedAt;
            final dietStartedAt = user.dietStartedAt;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
              children: [
                Text(
                  'Track the medications and diets you\'re using so they can '
                  'later be lined up against your symptom patterns.',
                  style: theme.bodySmall.override(
                    font: GoogleFonts.inter(),
                    color: theme.secondaryText,
                  ),
                ),
                const SizedBox(height: 24.0),
                _sectionHeader(context, 'Medication'),
                const SizedBox(height: 8.0),
                StreamBuilder<List<MedicationsRecord>>(
                  stream: queryMedicationsRecord(
                    queryBuilder: (m) => m.where('isActive', isEqualTo: true),
                  ),
                  builder: (context, medsSnapshot) {
                    if (!medsSnapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final meds = medsSnapshot.data!.toList()
                      ..sort((a, b) => a.order.compareTo(b.order));
                    return Column(
                      children: meds
                          .map((med) => _medicationTile(
                                context,
                                med,
                                doses[med.reference.id],
                                medStartedAt[med.reference.id],
                              ))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 24.0),
                _sectionHeader(context, 'Diet'),
                const SizedBox(height: 8.0),
                StreamBuilder<List<DietTypesRecord>>(
                  stream: queryDietTypesRecord(
                    queryBuilder: (d) => d.where('isActive', isEqualTo: true),
                  ),
                  builder: (context, dietsSnapshot) {
                    if (!dietsSnapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final diets = dietsSnapshot.data!.toList()
                      ..sort((a, b) => a.order.compareTo(b.order));
                    return Column(
                      children: diets
                          .map((diet) => _dietTile(
                                context,
                                diet,
                                dietKeys.contains(diet.reference.id),
                                dietStartedAt[diet.reference.id],
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Text(
      label,
      style: FlutterFlowTheme.of(context).titleSmall.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: FlutterFlowTheme.of(context).primaryText,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _medicationTile(
    BuildContext context,
    MedicationsRecord medication,
    String? currentDose,
    DateTime? startedAt,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final isOn = currentDose != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: theme.bodyMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        color: theme.primaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      medication.category,
                      style: theme.labelSmall.override(
                        font: GoogleFonts.inter(),
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _pickDose(context, medication, currentDose),
                borderRadius: BorderRadius.circular(20.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isOn ? const Color(0xFF123C45) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: isOn ? theme.primary : theme.alternate,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOn ? Icons.check_circle : Icons.add_circle_outline,
                        size: 15.0,
                        color: isOn ? theme.primary : theme.secondaryText,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        isOn ? currentDose : 'Add',
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: isOn ? theme.primary : theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 8.0),
            _startDateRow(
              context,
              startedAt,
              () => _pickStartDate(
                context,
                startedAt,
                (date) =>
                    _setMedicationStartDate(medication.reference.id, date),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // "Started [date]" row with an edit affordance - shown only for active
  // (dose-set / diet-on) items, right under the name. This date is what
  // Patterns > Interventions uses to split before/after, so it needs to be
  // directly editable here rather than just auto-stamped to "today".
  Widget _startDateRow(
    BuildContext context,
    DateTime? startedAt,
    VoidCallback onEdit,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final label = startedAt == null
        ? 'Set a start date'
        : 'Started ${dateTimeFormat('MMM d, y', startedAt)}';
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(6.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_outlined, size: 13.0, color: theme.secondaryText),
          const SizedBox(width: 4.0),
          Text(
            label,
            style: theme.labelSmall.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w600),
              color: theme.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4.0),
          Icon(Icons.edit_outlined, size: 12.0, color: theme.secondaryText),
        ],
      ),
    );
  }

  Widget _dietTile(
    BuildContext context,
    DietTypesRecord diet,
    bool isOn,
    DateTime? startedAt,
  ) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diet.name,
                      style: theme.bodyMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        color: theme.primaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      diet.description,
                      style: theme.labelSmall.override(
                        font: GoogleFonts.inter(),
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isOn,
                activeThumbColor: theme.primary,
                onChanged: (value) => _setDietType(diet.reference.id, value),
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 4.0),
            _startDateRow(
              context,
              startedAt,
              () => _pickStartDate(
                context,
                startedAt,
                (date) => _setDietStartDate(diet.reference.id, date),
              ),
            ),
            const SizedBox(height: 8.0),
          ],
        ],
      ),
    );
  }
}
