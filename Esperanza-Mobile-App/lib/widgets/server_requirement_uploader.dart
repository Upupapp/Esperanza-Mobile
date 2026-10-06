import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attachment.dart';
import '../models/service_request.dart';
import '../services/citizen_session_service.dart';
import '../services/master_file_service.dart';
import '../utils/requirement_document_type.dart';
import 'requirement_uploader.dart';

/// The uploader for a requirement whose document the server keeps: a flagged
/// one being replaced, or a pending one being attached. Wired to
/// [MasterFileService] the same way the submission-time uploaders are, so
/// "Use Existing Document" works here too. There is no Remove: the server
/// keeps a requirement's file, which can only be replaced.
class ServerRequirementUploader extends StatelessWidget {
  final String label;
  final Attachment? current;
  final Color accent;
  final bool busy;
  final String serviceName;
  final ServiceCategory category;
  final ValueChanged<Attachment> onPicked;
  final bool showTitle;

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
            // Reuse needs the file on this device: the endpoint uploads bytes,
            // and a server-only Papeles copy has none here.
            final found = accountId != null ? masterFile.findByType(accountId, requirement.documentType) : null;
            final existing = (found?.attachment.localPath?.isNotEmpty ?? false) ? found : null;
            return RequirementUploader(
              requirement: requirement,
              showTitle: showTitle,
              attachment: current,
              accent: accent,
              existingMasterDoc: existing,
              onAttachNew: (a) {
                onPicked(a);
                if (accountId != null) {
                  masterFile.saveOrUpdate(
                    accountId: accountId,
                    documentType: requirement.documentType,
                    label: requirement.label,
                    attachment: a,
                    origin: category == ServiceCategory.dokyu ? 'Dokyu' : 'Tulong',
                    serviceName: serviceName,
                  );
                }
              },
              onUseExisting: () {
                if (existing != null) {
                  onPicked(attachmentForReuse(existing.attachment, requirementLabel: requirement.label));
                }
              },
            );
          },
        ),
      ),
    );
  }
}
