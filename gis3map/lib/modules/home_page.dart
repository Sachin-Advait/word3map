// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:isolate';
import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'package:word3map/constants/app_strings.dart';
import 'package:word3map/modules/three_word_algo.dart';
import 'package:word3map/modules/grid_isolate.dart';
import 'package:word3map/modules/home_bottom.dart';
import 'package:word3map/modules/search_card.dart';
import 'package:word3map/routes/routes.dart';

// Grid calculation result
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.notificationThreeWord});

  final String? notificationThreeWord;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AppleMapController mapController;
  LatLng? currentLocation;
  LatLng? selectedLocation;
  String? threeWordAddress;
  MapType _currentMapType = MapType.standard;
  Set<Annotation> annotations = {};
  Set<Circle> circles = {};
  bool showNavigateIcon = false;
  TextEditingController searchController = TextEditingController();
  Set<Polyline> gridLines = {};
  StreamSubscription? _sub;

  // Isolate-related variables
  Isolate? _gridIsolate;
  ReceivePort? _gridReceivePort;
  SendPort? _gridSendPort;
  CameraPosition? _lastGridPosition;
  CameraPosition? _pendingGridPosition;
  bool _isolateInitialized = false;

  @override
  void initState() {
    _initializeGridIsolate();
    _getCurrentLocation();
    _handleIncomingLinks();
    _loadGridIcon();
    super.initState();
  }

  Future<void> _initializeGridIsolate() async {
    if (_isolateInitialized) return;

    _gridReceivePort = ReceivePort();

    // Listen for both SendPort and GridCalculationResult
    _gridReceivePort!.listen((dynamic data) {
      if (data is SendPort) {
        _gridSendPort = data;
        _isolateInitialized = true;
        debugPrint('Grid isolate communication established');

        // If there's a pending position, send it now that isolate is ready
        if (_pendingGridPosition != null) {
          _generateGridLinesInIsolate(_pendingGridPosition!);
        }
      } else if (data is GridCalculationResult) {
        // _isGridComputing = false;
        debugPrint('Received grid result with ${data.gridLines.length} lines');

        // Always update with the latest result, but check if we have newer pending position
        if (mounted) {
          setState(() {
            gridLines = data.gridLines;
          });
        }
        _lastGridPosition = data.position;

        // If there's a newer pending position, process it
        if (_pendingGridPosition != null &&
            (_pendingGridPosition!.target.latitude !=
                    data.position.target.latitude ||
                _pendingGridPosition!.target.longitude !=
                    data.position.target.longitude ||
                _pendingGridPosition!.zoom != data.position.zoom)) {
          _generateGridLinesInIsolate(_pendingGridPosition!);
        } else {
          _pendingGridPosition = null;
        }
      }
    });

    try {
      _gridIsolate = await Isolate.spawn(
        gridCalculationIsolateEntryPoint,
        _gridReceivePort!.sendPort,
      );
    } catch (e) {
      debugPrint('Failed to create grid isolate: $e');
      // _isGridComputing = false;
    }
  }

  // bool _isGridComputing = false;
  static const double _gridUpdateThreshold = 0.0003;

  void _generateGridLinesInIsolate(CameraPosition position) {
    // Check if we need to update the grid (avoid unnecessary calculations)
    if (_lastGridPosition != null) {
      double latDiff =
          (position.target.latitude - _lastGridPosition!.target.latitude).abs();
      double lngDiff =
          (position.target.longitude - _lastGridPosition!.target.longitude)
              .abs();
      double zoomDiff = (position.zoom - _lastGridPosition!.zoom).abs();

      // Only update if there's significant movement or zoom change
      if (latDiff < _gridUpdateThreshold &&
          lngDiff < _gridUpdateThreshold &&
          zoomDiff < 0.3) {
        return;
      }
    }

    // if (_isGridComputing) {
    _pendingGridPosition = position;
    // return;
    // }

    // _isGridComputing = true;
    _pendingGridPosition = position;

    if (_gridSendPort != null && _isolateInitialized) {
      _gridSendPort!.send(position);
      debugPrint(
        'Sent position to isolate: ${position.target.latitude}, ${position.target.longitude}, zoom: ${position.zoom}',
      );
    } else if (!_isolateInitialized) {
      if (_isolateInitialized) {
        _generateGridLinesInIsolate(position);
      }
      // else {
      //   _isGridComputing = false; // Reset flag if still not initialized
      // }
    }
    // else {
    //   _isGridComputing = false; // Reset flag if send port is not available
    // }
  }

  void _onCameraMove(CameraPosition position) {
    _generateGridLinesInIsolate(position);

    if (selectedLocation != currentLocation && !showNavigateIcon) {
      setState(() {
        showNavigateIcon = true;
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _gridReceivePort?.close();
    _gridIsolate?.kill(priority: Isolate.immediate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Replace your existing AppleMap with this:
                AppleMap(
                  onMapCreated: (controller) {
                    mapController = controller;
                    if (widget.notificationThreeWord != null) {
                      _handleThreeWordAddress(widget.notificationThreeWord!);
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: currentLocation!,
                    zoom: 19.5,
                  ),
                  onTap: (latLng) {
                    String code = latLonToThreeWords(
                      latLng.latitude,
                      latLng.longitude,
                      uniqueWordlist,
                    );
                    setState(() {
                      selectedLocation = latLng;
                      threeWordAddress = code;
                      showNavigateIcon = selectedLocation != currentLocation;
                      _updateMarkersAndCircles();
                    });
                  },
                  onCameraMove: _onCameraMove,
                  mapType: _currentMapType,
                  annotations: annotations,
                  circles: circles,
                  polylines: gridLines, // Add this line for grid
                  minMaxZoomPreference: MinMaxZoomPreference(0, 20),
                ),

                // Your existing search card and notification buttons
                Positioned(
                  top: 65,
                  child: Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width - 85,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: Colors.black12,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: SearchCard(
                          searchController: searchController,
                          suffixIcon: searchController.text.isNotEmpty
                              ? Container(
                                  alignment: Alignment.centerRight,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    constraints: BoxConstraints(
                                      minHeight: 24,
                                      minWidth: 24,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (searchController.text.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            searchController.clear();
                                            FocusManager.instance.primaryFocus!
                                                .unfocus();
                                          });
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          size: 20,
                                        ),
                                      ),
                                    const SizedBox(width: 5),
                                  ],
                                ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.NOTIFICATION,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 10,
                                color: Colors.black12,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.only(right: 14),
                          child: Icon(
                            Icons.notifications,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          prefs.setString("userId", "");
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.LOGIN,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 10,
                                color: Colors.black12,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.logout,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Navigate to selected location button
                if (showNavigateIcon && selectedLocation != null)
                  Positioned(
                    bottom: 140,
                    right: 20,
                    child: GestureDetector(
                      onTap: () async {
                        if (selectedLocation != null) {
                          mapController.moveCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: selectedLocation!,
                                zoom: 19.5,
                              ),
                            ),
                          );
                          setState(() {
                            showNavigateIcon = false;
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.orange,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.navigation, color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                // Current location button
                Positioned(
                  bottom: 80,
                  right: 20,
                  child: GestureDetector(
                    onTap: () async {
                      Position pos = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );
                      final latLng = LatLng(pos.latitude, pos.longitude);
                      mapController.moveCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(target: latLng, zoom: 19.5),
                        ),
                      );
                      setState(() {
                        currentLocation = latLng;
                        selectedLocation = latLng;
                        threeWordAddress = latLonToThreeWords(
                          pos.latitude,
                          pos.longitude,
                          uniqueWordlist,
                        );
                        showNavigateIcon = false;
                        _updateMarkersAndCircles();
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.my_location, color: Colors.indigo),
                      ),
                    ),
                  ),
                ),

                // Map type toggle button
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_currentMapType == MapType.standard) {
                          _currentMapType = MapType.satellite;
                        } else if (_currentMapType == MapType.satellite) {
                          _currentMapType = MapType.hybrid;
                        } else {
                          _currentMapType = MapType.standard;
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.map, color: Colors.indigo),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (threeWordAddress != null)
            HomeBottom(
              threeWordAddress: threeWordAddress!,
              currentLocation: selectedLocation,
            ),
        ],
      ),
    );
  }

  void _handleThreeWordAddress(String words) {
    final latLon = threeWordsToLatLon(words, uniqueWordlist);

    if (latLon['lat'] == 0.0 && latLon['lon'] == 0.0) {
      debugPrint("Invalid 3-word address: $words");
      return;
    }

    final latLng = LatLng(latLon['lat']!, latLon['lon']!);

    setState(() {
      selectedLocation = latLng;
      threeWordAddress = words;
      showNavigateIcon = true;
      _updateMarkersAndCircles();
    });

    mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 19.5),
      ),
    );
  }

  late BitmapDescriptor gridIcon;

  Future<void> _loadGridIcon() async {
    gridIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(4, 4), devicePixelRatio: 3),
      'assets/images/logo30.png',
    );
    setState(() {});
  }

  void _updateMarkersAndCircles() async {
    setState(() {
      annotations.clear();
      circles.clear();

      // Add current location marker (blue dot style)
      if (currentLocation != null) {
        annotations.add(
          Annotation(
            annotationId: AnnotationId('current_location'),
            position: currentLocation!,
            infoWindow: const InfoWindow(title: 'Current Location'),
            icon: BitmapDescriptor.defaultAnnotationWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        );

        // Add accuracy circle around current location
        circles.add(
          Circle(
            circleId: CircleId('current_location_circle'),
            center: currentLocation!,
            radius: 20,
            fillColor: Colors.blue.withOpacity(0.1),
            strokeColor: Colors.blue.withOpacity(0.3),
            strokeWidth: 1,
          ),
        );
      }

      // Add selected location marker if different from current location
      if (selectedLocation != null && selectedLocation != currentLocation) {
        annotations.add(
          Annotation(
            annotationId: AnnotationId('selected_location'),
            position: selectedLocation!,
            infoWindow: InfoWindow(
              title: 'Selected Location',
              snippet: threeWordAddress ?? '',
            ),
            icon: BitmapDescriptor.defaultAnnotationWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied, open settings.');
      await Geolocator.openAppSettings();
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentLocation = LatLng(pos.latitude, pos.longitude);
      selectedLocation =
          currentLocation; // Initially selected location is current location
      threeWordAddress = latLonToThreeWords(
        pos.latitude,
        pos.longitude,
        uniqueWordlist,
      );

      _updateMarkersAndCircles();
      showNavigateIcon = false; // Hide navigate icon initially
    });

    debugPrint(pos.toString());
  }

  void _handleIncomingLinks() {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.host == 'location') {
        final words = uri.queryParameters['words'];
        if (words != null) {
          print('Received deep link words: $words'); // Debug print
          final latLon = threeWordsToLatLon(words, uniqueWordlist);

          // Add validation
          if (latLon['lat'] == 0.0 && latLon['lon'] == 0.0) {
            print('Failed to decode three words: $words');
            return; // Don't process invalid coordinates
          }

          final latLng = LatLng(latLon['lat']!, latLon['lon']!);

          setState(() {
            selectedLocation = latLng;
            threeWordAddress = words;
            showNavigateIcon = true;
            mapController.moveCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: latLng, zoom: 19.5),
              ),
            );

            _updateMarkersAndCircles();
            // Move camera to the shared location
          });
        }
      }
    });
  }
}
