import 'package:flutter/material.dart';
import '../../theme/driver_colors.dart';

class CancelRequestDialog extends StatelessWidget {
  final VoidCallback onNo;
  final VoidCallback onYes;

  const CancelRequestDialog({
    super.key,
    required this.onNo,
    required this.onYes,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Center(
                    child: Text("Cancel Request",
                        style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                InkWell(
                  onTap: onNo,
                  child: const Icon(Icons.close,
                      color: DriverColors.primary, size: 22),
                )
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Are you sure you want to\nCancel a trip",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.25),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: onNo,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: DriverColors.primary),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text("No",
                          style: TextStyle(
                              color: DriverColors.primary,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onYes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DriverColors.primary,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text("Yes",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}