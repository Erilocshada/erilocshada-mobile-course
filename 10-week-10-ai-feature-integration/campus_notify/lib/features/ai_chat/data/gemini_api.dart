import 'dart:io';

import 'package:dio/dio.dart';

/// Hasil pemanggilan Gemini — sudah dinormalisasi, parsing null-safe
/// (response kosong / diblokir safety TIDAK boleh membuat crash).
typedef AiCallResult =
    ({
      bool ok,
      String? text,
      int? statusCode,
      String? reason,
    });

/// Client Gemini generatif. Hanya boleh dipakai repository impl (data layer).
class GeminiApi {
  GeminiApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              responseType: ResponseType.json,
            ),
          );

  final Dio _dio;

  static const String model = 'gemini-2.0-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta'
      '/models/$model:generateContent';

  /// System prompt — persona + batas (lihat docs/ai-log.md).
  static const String systemPrompt =
      'Kamu adalah asisten kampus "Campus Notify" untuk mahasiswa Indonesia. '
      'Jawab dalam Bahasa Indonesia, maksimal 3 kalimat, ramah dan spesifik. '
      'Jangan pernah meminta atau menampilkan data pribadi (NIK, telepon, '
      'alamat). Jangan beri jawaban di luar konteks layanan kampus.';

  Future<AiCallResult> generate({
    required String apiKey,
    required String question,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _baseUrl,
        queryParameters: {'key': apiKey},
        data: {
          'systemInstruction': {
            'parts': [
              {'text': systemPrompt},
            ],
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': question},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.4,
            'maxOutputTokens': 300,
          },
        },
      );

      final text = _extractText(response.data);
      if (text == null || text.isEmpty) {
        return (
          ok: false,
          text: null,
          statusCode: response.statusCode,
          reason: 'Respons AI kosong atau diblokir safety filter.',
        );
      }

      return (
        ok: true,
        text: text,
        statusCode: response.statusCode,
        reason: null,
      );
    } on DioException catch (e) {
      return (
        ok: false,
        text: null,
        statusCode: e.response?.statusCode,
        reason: _describeDioError(e),
      );
    } on SocketException {
      return (
        ok: false,
        text: null,
        statusCode: null,
        reason: 'Perangkat tidak terhubung ke internet.',
      );
    }
  }

  /// Parsing defensif: candidates/part(s)/text bisa hilang atau berubah bentuk.
  String? _extractText(Map<String, dynamic>? body) {
    final candidates = body?['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final first = candidates.first;
    if (first is! Map) return null;

    final content = first['content'];
    if (content is! Map) return null;

    final parts = content['parts'];
    if (parts is! List) return null;

    final text = parts
        .whereType<Map>()
        .map((p) => p['text'])
        .whereType<String>()
        .join(' ')
        .trim();

    return text.isEmpty ? null : text;
  }

  String _describeDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Layanan AI tidak merespons (timeout).';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 400 || code == 401 || code == 403) {
          return 'API key AI ditolak ($code). Periksa di Pengaturan AI.';
        }
        if (code == 429) {
          return 'Kuota permintaan AI habis (429). Coba lagi nanti.';
        }
        return 'Layanan AI error (HTTP ${code ?? '?'})';
      default:
        return 'Gagal menghubungi layanan AI.';
    }
  }
}
