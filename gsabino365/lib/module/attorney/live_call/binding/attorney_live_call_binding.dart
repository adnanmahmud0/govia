import 'package:get/get.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';
import 'package:gsabino365/module/attorney/live_call/controller/attorney_live_call_controller.dart';

class AttorneyLiveCallBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MeetingRepository>()) {
      Get.lazyPut<MeetingRepository>(
        () => MeetingRepository(apiClient: Get.find<ApiClient>()),
        fenix: true,
      );
    }
    Get.lazyPut(() => AttorneyLiveCallController(
          meetingRepo: Get.find<MeetingRepository>(),
        ));
  }
}
