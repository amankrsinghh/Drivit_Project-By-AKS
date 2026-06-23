abstract class DriverRoutes {
  static const splash = '/driver/splash';
  static const login = '/driver/login';
  static const otp = '/driver/otp';

  static const registerStep1 = '/driver/register-step1';
  static const registerStep2 = '/driver/register-step2';
  static const documentsUpload = '/driver/documents-upload';

  static const verificationPending = '/driver/verification-pending';
  static const verificationApproved = '/driver/verification-approved';

  static const home = '/driver/home';

  // Trip flow
  static const newRequest = '/driver/trip/new-request';
  static const afterAcceptLocation = '/driver/trip/after-accept-location';
  static const atLocation = '/driver/trip/at-location';
  static const quickCheck = '/driver/trip/quick-check';
  static const reachDestination = '/driver/trip/reach-destination';
  static const tripEarning = '/driver/trip/trip-earning';

  // History
  static const tripDetails = '/driver/history/trip-details';

  // Profile
  static const wallet = '/driver/profile/wallet';
  static const privacy = '/driver/profile/privacy-policy';
  static const terms = '/driver/profile/terms';
  static const rateUs = '/driver/profile/rate-us';

  // (Optional) agar aap use karte ho
  static const addAmount = '/driver/profile/add-amount';
  static const aboutUs = '/driver/profile/about-us';
  static const contactSupport = '/contact-support';
  static const chat = '/chat';
  static const contactUs = '/driver/profile/contact-us';
  static const notifications = '/driver/notifications';
  static const editProfile = '/driver/profile/edit-profile';

}
