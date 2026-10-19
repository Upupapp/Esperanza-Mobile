import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/balita_media.dart';
import 'api_client.dart';
import 'json_read.dart';

/// Where one photo or video of a post being written stands.
enum BalitaUploadStatus { waiting, uploading, done, failed }

/// One photo or video of a Balita post being written (2026-10-18): picked,
/// then sent in pieces while the resident keeps typing. [media] is what the
/// server made of it; the post names it by id when it is sent.
class BalitaUpload extends ChangeNotifier {
  BalitaUpload({required this.file, required this.kind});

  final XFile file;
  final BalitaMediaKind kind;

  BalitaUploadStatus status = BalitaUploadStatus.waiting;

  /// 0..1.
  double progress = 0;
  String? error;
  BalitaMedia? media;

  /// A photo's own bytes, for its thumbnail.
  Uint8List? previewBytes;
  int? width;
  int? height;
  int? durationMs;

  bool _cancelled = false;
  bool get cancelled => _cancelled;
  bool get busy => status == BalitaUploadStatus.waiting || status == BalitaUploadStatus.uploading;

  void cancel() => _cancelled = true;

  void _set({BalitaUploadStatus? status, double? progress, String? error}) {
    if (status != null) this.status = status;
    if (progress != null) this.progress = progress;
    this.error = error;
    notifyListeners();
  }
}

/// Sends Balita photos and videos the way the website does
/// (esperanza-backend BalitaMediaController): POST /uploads names the file,
/// each 4 MB piece goes to /uploads/{id}/chunk at the offset the server has
/// reached, and /complete checks it (its real type, its size, a scan; a video
/// must be H.264 MP4 or WebM). A dropped connection costs one piece: a
/// failed piece is tried again, and an offset the server refuses (it already
/// had more, or less) resumes from where the server says it stopped.
class BalitaUploader {
  BalitaUploader._();

  static const maxItems = 10;
  static const maxImageBytes = 10 * 1024 * 1024;
  static const maxVideoBytes = 100 * 1024 * 1024;
  static const chunkBytes = 4 * 1024 * 1024;
  static const _retryDelays = [Duration(seconds: 1), Duration(seconds: 2), Duration(seconds: 4), Duration(seconds: 8)];

  /// Delays between retries; tests shorten them.
  @visibleForTesting
  static List<Duration> retryDelays = _retryDelays;

  static const _videoExtensions = {'mp4', 'm4v', 'mov', 'webm', '3gp', 'mkv'};

  /// Photo or video, from the picker's own type, else the file's extension.
  static BalitaMediaKind kindOf(XFile file) {
    final mime = file.mimeType ?? '';
    if (mime.startsWith('video/')) return BalitaMediaKind.video;
    if (mime.startsWith('image/')) return BalitaMediaKind.image;
    final name = (file.name.isNotEmpty ? file.name : file.path).toLowerCase();
    final dot = name.lastIndexOf('.');
    final ext = dot < 0 ? '' : name.substring(dot + 1);
    return _videoExtensions.contains(ext) ? BalitaMediaKind.video : BalitaMediaKind.image;
  }

  /// Uploads [upload]; its status says how it went. Never throws.
  static Future<void> run(BalitaUpload upload, {String base = '/citizen/balita'}) async {
    upload._set(status: BalitaUploadStatus.uploading, progress: 0);
    try {
      final size = await upload.file.length();
      final limit = upload.kind == BalitaMediaKind.video ? maxVideoBytes : maxImageBytes;
      if (size > limit) {
        upload._set(
          status: BalitaUploadStatus.failed,
          error: upload.kind == BalitaMediaKind.video
              ? 'This video is over ${limit ~/ 1048576} MB. Shorten it or record at a lower quality.'
              : 'This photo is over ${limit ~/ 1048576} MB.',
        );
        return;
      }

      final started = await _retry(() => api.post('$base/uploads', body: {
            'name': upload.file.name.isNotEmpty ? upload.file.name : 'file',
            'size': size,
            'kind': upload.kind == BalitaMediaKind.video ? 'video' : 'image',
          }));
      final id = JsonRead.string(started.map['id']);
      if (id == null) throw const ApiException(messageEn: 'The upload could not start.', messageFil: 'Hindi masimulan ang pag-upload.');
      final step = JsonRead.integer(started.map['chunk_bytes']) ?? chunkBytes;
      var offset = JsonRead.integer(started.map['received_bytes']) ?? 0;

      while (offset < size) {
        if (upload.cancelled) return;
        final end = offset + step < size ? offset + step : size;
        final bytes = await _read(upload.file, offset, end);
        try {
          final res = await _retry(() => api.postMultipart(
                '$base/uploads/$id/chunk',
                fields: {'offset': '$offset'},
                bytesFiles: {'chunk': (bytes: bytes, filename: 'piece')},
              ));
          offset = JsonRead.integer(res.map['received_bytes']) ?? end;
        } on ApiException catch (e) {
          if (e.status != 409 || e.code != 'UPLOAD_OFFSET_MISMATCH') rethrow;
          // The server holds a different amount: resume from there.
          final state = await _retry(() => api.get('$base/uploads/$id'));
          offset = JsonRead.integer(state.map['received_bytes']) ?? offset;
        }
        upload._set(progress: size == 0 ? 1 : (offset / size).clamp(0, 0.99).toDouble());
      }
      if (upload.cancelled) return;

      final done = await _retry(() => api.postMultipart('$base/uploads/$id/complete', fields: {
            if (upload.width != null) 'width': '${upload.width}',
            if (upload.height != null) 'height': '${upload.height}',
            if (upload.durationMs != null) 'duration_ms': '${upload.durationMs}',
          }));
      upload.media = BalitaMedia.fromApi(done.map);
      upload._set(status: BalitaUploadStatus.done, progress: 1);
    } on ApiException catch (e) {
      upload._set(status: BalitaUploadStatus.failed, error: e.explain());
    } on FormatException {
      upload._set(status: BalitaUploadStatus.failed, error: 'The server sent something this app could not read.');
    } catch (_) {
      upload._set(status: BalitaUploadStatus.failed, error: 'The file could not be read. Choose it again.');
    }
  }

  /// Bytes [start]..[end] of the file, without reading the whole video.
  static Future<Uint8List> _read(XFile file, int start, int end) async {
    final builder = BytesBuilder(copy: false);
    await for (final piece in file.openRead(start, end)) {
      builder.add(piece);
    }
    return builder.takeBytes();
  }

  /// Retries what can be retried (no connection, a timeout, 429, 5xx).
  static Future<T> _retry<T>(Future<T> Function() task) async {
    for (var attempt = 0;; attempt++) {
      try {
        return await task();
      } on ApiException catch (e) {
        if (!e.retryable || attempt >= retryDelays.length) rethrow;
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }
  }
}
