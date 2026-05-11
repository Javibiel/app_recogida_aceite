import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/client_profile.dart';
import '../models/pickup_request.dart';
import '../models/route_assignment.dart';

class FirestoreDatabase {
  FirestoreDatabase({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _pickupRequests =>
      _firestore.collection('recogidas');

  CollectionReference<Map<String, dynamic>> get _clients =>
      _firestore.collection('clientes');

  CollectionReference<Map<String, dynamic>> get _operators =>
      _firestore.collection('operarios');

  Future<int> seedInitialData() async {
    final clientsCreated = await seedInitialClients();
    final operatorsCreated = await seedInitialOperators();

    return clientsCreated + operatorsCreated;
  }

  Future<int> seedInitialClients() async {
    final clients = _buildInitialClients();
    final batch = _firestore.batch();
    var pendingWrites = 0;

    for (final client in clients.entries) {
      final clientRef = _clients.doc(client.key);
      final snapshot = await clientRef.get();
      final clientData = {
        ...client.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists) {
        clientData['createdAt'] = FieldValue.serverTimestamp();
      }

      batch.set(clientRef, clientData, SetOptions(merge: true));
      pendingWrites++;
    }

    if (pendingWrites == 0) {
      return 0;
    }

    await batch.commit();
    return pendingWrites;
  }

  Future<int> seedInitialOperators() async {
    final operators = _buildInitialOperators();
    final batch = _firestore.batch();
    var pendingWrites = 0;

    for (final operator in operators.entries) {
      final operatorRef = _operators.doc(operator.key);
      final snapshot = await operatorRef.get();
      final operatorData = {
        ...operator.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists) {
        operatorData['createdAt'] = FieldValue.serverTimestamp();
      }

      batch.set(operatorRef, operatorData, SetOptions(merge: true));
      pendingWrites++;
    }

    if (pendingWrites == 0) {
      return 0;
    }

    await batch.commit();
    return pendingWrites;
  }

  Stream<List<ClientProfile>> watchClients({int? operatorCode}) {
    return _clients.snapshots().map((snapshot) {
      final clients = snapshot.docs
          .map(ClientProfile.fromSnapshot)
          .where((client) {
            if (operatorCode == null || operatorCode == 6) {
              return true;
            }

            return RouteAssignment.operatorCodeForRoute(client.route) ==
                operatorCode;
          })
          .toList(growable: false);

      return [...clients]..sort((a, b) {
        final routeComparison = a.route.compareTo(b.route);
        if (routeComparison != 0) return routeComparison;

        return a.name.compareTo(b.name);
      });
    });
  }

  Future<void> createClient({
    required String cif,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String route,
    required String contactPerson,
    required String businessType,
    required String collectionSchedule,
    required String containerType,
    required int estimatedLiters,
    required bool active,
    String notes = '',
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existingClient = await _findClientByEmailOrNull(normalizedEmail);

    if (existingClient != null) {
      throw DuplicateClientEmailException(normalizedEmail);
    }

    await _clients.add({
      'cif': cif.trim(),
      'nombre': name.trim(),
      'email': normalizedEmail,
      'telefono': phone.trim(),
      'direccion': address.trim(),
      'ruta': route,
      'operarioAsignado': RouteAssignment.operatorCodeForRoute(route),
      'personaContacto': contactPerson.trim(),
      'tipoNegocio': businessType.trim(),
      'horarioRecogida': collectionSchedule.trim(),
      'tipoContenedor': containerType.trim(),
      'litrosEstimados': estimatedLiters,
      'observaciones': notes.trim(),
      'activo': active,
      'password': '1234',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<ClientLoginResult> validateClientLogin({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final snapshot = await _clients
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return ClientLoginResult.emailNotFound;
    }

    final data = snapshot.docs.first.data();
    final storedPassword = data['password'] as String? ?? '';
    final active = data['activo'] as bool? ?? true;

    if (!active) {
      return ClientLoginResult.inactive;
    }

    if (storedPassword != password) {
      return ClientLoginResult.wrongPassword;
    }

    return ClientLoginResult.success;
  }

  Future<void> createPickupRequest({
    required String clientEmail,
    String notes = '',
  }) async {
    final normalizedEmail = clientEmail.trim().toLowerCase();
    final emailRoute = RouteAssignment.routeFromClientEmail(normalizedEmail);
    final client = await _findClientByEmailOrNull(normalizedEmail);
    final clientRoute = emailRoute.isNotEmpty
        ? emailRoute
        : client?.route ?? '';
    final assignedOperatorCode = RouteAssignment.operatorCodeForRoute(
      clientRoute,
    );

    await _pickupRequests.add({
      'clientEmail': normalizedEmail,
      'clientName': client?.name ?? '',
      'clientAddress': client?.address ?? '',
      'clientPhone': client?.phone ?? '',
      'clientRoute': clientRoute,
      'containerType': client?.containerType ?? '',
      'assignedOperatorCode': assignedOperatorCode,
      'notes': notes,
      'status': 'pendiente',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePickupRequest(String requestId) {
    return _pickupRequests.doc(requestId).delete();
  }

  Stream<List<PickupRequest>> watchPickupRequests({int? operatorCode}) {
    return _pickupRequests.snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map(PickupRequest.fromSnapshot)
          .where((request) {
            if (operatorCode == null || operatorCode == 6) {
              return true;
            }

            if (request.assignedOperatorCode != 0) {
              return request.assignedOperatorCode == operatorCode;
            }

            return RouteAssignment.operatorCodeForRoute(request.clientRoute) ==
                operatorCode;
          })
          .toList(growable: false);

      return [...requests]..sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });
    });
  }

  Future<ClientProfile?> _findClientByEmailOrNull(String clientEmail) async {
    final normalizedEmail = clientEmail.trim().toLowerCase();
    try {
      final snapshot = await _clients
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return ClientProfile.fromSnapshot(snapshot.docs.first);
    } on FirebaseException {
      return null;
    }
  }

  Map<String, Map<String, dynamic>> _buildInitialClients() {
    const routes = [
      RouteAssignment.northRoute,
      RouteAssignment.southRoute,
      RouteAssignment.eastRoute,
      RouteAssignment.westRoute,
      RouteAssignment.centerRoute,
    ];

    final clients = <String, Map<String, dynamic>>{};

    for (final route in routes) {
      final routeKey = route.replaceFirst('ruta ', '');
      final routeLabel = _routeLabel(route);

      for (var index = 1; index <= 5; index++) {
        final paddedIndex = index.toString().padLeft(2, '0');
        final clientId = 'cliente_${routeKey}_$paddedIndex';

        clients[clientId] = {
          'cif': 'B${routes.indexOf(route) + 1}0000$paddedIndex',
          'nombre': 'Cliente $routeLabel $index',
          'email': 'cliente.$routeKey$index@serrma.com',
          'telefono': '600000${routes.indexOf(route) + 1}$paddedIndex',
          'direccion': 'Calle $routeLabel $index',
          'ruta': route,
          'operarioAsignado': RouteAssignment.operatorCodeForRoute(route),
          'personaContacto': 'Responsable $routeLabel $index',
          'tipoNegocio': _businessType(index),
          'horarioRecogida': _collectionSchedule(index),
          'tipoContenedor': _containerType(index),
          'litrosEstimados': 40 + (index * 15),
          'observaciones': 'Ficha pendiente de validacion en proxima visita.',
          'activo': true,
          'password': '1234',
        };
      }
    }

    return clients;
  }

  Map<String, Map<String, dynamic>> _buildInitialOperators() {
    return {
      'operario_1': {
        'codigo': 1,
        'nombre': 'Operario 1',
        'rol': 'operario',
        'ruta': RouteAssignment.northRoute,
        'activo': true,
      },
      'operario_2': {
        'codigo': 2,
        'nombre': 'Operario 2',
        'rol': 'operario',
        'ruta': RouteAssignment.southRoute,
        'activo': true,
      },
      'operario_3': {
        'codigo': 3,
        'nombre': 'Operario 3',
        'rol': 'operario',
        'ruta': RouteAssignment.westRoute,
        'activo': true,
      },
      'operario_4': {
        'codigo': 4,
        'nombre': 'Operario 4',
        'rol': 'operario',
        'ruta': RouteAssignment.eastRoute,
        'activo': true,
      },
      'operario_5': {
        'codigo': 5,
        'nombre': 'Operario 5',
        'rol': 'operario',
        'ruta': RouteAssignment.centerRoute,
        'activo': true,
      },
      'encargado': {
        'codigo': 6,
        'nombre': 'Encargado',
        'rol': 'encargado',
        'ruta': null,
        'activo': true,
      },
    };
  }

  String _routeLabel(String route) {
    switch (route) {
      case 'ruta norte':
        return 'Norte';
      case 'ruta sur':
        return 'Sur';
      case 'ruta este':
        return 'Este';
      case 'ruta oeste':
        return 'Oeste';
      case 'ruta centro':
        return 'Centro';
      default:
        return route;
    }
  }

  String _businessType(int index) {
    switch (index) {
      case 1:
        return 'Bar';
      case 2:
        return 'Restaurante';
      case 3:
        return 'Cafeteria';
      case 4:
        return 'Hotel';
      default:
        return 'Comedor colectivo';
    }
  }

  String _collectionSchedule(int index) {
    switch (index) {
      case 1:
        return 'Lunes de 9:00 a 11:00';
      case 2:
        return 'Martes de 11:00 a 13:00';
      case 3:
        return 'Miercoles de 8:00 a 10:00';
      case 4:
        return 'Jueves de 12:00 a 14:00';
      default:
        return 'Viernes de 9:00 a 12:00';
    }
  }

  String _containerType(int index) {
    return index.isEven ? 'Bidon 60 L' : 'Contenedor 120 L';
  }
}

enum ClientLoginResult { success, emailNotFound, wrongPassword, inactive }

class DuplicateClientEmailException implements Exception {
  const DuplicateClientEmailException(this.email);

  final String email;

  @override
  String toString() => 'Ya existe un cliente con el email $email';
}
