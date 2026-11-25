import 'package:cloud_firestore/cloud_firestore.dart'; // Para QuerySnapshot y documentos de Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Para el tipo User del usuario autenticado
import 'package:flutter/material.dart'; // Widgets básicos de Flutter
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart'; // Íconos
import 'package:objetos_perdidos/constants.dart'; // Colores personalizados de la app
import 'package:objetos_perdidos/pages/detalle_objeto_page.dart'; // Pantalla para ver el detalle de un objeto
import 'package:objetos_perdidos/services/auth_service.dart'; // Para obtener el usuario actual
import 'package:objetos_perdidos/services/fs_service.dart'; // Para editar y borrar objetos en Firestore
import 'package:objetos_perdidos/widgets/card_imagen.dart'; // Tarjeta reutilizable de cada publicación

class TabMisPublicaciones extends StatefulWidget {
  // Pestaña con estado porque guarda el usuario actual y evita dobles clics al guardar o borrar
  const TabMisPublicaciones({super.key});

  @override
  State<TabMisPublicaciones> createState() => _TabMisPublicacionesState();
}

class _TabMisPublicacionesState extends State<TabMisPublicaciones> {
  User? user; // Usuario que inició sesión
  bool _guardando = false; // Evita enviar dos veces la edición al mismo tiempo
  bool _borrando = false; // Evita borrar dos veces seguidas por doble toque

  @override
  void initState() {
    super.initState();
    // Consulta el usuario actual al abrir la pestaña
    AuthService().currentUser().then((currentU) {
      if (!mounted) return; // Si la pantalla ya se cerró, no actualiza estado
      setState(() {
        user = currentU; // Guarda el usuario y permite escuchar sus publicaciones
      });
    });
  }

  // Abre una ventana emergente para editar los datos de una publicación propia
  void _mostrarDialogoEditar(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>; // Datos actuales del documento
    final formKey = GlobalKey<FormState>(); // Clave para validar los campos del diálogo
    // Controladores precargados con los valores actuales del objeto
    final tituloCtrl = TextEditingController(
      text: (data['titulo'] ?? '').toString(),
    );
    final descripcionCtrl = TextEditingController(
      text: (data['descripcion'] ?? '').toString(),
    );
    final lugarCtrl = TextEditingController(
      text: (data['lugar'] ?? '').toString(),
    );
    String estadoSeleccionado = (data['estado'] ?? 'Perdido').toString(); // Estado actual
    bool devueltoSeleccionado = data['devuelto'] == true; // Estado de devolución actual

    showDialog(
      barrierDismissible: false, // Obliga a usar Cancelar o Guardar para cerrar el diálogo
      context: context,
      builder: (editDialogContext) => StatefulBuilder(
        // Permite actualizar solo el contenido del diálogo (como el Switch o el Dropdown)
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.textoClaro,
            title: Text(
              'Editar publicación',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.primario,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              // Evita desbordes si aparece el teclado del teléfono
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo de título obligatorio
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
                    // Campo de lugar obligatorio
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
                    // Campo de descripción obligatorio
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
                    // Selector de estado ('Perdido' o 'Encontrado')
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
                          setDialogState(() => estadoSeleccionado = valor); // Actualiza el selector en el diálogo
                        }
                      },
                    ),
                    // Interruptor para marcar o desmarcar si el objeto ya fue devuelto
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('¿Ya fue devuelto?'),
                      value: devueltoSeleccionado,
                      activeTrackColor: AppColors.primario,
                      onChanged: (valor) {
                        setDialogState(() => devueltoSeleccionado = valor); // Cambia el interruptor en el diálogo
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // Cierra el diálogo sin guardar cambios
              TextButton(
                onPressed: () => Navigator.pop(editDialogContext),
                child: const Text('Cancelar'),
              ),
              // Valida y guarda los cambios en Firestore
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primario,
                  foregroundColor: AppColors.textoClaro,
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return; // Detiene si hay campos vacíos
                  if (_guardando) return; // Evita guardar dos veces seguidas
                  _guardando = true;

                  final navigator = Navigator.of(editDialogContext); // Referencia del diálogo antes de await
                  final messenger = ScaffoldMessenger.of(context); // Referencia para mostrar SnackBar

                  try {
                    // Actualiza el documento en Firestore por su id
                    await FsService().editarObjeto(
                      doc.id,
                      tituloCtrl.text.trim(),
                      descripcionCtrl.text.trim(),
                      lugarCtrl.text.trim(),
                      estadoSeleccionado,
                      devueltoSeleccionado,
                    );

                    if (!mounted) return;
                    navigator.pop(); // Cierra el diálogo al guardar con éxito
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
                        backgroundColor: AppColors.terciario,
                        content: Text('Error al actualizar la publicación'),
                      ),
                    );
                  } finally {
                    _guardando = false; // Libera el bloqueo aunque ocurra un error
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

  // Pide confirmación antes de borrar definitivamente una publicación de Firestore
  void _confirmarBorrado(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    showDialog(
      barrierDismissible: false, // Evita cerrar accidentalmente tocando fuera
      context: context,
      builder: (alertDialogContext) => AlertDialog(
        backgroundColor: AppColors.textoClaro,
        title: const Text('Borrar publicación'),
        content: Text('¿Seguro que quieres borrar "${data['titulo'] ?? ''}"?'),
        actions: [
          // Cancela y cierra el diálogo
          TextButton(
            onPressed: () => Navigator.pop(alertDialogContext),
            child: const Text('Cancelar'),
          ),
          // Elimina el documento en Firestore
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terciario,
              foregroundColor: AppColors.textoClaro,
            ),
            onPressed: () async {
              if (_borrando) return; // Evita doble borrado
              _borrando = true;

              final navigator = Navigator.of(alertDialogContext);
              final messenger = ScaffoldMessenger.of(context);

              try {
                await FsService().borrarObjeto(doc.id); // Borra el documento por su id
                if (!mounted) return;
                navigator.pop(); // Cierra el diálogo de confirmación
                messenger.showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.terciario,
                    content: Text('Publicación eliminada'),
                  ),
                );
              } finally {
                _borrando = false; // Libera el estado de borrado
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
    // Si todavía no se carga el usuario actual, muestra un indicador de carga
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Escucha en tiempo real solo los documentos cuyo autorUid sea igual al uid del usuario
    return StreamBuilder<QuerySnapshot>(
      stream: FsService().misObjetos(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Muestra mensaje si ocurre un error en Firestore
          return Center(
            child: Text(
              'Error al cargar tus objetos: ${snapshot.error}',
              style: const TextStyle(color: AppColors.terciario),
            ),
          );
        }

        // Mientras espera los primeros datos del stream
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs; // Lista de publicaciones del usuario actual
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'Aún no tienes publicaciones.',
              style: TextStyle(color: AppColors.textoOscuro),
            ),
          );
        }

        // Construye la lista de publicaciones propias
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return CardImagen(
              objeto: doc,
              onTap: () {
                // Abre el detalle completo del objeto al tocar la tarjeta
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetalleObjetoPage(objeto: doc),
                  ),
                );
              },
              // Menú de tres puntos a la derecha para editar o borrar esta publicación
              trailing: PopupMenuButton<String>(
                onSelected: (opcion) {
                  if (opcion == 'editar') {
                    _mostrarDialogoEditar(doc); // Abre diálogo de edición
                  } else if (opcion == 'borrar') {
                    _confirmarBorrado(doc); // Abre confirmación de borrado
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
                        Icon(MdiIcons.trashCan, color: AppColors.terciario, size: 18),
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