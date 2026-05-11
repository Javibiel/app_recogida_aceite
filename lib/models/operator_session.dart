import 'route_assignment.dart';

class OperatorSession {
  const OperatorSession({
    required this.code,
    required this.name,
    this.route,
    this.isManager = false,
  });

  final int code;
  final String name;
  final String? route;
  final bool isManager;

  static OperatorSession fromCode(int code) {
    switch (code) {
      case 1:
        return const OperatorSession(
          code: 1,
          name: 'Operario 1',
          route: RouteAssignment.northRoute,
        );
      case 2:
        return const OperatorSession(
          code: 2,
          name: 'Operario 2',
          route: RouteAssignment.southRoute,
        );
      case 3:
        return const OperatorSession(
          code: 3,
          name: 'Operario 3',
          route: RouteAssignment.westRoute,
        );
      case 4:
        return const OperatorSession(
          code: 4,
          name: 'Operario 4',
          route: RouteAssignment.eastRoute,
        );
      case 5:
        return const OperatorSession(
          code: 5,
          name: 'Operario 5',
          route: RouteAssignment.centerRoute,
        );
      case 6:
        return const OperatorSession(
          code: 6,
          name: 'Encargado',
          isManager: true,
        );
      default:
        throw ArgumentError.value(code, 'code', 'Codigo de acceso no valido');
    }
  }
}
