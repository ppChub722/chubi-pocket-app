import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../data/contacts_repository.dart';
import '../../domain/contact.dart';
import '../cubit/contacts_cubit.dart';

class ContactFormPage extends StatefulWidget {
  const ContactFormPage({
    required this.linkRequestId,
    this.editingId,
    this.lockedDisplayName,
    this.lockedEmail,
    super.key,
  });

  final String? editingId;

  final String linkRequestId;

  final String? lockedDisplayName;
  final String? lockedEmail;

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _description = TextEditingController();
  final _note = TextEditingController();

  bool _loading = false;

  Contact? _existing;

  bool get _isLinkExisting => widget.editingId != null;
  bool get _isLinkCreate => !_isLinkExisting;

  @override
  void initState() {
    super.initState();
    if (_isLinkExisting) {
      _loadExisting();
    } else {
      _name.text = widget.lockedDisplayName ?? '';
      _email.text = widget.lockedEmail ?? '';
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final c = (await context.read<ContactsRepository>().get(
        widget.editingId!,
      )).contact;
      if (!mounted) return;
      _existing = c;
      _name.text = c.name;
      _email.text = c.email ?? '';
      _phone.text = c.phone ?? '';
      _description.text = c.description ?? '';
      _note.text = c.note ?? '';
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.contactNameRequired,
        tone: Tone.danger,
      );
      return;
    }
    final cubit = context.read<ContactsCubit>();
    setState(() => _loading = true);
    final phone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
    final description = _description.text.trim().isEmpty
        ? null
        : _description.text.trim();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    try {
      if (_isLinkExisting) {
        await cubit.linkExistingFromRequest(
          widget.linkRequestId,
          widget.editingId!,
          phone: phone,
          description: description,
          note: note,
        );
        if (!mounted) return;
        context.pushReplacement('/contacts/${widget.editingId!}');
      } else {
        final res = await cubit.createLinkedFromRequest(
          widget.linkRequestId,
          phone: phone,
          description: description,
          note: note,
        );
        if (!mounted) return;
        final id = res.contact?.id;
        if (id != null) context.pushReplacement('/contacts/$id');
      }
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = _isLinkCreate
        ? l.contactLinkCreateTitle
        : l.contactLinkExistingTitle;
    final lockedHelper = l.contactLinkedLockedHint;
    final loadingExisting = _loading && _isLinkExisting && _existing == null;
    final name = _name.text;
    final name2 = name.isEmpty ? '…' : name;
    return Scaffold(
      appBar: AppTopBar(title: title, showBack: true, editing: true),
      extendBodyBehindAppBar: true,
      body: Builder(
        builder: (context) {
          final top = MediaQuery.paddingOf(context).top;
          // First load (linking an existing contact): the template's detail
          // skeleton, never a spinner; it clears the floating bar itself.
          if (loadingExisting) return const DetailPageSkeleton();
          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              top + AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              AppMessage(
                tone: Tone.info,
                message: _isLinkExisting
                    ? l.contactLinkBannerExisting(name2)
                    : l.contactLinkBannerNew(name2),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                first: true,
                children: [
                  AppDetailRow(
                    label: l.commonName,
                    locked: true,
                    helper: lockedHelper,
                    trailing: AppText(name),
                  ),
                  DetailStacked(
                    label: l.commonDescription,
                    child: AppInput.inline(
                      editing: true,
                      controller: _description,
                      hint: l.contactDescriptionHint,
                      maxLines: 3,
                      maxLength: TextLimits.description,
                    ),
                  ),
                  AppDetailRow(
                    label: l.contactEmailLabel,
                    locked: true,
                    helper: lockedHelper,
                    trailing: _email.text.isEmpty
                        ? DetailPlaceholder(l.contactFieldNotSet)
                        : AppText(_email.text),
                  ),
                  DetailStacked(
                    label: l.contactPhoneLabel,
                    child: AppInput.inline(
                      editing: true,
                      controller: _phone,
                      maxLength: TextLimits.phone,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  DetailStacked(
                    label: l.commonNote,
                    child: AppInput.inline(
                      editing: true,
                      controller: _note,
                      hint: l.contactNoteHint,
                      maxLines: 3,
                      maxLength: TextLimits.note,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: loadingExisting
          ? null
          : ModeActionBar(
              canSave: !_loading,
              saving: _loading,
              cancelLabel: l.commonCancel,
              saveLabel: l.contactLinkSave,
              onCancel: () => Navigator.of(context).maybePop(),
              onSave: _submit,
            ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _description.dispose();
    _note.dispose();
    super.dispose();
  }
}
