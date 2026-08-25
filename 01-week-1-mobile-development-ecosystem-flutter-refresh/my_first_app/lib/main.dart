import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profil Mahasiswa')),
        body: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.school, size: 72),
            SizedBox(height: 16),
            Text('Muhammad Pearl Ocshada', style: TextStyle(fontSize: 24)),
            Text('Pemrograman Mobile — Minggu 1'),
            // Menambahkan widget Text untuk menampilkan NIM
            Text('NIM: 244107020064', style: TextStyle(fontSize: 18)),
          ]),
        ),
      ),
    );
  }
}