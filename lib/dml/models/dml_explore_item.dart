class DmlServiceItem {
  final String id;
  final String title;
  final String summary;
  final String imagePath;
  final String audience;
  final String requiredInput;
  final String deliverable;
  final String duration;
  final List<String> processSteps;
  final List<String> relatedMethods;

  const DmlServiceItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.imagePath,
    required this.audience,
    required this.requiredInput,
    required this.deliverable,
    required this.duration,
    required this.processSteps,
    required this.relatedMethods,
  });
}

class DmlProductionMethod {
  final String id;
  final String title;
  final String fullName;
  final String summary;
  final String imagePath;
  final String workingPrinciple;
  final List<String> suitableFor;
  final List<String> materials;
  final List<String> strengths;
  final List<String> considerations;

  const DmlProductionMethod({
    required this.id,
    required this.title,
    required this.fullName,
    required this.summary,
    required this.imagePath,
    required this.workingPrinciple,
    required this.suitableFor,
    required this.materials,
    required this.strengths,
    required this.considerations,
  });
}

class DmlExploreData {
  final List<DmlServiceItem> services;
  final List<DmlProductionMethod> methods;

  const DmlExploreData({required this.services, required this.methods});
}
