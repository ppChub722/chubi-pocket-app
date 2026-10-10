import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/contact.dart';

/// The one "linked to an app account" mark (owner 2026-10-11) — the kit's
/// [PersonLinkBadge]. On avatars it comes with [ContactAvatar]; headers
/// also show [ContactLinkedPill].
class ContactLinkedIcon extends StatelessWidget {
  const ContactLinkedIcon({super.key});

  @override
  Widget build(BuildContext context) => const PersonLinkBadge();
}

/// A contact's avatar as the kit [PersonMark] — its own icon, or (linked)
/// the user's icon then the 🔗: "(ม)🔗 มาตาก". Row avatars; the only 🔗 on
/// the row (owner 2026-10-11). [reserveLinkSlot] (on: it's for lists)
/// keeps unlinked rows' names in line with linked ones.
class ContactAvatar extends StatelessWidget {
  const ContactAvatar({
    required this.contact,
    this.size = 40,
    this.reserveLinkSlot = true,
    super.key,
  });

  final Contact contact;
  final double size;
  final bool reserveLinkSlot;

  @override
  Widget build(BuildContext context) => PersonMark(
    name: contact.effectiveName,
    level: contact.isLinked ? PersonLevel.linked : PersonLevel.contact,
    iconCode: contact.effectiveIconCode,
    size: size,
    reserveLinkSlot: reserveLinkSlot,
  );
}

/// "🔗 ผูกแล้ว" — [ContactLinkedIcon] as a primary label pill, for a
/// contact's header.
class ContactLinkedPill extends StatelessWidget {
  const ContactLinkedPill({this.size = PillSize.normal, super.key});

  final PillSize size;

  @override
  Widget build(BuildContext context) => LabelPill(
    label: AppLocalizations.of(context)!.contactLinked,
    icon: AppIcons.link,
    tone: Tone.primary,
    size: size,
  );
}
