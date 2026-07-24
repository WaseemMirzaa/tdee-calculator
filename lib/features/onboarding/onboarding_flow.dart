import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/tdee_engine.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/util/units.dart';
import '../../core/providers/app_providers.dart';
import '../../router.dart';
import '../../widgets/vita.dart';
import 'onboarding_draft.dart';

/// A best-in-class, one-question-per-screen onboarding — the pattern used by
/// the world's top fitness apps. Six focused steps with a ruler picker for
/// numbers and big tap cards for choices. Used for first-run AND "Recalculate".
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  static const _steps = 6;
  final _page = PageController();
  int _step = 0;

  void _next() {
    if (_step < _steps - 1) {
      setState(() => _step++);
      _page.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _page.previousPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      context.pop();
    }
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    await ref.read(profileProvider.notifier).save(ref.read(onboardingDraftProvider).toProfile());
    if (mounted) context.go(Routes.calculating);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                child: Row(
                  children: [
                    VitaCircleButton(icon: Icons.arrow_back_rounded, onPressed: _back),
                    const SizedBox(width: 14),
                    Expanded(child: StepProgressBar(current: _step + 1, total: _steps)),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    _AboutStep(),
                    _AgeStep(),
                    _HeightStep(),
                    _WeightStep(),
                    _GoalStep(),
                    _ActivityStep(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: VitaPrimaryButton(
                  label: _step == _steps - 1 ? 'Calculate my TDEE' : 'Continue',
                  icon: _step == _steps - 1 ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared step chrome
// ---------------------------------------------------------------------------

class _StepBody extends StatelessWidget {
  const _StepBody({required this.title, this.subtitle, required this.child, this.scroll = false});
  final String title;
  final String? subtitle;
  final Widget child;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.vt.headlineMedium?.copyWith(fontSize: 28)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: TextStyle(color: v.inkSoft, fontSize: 15.5, height: 1.4)),
        ],
      ],
    );
    if (scroll) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
        children: [header, const SizedBox(height: 24), child],
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, Expanded(child: Center(child: child))],
      ),
    );
  }
}

/// The huge value readout above a ruler.
class _BigValue extends StatelessWidget {
  const _BigValue({required this.value, required this.unit});
  final String value;
  final String unit;
  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: context.mono(size: 58, weight: FontWeight.w800, color: v.brand)),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(unit, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: v.muted)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — about (name + gender)
// ---------------------------------------------------------------------------

class _AboutStep extends ConsumerStatefulWidget {
  const _AboutStep();
  @override
  ConsumerState<_AboutStep> createState() => _AboutStepState();
}

class _AboutStepState extends ConsumerState<_AboutStep> {
  late final TextEditingController _name =
      TextEditingController(text: ref.read(onboardingDraftProvider).name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _update(void Function(OnboardingDraft) fn) {
    final d = ref.read(onboardingDraftProvider).clone();
    fn(d);
    ref.read(onboardingDraftProvider.notifier).state = d;
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingDraftProvider);
    final v = context.vita;
    return _StepBody(
      scroll: true,
      title: "Let's get to know you",
      subtitle: 'A couple of basics so we can personalise your plan.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Your name'),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            onChanged: (t) => ref.read(onboardingDraftProvider).name = t,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Optional',
              filled: true,
              fillColor: v.isDark ? v.lineSoft : const Color(0xFFF0EEE4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            style: TextStyle(fontWeight: FontWeight.w600, color: v.ink),
          ),
          const SizedBox(height: 26),
          const SectionLabel('You are'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _GenderCard(
                label: 'Male', emoji: '♂', selected: draft.sex == Sex.male,
                onTap: () => _update((d) => d.sex = Sex.male))),
              const SizedBox(width: 12),
              Expanded(child: _GenderCard(
                label: 'Female', emoji: '♀', selected: draft.sex == Sex.female,
                onTap: () => _update((d) => d.sex = Sex.female))),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({required this.label, required this.emoji, required this.selected, required this.onTap});
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 140,
        decoration: BoxDecoration(
          color: selected ? v.brand.withOpacity(0.10) : (v.isDark ? v.lineSoft : const Color(0xFFF0EEE4)),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? v.brand : Colors.transparent, width: 1.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: 44, color: selected ? v.brand : v.muted)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: v.ink)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — age
// ---------------------------------------------------------------------------

class _AgeStep extends ConsumerWidget {
  const _AgeStep();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    return _StepBody(
      title: 'How old are you?',
      subtitle: 'Age refines your metabolic rate.',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _BigValue(value: '${draft.age}', unit: 'years'),
          const SizedBox(height: 24),
          VitaRulerPicker(
            min: 10, max: 100, value: draft.age.toDouble(),
            onChanged: (val) {
              final d = ref.read(onboardingDraftProvider).clone()..age = val.round();
              ref.read(onboardingDraftProvider.notifier).state = d;
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — height
// ---------------------------------------------------------------------------

class _HeightStep extends ConsumerWidget {
  const _HeightStep();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final unit = ref.watch(unitSystemProvider);
    final metric = unit == UnitSystem.metric;

    final String bigVal;
    final String bigUnit;
    if (metric) {
      bigVal = draft.heightCm.round().toString();
      bigUnit = 'cm';
    } else {
      final (ft, inch) = Units.cmToFeetInches(draft.heightCm);
      bigVal = "$ft'$inch\"";
      bigUnit = '';
    }

    return _StepBody(
      title: "What's your height?",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _unitToggle(context, ref, unit),
          const SizedBox(height: 20),
          _BigValue(value: bigVal, unit: bigUnit),
          const SizedBox(height: 24),
          if (metric)
            VitaRulerPicker(
              min: 120, max: 220, value: draft.heightCm.clamp(120, 220),
              onChanged: (cm) => _setCm(ref, cm),
            )
          else
            VitaRulerPicker(
              min: 48, max: 96, value: (draft.heightCm / 2.54).clamp(48, 96),
              onChanged: (inches) => _setCm(ref, inches * 2.54),
            ),
        ],
      ),
    );
  }

  void _setCm(WidgetRef ref, double cm) {
    final d = ref.read(onboardingDraftProvider).clone()..heightCm = cm.clamp(120, 230);
    ref.read(onboardingDraftProvider.notifier).state = d;
  }
}

// ---------------------------------------------------------------------------
// Step 4 — weight
// ---------------------------------------------------------------------------

class _WeightStep extends ConsumerWidget {
  const _WeightStep();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final unit = ref.watch(unitSystemProvider);
    final metric = unit == UnitSystem.metric;
    final display = Units.displayWeight(draft.weightKg, unit);

    return _StepBody(
      title: "What's your weight?",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _unitToggle(context, ref, unit),
          const SizedBox(height: 20),
          _BigValue(value: display.round().toString(), unit: Units.weightUnit(unit)),
          const SizedBox(height: 24),
          if (metric)
            VitaRulerPicker(
              min: 30, max: 250, value: draft.weightKg.clamp(30, 250),
              onChanged: (kg) => _setKg(ref, kg),
            )
          else
            VitaRulerPicker(
              min: 66, max: 550, value: Units.kgToLb(draft.weightKg).clamp(66, 550),
              onChanged: (lb) => _setKg(ref, Units.lbToKg(lb)),
            ),
        ],
      ),
    );
  }

  void _setKg(WidgetRef ref, double kg) {
    final d = ref.read(onboardingDraftProvider).clone()..weightKg = kg.clamp(20, 300);
    ref.read(onboardingDraftProvider.notifier).state = d;
  }
}

Widget _unitToggle(BuildContext context, WidgetRef ref, UnitSystem unit) {
  return SizedBox(
    width: 220,
    child: VitaSegmented<UnitSystem>(
      value: unit,
      onChanged: (u) => ref.read(unitSystemProvider.notifier).set(u),
      segments: const [
        VitaSegment(UnitSystem.metric, 'kg · cm'),
        VitaSegment(UnitSystem.imperial, 'lb · ft'),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Step 5 — goal
// ---------------------------------------------------------------------------

class _GoalStep extends ConsumerWidget {
  const _GoalStep();
  static const _goals = [
    (Goal.loseWeight, 'Lose weight', 'Trim fat at a steady, sustainable pace', '🔻'),
    (Goal.maintainWeight, 'Maintain weight', 'Hold steady and eat with intention', '⚖️'),
    (Goal.gainWeight, 'Gain weight', 'Build size with a controlled surplus', '🔺'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    return _StepBody(
      scroll: true,
      title: "What's your goal?",
      subtitle: 'This shapes your calorie targets and meal plan.',
      child: Column(
        children: [
          for (final g in _goals) ...[
            SelectableTile(
              title: g.$2, subtitle: g.$3, selected: draft.goal == g.$1,
              leading: Text(g.$4, style: const TextStyle(fontSize: 26)),
              onTap: () {
                final d = draft.clone()..goal = g.$1;
                ref.read(onboardingDraftProvider.notifier).state = d;
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 6 — activity
// ---------------------------------------------------------------------------

class _ActivityStep extends ConsumerWidget {
  const _ActivityStep();
  static const _levels = <(ActivityLevel, String, String)>[
    (ActivityLevel.sedentary, 'Sedentary', 'Little or no exercise · desk job'),
    (ActivityLevel.light, 'Lightly active', 'Light exercise 1–3 days/week'),
    (ActivityLevel.moderate, 'Moderately active', 'Moderate exercise 3–5 days/week'),
    (ActivityLevel.veryActive, 'Very active', 'Hard exercise 6–7 days/week'),
    (ActivityLevel.extreme, 'Extreme', 'Very intense training or physical job'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final bmr = TdeeCalculator.bmr(draft.toProfile());
    final pal = TdeeCalculator.config.pal;
    return _StepBody(
      scroll: true,
      title: 'How active are you?',
      subtitle: 'Pick the option that matches a typical week.',
      child: Column(
        children: [
          for (final l in _levels) ...[
            SelectableTile(
              title: l.$2, subtitle: l.$3, selected: draft.activity == l.$1,
              onTap: () {
                final d = draft.clone()..activity = l.$1;
                ref.read(onboardingDraftProvider.notifier).state = d;
              },
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${(bmr * pal[l.$1]!).round()}', style: context.mono(size: 15, color: context.vita.brand)),
                  Text('kcal', style: context.monoLabel(size: 9)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
