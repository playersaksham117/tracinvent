import 'package:flutter/material.dart';
import 'navigation_sidebar.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const AppLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebar(
            currentRoute: widget.currentRoute,
            onNavigate: (route) {
              if (route == '/') {
                Navigator.pushReplacementNamed(context, '/');
              } else {
                Navigator.pushReplacementNamed(context, route);
              }
            },
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
          ),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
