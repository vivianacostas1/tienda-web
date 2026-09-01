import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const TiendaApp());
}

class TiendaApp extends StatelessWidget {
  const TiendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KUÑAS STORE LA PAZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff7f7fb),
      ),
      home: const TiendaScreen(),
    );
  }
}

class TiendaScreen extends StatefulWidget {
  const TiendaScreen({super.key});

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  // ============================================================
  // CONFIGURACIÓN
  // ============================================================

  final String apiUrl =
      'http://localhost:3000/api/tienda-products';

  final String telefonoWhatsApp = '59178867110';

  // ============================================================
  // ESTADOS
  // ============================================================

  List<dynamic> productos = [];
  List<dynamic> productosFiltrados = [];

  final Set<String> favoritos = {};

  bool isLoading = true;
  String errorMessage = '';

  int paginaActual = 0;

  String categoriaSeleccionada = 'Todos';

  final TextEditingController searchController =
      TextEditingController();

  // ============================================================
  // INICIO
  // ============================================================

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

  // ============================================================
  // API
  // ============================================================

  Future<void> fetchProductos() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print('====================================');
      print('CONECTANDO CON API');
      print(apiUrl);
      print('====================================');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
        },
      );

      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');

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
      print('ERROR AL CONECTAR CON LA API: $e');

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

  // ============================================================
  // CATEGORÍAS
  // ============================================================

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

  // ============================================================
  // FILTROS
  // ============================================================

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
            producto['category']?.toString() ??
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

  void seleccionarCategoria(String categoria) {
    setState(() {
      categoriaSeleccionada = categoria;
    });

    filtrarProductos();
  }

  // ============================================================
  // FAVORITOS
  // ============================================================

  void toggleFavorito(String id) {
    setState(() {
      if (favoritos.contains(id)) {
        favoritos.remove(id);
      } else {
        favoritos.add(id);
      }
    });
  }

  List<dynamic> obtenerFavoritos() {
    return productos.where((producto) {
      final id = producto['id']?.toString();

      return id != null && favoritos.contains(id);
    }).toList();
  }

  // ============================================================
  // OFERTAS
  // ============================================================

  List<dynamic> obtenerOfertas() {
    return productos.where((producto) {
      return producto['isOffer'] == true ||
          (producto['discountPercentage'] ?? 0) > 0;
    }).toList();
  }

  // ============================================================
  // WHATSAPP
  // ============================================================

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

  // ============================================================
  // IMAGEN
  // ============================================================

  Widget imagenProducto(
    dynamic producto, {
    double height = 180,
  }) {
    final imageUrl =
        producto['imageUrl']?.toString();

    if (imageUrl == null ||
        imageUrl.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        color: Colors.deepPurple.shade50,
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 55,
          color: Colors.deepPurple,
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

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        errorBuilder:
            (context, error, stackTrace) {
          print(
            'ERROR IMAGEN CLOUDINARY: $imageUrl',
          );

          return const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 55,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TARJETA PRODUCTO
  // ============================================================

  Widget tarjetaProducto(
    dynamic producto, {
    bool compact = false,
  }) {
    final id =
        producto['id']?.toString() ?? '';

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
        producto['originalPrice'] ?? precio;

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

    final esFavorito =
        favoritos.contains(id);

    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          // IMAGEN
          Stack(
            children: [
              imagenProducto(
                producto,
                height:
                    compact ? 150 : 190,
              ),

              if (esOferta)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.red,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      descuento > 0
                          ? '-$descuento%'
                          : 'OFERTA',
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration:
                      const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      esFavorito
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: esFavorito
                          ? Colors.red
                          : Colors.grey,
                    ),
                    onPressed: () {
                      toggleFavorito(id);
                    },
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding:
                const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  categoria,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        Colors.deepPurple.shade600,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  nombre,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize:
                        compact ? 14 : 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                if (!compact)
                  Text(
                    descripcion,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),

                const SizedBox(height: 8),

                if (esOferta &&
                    precioOriginal != precio)
                  Text(
                    '\$$precioOriginal',
                    style: TextStyle(
                      color:
                          Colors.grey.shade500,
                      fontSize: 12,
                      decoration:
                          TextDecoration
                              .lineThrough,
                    ),
                  ),

                Text(
                  '\$$precio',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize:
                        compact ? 18 : 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  disponible
                      ? '✓ Disponible'
                      : 'Agotado',
                  style: TextStyle(
                    color: disponible
                        ? Colors.green
                        : Colors.red,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
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
                      size: 17,
                    ),
                    label: const Text(
                      'Comprar',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.green,
                      foregroundColor:
                          Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRID DE PRODUCTOS
  // ============================================================

  Widget gridProductos(
    List<dynamic> lista,
  ) {
    if (lista.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
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

        if (constraints.maxWidth < 1200) {
          columnas = 3;
        }

        if (constraints.maxWidth < 800) {
          columnas = 2;
        }

        if (constraints.maxWidth < 520) {
          columnas = 1;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: lista.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio:
                columnas == 1
                    ? 0.85
                    : 0.62,
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

  // ============================================================
  // BUSCADOR
  // ============================================================

  Widget buscador() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ),
      child: TextField(
        controller: searchController,
        onChanged: (_) {
          filtrarProductos();
        },
        decoration: InputDecoration(
          hintText:
              '¿Qué estás buscando?',
          prefixIcon:
              const Icon(Icons.search),
          suffixIcon:
              searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                      ),
                      onPressed: () {
                        searchController
                            .clear();
                        filtrarProductos();
                      },
                    )
                  : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(18),
            borderSide:
                BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECCIÓN CATEGORÍAS
  // ============================================================

  Widget seccionCategorias() {
    final categorias =
        obtenerCategorias();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Text(
            'Explora por categoría',
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection:
                Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            itemCount:
                categorias.length,
            itemBuilder:
                (context, index) {
              final categoria =
                  categorias[index];

              final seleccionada =
                  categoria ==
                      categoriaSeleccionada;

              return Padding(
                padding:
                    const EdgeInsets.only(
                  right: 8,
                ),
                child: ChoiceChip(
                  label:
                      Text(categoria),
                  selected:
                      seleccionada,
                  onSelected: (_) {
                    seleccionarCategoria(
                      categoria,
                    );

                    setState(() {
                      paginaActual = 1;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INICIO
  // ============================================================

  Widget paginaInicio() {
    final ofertas =
        obtenerOfertas();

    final destacados =
        productos.take(4).toList();

    return RefreshIndicator(
      onRefresh: fetchProductos,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.only(
          bottom: 30,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // HERO
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(30),
              decoration:
                  const BoxDecoration(
                gradient:
                    LinearGradient(
                  colors: [
                    Colors.deepPurple,
                    Color(0xff8e5de7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    '¡Bienvenido a\nKUÑAS STORE! 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Encuentra productos para tu hogar '
                    'de forma fácil, rápida y segura.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        paginaActual = 1;
                      });
                    },
                    icon: const Icon(
                      Icons.shopping_bag,
                    ),
                    label: const Text(
                      'Ver catálogo',
                    ),
                  ),
                ],
              ),
            ),

            buscador(),

            seccionCategorias(),

            const SizedBox(height: 25),

            // OFERTAS
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
                      '🔥 Ofertas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
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
                        'Ver todas',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 430,
                child: ListView.builder(
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
                      width: 270,
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

            const SizedBox(height: 25),

            // DESTACADOS
            const Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Text(
                '⭐ Productos destacados',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child:
                  gridProductos(destacados),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CATÁLOGO
  // ============================================================

  Widget paginaCatalogo() {
    return RefreshIndicator(
      onRefresh: fetchProductos,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.only(
          bottom: 30,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            const Padding(
              padding:
                  EdgeInsets.fromLTRB(
                20,
                20,
                20,
                5,
              ),
              child: Text(
                '🛍️ Catálogo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Text(
                'Encuentra todos nuestros productos.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

            buscador(),

            seccionCategorias(),

            const SizedBox(height: 20),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: gridProductos(
                productosFiltrados,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OFERTAS
  // ============================================================

  Widget paginaOfertas() {
    final ofertas =
        obtenerOfertas();

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          const Text(
            '🔥 Ofertas',
            style: TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Aprovecha nuestros precios especiales.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          gridProductos(ofertas),
        ],
      ),
    );
  }

  // ============================================================
  // FAVORITOS
  // ============================================================

  Widget paginaFavoritos() {
    final lista =
        obtenerFavoritos();

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          const Text(
            '❤️ Mis favoritos',
            style: TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Guarda aquí los productos que más te gustan.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          if (lista.isEmpty)
            const Center(
              child: Padding(
                padding:
                    EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 70,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Todavía no tienes favoritos.',
                      style:
                          TextStyle(
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            gridProductos(lista),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget barraSuperior() {
    return AppBar(
      elevation: 2,
      backgroundColor:
          Colors.deepPurple,
      foregroundColor:
          Colors.white,

      title: const Row(
        children: [
          Icon(Icons.store),
          SizedBox(width: 10),
          Text(
            'KUÑAS STORE',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),

      actions: [

        if (favoritos.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(
              right: 5,
            ),
            child: Center(
              child: Text(
                '${favoritos.length}',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

        IconButton(
          tooltip: 'Actualizar',
          icon: const Icon(
            Icons.refresh,
          ),
          onPressed:
              fetchProductos,
        ),
      ],
    );
  }

  // ============================================================
  // NAVEGACIÓN INFERIOR
  // ============================================================

  Widget barraNavegacion() {
    return NavigationBar(
      selectedIndex:
          paginaActual,
      onDestinationSelected:
          (index) {
        setState(() {
          paginaActual = index;
        });
      },
      destinations: const [

        NavigationDestination(
          icon: Icon(
            Icons.home_outlined,
          ),
          selectedIcon:
              Icon(Icons.home),
          label: 'Inicio',
        ),

        NavigationDestination(
          icon: Icon(
            Icons.shopping_bag_outlined,
          ),
          selectedIcon:
              Icon(Icons.shopping_bag),
          label: 'Catálogo',
        ),

        NavigationDestination(
          icon: Icon(
            Icons.local_offer_outlined,
          ),
          selectedIcon:
              Icon(Icons.local_offer),
          label: 'Ofertas',
        ),

        NavigationDestination(
          icon: Icon(
            Icons.favorite_border,
          ),
          selectedIcon:
              Icon(Icons.favorite),
          label: 'Favoritos',
        ),
      ],
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget contenido() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [

              const Icon(
                Icons.cloud_off,
                size: 70,
                color: Colors.red,
              ),

              const SizedBox(height: 20),

              Text(
                errorMessage,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed:
                    fetchProductos,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
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

      case 3:
        return paginaFavoritos();

      default:
        return paginaInicio();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraSuperior(),

      body: contenido(),

      bottomNavigationBar:
          barraNavegacion(),
    );
  }
}
