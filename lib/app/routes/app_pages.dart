import 'package:get/get.dart';

import '../middleware/auth_guard.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/users/bindings/users_binding.dart';
import '../modules/users/views/users_view.dart';
import '../modules/tikets/bindings/tikets_binding.dart';
import '../modules/tikets/views/tikets_view.dart';
import '../modules/tikets/bindings/tiket_detail_binding.dart';
import '../modules/tikets/views/tiket_detail_view.dart';
import '../modules/tikets/bindings/create_tiket_binding.dart';
import '../modules/tikets/views/create_tiket_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.DASHBOARD;

  static final routes = [
    GetPage(
      name: _Paths.DASHBOARD,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
      middlewares: [AuthGuard()],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
      middlewares: [LoginGuard()],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
      middlewares: [RegisterGuard()],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      middlewares: [AuthGuard()],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: _Paths.USERS,
      page: () => const UsersView(),
      binding: UsersBinding(),
      middlewares: [AuthGuard()],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: _Paths.TIKETS,
      page: () => const TiketsView(),
      binding: TiketsBinding(),
      middlewares: [AuthGuard()],
      transition: Transition.noTransition,
    ),
    // IMPORTANT: Create route must come BEFORE detail route
    // because /tikets/create would match /tikets/:id pattern
    GetPage(
      name: _Paths.TIKET_CREATE,
      page: () => const CreateTiketView(),
      binding: CreateTiketBinding(),
      middlewares: [AuthGuard()],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: _Paths.TIKET_DETAIL,
      page: () => const TiketDetailView(),
      binding: TiketDetailBinding(),
      middlewares: [AuthGuard()],
      transition: Transition.noTransition,
    ),
  ];
}
