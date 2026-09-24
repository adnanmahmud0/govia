import 'package:get/get.dart';
import 'package:gsabino365/module/bail_bondsman/history/controller/bail_bondsman_history_controller.dart';

class BailBondsmanHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BailBondsmanHistoryController());
  }
}
