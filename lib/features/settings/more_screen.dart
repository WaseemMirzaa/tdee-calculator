import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vita_tokens.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/util/units.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/notification_service.dart';
import '../../router.dart';
import '../../widgets/vita.dart';
import '../onboarding/onboarding_draft.dart';

/// S13 · More / Settings. Profile summary, recalculate, preferences
/// (units + theme), and the standard support/legal links.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final unit = ref.watch(unitSystemProvider);
    final themeMode = ref.watch(themeModeProvider);
    final v = context.vita;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        Text('More', style: context.vt.titleLarge),
        const SizedBox(height: 14),

        // Profile summary
        VitaCard(
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: v.brand.withOpacity(0.12), shape: BoxShape.circle),
                child: Text(
                  (profile?.name?.isNotEmpty ?? false) ? profile!.name![0].toUpperCase() : '🙂',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: v.brandDeep),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile?.name?.isNotEmpty == true ? profile!.name! : 'Your profile',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: v.ink)),
                    if (profile != null)
                      Text('${profile.age} yr · ${profile.weightKg.toStringAsFixed(0)} kg · ${profile.heightCm.toStringAsFixed(0)} cm',
                          style: TextStyle(color: v.muted, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _Group(children: [
          _Tile(
            icon: Icons.refresh_rounded,
            title: 'Recalculate',
            subtitle: 'Update your details and numbers',
            onTap: () {
              if (profile != null) {
                ref.read(onboardingDraftProvider.notifier).state = OnboardingDraft.fromProfile(profile);
              }
              context.push(Routes.onboard);
            },
          ),
          _ToggleTile(
            icon: Icons.straighten_rounded,
            title: 'Units',
            value: unit == UnitSystem.metric ? 'Metric (kg · cm)' : 'Imperial (lb · ft)',
            onTap: () => ref.read(unitSystemProvider.notifier).toggle(),
          ),
          _ThemeTile(themeMode: themeMode, onChanged: (m) => ref.read(themeModeProvider.notifier).set(m)),
        ]),
        const SizedBox(height: 12),

        _SchemePicker(
          selected: ref.watch(schemeProvider),
          onSelect: (s) => ref.read(schemeProvider.notifier).select(s),
        ),
        const SizedBox(height: 12),

        _Group(children: [
          _Tile(icon: Icons.ios_share_rounded, title: 'Share Vita', onTap: () => _todo(context)),
          _Tile(icon: Icons.support_agent_rounded, title: 'Customer support', onTap: () => _todo(context)),
          _Tile(icon: Icons.star_outline_rounded, title: 'Rate us', onTap: () => _todo(context)),
          _Tile(icon: Icons.description_outlined, title: 'Terms of service', onTap: () => _todo(context)),
          _Tile(icon: Icons.privacy_tip_outlined, title: 'Privacy policy', onTap: () => _todo(context)),
        ]),
        const SizedBox(height: 12),

        _Group(children: [
          _Tile(
            icon: Icons.delete_outline_rounded,
            title: 'Reset all data',
            danger: true,
            onTap: () => _confirmReset(context, ref),
          ),
        ]),
        const SizedBox(height: 18),
        Center(child: Text('Vita · v1.0.0', style: context.mono(size: 12, color: v.muted))),
      ],
    );
  }

  void _todo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wire this to your store / support URL before release.')),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final v = context.vita;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: v.card,
        title: const Text('Reset all data?'),
        content: const Text('This deletes your profile, meal plan, and weigh-in history from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: VitaColors.crit),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(profileProvider.notifier).clear(); // wipes every table
      // Drop cached in-memory state so the next user starts truly clean.
      ref.invalidate(planProvider);
      ref.invalidate(favoritesProvider);
      ref.invalidate(foodPrefsProvider);
      ref.invalidate(weighInsProvider);
      ref.invalidate(kitchenProvider);
      NotificationService.instance.cancelRestockReminder();
      ref.read(selectedDietProvider.notifier).select('anything');
      if (context.mounted) context.go(Routes.welcome);
    }
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Container(
      decoration: BoxDecoration(
        color: v.card,
        borderRadius: VitaRadius.cardR,
        border: Border.all(color: v.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: v.lineSoft, indent: 56),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, this.subtitle, this.onTap, this.danger = false});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final color = danger ? VitaColors.crit : v.ink;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: danger ? VitaColors.crit : v.brand, size: 22),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: v.muted, fontSize: 12.5)) : null,
      trailing: danger ? null : Icon(Icons.chevron_right_rounded, color: v.muted),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({required this.icon, required this.title, required this.value, required this.onTap});
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: v.brand, size: 22),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: v.ink, fontSize: 15)),
      trailing: Text(value, style: TextStyle(color: v.muted, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.themeMode, required this.onChanged});
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Icon(Icons.dark_mode_outlined, color: v.brand, size: 22),
          const SizedBox(width: 16),
          Text('Theme', style: TextStyle(fontWeight: FontWeight.w600, color: v.ink, fontSize: 15)),
          const Spacer(),
          SizedBox(
            width: 168,
            child: VitaSegmented<ThemeMode>(
              value: themeMode,
              onChanged: onChanged,
              segments: const [
                VitaSegment(ThemeMode.system, 'Auto'),
                VitaSegment(ThemeMode.light, 'Light'),
                VitaSegment(ThemeMode.dark, 'Dark'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Accent-scheme picker: six premium colour swatches; tap to switch instantly.
class _SchemePicker extends StatelessWidget {
  const _SchemePicker({required this.selected, required this.onSelect});
  final VitaScheme selected;
  final ValueChanged<VitaScheme> onSelect;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: v.brand, size: 22),
              const SizedBox(width: 16),
              Text('Accent colour', style: TextStyle(fontWeight: FontWeight.w600, color: v.ink, fontSize: 15)),
              const Spacer(),
              Text(selected.name, style: TextStyle(color: v.muted, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final s in kVitaSchemes)
                GestureDetector(
                  onTap: () => onSelect(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [s.brandLight, s.accent],
                      ),
                      border: Border.all(
                        color: s.id == selected.id ? v.ink : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(color: s.brandLight.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: s.id == selected.id
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
