import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../../models/client_profile.dart';
import '../../../models/operator_session.dart';
import '../../../models/pickup_request.dart';
import '../../../models/route_assignment.dart';
import '../../../services/firestore_database.dart';

class HomeOperatorScreen extends StatelessWidget {
  const HomeOperatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final operatorCode =
        ModalRoute.of(context)?.settings.arguments as int? ?? 6;
    final session = OperatorSession.fromCode(operatorCode);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFC7E0B0),
          title: Text(
            session.isManager
                ? "Consola del encargado"
                : "${session.name} - ${session.route}",
          ),
          actions: [
            if (session.isManager)
              TextButton.icon(
                onPressed: () => _showCreateClientDialog(context),
                icon: const Icon(Icons.add_business),
                label: const Text("Nuevo cliente"),
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.assignment), text: "Recogidas"),
              Tab(icon: Icon(Icons.store), text: "Clientes"),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFC7E0B0),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TabBarView(
                  children: [
                    _PickupRequestsTab(session: session),
                    _ClientsTab(session: session),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                },
                child: const Text("Volver al inicio"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateClientDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => const _CreateClientDialog(),
    );
  }
}

class _PickupRequestsTab extends StatefulWidget {
  const _PickupRequestsTab({required this.session});

  final OperatorSession session;

  @override
  State<_PickupRequestsTab> createState() => _PickupRequestsTabState();
}

enum _PickupRequestFilter { all, pending, collected }

class _PickupRequestsTabState extends State<_PickupRequestsTab> {
  _PickupRequestFilter _selectedFilter = _PickupRequestFilter.all;
  final Set<String> _knownRequestIds = <String>{};
  bool _hasLoadedInitialRequests = false;

  Future<void> _confirmDeleteRequest(
    BuildContext context,
    PickupRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Eliminar solicitud"),
          content: Text(
            "Se eliminara la solicitud de ${request.clientName.isEmpty ? request.clientEmail : request.clientName}.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FirestoreDatabase().deletePickupRequest(request.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Solicitud eliminada")));
    } on FirebaseException catch (error) {
      if (!context.mounted) return;

      final message = error.code == 'permission-denied'
          ? "No se pudo eliminar: publica las reglas de Firestore"
          : "No se pudo eliminar: ${error.code}";

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No se pudo eliminar: $error")));
    }
  }

  Future<void> _markRequestAsCollected(
    BuildContext context,
    PickupRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmar recogida"),
          content: Text(
            "Confirmas que la recogida de ${request.clientName.isEmpty ? request.clientEmail : request.clientName} ha sido realizada?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirmar"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FirestoreDatabase().markPickupRequestAsCollected(request.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Recogida marcada")));
    } on FirebaseException catch (error) {
      if (!context.mounted) return;

      final message = error.code == 'permission-denied'
          ? "No se pudo actualizar: publica las reglas de Firestore"
          : "No se pudo actualizar: ${error.code}";

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No se pudo actualizar: $error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Solicitudes de recogida",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        Expanded(
          child: StreamBuilder<List<PickupRequest>>(
            stream: FirestoreDatabase().watchPickupRequests(
              operatorCode: widget.session.code,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "No se pudieron cargar las solicitudes:\n"
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final requests = snapshot.data!;
              _notifyNewPickupRequests(requests);

              if (requests.isEmpty) {
                return Center(
                  child: Text(
                    widget.session.isManager
                        ? "No hay solicitudes pendientes"
                        : "No hay solicitudes para ${widget.session.route}",
                  ),
                );
              }

              return _buildRequestsContent(context, requests);
            },
          ),
        ),
      ],
    );
  }

  void _notifyNewPickupRequests(List<PickupRequest> requests) {
    final currentIds = requests.map((request) => request.id).toSet();

    if (!_hasLoadedInitialRequests) {
      _knownRequestIds
        ..clear()
        ..addAll(currentIds);
      _hasLoadedInitialRequests = true;
      return;
    }

    final newPendingRequests = requests
        .where(
          (request) =>
              !_knownRequestIds.contains(request.id) && _isPending(request),
        )
        .toList(growable: false);

    _knownRequestIds
      ..clear()
      ..addAll(currentIds);

    if (newPendingRequests.isEmpty) {
      return;
    }

    final message = newPendingRequests.length == 1
        ? "Nueva recogida solicitada por ${_clientLabel(newPendingRequests.first)}"
        : "${newPendingRequests.length} nuevas recogidas solicitadas";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            action: SnackBarAction(
              label: "Ver",
              textColor: const Color(0xFFC7E0B0),
              onPressed: () {
                setState(() {
                  _selectedFilter = _PickupRequestFilter.pending;
                });
              },
            ),
          ),
        );
    });
  }

  Widget _buildRequestsContent(
    BuildContext context,
    List<PickupRequest> requests,
  ) {
    final pendingRequests = requests.where(_isPending).toList(growable: false);
    final collectedRequests = requests
        .where(_isCollected)
        .toList(growable: false);
    final visibleRequests = _filteredRequests(requests);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PickupSummary(
          pendingCount: pendingRequests.length,
          collectedCount: collectedRequests.length,
          totalCount: requests.length,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<_PickupRequestFilter>(
            segments: const [
              ButtonSegment(
                value: _PickupRequestFilter.all,
                icon: Icon(Icons.list),
                label: Text("Todas"),
              ),
              ButtonSegment(
                value: _PickupRequestFilter.pending,
                icon: Icon(Icons.schedule),
                label: Text("Pendientes"),
              ),
              ButtonSegment(
                value: _PickupRequestFilter.collected,
                icon: Icon(Icons.check_circle),
                label: Text("Recogidas"),
              ),
            ],
            selected: {_selectedFilter},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedFilter = selection.first;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: visibleRequests.isEmpty
              ? const Center(child: Text("No hay solicitudes con este filtro"))
              : _buildRequestList(context, visibleRequests),
        ),
      ],
    );
  }

  Widget _buildRequestList(BuildContext context, List<PickupRequest> requests) {
    if (_selectedFilter != _PickupRequestFilter.all) {
      return ListView.separated(
        itemCount: requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            _buildRequestCard(context, requests[index]),
      );
    }

    final pendingRequests = requests.where(_isPending).toList(growable: false);
    final collectedRequests = requests
        .where(_isCollected)
        .toList(growable: false);
    final otherRequests = requests
        .where((request) => !_isPending(request) && !_isCollected(request))
        .toList(growable: false);

    return ListView(
      children: [
        if (pendingRequests.isNotEmpty)
          _RequestSection(
            title: "Pendientes",
            children: [
              for (final request in pendingRequests)
                _buildRequestCard(context, request),
            ],
          ),
        if (collectedRequests.isNotEmpty)
          _RequestSection(
            title: "Recogidas",
            children: [
              for (final request in collectedRequests)
                _buildRequestCard(context, request),
            ],
          ),
        if (otherRequests.isNotEmpty)
          _RequestSection(
            title: "Otros estados",
            children: [
              for (final request in otherRequests)
                _buildRequestCard(context, request),
            ],
          ),
      ],
    );
  }

  Widget _buildRequestCard(BuildContext context, PickupRequest request) {
    final createdAt = request.createdAt;
    final isPending = _isPending(request);
    final cardColor = _requestCardColor(request.status);
    final statusLabel = _statusLabel(request.status);
    final collectedAt = request.collectedAt;

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.recycling),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.clientName.isEmpty
                            ? request.clientEmail
                            : request.clientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        createdAt == null
                            ? "${request.clientRoute} - fecha pendiente"
                            : "${request.clientRoute} - ${_formatDate(createdAt)}",
                      ),
                    ],
                  ),
                ),
                Text(
                  widget.session.isManager
                      ? "Op. ${request.assignedOperatorCode}"
                      : statusLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _RequestField(
              label: "Nombre",
              value: request.clientName.isEmpty
                  ? request.clientEmail
                  : request.clientName,
            ),
            _RequestField(label: "Direccion", value: request.clientAddress),
            _RequestField(label: "Telefono", value: request.clientPhone),
            _RequestField(label: "Contenedor", value: request.containerType),
            _RequestField(
              label: "Bidones",
              value: "${request.drumCount} x ${request.drumCapacityLiters} L",
            ),
            _RequestField(label: "Campanas", value: "${request.filterCount}"),
            _RequestField(
              label: "Jabon",
              value: request.needsSoap ? "Si" : "No",
            ),
            _RequestField(
              label: "Operario asignado",
              value: request.assignedOperatorCode == 0
                  ? "Sin asignar"
                  : "Operario ${request.assignedOperatorCode}",
            ),
            _RequestField(label: "Estado", value: statusLabel),
            if (collectedAt != null)
              _RequestField(
                label: "Fecha recogida",
                value: _formatDate(collectedAt),
              ),
            if (isPending || widget.session.isManager) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    if (isPending)
                      FilledButton.icon(
                        onPressed: () =>
                            _markRequestAsCollected(context, request),
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Marcar recogido"),
                      ),
                    if (widget.session.isManager)
                      FilledButton.icon(
                        onPressed: () =>
                            _confirmDeleteRequest(context, request),
                        icon: const Icon(Icons.delete),
                        label: const Text("Eliminar"),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<PickupRequest> _filteredRequests(List<PickupRequest> requests) {
    switch (_selectedFilter) {
      case _PickupRequestFilter.all:
        return requests;
      case _PickupRequestFilter.pending:
        return requests.where(_isPending).toList(growable: false);
      case _PickupRequestFilter.collected:
        return requests.where(_isCollected).toList(growable: false);
    }
  }

  bool _isPending(PickupRequest request) {
    return request.status.trim().toLowerCase() == 'pendiente';
  }

  bool _isCollected(PickupRequest request) {
    final normalizedStatus = request.status.trim().toLowerCase();

    return normalizedStatus == 'recogido' ||
        normalizedStatus == 'recogida' ||
        normalizedStatus == 'realizado';
  }

  Color? _requestCardColor(String status) {
    final normalizedStatus = status.trim().toLowerCase();

    if (normalizedStatus == 'pendiente') {
      return const Color(0xFFFF8A80);
    }

    if (normalizedStatus == 'recogido' ||
        normalizedStatus == 'recogida' ||
        normalizedStatus == 'realizado') {
      return const Color(0xFF81C784);
    }

    return null;
  }

  String _statusLabel(String status) {
    if (status.trim().toLowerCase() == 'pendiente') {
      return 'Pendiente';
    }

    return status;
  }

  String _clientLabel(PickupRequest request) {
    return request.clientName.isEmpty
        ? request.clientEmail
        : request.clientName;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return "$day/$month/${date.year}";
  }
}

class _PickupSummary extends StatelessWidget {
  const _PickupSummary({
    required this.pendingCount,
    required this.collectedCount,
    required this.totalCount,
  });

  final int pendingCount;
  final int collectedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: "Pendientes",
            value: "$pendingCount",
            color: const Color(0xFFFF8A80),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: "Recogidas",
            value: "$collectedCount",
            color: const Color(0xFF81C784),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: "Total",
            value: "$totalCount",
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF7DA85E)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _RequestSection extends StatelessWidget {
  const _RequestSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          for (final child in children) ...[child, const SizedBox(height: 8)],
        ],
      ),
    );
  }
}

class _RequestField extends StatelessWidget {
  const _RequestField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5E7F4F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? "-" : value)),
        ],
      ),
    );
  }
}

class _ClientsTab extends StatelessWidget {
  const _ClientsTab({required this.session});

  final OperatorSession session;

  Future<void> _showCreateClientDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => const _CreateClientDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsList = StreamBuilder<List<ClientProfile>>(
      stream: FirestoreDatabase().watchClients(operatorCode: session.code),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "No se pudieron cargar los clientes:\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final clients = snapshot.data!;

        if (clients.isEmpty) {
          return const Center(child: Text("No hay clientes registrados"));
        }

        return ListView.separated(
          itemCount: clients.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final client = clients[index];

            return Card(
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFD7E6C3),
                  foregroundColor: const Color(0xFF1F4D35),
                  child: Text(client.name.isEmpty ? "?" : client.name[0]),
                ),
                title: Text(client.name),
                subtitle: Text("${client.route} · ${client.businessType}"),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ClientField(label: "CIF", value: client.cif),
                  _ClientField(label: "Email", value: client.email),
                  _ClientField(label: "Telefono", value: client.phone),
                  _ClientField(label: "Direccion", value: client.address),
                  _ClientField(
                    label: "Persona de contacto",
                    value: client.contactPerson,
                  ),
                  _ClientField(
                    label: "Horario de recogida",
                    value: client.collectionSchedule,
                  ),
                  const _ClientField(
                    label: "Contenedor",
                    value: "Bidones 25L / Bidones 50L",
                  ),
                  _ClientField(
                    label: "Estado",
                    value: client.active ? "Activo" : "Inactivo",
                  ),
                  if (client.notes.isNotEmpty)
                    _ClientField(label: "Observaciones", value: client.notes),
                ],
              ),
            );
          },
        );
      },
    );

    if (!session.isManager) {
      return clientsList;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _showCreateClientDialog(context),
            icon: const Icon(Icons.add_business),
            label: const Text("Nuevo cliente"),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: clientsList),
      ],
    );
  }
}

class _CreateClientDialog extends StatefulWidget {
  const _CreateClientDialog();

  @override
  State<_CreateClientDialog> createState() => _CreateClientDialogState();
}

class _CreateClientDialogState extends State<_CreateClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cifController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _collectionScheduleController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedRoute = RouteAssignment.northRoute;
  String _selectedContainerType = RouteAssignment.defaultContainerType;
  bool _active = true;
  bool _isSaving = false;

  static const _routes = [
    RouteAssignment.northRoute,
    RouteAssignment.southRoute,
    RouteAssignment.westRoute,
    RouteAssignment.eastRoute,
    RouteAssignment.centerRoute,
  ];

  @override
  void dispose() {
    _cifController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    _businessTypeController.dispose();
    _collectionScheduleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirestoreDatabase().createClient(
        cif: _cifController.text,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        route: _selectedRoute,
        contactPerson: _contactPersonController.text,
        businessType: _businessTypeController.text,
        collectionSchedule: _collectionScheduleController.text,
        containerType: _selectedContainerType,
        active: _active,
        notes: _notesController.text,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cliente creado correctamente")),
      );
    } on DuplicateClientEmailException catch (error) {
      if (!mounted) return;
      _showError(error.toString());
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showError("No se pudo crear el cliente: ${error.code}");
    } catch (error) {
      if (!mounted) return;
      _showError("No se pudo crear el cliente: $error");
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Campo obligatorio";
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? "";
    final emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (email.isEmpty) {
      return "Campo obligatorio";
    }

    if (!emailFormat.hasMatch(email)) {
      return "Introduce un email valido";
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nuevo cliente"),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ClientTextField(
                  controller: _cifController,
                  label: "CIF",
                  validator: _requiredText,
                ),
                _ClientTextField(
                  controller: _nameController,
                  label: "Nombre",
                  validator: _requiredText,
                ),
                _ClientTextField(
                  controller: _emailController,
                  label: "Email",
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                _ClientTextField(
                  controller: _phoneController,
                  label: "Telefono",
                  keyboardType: TextInputType.phone,
                  validator: _requiredText,
                ),
                _ClientTextField(
                  controller: _addressController,
                  label: "Direccion",
                  validator: _requiredText,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRoute,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Ruta",
                  ),
                  items: [
                    for (final route in _routes)
                      DropdownMenuItem(value: route, child: Text(route)),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedRoute = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                _ClientTextField(
                  controller: _contactPersonController,
                  label: "Persona de contacto",
                  validator: _requiredText,
                ),
                _ClientTextField(
                  controller: _businessTypeController,
                  label: "Tipo de negocio",
                  validator: _requiredText,
                ),
                _ClientTextField(
                  controller: _collectionScheduleController,
                  label: "Horario de recogida",
                  validator: _requiredText,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedContainerType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Tamaño del bidon",
                  ),
                  items: [
                    for (final containerType
                        in RouteAssignment.availableContainerTypes)
                      DropdownMenuItem(
                        value: containerType,
                        child: Text(containerType),
                      ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedContainerType = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                _ClientTextField(
                  controller: _notesController,
                  label: "Observaciones",
                  maxLines: 3,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Cliente activo"),
                  value: _active,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _active = value;
                          });
                        },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveClient,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Guardar"),
        ),
      ],
    );
  }
}

class _ClientTextField extends StatelessWidget {
  const _ClientTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }
}

class _ClientField extends StatelessWidget {
  const _ClientField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5E7F4F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? "-" : value)),
        ],
      ),
    );
  }
}
