import 'package:get/get.dart';
import 'package:gsabino365/module/citizen/encounter_history/controller/encounter_history_controller.dart';

class EncounterHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EncounterHistoryController());
  }
}
