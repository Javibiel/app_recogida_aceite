class RouteAssignment {
  const RouteAssignment._();

  static const String northRoute = 'ruta norte';
  static const String southRoute = 'ruta sur';
  static const String westRoute = 'ruta oeste';
  static const String eastRoute = 'ruta este';
  static const String centerRoute = 'ruta centro';
  static const String defaultContainerType = 'Bidon 25 L';
  static const int drumCount = 1;
  static const int drumCapacityLiters = 25;
  static const int filterCount = 0;
  static const bool needsSoap = false;
  static const List<String> availableContainerTypes = [
    defaultContainerType,
    'Bidon 50 L',
  ];

  static String routeFromClientEmail(String clientEmail) {
    final email = clientEmail.trim().toLowerCase();

    if (_emailsForRoute('norte').contains(email)) return northRoute;
    if (_emailsForRoute('sur').contains(email)) return southRoute;
    if (_emailsForRoute('oeste').contains(email)) return westRoute;
    if (_emailsForRoute('este').contains(email)) return eastRoute;
    if (_emailsForRoute('centro').contains(email)) return centerRoute;

    return '';
  }

  static String clientNameFromEmail(String clientEmail) {
    final route = routeFromClientEmail(clientEmail);
    final index = clientIndexFromEmail(clientEmail);

    if (route.isEmpty || index == null) {
      return '';
    }

    return 'Cliente ${routeLabel(route)} $index';
  }

  static String clientAddressFromEmail(String clientEmail) {
    final route = routeFromClientEmail(clientEmail);
    final index = clientIndexFromEmail(clientEmail);

    if (route.isEmpty || index == null) {
      return '';
    }

    return 'Calle ${routeLabel(route)} $index';
  }

  static String clientPhoneFromEmail(String clientEmail) {
    final route = routeFromClientEmail(clientEmail);
    final index = clientIndexFromEmail(clientEmail);

    if (route.isEmpty || index == null) {
      return '';
    }

    final routeNumber = switch (route) {
      northRoute => 1,
      southRoute => 2,
      eastRoute => 3,
      westRoute => 4,
      centerRoute => 5,
      _ => 0,
    };
    final paddedIndex = index.toString().padLeft(2, '0');

    return '600000$routeNumber$paddedIndex';
  }

  static String containerTypeFromEmail(String clientEmail) {
    final index = clientIndexFromEmail(clientEmail);

    if (index == null) {
      return '';
    }

    return index.isEven ? 'Bidon 50 L' : defaultContainerType;
  }

  static String normalizeContainerType(String containerType) {
    final normalized = containerType.trim().toLowerCase();

    if (normalized.contains('50')) {
      return 'Bidon 50 L';
    }

    if (normalized.contains('25')) {
      return defaultContainerType;
    }

    return defaultContainerType;
  }

  static int? clientIndexFromEmail(String clientEmail) {
    final email = clientEmail.trim().toLowerCase();
    final match = RegExp(
      r'^cliente\.(norte|sur|oeste|este|centro)([1-5])@serrma\.com$',
    ).firstMatch(email);

    if (match == null) {
      return null;
    }

    return int.parse(match.group(2)!);
  }

  static String routeLabel(String route) {
    switch (route) {
      case northRoute:
        return 'Norte';
      case southRoute:
        return 'Sur';
      case westRoute:
        return 'Oeste';
      case eastRoute:
        return 'Este';
      case centerRoute:
        return 'Centro';
      default:
        return route;
    }
  }

  static int operatorCodeForRoute(String route) {
    switch (route) {
      case northRoute:
        return 1;
      case southRoute:
        return 2;
      case westRoute:
        return 3;
      case eastRoute:
        return 4;
      case centerRoute:
        return 5;
      default:
        return 0;
    }
  }

  static Set<String> _emailsForRoute(String routeKey) {
    return {
      for (var index = 1; index <= 5; index++)
        'cliente.$routeKey$index@serrma.com',
    };
  }
}
