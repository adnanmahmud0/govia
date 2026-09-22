import 'package:get/get.dart';
import 'package:gsabino365/module/citizen/community/controller/citizen_community_controller.dart';

class CitizenCommunityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CitizenCommunityController());
  }
}
