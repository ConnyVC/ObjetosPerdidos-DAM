import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:objetos_perdidos/services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user;

  @override
  void initState() {
    super.initState();
    AuthService().currentUser().then((currentU) {
      if (!mounted) return;
      setState(() {
        user = currentU;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink.shade500,
        leading: Icon(MdiIcons.bagPersonal, size: 30, color: Colors.white),
        title: Text(
          user?.email ?? "Cargando datos...",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        actions: [
          PopupMenuButton(
            onSelected: (valueSeleccionado) async {
              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
            },
            iconColor: Colors.white,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.blueGrey.shade300),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(child: Text('Pantalla principal - objetos perdidos')),
    );
  }
}
