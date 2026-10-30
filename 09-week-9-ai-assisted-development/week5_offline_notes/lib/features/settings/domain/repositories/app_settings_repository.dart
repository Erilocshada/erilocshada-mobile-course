/// Kontrak penyimpanan preferensi aplikasi.
///
/// Bentuknya sengaja abstrak ("tema gelap nyala/tidak", "kapan terakhir dibuka")
/// supaya SharedPreferences hari ini bisa ditukar tanpa menyentuh presentation.
abstract class AppSettingsRepository {
  Future<bool> getDarkMode();

  Future<void> setDarkMode(bool value);

  Future<void> markOpenedNow();

  Future<String?> getLastOpened();
}
