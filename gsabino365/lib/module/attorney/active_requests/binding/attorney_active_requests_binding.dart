import 'package:get/get.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';
import 'package:gsabino365/module/attorney/active_requests/controller/attorney_active_requests_controller.dart';

class AttorneyActiveRequestsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MeetingRepository>()) {
      Get.lazyPut<MeetingRepository>(
        () => MeetingRepository(apiClient: Get.find<ApiClient>()),
        fenix: true,
      );
    }
    Get.lazyPut(() => AttorneyActiveRequestsController());
  }
}
