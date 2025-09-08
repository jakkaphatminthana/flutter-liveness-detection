import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liveness_detection/features/face_liveness/ui/face_liveness_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // disable landscape screen
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liveness Detection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showSnackBar(BuildContext context, bool success) {
    final message = success ? "✅ Detection Success" : "❌ Detection Failed";
    final color = success ? Colors.green : Colors.red;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Liveness Detection"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FaceLivenessScreen(
                  callback: (success) => _showSnackBar(context, success),
                ),
              ),
            );
          },
          child: const Text("Start Detection"),
        ),
      ),
    );
  }
}
