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
          backgroundColor: const Color(0xFFE8F1D8),
          title: Text(
            session.isManager
                ? "Consola del encargado"
                : "${session.name} - ${session.route}",
          ),
          actions: [
            if (session.isManager)
              IconButton(
                onPressed: () => _showCreateClientDialog(context),
                icon: const Icon(Icons.add_business),
                tooltip: "Nuevo cliente",
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.assignment), text: "Recogidas"),
              Tab(icon: Icon(Icons.store), text: "Clientes"),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFE8F1D8),
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

class _PickupRequestsTab extends StatelessWidget {
  const _PickupRequestsTab({required this.session});

  final OperatorSession session;

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
              operatorCode: session.code,
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

              if (requests.isEmpty) {
                return Center(
                  child: Text(
                    session.isManager
                        ? "No hay solicitudes pendientes"
                        : "No hay solicitudes para ${session.route}",
                  ),
                );
              }

              return ListView.separated(
                itemCount: requests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final request = requests[index];
                  final createdAt = request.createdAt;

                  return Card(
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
                                          : "${request.clientRoute} - ${createdAt.day}/${createdAt.month}/${createdAt.year}",
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                session.isManager
                                    ? "Op. ${request.assignedOperatorCode}"
                                    : request.status,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
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
                          _RequestField(
                            label: "Direccion",
                            value: request.clientAddress,
                          ),
                          _RequestField(
                            label: "Telefono",
                            value: request.clientPhone,
                          ),
                          _RequestField(
                            label: "Contenedor",
                            value: request.containerType,
                          ),
                          _RequestField(
                            label: "Operario asignado",
                            value: request.assignedOperatorCode == 0
                                ? "Sin asignar"
                                : "Operario ${request.assignedOperatorCode}",
                          ),
                          if (session.isManager) ...[
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: () =>
                                    _confirmDeleteRequest(context, request),
                                icon: const Icon(Icons.delete),
                                label: const Text("Eliminar"),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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
                  _ClientField(
                    label: "Contenedor",
                    value: client.containerType,
                  ),
                  _ClientField(
                    label: "Litros estimados",
                    value: "${client.estimatedLiters} L",
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
  final _containerTypeController = TextEditingController();
  final _estimatedLitersController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedRoute = RouteAssignment.northRoute;
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
    _containerTypeController.dispose();
    _estimatedLitersController.dispose();
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
        containerType: _containerTypeController.text,
        estimatedLiters: int.parse(_estimatedLitersController.text.trim()),
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

  String? _validateEstimatedLiters(String? value) {
    final liters = int.tryParse(value?.trim() ?? "");

    if (liters == null) {
      return "Introduce un numero valido";
    }

    if (liters <= 0) {
      return "Debe ser mayor que 0";
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
                _ClientTextField(
                  controller: _containerTypeController,
                  label: "Tipo de contenedor",
                  validator: _requiredText,
                ),
                _ClientTextField(
                  controller: _estimatedLitersController,
                  label: "Litros estimados",
                  keyboardType: TextInputType.number,
                  validator: _validateEstimatedLiters,
                ),
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
