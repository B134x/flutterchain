import 'package:material_ui/material_ui.dart';

import 'config.dart';
import 'logbook_controller.dart';
import 'screens/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig? config;
  String? configError;
  try {
    config = await AppConfig.load();
  } on ConfigError catch (e) {
    configError = e.message;
  }
  runApp(LogbookApp(config: config, configError: configError));
}

class LogbookApp extends StatefulWidget {
  const LogbookApp({super.key, this.config, this.configError});

  final AppConfig? config;
  final String? configError;

  @override
  State<LogbookApp> createState() => _LogbookAppState();
}

class _LogbookAppState extends State<LogbookApp> {
  LogbookController? _controller;

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    if (config != null) _controller = LogbookController(config)..start();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'Logbook Alat Lab IoT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
      home: _controller == null ? _ConfigErrorPage(widget.configError ?? '') : const HomePage(),
    );
    final controller = _controller;
    // Above MaterialApp, so pushed routes (e.g. the borrow form) can reach the state too.
    return controller == null ? app : LogbookScope(controller: controller, child: app);
  }
}

class _ConfigErrorPage extends StatelessWidget {
  const _ConfigErrorPage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfigurasi belum lengkap')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.settings_suggest_outlined, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const Text('Perbaiki .env lalu build ulang aplikasi. RPC URL dan alamat kontrak bisa diatur '
              'nanti di halaman Koneksi, tetapi CHAIN_ID harus 11155111.'),
        ],
      ),
    );
  }
}
