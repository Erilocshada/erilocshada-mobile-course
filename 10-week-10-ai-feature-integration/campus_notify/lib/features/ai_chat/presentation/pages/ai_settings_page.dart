import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes.dart';
import '../providers/ai_chat_providers.dart';

/// Pengaturan API key AI. Key disimpan di flutter_secure_storage —
/// TIDAK pernah ditulis di kode sumber / repository Git.
class AiSettingsPage extends ConsumerStatefulWidget {
  const AiSettingsPage({super.key});

  @override
  ConsumerState<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends ConsumerState<AiSettingsPage> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;

    await ref.read(aiChatProvider.notifier).saveApiKey(key);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key tersimpan di secure storage.')),
    );
    context.go(RoutePaths.aiChat);
  }

  Future<void> _clear() async {
    await ref.read(aiChatProvider.notifier).clearApiKey();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key dihapus — kembali ke mode offline.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(aiChatProvider.select((s) => s.apiKeyConfigured));

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                configured ? Icons.check_circle : Icons.radio_button_unchecked,
                color: configured ? Colors.green : Colors.orange,
              ),
              title: const Text('API Key Google Gemini'),
              subtitle: Text(
                configured
                    ? 'Terpasang — chat memakai LLM asli.'
                    : 'Belum diatur — chat memakai data lokal (fallback).',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'AIza...',
              helperText:
                  'Kunci didapat dari https://aistudio.google.com/apikey. '
                  'Disimpan aman di perangkat, tidak pernah di-commit.',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Simpan API Key'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: configured ? _clear : null,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus API Key (mode offline)'),
          ),
        ],
      ),
    );
  }
}
