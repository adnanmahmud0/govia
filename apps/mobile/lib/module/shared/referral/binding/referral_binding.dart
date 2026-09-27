import 'package:get/get.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/data/repositories/referral_repository.dart';
import 'package:gsabino365/module/shared/referral/controller/referral_controller.dart';

class ReferralBinding extends Bindings {
  @override
  void dependencies() {
    final apiClient = Get.isRegistered<ApiClient>()
        ? Get.find<ApiClient>()
        : Get.put(ApiClient());

    final referralRepo = Get.isRegistered<ReferralRepository>()
        ? Get.find<ReferralRepository>()
        : Get.put(ReferralRepository(apiClient: apiClient));

    Get.lazyPut(() => ReferralController(referralRepository: referralRepo));
  }
}
