import 'package:get/get.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';
import 'package:gsabino365/module/doctore/active_sessions/controller/doctor_live_call_controller.dart';

class DoctorLiveCallBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MeetingRepository>()) {
      final apiClient = Get.isRegistered<ApiClient>()
          ? Get.find<ApiClient>()
          : Get.put(ApiClient());
      Get.lazyPut<MeetingRepository>(() => MeetingRepository(apiClient: apiClient));
    }

    Get.lazyPut<DoctorLiveCallController>(
      () => DoctorLiveCallController(meetingRepo: Get.find<MeetingRepository>()),
    );
  }
}
