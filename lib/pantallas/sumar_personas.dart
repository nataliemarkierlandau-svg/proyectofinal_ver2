import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pantallas/mapa.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';    
import 'package:image_picker/image_picker.dart'; 

class Persona {
  final String id; 
  final String nombre;
  final String telefono;
  final String fotoUrl; 

  Persona(this.id, this.nombre, this.telefono, this.fotoUrl);
}

class PersonasScreen extends StatefulWidget {
  const PersonasScreen({super.key});

  @override
  State<PersonasScreen> createState() => _PersonasScreenState();
}

class _PersonasScreenState extends State<PersonasScreen> {
  List<Persona> personas = [];
  String busqueda = '';
  final ImagePicker _picker = ImagePicker(); 

  @override
  void initState() {
    super.initState();
    _cargarPersonasDesdeFirebase(); 
  }

  Future<void> _cargarPersonasDesdeFirebase() async {
    try {
      String? supervisorUid = FirebaseAuth.instance.currentUser?.uid;
      if (supervisorUid == null) return;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('personas_asignadas')
          .where('supervisor_id', isEqualTo: supervisorUid)
          .get();

      List<Persona> listaTemporal = [];

      for (var doc in snapshot.docs) {
        String nombre = doc['nombre'] ?? '';
        String telefono = doc['telefono'] ?? '';
        String fotoDefecto = "https://ui-avatars.com/api/?name=${Uri.encodeComponent(nombre)}&background=3B6E8C&color=fff&size=128";

        final datos = doc.data() as Map<String, dynamic>;
        String urlFinal = datos.containsKey('foto_url') && datos['foto_url'] != null && datos['foto_url'].toString().isNotEmpty
            ? datos['foto_url']
            : fotoDefecto;

        listaTemporal.add(
          Persona(doc.id, nombre, telefono, urlFinal),
        );
      }

      if (mounted) {
        setState(() {
          personas = listaTemporal;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar personas: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void agregarPersona() {
    TextEditingController nombreController = TextEditingController();
    TextEditingController telefonoController = TextEditingController();
    
    Uint8List? webImageBytes;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder( 
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF0F4F8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                "Agregar persona",
                style: TextStyle(color: Color(0xFF3B6E8C), fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
                        if (imagen != null) {
                          var bytes = await imagen.readAsBytes();
                          setDialogState(() {
                            webImageBytes = bytes;
                          });
                        }
                      },
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: const Color(0xFF3B6E8C).withValues(alpha: 0.2),
                        backgroundImage: webImageBytes != null
                            ? MemoryImage(webImageBytes!)
                            : null,
                        child: webImageBytes == null
                            ? const Icon(Icons.camera_alt, size: 35, color: Color(0xFF3B6E8C))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Toca para elegir foto de tu PC/Teléfono",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: "Nombre",
                        hintText: "Ingrese el nombre",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF3B6E8C), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Teléfono",
                        hintText: "Ingrese el número",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF3B6E8C), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B6E8C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (nombreController.text.trim().isNotEmpty && telefonoController.text.trim().isNotEmpty) {
                      try {
                        String? supervisorUid = FirebaseAuth.instance.currentUser?.uid;
                        if (supervisorUid == null) throw Exception("No hay sesión activa");

                        String nombre = nombreController.text.trim();
                        String telefono = telefonoController.text.trim();
                        
                        // ID numérico limpio para la colección de dispositivos
                        String telefonoId = telefono.replaceAll(RegExp(r'\D'), '');

                        String fotoAGuardar = "https://ui-avatars.com/api/?name=${Uri.encodeComponent(nombre)}&background=3B6E8C&color=fff&size=128";

                        // 1. Guardar persona en 'personas_asignadas'
                        DocumentReference docRef = await FirebaseFirestore.instance.collection('personas_asignadas').add({
                          'nombre': nombre,
                          'telefono': telefono,
                          'telefono_id': telefonoId,
                          'foto_url': fotoAGuardar, 
                          'supervisor_id': supervisorUid, 
                          'fecha_creacion': FieldValue.serverTimestamp(),
                        });

                        // 2. Alta inicial en 'dispositivos' para las nuevas personas
                        if (telefonoId.isNotEmpty) {
                          await FirebaseFirestore.instance.collection('dispositivos').doc(telefonoId).set({
                            'nombre': nombre,
                            'telefono': telefono,
                            'lat': -34.5947, // Ubicación inicial por defecto (Colegio Aletheia)
                            'lng': -58.4116,
                            'creado_el': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                        }

                        if (!mounted) return;

                        setState(() {
                          personas.add(Persona(docRef.id, nombre, telefono, fotoAGuardar));
                        });

                        Navigator.pop(dialogContext);

                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
                  child: const Text("Agregar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Persona> personasFiltradas = personas.where((persona) {
      return persona.nombre.toLowerCase().contains(busqueda.toLowerCase()) || persona.telefono.contains(busqueda);
    }).toList();

    personasFiltradas.sort((a, b) => a.nombre.compareTo(b.nombre));

    return Scaffold(
      backgroundColor: const Color(0xFF98B4CE), 
      appBar: AppBar(
        title: const Text("Personas Asignadas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF3B6E8C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar persona o teléfono...",
                hintStyle: const TextStyle(color: Colors.black45),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF3B6E8C)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onChanged: (texto) => setState(() => busqueda = texto),
            ),
          ),
          Expanded(
            child: personasFiltradas.isEmpty
                ? const Center(
                    child: Text(
                      "No se encontraron personas",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: personasFiltradas.length,
                    itemBuilder: (context, index) {
                      Persona persona = personasFiltradas[index];
                      String avatarAlternativo = "https://ui-avatars.com/api/?name=${Uri.encodeComponent(persona.nombre)}&background=3B6E8C&color=fff&size=128";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: ClipOval(
                            child: Image.network(
                              persona.fotoUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.network(avatarAlternativo, width: 50, height: 50),
                            ),
                          ),
                          title: Text(
                            persona.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          ),
                          subtitle: Text(
                            persona.telefono,
                            style: const TextStyle(color: Colors.black54, fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () async {
                              try {
                                await FirebaseFirestore.instance.collection('personas_asignadas').doc(persona.id).delete();
                                
                                if (mounted) {
                                  setState(() {
                                    personas.removeWhere((p) => p.id == persona.id);
                                  });
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.redAccent),
                                  );
                                }
                              }
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => Mapa(persona: persona)),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B6E8C),
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: agregarPersona,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}