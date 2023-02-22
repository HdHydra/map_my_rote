import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_map/plugin_api.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GlobalKey _globalKey = new GlobalKey();
  Position? _currentPosition;
  List<LatLng> points = [LatLng(0, 0)];

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   // Use `MapController` as needed
    // });
    setState(() {
      points.clear();
      // _loadPositionsFromFile();
    });
    _checkLocationPermission();
  }

  // Check location permission status
  void _checkLocationPermission() async {
    PermissionStatus permission = await Permission.location.status;
    if (permission == PermissionStatus.granted) {
      // try {
      //   await Geolocator.getPositionStream(
      //     locationSettings: LocationSettings(
      //       accuracy: LocationAccuracy.low,
      //       distanceFilter: 20,
      //     ),
      //   ).listen((Position position) {
      //     setState(() {
      //       _currentPosition = position;
      //       points.add(_currentPosition);
      //       print('low mode');
      //     });
      //   });
      // } catch (e) {
      await Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
      ).listen((Position position) {
        setState(() {
          _currentPosition = position;
          points.add(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
          print('high mode');
        });
      });
      // }
    } else {
      await Permission.location.request();
      _checkLocationPermission();
    }
  }

  // void _savePositionsToFile() async {
  //   try {
  //     final file = await _localFile;
  //     final encodedPositions = json.encode(points.map((position) => {
  //       'latitude': position.latitude,
  //       'longitude': position.longitude,
  //     }).toList());
  //     await file.writeAsString(encodedPositions);
  //   } catch (e) {
  //     print('Error saving positions to file: $e');
  //   }
  // }

  // Save the current position list to file when the widget is disposed
  // @override
  // void dispose() {
  //   super.dispose();
  //   _savePositionsToFile();
  // }

  // Load the current position list from file
  // void _loadPositionsFromFile() async {
  //   try {
  //     final file = await _localFile;
  //     final contents = await file.readAsString();
  //     final decodedContents = json.decode(contents);
  //     final positions = List<Map<String, double>>.from(decodedContents)
  //         .map((position) => LatLng(position['latitude']!, position['longitude']!))
  //         .toList();
  //     setState(() {
  //       points = positions;
  //     });
  //   } catch (e) {
  //     print('Error loading positions from file: $e');
  //   }
  // }
  void _takeScreenShot() async {
    RenderRepaintBoundary? boundary =
        _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary?.debugNeedsPaint == false) {
      var image = await boundary?.toImage(pixelRatio: 6.0);
      ByteData? byteData = await image?.toByteData(format: ImageByteFormat.png);
      var pngBytes = byteData?.buffer.asUint8List();
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      File imgFile = File('$path/map_screenshot.png');
      if (pngBytes != null) {
        await imgFile.writeAsBytes(pngBytes, flush: true);
        print('saved');
      }
    }
  }

  // Future<File> get _localFile async {
  //   final directory = await getApplicationDocumentsDirectory();
  //   return File('${directory.path}/positions.json');
  // }

  // void _takeScreenShot() async {
  //   RenderRepaintBoundary boundary =
  //       _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
  //   if (boundary.debugNeedsPaint == false) {
  //     var image = await boundary.toImage(pixelRatio: 3.0);
  //     ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
  //     var pngBytes = byteData?.buffer.asUint8List();
  //
  //     // Request permission to access the pictures directory
  //     bool permissionGranted = await _requestPermission();
  //     if (!permissionGranted) {
  //       // Handle permission not granted
  //       return;
  //     }
  //
  //     // Get the pictures directory
  //     final directory = await getExternalStorageDirectory();
  //     final path = '${directory!.path}/Pictures';
  //     Directory(path).createSync(recursive: true);
  //
  //     File imgFile = File('$path/map_screenshot.png');
  //     if (pngBytes != null) {
  //       await imgFile.writeAsBytes(pngBytes, flush: true);
  //       print('saved');
  //     } else {
  //       print('sorry');
  //     }
  //   }
  // }

// Request permission to access the pictures directory
  Future<bool> _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();
    return statuses[Permission.storage] == PermissionStatus.granted;
  }

  // void _takeScreenShot() async {
  //   RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  //   if (boundary?.debugNeedsPaint == false) { // Add this line
  //     var image = await boundary?.toImage();
  //     ByteData? byteData = await image?.toByteData(format: ImageByteFormat.png);
  //     var pngBytes = byteData?.buffer.asUint8List();
  //     final directory = await getApplicationDocumentsDirectory();
  //     final path = directory.path;
  //     File imgFile = File('$path/map_screenshot.png');
  //     if(pngBytes != null){
  //       await imgFile.writeAsBytes(pngBytes, flush: true);
  //       print('good');
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Demo',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Map my Route'),
        ),
        body: RepaintBoundary(
          key: _globalKey,
          child: _currentPosition == null
              ? Center(child: CircularProgressIndicator())
              : FlutterMap(
                  options: MapOptions(
                    center: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    interactiveFlags: InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom,
                    zoom: 16.0,
                    // zoomDuration: const Duration(milliseconds: 5000),
                    maxZoom: 17.49999,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.route_map',
                      retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points.toList(),
                          color: Colors.green,
                          strokeWidth: 2.0,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          // width: 80.0,
                          // height: 80.0,
                          anchorPos: AnchorPos.align(AnchorAlign.top),
                          point: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          builder: (ctx) => Container(
                            child: Icon(
                              Icons.location_pin,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 30,
                      right: 30,
                      child: FloatingActionButton(
                        onPressed: _takeScreenShot,
                        child: Icon(Icons.camera_alt),
                      ),
                    )
                  ],
                ),
        ),
      ),
    );
  }

  // @override
  // void didUpdateWidget(MyApp oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   setState(() {
  //     points.add(
  //       LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
  //     );
  //   });
  // }
}
