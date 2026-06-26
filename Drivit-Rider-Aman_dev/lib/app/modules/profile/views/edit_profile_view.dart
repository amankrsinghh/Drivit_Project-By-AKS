import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/validators.dart';

import '../../../core/services/api_service.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_widget.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final c = Get.find<ProfileController>();
  final picker = ImagePicker();

  late final TextEditingController nameC;
  late final TextEditingController phoneC;
  late final TextEditingController emailC;
  late final TextEditingController addressC;
  late final TextEditingController carModelC;
  late final TextEditingController carNumberC;
  late String transmissionVal;
  late String fuelTypeVal;

  bool _isEditable = false;
  bool _hasChanges = false;
  bool _isSaving = false;

  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _addressError;
  String? _carModelError;
  String? _carNumberError;

  void _validateAll() {
    setState(() {
      final name = nameC.text.trim();
      final phone = phoneC.text.trim();
      final email = emailC.text.trim();
      final address = addressC.text.trim();
      final carModel = carModelC.text.trim();
      final carNumber = carNumberC.text.trim();

      if (name.isEmpty) {
        _nameError = null;
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

      if (address.isEmpty) {
        _addressError = null;
      } else {
        _addressError = Validators.validateRequired(address, 'Address');
      }

      if (carModel.isEmpty) {
        _carModelError = null;
      } else {
        _carModelError = Validators.validateRequired(carModel, 'Car Name / Model');
      }

      if (carNumber.isEmpty) {
        _carNumberError = null;
      } else {
        _carNumberError = Validators.validateRequired(carNumber, 'Car Number');
      }

      // Detect if there are actual changes from original
      _hasChanges = name != c.name.value || 
                    phone != c.phone.value || 
                    email != c.email.value || 
                    address != c.address.value ||
                    carModel != c.carModel.value ||
                    carNumber != c.carNumber.value ||
                    transmissionVal != c.transmission.value ||
                    fuelTypeVal != c.fuelType.value ||
                    c.profileImagePath.value.isNotEmpty;
    });
  }

  bool _isFormValid() {
    return _nameError == null && 
           _phoneError == null && 
           _emailError == null && 
           _addressError == null &&
           _carModelError == null &&
           _carNumberError == null &&
           _hasChanges &&
           nameC.text.trim().isNotEmpty &&
           phoneC.text.trim().isNotEmpty &&
           emailC.text.trim().isNotEmpty &&
           addressC.text.trim().isNotEmpty &&
           carModelC.text.trim().isNotEmpty &&
           carNumberC.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    nameC = TextEditingController(text: c.name.value);
    phoneC = TextEditingController(text: c.phone.value);
    emailC = TextEditingController(text: c.email.value);
    addressC = TextEditingController(text: c.address.value);
    carModelC = TextEditingController(text: c.carModel.value);
    carNumberC = TextEditingController(text: c.carNumber.value);
    transmissionVal = c.transmission.value.isEmpty ? 'Manual' : c.transmission.value;
    fuelTypeVal = c.fuelType.value.isEmpty ? 'Petrol' : c.fuelType.value;
  }

  @override
  void dispose() {
    nameC.dispose();
    phoneC.dispose();
    emailC.dispose();
    addressC.dispose();
    carModelC.dispose();
    carNumberC.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (file != null) {
      c.setProfileImage(file.path);
      setState(() => _hasChanges = true);
    }
  }

  void _openImageSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from gallery"),
              onTap: () async {
                Get.back();
                await _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a photo"),
              onTap: () async {
                Get.back();
                await _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = nameC.text.trim();
    final phone = phoneC.text.trim();
    final email = emailC.text.trim();
    final address = addressC.text.trim();
    final carModel = carModelC.text.trim();
    final carNumber = carNumberC.text.trim();

    setState(() => _isSaving = true);
    final res = await ApiService.updateCustomerProfile(
      {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'carModel': carModel,
        'carNumber': carNumber,
        'transmission': transmissionVal,
        'fuelType': fuelTypeVal,
      },
      profileImagePath: c.profileImagePath.value,
    );
    setState(() => _isSaving = false);

    if (res.containsKey('error')) {
      Get.snackbar('Error', res['error'] ?? 'Update failed', backgroundColor: Colors.red.withValues(alpha: 0.7), colorText: Colors.white);
    } else {
      await c.fetchProfile();
      Get.back();
      Get.snackbar('Success', 'Profile updated!', backgroundColor: Colors.green.withValues(alpha: 0.7), colorText: Colors.white);
    }
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
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFFF38900), size: 20),
            ),
          ),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!_isEditable)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: () => setState(() => _isEditable = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Edit",
                      style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
        children: [
          // Avatar Section
          Center(
            child: Obx(() {
              final path = c.profileImagePath.value;
              final url = c.profileImageUrl.value;
              return Stack(
                children: [
                  Container(
                    width: 100, // Match ProfileView size
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD9D9D9),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: path.isNotEmpty
                          ? Image.file(File(path), fit: BoxFit.cover)
                          : url.isNotEmpty
                              ? Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset("assets/images/user.png", fit: BoxFit.cover),
                                )
                              : Image.asset("assets/images/user.png", fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: _isEditable ? _openImageSheet : null,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _isEditable ? const Color(0xFFFFF7EA) : Colors.grey.shade300,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 18,
                          color: _isEditable ? const Color(0xFFF38900) : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 35),

          _label("Your Full Name"),
          TextField(
            controller: nameC,
            readOnly: !_isEditable,
            onChanged: (v) => _validateAll(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
            ],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: profileFieldDecoration("Enter your name").copyWith(
              errorText: _nameError,
            ),
          ),

          const SizedBox(height: 20),
          _label("Your Mobile no"),
          TextField(
            controller: phoneC,
            readOnly: !_isEditable,
            onChanged: (v) => _validateAll(),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: profileFieldDecoration("+91  XXX XXX XXXX").copyWith(
              errorText: _phoneError,
            ),
          ),

          const SizedBox(height: 20),
          _label("Your Email Address"),
          TextField(
            controller: emailC,
            readOnly: !_isEditable,
            onChanged: (v) => _validateAll(),
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: profileFieldDecoration("XYZ@gmail.com").copyWith(
              errorText: _emailError,
            ),
          ),

          const SizedBox(height: 20),
          _label("Your Address"),
          TextField(
            controller: addressC,
            readOnly: !_isEditable,
            onChanged: (v) => _validateAll(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: profileFieldDecoration("123, Jaipur").copyWith(
              errorText: _addressError,
            ),
          ),

          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),
          const Text(
            "Vehicle Information",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          _label("Transmission Type"),
          Row(
            children: ['Manual', 'Automatic'].map((opt) {
              final isSelected = transmissionVal == opt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Center(child: Text(opt)),
                    selected: isSelected,
                    onSelected: _isEditable
                        ? (selected) {
                            if (selected) {
                              setState(() {
                                transmissionVal = opt;
                                _validateAll();
                              });
                            }
                          }
                        : null,
                    selectedColor: const Color(0xffFFF3E0),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.orange.shade900 : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    side: BorderSide(
                      color: isSelected ? Colors.orange : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          _label("Vehicle Fuel Type"),
          Row(
            children: ['Petrol', 'Diesel', 'EV'].map((opt) {
              final isSelected = fuelTypeVal == opt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Center(child: Text(opt)),
                    selected: isSelected,
                    onSelected: _isEditable
                        ? (selected) {
                            if (selected) {
                              setState(() {
                                fuelTypeVal = opt;
                                _validateAll();
                              });
                            }
                          }
                        : null,
                    selectedColor: const Color(0xffFFF3E0),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.orange.shade900 : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    side: BorderSide(
                      color: isSelected ? Colors.orange : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          _label("Car Name / Model"),
          TextField(
            controller: carModelC,
            readOnly: !_isEditable,
            onChanged: (v) => _validateAll(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: profileFieldDecoration("Enter your car model (e.g. Swift)").copyWith(
              errorText: _carModelError,
            ),
          ),
          const SizedBox(height: 20),

          _label("Your Car Number"),
          TextField(
            controller: carNumberC,
            readOnly: !_isEditable,
            onChanged: (v) => _validateAll(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: profileFieldDecoration("Enter your car number").copyWith(
              errorText: _carNumberError,
            ),
          ),

          const SizedBox(height: 40),
          Visibility(
            visible: _isEditable,
            child: OrangePillButton(
              title: _isSaving ? "Saving..." : "Update Profile",
              onTap: (_isFormValid() && !_isSaving) ? _save : () {},
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

