import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/pantallas/sumar_personas.dart';


class EnterUser extends StatefulWidget {
  const EnterUser({super.key});


  @override
  State<EnterUser> createState() => _EnterUserState();
}


class _EnterUserState extends State<EnterUser> {
  final mailController = TextEditingController();
  final passwordController = TextEditingController();


  String mensaje = '';
  bool _estaCargando = false;
  bool _mostrarPassword = false; // Estado para ver/ocultar contraseña


  Future<void> _validarIngreso() async {
    String mail = mailController.text.trim();
    String password = passwordController.text.trim();


    if (mail.isEmpty || password.isEmpty) {
      _mostrarSnackBar('Por favor, completa todos los campos');
      return;
    }


    setState(() {
      _estaCargando = true;
    });


    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: mail,
        password: password,
      );


      User? user = userCredential.user;


      if (user != null) {
        await user.reload();
        user = FirebaseAuth.instance.currentUser;


        if (!user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            _mostrarSnackBar('Debes verificar tu correo antes de ingresar.');
          }
          return;
        }


        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PersonasScreen(),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          mensaje = 'Mail o contraseña incorrectos';
        } else if (e.code == 'invalid-email') {
          mensaje = 'El formato del mail no es válido';
        } else {
          mensaje = 'Error al iniciar sesión: ${e.message}';
        }
      });
      _mostrarSnackBar(mensaje);
    } catch (e) {
      _mostrarSnackBar('Ocurrió un error inesperado');
    } finally {
      if (mounted) {
        setState(() {
          _estaCargando = false;
        });
      }
    }
  }


  void _mostrarSnackBar(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        duration: const Duration(seconds: 4),
      ),
    );
  }


  @override
  void dispose() {
    mailController.dispose();
    passwordController.dispose();
    super.dispose();
  }


  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword && !showPassword,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF2C3E50),
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF2C3E50),
                width: 2.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF2C3E50),
                width: 2.5,
              ),
            ),
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8FAEC4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(
                      label: 'Mail',
                      controller: mailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),
                    _buildInputField(
                      label: 'Contraseña',
                      controller: passwordController,
                      isPassword: true,
                      showPassword: _mostrarPassword,
                      onTogglePassword: () {
                        setState(() {
                          _mostrarPassword = !_mostrarPassword;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              SizedBox(
                width: 220,
                height: 56,
                child: _estaCargando
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : ElevatedButton(
                        onPressed: _validarIngreso,
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
                        child: const Text(
                          "INICIAR SESIÓN",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: Colors.white,
                          ),
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




