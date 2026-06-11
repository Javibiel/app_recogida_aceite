                                                                                                                                                                                                                              import 'package:flutter_test/flutter_test.dart';
import 'package:app_recogida_aceite/models/route_assignment.dart';

void main() {
  group('RouteAssignment', () {
    test('asigna la ruta correcta segun el email del cliente', () {
      expect(
        RouteAssignment.routeFromClientEmail('cliente.norte1@serrma.com'),
        RouteAssignment.northRoute,
      );
      expect(
        RouteAssignment.routeFromClientEmail('cliente.sur3@serrma.com'),
        RouteAssignment.southRoute,
      );
      expect(RouteAssignment.routeFromClientEmail('otro@serrma.com'), isEmpty);
    });

    test('asigna el codigo de operario correcto segun la ruta', () {
      expect(
        RouteAssignment.operatorCodeForRoute(RouteAssignment.northRoute),
        1,
      );
      expect(
        RouteAssignment.operatorCodeForRoute(RouteAssignment.southRoute),
        2,
      );
      expect(
        RouteAssignment.operatorCodeForRoute(RouteAssignment.westRoute),
        3,
      );
      expect(
        RouteAssignment.operatorCodeForRoute(RouteAssignment.eastRoute),
        4,
      );
      expect(
        RouteAssignment.operatorCodeForRoute(RouteAssignment.centerRoute),
        5,
      );
      expect(RouteAssignment.operatorCodeForRoute('ruta inexistente'), 0);
    });

    test('mantiene los valores por defecto de la solicitud de recogida', () {
      expect(RouteAssignment.defaultContainerType, 'Bidon 25 L');
      expect(RouteAssignment.drumCount, 1);
      expect(RouteAssignment.drumCapacityLiters, 25);
      expect(RouteAssignment.filterCount, 0);
      expect(RouteAssignment.needsSoap, isFalse);
      expect(
        RouteAssignment.normalizeContainerType('Bidon 50 L'),
        'Bidon 50 L',
      );
      expect(
        RouteAssignment.normalizeContainerType('contenedor desconocido'),
        RouteAssignment.defaultContainerType,
      );
    });
  });
}
