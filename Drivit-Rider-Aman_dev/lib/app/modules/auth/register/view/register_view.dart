import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../theme/app_text_styles.dart';

import '../../../../widgets/common_text.dart';
import '../controller/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// Header with Back Button
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: controller.prevStep,
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                  child: _buildProfileStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: "Welcome to ",
            style: AppTextStyles.heading.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            children: const [
              TextSpan(
                text: "DRIVIT",
                style: TextStyle(color: AppColors.primary),
               ),
             ],
           ),
         ),
         const SizedBox(height: 12),
         CommonText(
           text: "Complete your profile and discover nearby drivers.",
           style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
         ),
         const SizedBox(height: 32),
 
         _buildFieldLabel("Your Full Name"),
         Obx(() => _buildTextField(
               controller.nameController,
               "Enter your full name",
               errorText: controller.nameError.value,
               onChanged: (_) => controller.validateFields(),
               inputFormatters: [
                 FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
               ],
             )),
 
         const SizedBox(height: 20),
         _buildFieldLabel("Your Mobile no"),
         Obx(() => Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Container(
                   height: 52,
                   decoration: BoxDecoration(
                     color: const Color(0xffFFF7EE),
                     borderRadius: BorderRadius.circular(12),
                     border: controller.phoneError.value != null ? Border.all(color: Colors.red, width: 1) : null,
                   ),
                   child: Row(
                     children: [
                       const Padding(
                         padding: EdgeInsets.symmetric(horizontal: 16),
                         child: Text(
                           "+91",
                           style: TextStyle(fontWeight: FontWeight.bold),
                         ),
                       ),
                       Expanded(
                         child: TextField(
                           controller: controller.phoneController,
                           readOnly: controller.isPhoneReadOnly.value,
                           onChanged: (_) => controller.validateFields(),
                           keyboardType: TextInputType.phone,
                           inputFormatters: [
                             FilteringTextInputFormatter.digitsOnly,
                             LengthLimitingTextInputFormatter(10),
                           ],
                           decoration: const InputDecoration(
                             border: InputBorder.none,
                             hintText: "Enter mobile no",
                             hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
                 if (controller.phoneError.value != null)
                   Padding(
                     padding: const EdgeInsets.only(top: 8, left: 16),
                     child: Text(
                       controller.phoneError.value!,
                       style: const TextStyle(color: Colors.red, fontSize: 12),
                     ),
                   ),
               ],
             )),
 
         const SizedBox(height: 20),
         _buildFieldLabel("Your Email Address"),
         Obx(() => _buildTextField(
               controller.emailController,
               "Enter email address",
               errorText: controller.emailError.value,
               onChanged: (_) => controller.validateFields(),
             )),
 
         const SizedBox(height: 20),
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             _buildFieldLabel("Your Address"),
             Obx(() => GestureDetector(
                   onTap: controller.isAddressLoading.value
                       ? null
                       : controller.autoDetectAddress,
                   child: Container(
                     padding:
                         const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                       color: const Color(0xfff0f0f0),
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: controller.isAddressLoading.value
                         ? const SizedBox(
                             width: 12,
                             height: 12,
                             child: CircularProgressIndicator(
                                 strokeWidth: 2, color: AppColors.primary),
                           )
                         : const Text(
                             "Auto detect",
                             style: TextStyle(
                                 color: Colors.black87,
                                 fontSize: 11,
                                 fontWeight: FontWeight.w500),
                           ),
                   ),
                 )),
           ],
         ),
         Obx(() => Column(
               children: [
                 _buildTextField(
                   controller.addressController,
                   "Enter your address (manually)",
                   errorText: controller.addressError.value,
                   onChanged: (v) {
                     controller.onAddressChanged(v);
                     controller.validateFields();
                   },
                 ),
                 if (controller.addressSuggestions.isNotEmpty)
                   Container(
                     margin: const EdgeInsets.only(top: 4, bottom: 8),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(12),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withValues(alpha: 0.05),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         ),
                       ],
                     ),
                     child: ListView.separated(
                       shrinkWrap: true,
                       physics: const NeverScrollableScrollPhysics(),
                       itemCount: controller.addressSuggestions.length,
                       separatorBuilder: (_, __) => const Divider(height: 1),
                       itemBuilder: (context, index) {
                         final suggestion = controller.addressSuggestions[index];
                         return ListTile(
                           title: Text(
                             suggestion.displayName,
                             style: const TextStyle(fontSize: 13),
                             maxLines: 2,
                             overflow: TextOverflow.ellipsis,
                           ),
                           onTap: () => controller.selectAddress(suggestion),
                         );
                       },
                     ),
                   ),
               ],
             )),
 
         const SizedBox(height: 32),
         Obx(() => SizedBox(
               width: double.infinity,
               height: 55,
               child: ElevatedButton(
                 onPressed: (controller.isFormValid() && !controller.isLoading.value) ? controller.nextStep : null,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primary,
                   disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(30),
                   ),
                   elevation: 0,
                 ),
                 child: controller.isLoading.value
                     ? const SizedBox(
                         height: 20,
                         width: 20,
                         child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                       )
                     : const Text(
                         "Continue",
                         style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                       ),
               ),
             )),
         const SizedBox(height: 40),
       ],
     );
   }
 
   Widget _buildFieldLabel(String label) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 10),
       child: Text(
         label,
         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
       ),
     );
   }
 
   Widget _buildTextField(
     TextEditingController ctrl,
     String hint, {
     Widget? suffix,
     List<TextInputFormatter>? inputFormatters,
     TextInputType? keyboardType,
     ValueChanged<String>? onChanged,
     String? errorText,
   }) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Container(
           height: 52,
           padding: const EdgeInsets.symmetric(horizontal: 16),
           decoration: BoxDecoration(
             color: const Color(0xffFFF7EE),
             borderRadius: BorderRadius.circular(12),
             border: errorText != null ? Border.all(color: Colors.red, width: 1) : null,
           ),
           child: TextField(
             controller: ctrl,
             onChanged: onChanged,
             inputFormatters: inputFormatters,
             keyboardType: keyboardType,
             style: const TextStyle(fontSize: 14),
             decoration: InputDecoration(
               border: InputBorder.none,
               hintText: hint,
               hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
               suffixIcon: suffix,
               contentPadding: const EdgeInsets.symmetric(vertical: 14),
             ),
           ),
         ),
         if (errorText != null)
           Padding(
             padding: const EdgeInsets.only(top: 8, left: 16),
             child: Text(
               errorText,
               style: const TextStyle(color: Colors.red, fontSize: 12),
             ),
           ),
       ],
     );
   }
 }
