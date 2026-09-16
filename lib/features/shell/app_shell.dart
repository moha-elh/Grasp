import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../explore/explore_screen.dart';
import '../generation/generation_controller.dart';
import '../retention/retention_screen.dart';
import '../session/session_screen.dart';
import '../vetting/vetting_controller.dart';
import '../vetting/vetting_screen.dart';

/// Root navigation: Session · Vet · Retention · Explore (§14, FR-18/19).
/// Vetting is its own tab now (visited when you like, e.g. after the daily
/// dose). The tab bar hides during an active review so the loop isn't
/// interrupted - Session drives that via [onActiveChanged].
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;
  bool _sessionActive = false;

  @override
  void initState() {
    super.initState();
    // Kick off one background generation pass on entry (FR-7). No-ops when
    // signed out or when the pending queue is already full.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(generationControllerProvider.notifier).runPass();
    });
  }

  static const _tabs = [
    _Tab('Session', Icons.school_outlined, Icons.school),
    _Tab('Vet', Icons.fact_check_outlined, Icons.fact_check),
    _Tab('Retention', Icons.insights_outlined, Icons.insights),
    _Tab('Explore', Icons.explore_outlined, Icons.explore),
  ];

  void _select(int i) {
    // Reload the vetting batch each time the tab is opened so freshly generated
    // pending cards show up (the provider is otherwise kept alive by the shell).
    if (i == 1) ref.invalidate(vettingControllerProvider);
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      SessionScreen(
        onActiveChanged: (a) => setState(() => _sessionActive = a),
      ),
      const VettingScreen(),
      const RetentionScreen(),
      const ExploreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: _sessionActive ? null : _buildTabBar(),
    );
  }

  Widget _buildTabBar() {
    final vet = ref.watch(vettingControllerProvider);
    final toVet = vet.total - vet.index;
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
                Expanded(child: _tabItem(i, badge: i == 1 ? toVet : 0)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem(int i, {int badge = 0}) {
    final tab = _tabs[i];
    final selected = i == _index;
    final color = selected ? T.ink : T.inkMeta;
    return InkResponse(
      onTap: () => _select(i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(selected ? tab.activeIcon : tab.icon, size: 22, color: color),
              if (badge > 0)
                Positioned(
                  top: -6,
                  right: -10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: T.accent,
                      borderRadius: BorderRadius.circular(T.rPill),
                    ),
                    child: Text('$badge',
                        style: Typo.mono(size: 9, color: T.surface)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: T.s4),
          Text(tab.label,
              style: Typo.mono(size: 10, color: color).copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
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
