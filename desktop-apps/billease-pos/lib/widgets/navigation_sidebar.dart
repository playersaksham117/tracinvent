import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NavigationSidebar extends StatefulWidget {
  final String currentRoute;
  final Function(String) onNavigate;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const NavigationSidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  State<NavigationSidebar> createState() => _NavigationSidebarState();
}

class _NavigationSidebarState extends State<NavigationSidebar> {
  int _focusedIndex = 0;
  final List<SidebarItemConfig> _menuItems = [
    SidebarItemConfig(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: '/',
      shortcut: '',
    ),
    SidebarItemConfig(
      icon: Icons.point_of_sale_rounded,
      label: 'Point of Sale',
      route: '/billing',
      shortcut: 'Ctrl+N',
    ),
    SidebarItemConfig(
      icon: Icons.inventory_2_rounded,
      label: 'Inventory',
      route: '/products',
      shortcut: 'Ctrl+I',
    ),
    SidebarItemConfig(
      icon: Icons.people_rounded,
      label: 'Customers',
      route: '/customers',
      shortcut: '',
    ),
    SidebarItemConfig(
      icon: Icons.receipt_long_rounded,
      label: 'Sales History',
      route: '/sales-history',
      shortcut: '',
    ),
    SidebarItemConfig(
      icon: Icons.bar_chart_rounded,
      label: 'Reports',
      route: '/reports',
      shortcut: '',
    ),
    SidebarItemConfig(
      icon: Icons.settings_rounded,
      label: 'Settings',
      route: '/settings',
      shortcut: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.isCollapsed ? 72 : 240,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(color: Color(0xFF334155), height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  return _buildSidebarItem(
                    _menuItems[index],
                    index,
                  );
                },
              ),
            ),
            const Divider(color: Color(0xFF334155), height: 1),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      // Arrow Up: Navigate up
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _focusedIndex = (_focusedIndex - 1) % _menuItems.length;
          if (_focusedIndex < 0) _focusedIndex = _menuItems.length - 1;
        });
        return KeyEventResult.handled;
      }
      
      // Arrow Down: Navigate down
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _focusedIndex = (_focusedIndex + 1) % _menuItems.length;
        });
        return KeyEventResult.handled;
      }
      
      // Enter: Select focused item
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        widget.onNavigate(_menuItems[_focusedIndex].route);
        return KeyEventResult.handled;
      }
      
      // Ctrl+S: Toggle sidebar
      if (HardwareKeyboard.instance.isControlPressed && 
          event.logicalKey == LogicalKeyboardKey.keyS) {
        widget.onToggleCollapse();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
          ),
          if (!widget.isCollapsed) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'BillEase POS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          IconButton(
            icon: Icon(
              widget.isCollapsed ? Icons.chevron_right : Icons.chevron_left,
              color: const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: widget.onToggleCollapse,
            tooltip: widget.isCollapsed ? 'Expand (Ctrl+S)' : 'Collapse (Ctrl+S)',
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(SidebarItemConfig config, int index) {
    final isActive = widget.currentRoute == config.route;
    final isFocused = _focusedIndex == index;
    final isCollapsed = widget.isCollapsed;
    
    Widget item = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onNavigate(config.route),
          onHover: (hovering) {
            if (hovering && _focusedIndex != index) {
              setState(() => _focusedIndex = index);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                  : isFocused
                      ? const Color(0xFF334155)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: isCollapsed
                ? Center(
                    child: Icon(
                      config.icon,
                      color: isActive
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF94A3B8),
                      size: 24,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        config.icon,
                        color: isActive
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          config.label,
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : const Color(0xFFCBD5E1),
                            fontSize: 14,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (config.shortcut.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            config.shortcut,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );

    // Add tooltip when collapsed
    if (isCollapsed) {
      item = Tooltip(
        message: config.label,
        preferBelow: false,
        verticalOffset: 20,
        child: item,
      );
    }

    return item;
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: widget.isCollapsed
          ? const Center(
              child: Icon(
                Icons.person_rounded,
                color: Color(0xFF94A3B8),
                size: 24,
              ),
            )
          : Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Administrator',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class SidebarItemConfig {
  final IconData icon;
  final String label;
  final String route;
  final String shortcut;

  SidebarItemConfig({
    required this.icon,
    required this.label,
    required this.route,
    required this.shortcut,
  });
}
