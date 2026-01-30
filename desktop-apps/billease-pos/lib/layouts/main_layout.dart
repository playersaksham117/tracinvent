import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// =============================================================================
/// MAIN LAYOUT - THE APP SHELL
/// Persistent layout with Sidebar, Topbar, and Content Area
/// =============================================================================

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final String pageTitle;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    this.pageTitle = 'Dashboard',
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isSidebarCollapsed = false;

  static const double _sidebarExpandedWidth = 250.0;
  static const double _sidebarCollapsedWidth = 70.0;
  static const double _topbarHeight = 60.0;
  static const double _autoCollapseBreakpoint = 1100.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final autoCollapsed = screenWidth < _autoCollapseBreakpoint;
    final isCollapsed = _isSidebarCollapsed || autoCollapsed;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          _AppSidebar(
            isCollapsed: isCollapsed,
            currentRoute: widget.currentRoute,
            onToggle: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            expandedWidth: _sidebarExpandedWidth,
            collapsedWidth: _sidebarCollapsedWidth,
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _AppTopbar(
                  height: _topbarHeight,
                  pageTitle: widget.pageTitle,
                ),

                // Content
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =============================================================================
/// APP SIDEBAR
/// =============================================================================

class _AppSidebar extends StatelessWidget {
  final bool isCollapsed;
  final String currentRoute;
  final VoidCallback onToggle;
  final double expandedWidth;
  final double collapsedWidth;

  const _AppSidebar({
    required this.isCollapsed,
    required this.currentRoute,
    required this.onToggle,
    required this.expandedWidth,
    required this.collapsedWidth,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: isCollapsed ? collapsedWidth : expandedWidth,
      decoration: const BoxDecoration(
        color: AppColors.navyDark,
      ),
      child: Column(
        children: [
          // Logo Section
          _buildLogoSection(),

          const SizedBox(height: 8),

          // Navigation Items
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 8 : 12,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCollapsed) _buildSectionLabel('MAIN MENU'),
                  _buildNavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    route: '/',
                    context: context,
                  ),
                  _buildNavItem(
                    icon: Icons.point_of_sale_rounded,
                    label: 'Billing',
                    route: '/billing',
                    context: context,
                  ),
                  _buildNavItem(
                    icon: Icons.inventory_2_rounded,
                    label: 'Inventory',
                    route: '/products',
                    context: context,
                  ),
                  _buildNavItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Sales History',
                    route: '/sales-history',
                    context: context,
                  ),

                  const SizedBox(height: 16),
                  if (!isCollapsed) _buildSectionLabel('MANAGEMENT'),
                  _buildNavItem(
                    icon: Icons.people_rounded,
                    label: 'Customers',
                    route: '/customers',
                    context: context,
                  ),
                  _buildNavItem(
                    icon: Icons.store_rounded,
                    label: 'Branches',
                    route: '/branches',
                    context: context,
                  ),
                  _buildNavItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Reports',
                    route: '/reports',
                    context: context,
                  ),

                  const SizedBox(height: 16),
                  if (!isCollapsed) _buildSectionLabel('SYSTEM'),
                  _buildNavItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    route: '/settings',
                    context: context,
                  ),
                ],
              ),
            ),
          ),

          // Collapse Toggle
          _buildCollapseToggle(),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.navyMedium, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Try Sarthi',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 16, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.slate500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String route,
    required BuildContext context,
  }) {
    final isActive = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () {
            if (route != currentRoute) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
          hoverColor: AppColors.navyMedium,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.navyMedium : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: isActive
                  ? const Border(
                      left: BorderSide(color: AppColors.primary, width: 3),
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment:
                  isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? Colors.white : AppColors.slate400,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                        color: isActive ? Colors.white : AppColors.slate400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.navyMedium, width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onToggle,
          hoverColor: AppColors.navyMedium,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment:
                  isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                if (!isCollapsed) const SizedBox(width: 12),
                Icon(
                  isCollapsed
                      ? Icons.keyboard_double_arrow_right_rounded
                      : Icons.keyboard_double_arrow_left_rounded,
                  size: 20,
                  color: AppColors.slate400,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Collapse',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.slate400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// APP TOPBAR
/// =============================================================================

class _AppTopbar extends StatelessWidget {
  final double height;
  final String pageTitle;

  const _AppTopbar({
    required this.height,
    required this.pageTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Page Title
          Text(
            pageTitle,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),

          const Spacer(),

          // Global Search
          _buildSearchBar(),

          const SizedBox(width: 16),

          // Notifications
          _buildIconButton(
            icon: Icons.notifications_outlined,
            badge: 3,
            onTap: () {},
          ),

          const SizedBox(width: 8),

          // User Profile
          _buildUserProfile(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 320,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.slate400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search anything...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.slate400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.slate700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.slate200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '⌘K',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.slate500,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    int? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: AppColors.slate600,
              ),
              if (badge != null && badge > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  'A',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin User',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate800,
                    ),
                  ),
                  Text(
                    'Administrator',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
