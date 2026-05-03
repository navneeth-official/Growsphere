/// Static pest library (expandable guide + AI taxonomy reference).
class PestGuideEntry {
  const PestGuideEntry({
    required this.id,
    required this.title,
    required this.emoji,
    required this.hostPlants,
    required this.symptoms,
    required this.organicControls,
    required this.severityHint,
  });

  final String id;
  final String title;
  final String emoji;
  final String hostPlants;
  final String symptoms;
  final String organicControls;
  final String severityHint;

  static const List<PestGuideEntry> catalog = [
    PestGuideEntry(
      id: 'aphids',
      title: 'Aphids',
      emoji: '🐛',
      hostPlants: '🌱 Roses, tomatoes, peppers',
      symptoms: 'Clusters on new growth; sticky honeydew; curled leaves; ants farming aphids.',
      organicControls: 'Blast with water; insecticidal soap; neem (follow label); release lady beetles; exclude ants.',
      severityHint: 'Common',
    ),
    PestGuideEntry(
      id: 'spider_mites',
      title: 'Spider mites',
      emoji: '🕷️',
      hostPlants: '🌱 Most plants in hot, dry air',
      symptoms: 'Fine stippling; silky webbing; leaves look dusty bronze under leaves.',
      organicControls: 'Raise humidity; rinse undersides weekly; horticultural oil; predatory mites.',
      severityHint: 'High in dry greenhouses',
    ),
    PestGuideEntry(
      id: 'fungus_gnats',
      title: 'Fungus gnats',
      emoji: '🦟',
      hostPlants: '🌱 Indoor plants, seedlings',
      symptoms: 'Tiny flies around soil; larvae in wet media; sudden seedling collapse.',
      organicControls: 'Let surface dry between waters; yellow sticky traps; Bti drenches where appropriate.',
      severityHint: 'Medium',
    ),
    PestGuideEntry(
      id: 'whiteflies',
      title: 'Whiteflies',
      emoji: '🦋',
      hostPlants: '🌱 Tomatoes, cucumbers, ornamentals',
      symptoms: 'Clouds of white adults when disturbed; honeydew; sooty mold.',
      organicControls: 'Yellow traps; vacuum adults; soap/oil sprays; reflective mulch outdoors.',
      severityHint: 'Medium',
    ),
    PestGuideEntry(
      id: 'caterpillars',
      title: 'Caterpillars',
      emoji: '🐛',
      hostPlants: '🌱 Brassicas, leafy greens, tomatoes',
      symptoms: 'Chewed holes, frass pellets, rolled leaves; often visible larvae.',
      organicControls: 'Hand-pick; Bt kurstaki for caterpillars; row covers; encourage predators.',
      severityHint: 'Variable',
    ),
    PestGuideEntry(
      id: 'root_rot',
      title: 'Root rot',
      emoji: '🍄',
      hostPlants: '🌱 Most plants in waterlogged soil',
      symptoms: 'Wilting despite wet soil; brown/black mushy roots; sour smell; stunted growth.',
      organicControls: 'Improve drainage; repot into fresh mix; reduce watering; aerate medium.',
      severityHint: 'High if anaerobic',
    ),
    PestGuideEntry(
      id: 'thrips',
      title: 'Thrips',
      emoji: '✨',
      hostPlants: '🌱 Flowers, peppers, monocots',
      symptoms: 'Silvery streaks; black specks (frass); distorted buds; virus risk in some crops.',
      organicControls: 'Blue sticky cards; spinosad where allowed; predatory mites; remove weed hosts.',
      severityHint: 'Medium–high',
    ),
    PestGuideEntry(
      id: 'mealybugs',
      title: 'Mealybugs',
      emoji: '🤍',
      hostPlants: '🌱 Succulents, citrus, tropical houseplants',
      symptoms: 'White cottony masses in leaf axils; honeydew; stunted shoots.',
      organicControls: 'Alcohol swab on small spots; horticultural oil series; isolate heavily infested plants.',
      severityHint: 'Medium',
    ),
    PestGuideEntry(
      id: 'scale',
      title: 'Scale insects',
      emoji: '🛡️',
      hostPlants: '🌱 Woody ornamentals, citrus, ficus',
      symptoms: 'Brown bumps stuck to stems; sticky leaves; ants present.',
      organicControls: 'Scrape adults; horticultural oil series; beneficial parasitoids outdoors.',
      severityHint: 'Medium',
    ),
    PestGuideEntry(
      id: 'powdery_mildew',
      title: 'Powdery mildew',
      emoji: '☁️',
      hostPlants: '🌱 Cucurbits, roses, grapes',
      symptoms: 'White talcum-like patches on leaves; curling; reduced photosynthesis.',
      organicControls: 'Potassium bicarbonate; improve airflow; resistant varieties; avoid dense canopy.',
      severityHint: 'Common humid days + cool nights',
    ),
    PestGuideEntry(
      id: 'leaf_miners',
      title: 'Leaf miners',
      emoji: '🗺️',
      hostPlants: '🌱 Spinach, beets, tomatoes, ornamentals',
      symptoms: 'Wandering translucent tunnels inside leaf blade.',
      organicControls: 'Remove affected leaves; timed sprays for larvae; parasitic wasps; rotation.',
      severityHint: 'Low–medium',
    ),
    PestGuideEntry(
      id: 'snails_slugs',
      title: 'Snails & slugs',
      emoji: '🐌',
      hostPlants: '🌱 Leafy greens, seedlings',
      symptoms: 'Irregular holes with slime trails; seedlings vanished overnight.',
      organicControls: 'Iron-phosphate baits; beer traps; evening hand-pick; copper barriers.',
      severityHint: 'High after rain',
    ),
  ];

  static String referenceBlockForAi() {
    final titles = catalog.map((e) => e.title).join(', ');
    return 'Pest guide taxonomy (match one when evidence fits, else say uncertain): $titles.';
  }
}
