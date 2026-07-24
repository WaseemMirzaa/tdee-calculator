import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/vita_tokens.dart';
import 'core/theme/vita_theme.dart';
import 'features/results/results_screen.dart';
import 'features/meals/meals_tab.dart';
import 'features/journey/journey_screen.dart';
import 'features/settings/more_screen.dart';
import 'widgets/vita.dart';
import 'router.dart';

/// The home shell: four tabs in an [IndexedStack] so each keeps its state.
/// Home · Meals · Journey · More. A banner ad is pinned above the nav (the app
/// is free and ad-supported). Other screens switch tabs via [homeTabProvider].
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _tabs = [
    _TabDef('Home', Icons.donut_large_rounded),
    _TabDef('Meals', Icons.restaurant_rounded),
    _TabDef('Journey', Icons.show_chart_rounded),
    _TabDef('More', Icons.grid_view_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabProvider);
    final v = context.vita;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: index,
          children: const [
            ResultsScreen(),
            MealsTab(),
            JourneyScreen(),
            MoreScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: v.card,
          border: Border(top: BorderSide(color: v.line)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(v.isDark ? 0.4 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, -6),
              spreadRadius: -8,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AdSlot(), // pinned banner ad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: SizedBox(
                  height: 54,
                  child: Row(
                    children: [
                      for (var i = 0; i < _tabs.length; i++)
                        Expanded(
                          child: _NavItem(
                            def: _tabs[i],
                            selected: i == index,
                            onTap: () => ref.read(homeTabProvider.notifier).state = i,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.def, required this.selected, required this.onTap});
  final _TabDef def;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final color = selected ? v.brand : v.muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: VitaMotion.fast,
          curve: VitaMotion.curve,
          padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 8, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? v.brand.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(VitaRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(def.icon, size: 22, color: color),
              AnimatedSize(
                duration: VitaMotion.fast,
                curve: VitaMotion.curve,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Text(
                          def.label,
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800, color: color),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
