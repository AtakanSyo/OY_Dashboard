import 'package:oy_site/models/customer_address_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class CustomerAddressRepository {
  Future<List<CustomerAddressModel>> getAddressesForCurrentCustomer();

  Future<CustomerAddressModel> saveAddress(CustomerAddressModel address);
}

class SupabaseCustomerAddressRepository implements CustomerAddressRepository {
  SupabaseCustomerAddressRepository({SupabaseClient? client})
    : _providedClient = client;

  final SupabaseClient? _providedClient;

  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  @override
  Future<List<CustomerAddressModel>> getAddressesForCurrentCustomer() async {
    final owner = await _loadOwner();
    final filter = _ownerFilter(owner);
    if (filter == null) return const [];

    final response = await _client
        .from('customer_addresses')
        .select()
        .or(filter)
        .order('is_default', ascending: false)
        .order('updated_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => CustomerAddressModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<CustomerAddressModel> saveAddress(CustomerAddressModel address) async {
    final owner = await _loadOwner();
    if (owner.profileId == null && owner.patientId == null) {
      throw Exception('Adresin bağlanacağı müşteri kaydı bulunamadı.');
    }

    final existingAddresses = await getAddressesForCurrentCustomer();
    final shouldBeDefault = address.isDefault || existingAddresses.isEmpty;
    final ownedAddress = CustomerAddressModel(
      addressId: address.addressId,
      userId: owner.profileId,
      patientId: owner.patientId,
      title: address.title,
      fullName: address.fullName,
      phone: address.phone,
      city: address.city,
      district: address.district,
      addressLine: address.addressLine,
      isDefault: shouldBeDefault,
      createdAt: address.createdAt,
      updatedAt: address.updatedAt,
    );

    if (shouldBeDefault) {
      final filter = _ownerFilter(owner);
      if (filter != null) {
        await _client
            .from('customer_addresses')
            .update({'is_default': false})
            .or(filter);
      }
    }

    final dynamic response;
    if (ownedAddress.addressId == null) {
      response = await _client
          .from('customer_addresses')
          .insert(ownedAddress.toInsertMap())
          .select()
          .single();
    } else {
      response = await _client
          .from('customer_addresses')
          .update(ownedAddress.toUpdateMap())
          .eq('id', ownedAddress.addressId!)
          .select()
          .single();
    }

    return CustomerAddressModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<_CustomerAddressOwner> _loadOwner() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw Exception('Oturum açmış kullanıcı bulunamadı.');
    }

    final results = await Future.wait<dynamic>([
      _client
          .from('user_profiles')
          .select('id')
          .eq('auth_id', authUser.id)
          .maybeSingle(),
      _client
          .from('patients')
          .select('id')
          .eq('auth_user_id', authUser.id)
          .maybeSingle(),
    ]);

    return _CustomerAddressOwner(
      profileId: _toInt((results[0] as Map?)?['id']),
      patientId: _toInt((results[1] as Map?)?['id']),
    );
  }

  String? _ownerFilter(_CustomerAddressOwner owner) {
    final parts = <String>[
      if (owner.profileId != null) 'user_id.eq.${owner.profileId}',
      if (owner.patientId != null) 'patient_id.eq.${owner.patientId}',
    ];
    return parts.isEmpty ? null : parts.join(',');
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class _CustomerAddressOwner {
  const _CustomerAddressOwner({this.profileId, this.patientId});

  final int? profileId;
  final int? patientId;
}
