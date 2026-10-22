import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_dialogs.dart';

import '../l10n/tr.dart';
/// The kind of protected device resource an action needs — drives which
/// explanation copy/permission this goes through. Every screen in the app
/// that touches the camera, photo library, or a document picker routes
/// through the two functions below ([pickImageProtected] /
/// [pickDocumentProtected]) rather than calling `image_picker`/
/// `file_picker` directly, so this one file is the only place permission
/// logic lives — never duplicated per screen.
enum ProtectedResource { camera, photos, document }

class _ResourceCopy {
  final String title;
  final String explanation;
  final String deniedMessage;
  const _ResourceCopy({required this.title, required this.explanation, required this.deniedMessage});
}

const _copy = <ProtectedResource, _ResourceCopy>{
  ProtectedResource.camera: _ResourceCopy(
    title: 'Camera Access Required',
    explanation: 'Esperanza needs access to your camera so you can take a photo and attach it to your request.',
    deniedMessage: 'Permission was not granted. You can continue using the app, but this feature requires access to your camera.',
  ),
  ProtectedResource.photos: _ResourceCopy(
    title: 'Photo Access Required',
    explanation: 'Esperanza needs access to your photos so you can select an image to attach to your request.',
    deniedMessage: 'Permission was not granted. You can continue using the app, but this feature requires access to your photos.',
  ),
  ProtectedResource.document: _ResourceCopy(
    title: 'Document Access',
    explanation: 'Esperanza needs permission to let you choose a document to attach to your request.',
    deniedMessage: 'Permission was not granted. You can continue using the app, but this feature requires access to choose a document.',
  ),
};

/// Explanation dialogs are only ever shown in direct response to the
/// citizen tapping a specific protected action (Take a photo / Choose from
/// gallery / Choose a document) — never at startup, splash, onboarding, or
/// merely opening a tab/form. Acknowledged once per resource on this phone:
/// a Continue is remembered (shared_preferences), so the same explanation is
/// not shown again on every app start (QA run 2026-10-04: Document Access
/// came up on every pick). The in-memory Set answers without a disk read.
final Set<ProtectedResource> _acknowledgedThisSession = {};

const _ackPrefix = 'protected_action_ack.';

Future<bool> _acknowledged(ProtectedResource resource) async {
  if (_acknowledgedThisSession.contains(resource)) return true;
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('$_ackPrefix${resource.name}') ?? false) {
      _acknowledgedThisSession.add(resource);
      return true;
    }
  } catch (_) {
    // No storage (a test without a mock): ask, as before.
  }
  return false;
}

Future<void> _remember(ProtectedResource resource) async {
  _acknowledgedThisSession.add(resource);
  try {
    await (await SharedPreferences.getInstance()).setBool('$_ackPrefix${resource.name}', true);
  } catch (_) {
    // Remembered for this session only.
  }
}

/// Shows the Esperanza-styled explanation dialog (Not Now / Continue) for
/// [resource], skipping it if already acknowledged. [explanation] replaces
/// the generic "attach it to your request" copy where the purpose differs
/// (a selfie to verify the account, a profile photo). Returns true only if
/// the citizen tapped Continue.
Future<bool> _confirmExplanation(BuildContext context, ProtectedResource resource, {String? explanation}) async {
  if (await _acknowledged(resource)) return true;
  if (!context.mounted) return false;
  final copy = _copy[resource]!;
  final proceed = await AppDialogs.confirm(
    context,
    title: copy.title,
    message: explanation ?? copy.explanation,
    cancelLabel: 'Not Now',
    confirmLabel: tr('Continue'),
  );
  if (proceed) await _remember(resource);
  return proceed;
}

Future<void> _showPermanentlyDeniedDialog(BuildContext context) async {
  final openSettings = await AppDialogs.confirm(
    context,
    title: 'Permission Required',
    message: 'This permission is currently disabled. You can enable it from your device settings.',
    cancelLabel: 'Not Now',
    confirmLabel: 'Open Settings',
  );
  if (openSettings) await openAppSettings();
}

Future<void> _showDeniedDialog(BuildContext context, ProtectedResource resource) {
  return AppDialogs.info(context, title: _copy[resource]!.title, message: _copy[resource]!.deniedMessage);
}

/// Camera or gallery, gated by the explanation dialog and (native
/// platforms only) the actual runtime permission. Returns the picked
/// file, or null if the citizen declined the explanation, cancelled the
/// picker, or the permission wasn't available.
///
/// Deliberately does *not* force a `Permission.request()` call up front on
/// every attempt — `image_picker` already manages the native prompt
/// itself where one is actually required (and, on Android 13+ gallery
/// picks in particular, the OS Photo Picker needs no runtime permission
/// grant at all — forcing one anyway would be exactly the "broad/
/// unrestricted access" this must avoid). `permission_handler` is used
/// only to (a) short-circuit straight to the "permanently denied ->
/// Open Settings" dialog when that's already the known state, so the
/// picker isn't attempted only to silently fail, and (b) after a null
/// result, distinguish "the citizen just cancelled the picker" (do
/// nothing, exactly like today) from "the permission was actually denied"
/// (show the friendly denied message).
///
/// [maxDimension] caps the longer side in pixels. The profile photo passes
/// 1024: it is shown at 192pt at most and is kept on the phone, where a
/// full-size camera shot (several MB) could exceed what the store holds.
///
/// [preferredCamera] is the camera to open with [ImageSource.camera]: the
/// rear one unless a caller asks otherwise, as the registration selfie does
/// (Esperanza QA, 2026-10-07: residents had to flip the camera to take a
/// selfie). The platform treats it as a request, not a guarantee.
Future<XFile?> pickImageProtected(
  BuildContext context, {
  required ImageSource source,
  double? maxDimension,
  String? explanation,
  CameraDevice preferredCamera = CameraDevice.rear,
}) async {
  final resource = source == ImageSource.camera ? ProtectedResource.camera : ProtectedResource.photos;
  if (!await _confirmExplanation(context, resource, explanation: explanation)) return null;
  if (!context.mounted) return null;

  // Flutter Web has no native runtime permission model to query — the
  // browser handles its own camera/file-access prompts as part of the
  // picker call itself, so permission_handler is skipped entirely here.
  if (kIsWeb) {
    return ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      preferredCameraDevice: preferredCamera,
    );
  }

  final permission = source == ImageSource.camera ? Permission.camera : Permission.photos;
  final preStatus = await permission.status;
  if (preStatus.isPermanentlyDenied) {
    if (context.mounted) await _showPermanentlyDeniedDialog(context);
    return null;
  }

  final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      preferredCameraDevice: preferredCamera,
    );
  if (file != null) return file;
  if (!context.mounted) return null;

  final postStatus = await permission.status;
  if (postStatus.isPermanentlyDenied) {
    if (context.mounted) await _showPermanentlyDeniedDialog(context);
  } else if (postStatus.isDenied) {
    if (context.mounted) await _showDeniedDialog(context, resource);
  }
  // Otherwise the permission is fine and the citizen simply cancelled the
  // picker — return to the form without any error, exactly as before.
  return null;
}

/// Document/PDF/DOCX picker, gated only by the explanation dialog — the
/// OS's own secure document picker (Storage Access Framework on Android,
/// UIDocumentPickerViewController on iOS, a native `<input type=file>` on
/// Web) grants access to just the file the citizen chooses without ever
/// needing a broad filesystem/storage permission, so there is nothing for
/// permission_handler to check here at all.
Future<FilePickerResult?> pickDocumentProtected(
  BuildContext context, {
  required List<String> allowedExtensions,
  bool withData = true,
  String? explanation,
}) async {
  if (!await _confirmExplanation(context, ProtectedResource.document, explanation: explanation)) return null;
  if (!context.mounted) return null;
  return FilePicker.pickFiles(type: FileType.custom, allowedExtensions: allowedExtensions, withData: withData);
}
