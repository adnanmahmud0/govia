import 'package:get/get.dart';
import 'package:gsabino365/module/shared/provider_pricing_payouts/controller/provider_pricing_payouts_controller.dart';

class ProviderPricingPayoutsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProviderPricingPayoutsController>(
      () => ProviderPricingPayoutsController(),
    );
  }
}
