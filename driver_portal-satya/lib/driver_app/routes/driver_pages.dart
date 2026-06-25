import 'package:get/get.dart';
import '../profile/views/driver_about_us-view.dart';
import '../profile/views/driver_add_ammount_view.dart';
import '../profile/views/driver_edit_profile.dart';

import '../profile/views/driver_terms_conditions_view.dart';
import '../profile/views/driver_contact_us_view.dart';
import '../chat/views/driver_chat_view.dart';
import '../chat/bindings/driver_chat_binding.dart';
import '../splash/views/driver_splash_view.dart';
import 'driver_routes.dart';

// Auth bindings + views
import '../auth/bindings/driver_login_binding.dart';
import '../auth/bindings/driver_otp_binding.dart';
import '../auth/bindings/driver_register_binding.dart';

import '../auth/views/driver_login_view.dart';
import '../auth/views/driver_otp_view.dart';
import '../auth/views/driver_register_step1_view.dart';
import '../auth/views/driver_register_step2_view.dart';
import '../auth/views/driver_documents_upload_view.dart';

// Verification
import '../verification/views/verification_pending_view.dart';
import '../verification/views/verification_approved_view.dart';

// Home
import '../home/bindings/driver_home_binding.dart';
import '../home/views/driver_home_view.dart';

// History
import '../history/views/driver_trip_details_view.dart';

// Profile
import '../profile/views/driver_wallet_view.dart';
import '../profile/views/driver_privacy_policy_view.dart';
import '../profile/views/driver_rate_us_view.dart';

// Trip
import '../trip/views/new_request_view.dart';
import '../trip/views/after_accept_location_view.dart';
import '../trip/controllers/driver_new_request_controller.dart';

// ✅ ADD THESE (QuickCheck flow)
import '../trip/bindings/driver_trip_binding.dart';
import '../trip/views/quick_check_view.dart';
import '../trip/views/reach_destination_view.dart';
import '../trip/views/trip_earning_view.dart';

import '../home/views/driver_notification_view.dart';

class DriverPages {
  static final pages = <GetPage>[
    GetPage(name: DriverRoutes.splash, page: () => const DriverSplashView()),
    GetPage(
      name: DriverRoutes.notifications,
      page: () => const DriverNotificationView(),
      binding: DriverHomeBinding(),
    ),
    GetPage(
      name: DriverRoutes.login,
      page: () => const DriverLoginView(),
      binding: DriverLoginBinding(),
    ),
    GetPage(
      name: DriverRoutes.otp,
      page: () => const DriverOtpView(),
      binding: DriverOtpBinding(),
    ),

    GetPage(
      name: DriverRoutes.registerStep1,
      page: () => const DriverRegisterStep1View(),
      binding: DriverRegisterBinding(),
    ),
    GetPage(
      name: DriverRoutes.registerStep2,
      page: () => const DriverRegisterStep2View(),
      binding: DriverRegisterBinding(),
    ),
    GetPage(
      name: DriverRoutes.documentsUpload,
      page: () => const DriverDocumentsUploadView(),
      binding: DriverRegisterBinding(),
    ),

    GetPage(
      name: DriverRoutes.verificationPending,
      page: () => const VerificationPendingView(),
    ),
    GetPage(
      name: DriverRoutes.verificationApproved,
      page: () => const VerificationApprovedView(),
    ),

    GetPage(
      name: DriverRoutes.home,
      page: () => const DriverHomeView(),
      binding: DriverHomeBinding(),
    ),

    // Trip flow
    GetPage(
      name: DriverRoutes.newRequest,
      page: () => const DriverNewRequestView(),
      binding: BindingsBuilder(() {
        Get.put(DriverNewRequestController());
      }),
    ),
    GetPage(
      name: DriverRoutes.afterAcceptLocation,
      page: () => const DriverAfterAcceptLocationView(),
      binding: DriverTripBinding(),
    ),

    // ✅ THIS WAS MISSING (isliye quickCheck open nahi ho raha tha)
    GetPage(
      name: DriverRoutes.quickCheck,
      page: () => const DriverQuickCheckView(),
      binding: DriverTripBinding(),
    ),
    GetPage(
      name: DriverRoutes.reachDestination,
      page: () => const DriverReachDestinationView(),
      binding: DriverTripBinding(),
    ),
    GetPage(
      name: DriverRoutes.tripEarning,
      page: () => const DriverTripEarningView(),
      binding: DriverTripBinding(),
    ),

    GetPage(
      name: DriverRoutes.tripDetails,
      page: () => const DriverTripDetailsView(),
      binding: DriverHomeBinding(),
    ),

    GetPage(name: DriverRoutes.wallet, page: () => const DriverWalletView()),

    GetPage(
      name: DriverRoutes.addAmount,
      page: () => const DriverAddAmountView(),
    ),
    GetPage(name: DriverRoutes.aboutUs, page: () => const DriverAboutUsView()),
    GetPage(
      name: DriverRoutes.contactUs,
      page: () => const DriverContactUsView(),
    ),
    GetPage(
      name: DriverRoutes.privacy,
      page: () => const DriverPrivacyPolicyView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: DriverRoutes.terms,
      page: () => const DriverTermsConditionsView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(name: DriverRoutes.rateUs, page: () => const DriverRateUsView()),

    GetPage(
      name: DriverRoutes.editProfile,
      
      page: () => const DriverEditProfileView(),
    ),
    GetPage(
      name: DriverRoutes.chat,
      page: () => const DriverChatView(),
      bindings: [DriverChatBinding(), DriverHomeBinding()],
    ),
  ];
}
