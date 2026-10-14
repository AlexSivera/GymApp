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
        RankTier.hierro => 'Saiyan',
        RankTier.bronce => 'Super Saiyan',
        RankTier.plata => 'Super Saiyan 2',
        RankTier.oro => 'Super Saiyan 3',
        RankTier.platino => 'Super Saiyan 4',
        RankTier.esmeralda => 'Super Saiyan God',
        RankTier.diamante => 'Super Saiyan Blue',
        RankTier.maestro => 'Ultra Instinto',
      };

  // Compact form for chips and tight rows ("SSJ2").
  String get shortLabel => switch (this) {
        RankTier.hierro => 'Saiyan',
        RankTier.bronce => 'SSJ',
        RankTier.plata => 'SSJ2',
        RankTier.oro => 'SSJ3',
        RankTier.platino => 'SSJ4',
        RankTier.esmeralda => 'SSJ God',
        RankTier.diamante => 'SSJ Blue',
        RankTier.maestro => 'Ultra Instinto',
      };

  // Pack media slot suffix for this transformation (transform_ssj.mp4…).
  String get slug => switch (this) {
        RankTier.hierro => 'saiyan',
        RankTier.bronce => 'ssj',
        RankTier.plata => 'ssj2',
        RankTier.oro => 'ssj3',
        RankTier.platino => 'ssj4',
        RankTier.esmeralda => 'ssj_god',
        RankTier.diamante => 'ssj_blue',
        RankTier.maestro => 'ultra_instinto',
      };
}

// Grades are stars: "Super Saiyan 2 ★★" reads better than "… 2 II".
String rankGradeLabel(RankTier tier, int subTier) => '★' * subTier.clamp(1, 3);

// A tier plus its 1–3 star sub-step, e.g. "Super Saiyan ★★".
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
