import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';

/// Application-owned boundary for choosing and writing an export destination.
///
/// The export controller only deals in UTF-8 bytes, so tests do not need a
/// platform file picker or a real filesystem.
abstract interface class BackupFileGateway {
  Future<BackupFileSaveResult> save({
    required String fileName,
    required List<int> bytes,
  });
}

/// Application-owned boundary for selecting and reading an import file.
abstract interface class BackupRestoreFileGateway {
  Future<BackupFileReadResult> pick();
}

enum BackupFileReadStatus { selected, cancelled }

class BackupFileReadResult {
  BackupFileReadResult._(this.status, {this.bytes, this.source});

  factory BackupFileReadResult.selected(Iterable<int> bytes, {String? source}) {
    return BackupFileReadResult._(
      BackupFileReadStatus.selected,
      bytes: List.unmodifiable(bytes),
      source: source,
    );
  }

  const BackupFileReadResult.cancelled()
    : status = BackupFileReadStatus.cancelled,
      bytes = null,
      source = null;

  final BackupFileReadStatus status;
  final List<int>? bytes;
  final String? source;

  bool get selected => status == BackupFileReadStatus.selected;
  bool get cancelled => status == BackupFileReadStatus.cancelled;
}

class UnavailableBackupRestoreFileGateway implements BackupRestoreFileGateway {
  const UnavailableBackupRestoreFileGateway();

  @override
  Future<BackupFileReadResult> pick() async {
    return const BackupFileReadResult.cancelled();
  }
}

/// Selects a JSON backup through the platform file picker.
class FilePickerBackupRestoreFileGateway implements BackupRestoreFileGateway {
  const FilePickerBackupRestoreFileGateway();

  @override
  Future<BackupFileReadResult> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return const BackupFileReadResult.cancelled();
    }

    final file = result.files.single;
    final bytes =
        file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) {
      throw StateError('The selected backup could not be read');
    }
    return BackupFileReadResult.selected(bytes, source: file.path ?? file.name);
  }
}

typedef FilePickerBackupFileGateway = FilePickerBackupRestoreFileGateway;

enum BackupFileSaveStatus { saved, cancelled }

class BackupFileSaveResult {
  const BackupFileSaveResult._(this.status, {this.destination});

  const BackupFileSaveResult.saved({String? destination})
    : this._(BackupFileSaveStatus.saved, destination: destination);

  const BackupFileSaveResult.cancelled()
    : this._(BackupFileSaveStatus.cancelled);

  final BackupFileSaveStatus status;
  final String? destination;

  bool get saved => status == BackupFileSaveStatus.saved;
  bool get cancelled => status == BackupFileSaveStatus.cancelled;
}

/// Used until a platform save flow is configured.
class UnavailableBackupFileGateway implements BackupFileGateway {
  const UnavailableBackupFileGateway();

  @override
  Future<BackupFileSaveResult> save({
    required String fileName,
    required List<int> bytes,
  }) async {
    return const BackupFileSaveResult.cancelled();
  }
}

/// Saves JSON through the platform file flow.
///
/// Mobile and Windows/macOS use the plugin's save-as flow. Linux currently
/// uses its supported default-directory flow because the plugin does not
/// expose a Linux save dialog.
class FileSaverBackupFileGateway implements BackupFileGateway {
  const FileSaverBackupFileGateway();

  @override
  Future<BackupFileSaveResult> save({
    required String fileName,
    required List<int> bytes,
  }) async {
    final extension = _extensionOf(fileName);
    final name = _nameWithoutExtension(fileName);
    final saver = FileSaver.instance;
    final path =
        Platform.isLinux
            ? await saver.saveFile(
              name: name,
              bytes: Uint8List.fromList(bytes),
              fileExtension: extension,
              mimeType: MimeType.json,
            )
            : await saver.saveAs(
              name: name,
              bytes: Uint8List.fromList(bytes),
              fileExtension: extension,
              mimeType: MimeType.json,
            );

    if (path == null) {
      return const BackupFileSaveResult.cancelled();
    }
    if (path.trim().isEmpty || path.startsWith('Something went wrong')) {
      throw StateError('The backup destination could not be written');
    }
    return BackupFileSaveResult.saved(destination: path);
  }
}

String _extensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot < 0 || dot == fileName.length - 1
      ? ''
      : fileName.substring(dot + 1);
}

String _nameWithoutExtension(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot <= 0 ? fileName : fileName.substring(0, dot);
}
