import 'dart:convert'; // Sirve para decodificar texto base64 si existiera alguna foto vieja así
import 'dart:typed_data'; // Permite trabajar con bytes de imagen (Uint8List)
import 'package:cloud_firestore/cloud_firestore.dart'; // Para usar Blob y QueryDocumentSnapshot
import 'package:flutter/material.dart'; // Widgets básicos de Flutter
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart'; // Íconos
import 'package:objetos_perdidos/constants.dart'; // Colores personalizados de la app

class CardImagen extends StatelessWidget {
  // Constructor de la tarjeta; recibe el documento del objeto, qué hacer al tocarlo y un widget opcional a la derecha
  const CardImagen({
    super.key,
    required this.objeto,
    required this.onTap,
    this.trailing,
  });

  final QueryDocumentSnapshot objeto; // Documento que viene desde Firestore
  final VoidCallback onTap; // Función que se ejecuta al tocar la tarjeta
  final Widget? trailing; // Widget extra al final (por ejemplo, el menú de editar/borrar)

  // Saca los bytes de la imagen desde el documento de Firestore
  Uint8List? extraerFotoBytes(Map<String, dynamic> data) {
    final dynamic fotoCampo = data['foto']; // Lee el campo 'foto'
    if (fotoCampo is Blob) {
      return fotoCampo.bytes; // Si es Blob (como se guarda ahora), devuelve sus bytes
    }
    if (fotoCampo is Uint8List) {
      return fotoCampo; // Si ya viene como lista de bytes, la devuelve directo
    }
    // Respaldo por si algún documento antiguo tenía la foto guardada como texto base64
    final String? base64String = data['fotoBase64']?.toString();
    if (base64String != null && base64String.isNotEmpty) {
      try {
        return base64Decode(base64String); // Convierte el texto base64 a bytes
      } catch (_) {
        return null; // Si falla al decodificar, devuelve null
      }
    }
    return null; // Si no hay foto, devuelve null
  }

  @override
  Widget build(BuildContext context) {
    final data = objeto.data() as Map<String, dynamic>; // Convierte los datos del documento a un mapa clave-valor
    final String titulo = (data['titulo'] ?? 'Sin título').toString(); // Obtiene el título o un texto por defecto
    final String lugar = (data['lugar'] ?? 'Sin lugar').toString(); // Obtiene el lugar o un texto por defecto
    final String categoria = (data['categoria'] ?? 'General').toString(); // Obtiene la categoría o 'General'
    final String estado = (data['estado'] ?? 'Perdido').toString(); // Obtiene 'Perdido' o 'Encontrado'
    final bool devuelto = data['devuelto'] == true; // Revisa si ya fue devuelto (true/false)
    final Uint8List? fotoBytes = extraerFotoBytes(data); // Obtiene los bytes de la foto

    final bool esPerdido = estado == 'Perdido'; // Ayuda a decidir el color de la etiqueta de estado

    return Card(
      color: AppColors.textoClaro, // Fondo blanco de la tarjeta
      elevation: 2, // Sombra suave
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Separación con los bordes y otras tarjetas
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bordes redondeados
      child: InkWell(
        borderRadius: BorderRadius.circular(12), // Mismo borde redondeado al tocar
        onTap: onTap, // Abre el detalle al presionar la tarjeta
        child: Padding(
          padding: const EdgeInsets.all(10), // Espacio interior de la tarjeta
          child: Row(
            children: [
              // Cuadro de la imagen a la izquierda
              ClipRRect(
                borderRadius: BorderRadius.circular(8), // Bordes redondeados para la foto
                child: fotoBytes != null
                    ? Image.memory(
                        fotoBytes, // Muestra la imagen desde los bytes en memoria
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover, // Recorta/ajusta para llenar el cuadrado sin deformar
                      )
                    : Container(
                        // Si no hay imagen, muestra un cuadro con ícono de sin imagen
                        width: 72,
                        height: 72,
                        color: AppColors.fondo,
                        child: Icon(
                          MdiIcons.imageOffOutline,
                          color: AppColors.textoNoSeleccionado,
                        ),
                      ),
              ),
              const SizedBox(width: 12), // Separación entre la imagen y los textos
              Expanded(
                // Ocupa el espacio restante para que el texto no se salga de la pantalla
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Alinea textos a la izquierda
                  children: [
                    Row(
                      children: [
                        // Etiqueta de estado ('Perdido' en rojo suave, 'Encontrado' en azul suave)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: esPerdido
                                ? AppColors.perdido
                                : AppColors.encontrado,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            estado,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: esPerdido
                                  ? AppColors.textoOscuro
                                  : AppColors.textoOscuro,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6), // Separación entre ambas etiquetas
                        // Etiqueta de devolución ('Devuelto' en verde, 'No devuelto' en ámbar)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: devuelto
                                ? AppColors.devuelto
                                : AppColors.noDevuelto,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            devuelto ? 'Devuelto' : 'No devuelto',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: devuelto
                                  ? AppColors.textoOscuro
                                  : AppColors.textoOscuro,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5), // Espacio entre etiquetas y título
                    // Título del objeto
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textoOscuro,
                      ),
                      maxLines: 1, // Solo una línea
                      overflow: TextOverflow.ellipsis, // Pone '...' si es muy largo
                    ),
                    const SizedBox(height: 2), // Pequeño espacio entre título y lugar/categoría
                    // Lugar y categoría del objeto
                    Text(
                      '$lugar • $categoria',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textoOscuro,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ?trailing, // Muestra el widget extra si se pasó (por ejemplo, el botón de opciones)
            ],
          ),
        ),
      ),
    );
  }
}