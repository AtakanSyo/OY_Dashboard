import 'package:flutter/material.dart';

import '../theme/site_responsive.dart';
import '../theme/site_tokens.dart';
import 'app_footer.dart';
import 'app_header.dart';

/// Tüm public sayfaların ortak kabuğu: sabit üst bar, kaydırılabilir içerik,
/// footer ve mobil menü.
class SiteScaffold extends StatefulWidget {
  final List<Widget> children;

  const SiteScaffold({super.key, required this.children});

  @override
  State<SiteScaffold> createState() => _SiteScaffoldState();
}

class _SiteScaffoldState extends State<SiteScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _scrolled = false;

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final scrolled = notification.metrics.pixels > 8;
    if (scrolled != _scrolled) {
      setState(() => _scrolled = scrolled);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = AppHeader.heightFor(context.device);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: SiteColors.surface,
      endDrawer: const SiteMobileMenu(),
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: Scrollbar(
              child: SingleChildScrollView(
                primary: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: headerHeight),
                    ...widget.children,
                    const AppFooter(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppHeader(
              scrolled: _scrolled,
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
        ],
      ),
    );
  }
}
