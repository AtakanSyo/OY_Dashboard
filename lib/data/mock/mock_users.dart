import '../../models/app_user.dart';

class MockUsers {
  static AppUser buildTestUser({
    required String email,
    required String roleCode,
  }) {
    switch (roleCode) {
      case RoleCodes.expert:
        return AppUser(
          userId: 1,
          roleId: 1,
          clinicId: 101,
          firstName: 'Atakan',
          lastName: 'Alkan',
          email: email,
          username: 'atakan.expert',
          phone: '+90 555 000 00 01',
          title: 'Uzm. Dr.',
          commissionProfileName: 'expert_default',
          roleCode: RoleCodes.expert,
          roleName: 'Uzman',
          clinicCode: 'CLN-IZM-001',
          clinicName: 'İzmir Ortopedi Merkezi',
          clinicType: 'ortho_center',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

      case RoleCodes.optiYouTeam:
        return AppUser(
          userId: 2,
          roleId: 3,
          clinicId: null,
          firstName: 'OptiYou',
          lastName: 'Admin',
          email: email,
          username: 'optiyou.team',
          phone: '+90 555 000 00 02',
          title: 'Admin',
          commissionProfileName: 'team_default',
          roleCode: RoleCodes.optiYouTeam,
          roleName: 'OptiYou Ekibi',
          clinicCode: null,
          clinicName: null,
          clinicType: null,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

      case RoleCodes.corporate:
        return AppUser(
          userId: 4,
          roleId: 4,
          clinicId: null,
          firstName: 'Kurumsal',
          lastName: 'Kullanıcı',
          email: email,
          username: 'corporate.user',
          phone: '+90 555 000 00 04',
          title: 'Kurumsal Yetkili',
          commissionProfileName: 'corporate_default',
          roleCode: RoleCodes.corporate,
          roleName: 'Kurumsal',
          clinicCode: null,
          clinicName: 'Kurumsal Firma',
          clinicType: 'corporate',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

      case RoleCodes.customer:
      default:
        return AppUser(
          userId: 3,
          roleId: 2,
          clinicId: null,
          firstName: 'Test',
          lastName: 'Kullanıcı',
          email: email,
          username: 'test.customer',
          phone: '+90 555 000 00 03',
          title: null,
          commissionProfileName: null,
          roleCode: RoleCodes.customer,
          roleName: 'Müşteri',
          clinicCode: null,
          clinicName: null,
          clinicType: null,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    }
  }
}