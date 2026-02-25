/// Configuration de la carte (parcours gamification).
/// Chaque étape = un ou plusieurs thèmes ; déblocage par mots réussis.
class MapConfig {
  MapConfig._();

  /// Nombre de mots à réussir (au moins 1 succès) dans une étape pour débloquer la suivante.
  static const int wordsToUnlockNext = 5;

  /// Étapes du parcours : id, titre court, liste de thèmes (correspondent aux thèmes dans les données).
  static const List<MapStep> steps = [
    MapStep(id: 0, title: 'Son [a]', themes: ['niveau_1_cv_son_a']),
    MapStep(id: 1, title: 'Son [e/eu]', themes: ['niveau_1_cv_son_e_eu']),
    MapStep(id: 2, title: 'Son [i/y]', themes: ['niveau_1_cv_son_i_y']),
    MapStep(id: 3, title: 'Son [o]', themes: ['niveau_1_cv_son_o']),
    MapStep(id: 4, title: 'Son [u]', themes: ['niveau_1_cv_son_u']),
    MapStep(id: 5, title: 'Consonnes doubles', themes: ['niveau_1_consonnes_doubles']),
    MapStep(id: 6, title: 'Niveau 2', themes: [
      'aliments', 'animaux', 'corps_humain', 'ecole', 'maison_objets',
      'metiers_lieux', 'nature', 'transport', 'verbes_actions', 'vetements',
    ]),
  ];
}

class MapStep {
  final int id;
  final String title;
  final List<String> themes;

  const MapStep({
    required this.id,
    required this.title,
    required this.themes,
  });
}
