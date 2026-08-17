class ParsedScanReport {
  final String? reportNo;
  final String? reportDate;
  final String? reportTime;
  final String? storeCode;
  final String? address;

  final String? customerName;
  final String? gender;
  final String? age;
  final String? phone;

  final double? leftFootLength;
  final double? rightFootLength;

  final double? leftSoleLength;
  final double? rightSoleLength;

  final double? leftArchLength;
  final double? rightArchLength;

  final double? leftFirstMetaLength;
  final double? rightFirstMetaLength;

  final double? leftFifthMetaLength;
  final double? rightFifthMetaLength;

  final double? leftHalluxBumpsLength;
  final double? rightHalluxBumpsLength;

  final double? leftFootFlankLength;
  final double? rightFootFlankLength;

  final double? leftHeelCenterLength;
  final double? rightHeelCenterLength;

  final double? leftHeelMarginLength;
  final double? rightHeelMarginLength;

  final double? leftFootWidth;
  final double? rightFootWidth;

  final double? leftSlantWidth;
  final double? rightSlantWidth;

  final double? leftToeWidth;
  final double? rightToeWidth;

  final double? leftArchOutsideWidth;
  final double? rightArchOutsideWidth;

  final double? leftFootFlankWidth;
  final double? rightFootFlankWidth;

  final double? leftHeelCenterWidth;
  final double? rightHeelCenterWidth;

  final double? leftTotalHeelWidth;
  final double? rightTotalHeelWidth;

  final double? leftArchHeight;
  final double? rightArchHeight;

  final double? leftFirstMetaJointHeight;
  final double? rightFirstMetaJointHeight;

  final double? leftHeelProtrusionHeight;
  final double? rightHeelProtrusionHeight;

  final double? leftHalluxAngle;
  final double? rightHalluxAngle;

  final double? leftPronatorAngle;
  final double? rightPronatorAngle;

  final double? leftKneeAngle;
  final double? rightKneeAngle;

  final String? leftShoeSize;
  final String? rightShoeSize;

  final String? leftInsoleRecommendation;
  final String? rightInsoleRecommendation;

  final String? leftArchType;
  final String? rightArchType;

  final double? leftArchIndex;
  final double? rightArchIndex;

  final double? leftArchWidthIndex;
  final double? rightArchWidthIndex;

  final String? leftHalluxType;
  final String? rightHalluxType;

  final String? leftHeelType;
  final String? rightHeelType;

  final String? leftKneeType;
  final String? rightKneeType;

  final String? recommendationText;
  final String? rawText;

  const ParsedScanReport({
    this.reportNo,
    this.reportDate,
    this.reportTime,
    this.storeCode,
    this.address,
    this.customerName,
    this.gender,
    this.age,
    this.phone,
    this.leftFootLength,
    this.rightFootLength,
    this.leftSoleLength,
    this.rightSoleLength,
    this.leftArchLength,
    this.rightArchLength,
    this.leftFirstMetaLength,
    this.rightFirstMetaLength,
    this.leftFifthMetaLength,
    this.rightFifthMetaLength,
    this.leftHalluxBumpsLength,
    this.rightHalluxBumpsLength,
    this.leftFootFlankLength,
    this.rightFootFlankLength,
    this.leftHeelCenterLength,
    this.rightHeelCenterLength,
    this.leftHeelMarginLength,
    this.rightHeelMarginLength,
    this.leftFootWidth,
    this.rightFootWidth,
    this.leftSlantWidth,
    this.rightSlantWidth,
    this.leftToeWidth,
    this.rightToeWidth,
    this.leftArchOutsideWidth,
    this.rightArchOutsideWidth,
    this.leftFootFlankWidth,
    this.rightFootFlankWidth,
    this.leftHeelCenterWidth,
    this.rightHeelCenterWidth,
    this.leftTotalHeelWidth,
    this.rightTotalHeelWidth,
    this.leftArchHeight,
    this.rightArchHeight,
    this.leftFirstMetaJointHeight,
    this.rightFirstMetaJointHeight,
    this.leftHeelProtrusionHeight,
    this.rightHeelProtrusionHeight,
    this.leftHalluxAngle,
    this.rightHalluxAngle,
    this.leftPronatorAngle,
    this.rightPronatorAngle,
    this.leftKneeAngle,
    this.rightKneeAngle,
    this.leftShoeSize,
    this.rightShoeSize,
    this.leftInsoleRecommendation,
    this.rightInsoleRecommendation,
    this.leftArchType,
    this.rightArchType,
    this.leftArchIndex,
    this.rightArchIndex,
    this.leftArchWidthIndex,
    this.rightArchWidthIndex,
    this.leftHalluxType,
    this.rightHalluxType,
    this.leftHeelType,
    this.rightHeelType,
    this.leftKneeType,
    this.rightKneeType,
    this.recommendationText,
    this.rawText,
  });

  factory ParsedScanReport.fromMap(Map<String, dynamic> map) {
    dynamic valueFor(String key) {
      if (map.containsKey(key)) return map[key];
      final snakeCase = key.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      );
      return map[snakeCase];
    }

    double? number(String key) {
      final value = valueFor(key);
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString().replaceAll(',', '.') ?? '');
    }

    String? text(String key) {
      final value = valueFor(key)?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    return ParsedScanReport(
      reportNo: text('reportNo'),
      reportDate: text('reportDate'),
      reportTime: text('reportTime'),
      storeCode: text('storeCode'),
      address: text('address'),
      customerName: text('customerName'),
      gender: text('gender'),
      age: text('age'),
      phone: text('phone'),
      leftFootLength: number('leftFootLength'),
      rightFootLength: number('rightFootLength'),
      leftSoleLength: number('leftSoleLength'),
      rightSoleLength: number('rightSoleLength'),
      leftArchLength: number('leftArchLength'),
      rightArchLength: number('rightArchLength'),
      leftFirstMetaLength: number('leftFirstMetaLength'),
      rightFirstMetaLength: number('rightFirstMetaLength'),
      leftFifthMetaLength: number('leftFifthMetaLength'),
      rightFifthMetaLength: number('rightFifthMetaLength'),
      leftFootWidth: number('leftFootWidth'),
      rightFootWidth: number('rightFootWidth'),
      leftToeWidth: number('leftToeWidth'),
      rightToeWidth: number('rightToeWidth'),
      leftArchOutsideWidth: number('leftArchOutsideWidth'),
      rightArchOutsideWidth: number('rightArchOutsideWidth'),
      leftTotalHeelWidth: number('leftTotalHeelWidth'),
      rightTotalHeelWidth: number('rightTotalHeelWidth'),
      leftArchHeight: number('leftArchHeight'),
      rightArchHeight: number('rightArchHeight'),
      leftFirstMetaJointHeight: number('leftFirstMetaJointHeight'),
      rightFirstMetaJointHeight: number('rightFirstMetaJointHeight'),
      leftHalluxAngle: number('leftHalluxAngle'),
      rightHalluxAngle: number('rightHalluxAngle'),
      leftPronatorAngle: number('leftPronatorAngle'),
      rightPronatorAngle: number('rightPronatorAngle'),
      leftKneeAngle: number('leftKneeAngle'),
      rightKneeAngle: number('rightKneeAngle'),
      leftArchType: text('leftArchType'),
      rightArchType: text('rightArchType'),
      leftArchIndex: number('leftArchIndex'),
      rightArchIndex: number('rightArchIndex'),
      leftArchWidthIndex: number('leftArchWidthIndex'),
      rightArchWidthIndex: number('rightArchWidthIndex'),
      leftHalluxType: text('leftHalluxType'),
      rightHalluxType: text('rightHalluxType'),
      leftHeelType: text('leftHeelType'),
      rightHeelType: text('rightHeelType'),
      leftKneeType: text('leftKneeType'),
      rightKneeType: text('rightKneeType'),
      leftInsoleRecommendation: text('leftInsoleRecommendation'),
      rightInsoleRecommendation: text('rightInsoleRecommendation'),
      recommendationText: text('recommendationText'),
      rawText: text('rawText'),
    );
  }

  factory ParsedScanReport.merge({
    required ParsedScanReport? preferred,
    required ParsedScanReport? fallback,
  }) {
    final p = preferred;
    final f = fallback;
    return ParsedScanReport(
      reportNo: p?.reportNo ?? f?.reportNo,
      reportDate: p?.reportDate ?? f?.reportDate,
      reportTime: p?.reportTime ?? f?.reportTime,
      storeCode: p?.storeCode ?? f?.storeCode,
      address: p?.address ?? f?.address,
      customerName: p?.customerName ?? f?.customerName,
      leftFootLength: p?.leftFootLength ?? f?.leftFootLength,
      rightFootLength: p?.rightFootLength ?? f?.rightFootLength,
      leftSoleLength: p?.leftSoleLength ?? f?.leftSoleLength,
      rightSoleLength: p?.rightSoleLength ?? f?.rightSoleLength,
      leftArchLength: p?.leftArchLength ?? f?.leftArchLength,
      rightArchLength: p?.rightArchLength ?? f?.rightArchLength,
      leftFirstMetaLength: p?.leftFirstMetaLength ?? f?.leftFirstMetaLength,
      rightFirstMetaLength: p?.rightFirstMetaLength ?? f?.rightFirstMetaLength,
      leftFifthMetaLength: p?.leftFifthMetaLength ?? f?.leftFifthMetaLength,
      rightFifthMetaLength: p?.rightFifthMetaLength ?? f?.rightFifthMetaLength,
      leftFootWidth: p?.leftFootWidth ?? f?.leftFootWidth,
      rightFootWidth: p?.rightFootWidth ?? f?.rightFootWidth,
      leftToeWidth: p?.leftToeWidth ?? f?.leftToeWidth,
      rightToeWidth: p?.rightToeWidth ?? f?.rightToeWidth,
      leftArchOutsideWidth: p?.leftArchOutsideWidth ?? f?.leftArchOutsideWidth,
      rightArchOutsideWidth:
          p?.rightArchOutsideWidth ?? f?.rightArchOutsideWidth,
      leftTotalHeelWidth: p?.leftTotalHeelWidth ?? f?.leftTotalHeelWidth,
      rightTotalHeelWidth: p?.rightTotalHeelWidth ?? f?.rightTotalHeelWidth,
      leftArchHeight: p?.leftArchHeight ?? f?.leftArchHeight,
      rightArchHeight: p?.rightArchHeight ?? f?.rightArchHeight,
      leftFirstMetaJointHeight:
          p?.leftFirstMetaJointHeight ?? f?.leftFirstMetaJointHeight,
      rightFirstMetaJointHeight:
          p?.rightFirstMetaJointHeight ?? f?.rightFirstMetaJointHeight,
      leftHalluxAngle: p?.leftHalluxAngle ?? f?.leftHalluxAngle,
      rightHalluxAngle: p?.rightHalluxAngle ?? f?.rightHalluxAngle,
      leftPronatorAngle: p?.leftPronatorAngle ?? f?.leftPronatorAngle,
      rightPronatorAngle: p?.rightPronatorAngle ?? f?.rightPronatorAngle,
      leftKneeAngle: p?.leftKneeAngle ?? f?.leftKneeAngle,
      rightKneeAngle: p?.rightKneeAngle ?? f?.rightKneeAngle,
      leftArchType: p?.leftArchType ?? f?.leftArchType,
      rightArchType: p?.rightArchType ?? f?.rightArchType,
      leftArchIndex: p?.leftArchIndex ?? f?.leftArchIndex,
      rightArchIndex: p?.rightArchIndex ?? f?.rightArchIndex,
      leftArchWidthIndex: p?.leftArchWidthIndex ?? f?.leftArchWidthIndex,
      rightArchWidthIndex: p?.rightArchWidthIndex ?? f?.rightArchWidthIndex,
      leftHalluxType: p?.leftHalluxType ?? f?.leftHalluxType,
      rightHalluxType: p?.rightHalluxType ?? f?.rightHalluxType,
      leftHeelType: p?.leftHeelType ?? f?.leftHeelType,
      rightHeelType: p?.rightHeelType ?? f?.rightHeelType,
      leftKneeType: p?.leftKneeType ?? f?.leftKneeType,
      rightKneeType: p?.rightKneeType ?? f?.rightKneeType,
      leftInsoleRecommendation:
          p?.leftInsoleRecommendation ?? f?.leftInsoleRecommendation,
      rightInsoleRecommendation:
          p?.rightInsoleRecommendation ?? f?.rightInsoleRecommendation,
      recommendationText: p?.recommendationText ?? f?.recommendationText,
      rawText: p?.rawText ?? f?.rawText,
    );
  }

  bool get hasAnyCoreMeasurement =>
      leftFootLength != null ||
      rightFootLength != null ||
      leftFootWidth != null ||
      rightFootWidth != null ||
      leftArchHeight != null ||
      rightArchHeight != null;
}
