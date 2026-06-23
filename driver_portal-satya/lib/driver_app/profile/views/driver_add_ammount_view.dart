import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../theme/driver_colors.dart';
import '../controllers/driver_wallet_controller.dart';

class DriverAddAmountView extends StatefulWidget {
  const DriverAddAmountView({super.key});

  @override
  State<DriverAddAmountView> createState() => _DriverAddAmountViewState();
}

class _DriverAddAmountViewState extends State<DriverAddAmountView> {
  String amount = "200";

  void _addPreset(int v) {
    setState(() {
      final cur = int.tryParse(amount) ?? 0;
      amount = (cur + v).toString();
    });
  }

  void _tapDigit(String d) {
    setState(() {
      if (amount == "0") {
        amount = d;
      } else {
        amount = amount + d;
      }
    });
  }

  void _backspace() {
    setState(() {
      if (amount.isEmpty || amount.length == 1) {
        amount = "0";
      } else {
        amount = amount.substring(0, amount.length - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final controller = Get.find<DriverWalletController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: DriverColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _orangeHeader(top, "Add Amount"),
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Text(
                    "₹ $amount",
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 17),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _preset("+500", () => _addPreset(500)),
                      const SizedBox(width: 12),
                      _preset("+1000", () => _addPreset(1000)),
                      const SizedBox(width: 12),
                      _preset("+1500", () => _addPreset(1500)),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 44,
                      width: double.infinity,
                        child: Obx(() {
                          return ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : () {
                                    final amt = int.tryParse(amount) ?? 0;

                                    if (amt < 200) {
                                      return;
                                    }

                                    // ✅ add to wallet balance + recharge history
                                    controller.addMoney(
                                      amt.toDouble(),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DriverColors.primary,
                              elevation: 0,
                              shape: const StadiumBorder(),
                            ),
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Add Money",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                          );
                        }),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    "Note: Minimum ₹200 balance is required to receive ride requests.",
                    style: TextStyle(color: Colors.black54, fontSize: 11),
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 19, 18, 19),
                    child: Column(
                      children: [
                        _keyRow(["1", "2", "3"]),
                        const SizedBox(height: 10),
                        _keyRow(["4", "5", "6"]),
                        const SizedBox(height: 10),
                        _keyRow(["7", "8", "9"]),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Expanded(child: SizedBox()),
                            Expanded(child: _key("0", () => _tapDigit("0"))),
                            Expanded(
                              child: InkWell(
                                onTap: _backspace,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 44,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.backspace_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preset(String t, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE0E0E0)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        t,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    );
  }

  Widget _keyRow(List<String> d) {
    return Row(
      children: [
        Expanded(child: _key(d[0], () => _tapDigit(d[0]))),
        const SizedBox(width: 10),
        Expanded(child: _key(d[1], () => _tapDigit(d[1]))),
        const SizedBox(width: 10),
        Expanded(child: _key(d[2], () => _tapDigit(d[2]))),
      ],
    );
  }

  Widget _key(String t, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
    );
  }

  Widget _orangeHeader(double top, String title) {
    return Container(
      color: DriverColors.primary,
      padding: EdgeInsets.only(top: top),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 12),
            InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(99),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 25),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
