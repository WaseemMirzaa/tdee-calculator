import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/tdee_engine.dart';
import '../../core/theme/vita_tokens.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/util/units.dart';
import '../../core/providers/app_providers.dart';
import '../../router.dart';
import '../../widgets/vita.dart';
import 'onboarding_draft.dart';

/// S3 · "About you" — a paced two-step stepper (body metrics, then goal) with a
/// live progress bar, unit toggle, and inline validation. Step 3 is Activity.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _page = PageController();
  int _step = 0;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: ref.read(onboardingDraftProvider).name);
  }

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    super.dispose();
  }

  OnboardingDraft get _draft => ref.read(onboardingDraftProvider);

  void _next() {
    if (_step == 0) {
      setState(() => _step = 1);
      _page.nextPage(duration: VitaMotion.base, curve: VitaMotion.curve);
    } else {
      context.push(Routes.activity);
    }
  }

  void _back() {
    if (_step == 1) {
      setState(() => _step = 0);
      _page.previousPage(duration: VitaMotion.base, curve: VitaMotion.curve);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            children: [
              Row(
                children: [
                  VitaCircleButton(icon: Icons.arrow_back_rounded, onPressed: _back),
                  const SizedBox(width: 14),
                  Expanded(child: StepProgressBar(current: _step + 1, total: 3)),
                ],
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _BodyStep(nameController: _name),
                    const _GoalStep(),
                  ],
                ),
              ),
              VitaPrimaryButton(
                label: _step == 0 ? 'Continue' : 'Next',
                icon: Icons.arrow_forward_rounded,
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — body metrics
// ---------------------------------------------------------------------------

class _BodyStep extends ConsumerWidget {
  const _BodyStep({required this.nameController});
  final TextEditingController nameController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final unit = ref.watch(unitSystemProvider);
    final v = context.vita;

    return ListView(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      children: [
        Text('Tell us about you', style: context.vt.headlineMedium?.copyWith(fontSize: 27)),
        const SizedBox(height: 6),
        Text('So we can compute your energy needs accurately.',
            style: TextStyle(color: v.inkSoft, fontSize: 15)),
        const SizedBox(height: 22),

        // Gender
        VitaSegmented<Sex>(
          value: draft.sex,
          onChanged: (s) => _update(ref, (d) => d.sex = s),
          segments: const [VitaSegment(Sex.male, 'Male'), VitaSegment(Sex.female, 'Female')],
        ),
        const SizedBox(height: 18),

        // Name
        _FieldShell(
          label: 'Your name',
          child: TextField(
            controller: nameController,
            onChanged: (t) => _update(ref, (d) => d.name = t, rebuild: false),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: 'Optional',
            ),
            style: TextStyle(fontWeight: FontWeight.w600, color: v.ink),
          ),
        ),
        const SizedBox(height: 12),

        // Age
        _StepperRow(
          label: 'How old are you?',
          value: '${draft.age}',
          unit: 'years',
          onMinus: draft.age > 10 ? () => _update(ref, (d) => d.age--) : null,
          onPlus: draft.age < 100 ? () => _update(ref, (d) => d.age++) : null,
        ),
        const SizedBox(height: 12),

        // Weight (respects unit system)
        _WeightRow(),
        const SizedBox(height: 12),

        // Height (cm, or ft+in)
        _HeightRow(),
        const SizedBox(height: 16),

        // Unit toggle
        Row(
          children: [
            Text('Units', style: TextStyle(color: v.muted, fontWeight: FontWeight.w600, fontSize: 13)),
            const Spacer(),
            SizedBox(
              width: 190,
              child: VitaSegmented<UnitSystem>(
                value: unit,
                onChanged: (u) => ref.read(unitSystemProvider.notifier).set(u),
                segments: const [
                  VitaSegment(UnitSystem.metric, 'kg · cm'),
                  VitaSegment(UnitSystem.imperial, 'lb · ft'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _update(WidgetRef ref, void Function(OnboardingDraft) fn, {bool rebuild = true}) {
    final d = ref.read(onboardingDraftProvider).clone();
    fn(d);
    if (rebuild) {
      ref.read(onboardingDraftProvider.notifier).state = d;
    } else {
      // Mutate without triggering a rebuild (text fields manage their own).
      ref.read(onboardingDraftProvider).name = d.name;
    }
  }
}

class _WeightRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final unit = ref.watch(unitSystemProvider);
    final display = Units.displayWeight(draft.weightKg, unit);
    return _StepperRow(
      label: "What's your weight?",
      value: display.toStringAsFixed(0),
      unit: Units.weightUnit(unit),
      onMinus: draft.weightKg > 20 ? () => _bump(ref, unit, -1) : null,
      onPlus: draft.weightKg < 300 ? () => _bump(ref, unit, 1) : null,
    );
  }

  /// Bump by 1 display-unit (1 kg, or 1 lb) and clamp in kg.
  void _bump(WidgetRef ref, UnitSystem unit, int dir) {
    final deltaKg = unit == UnitSystem.metric ? 1.0 : Units.lbToKg(1);
    final d = ref.read(onboardingDraftProvider).clone();
    d.weightKg = (d.weightKg + dir * deltaKg).clamp(20, 300);
    ref.read(onboardingDraftProvider.notifier).state = d;
  }
}

class _HeightRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final unit = ref.watch(unitSystemProvider);
    if (unit == UnitSystem.metric) {
      return _StepperRow(
        label: "What's your height?",
        value: draft.heightCm.toStringAsFixed(0),
        unit: 'cm',
        onMinus: draft.heightCm > 120 ? () => _setCm(ref, -1) : null,
        onPlus: draft.heightCm < 230 ? () => _setCm(ref, 1) : null,
      );
    }
    final (feet, inches) = Units.cmToFeetInches(draft.heightCm);
    return _FieldShell(
      label: "What's your height?",
      child: Row(
        children: [
          _SmallStepper(value: '$feet', unit: 'ft', onMinus: feet > 3 ? () => _setFt(ref, feet - 1, inches) : null, onPlus: feet < 8 ? () => _setFt(ref, feet + 1, inches) : null),
          const SizedBox(width: 12),
          _SmallStepper(value: '$inches', unit: 'in', onMinus: () => _setFt(ref, feet, (inches - 1) % 12 < 0 ? 11 : inches - 1), onPlus: () => _setFt(ref, feet, (inches + 1) % 12)),
        ],
      ),
    );
  }

  void _setCm(WidgetRef ref, int delta) {
    final d = ref.read(onboardingDraftProvider).clone();
    d.heightCm = (d.heightCm + delta).clamp(120, 230);
    ref.read(onboardingDraftProvider.notifier).state = d;
  }

  void _setFt(WidgetRef ref, int feet, int inches) {
    final f = feet.clamp(3, 8);
    final i = inches.clamp(0, 11);
    final d = ref.read(onboardingDraftProvider).clone();
    d.heightCm = Units.feetInchesToCm(f, i);
    ref.read(onboardingDraftProvider.notifier).state = d;
  }
}

// ---------------------------------------------------------------------------
// Step 2 — goal
// ---------------------------------------------------------------------------

class _GoalStep extends ConsumerWidget {
  const _GoalStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final v = context.vita;
    const goals = [
      (Goal.loseWeight, 'Lose weight', 'Trim fat at a steady, sustainable pace', '🔻'),
      (Goal.maintainWeight, 'Maintain weight', 'Hold steady and eat with intention', '⚖️'),
      (Goal.gainWeight, 'Gain weight', 'Build size with a controlled surplus', '🔺'),
    ];
    return ListView(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      children: [
        Text("What's your goal?", style: context.vt.headlineMedium?.copyWith(fontSize: 27)),
        const SizedBox(height: 6),
        Text('This shapes your calorie targets and meal plan.',
            style: TextStyle(color: v.inkSoft, fontSize: 15)),
        const SizedBox(height: 22),
        for (final g in goals) ...[
          SelectableTile(
            title: g.$2,
            subtitle: g.$3,
            selected: draft.goal == g.$1,
            leading: Text(g.$4, style: const TextStyle(fontSize: 24)),
            onTap: () {
              final d = draft.clone()..goal = g.$1;
              ref.read(onboardingDraftProvider.notifier).state = d;
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared little inputs
// ---------------------------------------------------------------------------

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: v.isDark ? v.lineSoft : const Color(0xFFF0EEE4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: v.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.unit,
    this.onMinus,
    this.onPlus,
  });
  final String label;
  final String value;
  final String unit;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: v.isDark ? v.lineSoft : const Color(0xFFF0EEE4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: v.ink, fontSize: 15)),
          ),
          _RoundBtn(icon: Icons.remove_rounded, onTap: onMinus),
          const SizedBox(width: 4),
          SizedBox(
            width: 62,
            child: Column(
              children: [
                Text(value, style: context.mono(size: 20)),
                Text(unit, style: TextStyle(fontSize: 10.5, color: v.muted)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          _RoundBtn(icon: Icons.add_rounded, onTap: onPlus),
        ],
      ),
    );
  }
}

class _SmallStepper extends StatelessWidget {
  const _SmallStepper({required this.value, required this.unit, this.onMinus, this.onPlus});
  final String value;
  final String unit;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Expanded(
      child: Row(
        children: [
          _RoundBtn(icon: Icons.remove_rounded, onTap: onMinus),
          Expanded(
            child: Column(
              children: [
                Text(value, style: context.mono(size: 19)),
                Text(unit, style: TextStyle(fontSize: 10.5, color: v.muted)),
              ],
            ),
          ),
          _RoundBtn(icon: Icons.add_rounded, onTap: onPlus),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap == null ? null : () { HapticFeedback.selectionClick(); onTap!(); },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: v.card,
          shape: BoxShape.circle,
          border: Border.all(color: v.line),
        ),
        child: Icon(icon, size: 18, color: enabled ? v.ink : v.muted.withValues(alpha: 0.4)),
      ),
    );
  }
}
