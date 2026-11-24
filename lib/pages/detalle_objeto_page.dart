import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:objetos_perdidos/constants.dart';

class DetalleObjetoPage extends StatelessWidget {
  const DetalleObjetoPage({super.key, required this.objeto});

  final QueryDocumentSnapshot objeto;

  Uint8List? extraerFotoBytes(Map<String, dynamic> data) {
  final dynamic fotoCampo = data['foto'];
  if (fotoCampo is Blob) {
    return fotoCampo.bytes;
  }
  if (fotoCampo is Uint8List) {
    return fotoCampo;
  }
  final String? base64String = data['fotoBase64']?.toString();
  if (base64String != null && base64String.isNotEmpty) {
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }
  return null;
}

  String _formatearFecha(dynamic fechaRaw) {
    if (fechaRaw is! Timestamp) return 'Sin fecha registrada';
    final dt = fechaRaw.toDate().toLocal();
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final anio = dt.year.toString();
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio $hora:$min';
  }

  @override
  Widget build(BuildContext context) {
    final data = objeto.data() as Map<String, dynamic>;
    final String titulo = (data['titulo'] ?? 'Sin título').toString();
    final String descripcion = (data['descripcion'] ?? 'Sin descripción').toString();
    final String lugar = (data['lugar'] ?? 'Sin lugar').toString();
    final String categoria = (data['categoria'] ?? 'General').toString();
    final String estado = (data['estado'] ?? 'Perdido').toString();
    final bool devuelto = data['devuelto'] == true;
    final String autorNombre = (data['autorNombre'] ?? 'Usuario').toString();
    final String autorEmail = (data['autorEmail'] ?? 'Sin correo').toString();
    final Uint8List? fotoBytes = extraerFotoBytes(data);

    final bool esPerdido = estado == 'Perdido';

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.primario,
        foregroundColor: Colors.white,
        title: Text(
          titulo,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen principal
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: fotoBytes != null
                  ? Image.memory(
                      fotoBytes,
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.white,
                      child: Icon(
                        MdiIcons.imageOffOutline,
                        size: 56,
                        color: Colors.grey.shade400,
                      ),
                    ),
            ),
            const SizedBox(height: 14),

            // Etiquetas de estado y devolución
            Row(
              children: [
                Chip(
                  backgroundColor:
                      esPerdido ? Colors.red.shade100 : Colors.blue.shade100,
                  label: Text(
                    estado,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: esPerdido
                          ? Colors.red.shade800
                          : Colors.blue.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  backgroundColor:
                      devuelto ? Colors.green.shade100 : Colors.amber.shade100,
                  label: Text(
                    devuelto ? 'Devuelto' : 'No devuelto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: devuelto
                          ? Colors.green.shade800
                          : Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Título y datos clave
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  const Divider(height: 20),
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

            // Descripción
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
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

            // Contacto del autor
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
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

class _FilaDato extends StatelessWidget {
  const _FilaDato({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

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
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }
}