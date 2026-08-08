// Eight-tier gamified rank ladder, from weakest to strongest. Purely a
// personal-progress scale — GymApp is local/single-user, so these are never
// compared against other real people's data (see StrengthStandards).
enum RankTier { hierro, bronce, plata, oro, platino, esmeralda, diamante, maestro }

extension RankTierLabel on RankTier {
  String get label => switch (this) {
        RankTier.hierro => 'Hierro',
        RankTier.bronce => 'Bronce',
        RankTier.plata => 'Plata',
        RankTier.oro => 'Oro',
        RankTier.platino => 'Platino',
        RankTier.esmeralda => 'Esmeralda',
        RankTier.diamante => 'Diamante',
        RankTier.maestro => 'Maestro',
      };
}

// A tier plus its I/II/III sub-step, e.g. "Oro II".
class Rank implements Comparable<Rank> {
  const Rank(this.tier, this.subTier);

  final RankTier tier;
  final int subTier; // 1..3

  String get label => '${tier.label} ${const ['', 'I', 'II', 'III'][subTier]}';

  // A single sortable/averageable number: tier index * 3 + subTier.
  double get score => tier.index * 3.0 + subTier;

  @override
  int compareTo(Rank other) => score.compareTo(other.score);

  @override
  bool operator ==(Object other) => other is Rank && other.tier == tier && other.subTier == subTier;

  @override
  int get hashCode => Object.hash(tier, subTier);
}
