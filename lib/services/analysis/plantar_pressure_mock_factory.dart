import 'models/plantar_pressure_summary.dart';

class PlantarPressureMockFactory {
  const PlantarPressureMockFactory();

  PlantarPressureSummary buildBalanced() {
    return const PlantarPressureSummary(
      leftLoadPercentage: 50,
      rightLoadPercentage: 50,
      peakPressure: 240,
      peakPressureRegion: 'Topuk',
      stabilityScore: 82,
    );
  }

  PlantarPressureSummary buildLeftDominant() {
    return const PlantarPressureSummary(
      leftLoadPercentage: 56,
      rightLoadPercentage: 44,
      peakPressure: 310,
      peakPressureRegion: 'Sol topuk',
      stabilityScore: 70,
    );
  }

  PlantarPressureSummary buildRightDominant() {
    return const PlantarPressureSummary(
      leftLoadPercentage: 44,
      rightLoadPercentage: 56,
      peakPressure: 305,
      peakPressureRegion: 'Sağ ön ayak',
      stabilityScore: 72,
    );
  }

  PlantarPressureSummary buildHighPressure() {
    return const PlantarPressureSummary(
      leftLoadPercentage: 54,
      rightLoadPercentage: 46,
      peakPressure: 370,
      peakPressureRegion: 'Topuk',
      stabilityScore: 62,
    );
  }

  PlantarPressureSummary buildDefaultForTest() {
    return buildLeftDominant();
  }
}