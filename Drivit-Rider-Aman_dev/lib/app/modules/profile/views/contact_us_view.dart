import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/utils/validators.dart';
import '../../../theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/notification_service.dart';
import '../widgets/profile_widget.dart';

class ContactUsView extends StatefulWidget {
  const ContactUsView({super.key});

  @override
  State<ContactUsView> createState() => _ContactUsViewState();
}

class _ContactUsViewState extends State<ContactUsView> {
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final emailC = TextEditingController();
  final queryC = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  
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
        _nameError = null; // Don't show error if empty, just keep button disabled
      } else {
        _nameError = Validators.validateName(name);
      }

      if (phone.isEmpty) {
        _phoneError = null;
      } else {
        _phoneError = Validators.validatePhone(phone);
      }

      if (email.isEmpty) {
        _emailError = null;
      } else {
        _emailError = Validators.validateEmail(email);
      }

      if (query.isEmpty) {
        _queryError = null;
      } else {
        _queryError = Validators.validateRequired(query, 'Query');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primary,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 30),
          child: Text(
            "Contact us",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
      ),

      body: ListView(
        physics: const BouncingScrollPhysics(),
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
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
            ],
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
            decoration: profileFieldDecoration("+91    Enter mobile no").copyWith(
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
          const SizedBox(height: 18),

          OrangePillButton(
            title: "Send",
            successTitle: "Successfully Sent",
            isLoading: _isLoading,
            isSuccess: _isSuccess,
            onTap: _isFormValid() ? () async {
              if (_isLoading || _isSuccess) return;
              
              final name = nameC.text.trim();
              final phone = phoneC.text.trim();
              final email = emailC.text.trim();
              final query = queryC.text.trim();

              setState(() => _isLoading = true);
              final res = await ApiService.submitContactQuery(
                name: name,
                email: email,
                message: query,
              );
              
              if (res['error'] != null) {
                setState(() => _isLoading = false);
                NotificationService.to.showLocalNotification(title: "Error", body: res['error']);
              } else {
                setState(() {
                  _isLoading = false;
                  _isSuccess = true;
                  // Clear all controllers as requested
                  nameC.clear();
                  phoneC.clear();
                  emailC.clear();
                  queryC.clear();
                });
                
                // Keep customer on the same page and reset button after 2 seconds
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      _isSuccess = false;
                      _validateAll(); // Refresh valid state
                    });
                  }
                });
              }
            } : () {}, // Passing empty function instead of null to keep it disabled but styled? 
            // Wait, OrangePillButton uses onPressed: onTap. If I pass null it disables it fully.
          ),
        ],
      ),
    );
  }
}



