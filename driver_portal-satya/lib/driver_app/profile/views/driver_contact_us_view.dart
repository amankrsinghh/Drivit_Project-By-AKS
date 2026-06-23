import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '../../theme/driver_colors.dart';
import '../../common/widgets/primary_button.dart';
import '../../../services/api_service.dart';

class DriverContactUsView extends StatefulWidget {
  const DriverContactUsView({super.key});

  @override
  State<DriverContactUsView> createState() => _DriverContactUsViewState();
}

class _DriverContactUsViewState extends State<DriverContactUsView> {
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final emailC = TextEditingController();
  final queryC = TextEditingController();
  
  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _queryError;

  Future<Map<String, dynamic>>? _contactPolicyFuture;

  @override
  void initState() {
    super.initState();
    _contactPolicyFuture = ApiService.getPolicy('Contact');
  }

  @override
  void dispose() {
    nameC.dispose();
    phoneC.dispose();
    emailC.dispose();
    queryC.dispose();
    super.dispose();
  }

  void _validateAll() {
    setState(() {
      final name = nameC.text.trim();
      final phone = phoneC.text.trim();
      final email = emailC.text.trim();
      final query = queryC.text.trim();

      if (name.isEmpty) {
        _nameError = null;
      } else if (name.length < 3) {
        _nameError = "Enter valid name";
      } else {
        _nameError = null;
      }

      if (phone.isEmpty) {
        _phoneError = null;
      } else if (phone.length != 10) {
        _phoneError = "Enter 10 digit number";
      } else {
        _phoneError = null;
      }

      if (email.isEmpty) {
        _emailError = null;
      } else if (!email.contains('@')) {
        _emailError = "Invalid email address";
      } else {
        _emailError = null;
      }

      if (query.isEmpty) {
        _queryError = null;
      } else if (query.length < 5) {
        _queryError = "Query too short";
      } else {
        _queryError = null;
      }
    });
  }

  bool _isFormValid() {
    final name = nameC.text.trim();
    final phone = phoneC.text.trim();
    final email = emailC.text.trim();
    final query = queryC.text.trim();

    return name.isNotEmpty && 
           phone.isNotEmpty && 
           email.isNotEmpty && 
           query.isNotEmpty &&
           _nameError == null && 
           _phoneError == null && 
           _emailError == null && 
           _queryError == null;
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );

  InputDecoration profileFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  bool isLoading = false;
  bool isSuccess = false;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

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
            _orangeHeader(top, "Contact Us"),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                children: [
                  // Dynamic Policy Content
                  FutureBuilder<Map<String, dynamic>>(
                    future: _contactPolicyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!['error'] == null && snapshot.data!['content'] != null) {
                        String rawHtml = snapshot.data!['content'];
                        String content = rawHtml
                            .replaceAll(RegExp(r'</p>|<br\s*/?>'), '\n')
                            .replaceAll(RegExp(r'<[^>]*>'), '')
                            .replaceAll('&nbsp;', ' ')
                            .trim();
                        
                        if (content.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                content,
                                style: const TextStyle(
                                  color: Color(0xFF555555),
                                  height: 1.6,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 30),
                              const Divider(),
                              const SizedBox(height: 30),
                            ],
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const Text(
                    "Send us a Message",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _label("Name"),
                  TextField(
                    controller: nameC,
                    onChanged: (v) => _validateAll(),
                    decoration: profileFieldDecoration("Enter your full name").copyWith(
                      errorText: _nameError,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _label("Your Mobile no"),
                  TextField(
                    controller: phoneC,
                    onChanged: (v) => _validateAll(),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: profileFieldDecoration(
                      "+91    Enter mobile no",
                    ).copyWith(
                      errorText: _phoneError,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _label("Your Email Address"),
                  TextField(
                    controller: emailC,
                    onChanged: (v) => _validateAll(),
                    keyboardType: TextInputType.emailAddress,
                    decoration: profileFieldDecoration("Enter email address").copyWith(
                      errorText: _emailError,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _label("Send Query"),
                  TextField(
                    controller: queryC,
                    onChanged: (v) => _validateAll(),
                    maxLines: 4,
                    decoration: profileFieldDecoration("Enter your Query").copyWith(
                      errorText: _queryError,
                    ),
                  ),
                  const SizedBox(height: 24),

                  DriverPrimaryButton(
                    title: isSuccess ? "Successfully Sent" : "Send",
                    isLoading: isLoading,
                    bgColor: isSuccess ? Colors.green : (_isFormValid() ? DriverColors.primary : Colors.grey.withValues(alpha: 0.5)),
                    textColor: isSuccess ? Colors.white : Colors.black,
                    onTap: _isFormValid() ? () async {
                      if (isLoading || isSuccess) return;
                      final name = nameC.text.trim();
                      final phone = phoneC.text.trim();
                      final email = emailC.text.trim();
                      final query = queryC.text.trim();

                      setState(() => isLoading = true);
                      try {
                        final res = await ApiService.submitContactQuery(
                          name: name,
                          phone: phone,
                          email: email,
                          message: query,
                        );

                        if (res['error'] != null) {
                          setState(() => isLoading = false);
                          Get.snackbar("Error", res['error'], backgroundColor: Colors.red.withValues(alpha: 0.7), colorText: Colors.white);
                        } else {
                          setState(() {
                             isLoading = false;
                             isSuccess = true;
                          });
                          
                          // Clear all fields
                          nameC.clear();
                          phoneC.clear();
                          emailC.clear();
                          queryC.clear();
                          
                          // Show success state for 2 seconds then reset
                          await Future.delayed(const Duration(seconds: 2));
                          if (mounted) {
                            setState(() {
                              isSuccess = false;
                              _validateAll();
                            });
                          }
                        }
                      } finally {
                        if (mounted && !isSuccess) {
                          setState(() => isLoading = false);
                        }
                      }
                    } : () {},
                  ),
                ],
              ),
            ),
          ],
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
                    fontSize: 25,
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

