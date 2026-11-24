import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:objetos_perdidos/constants.dart';
import 'package:objetos_perdidos/pages/detalle_objeto_page.dart';
import 'package:objetos_perdidos/services/fs_service.dart';
import 'package:objetos_perdidos/widgets/card_imagen.dart';

class TabObjetos extends StatefulWidget {
  const TabObjetos({super.key});

  @override
  State<TabObjetos> createState() => _TabObjetosState();
}

class _TabObjetosState extends State<TabObjetos> {
  String _categoriaSeleccionada = 'Todas';
  late final Future<QuerySnapshot> _categoriasFuture;

  @override
  void initState() {
    super.initState();
    _categoriasFuture = FsService().categorias();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: FutureBuilder<QuerySnapshot>(
            future: _categoriasFuture,
            builder: (context, snapshot) {
              final opciones = <DropdownMenuItem<String>>[
                const DropdownMenuItem(
                  value: 'Todas',
                  child: Text('Todas las categorías'),
                ),
              ];

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
                initialValue: _categoriaSeleccionada,
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
                    setState(() => _categoriaSeleccionada = valor);
                  }
                },
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FsService().objetos(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar objetos: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = snapshot.data!.docs;
              if (_categoriaSeleccionada != 'Todas') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['categoria'] == _categoriaSeleccionada;
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No hay objetos en esta categoría.',
                    style: TextStyle(color: AppColors.textoOscuro),
                  ),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return CardImagen(
                    objeto: doc,
                    onTap: () {
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