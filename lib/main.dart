import 'dart:convert';
import 'dart:io'; // Note: this import won’t work on web.
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_datakit/dart_datakit.dart'; // Imports both Datacat and Datakitties.
import 'package:alga_configui/src/config_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple App Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _cachedConfig;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _clearCachedConfig();
    _loadCachedConfig();
  }

  Future<void> _clearCachedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_config');
    setState(() {
      _cachedConfig = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cached config cleared.')),
    );
  }

  Future<void> _loadCachedConfig() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _cachedConfig = prefs.getString('cached_config');
    });
  }

  Future<void> _pickConfigFile() async {
    // Let the user pick a JSON file.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      _fileName = file.name;
      String? content;
      if (file.bytes != null) {
        // On web or when bytes are provided.
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        // On mobile/desktop when a file path is available.
        content = await File(file.path!).readAsString();
      }

      if (content != null) {
        // Cache the content using shared_preferences.
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_config', content);
        setState(() {
          _cachedConfig = content;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Config file "$_fileName" loaded and cached.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Parse the cached JSON into a Datakitties instance.
              final datakitties = _cachedConfig != null
                  ? Datakitties.fromJsonMapString(_cachedConfig!)
                  : null;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfigPage(datakitties: datakitties),
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left half: Controls and info.
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome to the App',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _pickConfigFile,
                    child: const Text('Select Config JSON File'),
                  ),
                  const SizedBox(height: 20),
                  if (_cachedConfig != null)
                    Text('Cached Config Loaded: ${_fileName ?? "Unknown"}')
                  else
                    const Text('No Config Cached'),
                ],
              ),
            ),
          ),
          // Right half: Display the JSON content.
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: _cachedConfig != null
                  ? SingleChildScrollView(
                      child: Text(
                        _cachedConfig!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const Center(
                      child: Text('No Config File Content to Display'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
