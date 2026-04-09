import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

class EnvFirebase {
  static FirebaseOptions get currentPlatform => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_APIKEY']!,
    authDomain: dotenv.env['FIREBASE_AUTHDOMAIN'],
    projectId: dotenv.env['FIREBASE_PROJECTID']!,
    storageBucket: dotenv.env['FIREBASE_STORAGEBUCKET'],
    messagingSenderId: dotenv.env['FIREBASE_MESSAGINGSENDERID']!,
    appId: dotenv.env['FIREBASE_APPID']!,
    measurementId: dotenv.env['FIREBASE_MEASUREMENTID'],
  );
}
