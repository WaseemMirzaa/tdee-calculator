import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/diet.dart';
import '../../core/providers/app_providers.dart';
import '../../router.dart';
import '../../widgets/vita.dart';

/// S9 · Diet type. Single-select, each showing its (nutritionally-corrected)
/// exclusions as chips. → Food preference.
class DietScreen extends ConsumerWidget {
  const DietScreen({super.key});

  static const _emoji = {
    'anything': '🍽',
    'keto': '🥑',
    'vegetarian': '🥦',
    'vegan': '🌱',
    'paleo': '🍗',
    'mediterranean': '🫒',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seed = ref.watch(seedProvider);
    final selected = ref.watch(selectedDietProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a diet')),
      body: seed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load foods: $e')),
        data: (data) => Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                itemCount: data.diets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final Diet d = data.diets[i];
                  return SelectableTile(
                    title: d.name,
                    subtitle: 'Excludes: ${d.exclusionLabel}',
                    selected: selected == d.id,
                    leading: Text(_emoji[d.id] ?? '🍴', style: const TextStyle(fontSize: 24)),
                    onTap: () => ref.read(selectedDietProvider.notifier).select(d.id),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
              child: VitaPrimaryButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: selected == null ? null : () => context.push(Routes.foodPrefs),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
