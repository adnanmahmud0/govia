import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/core/middleware/auth_middleware.dart';
import 'package:gsabino365/module/shared/forgot_password/binding/forgot_password_binding.dart';
import 'package:gsabino365/module/shared/forgot_password/view/forgot_password_view.dart';
import 'package:gsabino365/module/shared/splash/splash_binding.dart';
import 'package:gsabino365/module/shared/splash/splash_view.dart';
import 'package:gsabino365/module/shared/onbording/binding/onboarding_binding.dart';
import 'package:gsabino365/module/shared/onbording/view/onboarding_view.dart';
import 'package:gsabino365/module/shared/login/binding/login_binding.dart';
import 'package:gsabino365/module/shared/login/view/login_view.dart';
import 'package:gsabino365/module/shared/otp_verification/binding/otp_verification_binding.dart';
import 'package:gsabino365/module/shared/otp_verification/view/otp_verification_view.dart';
import 'package:gsabino365/module/shared/reset_password/binding/reset_password_binding.dart';
import 'package:gsabino365/module/shared/reset_password/view/reset_password_view.dart';
import 'package:gsabino365/module/shared/register/binding/register_binding.dart';
import 'package:gsabino365/module/shared/register/view/register_view.dart';
import 'package:gsabino365/module/shared/citizen_register/binding/citizen_register_binding.dart';
import 'package:gsabino365/module/shared/citizen_register/view/citizen_register_view.dart';
import 'package:gsabino365/module/shared/attorney_register/binding/attorney_register_binding.dart';
import 'package:gsabino365/module/shared/attorney_register/view/attorney_register_view.dart';
import 'package:gsabino365/module/shared/mental_health_register/binding/mental_health_register_binding.dart';
import 'package:gsabino365/module/shared/mental_health_register/view/mental_health_register_view.dart';
import 'package:gsabino365/module/shared/police_register/binding/police_register_binding.dart';
import 'package:gsabino365/module/shared/police_register/view/police_register_view.dart';
import 'package:gsabino365/module/shared/bail_bondsman_register/binding/bail_bondsman_register_binding.dart';
import 'package:gsabino365/module/shared/bail_bondsman_register/view/bail_bondsman_register_view.dart';
import 'package:gsabino365/module/shared/subscription/binding/subscription_binding.dart';
import 'package:gsabino365/module/shared/subscription/view/subscription_view.dart';

// Parent bottom nav bar bindings/views
import 'package:gsabino365/module/citizen/bottom_nav_bar/binding/bottom_nav_bar_binding.dart';
import 'package:gsabino365/module/citizen/bottom_nav_bar/view/bottom_nav_bar_view.dart';
import 'package:gsabino365/module/attorney/bottom_nav_bar/binding/bottom_nav_bar_binding.dart';
import 'package:gsabino365/module/attorney/bottom_nav_bar/view/bottom_nav_bar_view.dart';
import 'package:gsabino365/module/doctore/bottom_nav_bar/binding/bottom_nav_bar_binding.dart';
import 'package:gsabino365/module/doctore/bottom_nav_bar/view/bottom_nav_bar_view.dart';
import 'package:gsabino365/module/police/bottom_nav_bar/binding/bottom_nav_bar_binding.dart';
import 'package:gsabino365/module/police/bottom_nav_bar/view/bottom_nav_bar_view.dart';
import 'package:gsabino365/module/bail_bondsman/bottom_nav_bar/binding/bottom_nav_bar_binding.dart';
import 'package:gsabino365/module/bail_bondsman/bottom_nav_bar/view/bottom_nav_bar_view.dart';

// Citizen sub-tab views & bindings
import 'package:gsabino365/module/citizen/home/binding/citizen_home_binding.dart';
import 'package:gsabino365/module/citizen/home/view/citizen_home_view.dart';
import 'package:gsabino365/module/citizen/community/binding/citizen_community_binding.dart';
import 'package:gsabino365/module/citizen/community/view/citizen_community_view.dart';
import 'package:gsabino365/module/citizen/vault/binding/citizen_vault_binding.dart';
import 'package:gsabino365/module/citizen/vault/view/citizen_vault_view.dart';
import 'package:gsabino365/module/citizen/vault/view/vault_folder_details_view.dart';

import 'package:gsabino365/module/citizen/profile/binding/citizen_profile_binding.dart';
import 'package:gsabino365/module/citizen/profile/view/citizen_profile_view.dart';
import 'package:gsabino365/module/citizen/notification/binding/citizen_notification_binding.dart';
import 'package:gsabino365/module/citizen/notification/view/citizen_notification_view.dart';
import 'package:gsabino365/module/shared/personal_infrmation/binding/personal_info_binding.dart';
import 'package:gsabino365/module/shared/personal_infrmation/view/personal_info_view.dart';
import 'package:gsabino365/module/shared/preferred_providers/binding/preferred_providers_binding.dart';
import 'package:gsabino365/module/shared/preferred_providers/view/preferred_providers_view.dart';
import 'package:gsabino365/module/shared/provider_pricing_payouts/binding/provider_pricing_payouts_binding.dart';
import 'package:gsabino365/module/shared/provider_pricing_payouts/view/provider_pricing_payouts_view.dart';
import 'package:gsabino365/module/shared/settings/binding/settings_binding.dart';
import 'package:gsabino365/module/shared/settings/view/settings_view.dart';
import 'package:gsabino365/module/shared/settings/change_password/binding/change_password_binding.dart';
import 'package:gsabino365/module/shared/settings/change_password/view/change_password_view.dart';
import 'package:gsabino365/module/shared/settings/privacy_policy/view/privacy_policy_view.dart';
import 'package:gsabino365/module/shared/settings/terms_conditions/view/terms_conditions_view.dart';
import 'package:gsabino365/module/citizen/encounter_history/binding/encounter_history_binding.dart';
import 'package:gsabino365/module/citizen/encounter_history/view/encounter_history_view.dart';
import 'package:gsabino365/module/citizen/encounter_history/location/view/incident_location_view.dart';
import 'package:gsabino365/module/shared/referral/binding/referral_binding.dart';
import 'package:gsabino365/module/shared/referral/view/referral_view.dart';
import 'package:gsabino365/module/shared/gifting/binding/gifting_binding.dart';
import 'package:gsabino365/module/shared/gifting/view/gifting_hub_view.dart';
import 'package:gsabino365/module/shared/gifting/gift_safety/binding/gift_safety_binding.dart';
import 'package:gsabino365/module/shared/gifting/gift_safety/view/gift_safety_view.dart';
import 'package:gsabino365/module/shared/gifting/organization_details/binding/organization_details_binding.dart';
import 'package:gsabino365/module/shared/gifting/organization_details/view/organization_details_view.dart';
import 'package:gsabino365/module/citizen/highlight_hero/binding/highlight_hero_binding.dart';
import 'package:gsabino365/module/citizen/highlight_hero/view/highlight_hero_view.dart';
import 'package:gsabino365/module/citizen/mental_health/binding/mental_health_binding.dart';
import 'package:gsabino365/module/citizen/mental_health/view/mental_health_view.dart';
import 'package:gsabino365/module/citizen/live_call/binding/live_call_binding.dart';
import 'package:gsabino365/module/citizen/live_call/view/live_call_view.dart';
import 'package:gsabino365/module/citizen/live_call/view/live_call_connecting_view.dart';

// Attorney sub-tab views & bindings
import 'package:gsabino365/module/attorney/home/binding/attorney_home_binding.dart';
import 'package:gsabino365/module/attorney/home/view/attorney_home_view.dart';
import 'package:gsabino365/module/attorney/schedule/binding/attorney_schedule_binding.dart';
import 'package:gsabino365/module/attorney/schedule/view/attorney_schedule_view.dart';
import 'package:gsabino365/module/attorney/notification/binding/attorney_notification_binding.dart';
import 'package:gsabino365/module/attorney/notification/view/attorney_notification_view.dart';
import 'package:gsabino365/module/attorney/profile/binding/attorney_profile_binding.dart';
import 'package:gsabino365/module/attorney/profile/view/attorney_profile_view.dart';

import 'package:gsabino365/module/attorney/evidence_vault/binding/attorney_evidence_vault_binding.dart';
import 'package:gsabino365/module/attorney/evidence_vault/view/attorney_evidence_vault_view.dart';
import 'package:gsabino365/module/attorney/subpoena_request/binding/attorney_subpoena_request_binding.dart';
import 'package:gsabino365/module/attorney/subpoena_request/view/attorney_subpoena_request_view.dart';
import 'package:gsabino365/module/attorney/active_requests/binding/attorney_active_requests_binding.dart';
import 'package:gsabino365/module/attorney/active_requests/view/attorney_active_requests_view.dart';
import 'package:gsabino365/module/attorney/live_call/binding/attorney_live_call_binding.dart';
import 'package:gsabino365/module/attorney/live_call/view/attorney_live_call_view.dart';
import 'package:gsabino365/module/shared/govia_ai/binding/govia_ai_binding.dart';
import 'package:gsabino365/module/shared/govia_ai/view/govia_ai_view.dart';
import 'package:gsabino365/module/shared/chat/binding/chat_binding.dart';
import 'package:gsabino365/module/shared/chat/view/chat_list_view.dart';
import 'package:gsabino365/module/shared/chat/view/chat_details_view.dart';

// Doctor sub-tab views & bindings
import 'package:gsabino365/module/doctore/home/binding/doctor_home_binding.dart';
import 'package:gsabino365/module/doctore/home/view/doctor_home_view.dart';
import 'package:gsabino365/module/doctore/schedule/binding/doctor_schedule_binding.dart';
import 'package:gsabino365/module/doctore/schedule/view/doctor_schedule_view.dart';
import 'package:gsabino365/module/doctore/notification/binding/doctor_notification_binding.dart';
import 'package:gsabino365/module/doctore/notification/view/doctor_notification_view.dart';
import 'package:gsabino365/module/doctore/profile/binding/doctor_profile_binding.dart';
import 'package:gsabino365/module/doctore/profile/view/doctor_profile_view.dart';
import 'package:gsabino365/module/doctore/history/binding/doctor_history_binding.dart';
import 'package:gsabino365/module/doctore/history/view/doctor_history_view.dart';

import 'package:gsabino365/module/doctore/dispatch/binding/doctor_dispatch_binding.dart';
import 'package:gsabino365/module/doctore/dispatch/view/doctor_dispatch_view.dart';
import 'package:gsabino365/module/doctore/dispatch/view/doctor_request_emt_view.dart';
import 'package:gsabino365/module/doctore/dispatch/view/doctor_request_crisis_view.dart';
import 'package:gsabino365/module/doctore/dispatch/binding/doctor_request_community_binding.dart';
import 'package:gsabino365/module/doctore/dispatch/view/doctor_request_community_view.dart';
import 'package:gsabino365/module/doctore/active_sessions/binding/doctor_active_sessions_binding.dart';
import 'package:gsabino365/module/doctore/active_sessions/view/doctor_active_sessions_view.dart';
import 'package:gsabino365/module/doctore/active_sessions/binding/doctor_transfer_session_binding.dart';
import 'package:gsabino365/module/doctore/active_sessions/view/doctor_transfer_session_view.dart';
import 'package:gsabino365/module/doctore/active_sessions/binding/doctor_live_call_binding.dart';
import 'package:gsabino365/module/doctore/active_sessions/view/doctor_live_call_view.dart';

// Police sub-tab views & bindings
import 'package:gsabino365/module/police/home/binding/police_home_binding.dart';
import 'package:gsabino365/module/police/home/view/police_home_view.dart';
import 'package:gsabino365/module/police/schedule/binding/police_schedule_binding.dart';
import 'package:gsabino365/module/police/schedule/view/police_schedule_view.dart';
import 'package:gsabino365/module/police/notification/binding/police_notification_binding.dart';
import 'package:gsabino365/module/police/notification/view/police_notification_view.dart';
import 'package:gsabino365/module/police/profile/binding/police_profile_binding.dart';
import 'package:gsabino365/module/police/profile/view/police_profile_view.dart';
import 'package:gsabino365/module/police/birds_eye/binding/police_birds_eye_binding.dart';
import 'package:gsabino365/module/police/birds_eye/view/police_birds_eye_view.dart';
import 'package:gsabino365/module/police/birds_eye/binding/police_crisis_management_binding.dart';
import 'package:gsabino365/module/police/birds_eye/view/police_crisis_management_view.dart';

// Bail Bondsman sub-tab views & bindings
import 'package:gsabino365/module/bail_bondsman/home/binding/bail_bondsman_home_binding.dart';
import 'package:gsabino365/module/bail_bondsman/home/view/bail_bondsman_home_view.dart';
import 'package:gsabino365/module/bail_bondsman/schedule/binding/bail_bondsman_schedule_binding.dart';
import 'package:gsabino365/module/bail_bondsman/schedule/view/bail_bondsman_schedule_view.dart';
import 'package:gsabino365/module/bail_bondsman/notification/binding/bail_bondsman_notification_binding.dart';
import 'package:gsabino365/module/bail_bondsman/notification/view/bail_bondsman_notification_view.dart';
import 'package:gsabino365/module/bail_bondsman/profile/binding/bail_bondsman_profile_binding.dart';
import 'package:gsabino365/module/bail_bondsman/profile/view/bail_bondsman_profile_view.dart';
import 'package:gsabino365/module/bail_bondsman/active_requests/binding/bail_bondsman_active_requests_binding.dart';
import 'package:gsabino365/module/bail_bondsman/active_requests/view/bail_bondsman_active_requests_view.dart';
import 'package:gsabino365/module/bail_bondsman/history/binding/bail_bondsman_history_binding.dart';
import 'package:gsabino365/module/bail_bondsman/history/view/bail_bondsman_history_view.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String bottomNavBar = '/bottom-nav-bar';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String changePassword = '/change-password';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsAndConditions = '/terms-conditions';
  static const String welcomePage = '/welcome-page';
  static const String whatYourSpeciality = '/what-your-speciality';
  static const String preferredNoteMethod = '/preferred-note-method';
  static const String interactiveTutorial = '/interactive-tutorial';
  static const String verifyEmail = '/verify-email';
  static const String otpVerification = '/otp-verification';
  static const String cardDetails = '/card-details';
  static const String myCards = '/my-cards';
  static const String subscription = '/subscription';
  static const String eventDetails = '/event-details';
  static const String citizenRegister = '/citizen-register';
  static const String attorneyRegister = '/attorney-register';
  static const String mentalHealthRegister = '/mental-health-register';
  static const String policeRegister = '/police-register';
  static const String bailBondsmanRegister = '/bail-bondsman-register';

  // Dashboard primary shells
  static const String citizenDashboard = '/citizen-dashboard';
  static const String attorneyDashboard = '/attorney-dashboard';
  static const String doctorDashboard = '/doctor-dashboard';
  static const String policeDashboard = '/police-dashboard';
  static const String bailBondsmanDashboard = '/bail-bondsman-dashboard';

  // Citizen standalone sub-tabs
  static const String citizenHome = '/citizen-home';
  static const String citizenCommunity = '/citizen-community';
  static const String citizenNotification = '/citizen-notification';
  static const String citizenVault = '/citizen-vault';
  static const String citizenVaultFolderDetails =
      '/citizen-vault-folder-details';
  static const String citizenProfile = '/citizen-profile';
  static const String citizenPersonalInfo = '/citizen-personal-info';
  static const String preferredProviders = '/preferred-providers';
  static const String providerPricingPayouts = '/provider-pricing-payouts';
  static const String citizenSettings = '/citizen-settings';
  static const String citizenEncounterHistory = '/citizen-encounter-history';
  static const String citizenIncidentLocation = '/citizen-incident-location';
  static const String referral = '/referral';
  static const String giftingHub = '/gifting-hub';
  static const String giftSafety = '/gift-safety';
  static const String organizationDetails = '/organization-details';
  static const String citizenHighlightHero = '/citizen-highlight-hero';
  static const String citizenMentalHealth = '/citizen-mental-health';
  static const String citizenLiveCall = '/citizen-live-call';
  static const String citizenLiveCallConnecting =
      '/citizen-live-call-connecting';

  // Attorney standalone sub-tabs
  static const String attorneyHome = '/attorney-home';
  static const String attorneySchedule = '/attorney-schedule';
  static const String attorneyNotification = '/attorney-notification';
  static const String attorneyProfile = '/attorney-profile';
  static const String attorneyPersonalInfo = '/attorney-personal-info';
  static const String attorneySettings = '/attorney-settings';

  static const String attorneyEvidenceVault = '/attorney-evidence-vault';
  static const String attorneySubpoenaRequest = '/attorney-subpoena-request';
  static const String attorneyActiveRequests = '/attorney-active-requests';
  static const String attorneyLiveCall = '/attorney-live-call';
  static const String attorneyGoviaAi = '/attorney-govia-ai';
  static const String attorneyChatList = '/attorney-chat-list';
  static const String attorneyChatDetails = '/attorney-chat-details';

  // Doctor standalone sub-tabs
  static const String doctorHome = '/doctor-home';
  static const String doctorSchedule = '/doctor-schedule';
  static const String doctorNotification = '/doctor-notification';
  static const String doctorProfile = '/doctor-profile';
  static const String doctorPersonalInfo = '/doctor-personal-info';
  static const String doctorSettings = '/doctor-settings';
  static const String doctorHistory = '/doctor-history';

  static const String doctorDispatch = '/doctor-dispatch';
  static const String doctorRequestEmt = '/doctor-request-emt';
  static const String doctorRequestCrisis = '/doctor-request-crisis';
  static const String doctorRequestCommunity = '/doctor-request-community';
  static const String doctorActiveSessions = '/doctor-active-sessions';
  static const String doctorTransferSession = '/doctor-transfer-session';
  static const String doctorLiveCall = '/doctor-live-call';

  // Police standalone sub-tabs
  static const String policeHome = '/police-home';
  static const String policeSchedule = '/police-schedule';
  static const String policeNotification = '/police-notification';
  static const String policeProfile = '/police-profile';
  static const String policeBirdsEye = '/police-birds-eye';
  static const String policeSettings = '/police-settings';
  static const String policePersonalInfo = '/police-personal-info';
  static const String policeCrisisManagement = '/police-crisis-management';

  // Bail Bondsman standalone sub-tabs
  static const String bailBondsmanHome = '/bail-bondsman-home';
  static const String bailBondsmanSchedule = '/bail-bondsman-schedule';
  static const String bailBondsmanNotification = '/bail-bondsman-notification';
  static const String bailBondsmanProfile = '/bail-bondsman-profile';
  static const String bailBondsmanActiveRequests =
      '/bail-bondsman-active-requests';
  static const String bailBondsmanPersonalInfo = '/bail-bondsman-personal-info';
  static const String bailBondsmanSettings = '/bail-bondsman-settings';
  static const String bailBondsmanHistory = '/bail-bondsman-history';
}

final Transition transition = Transition.rightToLeft;

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('App is running!')),
      bottomNavigationBar: TextButton(
        onPressed: () {
          Get.offAllNamed(AppRoutes.login);
        },
        child: const Text('Logout'),
      ),
    );
  }
}

final List<GetMiddleware> authGuards = [AuthMiddleware()];

final pages = [
  GetPage(
    name: AppRoutes.splash,
    page: () => const SplashView(),
    binding: SplashBinding(),
  ),
  GetPage(
    name: AppRoutes.onboarding,
    page: () => const OnboardingView(),
    binding: OnboardingBinding(),
  ),
  GetPage(
    name: AppRoutes.login,
    page: () => const LoginView(),
    binding: LoginBinding(),
  ),

  // Citizen dashboard & sub-pages
  GetPage(
    name: AppRoutes.citizenDashboard,
    page: () => const CitizenBottomNavBarView(),
    binding: CitizenBottomNavBarBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.citizenHome,
    page: () => const CitizenHomeView(),
    binding: CitizenHomeBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.citizenCommunity,
    page: () => const CitizenCommunityView(),
    binding: CitizenCommunityBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.citizenVault,
    page: () => const CitizenVaultView(),
    binding: CitizenVaultBinding(),
    middlewares: authGuards,
  ),

  GetPage(
    name: AppRoutes.citizenProfile,
    page: () => const CitizenProfileView(),
    binding: CitizenProfileBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.citizenNotification,
    page: () => const CitizenNotificationView(),
    binding: CitizenNotificationBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.citizenPersonalInfo,
    page: () => const PersonalInfoView(),
    binding: PersonalInfoBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.preferredProviders,
    page: () => const PreferredProvidersView(),
    binding: PreferredProvidersBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.providerPricingPayouts,
    page: () => const ProviderPricingPayoutsView(),
    binding: ProviderPricingPayoutsBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.settings,
    page: () => const SettingsView(),
    binding: SettingsBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.citizenSettings,
    page: () => const SettingsView(),
    binding: SettingsBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.citizenEncounterHistory,
    page: () => const EncounterHistoryView(),
    binding: EncounterHistoryBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.citizenIncidentLocation,
    page: () => const IncidentLocationView(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.citizenVaultFolderDetails,
    page: () => const VaultFolderDetailsView(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.referral,
    page: () => const ReferralView(),
    binding: ReferralBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.giftingHub,
    page: () => const GiftingHubView(),
    binding: GiftingBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.giftSafety,
    page: () => const GiftSafetyView(),
    binding: GiftSafetyBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.organizationDetails,
    page: () => const OrganizationDetailsView(),
    binding: OrganizationDetailsBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.citizenHighlightHero,
    page: () => const HighlightHeroView(),
    binding: HighlightHeroBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.citizenMentalHealth,
    page: () => const MentalHealthView(),
    binding: MentalHealthBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.citizenLiveCall,
    page: () => const LiveCallView(),
    binding: LiveCallBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.citizenLiveCallConnecting,
    page: () => const LiveCallConnectingView(),
    binding: LiveCallBinding(),
    middlewares: authGuards,
  ),

  // Attorney dashboard & sub-pages
  GetPage(
    name: AppRoutes.attorneyDashboard,
    page: () => const AttorneyBottomNavBarView(),
    binding: AttorneyBottomNavBarBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.attorneyHome,
    page: () => const AttorneyHomeView(),
    binding: AttorneyHomeBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.attorneySchedule,
    page: () => const AttorneyScheduleView(),
    binding: AttorneyScheduleBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.attorneyNotification,
    page: () => const AttorneyNotificationView(),
    binding: AttorneyNotificationBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.attorneyProfile,
    page: () => const AttorneyProfileView(),
    binding: AttorneyProfileBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.attorneyPersonalInfo,
    page: () => const PersonalInfoView(),
    binding: PersonalInfoBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.attorneySettings,
    page: () => const SettingsView(),
    binding: SettingsBinding(),
    middlewares: authGuards,
  ),

  GetPage(
    name: AppRoutes.attorneyEvidenceVault,
    page: () => const AttorneyEvidenceVaultView(),
    binding: AttorneyEvidenceVaultBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.attorneySubpoenaRequest,
    page: () => const AttorneySubpoenaRequestView(),
    binding: AttorneySubpoenaRequestBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.attorneyActiveRequests,
    page: () => const AttorneyActiveRequestsView(),
    binding: AttorneyActiveRequestsBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.attorneyLiveCall,
    page: () => const AttorneyLiveCallView(),
    binding: AttorneyLiveCallBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.attorneyGoviaAi,
    page: () => const GoviaAiView(),
    binding: GoviaAiBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.attorneyChatList,
    page: () => const ChatListView(),
    binding: ChatBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.attorneyChatDetails,
    page: () => const ChatDetailsView(),
    binding: ChatBinding(),
    middlewares: authGuards,
  ),

  // Doctor dashboard & sub-pages
  GetPage(
    name: AppRoutes.doctorDashboard,
    page: () => const DoctorBottomNavBarView(),
    binding: DoctorBottomNavBarBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.doctorHome,
    page: () => const DoctorHomeView(),
    binding: DoctorHomeBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.doctorSchedule,
    page: () => const DoctorScheduleView(),
    binding: DoctorScheduleBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.doctorNotification,
    page: () => const DoctorNotificationView(),
    binding: DoctorNotificationBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.doctorProfile,
    page: () => const DoctorProfileView(),
    binding: DoctorProfileBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.doctorPersonalInfo,
    page: () => const PersonalInfoView(),
    binding: PersonalInfoBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.doctorSettings,
    page: () => const SettingsView(),
    binding: SettingsBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.doctorHistory,
    page: () => const DoctorHistoryView(),
    binding: DoctorHistoryBinding(),
    middlewares: authGuards,
  ),

  GetPage(
    name: AppRoutes.doctorDispatch,
    page: () => const DoctorDispatchView(),
    binding: DoctorDispatchBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.doctorRequestEmt,
    page: () => const DoctorRequestEmtView(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.doctorRequestCrisis,
    page: () => const DoctorRequestCrisisView(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.doctorRequestCommunity,
    page: () => const DoctorRequestCommunityView(),
    binding: DoctorRequestCommunityBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.doctorActiveSessions,
    page: () => const DoctorActiveSessionsView(),
    binding: DoctorActiveSessionsBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.doctorTransferSession,
    page: () => const DoctorTransferSessionView(),
    binding: DoctorTransferSessionBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.doctorLiveCall,
    page: () => const DoctorLiveCallView(),
    binding: DoctorLiveCallBinding(),
    middlewares: authGuards,
  ),

  // Police dashboard & sub-pages
  GetPage(
    name: AppRoutes.policeDashboard,
    page: () => const PoliceBottomNavBarView(),
    binding: PoliceBottomNavBarBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.policeHome,
    page: () => const PoliceHomeView(),
    binding: PoliceHomeBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.policeSchedule,
    page: () => const PoliceScheduleView(),
    binding: PoliceScheduleBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.policeNotification,
    page: () => const PoliceNotificationView(),
    binding: PoliceNotificationBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.policeProfile,
    page: () => const PoliceProfileView(),
    binding: PoliceProfileBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.policeBirdsEye,
    page: () => const PoliceBirdsEyeView(),
    binding: PoliceBirdsEyeBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.policeSettings,
    page: () => const SettingsView(),
    binding: SettingsBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.policePersonalInfo,
    page: () => const PersonalInfoView(),
    binding: PersonalInfoBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.policeCrisisManagement,
    page: () => const PoliceCrisisManagementView(),
    binding: PoliceCrisisManagementBinding(),
    middlewares: authGuards,
  ),

  // Bail Bondsman dashboard & sub-pages
  GetPage(
    name: AppRoutes.bailBondsmanDashboard,
    page: () => const BailBondsmanBottomNavBarView(),
    binding: BailBondsmanBottomNavBarBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.bailBondsmanHome,
    page: () => const BailBondsmanHomeView(),
    binding: BailBondsmanHomeBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.bailBondsmanSchedule,
    page: () => const BailBondsmanScheduleView(),
    binding: BailBondsmanScheduleBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.bailBondsmanNotification,
    page: () => const BailBondsmanNotificationView(),
    binding: BailBondsmanNotificationBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.bailBondsmanProfile,
    page: () => const BailBondsmanProfileView(),
    binding: BailBondsmanProfileBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.bailBondsmanActiveRequests,
    page: () => const BailBondsmanActiveRequestsView(),
    binding: BailBondsmanActiveRequestsBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.bailBondsmanPersonalInfo,
    page: () => const PersonalInfoView(),
    binding: PersonalInfoBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.bailBondsmanSettings,
    page: () => const SettingsView(),
    binding: SettingsBinding(),
    middlewares: authGuards,
  ),
  GetPage(
    name: AppRoutes.bailBondsmanHistory,
    page: () => const BailBondsmanHistoryView(),
    binding: BailBondsmanHistoryBinding(),
    middlewares: authGuards,
  ),

  // Authentication Registers & others
  GetPage(
    name: AppRoutes.forgotPassword,
    page: () => const ForgotPasswordView(),
    binding: ForgotPasswordBinding(),
  ),
  GetPage(
    name: AppRoutes.changePassword,
    page: () => const ChangePasswordView(),
    binding: ChangePasswordBinding(),
    middlewares: authGuards,
  ),
  GetPage(name: AppRoutes.privacyPolicy, page: () => const PrivacyPolicyView()),
  GetPage(
    name: AppRoutes.termsAndConditions,
    page: () => const TermsConditionsView(),
  ),
  GetPage(
    name: AppRoutes.otpVerification,
    page: () => const OtpVerificationView(),
    binding: OtpVerificationBinding(),
  ),
  GetPage(
    name: AppRoutes.resetPassword,
    page: () => const ResetPasswordView(),
    binding: ResetPasswordBinding(),
  ),
  GetPage(
    name: AppRoutes.register,
    page: () => const RegisterView(),
    binding: RegisterBinding(),
  ),
  GetPage(
    name: AppRoutes.citizenRegister,
    page: () => const CitizenRegisterView(),
    binding: CitizenRegisterBinding(),
  ),
  GetPage(
    name: AppRoutes.attorneyRegister,
    page: () => const AttorneyRegisterView(),
    binding: AttorneyRegisterBinding(),
  ),
  GetPage(
    name: AppRoutes.mentalHealthRegister,
    page: () => const MentalHealthRegisterView(),
    binding: MentalHealthRegisterBinding(),
  ),
  GetPage(
    name: AppRoutes.policeRegister,
    page: () => const PoliceRegisterView(),
    binding: PoliceRegisterBinding(),
  ),
  GetPage(
    name: AppRoutes.bailBondsmanRegister,
    page: () => const BailBondsmanRegisterView(),
    binding: BailBondsmanRegisterBinding(),
  ),
  GetPage(
    name: AppRoutes.subscription,
    page: () => const SubscriptionView(),
    binding: SubscriptionBinding(),
    middlewares: authGuards,
  ),
];
