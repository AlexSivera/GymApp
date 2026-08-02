// Epley formula — standard, simple estimate of 1-rep max from a working set.
double estimatedOneRepMax(double weightKg, int reps) {
  if (reps <= 1) return weightKg;
  return weightKg * (1 + reps / 30.0);
}
