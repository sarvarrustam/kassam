import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VersionBlockerPage extends StatelessWidget {
  final int currentVersion;
  final int requiredVersion;
  const VersionBlockerPage({super.key, required this.currentVersion, required this.requiredVersion});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.system_update_alt, size: 80, color: Colors.orange.shade700),
                const SizedBox(height: 32),
                const Text(
                  'Dastur yangilanishi kerak',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sizning versiyangiz: v$currentVersion\nKerakli versiya: v$requiredVersion',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Dasturdan chiqish', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
