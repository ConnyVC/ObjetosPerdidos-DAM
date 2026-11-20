import 'package:cloud_firestore/cloud_firestore.dart';

class FsService {
  Stream<QuerySnapshot> objetos() {
    return FirebaseFirestore.instance.collection('objetos').snapshots();
  }

  Future<void> agregarObjeto(
    String titulo,
    String descripcion,
    String lugar,
    String estado,
    String autorEmail,
  ) {
    return FirebaseFirestore.instance.collection('objetos').doc().set({
      'titulo': titulo,
      'descripcion': descripcion,
      'lugar': lugar,
      'estado': estado,
      'autorEmail': autorEmail,
    });
  }

  Future<void> borrarObjeto(String id) {
    return FirebaseFirestore.instance.collection('objetos').doc(id).delete();
  }

  Future<void> editarObjeto(
    String id,
    String titulo,
    String descripcion,
    String lugar,
    String estado,
  ) {
    return FirebaseFirestore.instance.collection('objetos').doc(id).update({
      'titulo': titulo,
      'descripcion': descripcion,
      'lugar': lugar,
      'estado': estado,
    });
  }
}
