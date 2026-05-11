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
    try {
      await FirestoreDatabase().createPickupRequest(clientEmail: clientEmail);

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
      appBar: AppBar(backgroundColor: const Color(0xFFE8F1D8)),
      backgroundColor: const Color(0xFFE8F1D8),
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
