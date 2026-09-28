import 'api_client.dart';
import 'json_read.dart';

/// One notification category and the channels it may also reach the citizen
/// on, as GET/PUT /citizen/notification-preferences returns it
/// (esperanza-backend CitizenPortalController::preferencesOf()).
class NotificationPreference {
  const NotificationPreference({
    required this.category,
    required this.labelEn,
    required this.labelFil,
    required this.inApp,
    required this.sms,
    required this.email,
  });

  /// `dokyu`, `tulong`, `account`, `community`, `events`, `sakuna`
  /// (CitizenPortalController::PREFERENCE_CATEGORIES). The server rejects
  /// any other value, so the list is never built on the device.
  final String category;
  final String labelEn;
  final String? labelFil;

  /// Sent back unchanged because the PUT requires it. The server delivers
  /// in-app notifications whatever this says (NotificationService
  /// ::queueDeliveries()), so the app offers no switch for it.
  final bool inApp;
  final bool sms;
  final bool email;

  NotificationPreference copyWith({bool? sms, bool? email}) => NotificationPreference(
    category: category,
    labelEn: labelEn,
    labelFil: labelFil,
    inApp: inApp,
    sms: sms ?? this.sms,
    email: email ?? this.email,
  );

  Map<String, dynamic> toJson() => {'category': category, 'in_app': inApp, 'sms': sms, 'email': email};

  static NotificationPreference? fromJson(Map<String, dynamic> row) {
    final category = JsonRead.nonEmpty(row['category']);
    if (category == null) return null;
    final label = row['label'];
    final en = label is Map ? JsonRead.nonEmpty(label['en']) : JsonRead.nonEmpty(label);
    return NotificationPreference(
      category: category,
      labelEn: en ?? category,
      labelFil: label is Map ? JsonRead.nonEmpty(label['fil']) : null,
      inApp: JsonRead.boolean(row['in_app']) ?? true,
      sms: JsonRead.boolean(row['sms']) ?? false,
      email: JsonRead.boolean(row['email']) ?? false,
    );
  }
}

class NotificationPreferencesService {
  NotificationPreferencesService._();

  static const _path = '/citizen/notification-preferences';

  static List<NotificationPreference> _parse(ApiResult res) =>
      JsonRead.rows(res.map['preferences'], NotificationPreference.fromJson);

  static Future<List<NotificationPreference>> fetch() async => _parse(await api.get(_path));

  /// Saves one category and returns the server's full list afterwards, so
  /// the screen shows what was stored, not what it asked for.
  static Future<List<NotificationPreference>> save(NotificationPreference preference) async => _parse(
    await api.put(
      _path,
      body: {
        'preferences': [preference.toJson()],
      },
    ),
  );
}
