import 'package:get/get.dart';
import 'package:gsabino365/module/citizen/vault/controller/citizen_vault_controller.dart';

class CitizenVaultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CitizenVaultController());
  }
}
