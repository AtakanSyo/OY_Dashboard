class DmlCatalogItem {
  final String id;
  final String name;
  final String category;
  final String shortDescription;
  final String description;
  final String imagePath;
  final List<String> useCases;
  final List<String> materials;
  final List<String> scaleOptions;
  final List<String> includedStructures;
  final String productionTime;
  final String priceLabel;
  final bool customizable;

  const DmlCatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.shortDescription,
    required this.description,
    required this.imagePath,
    required this.useCases,
    required this.materials,
    required this.scaleOptions,
    required this.includedStructures,
    required this.productionTime,
    required this.priceLabel,
    required this.customizable,
  });
}
