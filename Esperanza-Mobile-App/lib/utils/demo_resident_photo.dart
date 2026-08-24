import 'dart:convert';
import 'package:flutter/widgets.dart';
import '../models/citizen_account.dart';
import '../models/resident_profile.dart';

/// The one place that knows both "where each demo resident's portrait
/// lives" and "which account ids show it" — every avatar call site asks
/// [demoProfileImageFor] instead of re-deriving either fact itself, so
/// there's only one spot to update if an asset ever moves, and one place
/// to extend when a new seeded resident gets a photo.
const String cristyProfilePhotoAsset = 'assets/images/Cristy Profile.png';
const String ronaldoProfilePhotoAsset = 'assets/images/Ronaldo Bautista.png';
const String theodoroProfilePhotoAsset = 'assets/images/Theodoro Milaflor.png';

/// Every account id that shares a resident's single portrait — the
/// Verified Cristy account and her duplicate registration are the same
/// resident (see MockCatalog.duplicateCristyAccount's own doc comment), and
/// likewise both Teodoro Villaflor duplicate registrations (see
/// MockCatalog.unverifiedDuplicateAccountA/B) are the same resident.
/// Ronaldo has only the one account.
const _profilePhotoAssetByAccountId = {
  'ESP-RES-2024-1044': cristyProfilePhotoAsset,
  'ESP-RES-2024-1044-DUP': cristyProfilePhotoAsset,
  'ESP-RES-2024-1102': ronaldoProfilePhotoAsset,
  'ESP-RES-2026-2101': theodoroProfilePhotoAsset,
  'ESP-RES-2026-2102': theodoroProfilePhotoAsset,
};

/// The seeded portrait to show for [account], or null for every other
/// account (which should keep showing its initials, exactly as before).
ImageProvider? demoProfileImageFor(CitizenAccount? account) {
  if (account == null) return null;
  final asset = _profilePhotoAssetByAccountId[account.id];
  return asset == null ? null : AssetImage(asset);
}

/// Every avatar call site's actual entry point: a citizen's own saved
/// profile photo (set via the camera-icon flow — see
/// ResidentProfileService.updateProfilePhoto) takes priority over the
/// seeded portrait, which itself takes priority over showing initials.
/// [personal] is that account's own `ResidentProfile.personal` (pass null
/// only when no ResidentProfileService lookup applies, e.g. a guest).
ImageProvider? profileImageFor(CitizenAccount? account, Individual? personal) {
  if (account == null) return null;
  final b64 = personal?.photoBytesBase64;
  if (b64 != null && b64.isNotEmpty) {
    try {
      return MemoryImage(base64Decode(b64));
    } catch (_) {
      // Corrupt/undecodable — fall through to the seeded portrait below
      // rather than crash the avatar.
    }
  }
  return demoProfileImageFor(account);
}
