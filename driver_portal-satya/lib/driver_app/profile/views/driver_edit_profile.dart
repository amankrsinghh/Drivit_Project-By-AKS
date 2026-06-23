import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/driver_colors.dart';
import '../controllers/driver_profile_controller.dart';
import '../../../services/api_service.dart';
import '../../home/controllers/driver_home_controller.dart';

class DriverEditProfileView extends StatefulWidget {
  const DriverEditProfileView({super.key});

  @override
  State<DriverEditProfileView> createState() => _DriverEditProfileViewState();
}

class _DriverEditProfileViewState extends State<DriverEditProfileView> {
  late final TextEditingController nameC;
  late final TextEditingController phoneC;
  late final TextEditingController emailC;
  late final TextEditingController vehicleModelC;
  late final TextEditingController vehicleNumberC;
  late final TextEditingController cityC;
  late final TextEditingController pincodeC;
  String? _transmissionType;

  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _cityError;
  String? _pincodeError;
  String? _vehicleModelError;
  String? _vehicleNumberError;

  bool _isSaving = false;

  File? _pickedProfileImage;
  String? _existingProfileImageUrl;

  // Initial values to track changes
  String _initialName = "";
  String _initialPhone = "";
  String _initialEmail = "";
  String _initialVehicleModel = "";
  String _initialVehicleNumber = "";
  String _initialCity = "";
  String _initialPincode = "";
  String? _initialTransmission;

  void _validateFields() {
    setState(() {
      final name = nameC.text.trim();
      final phone = phoneC.text.trim();
      final email = emailC.text.trim();
      final city = cityC.text.trim();
      final pincode = pincodeC.text.trim();
      final model = vehicleModelC.text.trim();
      final num = vehicleNumberC.text.trim();

      _nameError = name.isEmpty ? null : (name.length < 3 ? "Name too short" : null);
      _phoneError = phone.isEmpty ? null : (phone.length != 10 ? "10 digit number required" : null);
      _emailError = email.isEmpty ? null : (!email.contains('@') ? "Invalid email address" : null);
      _cityError = city.isEmpty ? null : (city.length < 2 ? "Invalid city" : null);
      _pincodeError = pincode.isEmpty ? null : (pincode.length != 6 ? "6 digit pincode required" : null);
      _vehicleModelError = model.isEmpty ? null : (model.length < 2 ? "Invalid model" : null);
      _vehicleNumberError = num.isEmpty ? null : (num.length < 5 ? "Invalid number" : null);
    });
  }

  bool _isFormValid() {
    return _nameError == null &&
           _phoneError == null &&
           _emailError == null &&
           _cityError == null &&
           _pincodeError == null &&
           _vehicleModelError == null &&
           _vehicleNumberError == null &&
           nameC.text.trim().isNotEmpty &&
           phoneC.text.trim().isNotEmpty &&
           emailC.text.trim().isNotEmpty &&
           cityC.text.trim().isNotEmpty &&
           pincodeC.text.trim().isNotEmpty &&
           _hasChanges;
  }

  bool get _hasChanges {
    return nameC.text != _initialName ||
           phoneC.text != _initialPhone ||
           emailC.text != _initialEmail ||
           vehicleModelC.text != _initialVehicleModel ||
           vehicleNumberC.text != _initialVehicleNumber ||
           cityC.text != _initialCity ||
           pincodeC.text != _initialPincode ||
           _transmissionType != _initialTransmission ||
           _pickedProfileImage != null;
  }

  @override
  void initState() {
    super.initState();
    final profile = Get.find<DriverProfileController>();
    final data = profile.driverData;

    nameC = TextEditingController(text: data['name'] ?? profile.name.value);
    phoneC = TextEditingController(text: data['phone'] ?? profile.phone.value);
    emailC = TextEditingController(text: data['email'] ?? profile.email.value);
    vehicleModelC = TextEditingController(text: data['vehicleModel'] ?? '');
    vehicleNumberC = TextEditingController(text: data['vehicleNumber'] ?? '');
    cityC = TextEditingController(text: data['city'] ?? '');
    pincodeC = TextEditingController(text: data['pincode'] ?? '');
    _transmissionType = data['transmissionType'] ?? 'Manual';
    _existingProfileImageUrl = data['profileImage'];

    // Capture initial values
    _initialName = nameC.text;
    _initialPhone = phoneC.text;
    _initialEmail = emailC.text;
    _initialVehicleModel = vehicleModelC.text;
    _initialVehicleNumber = vehicleNumberC.text;
    _initialCity = cityC.text;
    _initialPincode = pincodeC.text;
    _initialTransmission = _transmissionType;
  }

  @override
  void dispose() {
    nameC.dispose();
    phoneC.dispose();
    emailC.dispose();
    vehicleModelC.dispose();
    vehicleNumberC.dispose();
    cityC.dispose();
    pincodeC.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: DriverColors.primary),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromImagePicker(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: DriverColors.primary),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickFromImagePicker(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromImagePicker(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _pickedProfileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Image Picker Error: $e");
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final res = await ApiService.updateDriverProfile(
      name: nameC.text.trim(),
      phone: phoneC.text.trim(),
      email: emailC.text.trim(),
      vehicleModel: vehicleModelC.text.trim(),
      vehicleNumber: vehicleNumberC.text.trim(),
      city: cityC.text.trim(),
      pincode: pincodeC.text.trim(),
      transmissionType: _transmissionType,
      profileImagePath: _pickedProfileImage?.path,
    );

    setState(() => _isSaving = false);

    if (res['error'] != null) {
      Get.snackbar('Error', res['error'], backgroundColor: Colors.red.withValues(alpha: 0.7), colorText: Colors.white);
    } else {
      Get.snackbar('Success', 'Profile updated!', backgroundColor: Colors.green.withValues(alpha: 0.7), colorText: Colors.white);
      if (res['driver'] != null) {
        Get.find<DriverProfileController>().updateWithDriverData(res['driver']);
        if (Get.isRegistered<DriverHomeController>()) {
          Get.find<DriverHomeController>().fetchStats();
        }
      }
      
      setState(() {
        _initialName = nameC.text;
        _initialPhone = phoneC.text;
        _initialEmail = emailC.text;
        _initialVehicleModel = vehicleModelC.text;
        _initialVehicleNumber = vehicleNumberC.text;
        _initialCity = cityC.text;
        _initialPincode = pincodeC.text;
        _initialTransmission = _transmissionType;
        _pickedProfileImage = null;
        if (res['driver'] != null && res['driver']['profileImage'] != null) {
          _existingProfileImageUrl = res['driver']['profileImage'];
        }
      });
    }
  }

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
            Container(
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
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(
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
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 19, 18, 40),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE5E5E5),
                              shape: BoxShape.circle,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _pickedProfileImage != null
                                ? Image.file(
                                    _pickedProfileImage!,
                                    fit: BoxFit.cover,
                                  )
                                : (_existingProfileImageUrl != null &&
                                        _existingProfileImageUrl!.isNotEmpty)
                                    ? Image.network(
                                        ApiService.getImageUrl(_existingProfileImageUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, o, s) => Image.asset("assets/images/user.png", fit: BoxFit.cover),
                                      )
                                    : Image.asset("assets/images/user.png", fit: BoxFit.cover),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: DriverColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _field('Full Name', nameC, error: _nameError),
                    const SizedBox(height: 12),
                    _field(
                      'Mobile Number',
                      phoneC,
                      keyboardType: TextInputType.phone,
                      error: _phoneError,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'Email',
                      emailC,
                      keyboardType: TextInputType.emailAddress,
                      error: _emailError,
                    ),
                    const SizedBox(height: 12),
                    _field('City', cityC, error: _cityError),
                    const SizedBox(height: 12),
                    _field('Pincode', pincodeC, keyboardType: TextInputType.number, error: _pincodeError),
                    const SizedBox(height: 12),
                    _transmissionField(),
                    const SizedBox(height: 12),
                    _field('Vehicle Model', vehicleModelC, error: _vehicleModelError),
                    const SizedBox(height: 12),
                    _field('Vehicle Number', vehicleNumberC, error: _vehicleNumberError),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isSaving || !_isFormValid()) ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DriverColors.primary,
                          disabledBackgroundColor: DriverColors.primary
                              .withValues(alpha: 0.6),
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transmissionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transmission Type',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _transmissionType,
              isExpanded: true,
              items: ['Manual', 'Automatic', 'Both']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _transmissionType = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    TextInputType keyboardType = TextInputType.text,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF4F4F4),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: error != null ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: error != null ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
            ),
            errorText: error,
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          onChanged: (v) => _validateFields(),
        ),
      ],
    );
  }
}
