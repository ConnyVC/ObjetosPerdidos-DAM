import 'dart:typed_data'; // Permite usar Uint8List para los bytes de la imagen
import 'package:cloud_firestore/cloud_firestore.dart'; // Permite conectarse y operar con Cloud Firestore

class FsService {
  // Obtiene las categorías desde Firestore ordenadas alfabéticamente por 'nombre' (una sola consulta con .get())
  Future<QuerySnapshot> categorias() {
    return FirebaseFirestore.instance
        .collection('categorias') // Entra a la colección 'categorias'
        .orderBy('nombre') // Ordena por el campo 'nombre'
        .get(); // Ejecuta la consulta y devuelve el resultado
  }

  // Escucha en tiempo real (.snapshots()) todos los objetos, ordenados de la fecha más nueva a la más vieja
  Stream<QuerySnapshot> objetos() {
    return FirebaseFirestore.instance
        .collection('objetos') // Entra a la colección 'objetos'
        .orderBy('fecha', descending: true) // Ordena por 'fecha' de forma descendente
        .snapshots(); // Devuelve un Stream que avisa cada vez que hay cambios en Firestore
  }

  // Escucha en tiempo real solo los objetos publicados por el usuario actual (según su autorUid)
  Stream<QuerySnapshot> misObjetos(String autorUid) {
    return FirebaseFirestore.instance
        .collection('objetos') // Entra a la colección 'objetos'
        .where('autorUid', isEqualTo: autorUid) // Filtra donde 'autorUid' sea igual al uid del usuario
        .snapshots(); // Devuelve el Stream en tiempo real con esos documentos
  }

  // Guarda un nuevo objeto en Firestore
  Future<void> agregarObjeto({
    required String titulo, // Título del objeto
    required String descripcion, // Descripción del objeto
    required String lugar, // Lugar donde se perdió o encontró
    required String categoria, // Categoría elegida
    required String estado, // 'Perdido' o 'Encontrado'
    required Uint8List fotoBytes, // Bytes de la imagen ya comprimida y validada
    required String autorUid, // ID del usuario que publica
    required String autorNombre, // Nombre del usuario que publica
    required String autorEmail, // Correo del usuario que publica
  }) {
    return FirebaseFirestore.instance
        .collection('objetos') // Entra a la colección 'objetos'
        .doc() // Crea una referencia a un documento nuevo con ID automático
        .set({
      'titulo': titulo, // Guarda el título
      'descripcion': descripcion, // Guarda la descripción
      'lugar': lugar, // Guarda el lugar
      'categoria': categoria, // Guarda la categoría
      'estado': estado, // Guarda el estado
      'devuelto': false, // Todo objeto nuevo empieza como no devuelto
      'foto': Blob(fotoBytes), // Guarda la imagen como tipo Blob dentro del mismo documento
      'autorUid': autorUid, // Guarda el uid del autor
      'autorNombre': autorNombre, // Guarda el nombre del autor
      'autorEmail': autorEmail, // Guarda el correo del autor
      'fecha': FieldValue.serverTimestamp(), // Pide a Firestore que ponga la fecha/hora del servidor
    });
  }

  // Actualiza los datos editables de un objeto ya existente usando su id de documento
  Future<void> editarObjeto(
    String id, // ID del documento a editar
    String titulo, // Nuevo título
    String descripcion, // Nueva descripción
    String lugar, // Nuevo lugar
    String estado, // Nuevo estado
    bool devuelto, // Nuevo valor de si ya fue devuelto o no
  ) {
    return FirebaseFirestore.instance
        .collection('objetos') // Entra a 'objetos'
        .doc(id) // Busca el documento por su id
        .update({
      'titulo': titulo, // Actualiza 'titulo'
      'descripcion': descripcion, // Actualiza 'descripcion'
      'lugar': lugar, // Actualiza 'lugar'
      'estado': estado, // Actualiza 'estado'
      'devuelto': devuelto, // Actualiza 'devuelto'
    });
  }

  // Borra un documento de Firestore según su id
  Future<void> borrarObjeto(String id) {
    return FirebaseFirestore.instance
        .collection('objetos') // Entra a 'objetos'
        .doc(id) // Busca el documento por su id
        .delete(); // Lo elimina de la base de datos
  }
}