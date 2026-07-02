import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EndTripReasonDialog extends StatelessWidget {
  final RxnString selectedReason;
  final TextEditingController reasonController;
  final VoidCallback onClose;
  final VoidCallback onSubmit;

  const EndTripReasonDialog({
    super.key,
    required this.selectedReason,
    required this.reasonController,
    required this.onClose,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final reasons = const [
      "Driver Misbehave",
      "Driver drive not Properly",
      "Other",
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // header + close
            Row(
              children: [
                const Expanded(
                  child: Center(
                    child: Text("Reason", style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                InkWell(
                  onTap: onClose,
                  child: const Icon(Icons.close, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // select reason
            Obx(() => DropdownButtonFormField<String>(
              value: selectedReason.value,
              items: reasons
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => selectedReason.value = v,
              decoration: InputDecoration(
                hintText: "Select Reason",
                filled: true,
                fillColor: const Color(0xFFF6F6F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            )),
            const SizedBox(height: 12),

            // write reason
            TextField(
              controller: reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write Reason",
                filled: true,
                fillColor: const Color(0xFFF6F6F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}