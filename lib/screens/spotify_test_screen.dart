import 'package:flutter/material.dart';
import 'package:songsurf/services/spotify_service.dart';

class SpotifyTestScreen extends StatefulWidget {
  const SpotifyTestScreen({super.key});

  @override
  State<SpotifyTestScreen> createState() => _SpotifyTestScreenState();
}

class _SpotifyTestScreenState extends State<SpotifyTestScreen> {
  final _spotifyService = SpotifyService();
  Map<String, dynamic>? _testResults;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotify Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spotify Connection Diagnostics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _runTests,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Run Diagnostics'),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Text(
                  'Error: $_errorMessage',
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            if (_testResults != null) ...[
              Text(
                'Test Results:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildTestResultsView(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _spotifyService.testSpotifyConnection();
      setState(() {
        _testResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildTestResultsView() {
    if (_testResults == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _testResults!.entries.map((entry) {
        final key = entry.key;
        final value = entry.value;
        
        // Format the key for better readability
        final formattedKey = key
            .replaceAllMapped(
                RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
            .replaceAllMapped(
                RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)} ${match.group(2)}')
            .toLowerCase()
            .trim();
        
        final capitalizedKey = formattedKey.substring(0, 1).toUpperCase() + formattedKey.substring(1);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$capitalizedKey:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                value.toString(),
                style: TextStyle(
                  color: value.toString().contains('Error') || value.toString().contains('Exception')
                      ? Colors.red
                      : value == true
                          ? Colors.green
                          : null,
                ),
              ),
              const Divider(),
            ],
          ),
        );
      }).toList(),
    );
  }
} 