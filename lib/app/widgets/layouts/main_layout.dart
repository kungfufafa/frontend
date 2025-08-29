import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  
  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final AuthService _authService = Get.find<AuthService>();
  int _selectedIndex = 0;

  // Dynamic navigation items based on user role
  List<NavigationItem> get _navigationItems {
    final user = _authService.user;
    if (user == null) return [];

    List<NavigationItem> items = [
      // Dashboard - Available for all roles
      const NavigationItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard',
        route: '/dashboard',
        roles: ['Administrator', 'Manager', 'Karyawan', 'Direksi', 'User/Klien'],
      ),
    ];

    // Administrator specific menus
    if (user.isAdmin()) {
      items.addAll([
        const NavigationItem(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: 'Users',
          route: '/users',
          roles: ['Administrator'],
        ),
        const NavigationItem(
          icon: Icons.business_outlined,
          selectedIcon: Icons.business,
          label: 'Units',
          route: '/units',
          roles: ['Administrator'],
        ),
      ]);
    }

    // Manager specific menus
    if (user.isManager()) {
      items.addAll([
        const NavigationItem(
          icon: Icons.confirmation_number_outlined,
          selectedIcon: Icons.confirmation_number,
          label: 'Tiket',
          route: '/tikets',
          roles: ['Manager'],
        ),
      ]);
    }

    // Karyawan specific menus
    if (user.isKaryawan()) {
      items.addAll([
        const NavigationItem(
          icon: Icons.confirmation_number_outlined,
          selectedIcon: Icons.confirmation_number,
          label: 'Tiket',
          route: '/tikets',
          roles: ['Karyawan'],
        ),
      ]);
    }

    // Direksi specific menus - no additional menus besides dashboard and profile
    // Direksi only gets Dashboard and Profile which are added separately

    // User/Klien specific menus
    if (user.isUser()) {
      items.addAll([
        const NavigationItem(
          icon: Icons.confirmation_number_outlined,
          selectedIcon: Icons.confirmation_number,
          label: 'Tiket',
          route: '/tikets',
          roles: ['User/Klien'],
        ),
      ]);
    }

    // Profile - Available for all roles
    items.add(
      const NavigationItem(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: 'Profil',
        route: '/profile',
        roles: ['Administrator', 'Manager', 'Karyawan', 'Direksi', 'User/Klien'],
      ),
    );

    return items;
  }

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _updateSelectedIndex();
    }
  }

  void _updateSelectedIndex() {
    final index = _navigationItems.indexWhere(
      (item) => item.route == widget.currentRoute,
    );
    setState(() {
      _selectedIndex = index != -1 ? index : 0; // Default to 0 if route not found
    });
  }

  void _onDestinationSelected(int index) {
    if (index != _selectedIndex) {
      Get.toNamed(_navigationItems[index].route);
    }
  }

  void _logout() {
    _authService.logout();
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout - gunakan NavigationRail untuk desktop/tablet
          if (constraints.maxWidth >= 840) {
            return Row(
              children: [
                // Navigation Rail - Modern Material 3 style
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      right: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                  ),
                  child: NavigationRail(
                    extended: false,
                    backgroundColor: Colors.transparent,
                    selectedIndex: _navigationItems.isNotEmpty && _selectedIndex < _navigationItems.length ? _selectedIndex : 0,
                    onDestinationSelected: _onDestinationSelected,
                    labelType: NavigationRailLabelType.all,
                    useIndicator: true,
                    indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
                    indicatorShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    selectedIconTheme: IconThemeData(
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    unselectedIconTheme: IconThemeData(
                      color: colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    leading: _buildNavigationHeader(colorScheme, textTheme),
                    trailing: _buildNavigationTrailing(colorScheme, textTheme),
                    destinations: _navigationItems.map((item) {
                      return NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      );
                    }).toList(),
                  ),
                ),
                // Body Pane - Clean Material 3 style
                Expanded(
                  child: Container(
                    color: AppTheme.backgroundWhite,
                    child: widget.child,
                  ),
                ),
              ],
            );
          } else {
            // Mobile layout - gunakan BottomNavigationBar
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  _getPageTitle(),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                backgroundColor: colorScheme.surface,
                surfaceTintColor: colorScheme.surfaceTint,
                elevation: 0,
                actions: [
                  _buildUserMenu(colorScheme, textTheme),
                ],
              ),
              body: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                ),
                child: widget.child,
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _navigationItems.isNotEmpty && _selectedIndex < _navigationItems.length ? _selectedIndex : 0,
                onDestinationSelected: _onDestinationSelected,
                backgroundColor: colorScheme.surface,
                indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                height: 72,
                destinations: _navigationItems.map((item) {
                  return NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  );
                }).toList(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildNavigationHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // App Logo - Modern minimalist style
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTrailing(ColorScheme colorScheme, TextTheme textTheme) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User profile section
              _buildUserProfile(colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(ColorScheme colorScheme, TextTheme textTheme) {
    return Obx(() {
      final user = _authService.user;
      return PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'logout') {
            _logout();
          }
        },
        tooltip: 'User menu',
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primary,
            child: Text(
              user?.nama.isNotEmpty == true 
                  ? user!.nama[0].toUpperCase() 
                  : 'U',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(
                  Icons.logout,
                  color: colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Logout',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildUserMenu(ColorScheme colorScheme, TextTheme textTheme) {
    return Obx(() {
      final user = _authService.user;
      return PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'logout') {
            _logout();
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primary,
            child: Text(
              user?.nama.isNotEmpty == true 
                  ? user!.nama[0].toUpperCase() 
                  : 'U',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(
                  Icons.logout,
                  color: colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Logout',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  String _getPageTitle() {
    switch (widget.currentRoute) {
      case '/profile':
        return 'Profil';
      case '/users':
        return 'Manajemen Users';
      case '/tikets':
        return 'Manajemen Tiket';
      case '/units':
        return 'Manajemen Unit';
      case '/karyawans':
        return 'Manajemen Karyawan';
      case '/my-team':
        return 'Tim Saya';
      case '/my-tasks':
        return 'Tugas Saya';
      case '/my-tickets':
        return 'Tiket Saya';
      case '/create-ticket':
        return 'Buat Tiket Baru';
      case '/analytics':
        return 'Analytics';
      case '/reports':
        return 'Laporan';
      case '/settings':
        return 'Pengaturan';
      default:
        return 'HelpDesk';
    }
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
  final List<String> roles;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    this.roles = const [],
  });
}
