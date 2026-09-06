AI PROMPT CHALLENGE
1. Untuk dashboard akademik dengan header profil dan hanya beberapa kartu, LayoutBuilder + Column lebih baik karena struktur dan aksesibilitasnya lebih mudah dikontrol. GridView digunakan sebagai bagian internal untuk menyusun kartu secara responsif.
Untuk dashboard dengan puluhan atau ratusan item yang bentuknya seragam, gunakan GridView.builder karena lebih efisien dan mendukung lazy loading.
2. Expanded menyebabkan overflow ketika ruang yang tersisa di dalam Row lebih kecil daripada kebutuhan child yang memiliki ukuran tetap.
3. Rekomendasi layout tetap responsif di bawah 600px dan tidak mengurangi aksesibilitas secara prinsip. Risiko utamanya adalah overflow saat layar sangat sempit atau text scaling diperbesar, serta label profil yang saat ini tidak sesuai dengan teks visual. Perbaikan paling penting adalah menyamakan label Semantics, menggunakan Flexible pada nilai kartu, dan mempertimbangkan layout Column untuk kartu pada lebar ekstrem.
