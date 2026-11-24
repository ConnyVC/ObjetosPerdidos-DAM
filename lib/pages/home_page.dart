import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:objetos_perdidos/constants.dart';
import 'package:objetos_perdidos/pages/agregar_objeto_page.dart';
import 'package:objetos_perdidos/pages/tabs/tab_mis_publicaciones.dart';
import 'package:objetos_perdidos/pages/tabs/tab_objetos.dart';
import 'package:objetos_perdidos/services/auth_service.dart';

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.fondo,
        appBar: AppBar(
          backgroundColor: AppColors.primario,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Objetos Perdidos',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                user?.displayName ?? user?.email ?? 'Cargando usuario...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(MdiIcons.logout, color: Colors.white),
              tooltip: 'Cerrar Sesión',
              onPressed: () async {
                await GoogleSignIn().signOut();
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.terciario,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(MdiIcons.viewList), text: 'Todos'),
              Tab(icon: Icon(MdiIcons.accountEdit), text: 'Mis publicaciones'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primario,
          foregroundColor: Colors.white,
          tooltip: 'Publicar objeto',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AgregarObjetoPage(),
              ),
            );
          },
          child: Icon(MdiIcons.plus),
        ),
        body: const TabBarView(
          children: [
            TabObjetos(),
            TabMisPublicaciones(),
          ],
        ),
      ),
    );
  }
}