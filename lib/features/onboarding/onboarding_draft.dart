import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/tdee_engine.dart';

/// Mutable data collected across the onboarding steps before a full
/// [UserProfile] is persisted. Seeded with sensible defaults so every field is
/// valid even if the user skips ahead.
class OnboardingDraft {
  OnboardingDraft({
    this.sex = Sex.male,
    this.name = '',
    this.age = 25,
    this.weightKg = 70,
    this.heightCm = 175,
    this.goal = Goal.maintainWeight,
    this.activity = ActivityLevel.sedentary,
  });

  Sex sex;
  String name;
  int age;
  double weightKg;
  double heightCm;
  Goal goal;
  ActivityLevel activity;

  OnboardingDraft clone() => OnboardingDraft(
        sex: sex,
        name: name,
        age: age,
        weightKg: weightKg,
        heightCm: heightCm,
        goal: goal,
        activity: activity,
      );

  UserProfile toProfile() => UserProfile(
        sex: sex,
        age: age,
        weightKg: weightKg,
        heightCm: heightCm,
        activity: activity,
        goal: goal,
        name: name.trim().isEmpty ? null : name.trim(),
      );

  factory OnboardingDraft.fromProfile(UserProfile p) => OnboardingDraft(
        sex: p.sex,
        name: p.name ?? '',
        age: p.age,
        weightKg: p.weightKg,
        heightCm: p.heightCm,
        goal: p.goal,
        activity: p.activity,
      );
}

final onboardingDraftProvider =
    StateProvider<OnboardingDraft>((ref) => OnboardingDraft());
