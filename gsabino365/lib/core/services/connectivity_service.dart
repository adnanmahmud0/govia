import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../controllers/internet_controller.dart';

class ConnectivityService {
  static void init() {
    final internet = Get.find<InternetController>();

    Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) {
        internet.setOffline();
      } else {
        internet.setOnline();
      }
    });
  }
}
