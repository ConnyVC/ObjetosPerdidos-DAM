import 'package:firebase_auth/firebase_auth.dart'; // Importa Firebase Auth para consultar el estado de sesión

class AuthService {
  // Devuelve el usuario actualmente autenticado en Firebase Auth (o null si no hay sesión iniciada)
  Future<User?> currentUser() async {
    return FirebaseAuth.instance.currentUser;
  }
}