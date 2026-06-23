



import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/driver_colors.dart';

class ReasonDialog extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onSubmit;

  const ReasonDialog({
    super.key,
    required this.onClose,
    required this.onSubmit,
  });

  @override
  State<ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<ReasonDialog> {
  bool expanded = false;

  String? selected; // null => "Select Reason"
  final reasonC = TextEditingController();

  final reasons = const [
    "Owner Misbehave",
    "Owner Use Abusive Language",
    "Other",
  ];

  @override
  void dispose() {
    reasonC.dispose();
    super.dispose();
  }

  void _toggle() => setState(() => expanded = !expanded);

  void _select(String r) {
    setState(() {
      selected = r;
      expanded = false; // ✅ close dropdown after select
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.7;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== Header =====
              Row(
                children: [
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Reason",
                        style: TextStyle(fontWeight: FontWeight.w900,
                        fontSize: 20),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: widget.onClose,
                    child: const Icon(
                      Icons.close,
                      color: DriverColors.primary,
                      size: 22,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // ===== Scroll area (prevents overflow) =====
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ===== Dropdown field =====
                      InkWell(
                        onTap: _toggle, // ✅ arrow/field click => open/close
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selected ?? "Select Reason",
                                  style: TextStyle(
                                    color: selected == null
                                        ? Colors.black.withValues(alpha: 0.45)
                                        : Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: expanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 180),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.black.withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ===== Dropdown list (only when expanded) =====
                      AnimatedCrossFade(
                        firstChild: const SizedBox(height: 0),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3F3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: reasons.map((r) {
                                final active = selected == r;
                                return InkWell(
                                  onTap: () => _select(r),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? DriverColors.primary
                                          : Colors.transparent,
                                      borderRadius: r == reasons.first
                                          ? const BorderRadius.vertical(
                                        top: Radius.circular(10),
                                      )
                                          : r == reasons.last
                                          ? const BorderRadius.vertical(
                                        bottom: Radius.circular(10),
                                      )
                                          : BorderRadius.zero,
                                    ),
                                    child: Text(
                                      r,
                                      style: TextStyle(
                                        color: active
                                            ? Colors.white
                                            : Colors.black54,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        crossFadeState: expanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 180),
                      ),

                      const SizedBox(height: 12),

                      // ===== Write reason box =====
                      TextField(
                        controller: reasonC,
                        minLines: 5,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: "Write Reason",
                          hintStyle: TextStyle(
                            color: Colors.black.withValues(alpha: 0.35),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade100),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade100),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ===== Confirm button fixed bottom =====
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final reason = reasonC.text.trim();
                    if (selected == null && reason.isEmpty) {
                      Get.snackbar(
                        "Required",
                        "Please select or write a reason for cancellation",
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    widget.onSubmit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverColors.primary,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    "Confirm",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}