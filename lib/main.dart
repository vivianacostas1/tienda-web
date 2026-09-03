import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const TiendaApp());
}

// ============================================================
// APP
// ============================================================

class TiendaApp extends StatelessWidget {
  const TiendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CLICK HOGAR',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        scaffoldBackgroundColor:
            const Color(0xfff5f5f3),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7A00),
          brightness: Brightness.light,
        ),

        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFFFF7A00),
          foregroundColor: Colors.white,
        ),
      ),

      home: const TiendaScreen(),
    );
  }
}

// ============================================================
// TIENDA
// ============================================================

class TiendaScreen extends StatefulWidget {
  const TiendaScreen({super.key});

  @override
  State<TiendaScreen> createState() =>
      _TiendaScreenState();
}

class _TiendaScreenState
    extends State<TiendaScreen> {

  // ==========================================================
  // CONFIGURACIÓN
  // ==========================================================

  final String apiUrl =
      'http://localhost:3000/api/tienda-products';

  final String telefonoWhatsApp =
      '59178867110';

  // COLORES (Naranja Corporativo)
  final Color colorPrincipal =
      const Color(0xFFFF7A00);

  final Color colorOscuro =
      const Color(0xff171717);

  // ==========================================================
  // ESTADOS
  // ==========================================================

  List<dynamic> productos = [];
  List<dynamic> productosFiltrados = [];

  bool isLoading = true;
  String errorMessage = '';

  int paginaActual = 0;

  String categoriaSeleccionada = 'Todos';

  final TextEditingController searchController =
      TextEditingController();

  // ==========================================================
  // INICIO
  // ==========================================================

  @override
  void initState() {
    super.initState();
    fetchProductos();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // API
  // ==========================================================

  Future<void> fetchProductos() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          setState(() {
            productos = data;
            productosFiltrados = data;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
                'La API no devolvió una lista de productos.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Error del servidor: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage =
            'No pudimos cargar la tienda.\n\n'
            'Verifica que el backend esté ejecutándose '
            'en http://localhost:3000\n\n'
            'Error: $e';

        isLoading = false;
      });
    }
  }

  // ==========================================================
  // CATEGORÍAS
  // ==========================================================

  List<String> obtenerCategorias() {
    final Set<String> categorias = {'Todos'};

    for (final producto in productos) {
      final categoria =
          producto['category']?.toString().trim();

      if (categoria != null && categoria.isNotEmpty) {
        categorias.add(categoria);
      }
    }

    return categorias.toList();
  }

  // ==========================================================
  // FILTROS
  // ==========================================================

  void filtrarProductos() {
    final texto =
        searchController.text.toLowerCase().trim();

    setState(() {
      productosFiltrados = productos.where((producto) {
        final nombre =
            producto['name']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final sku =
            producto['sku']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final categoria =
            producto['category']
                    ?.toString() ??
                'General';

        final coincideBusqueda =
            nombre.contains(texto) ||
            sku.contains(texto);

        final coincideCategoria =
            categoriaSeleccionada == 'Todos' ||
            categoria == categoriaSeleccionada;

        return coincideBusqueda &&
            coincideCategoria;
      }).toList();
    });
  }

  void seleccionarCategoria(
    String? categoria,
  ) {
    if (categoria == null) return;
    setState(() {
      categoriaSeleccionada = categoria;
    });

    filtrarProductos();
  }

  // ==========================================================
  // OFERTAS
  // ==========================================================

  List<dynamic> obtenerOfertas() {
    return productos.where((producto) {
      final descuento =
          double.tryParse(
                producto['discountPercentage']
                        ?.toString() ??
                    '0',
              ) ??
              0;

      return producto['isOffer'] == true ||
          descuento > 0;
    }).toList();
  }

  // ==========================================================
  // WHATSAPP
  // ==========================================================

  Future<void> abrirWhatsAppGeneral() async {
    final mensaje = Uri.encodeComponent(
      '¡Hola! Me gustaría realizar una consulta o compra en Click Hogar.',
    );

    final url =
        'https://wa.me/$telefonoWhatsApp?text=$mensaje';

    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir WhatsApp',
            ),
          ),
        );
      }
    } catch (e) {
      print('ERROR WHATSAPP: $e');
    }
  }

  Future<void> abrirWhatsApp(
    String nombre,
    dynamic precio,
    String descripcion,
  ) async {
    final mensaje = Uri.encodeComponent(
      '¡Hola! Estoy interesado/a en comprar:\n\n'
      '*$nombre*\n'
      'Precio: \$$precio\n'
      'Detalles: $descripcion\n\n'
      '¿Está disponible?',
    );

    final url =
        'https://wa.me/$telefonoWhatsApp?text=$mensaje';

    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir WhatsApp',
            ),
          ),
        );
      }
    } catch (e) {
      print('ERROR WHATSAPP: $e');
    }
  }

  // ==========================================================
  // IMAGEN PRODUCTO
  // ==========================================================

  Widget imagenProducto(
    dynamic producto, {
    double height = 160,
  }) {
    final imageUrl =
        producto['imageUrl']?.toString();

    if (imageUrl == null ||
        imageUrl.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        color: const Color(0xfff1f1f1),
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 50,
          color: Colors.grey,
        ),
      );
    }

    return Container(
      height: height,
      width: double.infinity,
      color: Colors.white,

      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,

        loadingBuilder:
            (context, child, progress) {
          if (progress == null) {
            return child;
          }

          return Center(
            child: CircularProgressIndicator(
              color: colorPrincipal,
            ),
          );
        },

        errorBuilder:
            (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 50,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // TARJETA PRODUCTO
  // ==========================================================

  Widget tarjetaProducto(
    dynamic producto, {
    bool compact = false,
  }) {
    final nombre =
        producto['name']?.toString() ??
            'Producto';

    final descripcion =
        producto['description']?.toString() ??
            'Sin descripción disponible.';

    final categoria =
        producto['category']?.toString() ??
            'General';

    final precio =
        producto['unitPrice'] ?? 0;

    final precioOriginal =
        producto['originalPrice'] ??
            precio;

    final descuento =
        int.tryParse(
              producto['discountPercentage']
                      ?.toString() ??
                  '0',
            ) ??
            0;

    final stock =
        int.tryParse(
              producto['stock']?.toString() ??
                  '0',
            ) ??
            0;

    final disponible =
        producto['available'] == true &&
        stock > 0;

    final esOferta =
        producto['isOffer'] == true ||
        descuento > 0;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              imagenProducto(
                producto,
                height: compact ? 150 : 180,
              ),

              if (esOferta)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colorPrincipal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      descuento > 0 ? '-$descuento%' : 'OFERTA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoria.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 13 : 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.2,
                    ),
                  ),

                  const Spacer(),

                  if (esOferta && precioOriginal != precio)
                    Text(
                      '\$$precioOriginal',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),

                  Text(
                    '\$$precio',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: compact ? 16 : 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    disponible ? '✓ Disponible' : 'Agotado',
                    style: TextStyle(
                      color: disponible ? Colors.green.shade700 : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: disponible
                          ? () {
                              abrirWhatsApp(
                                nombre,
                                precio,
                                descripcion,
                              );
                            }
                          : null,
                      icon: const Icon(
                        Icons.chat,
                        size: 15,
                      ),
                      label: const Text(
                        'Comprar por WhatsApp',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff25D366),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // GRID PRODUCTOS
  // ==========================================================

  Widget gridProductos(
    List<dynamic> lista,
  ) {
    if (lista.isEmpty) {
      return const Center(
        child: Padding(
          padding:
              EdgeInsets.all(40),

          child: Text(
            'No hay productos para mostrar.',

            style: TextStyle(
              fontSize: 17,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder:
          (context, constraints) {

        int columnas = 4;

        if (constraints.maxWidth <
            1200) {
          columnas = 3;
        }

        if (constraints.maxWidth <
            800) {
          columnas = 2;
        }

        if (constraints.maxWidth <
            520) {
          columnas = 1;
        }

        return GridView.builder(
          shrinkWrap: true,

          physics:
              const NeverScrollableScrollPhysics(),

          itemCount:
              lista.length,

          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                columnas,

            crossAxisSpacing: 18,

            mainAxisSpacing: 18,

            childAspectRatio:
                columnas == 1
                    ? 0.75
                    : columnas == 2
                        ? 0.58
                        : 0.60,
          ),

          itemBuilder:
              (context, index) {
            return tarjetaProducto(
              lista[index],
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // BUSCADOR
  // ==========================================================

  Widget buscador() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),

      child: TextField(
        controller:
            searchController,

        onChanged: (_) {
          filtrarProductos();
        },

        decoration:
            InputDecoration(
          hintText:
              '¿Qué estás buscando?',

          prefixIcon:
              const Icon(
            Icons.search,
          ),

          suffixIcon:
              searchController
                      .text
                      .isNotEmpty
                  ? IconButton(
                      icon:
                          const Icon(
                        Icons.clear,
                      ),

                      onPressed: () {
                        searchController
                            .clear();

                        filtrarProductos();

                        setState(() {});
                      },
                    )
                  : null,

          filled: true,

          fillColor:
              Colors.white,

          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 17,
          ),

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              30,
            ),

            borderSide:
                BorderSide.none,
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              30,
            ),

            borderSide:
                BorderSide(
              color:
                  Colors.grey.shade200,
            ),
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              30,
            ),

            borderSide:
                BorderSide(
              color:
                  colorPrincipal,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CATEGORÍAS (COMBO DESPLEGABLE)
  // ==========================================================

  Widget seccionCategorias() {
    final categorias = obtenerCategorias();

    // Asegurarnos de que la categoría seleccionada actual exista en la lista
    if (!categorias.contains(categoriaSeleccionada)) {
      categoriaSeleccionada = 'Todos';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explora por categoría',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: categoriaSeleccionada,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: categorias.map((String categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria,
                    child: Text(
                      categoria,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? nuevaCategoria) {
                  seleccionarCategoria(nuevaCategoria);
                  setState(() {
                    paginaActual = 1;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HERO PRINCIPAL
  // ==========================================================

  Widget heroPrincipal() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final esMovil = constraints.maxWidth < 700;

        return Container(
          width: double.infinity,
          height: esMovil ? 450 : 500,
          decoration: const BoxDecoration(
            color: Color(0xff181818),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: esMovil ? 25 : 70,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 700,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo_click_hogar.png',
                          height: esMovil ? 75 : 95,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Todo para tu hogar, al mejor precio',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: esMovil ? 30 : 46,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Encuentra productos de calidad, excelentes precios y compra fácilmente desde Click Hogar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: esMovil ? 15 : 17,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              paginaActual = 1;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrincipal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 35,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'VER CATÁLOGO  →',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // PIE DE PÁGINA (DESARROLLADO POR)
  // ==========================================================

  Widget pieDePaginaDesarrollo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      color: const Color(0xff181818),
      child: Center(
        child: Text(
          'Desarrollado por A&A SOLUTIONS TEL. 73016551',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ==========================================================
  // INICIO
  // ==========================================================

  Widget paginaInicio() {
    final ofertas =
        obtenerOfertas();

    final destacados =
        productos.take(4).toList();

    return RefreshIndicator(
      onRefresh:
          fetchProductos,

      child:
          SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding: EdgeInsets.zero,

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            heroPrincipal(),

            const SizedBox(
              height: 35,
            ),

            buscador(),

            const SizedBox(
              height: 30,
            ),

            seccionCategorias(),

            const SizedBox(
              height: 40,
            ),

            if (ofertas.isNotEmpty) ...[

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [

                    const Text(
                      'Ofertas especiales',

                      style:
                          TextStyle(
                        fontSize: 27,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        setState(() {
                          paginaActual = 2;
                        });
                      },

                      child:
                          const Text(
                        'Ver todas →',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              SizedBox(
                height: 470,

                child:
                    ListView.builder(
                  scrollDirection:
                      Axis.horizontal,

                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 20,
                  ),

                  itemCount:
                      ofertas.length,

                  itemBuilder:
                      (context, index) {

                    return SizedBox(
                      width: 275,

                      child:
                          tarjetaProducto(
                        ofertas[index],
                        compact: true,
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(
              height: 45,
            ),

            const Padding(
              padding:
                  EdgeInsets.symmetric(
                    horizontal: 20,
                  ),

              child: Text(
                'Productos destacados',

                style:
                    TextStyle(
                  fontSize: 27,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),

              child:
                  gridProductos(
                destacados,
              ),
            ),

            const SizedBox(
              height: 50,
            ),

            pieDePaginaDesarrollo(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CATÁLOGO
  // ==========================================================

  Widget paginaCatalogo() {
    return RefreshIndicator(
      onRefresh: fetchProductos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              decoration: BoxDecoration(
                color: colorPrincipal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Catálogo',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Encuentra todos nuestros productos para el hogar.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            buscador(),

            const SizedBox(
              height: 25,
            ),

            seccionCategorias(),

            const SizedBox(
              height: 25,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: gridProductos(
                productosFiltrados,
              ),
            ),

            const SizedBox(
              height: 50,
            ),

            pieDePaginaDesarrollo(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // OFERTAS
  // ==========================================================

  Widget paginaOfertas() {
    final ofertas =
        obtenerOfertas();

    return SingleChildScrollView(
      padding: EdgeInsets.zero,

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Padding(
            padding:
                EdgeInsets.fromLTRB(
              20,
              30,
              20,
              5,
            ),

            child: Text(
              'Ofertas',

              style:
                  TextStyle(
                fontSize: 32,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),

          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 20,
            ),

            child: Text(
              'Aprovecha nuestros precios especiales.',

              style:
                  TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ),

          const SizedBox(
            height: 30,
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),

            child:
                gridProductos(
              ofertas,
            ),
          ),

          const SizedBox(
            height: 50,
          ),

          pieDePaginaDesarrollo(),
        ],
      ),
    );
  }

  // ==========================================================
  // APP BAR (SIN FAVORITOS NI IDIOMA)
  // ==========================================================

  PreferredSizeWidget barraSuperior() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(76),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final esMovil = constraints.maxWidth < 800;

          final widgetLogoTexto = GestureDetector(
            onTap: () {
              setState(() {
                paginaActual = 0;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo_click_hogar.png',
                  height: 35,
                ),
                const SizedBox(width: 10),
                const Text(
                  'CLICK HOGAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );

          if (esMovil) {
            return AppBar(
              backgroundColor: colorPrincipal,
              foregroundColor: Colors.white,
              title: widgetLogoTexto,
              actions: [
                IconButton(
                  tooltip: 'Buscar',
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      paginaActual = 1;
                    });
                  },
                ),
                Builder(
                  builder: (context) {
                    return IconButton(
                      tooltip: 'Menú',
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    );
                  },
                ),
              ],
            );
          }

          return Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 35),
            color: colorPrincipal,
            child: Row(
              children: [
                widgetLogoTexto,
                const Spacer(),
                _menuItemColorido('Hogar', () {
                  setState(() {
                    paginaActual = 0;
                  });
                }),
                _menuItemColorido('Productos', () {
                  setState(() {
                    paginaActual = 1;
                  });
                }),
                _menuItemColorido('Ofertas', () {
                  setState(() {
                    paginaActual = 2;
                  });
                }),
                const SizedBox(width: 15),
                IconButton(
                  tooltip: 'Buscar',
                  icon: const Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      paginaActual = 1;
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _menuItemColorido(
    String texto,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          child: Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // MENU MOVIL (SIN FAVORITOS)
  // ==========================================================

  Widget menuMovil() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Padding(
              padding:
                  const EdgeInsets.all(
                25,
              ),

              child: Row(
                children: [

                  Image.asset(
                    'assets/images/logo_click_hogar.png',
                    height: 35,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'CLICK HOGAR',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const Spacer(),

                  IconButton(
                    icon:
                        const Icon(
                      Icons.close,
                    ),

                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(),

            _itemMenuMovil(
              Icons.home_outlined,
              'Hogar',
              0,
            ),

            _itemMenuMovil(
              Icons.shopping_bag_outlined,
              'Productos',
              1,
            ),

            _itemMenuMovil(
              Icons.local_offer_outlined,
              'Ofertas',
              2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemMenuMovil(
    IconData icon,
    String texto,
    int pagina,
  ) {
    return ListTile(
      leading:
          Icon(icon),

      title:
          Text(
        texto,

        style:
            const TextStyle(
          fontWeight:
              FontWeight.w600,
        ),
      ),

      onTap: () {
        Navigator.pop(
          context,
        );

        setState(() {
          paginaActual = pagina;
        });
      },
    );
  }

  // ==========================================================
  // NAVEGACIÓN INFERIOR MOVIL (SIN FAVORITOS)
  // ==========================================================

  Widget barraNavegacion() {
    return NavigationBar(
      backgroundColor:
          Colors.white,

      indicatorColor:
          colorPrincipal,

      selectedIndex:
          paginaActual > 2 ? 0 : paginaActual,

      onDestinationSelected:
          (index) {
        setState(() {
          paginaActual = index;
        });
      },

      destinations:
          const [

        NavigationDestination(
          icon:
              Icon(
            Icons.home_outlined,
          ),

          selectedIcon:
              Icon(
            Icons.home,
          ),

          label:
              'Inicio',
        ),

        NavigationDestination(
          icon:
              Icon(
            Icons.shopping_bag_outlined,
          ),

          selectedIcon:
              Icon(
            Icons.shopping_bag,
          ),

          label:
              'Catálogo',
        ),

        NavigationDestination(
          icon:
              Icon(
            Icons.local_offer_outlined,
          ),

          selectedIcon:
              Icon(
            Icons.local_offer,
          ),

          label:
              'Ofertas',
        ),
      ],
    );
  }

  // ==========================================================
  // CONTENIDO
  // ==========================================================

  Widget contenido() {
    if (isLoading) {
      return Center(
        child:
            CircularProgressIndicator(
          color:
              colorPrincipal,
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            30,
          ),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              const Icon(
                Icons.cloud_off,
                size: 70,
                color: Colors.red,
              ),

              const SizedBox(
                height: 20,
              ),

              Text(
                errorMessage,

                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  color: Colors.red,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              ElevatedButton.icon(
                onPressed:
                    fetchProductos,

                icon:
                    const Icon(
                  Icons.refresh,
                ),

                label:
                    const Text(
                  'Reintentar',
                ),
              ),
            ],
          ),
        ),
      );
    }

    switch (paginaActual) {
      case 1:
        return paginaCatalogo();

      case 2:
        return paginaOfertas();

      default:
        return paginaInicio();
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: barraSuperior(),
      drawer: menuMovil(),
      body: contenido(),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: abrirWhatsAppGeneral,
        backgroundColor: const Color(0xff25D366),
        icon: const Icon(Icons.chat, color: Colors.white),
        label: const Text(
          'Comprar por WhatsApp',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      bottomNavigationBar:
          MediaQuery.of(context).size.width < 800
              ? barraNavegacion()
              : null,
    );
  }
}