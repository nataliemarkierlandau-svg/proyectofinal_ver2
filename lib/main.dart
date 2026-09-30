import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'pantallas/enter_user.dart';
import 'pantallas/register.dart';
import 'pantallas/informacion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC6bPEExnW4hzhTXq0PrLRfo_NB98HA0K0",
      authDomain: "proyectofinal-486fb.firebaseapp.com",
      databaseURL: "https://proyectofinal-486fb-default-rtdb.firebaseio.com",
      projectId: "proyectofinal-486fb",
      storageBucket: "proyectofinal-486fb.appspot.com",
      messagingSenderId: "283486047182",
      appId: "1:283486047182:web:1884cd12ecd89cdeeb399f",
    ),
  );

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      home: const Inicio(),
    );
  }
}

class Inicio extends StatelessWidget {
  const Inicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98B4CE),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO EN FORMATO CIRCULAR DESDE ASSETS
                SizedBox(
                  width: 120,
                  height: 120,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo(2).png',
                      fit: BoxFit.cover, // 'cover' asegura que llene todo el círculo correctamente
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // BIENVENIDO EXTENDIDO DE PUNTA A PUNTA
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: const Text(
                      "BIENVENIDO",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // BLOQUE DE BOTONES Y TEXTO INFERIOR (CENTRADOS)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // BOTÓN REGISTRARSE
                    SizedBox(
                      width: 280,
                      height: 60,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Register(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B6E8C),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.black87, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "REGISTRARSE",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // BOTÓN INICIAR SESIÓN
                    SizedBox(
                      width: 280,
                      height: 60,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EnterUser(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B6E8C),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.black87, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "INICIAR SESIÓN",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30), // Espaciado bajado para el "Más información"

                    // TEXTO INFERIOR BLANCO Y CENTRADO
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InformacionScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Más información sobre esta app",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}