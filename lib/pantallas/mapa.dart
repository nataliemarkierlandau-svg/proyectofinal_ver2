
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_application_1/pantallas/sumar_personas.dart';

class Mapa extends StatefulWidget {
  final Persona persona;

  const Mapa({
    super.key,
    required this.persona,
  });

  @override
  State<Mapa> createState() => MapaState();
}

class MapaState extends State<Mapa> {
  final MapController _mapController = MapController();
  final Distance _distanceCalculator = const Distance();

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  StreamSubscription<DatabaseEvent>? _suscripcionUbicacion;

  double radiusMeters = 500;
  int rangoCuadras = 5;

  bool cargandoUbicacion = true;
  bool sinDispositivo = false;
  bool seleccionandoCentro = false;
  bool _estaFueraDeRango = false;

  String? lugarNombre;
  String? dispositivoKey;

  LatLng? centroRango;
  LatLng? ubicacionActual;
  LatLng? centroTemporal;

  final String telefonoObjetivo = "1133398718";

  @override
  void initState() {
    super.initState();
    _iniciarSistema();
  }

  Future<void> _iniciarSistema() async {
    try {
      await _inicializarNotificaciones();

      if (!mounted) return;

      _escucharUbicacionEnTiempoReal();
    } catch (e) {
      debugPrint('Error al iniciar notificaciones: $e');

      if (mounted) {
        _escucharUbicacionEnTiempoReal();
      }
    }
  }

  // INICIALIZAR NOTIFICACIONES

  Future<void> _inicializarNotificaciones() async {
    flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
      'alerta_movilidad_channel',
      'Alertas de Movilidad',
      description:
          'Notificaciones cuando una persona sale del rango permitido',
      importance: Importance.max,
      playSound: true,
    );

    final AndroidFlutterLocalNotificationsPlugin?
        androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);

      await androidImplementation.requestNotificationsPermission();
    }
  }

  // MOSTRAR NOTIFICACIÓN EN EL CELULAR

  Future<void> _mostrarNotificacionCelular() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'alerta_movilidad_channel',
      'Alertas de Movilidad',
      channelDescription:
          'Notificaciones cuando una persona sale del rango permitido',
      importance: Importance.max,
      priority: Priority.high,
      ticker: '¡Alerta de Movilidad!',
      color: Colors.redAccent,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      '¡ALERTA DE MOVILIDAD!',
      '${widget.persona.nombre} ha salido del rango permitido.',
      notificationDetails,
    );
  }

  // ESCUCHAR UBICACIÓN EN TIEMPO REAL

  void _escucharUbicacionEnTiempoReal() {
    String telefonoActual =
        widget.persona.telefono.replaceAll(RegExp(r'\D'), '');

    if (!telefonoActual.endsWith(telefonoObjetivo)) {
      setState(() {
        cargandoUbicacion = false;
        sinDispositivo = true;
      });
      return;
    }

    DatabaseReference ref =
        FirebaseDatabase.instance.ref('coordenadas');

    _suscripcionUbicacion = ref.onValue.listen(
      (event) async {
        if (!mounted) return;

        final snapshot = event.snapshot;

        if (snapshot.exists && snapshot.value != null) {
          Map<dynamic, dynamic> values =
              snapshot.value as Map<dynamic, dynamic>;

          Map<dynamic, dynamic>? dispositivoData;
          String? encontradaKey;

          for (var entry in values.entries) {
            if (entry.value is! Map) continue;

            var dataMap = Map<String, dynamic>.from(
              entry.value as Map<dynamic, dynamic>,
            );

            double? latTest =
                (dataMap['latitud'] as num?)?.toDouble();

            double? lngTest =
                (dataMap['longitud'] as num?)?.toDouble();

            if (latTest != null &&
                lngTest != null &&
                latTest < 0 &&
                lngTest < 0) {
              dispositivoData = dataMap;
              encontradaKey = entry.key.toString();
              break;
            }
          }

          if (dispositivoData == null && values.isNotEmpty) {
            var firstEntry = values.entries.first;

            if (firstEntry.value is Map) {
              dispositivoData = Map<String, dynamic>.from(
                firstEntry.value as Map<dynamic, dynamic>,
              );

              encontradaKey = firstEntry.key.toString();
            }
          }

          if (dispositivoData == null || encontradaKey == null) {
            setState(() {
              cargandoUbicacion = false;
              sinDispositivo = true;
            });
            return;
          }

          dispositivoKey = encontradaKey;

          double latActual =
              (dispositivoData['latitud'] as num?)?.toDouble() ??
                  -34.6037;

          if (latActual > 0) {
            latActual = -latActual;
          }

          double lngActual =
              (dispositivoData['longitud'] as num?)?.toDouble() ??
                  -58.3816;

          if (lngActual > 0) {
            lngActual = -lngActual;
          }

          String? lugar = dispositivoData['lugar'] as String?;

          int cuadrasGuardadas =
              (dispositivoData['rango_cuadras'] as num?)?.toInt() ?? 5;

          double metrosGuardados =
              (dispositivoData['rango_metros'] as num?)?.toDouble() ??
                  (cuadrasGuardadas * 100.0);

          double? centroLatStored =
              (dispositivoData['centro_lat'] as num?)?.toDouble();

          double? centroLngStored =
              (dispositivoData['centro_lng'] as num?)?.toDouble();

          LatLng nuevaUbicacion = LatLng(latActual, lngActual);

          LatLng nuevoCentro;

          if (centroLatStored != null &&
              centroLngStored != null) {
            if (centroLatStored > 0) {
              centroLatStored = -centroLatStored;
            }

            if (centroLngStored > 0) {
              centroLngStored = -centroLngStored;
            }

            nuevoCentro = LatLng(
              centroLatStored,
              centroLngStored,
            );
          } else {
            nuevoCentro = nuevaUbicacion;

            await _guardarCentroEnFirebase(
              nuevoCentro.latitude,
              nuevoCentro.longitude,
            );
          }

          // COMPROBAR SI SALIÓ DEL RANGO

          double distanciaMetros = _distanceCalculator.as(
            LengthUnit.Meter,
            nuevoCentro,
            nuevaUbicacion,
          );

          if (distanciaMetros > metrosGuardados) {
            if (!_estaFueraDeRango && mounted) {
              _estaFueraDeRango = true;

              _mostrarAlertaFueraDeRango();

              await _mostrarNotificacionCelular();
            }
          } else {
            _estaFueraDeRango = false;
          }

          bool primeraCarga = cargandoUbicacion;

          setState(() {
            ubicacionActual = nuevaUbicacion;
            centroRango = nuevoCentro;
            rangoCuadras = cuadrasGuardadas;
            radiusMeters = metrosGuardados;
            lugarNombre = lugar;
            cargandoUbicacion = false;
            sinDispositivo = false;
          });

          if (primeraCarga) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _mapController.move(nuevaUbicacion, 15.0);
              }
            });
          }
        } else {
          setState(() {
            cargandoUbicacion = false;
            sinDispositivo = true;
          });
        }
      },
      onError: (error) {
        debugPrint('Error escuchando Firebase: $error');

        if (mounted) {
          setState(() {
            cargandoUbicacion = false;
            sinDispositivo = true;
          });
        }
      },
    );
  }

  // GUARDAR CENTRO EN FIREBASE

  Future<void> _guardarCentroEnFirebase(
    double lat,
    double lng,
  ) async {
    if (dispositivoKey == null) return;

    try {
      DatabaseReference dispositivoRef =
          FirebaseDatabase.instance.ref(
        'coordenadas/$dispositivoKey',
      );

      await dispositivoRef.update({
        'centro_lat': lat,
        'centro_lng': lng,
      });
    } catch (e) {
      debugPrint('Error al guardar centro: $e');
    }
  }

  // ALERTA VISUAL DENTRO DE LA APLICACIÓN

  void _mostrarAlertaFueraDeRango() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¡ALERTA DE MOVILIDAD!',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.persona.nombre} ha salido del rango permitido.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.95),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 65),
      ),
    );
  }

  // GUARDAR RANGO EN FIREBASE

  Future<void> _guardarRangoFirebase(int cuadras) async {
    if (dispositivoKey == null) return;

    try {
      double metros = cuadras * 100.0;

      DatabaseReference dispositivoRef =
          FirebaseDatabase.instance.ref(
        'coordenadas/$dispositivoKey',
      );

      await dispositivoRef.update({
        'rango_cuadras': cuadras,
        'rango_metros': metros,
        'ultima_actualizacion_rango': ServerValue.timestamp,
      });

      if (mounted) {
        setState(() {
          rangoCuadras = cuadras;
          radiusMeters = metros;
          _estaFueraDeRango = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rango establecido en $cuadras cuadras para ${widget.persona.nombre}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 65),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar rango: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 65),
          ),
        );
      }
    }
  }

  // DIÁLOGO PARA CAMBIAR EL CENTRO

  void _mostrarDialogoCambiarCentro() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 6,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B6E8C)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pin_drop_rounded,
                  color: Color(0xFF3B6E8C),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Cambiar Centro',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B6E8C),
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            '¿Deseas cambiar el centro del rango?',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: const Text(
                'No',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B6E8C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  seleccionandoCentro = true;
                  centroTemporal = centroRango ?? ubicacionActual;
                });
              },
              child: const Text(
                'Sí',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // DIÁLOGO PARA DELIMITAR EL RANGO

  void _mostrarDialogoDelimitarRango() {
    TextEditingController cuadrasController =
        TextEditingController(
      text: rangoCuadras.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B6E8C)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: Color(0xFF3B6E8C),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tamaño del Rango',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B6E8C),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingresa las cuadras a la redonda permitidas para ${widget.persona.nombre}:',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cuadrasController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Cuadras a la redonda',
                  suffixText: 'cuadras',
                  filled: true,
                  fillColor: const Color(0xFFF0F4F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF3B6E8C),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B6E8C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                int? nuevasCuadras = int.tryParse(
                  cuadrasController.text.trim(),
                );

                if (nuevasCuadras != null && nuevasCuadras > 0) {
                  Navigator.pop(dialogContext);

                  await _guardarRangoFirebase(nuevasCuadras);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Por favor, ingresa un número de cuadras válido',
                      ),
                      backgroundColor: Colors.orangeAccent,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.fromLTRB(20, 16, 20, 65),
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // LIBERAR RECURSOS

  @override
  void dispose() {
    _suscripcionUbicacion?.cancel();
    super.dispose();
  }

  // CONSTRUIR PANTALLA

  @override
  Widget build(BuildContext context) {
    double distanciaActual =
        (centroRango != null && ubicacionActual != null)
            ? _distanceCalculator.as(
                LengthUnit.Meter,
                centroRango!,
                ubicacionActual!,
              )
            : 0;

    bool fueraDeZona = distanciaActual > radiusMeters;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa en vivo: ${widget.persona.nombre}'),
        backgroundColor: const Color(0xFF3B6E8C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: cargandoUbicacion
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : sinDispositivo
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_off_rounded,
                            size: 64,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Sin dispositivo vinculado',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B6E8C),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${widget.persona.nombre} (${widget.persona.telefono}) no tiene ningún dispositivo GPS configurado en el sistema.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // MAPA

                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: ubicacionActual ??
                            const LatLng(-34.6037, -58.3816),
                        initialZoom: 15.0,
                        onTap: seleccionandoCentro
                            ? (tapPosition, latLng) {
                                setState(() {
                                  centroTemporal = latLng;
                                });
                              }
                            : null,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.flutter_application_1',
                        ),

                        // CÍRCULO DEL RANGO

                        if (!seleccionandoCentro &&
                            centroRango != null)
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: centroRango!,
                                radius: radiusMeters,
                                useRadiusInMeter: true,
                                color: fueraDeZona
                                    ? Colors.red.withValues(alpha: 0.25)
                                    : const Color(0xFF3B6E8C)
                                        .withValues(alpha: 0.2),
                                borderColor: fueraDeZona
                                    ? Colors.red
                                    : const Color(0xFF3B6E8C),
                                borderStrokeWidth: 3,
                              ),
                            ],
                          ),

                        // CÍRCULO TEMPORAL AL CAMBIAR CENTRO

                        if (seleccionandoCentro &&
                            centroTemporal != null)
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: centroTemporal!,
                                radius: radiusMeters,
                                useRadiusInMeter: true,
                                color: Colors.orange
                                    .withValues(alpha: 0.25),
                                borderColor: Colors.orange,
                                borderStrokeWidth: 3,
                              ),
                            ],
                          ),

                        // MARCADOR DE LA PERSONA

                        if (ubicacionActual != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: ubicacionActual!,
                                width: 50,
                                height: 50,
                                child: CircleAvatar(
                                  backgroundColor: fueraDeZona
                                      ? Colors.red
                                      : const Color(0xFF3B6E8C),
                                  child: ClipOval(
                                    child: Image.network(
                                      widget.persona.fotoUrl,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // MARCADOR DEL NUEVO CENTRO

                              if (seleccionandoCentro &&
                                  centroTemporal != null)
                                Marker(
                                  point: centroTemporal!,
                                  width: 50,
                                  height: 50,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.orange,
                                    size: 45,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),

                    // BOTONES SUPERIORES

                    if (!seleccionandoCentro)
                      Positioned(
                        top: 20,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // CAMBIAR CENTRO

                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: _mostrarDialogoCambiarCentro,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color(0xFF3B6E8C),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.pin_drop_rounded,
                                        color: Color(0xFF3B6E8C),
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Cambiar Centro',
                                        style: TextStyle(
                                          color: Color(0xFF3B6E8C),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // DELIMITAR RANGO

                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: _mostrarDialogoDelimitarRango,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3B6E8C),
                                        Color(0xFF2C536B),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF3B6E8C)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.radar_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delimitar Rango',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // MODO DE SELECCIÓN DEL CENTRO

                    if (seleccionandoCentro)
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.orange,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.touch_app_rounded,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Toca en el mapa para marcar el nuevo centro',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    seleccionandoCentro = false;
                                    centroTemporal = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                    // PANEL INFERIOR

                    Positioned(
                      bottom: 24,
                      left: 20,
                      right: 20,
                      child: seleccionandoCentro
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              onPressed: centroTemporal == null
                                  ? null
                                  : () async {
                                      await _guardarCentroEnFirebase(
                                        centroTemporal!.latitude,
                                        centroTemporal!.longitude,
                                      );

                                      if (!mounted) return;

                                      setState(() {
                                        centroRango = centroTemporal;
                                        seleccionandoCentro = false;
                                        centroTemporal = null;
                                        _estaFueraDeRango = false;
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '¡Nuevo centro de rango establecido con éxito!',
                                          ),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(20),
                                            ),
                                          ),
                                          margin: EdgeInsets.fromLTRB(
                                            20,
                                            16,
                                            20,
                                            65,
                                          ),
                                        ),
                                      );
                                    },
                              child: const Text(
                                'Confirmar Nuevo Centro',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: fueraDeZona
                                    ? Colors.red.withValues(alpha: 0.95)
                                    : Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: fueraDeZona
                                      ? Colors.redAccent
                                      : const Color(0xFF3B6E8C)
                                          .withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.08,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    fueraDeZona
                                        ? Icons.warning_rounded
                                        : Icons.location_on_outlined,
                                    color: fueraDeZona
                                        ? Colors.white
                                        : const Color(0xFF3B6E8C),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          fueraDeZona
                                              ? '¡FUERA DE RANGO PERMITIDO!'
                                              : 'LUGAR: ${(lugarNombre ?? 'Desconocido').toUpperCase()}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: fueraDeZona
                                                ? Colors.white70
                                                : Colors.black45,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          fueraDeZona
                                              ? 'Fuera del perímetro establecido'
                                              : '$rangoCuadras cuadras de radio (${radiusMeters.toInt()} m)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: fueraDeZona
                                                ? Colors.white
                                                : const Color(0xFF3B6E8C),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}