import 'package:firebase_auth/firebase_auth.dart'; // Para cerrar sesión en Firebase Auth
import 'package:flutter/material.dart'; // Widgets básicos de Flutter
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart'; // Íconos
import 'package:google_sign_in/google_sign_in.dart'; // Para cerrar sesión también en Google Sign-In
import 'package:objetos_perdidos/constants.dart'; // Colores personalizados de la app
import 'package:objetos_perdidos/pages/agregar_objeto_page.dart'; // Pantalla para publicar un objeto nuevo
import 'package:objetos_perdidos/pages/tabs/tab_mis_publicaciones.dart'; // Pestaña con publicaciones del usuario actual
import 'package:objetos_perdidos/pages/tabs/tab_objetos.dart'; // Pestaña con todas las publicaciones
import 'package:objetos_perdidos/services/auth_service.dart'; // Servicio para obtener el usuario actual

class HomePage extends StatefulWidget {
  // Pantalla con estado porque guarda y muestra los datos del usuario autenticado
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user; // Guarda el usuario que inició sesión (o null mientras carga)

  @override
  void initState() {
    super.initState(); // Inicializa el estado base del widget
    // Pide el usuario actual a AuthService cuando se abre la pantalla
    AuthService().currentUser().then((currentU) {
      if (!mounted) return; // Evita llamar setState si el widget ya fue destruido
      setState(() {
        user = currentU; // Guarda el usuario y refresca la barra superior
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Controla la navegación entre las 2 pestañas ('Todos' y 'Mis publicaciones')
    return DefaultTabController(
      length: 2, // Cantidad de pestañas
      child: Scaffold(
        backgroundColor: AppColors.fondo, // Color de fondo general
        appBar: AppBar(
          backgroundColor: AppColors.primario, // Color principal de la barra superior
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Alinea los textos a la izquierda
            children: [
              // Nombre de la aplicación arriba en tamaño pequeño
              const Text(
                'Objetos Perdidos',
                style: TextStyle(color: AppColors.textoClaro, fontSize: 16),
              ),
              // Muestra el nombre del usuario autenticado; si no tiene nombre, el correo; o 'Cargando usuario...'
              Text(
                user?.displayName ?? user?.email ?? 'Cargando usuario...',
                style: const TextStyle(
                  color: AppColors.textoClaro,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis, // Corta con '...' si el nombre es muy largo
              ),
            ],
          ),
          actions: [
            // Botón de cerrar sesión a la derecha de la barra superior
            IconButton(
              icon: Icon(MdiIcons.logout, color: AppColors.textoClaro),
              tooltip: 'Cerrar Sesión',
              onPressed: () async {
                await GoogleSignIn().signOut(); // Cierra la sesión de Google
                await FirebaseAuth.instance.signOut(); // Cierra la sesión de Firebase (AuthWrapper volverá a LoginPage)
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.terciario, // Color de la línea bajo la pestaña activa
            indicatorWeight: 3, // Grosor de esa línea
            labelColor: AppColors.textoClaro, // Color del texto/ícono de la pestaña activa
            unselectedLabelColor: AppColors.textoNoSeleccionado, // Color de la pestaña inactiva
            tabs: [
              Tab(icon: Icon(MdiIcons.viewList), text: 'Todos'), // Primera pestaña: todos los objetos
              Tab(icon: Icon(MdiIcons.accountEdit), text: 'Mis publicaciones'), // Segunda pestaña: objetos propios
            ],
          ),
        ),
        // Botón flotante para ir a publicar un objeto nuevo
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primario,
          foregroundColor: AppColors.fondo,
          tooltip: 'Publicar objeto',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AgregarObjetoPage(), // Abre AgregarObjetoPage
              ),
            );
          },
          child: Icon(MdiIcons.plus), // Ícono de '+'
        ),
        // Contenido de cada pestaña en el mismo orden que las tabs
        body: const TabBarView(
          children: [
            TabObjetos(), // Vista de la pestaña 'Todos'
            TabMisPublicaciones(), // Vista de la pestaña 'Mis publicaciones'
          ],
        ),
      ),
    );
  }
}