import 'package:flutter/material.dart';

class StoreProduct {
  final String id;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final String usageTitle;
  final String usageDescription;
  final String whyRecommended;
  final String priceLabel;
  final double price;
  final String currencyCode;
  final IconData icon;
  final String imagePath;

  /// Ana ürün mü, yan ürün mü?
  final bool isAddOn;

  /// Yan ürün tek başına alınabilir mi?
  final bool canBePurchasedAlone;
  final bool isActive;
  final int sortOrder;

  const StoreProduct({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    required this.usageTitle,
    required this.usageDescription,
    required this.whyRecommended,
    required this.priceLabel,
    this.price = 0,
    this.currencyCode = 'TRY',
    required this.icon,
    required this.imagePath,
    this.isAddOn = false,
    this.canBePurchasedAlone = true,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory StoreProduct.fromMap(
    Map<String, dynamic> map, {
    required String priceLabel,
  }) {
    return StoreProduct(
      id: map['id'].toString(),
      title: (map['title'] ?? '').toString(),
      shortDescription: (map['short_description'] ?? '').toString(),
      fullDescription: (map['full_description'] ?? '').toString(),
      usageTitle: (map['usage_title'] ?? '').toString(),
      usageDescription: (map['usage_description'] ?? '').toString(),
      whyRecommended: (map['why_recommended'] ?? '').toString(),
      priceLabel: priceLabel,
      price:
          ((map['effective_price'] ?? map['base_price']) as num?)?.toDouble() ??
          0,
      currencyCode: (map['currency_code'] ?? 'TRY').toString(),
      icon: map['is_add_on'] == true
          ? Icons.inventory_2_outlined
          : Icons.accessibility_new,
      imagePath: (map['image_path'] ?? '').toString(),
      isAddOn: map['is_add_on'] == true,
      canBePurchasedAlone: map['can_be_purchased_alone'] != false,
      isActive: map['is_active'] != false,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
