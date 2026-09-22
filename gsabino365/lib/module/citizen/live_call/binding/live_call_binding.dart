import 'package:get/get.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';
import 'package:gsabino365/module/citizen/live_call/controller/live_call_controller.dart';

class LiveCallBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MeetingRepository>()) {
      Get.lazyPut<MeetingRepository>(
        () => MeetingRepository(apiClient: Get.find<ApiClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<LiveCallController>()) {
      Get.put<LiveCallController>(
        LiveCallController(meetingRepo: Get.find<MeetingRepository>()),
        permanent: true,
      );
    }
  }
}
