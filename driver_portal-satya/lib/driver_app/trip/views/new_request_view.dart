//
//
//
//
//
//
// import 'package:flutter/material.dart';
// import '../../theme/driver_colors.dart';
//
// class DriverNewRequestSheet extends StatelessWidget {
//   final VoidCallback onReject;
//   final VoidCallback onAccept;
//
//   const DriverNewRequestSheet({
//     super.key,
//     required this.onReject,
//     required this.onAccept,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       top: false,
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 16,
//               offset: Offset(0, -6),
//             )
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 44,
//               height: 5,
//               decoration: BoxDecoration(
//                 color: Colors.black12,
//                 borderRadius: BorderRadius.circular(99),
//               ),
//             ),
//             const SizedBox(height: 12),
//             const Text("New Request", style: TextStyle(fontWeight: FontWeight.w800)),
//             const SizedBox(height: 10),
//
//             _row("Pickup", "Adyar, 4th Main Road..."),
//             _row("Drop", "T Nagar, Chennai..."),
//             _row("Distance", "6.2 km"),
//             _row("Earning", "₹ 180"),
//
//             const SizedBox(height: 14),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: onReject,
//                     style: OutlinedButton.styleFrom(
//                       side: const BorderSide(color: DriverColors.primary),
//                       shape: const StadiumBorder(),
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                     child: const Text(
//                       "Reject",
//                       style: TextStyle(
//                         color: DriverColors.primary,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: onAccept,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: DriverColors.primary,
//                       elevation: 0,
//                       shape: const StadiumBorder(),
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                     child: const Text(
//                       "Accept",
//                       style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _row(String k, String v) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 90,
//             child: Text(k, style: const TextStyle(color: Colors.black54)),
//           ),
//           Expanded(
//             child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/driver_colors.dart';
import '../controllers/driver_new_request_controller.dart';
import '../../common/widgets/app_google_map.dart';

class DriverNewRequestView extends StatefulWidget {
  const DriverNewRequestView({super.key});

  @override
  State<DriverNewRequestView> createState() => _DriverNewRequestViewState();
}

class _DriverNewRequestViewState extends State<DriverNewRequestView> {
  final controller = Get.find<DriverNewRequestController>();
  GoogleMapController? _mapController;

  void _fitBounds() {
    if (controller.routePoints.isEmpty) {
      if (controller.pickupLat.value != 0 && controller.pickupLng.value != 0) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(controller.pickupLat.value, controller.pickupLng.value),
            14.5,
          ),
        );
      }
      return;
    }

    final points = controller.routePoints;
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
    ever(controller.routePoints, (_) => _fitBounds());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ✅ Configurable header (New Request + timer)
          Obx(() {
            final isScheduled = controller.rideData['isScheduled'] == true;
            return Container(
              color: isScheduled ? Colors.indigo : DriverColors.primary,
              padding: EdgeInsets.only(top: top),
              child: SizedBox(
                height: 58,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: controller.reject,
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, size: 20),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Obx(() {
                          final isScheduled = controller.rideData['isScheduled'] == true;
                          return Text(
                            isScheduled ? "Scheduled Ride" : "New Request",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        }),
                      ),
                    ),
                    Obx(
                      () => Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${controller.secondsLeft.value}s",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // ===== Map area =====
          SizedBox(
            height: 240,
            child: Obx(() {
              final pickupPos = LatLng(controller.pickupLat.value, controller.pickupLng.value);
              final hasPickup = controller.pickupLat.value != 0;
              
              final markers = <Marker>{
                 if (hasPickup)
                   Marker(
                     markerId: const MarkerId('pickup'),
                     position: pickupPos,
                     icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                   ),
                 if (controller.driverLat.value != 0)
                   Marker(
                     markerId: const MarkerId('driver'),
                     position: LatLng(controller.driverLat.value, controller.driverLng.value),
                     icon: controller.driverIcon.value ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                     anchor: const Offset(0.5, 0.5),
                   ),
              };

              return AppGoogleMap(
                center: hasPickup ? pickupPos : const LatLng(0, 0),
                zoom: 14,
                markers: markers,
                myLocationEnabled: false,
                polylines: {
                  if (controller.routePoints.isNotEmpty)
                    Polyline(
                      polylineId: PolylineId('new_request_route_${controller.rideData['_id'] ?? 'default'}'),
                      points: controller.routePoints,
                      color: DriverColors.primary,
                      width: 5,
                    ),
                },
                onMapCreated: (ctrl) {
                  _mapController = ctrl;
                  _fitBounds();
                },
              );
            }),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  Obx(
                    () => _infoCard(
                      iconBg: const Color(0xFFF1E6FF),
                      icon: Icons.location_on,
                      iconColor: const Color(0xFF7A3CFF),
                      title: "Pickup Location",
                      value: controller.rideData['pickupLocation'] ?? "...",
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => _infoCard(
                      iconBg: const Color(0xFFE9FBEF),
                      icon: Icons.person_pin_circle,
                      iconColor: const Color(0xFF2DBE60),
                      title: "Drop Location",
                      value: controller.rideData['dropoffLocation'] ?? "...",
                    ),
                  ),
                  Obx(() {
                    final isScheduled = controller.rideData['isScheduled'] == true;
                    if (!isScheduled) return const SizedBox.shrink();
                    
                    final scheduledAtStr = controller.rideData['scheduledAt']?.toString() ?? '';
                    DateTime? scheduledAt = DateTime.tryParse(scheduledAtStr);
                    String formattedDate = "Unknown Date";
                    if (scheduledAt != null) {
                       final localDt = scheduledAt.toLocal();
                       final hr = localDt.hour > 12 ? localDt.hour - 12 : (localDt.hour == 0 ? 12 : localDt.hour);
                       final mn = localDt.minute.toString().padLeft(2, '0');
                       final ampm = localDt.hour >= 12 ? 'PM' : 'AM';
                       formattedDate = "${localDt.day}/${localDt.month}/${localDt.year}  •  $hr:$mn $ampm";
                    }
                    
                    final customerDetails = controller.rideData['customerId'];
                    final name = customerDetails is Map ? (customerDetails['name']?.toString() ?? 'Unknown') : 'Customer';
                    
                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        _infoCard(
                          iconBg: const Color(0xFFE5F3FF),
                          icon: Icons.calendar_month,
                          iconColor: const Color(0xFF007AFF),
                          title: "Scheduled Date & Time",
                          value: formattedDate,
                        ),
                        const SizedBox(height: 12),
                        _infoCard(
                          iconBg: const Color(0xFFFFF3E6),
                          icon: Icons.person,
                          iconColor: Colors.orange,
                          title: "Rider Details",
                          value: name,
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 14),

                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: _miniStat("ETA", controller.estimatedTime.value, Icons.access_time),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _miniStat(
                            "Amount",
                            "₹${controller.rideData['fare'] ?? '0'}",
                            Icons.currency_rupee,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Customer Rating",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.orange),
                            const SizedBox(width: 2),
                            Text(
                              (() {
                                final customer = controller.rideData['customerId'];
                                if (customer is Map) {
                                  final double ratingVal = (customer['rating'] ?? 0.0).toDouble();
                                  if (ratingVal > 0) {
                                    return ratingVal.toStringAsFixed(1);
                                  }
                                  final double total = (customer['totalRating'] ?? 0.0).toDouble();
                                  final int count = (customer['ratingCount'] ?? 0).toInt();
                                  return count > 0 ? (total / count).toStringAsFixed(1) : "0.0";
                                }
                                return "0.0";
                              })(),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const SizedBox(height: 10),

                   Obx(() => Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Car Type",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                      Text(
                        "${controller.rideData['carType'] ?? 'N/A'} - ${controller.rideData['carModel'] ?? ''}",
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  )),

                  const SizedBox(height: 10),

                   Obx(() => Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Trip details",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                      Text(
                        "${() {
                          final bool isOutstation = controller.rideData['isOutstation'] == true || controller.rideData['isOutstation'] == 'true';
                          final String tripType = controller.rideData['tripType']?.toString() ?? 'One Way';
                          return isOutstation ? 'Outstation · $tripType' : 'Local';
                        }()} • ${controller.rideData['carPackage'] ?? controller.rideData['package'] ?? '-'}",
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  )),

                  if (controller.rideData['requireCarWash'] == true) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Car Wash",
                            style: TextStyle(color: Color(0xFF34C759), fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          "₹${controller.rideData['carWashPrice'] ?? '0'}",
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF34C759)),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE9E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFB6B6)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Do not start the trip without verifying the\nride OTP.",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.50,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ Bottom buttons
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: controller.reject,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: DriverColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Reject",
                          style: TextStyle(
                            color: DriverColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: controller.accept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34C759),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Accept",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
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

  Widget _infoCard({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _miniStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _miniStat(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEDED)),
        color: Colors.white,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFFFF3E6),
            child: Icon(icon, size: 16, color: DriverColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
