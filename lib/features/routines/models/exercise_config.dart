// Target sets/reps/RIR/rest for one exercise within a routine day — shared
// between the single-exercise edit dialog and the batch add flow.
class ExerciseConfig {
  const ExerciseConfig({
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    required this.rir,
    required this.restSeconds,
  });

  static const defaults = ExerciseConfig(sets: 3, repsMin: 8, repsMax: 12, rir: null, restSeconds: 90);

  final int sets;
  final int repsMin;
  final int repsMax;
  final int? rir;
  final int? restSeconds;

  ExerciseConfig copyWith({
    int? sets,
    int? repsMin,
    int? repsMax,
    int? rir,
    bool clearRir = false,
    int? restSeconds,
    bool clearRestSeconds = false,
  }) {
    return ExerciseConfig(
      sets: sets ?? this.sets,
      repsMin: repsMin ?? this.repsMin,
      repsMax: repsMax ?? this.repsMax,
      rir: clearRir ? null : (rir ?? this.rir),
      restSeconds: clearRestSeconds ? null : (restSeconds ?? this.restSeconds),
    );
  }
}
