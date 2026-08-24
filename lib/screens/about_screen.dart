import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Идентификатор на приложението в Google Play.
const String kPlayStorePackage = 'com.mirsolutionsbg.barcode_counter';

/// Директна връзка към страницата на приложението в Google Play.
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=$kPlayStorePackage';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = 'Версия ${info.version} (${info.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('За приложението'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Icon(
              Icons.qr_code_scanner,
              size: 96,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Баркод инвентар',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _version,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),

            // Покана за оценка
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 32),
                        Icon(Icons.star, color: Colors.amber, size: 32),
                        Icon(Icons.star, color: Colors.amber, size: 32),
                        Icon(Icons.star, color: Colors.amber, size: 32),
                        Icon(Icons.star, color: Colors.amber, size: 32),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Харесва ли Ви приложението?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Оставете 5 звезди в Google Play – отнема само няколко '
                      'секунди и ни помага много!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _openPlayStore,
                        icon: const Icon(Icons.star_rate, size: 26),
                        label: const Text(
                          'Оценете ни с 5 звезди',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Директна връзка към страницата в Google Play
            TextButton.icon(
              onPressed: _openPlayStore,
              icon: const Icon(Icons.open_in_new, size: 20),
              label: const Text('Отвори страницата в Google Play'),
            ),

            const SizedBox(height: 24),
            Text(
              '© MIR Solutions BG',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPlayStore() async {
    // Първо опитваме да отворим директно приложението Google Play,
    // след това падаме към браузър.
    final marketUri = Uri.parse('market://details?id=$kPlayStorePackage');
    final webUri = Uri.parse(kPlayStoreUrl);

    bool opened = false;
    try {
      opened = await launchUrl(marketUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }

    if (!opened) {
      try {
        opened =
            await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не може да се отвори Google Play'),
        ),
      );
    }
  }
}
