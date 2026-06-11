import 'package:cloud_firestore/cloud_firestore.dart';

import 'route_assignment.dart';

class ClientProfile {
  const ClientProfile({
    required this.id,
    required this.cif,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.route,
    required this.contactPerson,
    required this.businessType,
    required this.collectionSchedule,
    required this.containerType,
    required this.active,
    this.notes = '',
  });

  final String id;
  final String cif;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String route;
  final String contactPerson;
  final String businessType;
  final String collectionSchedule;
  final String containerType;
  final bool active;
  final String notes;

  factory ClientProfile.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return ClientProfile(
      id: snapshot.id,
      cif: data['cif'] as String? ?? '',
      name: data['nombre'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['telefono'] as String? ?? '',
      address: data['direccion'] as String? ?? '',
      route: data['ruta'] as String? ?? '',
      contactPerson: data['personaContacto'] as String? ?? '',
      businessType: data['tipoNegocio'] as String? ?? '',
      collectionSchedule: data['horarioRecogida'] as String? ?? '',
      containerType: RouteAssignment.normalizeContainerType(
        data['tipoContenedor'] as String? ?? '',
      ),
      active: data['activo'] as bool? ?? true,
      notes: data['observaciones'] as String? ?? '',
    );
  }
}
