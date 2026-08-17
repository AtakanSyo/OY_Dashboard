// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'English';

  @override
  String get login => 'Log In';

  @override
  String get register => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get profile => 'Profile';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get editInformation => 'Edit Information';

  @override
  String get logout => 'Log Out';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get customers => 'Customers';

  @override
  String get measurementHistory => 'Measurement History';

  @override
  String get orders => 'Orders';

  @override
  String get support => 'Support';

  @override
  String get home => 'Home';

  @override
  String get myAnalysisResults => 'My Analysis Results';

  @override
  String get store => 'Store';

  @override
  String get departmentAnalysis => 'Department Analysis';

  @override
  String get trends => 'Trends';

  @override
  String get employees => 'Employees';

  @override
  String get reports => 'Reports';

  @override
  String get salesStatistics => 'Sales Statistics';

  @override
  String get measurementPool => 'Measurement Pool';

  @override
  String get operations => 'Operations';

  @override
  String get digitalManufacturingLab => 'Digital Manufacturing Lab';

  @override
  String get services => 'Services';

  @override
  String get products => 'Products';

  @override
  String get measurementCenters => 'Measurement Centers';

  @override
  String get aboutUs => 'About Us';

  @override
  String get loading => 'Loading...';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Try Again';

  @override
  String get back => 'Back';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get editInformationComingSoon =>
      'The information editing screen will be connected later.';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get passwordReset => 'Reset Password';

  @override
  String get passwordResetDescription =>
      'Enter the email address linked to your account. We will send you a link to reset your password.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get newPassword => 'New Password';

  @override
  String get newPasswordAgain => 'New Password Again';

  @override
  String get setNewPassword => 'Set New Password';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get passwordUpdated => 'Password Updated';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get passwordAgain => 'Confirm Password';

  @override
  String get userType => 'User Type';

  @override
  String get alreadyHaveAccount => 'Already have an account? Log In';

  @override
  String get noAccount => 'Don\'t have an account? Sign Up';

  @override
  String get continueAction => 'Continue';

  @override
  String get invalidInvitation => 'Invalid Invitation Link';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get registerWithInvitation => 'Sign Up with Invitation Link';

  @override
  String get customerRole => 'Customer';

  @override
  String get expertRole => 'Specialist';

  @override
  String get corporateRole => 'Corporate';

  @override
  String get optiyouTeamRole => 'Optiyou Team';

  @override
  String get homeLoadError => 'Home page information could not be loaded.';

  @override
  String get partialHomeDataWarning =>
      'Some current information could not be loaded. You can continue using the other sections.';

  @override
  String get dataUnavailable => 'Information unavailable';

  @override
  String get noAssessmentYet => 'No assessment yet';

  @override
  String get noAssessmentYetDescription =>
      'Your assessment will appear here once a measurement result is linked to your account.';

  @override
  String get noActiveOrder => 'No active order';

  @override
  String get noActiveOrderDescription =>
      'You do not have a new or ongoing order.';

  @override
  String get recommendationPending => 'Specialist recommendation pending';

  @override
  String get recommendationPendingDescription =>
      'Your specialist recommendation will appear here when it is added to the assessment.';

  @override
  String get assessmentSummaryAvailable =>
      'Your assessment is ready. Open the results screen to review detailed findings and measurements.';

  @override
  String orderedOn(String date) {
    return 'Order date: $date';
  }

  @override
  String get browseProducts => 'Browse Products';

  @override
  String get productSelectionPendingDescription =>
      'A suitable product has not yet been selected. Product selection will be confirmed through specialist assessment.';

  @override
  String get notSpecified => 'Not specified';

  @override
  String helloUser(String name) {
    return 'Hello, $name';
  }

  @override
  String get customerHomeIntro =>
      'Track your foot health assessments, recommendations, and orders here.';

  @override
  String get viewMyAssessment => 'View my assessment';

  @override
  String get trackMyOrder => 'Track my order';

  @override
  String get latestAssessment => 'Latest assessment';

  @override
  String get activeOrder => 'Active order';

  @override
  String get recommendedProduct => 'Recommended product';

  @override
  String get personalRecommendation => 'Personal recommendation';

  @override
  String get orderProcess => 'Order progress';

  @override
  String get orderReceived => 'Received';

  @override
  String get design => 'Design';

  @override
  String get production => 'Production';

  @override
  String get shipped => 'Shipped';

  @override
  String get delivered => 'Delivered';

  @override
  String estimatedDelivery(String date) {
    return 'Estimated delivery: $date';
  }

  @override
  String get goToOrderDetails => 'Go to order details';

  @override
  String get specialistRecommendation => 'Recommendation from your specialist';

  @override
  String updatedOn(String date) {
    return 'Updated: $date';
  }

  @override
  String get yourLatestAssessment => 'Your latest assessment';

  @override
  String get viewDetailedAssessment => 'View detailed assessment';

  @override
  String get productRecommendedForYou => 'Product recommended for you';

  @override
  String get viewProduct => 'View product';

  @override
  String get haveAQuestion => 'Do you have a question?';

  @override
  String get supportTeamCanHelp => 'Our support team can help you.';

  @override
  String get getSupport => 'Get support';

  @override
  String get assessmentReady => 'Assessment ready';

  @override
  String get assessmentMockSummary =>
      'Your foot assessment indicates a need for arch support and increased load in the heel area.';

  @override
  String get archSupportNeed => 'Arch support needed';

  @override
  String get increasedHeelLoad => 'Increased heel load';

  @override
  String get personalSupportRecommendation =>
      'Personalized support recommendation';

  @override
  String get specialistMockNote =>
      'On days when you stand for long periods, using supportive insoles and having your product checked regularly is recommended.';

  @override
  String get inProduction => 'In production';

  @override
  String get customOrthopedicInsole => 'Custom Orthopedic Insole';

  @override
  String get customInsole => 'Custom Insole';

  @override
  String get customInsoleDescription =>
      'Helps balance pressure distribution during daily use and provide support tailored to your feet.';

  @override
  String get customInsoleReason =>
      'Recommended based on the need for arch support identified in your latest assessment.';

  @override
  String get enterEmail => 'Please enter your email address.';

  @override
  String get enterPassword => 'Please enter your password.';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get invalidCredentials => 'Incorrect email or password.';

  @override
  String get emailNotConfirmed => 'Your email address has not been confirmed.';

  @override
  String get tooManyAttempts => 'Too many attempts. Please wait and try again.';

  @override
  String get enterValidEmail => 'Please enter a valid email address.';

  @override
  String get resetLinkSent =>
      'The password reset link has been sent. Please check your inbox.';

  @override
  String get sending => 'Sending...';

  @override
  String get saving => 'Saving...';

  @override
  String get setPasswordDescription => 'Set a new password for your account.';

  @override
  String get saveNewPassword => 'Save New Password';

  @override
  String get enterPasswordTwice => 'Please enter your new password twice.';

  @override
  String get passwordMinEight => 'The password must be at least 8 characters.';

  @override
  String get passwordMinSix => 'The password must be at least 6 characters.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get registrationComplete => 'Registration Complete!';

  @override
  String get enterFirstAndLastName => 'Please enter your first and last name.';

  @override
  String get selectUserType => 'Please select a user type.';

  @override
  String get qrFootHealthEcosystem => 'Foot Health Ecosystem';

  @override
  String get qrDigitalManufacturing => 'Digital Manufacturing';

  @override
  String get qrPerformanceSupport => 'Performance Support';

  @override
  String get qrWelcomeTitle => 'Welcome to the Optiyou ecosystem.';

  @override
  String get qrWelcomeDescription =>
      'We bring measurement, specialist assessment, and access to results together in one user journey. Use the QR link to create your account and securely access your personal results.';

  @override
  String get qrCheckingLink => 'Checking your results access link...';

  @override
  String get qrLinkReady =>
      'This link is ready for personal results access. You can create an account or log in on this page.';

  @override
  String get qrGoToRegistration => 'Go to User Registration';

  @override
  String get qrRegistrationEyebrow => 'User registration';

  @override
  String get qrRegistrationTitle =>
      'Connect your results to your secure personal account.';

  @override
  String get qrRegistrationDescription =>
      'The QR link identifies your measurement record. When you create an account or log in, your analysis report and product recommendation are linked to your application account.';

  @override
  String get qrCreateAccount => 'Create Account';

  @override
  String get qrCreateAndClaim => 'Create Account and Link My Results';

  @override
  String get qrCreateAndContinue => 'Create Account and Continue';

  @override
  String get qrLoginAndClaim => 'Log In and Link My Results';

  @override
  String get qrLoginAndContinue => 'Log In and Open the App';

  @override
  String get qrReady => 'You\'re all set.';

  @override
  String get qrClaimSuccess =>
      'Your results have been linked to your account. You can view your analysis report, usage recommendations, and support options in the app.';

  @override
  String get qrAccountReady =>
      'Your account is ready. You can continue to the Optiyou app.';

  @override
  String get qrOpenApp => 'Open the App';

  @override
  String get qrResults => 'Results';

  @override
  String get qrResultsTitle =>
      'Your analysis report, product recommendation, and follow-up information in one place.';

  @override
  String get qrResultsDescription =>
      'Once registration is complete, you can view your measurement history, specialist assessment, and recommended product from your Optiyou account.';

  @override
  String get qrAnalysisSummary => 'Analysis summary';

  @override
  String get qrAnalysisSummaryText =>
      'Pressure, balance, and support needs are presented under clear headings.';

  @override
  String get qrSuitableProduct => 'Product recommendation for you';

  @override
  String get qrSuitableProductText =>
      'A suitable solution is selected from our product range based on your assessment.';

  @override
  String get qrTrackingHistory => 'Follow-up history';

  @override
  String get qrTrackingHistoryText =>
      'Changes and usage notes can be compared in future measurements.';

  @override
  String get qrOpenResults => 'Open Results';

  @override
  String get qrPersonalResults => 'Personal results overview';

  @override
  String get qrAnalysisScore => 'Analysis score';

  @override
  String get qrSupportNeed => 'Support need';

  @override
  String get qrMedium => 'Moderate';

  @override
  String get qrPersonalInsole => 'Personalized insole';

  @override
  String analysisResultsLoadError(String error) {
    return 'An error occurred while loading analysis results: $error';
  }

  @override
  String get noAnalysisResults => 'No analysis results found.';

  @override
  String get analysisWillAppear =>
      'Your measurement results will appear here once they are linked to your account.';

  @override
  String get checkAgain => 'Check Again';

  @override
  String get myProfile => 'My Profile';

  @override
  String get customerProfile => 'Customer Profile';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get fullName => 'Full Name';

  @override
  String get phone => 'Phone';

  @override
  String get role => 'Role';

  @override
  String get shortSummary => 'Summary';

  @override
  String get totalAnalyses => 'Total Analyses';

  @override
  String get myInsoleImages => 'My Insole Images';

  @override
  String get uploadInsoleImage => 'Upload Insole Image';

  @override
  String get noInsoleImages => 'No insole images have been uploaded yet.';

  @override
  String get imageUnavailable => 'Image unavailable';

  @override
  String get insoleImagesTemporaryNote =>
      'Images added here are previewed only during this session and are not yet saved to your account.';

  @override
  String get assessmentResults => 'Assessment Results';

  @override
  String get assessmentNotFound => 'No assessment result found.';

  @override
  String get preparingAssessment => 'Preparing assessment data...';

  @override
  String get measurementHistoryTitle => 'Measurement History';

  @override
  String get selectMeasurementSession =>
      'Select the measurement session you want to view.';

  @override
  String get preparingPdf => 'Preparing PDF...';

  @override
  String get savePdf => 'Save PDF';

  @override
  String get assessmentIntro =>
      '3D anatomical measurements, visual assessments, and plantar pressure results.';

  @override
  String get locationNotSpecified => 'Location not specified';

  @override
  String get anatomicalMeasurements => 'Anatomical Measurements';

  @override
  String get anatomicalMeasurementsSubtitle =>
      'Anatomical measurements obtained from the 3D scan.';

  @override
  String get noParsedScanReport =>
      'No parsed 3D scan report is available for this measurement.';

  @override
  String get left => 'Left';

  @override
  String get right => 'Right';

  @override
  String get leftFoot => 'Left Foot';

  @override
  String get rightFoot => 'Right Foot';

  @override
  String get footLength => 'Foot Length';

  @override
  String get soleLength => 'Sole Length';

  @override
  String get footWidth => 'Foot Width';

  @override
  String get forefootWidth => 'Forefoot Width';

  @override
  String get toeWidth => 'Toe Width';

  @override
  String get archLength => 'Arch Length';

  @override
  String get archHeight => 'Arch Height';

  @override
  String get outerArchWidth => 'Outer Arch Width';

  @override
  String get heelWidth => 'Heel Width';

  @override
  String get firstMetatarsalLength => '1st Metatarsal Length';

  @override
  String get fifthMetatarsalLength => '5th Metatarsal Length';

  @override
  String get metatarsalJointHeight => 'Metatarsal Joint Height';

  @override
  String get archStructure => 'Arch Structure';

  @override
  String get archStructureSubtitle => 'Arch height, width, and surface form.';

  @override
  String get archHeightMap => 'Arch Height Map';

  @override
  String get archIndex => 'Arch Index';

  @override
  String get archSectionImage => 'Arch Cross-Section Image';

  @override
  String get archWidthIndex => 'Arch Width Index';

  @override
  String get footFormHallux => 'Foot Form and Hallux Alignment';

  @override
  String get footFormHalluxSubtitle =>
      'Bilateral view of forefoot form and hallux angle.';

  @override
  String get footImage => 'Foot Image';

  @override
  String get halluxAngleType => 'Hallux Angle and Type';

  @override
  String get rearfootPronation => 'Rearfoot and Pronation';

  @override
  String get rearfootPronationSubtitle =>
      'Heel-ankle, pronation, and knee alignment.';

  @override
  String get ankleAlignment => 'Foot-Ankle Alignment';

  @override
  String get pronationAngleHeelType => 'Pronation Angle and Heel Type';

  @override
  String get kneeAngleAlignment => 'Knee Angle and Alignment';

  @override
  String get findingsAndImages => 'Assessment Findings and Images';

  @override
  String get findingsAndImagesSubtitle =>
      'Left and right foot descriptions, images, and values are shown together.';

  @override
  String get loadingImages => 'Loading images...';

  @override
  String get productAssessment => 'Product Assessment';

  @override
  String get productAssessmentSubtitle =>
      'Product recommended based on the assessment result.';

  @override
  String get productRecommended => 'Recommended Product';

  @override
  String get productNotDetermined => 'No product has been determined.';

  @override
  String get imageNotFound => 'Image not found.';

  @override
  String get imagePathNotFound => 'Image path not found.';

  @override
  String get imageCouldNotOpen => 'Image could not be opened.';

  @override
  String get noData => 'No data';

  @override
  String get normal => 'Normal';

  @override
  String get mild => 'Mild';

  @override
  String get moderate => 'Moderate';

  @override
  String get severe => 'Severe';

  @override
  String get highArch => 'High Arch';

  @override
  String get normalArch => 'Normal Arch';

  @override
  String get mildFlatFoot => 'Mild Flat Foot';

  @override
  String get moderateFlatFoot => 'Moderate Flat Foot';

  @override
  String get severeFlatFoot => 'Severe Flat Foot';

  @override
  String get plantarPressureMeasurements => 'Plantar Pressure Measurements';

  @override
  String get plantarPressureSubtitle =>
      'Pressure recordings captured during the selected session.';

  @override
  String get noPressureRecordings =>
      'No plantar pressure recording is available for this session.';

  @override
  String get selectPressureRecording =>
      'Select a pressure recording to view it.';

  @override
  String get pressureHeatmap => 'Pressure Heatmap';

  @override
  String frameCounter(int current, int total) {
    return 'Frame $current/$total';
  }

  @override
  String get loadDistribution => 'Load Distribution';

  @override
  String get weight => 'Weight';

  @override
  String get leftRightLoad => 'Left / Right Load Distribution';

  @override
  String get forefootHeelLoad => 'Forefoot / Heel Distribution';

  @override
  String get forefoot => 'Forefoot';

  @override
  String get heel => 'Heel';

  @override
  String get frameCount => 'Frame Count';

  @override
  String get duration => 'Duration';

  @override
  String get maximumRawValue => 'Maximum Raw Value';

  @override
  String get averageRawValue => 'Average Raw Value';

  @override
  String get physicalValueUnavailable =>
      'Physical value could not be calculated';

  @override
  String framesRecorded(int count) {
    return '$count frames';
  }

  @override
  String get footLengthDescription =>
      'Distance from the heel to the longest toe.';

  @override
  String get soleLengthDescription => 'Anatomical contact length of the sole.';

  @override
  String get footWidthDescription =>
      'Widest anatomical distance across the forefoot.';

  @override
  String get forefootWidthDescription =>
      'Width at the level of the toe joints.';

  @override
  String get archLengthDescription => 'Length of the medial longitudinal arch.';

  @override
  String get archHeightDescription => 'Maximum height of the foot arch.';

  @override
  String get outerArchWidthDescription =>
      'Outer width measurement of the arch region.';

  @override
  String get heelWidthDescription => 'Total width of the heel region.';

  @override
  String get firstMetatarsalDescription =>
      'Anatomical length of the first metatarsal.';

  @override
  String get fifthMetatarsalDescription =>
      'Anatomical length of the fifth metatarsal.';

  @override
  String get metatarsalJointDescription =>
      'Height at the first metatarsal joint region.';

  @override
  String get halluxNoData =>
      'No assessment data is available for the hallux angle.';

  @override
  String get halluxNormal =>
      'The big toe alignment appears to be within the normal angle range.';

  @override
  String get halluxMild =>
      'A mild alignment change is visible in the big toe angle.';

  @override
  String get halluxMarked =>
      'A marked alignment change is visible in the big toe angle.';

  @override
  String get pronationNoData =>
      'No assessment data is available for the pronation angle.';

  @override
  String get pronationNormal =>
      'Rearfoot alignment appears to be within the normal angle range.';

  @override
  String get pronationMild =>
      'A mild pronation or supination tendency is visible in the rearfoot.';

  @override
  String get pronationMarked =>
      'A marked angle change is visible in rearfoot alignment.';

  @override
  String get sessionIdMissing =>
      'No session ID is available for this assessment.';

  @override
  String get assessmentImagesUnavailable =>
      'No usable assessment images are available for this session.';

  @override
  String assessmentImagesLoadError(String error) {
    return 'Assessment images could not be loaded: $error';
  }

  @override
  String pressureRecordingsLoadError(String error) {
    return 'Pressure recordings could not be loaded: $error';
  }

  @override
  String pressureDataOpenError(String error) {
    return 'Pressure recording data could not be opened: $error';
  }

  @override
  String get leftArchDescriptionUnavailable =>
      'No description is available for the left arch structure.';

  @override
  String get rightArchDescriptionUnavailable =>
      'No description is available for the right arch structure.';

  @override
  String get pdfSaved => 'The PDF report has been saved.';

  @override
  String pdfCreateError(String error) {
    return 'The PDF report could not be created: $error';
  }

  @override
  String get myOrders => 'My Orders';

  @override
  String get customerOrdersIntro =>
      'Track the production and delivery status of your orders here.';

  @override
  String get orderManagementIntro =>
      'Track order progress and production statuses here.';

  @override
  String get orderSearchHint => 'Search by order number, product, or status';

  @override
  String ordersLoadError(String error) {
    return 'An error occurred while loading orders: $error';
  }

  @override
  String get customerAccountNotLinked =>
      'No customer record is linked to your account.';

  @override
  String get noCustomerOrders => 'You do not have any orders yet.';

  @override
  String get noSavedOrders => 'No saved orders were found.';

  @override
  String get productLabel => 'Product';

  @override
  String get netAmountLabel => 'Net Amount';

  @override
  String orderedChip(String date) {
    return 'Ordered: $date';
  }

  @override
  String shippedChip(String date) {
    return 'Shipped: $date';
  }

  @override
  String deliveredChip(String date) {
    return 'Delivered: $date';
  }

  @override
  String get orderDetailTitle => 'Order Details';

  @override
  String get orderStatusUpdated => 'The order status has been updated.';

  @override
  String orderStatusUpdateError(String error) {
    return 'The order could not be updated: $error';
  }

  @override
  String get orderInformation => 'Order Information';

  @override
  String get orderNumberLabel => 'Order Number';

  @override
  String get orderDateLabel => 'Order Date';

  @override
  String get shipmentDateLabel => 'Shipment Date';

  @override
  String get deliveryDateLabel => 'Delivery Date';

  @override
  String get deliveryAddressTitle => 'Delivery Address';

  @override
  String get deliveryAddressMissing =>
      'No delivery address is available for this order.';

  @override
  String get updateOrderStatus => 'Update Status';

  @override
  String get orderStatusLabel => 'Order Status';

  @override
  String get orderFlowTitle => 'Production and Order Progress';

  @override
  String completionRate(int percent) {
    return 'Completion: $percent%';
  }

  @override
  String get priceInformation => 'Price Information';

  @override
  String get grossAmount => 'Gross Amount';

  @override
  String get discountAmount => 'Discount';

  @override
  String get currency => 'Currency';

  @override
  String get stepCompleted => 'Completed';

  @override
  String get stepWaiting => 'Waiting';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get designingStatus => 'Designing';

  @override
  String get productionStatus => 'In Production';

  @override
  String get shippedStatus => 'Shipped';

  @override
  String get deliveredStatus => 'Delivered';

  @override
  String get cancelledStatus => 'Cancelled';

  @override
  String get insoleProduct => 'Insole';

  @override
  String get sportsInsoleProduct => 'Sports Insole';

  @override
  String get sandalProduct => 'Sandal';

  @override
  String get orderReceivedDescription =>
      'Your order has been recorded and is now being processed.';

  @override
  String get designPreparation => 'Design Preparation';

  @override
  String get designPreparationDescription =>
      'Technical design and production preparations are underway.';

  @override
  String get productionDescription =>
      'Your product is being prepared in production.';

  @override
  String get handedToCarrier => 'Handed to Carrier';

  @override
  String get shippedDescription =>
      'Your order was prepared for shipment and handed to the carrier.';

  @override
  String get deliveredDescription =>
      'Your order has arrived at the delivery address.';

  @override
  String get orderCancelledDescription =>
      'This order has been cancelled. Contact support for more information.';

  @override
  String get actingUser => 'Acting User';

  @override
  String get internalOrderId => 'Order ID';

  @override
  String get internalSessionId => 'Session ID';

  @override
  String get internalPatientId => 'Customer ID';

  @override
  String get internalClinicId => 'Clinic ID';

  @override
  String get internalExpertId => 'Expert ID';

  @override
  String get internalAssignedUserId => 'Assigned OptiYou User ID';

  @override
  String get profileMenuTooltip => 'Profile menu';

  @override
  String get storeIntro =>
      'Explore personalized products and see information linked to your latest assessment.';

  @override
  String get latestMeasurement => 'Latest Assessment';

  @override
  String get sessionLabel => 'Session';

  @override
  String get dateLabel => 'Date';

  @override
  String get locationLabel => 'Location';

  @override
  String get linkedMeasurementMessage =>
      'Product suitability is determined using your latest assessment data together with specialist guidance.';

  @override
  String get noLinkedMeasurementTitle => 'No linked assessment found';

  @override
  String get noLinkedMeasurementDescription =>
      'You can explore the products, but an assessment must first be linked to your account for personalized production.';

  @override
  String get mainProducts => 'Personalized Products';

  @override
  String get mainProductsSubtitle =>
      'Core products manufactured according to measurements and specialist assessment.';

  @override
  String get accessoryProducts => 'Complementary Products';

  @override
  String get accessoryProductsSubtitle =>
      'Additional options for daily use, comfort, and care.';

  @override
  String get productAbout => 'About the Product';

  @override
  String get whoSuitable => 'Who is it for?';

  @override
  String get whyRecommended => 'Suitability Note';

  @override
  String get purchase => 'Purchase';

  @override
  String get storeRecommendationDisclaimer =>
      'This information is general guidance. The final product selection is confirmed using your assessment results and specialist evaluation.';

  @override
  String get paymentInvalidUrl => 'An invalid payment link was received.';

  @override
  String get paymentPageOpenError => 'The payment page could not be opened.';

  @override
  String paymentStartError(String error) {
    return 'Payment could not be started: $error';
  }

  @override
  String get paymentResultTitle => 'Payment Result';

  @override
  String get paymentCheckingTitle => 'Verifying payment';

  @override
  String get paymentCheckingDescription =>
      'Waiting for the secure result from the payment provider. This screen will update automatically after you complete the payment page.';

  @override
  String get paymentSuccessTitle => 'Payment Successful';

  @override
  String get paymentSuccessDescription =>
      'Your payment was verified and your order was created.';

  @override
  String get paymentFailedTitle => 'Payment Could Not Be Completed';

  @override
  String get paymentFailedDescription =>
      'The payment failed or was cancelled. Contact support if you believe your card was charged.';

  @override
  String paymentStatusLoadError(String error) {
    return 'The payment status could not be verified: $error';
  }

  @override
  String orderNumberValue(String orderNo) {
    return 'Order number: $orderNo';
  }

  @override
  String paidAmountValue(String amount) {
    return 'Amount paid: $amount';
  }

  @override
  String get goToMyOrders => 'Go to My Orders';

  @override
  String ordersNavigationError(String error) {
    return 'The orders page could not be opened: $error';
  }

  @override
  String addressLoadError(String error) {
    return 'Addresses could not be loaded: $error';
  }

  @override
  String addressSaveError(String error) {
    return 'The address could not be saved: $error';
  }

  @override
  String get deliveryAddressDescription =>
      'Select your delivery address or enter a new one before continuing to payment.';

  @override
  String get addNewAddress => 'Add New Address';

  @override
  String get backToList => 'Back to List';

  @override
  String get continueToPayment => 'Continue to Payment';

  @override
  String get selectDeliveryAddress => 'Please select a delivery address.';

  @override
  String get noSavedAddress =>
      'No saved address was found. Add a new address to continue.';

  @override
  String get addressTitle => 'Address Title';

  @override
  String get city => 'City';

  @override
  String get district => 'District';

  @override
  String get addressLine => 'Full Address';

  @override
  String requiredField(String field) {
    return '$field is required.';
  }

  @override
  String get customInsoleFullDescription =>
      'A personalized insole is prepared from your latest measurements with support geometry tailored to your foot. It is designed to support comfort and load distribution in daily use.';

  @override
  String get customInsoleUsage =>
      'For people who stand for long periods, want greater daily comfort, or have a personal support need identified by a specialist.';

  @override
  String get sportsInsoleTitle => 'Sports Insole';

  @override
  String get sportsInsoleShort =>
      'Dynamic support for active lifestyles and sports use.';

  @override
  String get sportsInsoleFull =>
      'The sports insole is personalized to support the foot during walking, training, and other active use.';

  @override
  String get sportsInsoleUsage =>
      'For people who exercise regularly or have a high level of daily physical activity.';

  @override
  String get heelPadTitle => 'Heel Pad';

  @override
  String get heelPadShort =>
      'A complementary product that provides extra cushioning in the heel area.';

  @override
  String get heelPadFull =>
      'The heel pad is used to soften contact in the heel area and support everyday comfort.';

  @override
  String get heelPadUsage =>
      'For users who need additional cushioning in the heel area.';

  @override
  String get metPadTitle => 'Metatarsal Support Pad';

  @override
  String get metPadShort =>
      'A complementary product that provides additional forefoot support.';

  @override
  String get metPadFull =>
      'The metatarsal support pad is used to support forefoot contact and comfort.';

  @override
  String get metPadUsage =>
      'For users whose need for additional forefoot support has been identified by a specialist.';

  @override
  String get cleaningSprayTitle => 'Cleaning Spray';

  @override
  String get cleaningSprayShort =>
      'A practical care solution for insoles and complementary products.';

  @override
  String get cleaningSprayFull =>
      'The cleaning spray helps with regular product care and hygienic use.';

  @override
  String get cleaningSprayUsage =>
      'For users who want to care for their personalized products regularly.';

  @override
  String get carryCaseTitle => 'Carrying Case';

  @override
  String get carryCaseShort =>
      'A compact case for protecting and carrying insoles.';

  @override
  String get carryCaseFull =>
      'The carrying case helps protect insoles inside a bag and keeps them organized in transit.';

  @override
  String get carryCaseUsage => 'For users who carry their insoles with them.';

  @override
  String get supportCenter => 'Support Center';

  @override
  String get customerSupportIntro =>
      'Get help with your orders, products, and product use.';

  @override
  String get expertSupportIntro =>
      'Get help with measurement workflows, customer records, and order management.';

  @override
  String get teamSupportIntro =>
      'Use the support options for operations, user flows, and system management.';

  @override
  String get genericSupportIntro =>
      'If you need help, use one of the contact or issue-reporting options below.';

  @override
  String get quickSupport => 'Quick Support';

  @override
  String get quickSupportSubtitle =>
      'Contact the support team by phone or email.';

  @override
  String get callSupport => 'Call Support';

  @override
  String get callSupportDescription =>
      'You can reach the support team using one of the numbers below.';

  @override
  String get tapToCall => 'Select to call';

  @override
  String get actionCouldNotOpen =>
      'This action could not be opened on the device.';

  @override
  String get reportIssue => 'Report an Issue';

  @override
  String get sendIssue => 'Prepare Report';

  @override
  String get clinicLabel => 'Clinic';

  @override
  String get messageLabel => 'Message';

  @override
  String get issueReportSubtitle =>
      'Describe the problem in detail. The message will be prepared in your email application.';

  @override
  String get issueType => 'Issue Type';

  @override
  String get technicalIssue => 'Technical Issue';

  @override
  String get measurementIssue => 'Measurement / Analysis Issue';

  @override
  String get orderIssue => 'Order Process';

  @override
  String get accountIssue => 'Account / User Issue';

  @override
  String get otherIssue => 'Other';

  @override
  String get priority => 'Priority';

  @override
  String get lowPriority => 'Low';

  @override
  String get highPriority => 'High';

  @override
  String get urgentPriority => 'Urgent';

  @override
  String get subjectTitle => 'Subject';

  @override
  String get subjectTitleHint =>
      'For example, assessment results will not open';

  @override
  String get issueDescription => 'Issue Description';

  @override
  String get issueDescriptionHint =>
      'Describe the screen where the problem occurred and include any error message.';

  @override
  String get subjectRequired => 'A subject is required.';

  @override
  String get subjectTooShort =>
      'Please make the subject a little more descriptive.';

  @override
  String get descriptionRequired => 'An issue description is required.';

  @override
  String get descriptionTooShort =>
      'Please describe the issue in a little more detail.';

  @override
  String supportFormEmailNotice(String email) {
    return 'When you send the form, your email application will open with a message prepared for $email.';
  }

  @override
  String get emailAppOpened =>
      'The issue report has been prepared in your email application.';

  @override
  String get supportClosingNote =>
      'Your support request will be reviewed as soon as possible.';

  @override
  String get frequentlyAskedQuestions => 'Frequently Asked Questions';

  @override
  String get faqSubtitle => 'Review common topics and guidance here.';

  @override
  String get faqResultsQuestion => 'Where can I view my assessment results?';

  @override
  String get faqResultsAnswer =>
      'After signing in, open Assessment Results to view the measurement results linked to your account.';

  @override
  String get faqOrderQuestion => 'How can I track my order?';

  @override
  String get faqOrderAnswer =>
      'Open My Orders to track design, production, shipment, and delivery.';

  @override
  String get faqUsageQuestion =>
      'What should I consider when using my product?';

  @override
  String get faqUsageAnswer =>
      'Use the product gradually at first. If you experience pain or significant discomfort, contact your specialist or the support team.';

  @override
  String get faqContactQuestion => 'How can I contact the support team?';

  @override
  String get faqContactAnswer =>
      'Use the phone or email options on this page to contact the OptiYou support team.';

  @override
  String get faqExpertPatientQuestion =>
      'How do I create a new customer record?';

  @override
  String get faqExpertPatientAnswer =>
      'Create a record from Customers in the expert panel and send the approval link to the customer.';

  @override
  String get faqExpertResultsQuestion =>
      'When can measurement results be viewed?';

  @override
  String get faqExpertResultsAnswer =>
      'Results can be viewed after the required clinical information, 3D scan, and measurement steps are complete.';

  @override
  String get faqExpertPhotoQuestion =>
      'How should a reference insole photo be taken?';

  @override
  String get faqExpertPhotoAnswer =>
      'Take a clear top-down photo with the scale reference visible.';

  @override
  String get faqExpertApprovalQuestion =>
      'Can a measurement be approved with missing steps?';

  @override
  String get faqExpertApprovalAnswer =>
      'All required steps must be completed before approval; the system blocks approval while a required step is missing.';

  @override
  String get faqTeamMissingQuestion =>
      'Where can missing operation information be checked?';

  @override
  String get faqTeamMissingAnswer =>
      'Review the clinic, user, measurement, and production steps in the operation and order detail screens.';

  @override
  String get faqTeamReportQuestion =>
      'How should clinic- or specialist-related issues be reported?';

  @override
  String get faqTeamReportAnswer =>
      'Include the relevant role, screen, workflow step, and error details in the issue report form.';

  @override
  String get faqTeamQrQuestion =>
      'What should I do if a QR or results-access link does not work?';

  @override
  String get faqTeamQrAnswer =>
      'Confirm that the session is approved and the invitation link is valid; report the issue if it continues.';

  @override
  String get faqTeamSystemQuestion =>
      'What information is needed for a system issue report?';

  @override
  String get faqTeamSystemAnswer =>
      'Include the screen, user role, workflow step, error message, and a screenshot when possible.';
}
