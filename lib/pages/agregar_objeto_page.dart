import 'dart:typed_data'; // Para manejar los bytes de la imagen (Uint8List)
import 'package:cloud_firestore/cloud_firestore.dart'; // Para QuerySnapshot de categorías
import 'package:firebase_auth/firebase_auth.dart'; // Para el tipo User del usuario autenticado
import 'package:flutter/material.dart'; // Widgets básicos de Flutter
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart'; // Íconos
import 'package:image_picker/image_picker.dart'; // Para tomar foto con cámara o elegir de galería
import 'package:objetos_perdidos/constants.dart'; // Colores personalizados de la app
import 'package:objetos_perdidos/services/auth_service.dart'; // Para obtener el usuario actual
import 'package:objetos_perdidos/services/fs_service.dart'; // Para consultar categorías y guardar el objeto

class AgregarObjetoPage extends StatefulWidget {
  // Pantalla con estado porque maneja campos del formulario, foto y estado de guardado
  const AgregarObjetoPage({super.key});

  @override
  State<AgregarObjetoPage> createState() => _AgregarObjetoPageState();
}

class _AgregarObjetoPageState extends State<AgregarObjetoPage> {
  // Límite de ~900 KB para que el documento completo en Firestore pese menos de 1 MB
  static const int _maxBytesFoto = 900 * 1024;

  final _formKey = GlobalKey<FormState>(); // Clave para validar todos los campos del formulario
  final _tituloCtrl = TextEditingController(); // Controla el texto del campo Título
  final _descripcionCtrl = TextEditingController(); // Controla el texto del campo Descripción
  final _lugarCtrl = TextEditingController(); // Controla el texto del campo Lugar

  String _estadoSeleccionado = 'Perdido'; // Estado inicial del desplegable ('Perdido' o 'Encontrado')
  String? _categoriaSeleccionada; // Categoría elegida por el usuario
  Uint8List? _fotoBytes; // Bytes de la foto seleccionada o tomada
  bool _guardando = false; // Evita que se envíe el formulario dos veces seguidas

  final ImagePicker _picker = ImagePicker(); // Herramienta para abrir cámara o galería
  late final Future<QuerySnapshot> _categoriasFuture; // Guarda la consulta futura de categorías

  @override
  void initState() {
    super.initState();
    // Carga las categorías una vez al abrir la pantalla para no repetir la consulta en cada rebuild
    _categoriasFuture = FsService().categorias();
  }

  @override
  void dispose() {
    // Libera la memoria de los controladores de texto cuando se cierra la pantalla
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _lugarCtrl.dispose();
    super.dispose();
  }

  // Muestra una barra roja inferior si la foto excede el tamaño máximo permitido
  void _mostrarAvisoTamano() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.terciario,
        content: Text(
          'La foto supera el tamaño permitido (el documento debe pesar menos de 1 MB).',
        ),
      ),
    );
  }

  // Abre la cámara o galería, comprime la imagen y valida que no supere _maxBytesFoto
  Future<void> _seleccionarFoto(ImageSource fuente) async {
    final XFile? imagen = await _picker.pickImage(
      source: fuente, // ImageSource.camera o ImageSource.gallery
      maxWidth: 1024, // Reduce el ancho máximo para bajar el peso de la imagen
      imageQuality: 65, // Comprime calidad al 65%
    );

    if (imagen == null) return; // Si el usuario canceló, no hace nada

    final Uint8List bytes = await imagen.readAsBytes(); // Lee la imagen como bytes
    if (!mounted) return;

    if (bytes.lengthInBytes > _maxBytesFoto) {
      _mostrarAvisoTamano(); // Avisa si sigue siendo muy pesada
      return;
    }

    setState(() {
      _fotoBytes = bytes; // Guarda la foto válida y redibuja la vista previa
    });
  }

  // Valida todo, obtiene el usuario actual y guarda el nuevo objeto en Firestore
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return; // Si algún campo obligatorio falla, se detiene

    // Verifica que exista una foto seleccionada
    if (_fotoBytes == null || _fotoBytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.terciario,
          content: Text('Debes tomar o seleccionar una foto'),
        ),
      );
      return;
    }

    // Vuelve a comprobar el tamaño antes de enviar a Firestore
    if (_fotoBytes!.lengthInBytes > _maxBytesFoto) {
      _mostrarAvisoTamano();
      return;
    }

    if (_guardando) return; // Evita doble clic mientras ya está guardando
    setState(() => _guardando = true); // Activa estado de carga y bloquea el botón

    final messenger = ScaffoldMessenger.of(context); // Guarda referencia antes de operaciones asíncronas
    final navigator = Navigator.of(context); // Guarda referencia de navegación antes de await

    try {
      User? user = await AuthService().currentUser(); // Obtiene el usuario autenticado
      if (user == null) return; // Si no hay usuario, corta el guardado

      // Envía todos los datos y la foto en bytes a Firestore mediante FsService
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
      navigator.pop(); // Regresa a HomePage tras publicar
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.terciario,
          content: Text('Error al guardar el objeto'),
        ),
      );
    } finally {
      // Siempre apaga el indicador de guardado si el widget sigue montado
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo, // Fondo de la pantalla
      appBar: AppBar(
        backgroundColor: AppColors.primario, // Barra superior
        foregroundColor: AppColors.textoClaro,
        title: const Text('Publicar Objeto'),
      ),
      body: Container(
        // Contenedor blanco redondeado que envuelve el formulario
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.textoClaro,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Form(
          key: _formKey, // Asocia la clave del formulario
          child: ListView(
            children: [
              // Selector de estado ('Perdido' o 'Encontrado')
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
              // Campo de título obligatorio
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
              // Campo de descripción obligatorio con 3 líneas de alto
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
              // Campo de lugar obligatorio
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
              // Construye el selector de categorías según el estado de _categoriasFuture
              FutureBuilder<QuerySnapshot>(
                future: _categoriasFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    // Muestra error si falló la lectura en Firestore
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Error al cargar categorías: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.terciario, fontSize: 12),
                      ),
                    );
                  }

                  // Mientras espera las categorías desde Firestore
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      !snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Cargando categorías...'),
                    );
                  }

                  final docs = snapshot.data!.docs; // Lista de documentos de categorías
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No hay categorías registradas en Firestore.'),
                    );
                  }

                  // Desplegable con las categorías obtenidas de Firestore
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
              // Botones para elegir foto desde cámara o galería
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
              // Vista previa de la foto si ya se eligió; si no, cuadro indicando que falta
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
                    border: Border.all(color: AppColors.textoOscuro),
                  ),
                  child: Center(
                    child: Text(
                      'Sin foto seleccionada',
                      style: TextStyle(color: AppColors.textoOscuro),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // Botón principal para publicar; se deshabilita mientras _guardando es true
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primario,
                    foregroundColor: AppColors.textoClaro,
                  ),
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: AppColors.textoClaro,
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