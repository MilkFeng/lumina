import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/features/external_sources/application/external_sources_notifier.dart';
import 'package:lumina/src/features/external_sources/domain/external_source.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_config.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_type.dart';
import 'package:lumina/src/features/external_sources/presentation/external_source_localizations.dart';
import 'package:lumina/src/features/external_sources/presentation/widgets/type_selector_field.dart';

/// What the editor should open on.
sealed class ExternalSourceEditorRequest {
  const ExternalSourceEditorRequest();
}

/// Create a new source, pre-filled with [initialName].
class NewExternalSource extends ExternalSourceEditorRequest {
  const NewExternalSource({required this.initialName, required this.type});

  final String initialName;
  final ExternalSourceType type;
}

/// Edit an existing [source].
class EditExternalSource extends ExternalSourceEditorRequest {
  const EditExternalSource(this.source);

  final ExternalSource source;
}

/// Create-or-edit dialog for one external source.
///
/// One dialog for both, because the two flows differ only in where the initial
/// values come from. Everything type-specific is driven by
/// [ExternalSourceConfig.fields]: the dialog renders whatever a source type
/// declares, so adding a type never touches this file.
class ExternalSourceEditorDialog extends ConsumerStatefulWidget {
  const ExternalSourceEditorDialog._({
    required this.request,
    required this.initialDraft,
  });

  final ExternalSourceEditorRequest request;
  final ExternalSourceConfigDraft initialDraft;

  /// Loads the configuration before opening the dialog and returns the saved
  /// source, or `null` when cancelled or the configuration could not be loaded.
  static Future<ExternalSource?> show(
    BuildContext context,
    ExternalSourceEditorRequest request,
  ) async {
    final notifier = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(externalSourcesProvider.notifier);
    final ExternalSourceConfigDraft draft;
    try {
      draft = switch (request) {
        NewExternalSource(:final type) => notifier.emptyDraft(type),
        EditExternalSource(:final source) => await notifier.draftFor(source),
      };
    } catch (_) {
      // Reading the keychain can fail on a device with a locked or reset
      // keystore. Report the failure before opening an unusable editor.
      if (!context.mounted) return null;
      ToastService.showError(
        AppLocalizations.of(context)!.externalSourceConfigurationLoadFailed,
      );
      return null;
    }
    if (!context.mounted) return null;

    return showDialog<ExternalSource>(
      context: context,
      builder: (context) =>
          ExternalSourceEditorDialog._(request: request, initialDraft: draft),
    );
  }

  @override
  ConsumerState<ExternalSourceEditorDialog> createState() =>
      _ExternalSourceEditorDialogState();
}

class _ExternalSourceEditorDialogState
    extends ConsumerState<ExternalSourceEditorDialog> {
  /// Side margin kept clear between the dialog and the screen edge.
  ///
  /// Half of what [AlertDialog] insets by default: the form is six full-width
  /// inputs, so on a phone the default margin spends a fifth of the width on
  /// empty space beside them.
  static const double _screenMargin = 20;

  /// Widest the input column grows.
  ///
  /// [AlertDialog] pads its content by 24 on each side, so this puts the frame a
  /// little under 560 wide on a large window — about as wide as a single-column
  /// form stays comfortable to read across, and a size the form could not reach
  /// while it was pinned to a fixed 360-wide box.
  static const double _maxFormWidth = 512;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  /// One controller per field key, rebuilt whenever the type changes.
  final Map<String, TextEditingController> _controllers = {};

  late ExternalSourceType _type;
  late ExternalSourceConfigDraft _draft;

  bool _busy = false;
  bool _nameTaken = false;

  /// Guards against an out-of-order duplicate-name answer overwriting a newer
  /// one while the user is still typing.
  int _nameCheckToken = 0;

  ExternalSource? get _editing => switch (widget.request) {
    EditExternalSource(:final source) => source,
    NewExternalSource() => null,
  };

  @override
  void initState() {
    super.initState();
    _type = switch (widget.request) {
      NewExternalSource(:final type) => type,
      // A row whose type this build does not know cannot be edited through any
      // form; falling back to the first supported type at least opens a usable
      // dialog instead of failing on a stale row.
      EditExternalSource(:final source) =>
        externalSourceTypeOf(source) ?? ExternalSourceType.values.first,
    };
    switch (widget.request) {
      case NewExternalSource(:final initialName):
        _nameController.text = initialName;
      case EditExternalSource(:final source):
        _nameController.text = source.name;
    }
    _nameController.addListener(_onNameChanged);
    _draft = widget.initialDraft;
    _rebuildControllers(_draft);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onNameChanged() {
    final token = ++_nameCheckToken;
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _nameTaken = false);
      // Re-runs the validator so an "already in use" error clears as soon as
      // the field is emptied, instead of lingering next to "required".
      _formKey.currentState?.validate();
      return;
    }

    // The answer arrives after the field's own validation pass, so the token
    // guards against a stale answer; `isNameAvailable` is advisory either way,
    // and the notifier re-checks on save.
    unawaited(() async {
      final available = await ref
          .read(externalSourcesProvider.notifier)
          .isNameAvailable(name, excludingId: _editing?.id);
      if (!mounted || token != _nameCheckToken) return;
      setState(() => _nameTaken = !available);
    }());
  }

  /// Rebuilds the per-field controllers for [draft], preserving any text the
  /// user already typed for fields that survived a type change.
  void _rebuildControllers(ExternalSourceConfigDraft draft) {
    final previous = Map<String, String>.fromEntries(
      _controllers.entries.map(
        (entry) => MapEntry(entry.key, entry.value.text),
      ),
    );

    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    for (final field in draft.fields) {
      _controllers[field.key] = TextEditingController(
        text: previous[field.key] ?? field.value,
      );
    }
  }

  /// Turns the controllers back into a draft.
  ExternalSourceConfigDraft _currentDraft() {
    var draft = _draft;
    for (final entry in _controllers.entries) {
      draft = draft.copyWithField(entry.key, entry.value.text);
    }
    return draft;
  }

  void _onTypeChanged(ExternalSourceType type) {
    if (type == _type) return;
    final notifier = ref.read(externalSourcesProvider.notifier);
    final draft = notifier.emptyDraft(type);
    setState(() {
      _type = type;
      // A different type means different fields; carrying text across would
      // only produce nonsense (a WebDAV host inside a field another protocol
      // reads as a bucket name).
      _rebuildControllers(draft);
      _draft = draft;
    });
  }

  /// Handles the OK action: validate, test, then save.
  ///
  /// The test runs first on purpose — saving a source that cannot be reached
  /// would leave the home screen with an import entry that fails when used.
  Future<void> _confirm() async {
    final draft = _currentDraft();
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _formKey.currentState?.validate();
      return;
    }
    if (_nameTaken) return;
    if (!draft.isComplete) {
      // Surfaces the required-field errors the fields raise on validation.
      _formKey.currentState?.validate();
      return;
    }

    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(externalSourcesProvider.notifier);

    try {
      final failure = await notifier.testDraft(draft);
      if (!mounted) return;

      if (failure != null) {
        ToastService.showError(l10n.externalSourceFailureMessage(failure));
        return;
      }

      final source = _editing;
      final result = source == null
          ? await notifier.add(name: name, draft: draft)
          : await notifier.saveChanges(
              source: source,
              name: name,
              draft: draft,
            );
      if (!mounted) return;

      result.match(
        (error) =>
            ToastService.showError(l10n.externalSourceFailureMessage(error)),
        (saved) {
          Navigator.of(context).pop(saved);
          ToastService.showSuccess(
            source == null
                ? l10n.externalSourceAdded(saved.name)
                : l10n.externalSourceUpdated(saved.name),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final draft = _draft;

    return AlertDialog(
      // Less side inset than the default, so the form gets the width a phone
      // has to give; the cap below keeps it from stretching on a wide window.
      insetPadding: const EdgeInsets.symmetric(
        horizontal: _screenMargin,
        vertical: 24,
      ),
      title: Text(
        _editing == null ? l10n.addExternalSource : l10n.externalSourceEdit,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxFormWidth),
        // `double.maxFinite` hands the width decision to the dialog rather than
        // to the widest thing inside it, so the form fills the room the screen
        // and the cap above leave, instead of the fixed phone-sized box it used
        // to sit in.
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Every input is disabled while the connection test runs:
                  // the values being tested are the ones on screen, so editing
                  // them mid-test would make the result describe something the
                  // user can no longer see.
                  _buildNameField(l10n),
                  const SizedBox(height: 12),
                  _buildTypeField(l10n),
                  const SizedBox(height: 20),
                  Text(
                    l10n.externalSourceConfiguration,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildConfigFields(context, draft, l10n),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        // The progress lives inside the confirm button rather than replacing
        // the actions row, so the dialog does not change shape mid-test.
        FilledButton(
          onPressed: _busy ? null : _confirm,
          child: _busy
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.externalSourceTesting),
                  ],
                )
              : Text(l10n.confirm),
        ),
      ],
    );
  }

  Widget _buildNameField(AppLocalizations l10n) {
    return TextFormField(
      controller: _nameController,
      // Deliberately not focused on open: both entry points already supply a
      // usable name (the suggested one when creating, the stored one when
      // editing), so raising the keyboard would cover most of the form to
      // invite an edit the user usually does not need to make.
      enabled: !_busy,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: l10n.externalSourceName,
        isDense: true,
        errorText: _nameTaken ? l10n.externalSourceNameDuplicate : null,
      ),
      validator: (value) {
        final name = value?.trim() ?? '';
        if (name.isEmpty) return l10n.externalSourceNameRequired;
        if (_nameTaken) return l10n.externalSourceNameDuplicate;
        return null;
      },
    );
  }

  Widget _buildTypeField(AppLocalizations l10n) {
    final types = ref.watch(externalSourceRegistryProvider).supportedTypes;
    // The type is chosen from a short list, so it is rendered as a selector
    // field rather than a dropdown: a dropdown menu is drawn over the field it
    // belongs to (see [TypeSelectorField]), which hides the field and its
    // label at the moment the user is reading them.
    return TypeSelectorField<ExternalSourceType>(
      value: _type,
      labelText: l10n.externalSourceType,
      // A disabled field is how the rest of the form reports the running
      // connection test; the selector greys out and stops opening with it.
      enabled: !_busy,
      items: [
        for (final type in types)
          TypeSelectorItem(
            value: type,
            label: l10n.externalSourceTypeName(type),
          ),
      ],
      onChanged: _onTypeChanged,
    );
  }

  /// Builds one input per field the draft declares.
  ///
  /// Secret fields are declared among the others, so the form stays the same
  /// shape whoever declares them; only the input type differs.
  List<Widget> _buildConfigFields(
    BuildContext context,
    ExternalSourceConfigDraft draft,
    AppLocalizations l10n,
  ) {
    return [
      for (final field in draft.fields)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: _controllers[field.key],
            enabled: !_busy,
            keyboardType: switch (field.type) {
              ExternalSourceFieldType.url => TextInputType.url,
              _ => TextInputType.text,
            },
            obscureText: field.type == ExternalSourceFieldType.password,
            autocorrect: false,
            enableSuggestions: field.type != ExternalSourceFieldType.password,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.externalSourceFieldLabel(field.labelKey),
              hintText: l10n.externalSourceFieldHint(field.hint),
              isDense: true,
            ),
            validator: (value) {
              if (!field.required) return null;
              return (value?.trim().isEmpty ?? true)
                  ? l10n.externalSourceRequiredField
                  : null;
            },
          ),
        ),
    ];
  }
}
