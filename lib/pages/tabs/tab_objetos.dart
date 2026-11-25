import 'package:cloud_firestore/cloud_firestore.dart'; // Para QuerySnapshot y documentos de Firestore
import 'package:flutter/material.dart'; // Widgets básicos de Flutter
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart'; // Íconos
import 'package:objetos_perdidos/constants.dart'; // Colores personalizados de la app
import 'package:objetos_perdidos/pages/detalle_objeto_page.dart'; // Pantalla para ver el detalle de un objeto
import 'package:objetos_perdidos/services/fs_service.dart'; // Servicio con consultas a Firestore
import 'package:objetos_perdidos/widgets/card_imagen.dart'; // Tarjeta reutilizable de cada objeto

class TabObjetos extends StatefulWidget {
  // Pestaña con estado porque guarda la categoría elegida para filtrar
  const TabObjetos({super.key});

  @override
  State<TabObjetos> createState() => _TabObjetosState();
}

class _TabObjetosState extends State<TabObjetos> {
  String _categoriaSeleccionada = 'Todas'; // Filtro inicial: muestra todas las categorías
  late final Future<QuerySnapshot> _categoriasFuture; // Guarda la consulta futura de categorías

  @override
  void initState() {
    super.initState();
    // Carga las categorías una sola vez al iniciar la pestaña
    _categoriasFuture = FsService().categorias();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Caja blanca superior con el filtro desplegable por categoría
        Container(
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.textoClaro,
            borderRadius: BorderRadius.circular(12),
          ),
          child: FutureBuilder<QuerySnapshot>(
            future: _categoriasFuture,
            builder: (context, snapshot) {
              // Siempre empieza con la opción 'Todas las categorías'
              final opciones = <DropdownMenuItem<String>>[
                const DropdownMenuItem(
                  value: 'Todas',
                  child: Text('Todas las categorías'),
                ),
              ];

              // Cuando llegan las categorías desde Firestore, agrega cada una al desplegable
              if (snapshot.hasData) {
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre = (data['nombre'] ?? '').toString();
                  if (nombre.isNotEmpty) {
                    opciones.add(
                      DropdownMenuItem<String>(
                        value: nombre,
                        child: Text(nombre),
                      ),
                    );
                  }
                }
              }

              return DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada, // Categoría seleccionada actualmente
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    MdiIcons.filterVariant,
                    color: AppColors.primario,
                  ),
                  labelText: 'Filtrar por categoría',
                  border: InputBorder.none,
                ),
                items: opciones,
                onChanged: (valor) {
                  if (valor != null) {
                    // Actualiza el filtro y vuelve a dibujar la lista
                    setState(() => _categoriaSeleccionada = valor);
                  }
                },
              );
            },
          ),
        ),
        // Ocupa el resto de la pantalla con la lista en tiempo real de objetos
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FsService().objetos(), // Escucha cambios en tiempo real de 'objetos'
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // Muestra error si falla el stream de Firestore
                return Center(
                  child: Text(
                    'Error al cargar objetos: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.terciario),
                  ),
                );
              }

              // Mientras espera los primeros datos del stream
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = snapshot.data!.docs; // Lista de documentos recibidos desde Firestore

              // Si hay una categoría específica seleccionada, filtra la lista por ese campo
              if (_categoriaSeleccionada != 'Todas') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['categoria'] == _categoriaSeleccionada;
                }).toList();
              }

              // Si tras filtrar no quedan elementos, muestra un mensaje
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No hay objetos en esta categoría.',
                    style: TextStyle(color: AppColors.textoOscuro),
                  ),
                );
              }

              // Construye la lista deslizable solo con los elementos visibles (eficiente con ListView.builder)
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index]; // Documento correspondiente a esta fila
                  return CardImagen(
                    objeto: doc, // Pasa el documento a la tarjeta
                    onTap: () {
                      // Al tocar la tarjeta, abre DetalleObjetoPage pasando el documento
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalleObjetoPage(objeto: doc),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}