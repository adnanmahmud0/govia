import 'package:get/get.dart';
import 'package:gsabino365/module/citizen/highlight_hero/controller/highlight_hero_controller.dart';

class HighlightHeroBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HighlightHeroController());
  }
}
