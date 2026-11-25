import 'package:firebase_auth/firebase_auth.dart'; // Permite escuchar el estado de sesión en Firebase Auth
import 'package:flutter/material.dart'; // Widgets básicos de Flutter

import 'home_page.dart'; // Pantalla principal cuando el usuario está autenticado
import 'login_page.dart'; // Pantalla de inicio de sesión cuando no hay usuario activo

class AuthWrapper extends StatelessWidget {
  // Widget que decide automáticamente si mostrar LoginPage o HomePage según la sesión
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha en tiempo real cada vez que cambia el usuario (inicia o cierra sesión)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras Firebase aún está verificando si existe una sesión guardada
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()), // Muestra un indicador de carga centrado
          );
        }

        // Si el stream trae un usuario (hay sesión iniciada)
        if (snapshot.hasData) {
          return const HomePage(); // Entra a la aplicación principal
        }

        // Si no hay usuario autenticado (o se cerró sesión)
        return const LoginPage(); // Vuelve o muestra la pantalla de login
      },
    );
  }
}