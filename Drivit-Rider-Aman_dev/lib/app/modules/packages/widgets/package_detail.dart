import 'package:flutter/material.dart';
import '../models/package_model.dart';

class PackageDetailCard extends StatelessWidget {
  final List<PackageDetailRow> rows;
  const PackageDetailCard({super.key, required this.rows});

  static const divider = Color(0xFFEDEDED);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Hour", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text("Rates", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: divider),
          const SizedBox(height: 10),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      r.left,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    r.right,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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