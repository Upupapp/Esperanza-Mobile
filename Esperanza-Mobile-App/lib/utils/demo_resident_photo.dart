import 'package:flutter/widgets.dart';
import '../models/citizen_account.dart';

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

/// The portrait to show for [account], or null for every other account
/// (which should keep showing its initials, exactly as before).
ImageProvider? demoProfileImageFor(CitizenAccount? account) {
  if (account == null) return null;
  final asset = _profilePhotoAssetByAccountId[account.id];
  return asset == null ? null : AssetImage(asset);
}
