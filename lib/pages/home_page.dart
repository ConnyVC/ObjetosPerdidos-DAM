import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:objetos_perdidos/constants.dart';
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
  bool soloMios = false;

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
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.primario,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Objetos Perdidos',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              user?.displayName ?? 'Cargando usuario...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
      ),
      body: Column(
        children: [
          // Barra superior de filtro (Todos vs Mis publicaciones)
          Container(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        soloMios = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !soloMios
                          ? AppColors.primario
                          : Colors.white,
                      foregroundColor: !soloMios
                          ? Colors.white
                          : AppColors.textoOscuro,
                    ),
                    child: Text('Todos'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        soloMios = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: soloMios
                          ? AppColors.primario
                          : Colors.white,
                      foregroundColor: soloMios
                          ? Colors.white
                          : AppColors.textoOscuro,
                    ),
                    child: Text('Mis publicaciones'),
                  ),
                ),
              ],
            ),
          ),

          // Espacio reservado para la lista de objetos (siguiente paso)
          Expanded(
            child: Center(
              child: Text(
                soloMios
                    ? 'Mostrando: Mis publicaciones'
                    : 'Mostrando: Todos los objetos',
                style: TextStyle(color: AppColors.textoOscuro),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
