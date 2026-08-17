import 'package:flutter/material.dart';

class DmlCapability {
  final IconData icon;
  final String title;
  final String description;

  const DmlCapability({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class DmlCaseStudy {
  final String category;
  final String title;
  final String description;
  final String method;

  const DmlCaseStudy({
    required this.category,
    required this.title,
    required this.description,
    required this.method,
  });
}

class DmlHomeData {
  final List<DmlCapability> capabilities;
  final List<DmlCaseStudy> caseStudies;
  final List<String> workflowSteps;

  const DmlHomeData({
    required this.capabilities,
    required this.caseStudies,
    required this.workflowSteps,
  });
}
