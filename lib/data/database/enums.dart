// `rest` appended at the end (not alphabetically) so existing rows keep their
// integer index after the v2 schema migration.
enum SessionStatus { planned, inProgress, completed, skipped, rest }

enum PersonalRecordType { maxWeight, maxReps, estimatedOneRepMax, maxVolume }

enum SessionExerciseStatus { pending, inProgress, completed, skipped }

// `strength` first so it stays the default for every existing exercise row
// once this column is added by migration.
enum ExerciseCategory { strength, cardio }
