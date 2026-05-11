import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/firestore_database.dart';
import '../../routes/app_routes.dart';
import '../../widgets/marquee_app_bar_title.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientEmailController = TextEditingController();
  final _clientPasswordController = TextEditingController();
  final _operatorCodeController = TextEditingController();
  final _operatorPasswordController = TextEditingController();
  String? _selectedAccessType;
  bool _isClientLoginLoading = false;

  @override
  void dispose() {
    _clientEmailController.dispose();
    _clientPasswordController.dispose();
    _operatorCodeController.dispose();
    _operatorPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loginAsClient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isClientLoginLoading = true;
    });

    try {
      final result = await FirestoreDatabase().validateClientLogin(
        email: _clientEmailController.text,
        password: _clientPasswordController.text,
      );

      if (!mounted) return;

      switch (result) {
        case ClientLoginResult.success:
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.clientHome,
            arguments: _clientEmailController.text.trim().toLowerCase(),
          );
          return;
        case ClientLoginResult.emailNotFound:
          _showLoginError("Ese email no esta registrado como cliente");
        case ClientLoginResult.wrongPassword:
          _showLoginError("La contrasena no es correcta");
        case ClientLoginResult.inactive:
          _showLoginError("Este cliente esta inactivo");
      }
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showLoginError("No se pudo validar el cliente: ${error.code}");
    } catch (error) {
      if (!mounted) return;
      _showLoginError("No se pudo validar el cliente: $error");
    } finally {
      if (mounted) {
        setState(() {
          _isClientLoginLoading = false;
        });
      }
    }
  }

  void _showLoginError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _loginAsOperator() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.operatorHome,
      arguments: int.parse(_operatorCodeController.text.trim()),
    );
  }

  void _showAccessType(String accessType) {
    _formKey.currentState?.reset();

    setState(() {
      _selectedAccessType = accessType;
    });
  }

  void _goBackToAccessSelection() {
    _formKey.currentState?.reset();

    setState(() {
      _selectedAccessType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7E6C3),
        foregroundColor: const Color(0xFF1F4D35),
        elevation: 0,
        title: const MarqueeAppBarTitle(
          text: "Mas de treinta años preocupandonos por el medioambiente.",
        ),
      ),
      backgroundColor: const Color(0xFFD7E6C3),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 56),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _BrandHeader(),

                        if (_selectedAccessType == "client")
                          _ClientAccessForm(
                            emailController: _clientEmailController,
                            passwordController: _clientPasswordController,
                            isLoading: _isClientLoginLoading,
                            onSubmit: _loginAsClient,
                            onBack: _goBackToAccessSelection,
                          )
                        else if (_selectedAccessType == "operator")
                          _OperatorAccessForm(
                            codeController: _operatorCodeController,
                            passwordController: _operatorPasswordController,
                            onSubmit: _loginAsOperator,
                            onBack: _goBackToAccessSelection,
                          )
                        else
                          _AccessTypeSelector(
                            onClientSelected: () => _showAccessType("client"),
                            onOperatorSelected: () =>
                                _showAccessType("operator"),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const Positioned(
              right: 16,
              bottom: 12,
              child: Text(
                "\u00A9 SERRMA",
                style: TextStyle(
                  color: Color(0xFF5E7F4F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessTypeSelector extends StatelessWidget {
  const _AccessTypeSelector({
    required this.onClientSelected,
    required this.onOperatorSelected,
  });

  final VoidCallback onClientSelected;
  final VoidCallback onOperatorSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Selecciona como quieres acceder",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF1F4D35),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 16),

        _AccessCard(
          icon: Icons.storefront,
          title: "Soy cliente",
          subtitle: "Solicitar recogidas para mi negocio",
          onPressed: onClientSelected,
        ),

        const SizedBox(height: 12),

        _AccessCard(
          icon: Icons.local_shipping,
          title: "Soy operario",
          subtitle: "Gestionar solicitudes pendientes",
          onPressed: onOperatorSelected,
        ),

        const SizedBox(height: 24),

        const Text(
          "Recogida responsable de recogida de residuos.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF5E7F4F)),
        ),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo_serrma.jpg',
            height: 118,
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          "Gestion de recogida de residuos",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF5E7F4F),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFBFD3A6)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7E6C3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF1F4D35)),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1F4D35),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF5E7F4F)),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Color(0xFF5E7F4F)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientAccessForm extends StatelessWidget {
  const _ClientAccessForm({
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
    required this.onBack,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final Future<void> Function() onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Acceso cliente",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 20),

        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Email del cliente",
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: (value) {
            final email = value?.trim() ?? "";
            final emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

            if (email.isEmpty) {
              return "Introduce el email del cliente";
            }

            if (!emailFormat.hasMatch(email)) {
              return "Introduce un email valido";
            }

            return null;
          },
        ),

        const SizedBox(height: 12),

        TextFormField(
          controller: passwordController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Contraseña",
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Introduce la contraseña";
            }

            return null;
          },
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: isLoading ? null : onSubmit,
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Acceder"),
        ),

        const SizedBox(height: 10),

        TextButton(onPressed: onBack, child: const Text("Volver")),
      ],
    );
  }
}

class _OperatorAccessForm extends StatelessWidget {
  const _OperatorAccessForm({
    required this.codeController,
    required this.passwordController,
    required this.onSubmit,
    required this.onBack,
  });

  final TextEditingController codeController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Acceso operario",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 20),

        TextFormField(
          controller: codeController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Código de operario",
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            final codeText = value?.trim() ?? "";
            final operatorCode = int.tryParse(codeText);

            if (codeText.isEmpty) {
              return "Introduce el código de operario";
            }

            if (operatorCode == null || operatorCode < 1 || operatorCode > 6) {
              return "Usa un codigo del 1 al 5, o el 6 para encargado";
            }

            return null;
          },
        ),

        const SizedBox(height: 12),

        TextFormField(
          controller: passwordController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Contraseña",
          ),
          obscureText: true,
          validator: (value) {
            final password = value?.trim() ?? "";

            if (password.isEmpty) {
              return "Introduce la contraseña";
            }

            if (password.toLowerCase() != "serrma") {
              return "La contraseña no es correcta";
            }

            return null;
          },
        ),

        const SizedBox(height: 20),

        ElevatedButton(onPressed: onSubmit, child: const Text("Acceder")),

        const SizedBox(height: 10),

        TextButton(onPressed: onBack, child: const Text("Volver")),
      ],
    );
  }
}
