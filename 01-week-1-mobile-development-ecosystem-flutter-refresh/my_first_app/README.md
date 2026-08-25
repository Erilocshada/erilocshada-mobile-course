1. Perbedaan hot reload dan hot restart?
2. Kapan native lebih tepat dipilih daripada cross-platform?
3. Bagaimana perubahan state berhubungan dengan widget tree dan UI deklaratif?
4. Mengapa commit kecil dengan pesan jelas bermanfaat bagi pekerjaan tim dan portfolio?

Jawaban:
1. Hot reload digunakan untuk perubahan code dengan cepat, sedangkan hot restart digunakan untuk menjalankan ulang aplikasi
2. Native digunakan ketika aplikasi membutuhkan performa tinggi, akses mendalam ke fitur perangkat, atau integrasi khusus dengan sistem operasi.
3. state atau data yang berubah selama aplikasi berjalan. ketika state berubah, maka FLutter akan melakukan rebuild terhadap bagian widget tree yang terdampak
4. commit kecil berfungsi untuk mengetahui perubahan code, mudah dipahami, dan diperbaiki.
untuk tim:
- Anggota tim lebih mudah memahami perubahan
- konflik kode mudah dicari
- code review jadi lebih mudah
- memudahkan rollback perubahan tertentu
untuk portofolio:
- Repo terlihat lebih profesional
- Recruiter dapat melihat proses pengembangan proyek
- menunjukan kemampuan bekerja secara terstruktur dan kolaboratif