// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get language => 'Bahasa';

  @override
  String get systemDefault => 'Ikuti sistem';

  @override
  String get cancel => 'Batal';

  @override
  String get addContent => 'Tambah Konten';

  @override
  String get retry => 'Coba lagi';

  @override
  String get tryAgain => 'Coba lagi';

  @override
  String get close => 'Tutup';

  @override
  String get databaseError => 'Kesalahan basis data';

  @override
  String get noSavedContent => 'Tidak ada konten tersimpan';

  @override
  String get loadContentFailed => 'Tidak dapat memuat konten';

  @override
  String get emptyContent => 'Belum ada konten';

  @override
  String get tryAgainMessage => 'Silakan coba lagi.';

  @override
  String get emptyContentHint =>
      'Simpan sesuatu yang ingin Anda lanjutkan nanti.';

  @override
  String get noSearchResults => 'Tidak ada hasil pencarian';

  @override
  String get noContentMatches =>
      'Tidak ada konten yang cocok dengan pencarian Anda.';

  @override
  String get clearSearch => 'Hapus pencarian';

  @override
  String get searchContent => 'Cari konten';

  @override
  String get searchHint => 'Nama, tag, atau catatan';

  @override
  String get filterByTag => 'Filter berdasarkan tag';

  @override
  String get allTags => 'Semua tag';

  @override
  String get dataUnchanged => 'Data tersimpan tidak berubah';

  @override
  String get noDetail => 'Belum ada detail tersimpan';

  @override
  String get openLatestLink => 'Buka tautan terbaru';

  @override
  String get linkUnavailable => 'Tautan tidak tersedia';

  @override
  String get openLinkFailed => 'Tidak dapat membuka tautan ini.';

  @override
  String get editContent => 'Edit Konten';

  @override
  String get editContentAction => 'Edit konten';

  @override
  String get updateContentHint => 'Perbarui konten tersimpan Anda';

  @override
  String get createContentHint => 'Apa yang ingin Anda lanjutkan?';

  @override
  String get contentName => 'Nama konten';

  @override
  String get contentNameHint => 'mis. Doraemon';

  @override
  String get optionalTag => 'Tag (opsional)';

  @override
  String get noTag => 'Tanpa tag';

  @override
  String get createTag => 'Buat tag';

  @override
  String get saveChanges => 'Simpan Perubahan';

  @override
  String get saveContent => 'Simpan Konten';

  @override
  String get contentNameRequired => 'Masukkan nama konten.';

  @override
  String get tagName => 'Nama tag';

  @override
  String get create => 'Buat';

  @override
  String get tagNameRequired => 'Masukkan nama tag.';

  @override
  String get editDetail => 'Edit Detail';

  @override
  String get addDetail => 'Tambah Detail';

  @override
  String get editDetailHint => 'Perbaiki titik lanjut tersimpan ini';

  @override
  String get createDetailHint => 'Simpan titik terakhir Anda';

  @override
  String get link => 'Tautan';

  @override
  String get optionalNote => 'Catatan (opsional)';

  @override
  String get noteHint => 'Tambahkan pengingat untuk nanti';

  @override
  String get saveDetail => 'Simpan Detail';

  @override
  String get validLinkRequired => 'Masukkan tautan absolut yang valid.';

  @override
  String get contentDetails => 'Detail konten';

  @override
  String get deleteContent => 'Hapus konten';

  @override
  String get history => 'Riwayat';

  @override
  String get emptyHistory =>
      'Belum ada detail tersimpan. Tambahkan tautan lanjut pertama Anda.';

  @override
  String get latest => 'Terbaru';

  @override
  String get editDetailAction => 'Edit detail';

  @override
  String get deleteDetail => 'Hapus detail';

  @override
  String get openLink => 'Buka tautan';

  @override
  String get deleteDetailTitle => 'Hapus detail?';

  @override
  String get deleteDetailMessage =>
      'Titik lanjut tersimpan ini akan dihapus dari riwayat.';

  @override
  String get deleteContentTitle => 'Hapus konten?';

  @override
  String get deleteContentMessage =>
      'Konten beserta seluruh riwayat tersimpannya akan dihapus.';

  @override
  String get exportBackup => 'Ekspor cadangan';

  @override
  String get exportBackupTitle => 'Ekspor cadangan?';

  @override
  String get export => 'Ekspor';

  @override
  String get importBackup => 'Impor cadangan';

  @override
  String get replaceLocalData => 'Ganti data lokal?';

  @override
  String get replace => 'Ganti';

  @override
  String get backupValidationFailed => 'Validasi cadangan gagal';

  @override
  String get languagePreferenceReadFailed =>
      'Tidak dapat membaca preferensi bahasa. Mengikuti sistem.';

  @override
  String get languagePreferenceSaveFailed =>
      'Tidak dapat menyimpan preferensi bahasa. Coba pilih lagi.';

  @override
  String get exportPrivacy =>
      'Cadangan ini mungkin berisi tautan dan catatan pribadi. Lokasi yang Anda pilih menentukan siapa yang dapat mengakses berkas.';

  @override
  String detailCount(int count) {
    return '$count detail';
  }

  @override
  String updatedAt(String timestamp) {
    return 'Diperbarui $timestamp';
  }

  @override
  String latestAt(String timestamp) {
    return 'Terbaru · $timestamp';
  }

  @override
  String get tagConflict => 'Tag dengan nama tersebut sudah ada.';

  @override
  String failureDatabase(String operation) {
    return 'Tidak dapat $operation. Data tersimpan Anda tidak berubah.';
  }

  @override
  String failureUnknown(String operation) {
    return 'Tidak dapat $operation. Silakan coba lagi.';
  }

  @override
  String failureNotFound(String operation) {
    return 'Tidak dapat $operation karena data sudah tidak ada.';
  }

  @override
  String failureValidation(String operation) {
    return 'Periksa nilai yang dimasukkan sebelum mencoba $operation.';
  }

  @override
  String failureField(String field, String operation) {
    return 'Masukkan $field yang valid untuk $operation.';
  }

  @override
  String get savedReloadFailed =>
      'Detail telah disimpan, tetapi kontennya tidak dapat dimuat ulang.';

  @override
  String get contentNotFound => 'Konten yang diminta tidak ditemukan.';

  @override
  String get operationLoadContent => 'memuat konten';

  @override
  String get operationLoadContentDetails => 'memuat detail konten';

  @override
  String get operationSaveContent => 'menyimpan konten';

  @override
  String get operationSaveDetail => 'menyimpan detail';

  @override
  String get operationDeleteDetail => 'menghapus detail';

  @override
  String get operationDeleteContent => 'menghapus konten';

  @override
  String get operationSaveChanges => 'menyimpan perubahan';

  @override
  String get operationLoadTags => 'memuat tag';

  @override
  String get operationSaveTag => 'menyimpan tag';

  @override
  String get operationRenameTag => 'mengganti nama tag';

  @override
  String get operationDeleteTag => 'menghapus tag';

  @override
  String get operationExportBackup => 'mengekspor cadangan';

  @override
  String get operationRestoreBackup => 'memulihkan cadangan';

  @override
  String get exportSuccess => 'Cadangan berhasil diekspor.';

  @override
  String get exportCancelled =>
      'Ekspor dibatalkan. Data tersimpan Anda tidak berubah.';

  @override
  String get exportFailed =>
      'Tidak dapat mengekspor cadangan. Silakan coba lagi.';

  @override
  String get issueInvalidUtf8 => 'Berkas bukan JSON UTF-8 yang valid.';

  @override
  String get issueInvalidJson => 'Berkas bukan JSON yang valid.';

  @override
  String get issueRootObject =>
      'Tingkat teratas cadangan harus berupa objek JSON.';

  @override
  String get issueSchemaVersion => 'Hanya skema versi 1 yang didukung.';

  @override
  String get issueTimestampRequired => 'Teks waktu wajib diisi.';

  @override
  String get issueTagNameEmpty => 'Nama tag tidak boleh kosong.';

  @override
  String get issueOwnershipType =>
      'Data kepemilikan harus berupa teks atau null.';

  @override
  String get issueMissingTag =>
      'Tag yang dirujuk tidak ada dalam cadangan ini.';

  @override
  String get issueContentNameEmpty => 'Nama konten tidak boleh kosong.';

  @override
  String get issueMissingContent =>
      'Konten yang dirujuk tidak ada dalam cadangan ini.';

  @override
  String get issueAbsoluteLink =>
      'Tautan harus berupa URI absolut yang tidak kosong.';

  @override
  String get issueArrayRequired => 'Array JSON wajib diisi.';

  @override
  String get issueObjectRequired => 'Objek JSON wajib diisi.';

  @override
  String get issueUuidRequired => 'UUID yang valid wajib diisi.';

  @override
  String get issueStringRequired => 'Nilai teks wajib diisi.';

  @override
  String get issueNullableRequired =>
      'Kolom wajib ada dan boleh bernilai null.';

  @override
  String get issueNullableString => 'Nilai harus berupa teks atau null.';

  @override
  String get issueInvalidTimestamp =>
      'Waktu harus berupa waktu ISO 8601 yang valid.';

  @override
  String issueDuplicateId(String reference) {
    return 'ID ini menduplikasi $reference dan harus unik.';
  }

  @override
  String issueDuplicateTag(String reference) {
    return 'Nama tag harus unik tanpa membedakan huruf besar dan kecil (duplikat dari $reference).';
  }

  @override
  String validationSummary(int count) {
    return '$count kesalahan validasi. Data tersimpan Anda tidak berubah.';
  }

  @override
  String additionalIssues(int count) {
    return '$count masalah lainnya.';
  }

  @override
  String restorePreview(int tags, int contents, int details) {
    return 'Cadangan valid ini berisi $tags tag, $contents konten, dan $details detail. Konfirmasi akan mengganti seluruh data lokal saat ini.';
  }

  @override
  String restoreSuccess(int tags, int contents, int details) {
    return 'Memulihkan $tags tag, $contents konten, dan $details detail.';
  }

  @override
  String get restoreCancelled =>
      'Impor dibatalkan. Data tersimpan Anda tidak berubah.';

  @override
  String get restoreUnreadable =>
      'Cadangan yang dipilih tidak dapat dibaca. Data tersimpan Anda tidak berubah.';

  @override
  String get restoreMissingPreview =>
      'Pilih cadangan yang valid dan tinjau pratinjaunya sebelum memulihkan.';

  @override
  String get restoreFailed =>
      'Tidak dapat memulihkan cadangan. Data tersimpan Anda tidak berubah.';

  @override
  String get restoreBusy => 'Impor sedang berlangsung.';

  @override
  String get settings => 'Pengaturan';

  @override
  String get backupAndRestore => 'Cadangan & Pemulihan';

  @override
  String get exportDescription =>
      'Simpan tag, konten, dan detail ke berkas JSON portabel.';

  @override
  String get importDescription =>
      'Pulihkan data dari berkas cadangan JSON. Ini menggantikan data lokal saat ini.';

  @override
  String get manageTags => 'Kelola tag';

  @override
  String get manageTagsDescription =>
      'Buat, ganti nama, dan hapus tag untuk mengatur konten.';

  @override
  String get emptyTags => 'Belum ada tag';

  @override
  String get emptyTagsHint =>
      'Buat tag untuk mengelompokkan dan memfilter konten tersimpan Anda.';

  @override
  String get renameTag => 'Ganti nama tag';

  @override
  String get rename => 'Ganti nama';

  @override
  String get deleteTagTitle => 'Hapus tag?';

  @override
  String get deleteTagMessage =>
      'Konten dengan tag ini tidak akan dihapus, tetapi tidak lagi memiliki tag.';

  @override
  String get deleteTagAction => 'Hapus tag';

  @override
  String get tagDeleted => 'Tag berhasil dihapus.';

  @override
  String get tagCreated => 'Tag berhasil dibuat.';

  @override
  String get tagRenamed => 'Tag berhasil diubah namanya.';

  @override
  String get theme => 'Tema';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get themePreferenceReadFailed =>
      'Tidak dapat membaca preferensi tema. Menggunakan Ikuti sistem.';

  @override
  String get themePreferenceSaveFailed =>
      'Tidak dapat menyimpan preferensi tema.';
}
