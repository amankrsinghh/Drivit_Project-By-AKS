import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/car_clinic_controller.dart';

class BookClinicServiceView extends GetView<CarClinicController> {
  const BookClinicServiceView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController addressTextController = TextEditingController(text: controller.pickupAddress.value);
    
    // Keep text controller in sync with observable
    addressTextController.addListener(() {
      controller.pickupAddress.value = addressTextController.text;
    });

    return Scaffold(
      backgroundColor: const Color(0xffF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Schedule Service",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.selectedService.value == null) {
          return const Center(child: Text("No service selected"));
        }

        final service = controller.selectedService.value!;
        final name = service['name'] ?? '';
        final desc = service['description'] ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Service Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xffF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Selected Service",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Location Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xffF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Service Address",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await controller.loadDefaultLocation();
                            addressTextController.text = controller.pickupAddress.value;
                          },
                          icon: const Icon(Icons.my_location_rounded, size: 14, color: Color(0xffF38900)),
                          label: const Text("Locate Me", style: TextStyle(color: Color(0xffF38900), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: addressTextController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: "Enter the location of your vehicle...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        fillColor: const Color(0xffF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Schedule Picker Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xffF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Choose Date & Time",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: Get.context!,
                                initialDate: DateTime.now().add(const Duration(days: 0)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xffF38900),
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black87,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                controller.scheduledDate.value = picked;
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xffF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xffF38900)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      controller.scheduledDate.value == null
                                          ? "Select Date"
                                          : "${controller.scheduledDate.value!.day}/${controller.scheduledDate.value!.month}/${controller.scheduledDate.value!.year}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: controller.scheduledDate.value == null ? Colors.grey : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: Get.context!,
                                initialTime: TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xffF38900),
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black87,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                controller.scheduledTime.value = picked;
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xffF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xffF38900)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      controller.scheduledTime.value == null
                                          ? "Select Time"
                                          : controller.scheduledTime.value!.format(context),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: controller.scheduledTime.value == null ? Colors.grey : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Payment Method Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xffF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Payment Method",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              controller.selectedPaymentMethod.value = "Cash";
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: controller.selectedPaymentMethod.value == "Cash"
                                    ? const Color(0xffFFF7EE)
                                    : const Color(0xffF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: controller.selectedPaymentMethod.value == "Cash"
                                      ? const Color(0xffF38900)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.money_rounded,
                                    color: controller.selectedPaymentMethod.value == "Cash"
                                        ? const Color(0xffF38900)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Cash on Service",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: controller.selectedPaymentMethod.value == "Cash"
                                          ? const Color(0xffF38900)
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              controller.selectedPaymentMethod.value = "Razorpay";
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: controller.selectedPaymentMethod.value == "Razorpay"
                                    ? const Color(0xffFFF7EE)
                                    : const Color(0xffF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: controller.selectedPaymentMethod.value == "Razorpay"
                                      ? const Color(0xffF38900)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.payment_rounded,
                                    color: controller.selectedPaymentMethod.value == "Razorpay"
                                        ? const Color(0xffF38900)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Pay Now (Razorpay)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: controller.selectedPaymentMethod.value == "Razorpay"
                                          ? const Color(0xffF38900)
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. Billing Breakdown Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xffF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Billing Summary",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 14),
                    _buildBillRow("Service Base Fee", "₹${controller.basePrice.value.toStringAsFixed(0)}"),
                    const SizedBox(height: 8),
                    _buildBillRow("Platform Fee", "₹${controller.platformCharge.value.toStringAsFixed(0)}"),
                    const SizedBox(height: 8),
                    _buildBillRow("GST (${controller.gstPercentage.value.toStringAsFixed(0)}%)", "₹${controller.gstAmount.toStringAsFixed(0)}"),
                    const Divider(height: 24, color: Color(0xffF1F5F9)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Fare",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          "₹${controller.totalFare.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xffF38900)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 6. Booking Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: controller.isBooking.value ? null : () => controller.bookClinicJob(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffF38900),
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: controller.isBooking.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Confirm Booking",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}
