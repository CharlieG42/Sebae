import 'package:flutter/material.dart';

/// Définition d'un module Sebae.
///
/// Chaque module est une brique autonome de la plateforme. Un module non
/// encore développé est déclarer avec [builder] null : il apparaît alors
/// comme "a venir" dans la liste des modules.
class SebaeModule {
  const SebaeModule({
    required this.id,
    required this.name,
    required this.description,
    this.builder,
    this.icon,
  });

  /// Identifiant unique (utilise aussi comme préfixe des boxes Hive).
  final String id;
  final String name;
  final String description;

  /// Écran principal du module. Null si le module n'est pas encore disponible.
  final WidgetBuilder? builder;
  final IconData? icon;

  bool get available => builder != null;
}
