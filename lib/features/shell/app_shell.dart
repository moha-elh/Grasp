import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../explore/explore_screen.dart';
import '../retention/retention_screen.dart';
import '../session/session_screen.dart';

/// Root navigation: Session · Retention · Explore (§14, FR-18/19).
/// The tab bar is hidden during an active session so the loop isn't
/// interrupted - Session drives that via [onSessionActiveChanged].
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _sessionActive = false;

  static const _tabs = [
    _Tab('Session', Icons.school_outlined, Icons.school),
    _Tab('Retention', Icons.insights_outlined, Icons.insights),
    _Tab('Explore', Icons.explore_outlined, Icons.explore),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      SessionScreen(
        onActiveChanged: (a) => setState(() => _sessionActive = a),
      ),
      const RetentionScreen(),
      const ExploreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: _sessionActive ? null : _buildTabBar(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: T.surfaceSunk,
        border: Border(top: BorderSide(color: T.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: T.hitTab + 8,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(child: _tabItem(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem(int i) {
    final tab = _tabs[i];
    final selected = i == _index;
    final color = selected ? T.ink : T.inkMeta;
    return InkResponse(
      onTap: () => setState(() => _index = i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? tab.activeIcon : tab.icon, size: 22, color: color),
          const SizedBox(height: T.s4),
          Text(tab.label,
              style: Typo.mono(size: 10, color: color)
                  .copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _Tab(this.label, this.icon, this.activeIcon);
}
