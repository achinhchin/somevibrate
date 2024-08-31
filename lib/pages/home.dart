import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final mapController = MapController();
  Position? position;
  bool locatonPermission = false;
  bool track = true;
  bool show = false;
  List<double>? mrk;
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  @override
  void initState() {
    super.initState();
    updateLocation();
  }

  Future<void> updateLocation() async {
    if (locatonPermission) {
      // check location Permission of your phone
      Geolocator.getPositionStream().listen((ps) {
        // get stream
        setState(() {
          position = ps;
        });
        if (track) {
          mapController.move(
            LatLng(ps.latitude, ps.longitude),
            mapController.camera.zoom,
          );
        }
        if (mrk != null &&
            Geolocator.distanceBetween(
                    mrk![1], mrk![2], ps.latitude, ps.longitude) <=
                mrk![0] &&
            !show) alert();
      });
    } else {
      await getLocationPermission(); // get locaiton Permission
      Future.delayed(const Duration(seconds: 1), updateLocation);
    }
  }

  void alert() {
    show = true;
    Navigator.push(
      context,
      DialogRoute(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            Timer pd = Timer.periodic(
              const Duration(seconds: 2),
              (t) => HapticFeedback.vibrate(),
            );
            return AlertDialog(
              title: const Text('You have reached your destination.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    show = false;
                    mrk = null;
                    pd.cancel();
                    Navigator.pop(context);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: const Text('close'),
                )
              ],
            );
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(13.7563, 100.5018),
        initialZoom: 16,
        onTap: (tapPosition, point) {
          setState(() {
            mrk = [100, point.latitude, point.longitude];
          });
        },
      ),
      mapController: mapController,
      children: [
        TileLayer(
          // Display map tiles from any source
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
          userAgentPackageName: 'com.achinhchin.somevibrate',
          maxNativeZoom:
              25, // Scale tiles when the server doesn't support higher zoom levels
          // And many more recommended properties!
        ),
        if (position != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(position!.latitude, position!.longitude),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.red,
                  size: 33,
                ),
              ),
            ],
          ),
        if (mrk != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: LatLng(mrk![1], mrk![2]),
                radius: mrk![0],
                useRadiusInMeter: true,
                color: Colors.red.withOpacity(.5),
                borderColor: Colors.red,
                borderStrokeWidth: 5,
              )
            ],
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (mrk != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        onPressed: () => setState(() {
                          mrk![0] += 25;
                        }),
                        backgroundColor:
                            Theme.of(context).colorScheme.tertiaryContainer,
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      FloatingActionButton(
                        onPressed: () {
                          if (mrk![0] > 50) {
                            setState(() {
                              mrk![0] -= 25;
                            });
                          }
                        },
                        backgroundColor:
                            Theme.of(context).colorScheme.tertiaryContainer,
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                const SizedBox(
                  height: 10,
                ),
                if (mrk != null)
                  FloatingActionButton.extended(
                    backgroundColor:
                        Theme.of(context).colorScheme.tertiaryContainer,
                    onPressed: () => setState(() => mrk = null),
                    label: const Text('Remove notification point'),
                    icon: const Icon(Icons.remove_circle_outlined),
                  ),
                const SizedBox(
                  height: 10,
                ),
                FloatingActionButton.extended(
                  onPressed: () => setState(
                    () {
                      track = !track;
                    },
                  ),
                  icon: track
                      ? const Icon(Icons.location_searching_rounded)
                      : const Icon(Icons.location_disabled_rounded),
                  label: const Text('Track your location'),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Future<void> getLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    locatonPermission = true;
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
