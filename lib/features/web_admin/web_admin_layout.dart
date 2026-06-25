import 'package:flutter/material.dart';
import 'package:baidoxe/core/theme.dart';
import 'widgets/sidebar.dart';
import 'widgets/topbar.dart';

class WebAdminLayout extends StatefulWidget {
  final Widget child;
  final String role;
  final String currentRoute;

  const WebAdminLayout({
    Key? key,
    required this.child,
    required this.role,
    required this.currentRoute,
  }) : super(key: key);

  @override
  State<WebAdminLayout> createState() => _WebAdminLayoutState();
}

class _WebAdminLayoutState extends State<WebAdminLayout> {
  bool isSidebarOpen = true;

  void toggleSidebar() {
    setState(() {
      isSidebarOpen = !isSidebarOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    // Auto collapse sidebar on smaller screens
    if (!isDesktop && isSidebarOpen) {
      isSidebarOpen = false;
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryWhite,
      drawer: !isDesktop
          ? Drawer(
              child: Sidebar(
                role: widget.role,
                currentRoute: widget.currentRoute,
                onClose: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar for Desktop
          if (isDesktop && isSidebarOpen)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Sidebar(
                role: widget.role,
                currentRoute: widget.currentRoute,
              ),
            ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Topbar
                Topbar(
                  role: widget.role,
                  onMenuPressed: () {
                    if (isDesktop) {
                      toggleSidebar();
                    } else {
                      Scaffold.of(context).openDrawer();
                    }
                  },
                ),
                // Child Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: widget.child,
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
