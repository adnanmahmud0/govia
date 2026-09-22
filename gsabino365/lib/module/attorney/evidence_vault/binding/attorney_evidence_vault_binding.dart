import 'package:get/get.dart';
import 'package:gsabino365/module/attorney/evidence_vault/controller/attorney_evidence_vault_controller.dart';
import 'package:gsabino365/module/citizen/vault/controller/citizen_vault_controller.dart';

class AttorneyEvidenceVaultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AttorneyEvidenceVaultController());
    if (!Get.isRegistered<CitizenVaultController>()) {
      Get.lazyPut(() => CitizenVaultController());
    }
  }
}
