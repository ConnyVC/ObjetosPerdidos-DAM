import 'package:firebase_auth/firebase_auth.dart'; // Autenticación con Firebase
import 'package:flutter/material.dart'; // Widgets de Flutter
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart'; // Íconos
import 'package:google_sign_in/google_sign_in.dart'; // Inicio de sesión con cuenta de Google
import 'package:objetos_perdidos/constants.dart'; // Colores personalizados de la app

class LoginPage extends StatefulWidget {
  // Pantalla con estado porque muestra u oculta mensajes de error al intentar entrar
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String mensajeError = ""; // Texto del error que se mostrará si falla el login
  bool hayError = false; // Indica si hay un error activo para mostrar el cuadro de aviso

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secundario, // Color de fondo de la pantalla
      body: Center(
        child: Container(
          // Tarjeta central donde va el ícono, texto y botón de Google
          padding: EdgeInsets.all(15),
          width: 300,
          height: 420,
          decoration: BoxDecoration(
            color: AppColors.fondo,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centra los elementos verticalmente
            children: [
              // Ícono decorativo superior
              Icon(
                MdiIcons.bagPersonal,
                size: 67,
                color: AppColors.icono,
              ),
              SizedBox(height: 8),
              // Instrucción para el usuario
              Text(
                'Ingresa con tu cuenta de gugul',
                style: TextStyle(color: AppColors.textoOscuro),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity, // Botón ocupa todo el ancho de la tarjeta
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      hayError = false; // Limpia cualquier error anterior al reintentar
                      final googleUser = await GoogleSignIn().signIn(); // Abre el selector de cuentas de Google

                      if (googleUser != null) {
                        // Si el usuario eligió una cuenta, obtiene sus tokens de autenticación
                        final googleAuth = await googleUser.authentication;
                        // Crea una credencial de Firebase usando los tokens de Google
                        final credential = GoogleAuthProvider.credential(
                          accessToken: googleAuth.accessToken,
                          idToken: googleAuth.idToken,
                        );
                        // Inicia sesión en Firebase Auth (esto hará que AuthWrapper pase a HomePage)
                        await FirebaseAuth.instance.signInWithCredential(
                          credential,
                        );
                      }
                    } on FirebaseAuthException catch (ex) {
                      // Captura errores propios de Firebase Auth
                      hayError = true;
                      switch (ex.code) {
                        case 'account-exists-with-different-credential':
                          mensajeError = "Cuenta ya existe :P ";
                          break;
                        case 'invalid-credential':
                          mensajeError = "Credenciales no válidas :C";
                          break;
                        case 'user-disabled':
                          mensajeError = "Cuenta desactivada";
                          break;
                        default:
                          mensajeError = "No se pudo iniciar sesión >:C ";
                      }
                      setState(() {}); // Actualiza la pantalla para mostrar el mensaje de error
                    } catch (ex) {
                      // Captura cualquier otro error (por ejemplo, problema de red o de Google Sign-In)
                      hayError = true;
                      mensajeError = "No se pudo conectar con gugul";
                      setState(() {}); // Actualiza la pantalla para mostrar el mensaje
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secundario, // Color del botón
                    padding: EdgeInsets.symmetric(vertical: 12), // Alto interno del botón
                  ),
                  icon: Icon(MdiIcons.heart, color: AppColors.terciario), // Ícono del botón
                  label: Text(
                    'Continuar con google',
                    style: TextStyle(color: AppColors.fondo), // Texto del botón
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Si hay error muestra un cuadro con alerta; si no, deja un espacio vacío de 45 px
              hayError
                  ? Container(
                      height: 45,
                      width: double.infinity,
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.shade200,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        children: [
                          Icon(MdiIcons.alert, color: AppColors.terciario), // Ícono de alerta
                          SizedBox(width: 10),
                          Text(
                            mensajeError, // Muestra el error ocurrido
                            style: TextStyle(color: AppColors.terciario),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(height: 45),
            ],
          ),
        ),
      ),
    );
  }
}