import 'package:cloud_firestore/cloud_firestore.dart';

import 'route_assignment.dart';

class PickupRequest {
  const PickupRequest({
    required this.id,
    required this.clientEmail,
    required this.status,
    required this.createdAt,
    this.collectedAt,
    required this.clientRoute,
    required this.assignedOperatorCode,
    this.clientName = '',
    this.clientAddress = '',
    this.clientPhone = '',
    this.containerType = '',
    this.notes = '',
    this.drumCount = 1,
    this.drumCapacityLiters = 25,
    this.filterCount = 0,
    this.needsSoap = false,
  });

  final String id;
  final String clientEmail;
  final String status;
  final DateTime? createdAt;
  final DateTime? collectedAt;
  final String clientRoute;
  final int assignedOperatorCode;
  final String clientName;
  final String clientAddress;
  final String clientPhone;
  final String containerType;
  final String notes;
  final int drumCount;
  final int drumCapacityLiters;
  final int filterCount;
  final bool needsSoap;

  factory PickupRequest.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    final clientEmail =
        data['clientEmail'] as String? ?? data['clientCif'] as String? ?? '';
    final clientRoute =
        data['clientRoute'] as String? ??
        data['ruta'] as String? ??
        RouteAssignment.routeFromClientEmail(clientEmail);
    final assignedOperatorCode =
        data['assignedOperatorCode'] as int? ??
        RouteAssignment.operatorCodeForRoute(clientRoute);

    return PickupRequest(
      id: snapshot.id,
      clientEmail: clientEmail,
      status: data['status'] as String? ?? 'pendiente',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      collectedAt: (data['collectedAt'] as Timestamp?)?.toDate(),
      clientRoute: clientRoute,
      assignedOperatorCode: assignedOperatorCode,
      clientName:
          data['clientName'] as String? ??
          RouteAssignment.clientNameFromEmail(clientEmail),
      clientAddress:
          data['clientAddress'] as String? ??
          RouteAssignment.clientAddressFromEmail(clientEmail),
      clientPhone:
          data['clientPhone'] as String? ??
          RouteAssignment.clientPhoneFromEmail(clientEmail),
      containerType: RouteAssignment.normalizeContainerType(
        data['containerType'] as String? ??
            RouteAssignment.containerTypeFromEmail(clientEmail),
      ),
      notes: data['notes'] as String? ?? '',
      drumCount: data['drumCount'] as int? ?? 1,
      drumCapacityLiters: data['drumCapacityLiters'] as int? ?? 25,
      filterCount: data['filterCount'] as int? ?? 0,
      needsSoap: data['needsSoap'] as bool? ?? false,
    );
  }
}
