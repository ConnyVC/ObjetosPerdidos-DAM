import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:objetos_perdidos/constants.dart';
import 'package:objetos_perdidos/services/auth_service.dart';
import 'package:objetos_perdidos/services/fs_service.dart';

class AgregarObjetoPage extends StatefulWidget {
  const AgregarObjetoPage({super.key});

  @override
  State<AgregarObjetoPage> createState() => _AgregarObjetoPageState();
}

class _AgregarObjetoPageState extends State<AgregarObjetoPage> {
  static const int _maxBytesFoto = 900 * 1024; // ~900 KB para mantener documento < 1 MB

  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();

  String _estadoSeleccionado = 'Perdido';
  String? _categoriaSeleccionada;
  Uint8List? _fotoBytes;
  bool _guardando = false;

  final ImagePicker _picker = ImagePicker();
  late final Future<QuerySnapshot> _categoriasFuture;

  @override
  void initState() {
    super.initState();
    _categoriasFuture = FsService().categorias();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _lugarCtrl.dispose();
    super.dispose();
  }

  void _mostrarAvisoTamano() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          'La foto supera el tamaño permitido (el documento debe pesar menos de 1 MB).',
        ),
      ),
    );
  }

  Future<void> _seleccionarFoto(ImageSource fuente) async {
    final XFile? imagen = await _picker.pickImage(
      source: fuente,
      maxWidth: 1024,
      imageQuality: 65,
    );

    if (imagen == null) return;

    final Uint8List bytes = await imagen.readAsBytes();
    if (!mounted) return;

    if (bytes.lengthInBytes > _maxBytesFoto) {
      _mostrarAvisoTamano();
      return;
    }

    setState(() {
      _fotoBytes = bytes;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fotoBytes == null || _fotoBytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Debes tomar o seleccionar una foto'),
        ),
      );
      return;
    }

    if (_fotoBytes!.lengthInBytes > _maxBytesFoto) {
      _mostrarAvisoTamano();
      return;
    }

    if (_guardando) return;
    setState(() => _guardando = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      User? user = await AuthService().currentUser();
      if (user == null) return;

      await FsService().agregarObjeto(
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        lugar: _lugarCtrl.text.trim(),
        categoria: _categoriaSeleccionada!,
        estado: _estadoSeleccionado,
        fotoBytes: _fotoBytes!,
        autorUid: user.uid,
        autorNombre: user.displayName ?? 'Usuario',
        autorEmail: user.email ?? '',
      );

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primario,
          content: const Text('Objeto publicado correctamente'),
        ),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al guardar el objeto'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.primario,
        foregroundColor: Colors.white,
        title: const Text('Publicar Objeto'),
      ),
      body: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _estadoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Perdido', child: Text('Perdido')),
                  DropdownMenuItem(value: 'Encontrado', child: Text('Encontrado')),
                ],
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() => _estadoSeleccionado = valor);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ej: Botella térmica azul',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Detalles o señas del objeto',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lugarCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lugar',
                  hintText: 'Ej: Patio Central / Sala B-102',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'El lugar es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<QuerySnapshot>(
                future: _categoriasFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Error al cargar categorías: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting ||
                      !snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Cargando categorías...'),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No hay categorías registradas en Firestore.'),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _categoriaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null) {
                        return 'Selecciona una categoría';
                      }
                      return null;
                    },
                    items: docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final nombre = (d['nombre'] ?? 'Sin nombre').toString();
                      return DropdownMenuItem<String>(
                        value: nombre,
                        child: Text(nombre),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setState(() => _categoriaSeleccionada = valor);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _seleccionarFoto(ImageSource.camera),
                      icon: Icon(MdiIcons.camera, color: AppColors.primario),
                      label: Text(
                        'Cámara',
                        style: TextStyle(color: AppColors.textoOscuro),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _seleccionarFoto(ImageSource.gallery),
                      icon: Icon(MdiIcons.image, color: AppColors.primario),
                      label: Text(
                        'Galería',
                        style: TextStyle(color: AppColors.textoOscuro),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_fotoBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    _fotoBytes!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.fondo,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      'Sin foto seleccionada',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primario,
                    foregroundColor: Colors.white,
                  ),
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(MdiIcons.contentSave),
                  label: Text(_guardando ? 'Guardando...' : 'Publicar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}