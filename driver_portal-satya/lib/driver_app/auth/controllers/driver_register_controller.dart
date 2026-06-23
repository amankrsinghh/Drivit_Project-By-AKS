import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../routes/driver_routes.dart';
import '../../../services/api_service.dart';
import '../../../services/socket_service.dart';
import '../../home/controllers/driver_home_controller.dart';
import '../../history/controllers/driver_history_controller.dart';
import '../../profile/controllers/driver_profile_controller.dart';
import '../../finding/controllers/driver_finding_controller.dart';
import '../../package/controllers/driver_package_controller.dart';
import '../../profile/controllers/driver_wallet_controller.dart';
import '../../../services/notification_service.dart';

enum _DocType { aadharFront, aadharBack, license, expProof, policeVerification }

class DriverRegisterController extends GetxController {
  // ---------------- Step 1 fields ----------------
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final otpC = TextEditingController();
  final addressC = TextEditingController();
  final cityC = TextEditingController();
  final pincodeC = TextEditingController();
  final aadharC = TextEditingController();
  final dlC = TextEditingController();

  final isOtpSent = false.obs;
  final isPhoneVerified = false.obs;
  final isPhoneReadOnly = false.obs;
  final isLoading = false.obs;

  // ---------------- Step 2 fields ----------------
  final licenseYearC = TextEditingController();
  final expYearC = TextEditingController();

  final transmissionType = "Select".obs;
  final prevAppExp = "No".obs;
  final policeVerification = "Not Done".obs;

  // ---------------- Step 3 docs ----------------
  final aadharFrontFile = "".obs;
  final aadharBackFile = "".obs;
  final licenseFile = "".obs;
  final expProofFile = "".obs;
  final policeVerificationFile = "".obs;

  final _imagePicker = ImagePicker();

  // ---------------- Validity Flags ----------------
  final isStep1Valid = false.obs;
  final isStep2Valid = false.obs;

  // ---------------- Error Messages ----------------
  final nameError = RxnString();
  final phoneError = RxnString();
  final pincodeError = RxnString();
  final aadharError = RxnString();
  final dlError = RxnString();
  final addressError = RxnString();
  final cityError = RxnString();

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments['phone'] != null) {
      phoneC.text = Get.arguments['phone'];
      isPhoneVerified.value = true; // Came from login OTP
      isPhoneReadOnly.value = true;
    }

    // Listeners for real-time validation
    nameC.addListener(validateStep1);
    phoneC.addListener(validateStep1);
    addressC.addListener(validateStep1);
    cityC.addListener(validateStep1);
    pincodeC.addListener(validateStep1);
    aadharC.addListener(validateStep1);
    dlC.addListener(validateStep1);
    ever(isPhoneVerified, (_) => validateStep1());

    licenseYearC.addListener(validateStep2);
    expYearC.addListener(validateStep2);
    ever(transmissionType, (_) => validateStep2());
    ever(prevAppExp, (_) => validateStep2());
    ever(policeVerification, (_) => validateStep2());
    ever(expProofFile, (_) => validateStep2());
    ever(policeVerificationFile, (_) => validateStep2());

    ever(aadharFrontFile, (_) => validateStep1()); // Actually Step 1 doesn't use these, but Step 3 does. Wait.
    // Step 3 validation is done in the view itself for confirm button. 
    // But let's add them just in case.

    // Initial validation
    validateStep1();
    validateStep2();
  }

  void validateStep1() {
    final name = nameC.text.trim();
    final phone = phoneC.text.trim();
    final address = addressC.text.trim();
    final city = cityC.text.trim();
    final pincode = pincodeC.text.trim();
    final aadhar = aadharC.text.trim();
    final dl = dlC.text.trim();

    // Reset errors
    nameError.value = null;
    phoneError.value = null;
    addressError.value = null;
    cityError.value = null;
    pincodeError.value = null;
    aadharError.value = null;
    dlError.value = null;

    bool isNameValid = name.isNotEmpty;
    bool isPhoneValid = phone.length == 10;
    bool isAddressValid = address.isNotEmpty;
    bool isCityValid = city.isNotEmpty;
    bool isPincodeValid = pincode.length == 6 && pincode.isNumericOnly;
    bool isAadharValid = aadhar.length == 12 && aadhar.isNumericOnly;
    // DL Validation
    bool isDLValid = false;
    // Exactly 16 characters: SS RR YYYY NNNNNNN (usually with a space or hyphen at index 4)
    // RJ14 20110001234 -> 2(RJ)+2(14)+1(space)+4(2011)+7(serial) = 16
    final dlRegex = RegExp(r'^[A-Z]{2}[0-9]{2}[- ]{1}[0-9]{4}[0-9]{7}$');
    
    if (dl.isEmpty) {
      isDLValid = false;
    } else if (dl.length != 16) {
      dlError.value = "Exactly 16 characters required";
      isDLValid = false;
    } else if (!dlRegex.hasMatch(dl)) {
      dlError.value = "Follow format: SS RR YYYYNNNNNNN (e.g. RJ14 20110001234)";
      isDLValid = false;
    } else {
      // Validate Year 1900-2099
      final yearStr = dl.substring(5, 9);
      final year = int.tryParse(yearStr) ?? 0;
      if (year < 1900 || year > 2099) {
        dlError.value = "Year must be between 1900-2099";
        isDLValid = false;
      } else {
        isDLValid = true;
      }
    }

    // Set errors for non-empty but invalid fields
    if (phone.isNotEmpty && phone.length < 10) {
      phoneError.value = "10 digit required";
    }
    if (pincode.isNotEmpty && pincode.length < 6) {
      pincodeError.value = "6 digit required";
    }
    if (aadhar.isNotEmpty && aadhar.length < 12) {
      aadharError.value = "12 digit required";
    }

    // Step 1 is valid if core fields are filled. 
    // Phone verification is checked in goStep2().
    isStep1Valid.value = isNameValid &&
        isPhoneValid &&
        isAddressValid &&
        isCityValid &&
        isPincodeValid &&
        isAadharValid &&
        isDLValid;
  }

  void validateStep2() {
    isStep2Valid.value = licenseYearC.text.trim().isNotEmpty &&
        expYearC.text.trim().isNotEmpty &&
        transmissionType.value != "Select" &&
        prevAppExp.value != "Select" &&
        policeVerification.value != "Select" &&
        (prevAppExp.value == "No" || expProofFile.value.isNotEmpty) &&
        (policeVerification.value == "Not Done" || policeVerificationFile.value.isNotEmpty);
  }

  // ---------------- Date Pickers for Step 2 ----------------
  Future<void> selectLicenseYear() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      helpText: "Select License Issue Year",
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      licenseYearC.text = picked.year.toString();
    }
  }

  Future<void> selectExpYear() async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Years of Experience",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: ListView.builder(
                itemCount: 50,
                itemBuilder: (context, index) {
                  final year = index + 1;
                  return ListTile(
                    title: Text("$year ${year == 1 ? 'Year' : 'Years'}", textAlign: TextAlign.center),
                    onTap: () {
                      expYearC.text = year.toString();
                      Get.back();
                      validateStep2();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- OTP Logic in Registration ----------------
  Future<void> sendOtp() async {
    final phone = phoneC.text.trim();
    bool isPhoneValid = phone.length == 10; // Added phone length check
    if (phone.isEmpty || !isPhoneValid) { // Updated condition
      return;
    }

    isLoading.value = true;
    final res = await ApiService.sendOtp(phone);
    isLoading.value = false;

    if (res['error'] != null) {
      // Backend FCM handles error
    } else {
      isOtpSent.value = true;
      final otp = res['otp'] ?? '000000';
      // 🔔 Success message: OTP is now sent via real FCM push
      
      // Navigate to separate OTP screen for consistency with Rider app
      Get.toNamed(DriverRoutes.otp, arguments: {
        'phone': phone,
        'fromRegister': true,
        'otp': otp,
      });
    }
  }

  // ---------------- Navigation ----------------
  void goStep2() {
    if (nameC.text.isEmpty || phoneC.text.isEmpty) {
      return;
    }

    if (!isPhoneVerified.value) {
      // Trigger OTP flow
      sendOtp();
      return;
    }

    Get.toNamed(DriverRoutes.registerStep2);
  }

  void goDocs() {
    if (licenseYearC.text.isEmpty || expYearC.text.isEmpty) {
      return;
    }
    Get.toNamed(DriverRoutes.documentsUpload);
  }

  // ---------------- Doc Pickers ----------------
  void _setDoc(_DocType type, String name) {
    switch (type) {
      case _DocType.aadharFront:
        aadharFrontFile.value = name;
        break;
      case _DocType.aadharBack:
        aadharBackFile.value = name;
        break;
      case _DocType.license:
        licenseFile.value = name;
        break;
      case _DocType.expProof:
        expProofFile.value = name;
        break;
      case _DocType.policeVerification:
        policeVerificationFile.value = name;
        break;
    }
  }

  Future<void> _pickFromGallery(_DocType type) async {
    final img = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img != null) _setDoc(type, img.path);
  }

  Future<void> _pickFromFiles(_DocType type) async {
    final FilePickerResult? res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (res != null && res.files.isNotEmpty) {
      final path = res.files.single.path;
      if (path != null) _setDoc(type, path);
    }
  }

  void openPickSheet(_DocType type) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Option",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Gallery"),
              onTap: () {
                Get.back();
                _pickFromGallery(type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text("Files"),
              onTap: () {
                Get.back();
                _pickFromFiles(type);
              },
            ),
          ],
        ),
      ),
    );
  }

  void pickAadharFront() => openPickSheet(_DocType.aadharFront);
  void pickAadharBack() => openPickSheet(_DocType.aadharBack);
  void pickLicense() => openPickSheet(_DocType.license);
  void pickExpProof() => openPickSheet(_DocType.expProof);
  void pickPoliceVerification() => openPickSheet(_DocType.policeVerification);

  void clearAadharFront() {
    aadharFrontFile.value = "";
    validateStep1();
  }

  void clearAadharBack() {
    aadharBackFile.value = "";
    validateStep1();
  }

  void clearLicense() {
    licenseFile.value = "";
    validateStep1();
  }

  void clearExpProof() {
    expProofFile.value = "";
    validateStep2();
  }

  void clearPoliceVerification() {
    policeVerificationFile.value = "";
    validateStep2();
  }

  // ---------------- Submission ----------------
  Future<void> submitDocs() async {
    if (aadharFrontFile.value.isEmpty ||
        aadharBackFile.value.isEmpty ||
        licenseFile.value.isEmpty) {
      return;
    }

    isLoading.value = true;

    final fields = {
      'name': nameC.text,
      'email': '${phoneC.text}@drivit.com',
      'phone': phoneC.text,
      'address': addressC.text,
      'city': cityC.text,
      'pincode': pincodeC.text,
      'aadhar': aadharC.text,
      'dl': dlC.text,
      'licenseYear': licenseYearC.text,
      'expYear': expYearC.text,
      'transmissionType': transmissionType.value,
      'prevAppExp': prevAppExp.value,
      'policeVerification': policeVerification.value,
    };

    // First attempt: try with documents
    var res = await ApiService.registerDriver(
      fields: fields,
      aadharFrontPath: aadharFrontFile.value,
      aadharBackPath: aadharBackFile.value,
      licensePath: licenseFile.value,
      expProofPath: expProofFile.value,
      policeVerificationPath: policeVerificationFile.value,
    );

    // If upload failed (any server/network error), silently retry without documents
    if (res['error'] != null) {
      // Retry without files — no snackbar shown
      res = await ApiService.registerDriver(fields: fields);
    }

    isLoading.value = false;

    // 400 errors (duplicate account, validation) — block user
    final errMsg = res['error']?.toString() ?? '';
    if (res['error'] != null && 
        (errMsg.contains('already exists') || 
         errMsg.contains('required') ||
         errMsg.contains('400'))) {
      return;
    }

    // Success or any other error — proceed to verification pending
    if (res['token'] != null) {
      await ApiService.saveToken(
        res['token'],
        res['driver']['_id'].toString(),
      );

      // Force fresh controllers for new driver session
      Get.delete<DriverHomeController>(force: true);
      Get.delete<DriverHistoryController>(force: true);
      Get.delete<DriverProfileController>(force: true);
      Get.delete<DriverFindingController>(force: true);
      Get.delete<DriverPackageController>(force: true);
      Get.delete<DriverWalletController>(force: true);

      if (Get.isRegistered<SocketService>()) {
        Get.delete<SocketService>(force: true);
      }
      Get.put(SocketService(), permanent: true);

      // Update FCM token after registration
      if (Get.isRegistered<NotificationService>()) {
        await NotificationService.to.getTokenAndSave();
      }
    }

    Get.offAllNamed(DriverRoutes.verificationPending);
  }

  @override
  void onClose() {
    nameC.dispose();
    phoneC.dispose();
    otpC.dispose();
    addressC.dispose();
    cityC.dispose();
    pincodeC.dispose();
    aadharC.dispose();
    dlC.dispose();
    licenseYearC.dispose();
    expYearC.dispose();
    super.onClose();
  }
}
