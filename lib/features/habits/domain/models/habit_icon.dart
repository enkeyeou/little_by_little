import 'package:flutter/material.dart';

class HabitIcon {
  final String key;
  final IconData icon;
  final String label;

  const HabitIcon({
    required this.key,
    required this.icon,
    required this.label,
  });
}

class HabitIconCatalog {
  static const List<HabitIcon> icons = [
    HabitIcon(key: 'sprout', icon: Icons.eco, label: 'Growth'),
    HabitIcon(key: 'book', icon: Icons.menu_book, label: 'Reading'),
    HabitIcon(key: 'water', icon: Icons.water_drop, label: 'Water'),
    HabitIcon(key: 'running', icon: Icons.directions_run, label: 'Running'),
    HabitIcon(key: 'meditation', icon: Icons.self_improvement, label: 'Meditation'),
    HabitIcon(key: 'fitness', icon: Icons.fitness_center, label: 'Fitness'),
    HabitIcon(key: 'art', icon: Icons.palette, label: 'Art'),
    HabitIcon(key: 'sleep', icon: Icons.bedtime, label: 'Sleep'),
    HabitIcon(key: 'writing', icon: Icons.edit, label: 'Writing'),
    HabitIcon(key: 'health', icon: Icons.favorite, label: 'Health'),
    HabitIcon(key: 'music', icon: Icons.music_note, label: 'Music'),
    HabitIcon(key: 'money', icon: Icons.savings, label: 'Saving'),
  ];

  static HabitIcon getByKey(String key) {
    return icons.firstWhere(
      (item) => item.key == key,
      orElse: () => icons.first,
    );
  }

  static String keyFromLegacyEmoji(String? emoji) {
    return switch (emoji) {
      '📚' => 'book',
      '💧' => 'water',
      '🏃' => 'running',
      '🧘' => 'meditation',
      '💪' => 'fitness',
      '🎨' => 'art',
      '💤' => 'sleep',
      _ => 'sprout',
    };
  }
}