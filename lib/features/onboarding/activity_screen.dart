import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/tdee_engine.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../router.dart';
import '../../widgets/vita.dart';
import 'onboarding_draft.dart';

/// S4 · Activity level. Five single-select levels, each showing a plain-language
/// descriptor and a *live* rough TDEE so the choice has visible consequence.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

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
    // Live preview: BMR is fixed across levels, so multiply by each PAL.
    final baseProfile = draft.toProfile();
    final bmr = TdeeCalculator.bmr(baseProfile);
    final pal = TdeeCalculator.config.pal;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            children: [
              Row(
                children: [
                  VitaCircleButton(icon: Icons.arrow_back_rounded, onPressed: () => context.pop()),
                  const SizedBox(width: 14),
                  const Expanded(child: StepProgressBar(current: 3, total: 3)),
                ],
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: SectionHeading(
                  title: 'How active are you?',
                  subtitle: 'Pick the option that best matches a typical week.',
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _levels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final (level, title, desc) = _levels[i];
                    final tdee = bmr * pal[level]!;
                    return SelectableTile(
                      title: title,
                      subtitle: desc,
                      selected: draft.activity == level,
                      onTap: () {
                        final d = draft.clone()..activity = level;
                        ref.read(onboardingDraftProvider.notifier).state = d;
                      },
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${tdee.round()}', style: context.mono(size: 16, color: context.vita.brand)),
                          Text('kcal', style: context.monoLabel(size: 9)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              VitaPrimaryButton(
                label: 'Calculate my TDEE',
                icon: Icons.auto_awesome_rounded,
                onPressed: () async {
                  await ref.read(profileProvider.notifier).save(draft.toProfile());
                  if (context.mounted) context.go(Routes.calculating);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
