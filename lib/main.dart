import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/services/auth_service.dart';
import 'package:frontend/app/routes/app_pages.dart';
import 'package:frontend/app/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  
  // Initialize global dependencies
  Get.put<ApiService>(ApiService(), permanent: true);
  Get.put<AuthService>(AuthService(), permanent: true);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "HelpDesk Application",
      theme: AppTheme.lightTheme(),
      initialRoute: _getInitialRoute(),
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
  
  String _getInitialRoute() {
    // Cek apakah user sudah login
    final token = ApiService.getToken();
    
    if (token != null && token.isNotEmpty) {
      // Ada token, mulai dari profile dan biarkan AuthService validasi
      return Routes.PROFILE;
    } else {
      // Tidak ada token, mulai dari login
      return Routes.LOGIN;
    }
  }
}
