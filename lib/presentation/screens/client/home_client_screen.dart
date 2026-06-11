import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../routes/app_routes.dart';
import '../../../services/firestore_database.dart';

class HomeClientScreen extends StatelessWidget {
  const HomeClientScreen({super.key});

  Future<void> _createPickupRequest(
    BuildContext context,
    String clientEmail,
  ) async {
    final pickupDetails = await showDialog<_PickupRequestDetails>(
      context: context,
      builder: (context) => const _PickupRequestDialog(),
    );

    if (pickupDetails == null) {
      return;
    }

    try {
      await FirestoreDatabase().createPickupRequest(
        clientEmail: clientEmail,
        drumCount: pickupDetails.drumCount,
        drumCapacityLiters: pickupDetails.drumCapacityLiters,
        filterCount: pickupDetails.filterCount,
        needsSoap: pickupDetails.needsSoap,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solicitud de recogida registrada")),
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo registrar: ${error.code}")),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No se pudo registrar: $error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientEmail =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'CLIENTE';

    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFFC7E0B0)),
      backgroundColor: const Color(0xFFC7E0B0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Bienvenido a SERRMA, $clientEmail"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => _createPickupRequest(context, clientEmail),
              child: const Text("SOLICITAR RECOGIDA DE RESIDUO"),
            ),

            const SizedBox(height: 10),

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
    );
  }
}

class _PickupRequestDetails {
  const _PickupRequestDetails({
    required this.drumCount,
    required this.drumCapacityLiters,
    required this.filterCount,
    required this.needsSoap,
  });

  final int drumCount;
  final int drumCapacityLiters;
  final int filterCount;
  final bool needsSoap;
}

class _PickupRequestDialog extends StatefulWidget {
  const _PickupRequestDialog();

  @override
  State<_PickupRequestDialog> createState() => _PickupRequestDialogState();
}

class _PickupRequestDialogState extends State<_PickupRequestDialog> {
  int _drumCount = 1;
  int _drumCapacityLiters = 25;
  int _filterCount = 0;
  bool _needsSoap = false;

  static const _drumCounts = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  static const _drumCapacities = [25, 50];
  static const _filterCounts = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  void _confirm() {
    Navigator.pop(
      context,
      _PickupRequestDetails(
        drumCount: _drumCount,
        drumCapacityLiters: _drumCapacityLiters,
        filterCount: _filterCount,
        needsSoap: _needsSoap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Datos de la recogida"),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _drumCount,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Numero de bidones",
              ),
              items: [
                for (final count in _drumCounts)
                  DropdownMenuItem(value: count, child: Text("$count")),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _drumCount = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _drumCapacityLiters,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Capacidad del bidon",
              ),
              items: [
                for (final liters in _drumCapacities)
                  DropdownMenuItem(value: liters, child: Text("$liters L")),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _drumCapacityLiters = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _filterCount,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Numero de campanas",
              ),
              items: [
                for (final count in _filterCounts)
                  DropdownMenuItem(value: count, child: Text("$count")),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _filterCount = value;
                });
              },
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Llevar jabon"),
              value: _needsSoap,
              onChanged: (value) {
                setState(() {
                  _needsSoap = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        FilledButton(onPressed: _confirm, child: const Text("Solicitar")),
      ],
    );
  }
}
