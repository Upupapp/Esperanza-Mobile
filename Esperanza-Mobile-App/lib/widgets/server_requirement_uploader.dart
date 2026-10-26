import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attachment.dart';
import '../models/master_file_document.dart';
import '../models/service_request.dart';
import '../services/citizen_session_service.dart';
import '../services/master_file_service.dart';
import '../utils/requirement_document_type.dart';
import 'requirement_uploader.dart';

/// The uploader for a requirement whose document the server keeps: a flagged
/// one being replaced, or a pending one being attached. Wired to
/// [MasterFileService] the same way the submission-time uploaders are, so
/// "Use Existing Document" works here too. There is no Remove: the server
/// keeps a requirement's file, which can only be replaced. With
/// [allowPapeles], "From My Papeles" offers any server-held document.
class ServerRequirementUploader extends StatelessWidget {
  final String label;
  final Attachment? current;
  final Color accent;
  final bool busy;
  final String serviceName;
  final ServiceCategory category;
  final ValueChanged<Attachment> onPicked;
  final bool showTitle;

  /// True where the server attaches (a new request's documents, or a pending
  /// requirement): a document in the resident's Papeles can then be used by
  /// reference, as on the web portal, even when its file is not on this
  /// phone. False for a replacement, which the server takes only as a file.
  final bool allowPapeles;

  const ServerRequirementUploader({
    super.key,
    required this.label,
    this.showTitle = true,
    required this.current,
    required this.accent,
    required this.busy,
    required this.serviceName,
    required this.category,
    required this.onPicked,
    this.allowPapeles = false,
  });

  @override
  Widget build(BuildContext context) {
    final requirement = RequirementInfo(label: label, documentType: documentTypeFor(label), isRequired: true);
    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: IgnorePointer(
        ignoring: busy,
        child: Consumer<MasterFileService>(
          builder: (context, masterFile, _) {
            final accountId = context.read<CitizenSessionService>().account?.id;
            // A replacement uploads bytes, so there reuse needs the file on
            // this device. An attach can instead name the Papeles document
            // (`papeles_id`), which needs no copy here.
            final found = accountId != null ? masterFile.findByType(accountId, requirement.documentType) : null;
            final foundRemoteId = found == null || !allowPapeles ? null : MasterFileService.remoteIdOf(found);
            final existing = (found?.attachment.localPath?.isNotEmpty ?? false) || foundRemoteId != null ? found : null;
            final choices = allowPapeles && accountId != null
                ? masterFile.serverDocumentsFor(accountId)
                : const <MasterFileDocument>[];
            return RequirementUploader(
              requirement: requirement,
              showTitle: showTitle,
              attachment: current,
              accent: accent,
              existingMasterDoc: existing,
              papelesChoices: choices,
              onUsePapeles: allowPapeles
                  ? (doc) => onPicked(
                      attachmentForReuse(
                        doc.attachment,
                        requirementLabel: requirement.label,
                        papelesId: MasterFileService.remoteIdOf(doc),
                      ),
                    )
                  : null,
              // The file goes with this request only, as on the website: it
              // used to be copied into the resident's Papeles without asking
              // (parity check, 2026-10-23). Papeles takes what they add there.
              onAttachNew: onPicked,
              onUseExisting: () {
                if (existing != null) {
                  onPicked(
                    attachmentForReuse(existing.attachment, requirementLabel: requirement.label, papelesId: foundRemoteId),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
