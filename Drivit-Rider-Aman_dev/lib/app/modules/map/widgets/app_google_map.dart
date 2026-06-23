import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/api_service.dart';

class AppGoogleMap extends StatefulWidget {
  final LatLng center;
  final double zoom;
  final bool showMarker;
  final bool interactive;
  final bool myLocationEnabled;
  final bool allowZoom;
  final EdgeInsets padding;

  final Set<Marker> markers;
  final Set<Polyline> polylines;

  final void Function(LatLng latLng)? onTap;
  final void Function(CameraPosition position)? onCameraMove;
  final void Function(GoogleMapController controller)? onMapCreated;

  const AppGoogleMap({
    super.key,
    required this.center,
    this.zoom = 16,
    this.showMarker = true,
    this.interactive = true,
    this.myLocationEnabled = true,
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.allowZoom = true,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.onCameraMove,
    this.onMapCreated,
  });

  @override
  State<AppGoogleMap> createState() => _AppGoogleMapState();
}

class _AppGoogleMapState extends State<AppGoogleMap> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  void _checkApiKey() async {
    if (ApiService.googleMapsApiKey == null || ApiService.googleMapsApiKey!.isEmpty) {
      final settings = await ApiService.getPublicSettings();
      if (settings.containsKey('google_maps_api_key')) {
        if (mounted) {
          setState(() {
            ApiService.googleMapsApiKey = settings['google_maps_api_key'];
          });
        }
      }
    }
  }

  static const String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#242f3e"
        }
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#746855"
        }
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#242f3e"
        }
      ]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#d59563"
        }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#d59563"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#263c3f"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#6b9a76"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#38414e"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [
        {
          "color": "#212a37"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#9ca5b3"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#746855"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [
        {
          "color": "#1f2835"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#f3d19c"
        }
      ]
    },
    {
      "featureType": "transit",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#2f3948"
        }
      ]
    },
    {
      "featureType": "transit.station",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#d59563"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#17263c"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#515c6d"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#17263c"
        }
      ]
    }
  ]
  ''';

  @override
  void didUpdateWidget(AppGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (ApiService.googleMapsApiKey == null || ApiService.googleMapsApiKey!.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final Set<Marker> effectiveMarkers = widget.markers.isNotEmpty
        ? widget.markers
        : (widget.showMarker
            ? {
                Marker(
                  markerId: const MarkerId('center'),
                  position: widget.center,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                )
              }
            : <Marker>{});

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.center,
        zoom: widget.zoom,
      ),
      padding: widget.padding,
      onMapCreated: (controller) {
        _mapController = controller;
        widget.onMapCreated?.call(controller);
      },
      onTap: widget.onTap,
      onCameraMove: widget.onCameraMove,
      markers: effectiveMarkers,
      polylines: widget.polylines,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      scrollGesturesEnabled: widget.interactive,
      zoomGesturesEnabled: widget.interactive,
      tiltGesturesEnabled: widget.interactive,
      rotateGesturesEnabled: widget.interactive,
      mapToolbarEnabled: false,
      compassEnabled: true,
      style: _mapStyle,
    );
  }
}
