import 'dart:convert'; // Para decodificar base64 si existiera algún dato antiguo con ese formato
import 'dart:typed_data'; // Para trabajar con bytes de imagen (Uint8List)
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Blob, Timestamp y QueryDocumentSnapshot
import 'package:flutter/material.dart'; // Widgets de Flutter
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart'; // Íconos
import 'package:objetos_perdidos/constants.dart'; // Colores personalizados de la app

class DetalleObjetoPage extends StatelessWidget {
  // Pantalla que muestra toda la información de un objeto al tocar su tarjeta
  const DetalleObjetoPage({super.key, required this.objeto});

  final QueryDocumentSnapshot objeto; // Documento del objeto seleccionado en Firestore

  // Extrae los bytes de la imagen desde Blob, Uint8List o base64 antiguo
  Uint8List? extraerFotoBytes(Map<String, dynamic> data) {
    final dynamic fotoCampo = data['foto']; // Lee el campo 'foto'
    if (fotoCampo is Blob) {
      return fotoCampo.bytes; // Si es Blob, devuelve sus bytes
    }
    if (fotoCampo is Uint8List) {
      return fotoCampo; // Si ya viene como Uint8List, lo devuelve directo
    }
    // Respaldo por si algún documento viejo guardó la foto como texto base64
    final String? base64String = data['fotoBase64']?.toString();
    if (base64String != null && base64String.isNotEmpty) {
      try {
        return base64Decode(base64String); // Convierte el texto base64 a bytes
      } catch (_) {
        return null; // Si no se puede decodificar, retorna null
      }
    }
    return null; // Si no hay imagen válida, retorna null
  }

  // Convierte una fecha Timestamp de Firestore a texto legible 'dd/mm/aaaa hh:mm' en hora local
  String _formatearFecha(dynamic fechaRaw) {
    if (fechaRaw is! Timestamp) return 'Sin fecha registrada'; // Si aún no tiene Timestamp válido
    final dt = fechaRaw.toDate().toLocal(); // Pasa de Timestamp a DateTime local
    final dia = dt.day.toString().padLeft(2, '0'); // Día con dos dígitos (ej. 05)
    final mes = dt.month.toString().padLeft(2, '0'); // Mes con dos dígitos
    final anio = dt.year.toString(); // Año
    final hora = dt.hour.toString().padLeft(2, '0'); // Hora con dos dígitos
    final min = dt.minute.toString().padLeft(2, '0'); // Minutos con dos dígitos
    return '$dia/$mes/$anio $hora:$min'; // Devuelve la fecha formateada
  }

  @override
  Widget build(BuildContext context) {
    final data = objeto.data() as Map<String, dynamic>; // Obtiene los campos del documento como mapa
    final String titulo = (data['titulo'] ?? 'Sin título').toString(); // Título del objeto
    final String descripcion = (data['descripcion'] ?? 'Sin descripción').toString(); // Descripción
    final String lugar = (data['lugar'] ?? 'Sin lugar').toString(); // Lugar
    final String categoria = (data['categoria'] ?? 'General').toString(); // Categoría
    final String estado = (data['estado'] ?? 'Perdido').toString(); // Estado ('Perdido' o 'Encontrado')
    final bool devuelto = data['devuelto'] == true; // Indica si ya fue devuelto
    final String autorNombre = (data['autorNombre'] ?? 'Usuario').toString(); // Nombre de quien publicó
    final String autorEmail = (data['autorEmail'] ?? 'Sin correo').toString(); // Correo de contacto del autor
    final Uint8List? fotoBytes = extraerFotoBytes(data); // Bytes de la foto para mostrarla

    final bool esPerdido = estado == 'Perdido'; // Define el estilo de la etiqueta de estado

    return Scaffold(
      backgroundColor: AppColors.fondo, // Fondo de la pantalla
      appBar: AppBar(
        backgroundColor: AppColors.primario, // Color de la barra superior
        foregroundColor: AppColors.textoClaro, // Color del texto y botón atrás
        title: Text(
          titulo, // Muestra el título del objeto en la barra superior
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        // Permite hacer scroll vertical si el contenido supera el alto de la pantalla
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Alinea bloques a la izquierda
          children: [
            // Imagen principal del objeto
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: fotoBytes != null
                  ? Image.memory(
                      fotoBytes, // Renderiza la imagen desde los bytes en memoria
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      // Si no hay foto, muestra un cuadro con ícono
                      height: 180,
                      width: double.infinity,
                      color: AppColors.textoClaro,
                      child: Icon(
                        MdiIcons.imageOffOutline,
                        size: 56,
                        color: AppColors.textoNoSeleccionado
                      ),
                    ),
            ),
            const SizedBox(height: 14),

            // Etiquetas de estado ('Perdido'/'Encontrado') y devolución ('Devuelto'/'No devuelto')
            Row(
              children: [
                Chip(
                  backgroundColor:
                      esPerdido ? AppColors.terciario : AppColors.secundario,
                  label: Text(
                    estado,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: esPerdido
                          ? AppColors.textoClaro
                          : AppColors.textoClaro,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  backgroundColor:
                      devuelto ? AppColors.terciario : AppColors.secundario,
                  label: Text(
                    devuelto ? 'Devuelto' : 'No devuelto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: devuelto
                          ? AppColors.textoClaro
                          : AppColors.textoClaro,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Tarjeta blanca con título, categoría, lugar y fecha
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.textoClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textoOscuro,
                    ),
                  ),
                  const Divider(height: 20), // Línea separadora
                  _FilaDato(
                    icono: MdiIcons.shapeOutline,
                    etiqueta: 'Categoría',
                    valor: categoria,
                  ),
                  const SizedBox(height: 8),
                  _FilaDato(
                    icono: MdiIcons.mapMarkerOutline,
                    etiqueta: 'Lugar',
                    valor: lugar,
                  ),
                  const SizedBox(height: 8),
                  _FilaDato(
                    icono: MdiIcons.calendarClock,
                    etiqueta: 'Fecha',
                    valor: _formatearFecha(data['fecha']),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tarjeta blanca con la descripción completa del objeto
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.textoClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primario,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textoOscuro,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tarjeta blanca con los datos de contacto de quien publicó el objeto
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.textoClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Publicado por',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primario,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FilaDato(
                    icono: MdiIcons.accountOutline,
                    etiqueta: 'Nombre',
                    valor: autorNombre,
                  ),
                  const SizedBox(height: 8),
                  _FilaDato(
                    icono: MdiIcons.emailOutline,
                    etiqueta: 'Correo',
                    valor: autorEmail,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar reutilizable para mostrar una fila con ícono, etiqueta en negrita y valor
class _FilaDato extends StatelessWidget {
  const _FilaDato({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono; // Ícono a la izquierda
  final String etiqueta; // Nombre del campo (ej. 'Categoría')
  final String valor; // Contenido del campo

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 18, color: AppColors.primario),
        const SizedBox(width: 8),
        Text(
          '$etiqueta: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textoOscuro,
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: TextStyle(color: AppColors.textoOscuro),
          ),
        ),
      ],
    );
  }
}