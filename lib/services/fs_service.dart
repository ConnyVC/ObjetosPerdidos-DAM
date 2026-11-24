import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class FsService {
  Future<QuerySnapshot> categorias() {
    return FirebaseFirestore.instance
        .collection('categorias')
        .orderBy('nombre')
        .get();
  }

  Stream<QuerySnapshot> objetos() {
    return FirebaseFirestore.instance
        .collection('objetos')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> misObjetos(String autorUid) {
    return FirebaseFirestore.instance
        .collection('objetos')
        .where('autorUid', isEqualTo: autorUid)
        .snapshots();
  }

  Future<void> agregarObjeto({
    required String titulo,
    required String descripcion,
    required String lugar,
    required String categoria,
    required String estado,
    required Uint8List fotoBytes,
    required String autorUid,
    required String autorNombre,
    required String autorEmail,
  }) {
    return FirebaseFirestore.instance.collection('objetos').doc().set({
      'titulo': titulo,
      'descripcion': descripcion,
      'lugar': lugar,
      'categoria': categoria,
      'estado': estado,
      'devuelto': false,
      'foto': Blob(fotoBytes),
      'autorUid': autorUid,
      'autorNombre': autorNombre,
      'autorEmail': autorEmail,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editarObjeto(
    String id,
    String titulo,
    String descripcion,
    String lugar,
    String estado,
    bool devuelto,
  ) {
    return FirebaseFirestore.instance.collection('objetos').doc(id).update({
      'titulo': titulo,
      'descripcion': descripcion,
      'lugar': lugar,
      'estado': estado,
      'devuelto': devuelto,
    });
  }

  Future<void> borrarObjeto(String id) {
    return FirebaseFirestore.instance.collection('objetos').doc(id).delete();
  }
}