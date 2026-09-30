import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_1/pantallas/sumar_personas.dart';

class Mapa extends StatefulWidget {
  final Persona persona;

  const Mapa({
    super.key,
    required this.persona,
  });

  @override
  State<Mapa> createState() => _MapaState();
}

class _MapaState extends State<Mapa> {
  // Coordenada de respaldo por si el GPS falla o tarda demasiado, para que la app NUNCA se quede congelada
  LatLng _ubicacionActual = const LatLng(-34.6037, -58.3816); 
  bool _cargando = true;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _posicionSubscription;

  @override
  void initState() {
    super.initState();
    _iniciarSeguimientoGPS();
  }

  @override
  void dispose() {
    _posicionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _iniciarSeguimientoGPS() async {
    try {
      // 1. Validar si el servicio de ubicación está activo
      bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        _quitarCargaConFallback("El GPS está desactivado.");
        return;
      }

      // 2. Comprobar permisos con un límite de tiempo por seguridad
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
          _quitarCargaConFallback("Permisos de ubicación denegados.");
          return;
        }
      }

      // 3. Intentar obtener una posición inicial rápido (con un timeout de 5 segundos para que no se cuelgue)
      Position? posicionInicial;
      try {
        posicionInicial = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Usamos medium para que responda más rápido
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Si tarda mucho getCurrentPosition, intentamos usar la última conocida
        posicionInicial = await Geolocator.getLastKnownPosition();
      }

      if (posicionInicial != null) {
        setState(() {
          _ubicacionActual = LatLng(posicionInicial!.latitude, posicionInicial.longitude);
        });
      }

      // Quitamos la pantalla de carga pase lo que pase para que el mapa renderice
      setState(() {
        _cargando = false;
      });

      // 4. Iniciar el stream en tiempo real
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, 
      );

      _posicionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position posicion) {
          final nuevaPos = LatLng(posicion.latitude, posicion.longitude);
          setState(() {
            _ubicacionActual = nuevaPos;
          });
          // Mueve el mapa en tiempo real
          _mapController.move(nuevaPos, _mapController.camera.zoom);
        },
        onError: (e) {
          debugPrint("Error en el stream de ubicación: $e");
        },
      );
    } catch (e) {
      _quitarCargaConFallback("Error al obtener ubicación: $e");
    }
  }

  void _quitarCargaConFallback(String mensaje) {
    if (mounted) {
      setState(() {
        _cargando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ubicación de ${widget.persona.nombre}"),
        backgroundColor: const Color(0xFF3B6E8C),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B6E8C)),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _ubicacionActual,
                initialZoom: 16.0,
                onMapReady: () {
                  _mapController.move(_ubicacionActual, 16.0);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flutter_application_1',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _ubicacionActual,
                      width: 80,
                      height: 80,
                      child: const Column(
                        children: [
                          Icon(
                            Icons.location_pin,
                            color: Colors.redAccent,
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}