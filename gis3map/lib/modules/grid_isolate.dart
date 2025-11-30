import 'dart:isolate';
import 'dart:math';

import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/material.dart';

// ignore: constant_identifier_names
const double GRID_SIZE_METERS = 3.0;

class GridCalculationResult {
  final Set<Polyline> gridLines;
  final CameraPosition position;

  GridCalculationResult({required this.gridLines, required this.position});
}

void gridCalculationIsolateEntryPoint(SendPort mainSendPort) {
  final isolateReceivePort = ReceivePort();
  mainSendPort.send(isolateReceivePort.sendPort);

  isolateReceivePort.listen((dynamic data) {
    if (data is CameraPosition) {
      gridCalculationIsolate(mainSendPort, data);
    }
  });
}

// Replace your current _gridCalculationIsolate function with this:

void gridCalculationIsolate(SendPort mainSendPort, CameraPosition position) {
  // Lower the zoom threshold so grid appears earlier
  const double gridZoomThreshold = 19;

  if (position.zoom < gridZoomThreshold) {
    mainSendPort.send(
      GridCalculationResult(gridLines: <Polyline>{}, position: position),
    );
    return;
  }

  // Calculate grid parameters
  double centerLat = position.target.latitude;
  double centerLng = position.target.longitude;
  double zoom = position.zoom;

  // REDUCED range for better performance - adjust these values as needed
  double latRange = 0.0006 * (22 - zoom);
  double lngRange = 0.0006 * (22 - zoom);

  // Define grid spacing based on GRID_SIZE_METERS
  double effectiveGridSize = GRID_SIZE_METERS * (21 - zoom);
  double latSpacing = effectiveGridSize / 111000;
  double lngSpacing = effectiveGridSize / (111000 * cos(centerLat * pi / 180));

  // Calculate grid bounds with reduced range
  double minLat = centerLat - latRange;
  double maxLat = centerLat + latRange;
  double minLng = centerLng - lngRange;
  double maxLng = centerLng + lngRange;

  // Align to grid
  minLat = (minLat / latSpacing).floor() * latSpacing;
  maxLat = (maxLat / latSpacing).ceil() * latSpacing;
  minLng = (minLng / lngSpacing).floor() * lngSpacing;
  maxLng = (maxLng / lngSpacing).ceil() * lngSpacing;

  // Calculate grid appearance
  int gridWidth = 2;

  Set<Polyline> newGridLines = {};
  int lineId = 0;

  // Generate horizontal lines (constant latitude)
  for (double lat = minLat; lat <= maxLat; lat += latSpacing) {
    newGridLines.add(
      Polyline(
        polylineId: PolylineId('horizontal_$lineId'),
        points: [LatLng(lat, minLng), LatLng(lat, maxLng)],
        color: Colors.black12,
        width: gridWidth,
      ),
    );
    lineId++;
  }

  // Generate vertical lines (constant longitude)
  for (double lng = minLng; lng <= maxLng; lng += lngSpacing) {
    newGridLines.add(
      Polyline(
        polylineId: PolylineId('vertical_$lineId'),
        points: [LatLng(minLat, lng), LatLng(maxLat, lng)],
        color: Colors.black12,
        width: gridWidth,
      ),
    );
    lineId++;
  }

  // Debug information
  debugPrint(
    'Grid stats: ${newGridLines.length} lines, '
    'Lat range: ${maxLat - minLat}, Lng range: ${maxLng - minLng}, '
    'Lat spacing: $latSpacing, Lng spacing: $lngSpacing',
  );

  // Send result back to main isolate
  mainSendPort.send(
    GridCalculationResult(gridLines: newGridLines, position: position),
  );
}
