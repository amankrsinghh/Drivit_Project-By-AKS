import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/api_service.dart';

class AppGoogleMap extends StatefulWidget {
  final LatLng center;
  final double zoom;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool interactive;
  final bool myLocationEnabled;
  final ValueChanged<GoogleMapController>? onMapCreated;
  final ArgumentCallback<LatLng>? onTap;
  final void Function(CameraPosition)? onCameraMove;

  const AppGoogleMap({
    super.key,
    required this.center,
    this.zoom = 15.0,
    this.markers = const {},
    this.polylines = const {},
    this.interactive = true,
    this.myLocationEnabled = false,
    this.onMapCreated,
    this.onTap,
    this.onCameraMove,
  });

  @override
  State<AppGoogleMap> createState() => _AppGoogleMapState();
}

class _AppGoogleMapState extends State<AppGoogleMap> {
  GoogleMapController? _controller;

  static const String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{ "color": "#212121" }]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#757575" }]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{ "color": "#212121" }]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{ "color": "#757575" }]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#9e9e9e" }]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{ "color": "#181818" }]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{ "color": "#181818" }]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#2c2c2c" }]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#8a8a8a" }]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{ "color": "#3c3c3c" }]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{ "color": "#000000" }]
  }
]
''';

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  void _checkApiKey() async {
    if (ApiService.googleMapsApiKey == null || ApiService.googleMapsApiKey!.isEmpty) {
      final settings = await ApiService.getPublicSettings();
      if (settings.containsKey('google_maps_api_key')) {
        setState(() {
          ApiService.googleMapsApiKey = settings['google_maps_api_key'];
        });
      }
    }
  }

  @override
  void didUpdateWidget(AppGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.center,
        zoom: widget.zoom,
      ),
      onMapCreated: (ctrl) {
        _controller = ctrl;
        widget.onMapCreated?.call(ctrl);
      },
      markers: widget.markers,
      polylines: widget.polylines,
      myLocationEnabled: widget.myLocationEnabled && widget.interactive,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onTap: widget.onTap,
      onCameraMove: widget.onCameraMove,
      scrollGesturesEnabled: widget.interactive,
      zoomGesturesEnabled: widget.interactive,
      tiltGesturesEnabled: widget.interactive,
      rotateGesturesEnabled: widget.interactive,
      style: _mapStyle,
    );
  }
}
