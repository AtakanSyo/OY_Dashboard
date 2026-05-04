class PlantarPressureSummary {
  final double leftLoadPercentage;
  final double rightLoadPercentage;

  final double peakPressure;
  final String peakPressureRegion;

  final double stabilityScore;

  const PlantarPressureSummary({
    required this.leftLoadPercentage,
    required this.rightLoadPercentage,
    required this.peakPressure,
    required this.peakPressureRegion,
    required this.stabilityScore,
  });
}