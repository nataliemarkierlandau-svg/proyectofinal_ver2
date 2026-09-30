import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/pantallas/sumar_personas.dart';


class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});


  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}


class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _puedeReenviar = true;


  @override
  void initState() {
    super.initState();
    // Revisa automáticamente cada 3 segundos el estado del correo
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _comprobarVerificacion();
    });
  }


  Future<void> _comprobarVerificacion() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      user = FirebaseAuth.instance.currentUser;


      // 1. CAMBIO AUTOMÁTICO AL CONFIRMAR
      if (user != null && user.emailVerified) {
        _timer?.cancel();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const PersonasScreen()),
            (route) => false,
          );
        }
      }
    }
  }


  Future<void> _reenviarCorreo() async {
    if (!_puedeReenviar) return;


    setState(() {
      _puedeReenviar = false;
    });


    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se ha reenviado el correo de verificación.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reenviar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }


    await Future.delayed(const Duration(seconds: 30));
    if (mounted) {
      setState(() {
        _puedeReenviar = true;
      });
    }
  }


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8FAEC4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9D6E5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2C3E50),
                    width: 2.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 70,
                      color: Color(0xFF2C3E50),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'VERIFICA TU MAIL',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Abre tu correo y confirma el enlace.\n\nEsta pantalla avanzará automáticamente en cuanto lo confirmes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF2C3E50),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 25),
                    const CircularProgressIndicator(
                      color: Color(0xFF2C3E50),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 220,
                height: 50,
                child: ElevatedButton(
                  onPressed: _puedeReenviar ? _reenviarCorreo : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38728F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    side: const BorderSide(
                      color: Color(0xFF2C3E50),
                      width: 2.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _puedeReenviar ? "REENVIAR CORREO" : "ESPERE UN MOMENTO...",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  _timer?.cancel();
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

