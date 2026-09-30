import 'package:flutter/material.dart';

class InformacionScreen extends StatelessWidget {
  const InformacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8FAEC4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Flecha de regresar
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Título en blanco
              const Text(
                "BIENVENIDO/A\nA FUGA DE MENTES",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 15),

              // Recuadro del scroll
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3ECF1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF2C3E50),
                      width: 2.5,
                    ),
                  ),
                  child: const SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Text(
                      "Nuestro proyecto busca ofrecer un sistema de ayuda en caso de que una persona se pierda mientras está en la vía pública.\n\n"
                      "Está dirigido a instituciones como geriátricos o escuelas alternativas donde necesitan un seguimiento más específico.\n\n"
                      "Para evitar esto, se presenta una operación de rastreo que identifica movimientos fuera de lo normal en lo que respecta al usuario.\n\n"
                      "El proyecto estará acompañado por una aplicación móvil que al iniciar sesión consultará el tipo de usuario al que se quiere rastrear (ya sea niño, adulto o anciano) y el tipo de condición que tenga.\n\n"
                      "El cuidador podrá establecer una zona o un radio específico dentro del cual la persona podrá moverse, y la app avisará al cuidador en caso de que salga de este.",
                      style: TextStyle(
                        fontSize: 15.5,
                        height: 1.4,
                        color: Color(0xFF2C3E50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Imagen en la parte inferior usando el asset local
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF2C3E50),
                      width: 2.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21.5),
                    child: Image.asset(
                      'assets/abuelos.png', // Ruta del asset declarado en pubspec.yaml
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Color(0xFF2C3E50),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}