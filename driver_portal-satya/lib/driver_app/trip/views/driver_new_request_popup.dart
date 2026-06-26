import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/driver_colors.dart';

class DriverNewRequestPopup extends StatefulWidget {
  final Map<String, dynamic> ride;
  final VoidCallback onReject;
  final VoidCallback onAccept;

  const DriverNewRequestPopup({
    super.key,
    required this.ride,
    required this.onReject,
    required this.onAccept,
  });

  @override
  State<DriverNewRequestPopup> createState() => _DriverNewRequestPopupState();
}

class _DriverNewRequestPopupState extends State<DriverNewRequestPopup> {
  static const int _start = 30; // UPDATED: 30 seconds for responding
  late int secondsLeft;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    secondsLeft = _start;

    _t = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => secondsLeft--);

      if (secondsLeft <= 0) {
        timer.cancel();
        // Silent close: Just dismiss the dialog without sending 'rejected' status
        if (mounted) Get.back(); 
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _reject() {
    _t?.cancel();
    widget.onReject();
  }

  void _accept() {
    _t?.cancel();
    widget.onAccept();
  }

  @override
  Widget build(BuildContext context) {
    final bool isScheduled = widget.ride['isScheduled'] == true || widget.ride['isScheduled'] == 'true';
    final String? scheduledAt = widget.ride['scheduledAt']?.toString();
    String scheduledLabel = '';
    if (isScheduled && scheduledAt != null) {
      try {
        final dt = DateTime.tryParse(scheduledAt)?.toLocal();
        if (dt != null) {
          final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
          final m = dt.minute.toString().padLeft(2, '0');
          final ap = dt.hour >= 12 ? 'PM' : 'AM';
          scheduledLabel = '${dt.day}/${dt.month}/${dt.year} $h:$m $ap';
        }
      } catch (_) {}
    }

    final String tripType = widget.ride['tripType']?.toString() ?? 'One Way';
    String package = widget.ride['carPackage']?.toString() ?? widget.ride['package']?.toString() ?? widget.ride['packageHours']?.toString() ?? '';
    final bool isRoundTrip = tripType == 'Round Trip';
    if (package.isNotEmpty && !package.toLowerCase().contains("hr")) {
      package = "$package Hours";
    }
    final bool isOutstation = widget.ride['isOutstation'] == true || widget.ride['isOutstation'] == 'true';
    final bool hasPackage = package.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top: Scheduled badge + Auto decline + close
            Row(
              children: [
                if (isScheduled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FD),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2196F3), width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 12, color: Color(0xFF2196F3)),
                        SizedBox(width: 4),
                        Text(
                          'Scheduled',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        const TextSpan(text: "Auto Close in : "),
                        TextSpan(
                          text: "${secondsLeft}s",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: _reject,
                  child: const Icon(
                    Icons.close,
                    size: 22,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            // Scheduled time row (only for scheduled rides)
            if (isScheduled && scheduledLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Color(0xFFF57F17)),
                    const SizedBox(width: 6),
                    Text(
                      'Scheduled: $scheduledLabel',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF57F17),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Trip Type Badge Row
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                // Trip Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRoundTrip
                        ? const Color(0xFFE8F5E9)
                        : isOutstation
                            ? const Color(0xFFFFF3E0)
                            : const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isRoundTrip
                          ? const Color(0xFF2DBE60)
                          : isOutstation
                              ? const Color(0xFFF97316)
                              : const Color(0xFF7A3CFF),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRoundTrip
                            ? Icons.loop
                            : isOutstation
                                ? Icons.map_outlined
                                : Icons.arrow_forward,
                        size: 11,
                        color: isRoundTrip
                            ? const Color(0xFF2DBE60)
                            : isOutstation
                                ? const Color(0xFFF97316)
                                : const Color(0xFF7A3CFF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOutstation ? 'Outstation · $tripType' : tripType,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isRoundTrip
                              ? const Color(0xFF2DBE60)
                              : isOutstation
                                  ? const Color(0xFFF97316)
                                  : const Color(0xFF7A3CFF),
                        ),
                      ),
                    ],
                  ),
                ),
                // Estimated usage hours badge (only if package is set and not a round trip to avoid duplication)
                if (hasPackage && !isRoundTrip)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2196F3), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 11, color: Color(0xFF2196F3)),
                        const SizedBox(width: 4),
                        Text(
                          'Est. $package',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              ),
            ),

            const SizedBox(height: 10),

            // Pickup
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CircleIcon(
                  bg: Color(0xFFF1E6FF),
                  icon: Icons.location_on,
                  iconColor: Color(0xFF7A3CFF),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.ride['pickupLocation'] ?? "...",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Drop
            Row(
              children: [
                const _CircleIcon(
                  bg: Color(0xFFE9FBEF),
                  icon: Icons.person,
                  iconColor: Color(0xFF2DBE60),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.ride['dropoffLocation'] ?? "...",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _Stat(
                    icon: Icons.access_time,
                    label: isRoundTrip ? "Time" : "ETA",
                    value: isRoundTrip ? package : (() {
                      int mins = int.tryParse(widget.ride['estimatedTime']?.toString() ?? '15') ?? 15;
                      if (mins > 60) {
                        return "${mins ~/ 60}:${(mins % 60).toString().padLeft(2, '0')} hr:min";
                      }
                      return "${mins}min";
                    })(),
                  ),
                ),
                Expanded(
                  child: _Stat(
                    icon: Icons.attach_money,
                    label: "Amount",
                    value: "₹ ${((widget.ride['fare'] ?? 0) as num).toStringAsFixed(0)}",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Rating
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Customer Rating",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
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
                      const SizedBox(width: 4),
                      Text(
                        (() {
                          final customer = widget.ride['customerId'];
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
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Car type & Model
            Row(
              children: [
                const Text(
                  "Car Type",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${widget.ride['carType'] ?? 'N/A'} - ${widget.ride['carModel'] ?? ''}",
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),

            if (widget.ride['requireCarWash'] == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Car Wash Required",
                      style: TextStyle(fontSize: 12, color: Color(0xFF2DBE60), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "₹${widget.ride['carWashPrice'] ?? '0'}",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2DBE60)),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _reject,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF3B30)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Reject",
                        style: TextStyle(
                          color: Color(0xFFFF3B30),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _accept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DBE60),
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
          ],
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final Color bg;
  final IconData icon;
  final Color iconColor;

  const _CircleIcon({
    required this.bg,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Stat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFF3F3F3),
          child: Icon(icon, size: 16, color: DriverColors.primary),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Colors.black45),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
