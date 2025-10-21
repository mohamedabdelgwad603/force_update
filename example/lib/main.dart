import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:force_update/force_update.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  checkForUpdate(BuildContext context) async {
    bool requiredUpdate = await ForceUpdateManager.checkForUpdate(
      minimumVersionRemoteConfigKey:
          "minimum_version", // get from Firebase Remote Config
      minimumVersionOverride:
          '2.0.0', // for local testing or fallback if Remote Config not set
      //if minimumVersionRemoteConfigKey is set in Firebase, this value is ignored
    );
    if (requiredUpdate) {
      ForceUpdateManager.performForceUpdate(
        context,
        barrierDismissible: true,
        androidStoreUrl:
            "https://play.google.com/store/apps/details?id=com.example.force_update",
        iosStoreUrl: "https://apps.apple.com/app/id0000000000",
      );
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      checkForUpdate(context);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Force Update Example')),
      body: Center(child: Text('Force Update Example')),
    );
  }
}
