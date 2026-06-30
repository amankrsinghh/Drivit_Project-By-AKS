import 'package:get/get.dart';

import '../core/middleware/auth_middleware.dart';
import '../modules/auth/car_details/binding/car_details_binding.dart';
import '../modules/auth/car_details/view/car_details_view.dart';
import '../modules/auth/login/binding/login_binding.dart';
import '../modules/auth/login/view/login_view.dart';
import '../modules/auth/login/view/otp_view.dart';
import '../modules/auth/register/binding/register_binding.dart';
import '../modules/auth/register/view/register_view.dart';

import '../modules/home/binding/home_binding.dart';
import '../modules/home/view/home_screen.dart';
import '../modules/home/views/notification_view.dart';

import '../modules/map/bindings/map_binding.dart';
import '../modules/map/select_ride/bindings/select_ride_binding.dart';
import '../modules/map/select_ride/views/select_ride_view.dart';
import '../modules/map/views/map_confirm_view.dart';

import '../modules/finding_drivers/bindings/finding_driver_binding.dart';
import '../modules/finding_drivers/views/finding_driver_view.dart';
import '../modules/finding_drivers/views/payment_success_view.dart';
import '../modules/finding_drivers/views/ride_otp_view.dart';

import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/chat/binding/chat_binding.dart';
import '../modules/chat/view/chat_view.dart';

import '../modules/tariffs/bindings/tariffs_binding.dart';
import '../modules/tariffs/views/tariffs_view.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/car_clinic/bindings/car_clinic_binding.dart';
import '../modules/car_clinic/views/car_clinic_view.dart';

import 'app_routes.dart';

class AppPages {
  static const initial = Routes.splash;

  // Auth-only middleware (applied to every protected page)
  static final _auth = [AuthMiddleware()];

  static final routes = <GetPage>[
    // ─── PUBLIC routes (no middleware) ──────────────────────────────────────
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
      children: [
        GetPage(
          name: "/otp",
          page: () => const OtpView(),
        ),
      ],
    ),

    GetPage(
      name: Routes.register,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),

    // ─── PROTECTED routes (require login) ───────────────────────────────────
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      middlewares: _auth,
    ),

    GetPage(
      name: Routes.carDetails,
      page: () => const CarDetailsView(),
      binding: CarDetailsBinding(),
    ),

    GetPage(
      name: Routes.selectRide,
      page: () => const SelectRideView(),
      bindings: [MapBinding(), SelectRideBinding()],
      middlewares: _auth,
    ),

    GetPage(
      name: Routes.findingDriver,
      page: () => const FindingDriverView(),
      bindings: [MapBinding(), FindingDriverBinding()],
      middlewares: _auth,
    ),

    GetPage(
      name: Routes.paymentSuccess,
      page: () => const PaymentSuccessView(),
      middlewares: _auth,
    ),

    GetPage(
      name: Routes.mapConfirm,
      page: () => const MapConfirmView(),
      binding: MapBinding(),
    ),

    GetPage(
      name: Routes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.chat,
      page: () => const ChatView(),
      binding: ChatBinding(),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.notifications,
      page: () => const NotificationView(),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.rideOtp,
      page: () => const RideOtpView(),
      binding: FindingDriverBinding(),
    ),
    GetPage(
      name: Routes.tariffs,
      page: () => const TariffsView(),
      binding: TariffsBinding(),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.CAR_CLINIC,
      page: () => const CarClinicView(),
      binding: CarClinicBinding(),
      middlewares: _auth,
    ),
  ];
}
