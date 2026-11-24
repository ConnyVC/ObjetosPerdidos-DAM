import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:objetos_perdidos/constants.dart';

class CardImagen extends StatelessWidget {
  const CardImagen({
    super.key,
    required this.objeto,
    required this.onTap,
    this.trailing,
  });

  final QueryDocumentSnapshot objeto;
  final VoidCallback onTap;
  final Widget? trailing;

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

  @override
  Widget build(BuildContext context) {
    final data = objeto.data() as Map<String, dynamic>;
    final String titulo = (data['titulo'] ?? 'Sin título').toString();
    final String lugar = (data['lugar'] ?? 'Sin lugar').toString();
    final String categoria = (data['categoria'] ?? 'General').toString();
    final String estado = (data['estado'] ?? 'Perdido').toString();
    final bool devuelto = data['devuelto'] == true;
    final Uint8List? fotoBytes = extraerFotoBytes(data);

    final bool esPerdido = estado == 'Perdido';

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: fotoBytes != null
                    ? Image.memory(
                        fotoBytes,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        color: AppColors.fondo,
                        child: Icon(
                          MdiIcons.imageOffOutline,
                          color: Colors.grey.shade500,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: esPerdido
                                ? Colors.red.shade100
                                : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            estado,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: esPerdido
                                  ? Colors.red.shade800
                                  : Colors.blue.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: devuelto
                                ? Colors.green.shade100
                                : Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            devuelto ? 'Devuelto' : 'No devuelto',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: devuelto
                                  ? Colors.green.shade800
                                  : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textoOscuro,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$lugar • $categoria',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}