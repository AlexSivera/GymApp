// Eight-tier gamified rank ladder, from weakest to strongest. Purely a
// personal-progress scale — GymApp is local/single-user, so these are never
// compared against other real people's data (see StrengthStandards).
//
// GymZ shows each tier as a Dragon Ball transformation; the enum names stay
// the original metals so stored data (tierIndex) and the ranking engine are
// untouched.
enum RankTier { hierro, bronce, plata, oro, platino, esmeralda, diamante, maestro }

extension RankTierLabel on RankTier {
  String get label => switch (this) {
        RankTier.hierro => 'Terrícola',
        RankTier.bronce => 'Guerrero Z',
        RankTier.plata => 'Kaioken',
        RankTier.oro => 'Super Saiyan',
        RankTier.platino => 'Super Saiyan 2',
        RankTier.esmeralda => 'Super Saiyan 3',
        RankTier.diamante => 'Super Saiyan Blue',
        RankTier.maestro => 'Ultra Instinto',
      };

  // Compact form for chips and tight rows ("SSJ 2").
  String get shortLabel => switch (this) {
        RankTier.hierro => 'Terrícola',
        RankTier.bronce => 'Guerrero Z',
        RankTier.plata => 'Kaioken',
        RankTier.oro => 'SSJ',
        RankTier.platino => 'SSJ 2',
        RankTier.esmeralda => 'SSJ 3',
        RankTier.diamante => 'SSJ Blue',
        RankTier.maestro => 'Ultra Instinto',
      };

  // Pack media slot suffix for this transformation (transform_ssj.mp4…).
  String get slug => switch (this) {
        RankTier.hierro => 'terricola',
        RankTier.bronce => 'guerrero_z',
        RankTier.plata => 'kaioken',
        RankTier.oro => 'ssj',
        RankTier.platino => 'ssj2',
        RankTier.esmeralda => 'ssj3',
        RankTier.diamante => 'ssj_blue',
        RankTier.maestro => 'ultra_instinto',
      };
}

// Kaioken counts its grades as multipliers (×2, ×3, ×4); every other form
// uses I/II/III.
String rankGradeLabel(RankTier tier, int subTier) =>
    tier == RankTier.plata ? '×${subTier + 1}' : const ['', 'I', 'II', 'III'][subTier];

// A tier plus its I/II/III sub-step, e.g. "Oro II".
class Rank implements Comparable<Rank> {
  const Rank(this.tier, this.subTier);

  final RankTier tier;
  final int subTier; // 1..3

  String get label => '${tier.label} ${rankGradeLabel(tier, subTier)}';

  String get shortLabel => '${tier.shortLabel} ${rankGradeLabel(tier, subTier)}';

  // A single sortable/averageable number: tier index * 3 + subTier.
  double get score => tier.index * 3.0 + subTier;

  @override
  int compareTo(Rank other) => score.compareTo(other.score);

  @override
  bool operator ==(Object other) => other is Rank && other.tier == tier && other.subTier == subTier;

  @override
  int get hashCode => Object.hash(tier, subTier);
}
