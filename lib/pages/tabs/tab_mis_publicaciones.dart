import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:objetos_perdidos/constants.dart';
import 'package:objetos_perdidos/pages/detalle_objeto_page.dart';
import 'package:objetos_perdidos/services/auth_service.dart';
import 'package:objetos_perdidos/services/fs_service.dart';
import 'package:objetos_perdidos/widgets/card_imagen.dart';

class TabMisPublicaciones extends StatefulWidget {
  const TabMisPublicaciones({super.key});

  @override
  State<TabMisPublicaciones> createState() => _TabMisPublicacionesState();
}

class _TabMisPublicacionesState extends State<TabMisPublicaciones> {
  User? user;
  bool _guardando = false;
  bool _borrando = false;

  @override
  void initState() {
    super.initState();
    AuthService().currentUser().then((currentU) {
      if (!mounted) return;
      setState(() {
        user = currentU;
      });
    });
  }

  void _mostrarDialogoEditar(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final formKey = GlobalKey<FormState>();
    final tituloCtrl = TextEditingController(
      text: (data['titulo'] ?? '').toString(),
    );
    final descripcionCtrl = TextEditingController(
      text: (data['descripcion'] ?? '').toString(),
    );
    final lugarCtrl = TextEditingController(
      text: (data['lugar'] ?? '').toString(),
    );
    String estadoSeleccionado = (data['estado'] ?? 'Perdido').toString();
    bool devueltoSeleccionado = data['devuelto'] == true;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (editDialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Editar publicación',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.primario,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: tituloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'El título es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: lugarCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lugar',
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'El lugar es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descripcionCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'La descripción es obligatoria';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: estadoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Perdido', child: Text('Perdido')),
                        DropdownMenuItem(
                          value: 'Encontrado',
                          child: Text('Encontrado'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setDialogState(() => estadoSeleccionado = valor);
                        }
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('¿Ya fue devuelto?'),
                      value: devueltoSeleccionado,
                      activeTrackColor: AppColors.primario,
                      onChanged: (valor) {
                        setDialogState(() => devueltoSeleccionado = valor);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(editDialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primario,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (_guardando) return;
                  _guardando = true;

                  final navigator = Navigator.of(editDialogContext);
                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    await FsService().editarObjeto(
                      doc.id,
                      tituloCtrl.text.trim(),
                      descripcionCtrl.text.trim(),
                      lugarCtrl.text.trim(),
                      estadoSeleccionado,
                      devueltoSeleccionado,
                    );

                    if (!mounted) return;
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.primario,
                        content: const Text('Publicación actualizada'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Error al actualizar la publicación'),
                      ),
                    );
                  } finally {
                    _guardando = false;
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmarBorrado(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (alertDialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Borrar publicación'),
        content: Text('¿Seguro que quieres borrar "${data['titulo'] ?? ''}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(alertDialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (_borrando) return;
              _borrando = true;

              final navigator = Navigator.of(alertDialogContext);
              final messenger = ScaffoldMessenger.of(context);

              try {
                await FsService().borrarObjeto(doc.id);
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Publicación eliminada'),
                  ),
                );
              } finally {
                _borrando = false;
              }
            },
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FsService().misObjetos(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar tus objetos: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'Aún no tienes publicaciones.',
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
              trailing: PopupMenuButton<String>(
                onSelected: (opcion) {
                  if (opcion == 'editar') {
                    _mostrarDialogoEditar(doc);
                  } else if (opcion == 'borrar') {
                    _confirmarBorrado(doc);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(MdiIcons.pen, color: AppColors.primario, size: 18),
                        const SizedBox(width: 8),
                        const Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'borrar',
                    child: Row(
                      children: [
                        Icon(MdiIcons.trashCan, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Borrar'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}