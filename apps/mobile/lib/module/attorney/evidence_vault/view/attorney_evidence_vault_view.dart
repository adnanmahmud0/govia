import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/module/citizen/vault/controller/citizen_vault_controller.dart';
import 'package:gsabino365/module/citizen/vault/view/citizen_vault_view.dart';

class AttorneyEvidenceVaultView extends StatelessWidget {
  const AttorneyEvidenceVaultView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure CitizenVaultController is initialized and data fetched
    if (!Get.isRegistered<CitizenVaultController>()) {
      Get.put(CitizenVaultController());
    }
    return const CitizenVaultView();
  }
}
