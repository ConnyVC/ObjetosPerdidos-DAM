import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:objetos_perdidos/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String mensajeError = "";
  bool hayError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secundario,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(15),
          width: 300,
          height: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                MdiIcons.bagPersonal,
                size: 67,
                color: Colors.purple.shade100,
              ),
              SizedBox(height: 8),
              Text(
                'Ingresa con tu cuenta de gugul',
                style: TextStyle(color: Colors.blueGrey.shade600),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      hayError = false;
                      final googleUser = await GoogleSignIn().signIn();

                      if (googleUser != null) {
                        final googleAuth = await googleUser.authentication;
                        final credential = GoogleAuthProvider.credential(
                          accessToken: googleAuth.accessToken,
                          idToken: googleAuth.idToken,
                        );
                        await FirebaseAuth.instance.signInWithCredential(
                          credential,
                        );
                      }
                    } on FirebaseAuthException catch (ex) {
                      hayError = true;
                      switch (ex.code) {
                        case 'account-exists-with-different-credential':
                          mensajeError = "Cuenta ya existe :P ";
                          break;
                        case 'invalid-credential':
                          mensajeError = "Credenciales no válidas :C";
                          break;
                        case 'user-disabled':
                          mensajeError = "Cuenta desactivada waja waja";
                          break;
                        default:
                          mensajeError = "No se pudo iniciar sesión >:C ";
                      }
                      setState(() {});
                    } catch (ex) {
                      hayError = true;
                      mensajeError = "No se pudo conectar con gugul";
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secundario,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(MdiIcons.heart, color: AppColors.terciario),
                  label: Text(
                    'Continuar con google',
                    style: TextStyle(color: AppColors.fondo),
                  ),
                ),
              ),
              SizedBox(height: 20),
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
                          Icon(MdiIcons.alert, color: AppColors.terciario),
                          SizedBox(width: 10),
                          Text(
                            mensajeError,
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
