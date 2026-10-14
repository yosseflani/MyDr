import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/family_relation_label.dart';
import 'package:mydr/features/family/widgets/birth_date_field.dart';
import 'package:mydr/features/family/widgets/member_not_found_view.dart';
import 'package:mydr/features/family/widgets/string_list_field.dart';

/// Form for adding a family member, or editing one when [memberId] is set.
///
/// Saves through the shared [FamilyController]; the list and profile update
/// automatically because they listen to it.
class MemberFormScreen extends StatefulWidget {
  const MemberFormScreen({super.key, this.memberId});

  /// The member to edit, or null to add a new one.
  final String? memberId;

  static const int maxNameLength = 50;
  static const int maxNotesLength = 500;

  static Route<void> addRoute() =>
      MaterialPageRoute<void>(builder: (_) => const MemberFormScreen());

  static Route<void> editRoute(String memberId) => MaterialPageRoute<void>(
    builder: (_) => MemberFormScreen(memberId: memberId),
  );

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  static const double _maxContentWidth = 600;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  late final FamilyController _controller;

  /// The member being edited, or null when adding or when it was not found.
  FamilyMember? _original;
  bool _isInitialized = false;

  /// Id for a new member, created once so a retry after a failed save
  /// reuses it.
  String? _newMemberId;

  FamilyRelation? _relation;
  DateTime? _birthDate;
  List<String> _allergies = const [];
  List<String> _chronicConditions = const [];

  bool _isSaving = false;

  /// Shown above the save button after a failed save. Inline rather than a
  /// snack bar, so it never covers the button.
  String? _saveError;

  /// Set once the user saved or chose to discard, so leaving is allowed.
  bool _canLeave = false;

  bool get _isEditing => widget.memberId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;

    _controller = AppScope.of(context).familyController;
    final memberId = widget.memberId;
    final original = memberId == null ? null : _controller.memberById(memberId);
    _original = original;
    if (original != null) {
      _nameController.text = original.name;
      _notesController.text = original.notes ?? '';
      _relation = original.relation;
      _birthDate = original.birthDate;
      _allergies = original.allergies;
      _chronicConditions = original.chronicConditions;
    }

    _nameController.addListener(_onTextChanged);
    _notesController.addListener(_onTextChanged);

    // A message left over from the previous screen (e.g. "saved") would
    // cover the save button, so clear it once this screen is shown.
    final messenger = ScaffoldMessenger.maybeOf(context);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => messenger?.removeCurrentSnackBar(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _hasUnsavedChanges {
    final original = _original;
    return _nameController.text.trim() != (original?.name ?? '').trim() ||
        _notesController.text.trim() != (original?.notes ?? '').trim() ||
        _relation != original?.relation ||
        _birthDate != original?.birthDate ||
        !listEquals(_allergies, original?.allergies ?? const []) ||
        !listEquals(
          _chronicConditions,
          original?.chronicConditions ?? const [],
        );
  }

  String? _validateRelation(FamilyRelation? relation) {
    if (relation == null) return AppStrings.relationRequired;
    if (relation == FamilyRelation.self &&
        !_controller.isSelfRelationAvailable(
          excludingMemberId: widget.memberId,
        )) {
      return AppStrings.selfAlreadyExists;
    }
    return null;
  }

  FamilyMember _buildMember() {
    final notes = _notesController.text.trim();
    return FamilyMember(
      id: widget.memberId ?? (_newMemberId ??= _controller.createId()),
      name: _nameController.text.trim(),
      relation: _relation!,
      birthDate: _birthDate,
      allergies: _allergies,
      chronicConditions: _chronicConditions,
      notes: notes.isEmpty ? null : notes,
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    final member = _buildMember();
    final result = _isEditing
        ? await _controller.update(member)
        : await _controller.add(member);
    if (!mounted) return;

    switch (result) {
      case FamilySaveResult.success:
        setState(() {
          _isSaving = false;
          _canLeave = true;
        });
        // Shown on the screen we return to.
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(AppStrings.saveSucceeded)),
          );
        Navigator.of(context).pop();
      case FamilySaveResult.selfAlreadyExists:
        setState(() {
          _isSaving = false;
          _saveError = AppStrings.selfAlreadyExists;
        });
      case FamilySaveResult.failed:
        setState(() {
          _isSaving = false;
          _saveError = AppStrings.saveFailed;
        });
    }
  }

  Future<void> _confirmLeave() async {
    if (_isSaving) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.discardChangesTitle),
        content: const Text(AppStrings.discardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.discardChanges),
          ),
          FilledButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.keepEditing),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      setState(() => _canLeave = true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMissing = _isEditing && _original == null;
    final canPop = _canLeave || isMissing || !_hasUnsavedChanges;

    return PopScope<void>(
      canPop: canPop && !_isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing
                ? AppStrings.editMemberTitle
                : AppStrings.addFamilyMember,
          ),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: isMissing ? const MemberNotFoundView() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final enabled = !_isSaving;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const DemoDataBanner(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  enabled: enabled,
                  maxLength: MemberFormScreen.maxNameLength,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: AppStrings.nameLabel,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? AppStrings.nameRequired
                      : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<FamilyRelation>(
                  initialValue: _relation,
                  isExpanded: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: AppStrings.relationLabel,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.family_restroom),
                    errorMaxLines: 3,
                  ),
                  items: [
                    for (final relation in FamilyRelation.values)
                      DropdownMenuItem(
                        value: relation,
                        child: Text(relation.label),
                      ),
                  ],
                  onChanged: enabled
                      ? (relation) => setState(() => _relation = relation)
                      : null,
                  validator: _validateRelation,
                ),
                const SizedBox(height: 24),
                BirthDateField(
                  value: _birthDate,
                  enabled: enabled,
                  onChanged: (date) => setState(() => _birthDate = date),
                ),
                const SizedBox(height: 24),
                StringListField(
                  title: AppStrings.allergiesSection,
                  inputLabel: AppStrings.allergyInputLabel,
                  initialItems: _allergies,
                  enabled: enabled,
                  onChanged: (items) => setState(() => _allergies = items),
                ),
                const SizedBox(height: 24),
                StringListField(
                  title: AppStrings.chronicConditionsSection,
                  inputLabel: AppStrings.chronicConditionInputLabel,
                  initialItems: _chronicConditions,
                  enabled: enabled,
                  onChanged: (items) =>
                      setState(() => _chronicConditions = items),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _notesController,
                  enabled: enabled,
                  maxLength: MemberFormScreen.maxNotesLength,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: AppStrings.notesOptionalLabel,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          // Kept outside the scroll view so it stays above the keyboard.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_saveError case final error?) ...[
                    _SaveErrorMessage(message: error),
                    const SizedBox(height: 8),
                  ],
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.save),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveErrorMessage extends StatelessWidget {
  const _SaveErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
