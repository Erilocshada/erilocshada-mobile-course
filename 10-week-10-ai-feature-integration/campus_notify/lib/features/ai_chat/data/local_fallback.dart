/// Sumber data lokal untuk fallback: dipakai saat API key belum diisi,
/// layanan AI error/down, atau respons tidak valid. Mengacu pada data
/// aplikasi minggu 6-8 (jadwal UTS, topik pengumuman, cara berlangganan).
class LocalFallback {
  const LocalFallback();

  static const String _generic =
      'Maaf, asisten AI sedang tidak tersedia. Anda bisa mengecek menu '
      'Pengumuman untuk info resmi kampus, atau coba lagi nanti.';

  /// Jawaban lokal berbasis kata kunci — tanpa jaringan, tanpa LLM.
  String answerFor(String question) {
    final q = question.toLowerCase();

    if (q.contains('jadwal') || q.contains('uts') || q.contains('ujian')) {
      return 'Jadwal Ujian Tengah Semester telah diumumkan. '
          'Silakan cek jadwal melalui sistem akademik (lihat menu Pengumuman #1).';
    }

    if (q.contains('pengumuman')) {
      return 'Pengumuman kampus tersedia di menu Pengumuman. '
          'Aktifkan langganan topik "pengumuman-kampus" di Beranda '
          'agar notifikasinya masuk otomatis.';
    }

    if (q.contains('notifikasi') ||
        q.contains('notif') ||
        q.contains('langganan') ||
        q.contains('subscribe')) {
      return 'Notifikasi berbasis topik Firebase. Buka Beranda lalu '
          'aktifkan switch "Topik Pengumuman Kampus" untuk berlangganan.';
    }

    if (q.contains('login') || q.contains('akun') || q.contains('masuk')) {
      return 'Masuk menggunakan email kampus (@) dan password minimal '
          '6 karakter. sesi disimpan aman di perangkat Anda.';
    }

    return _generic;
  }
}
