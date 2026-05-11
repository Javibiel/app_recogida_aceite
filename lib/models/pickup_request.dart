import 'package:cloud_firestore/cloud_firestore.dart';

import 'route_assignment.dart';

class PickupRequest {
  const PickupRequest({
    required this.id,
    required this.clientEmail,
    required this.status,
    required this.createdAt,
    required this.clientRoute,
    required this.assignedOperatorCode,
    this.clientName = '',
    this.clientAddress = '',
    this.clientPhone = '',
    this.containerType = '',
    this.notes = '',
  });

  final String id;
  final String clientEmail;
  final String status;
  final DateTime? createdAt;
  final String clientRoute;
  final int assignedOperatorCode;
  final String clientName;
  final String clientAddress;
  final String clientPhone;
  final String containerType;
  final String notes;

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
      containerType:
          data['containerType'] as String? ??
          RouteAssignment.containerTypeFromEmail(clientEmail),
      notes: data['notes'] as String? ?? '',
    );
  }
}
