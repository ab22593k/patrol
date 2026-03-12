import 'package:flutter/material.dart';

void main() {
  runApp(const LinuxTestApp());
}

class LinuxTestApp extends StatelessWidget {
  const LinuxTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linux Patrol Test App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestHomePage(),
    );
  }
}

class TestHomePage extends StatefulWidget {
  const TestHomePage({super.key});

  @override
  State<TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<TestHomePage> {
  var _displayText = 'Hello, Linux!';
  var _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
      _displayText = 'Button clicked $_counter times';
    });
  }

  void _changeText(String text) {
    setState(() {
      _displayText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linux Patrol Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Display Text:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _displayText,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Enter text',
                border: OutlineInputBorder(),
              ),
              onChanged: _changeText,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _incrementCounter,
              child: const Text('Click Me'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _changeText('Option 1'),
                  child: const Text('Option 1'),
                ),
                ElevatedButton(
                  onPressed: () => _changeText('Option 2'),
                  child: const Text('Option 2'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
