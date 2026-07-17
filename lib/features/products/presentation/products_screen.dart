import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/product_service.dart';
import '../models/product_model.dart';
import 'widgets/product_card.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _metalTab = "gold";
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await ProductService.getProducts();
    if (mounted) {
      setState(() {
        _products = data;
        _isLoading = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    return _products
        .where((p) => p.metalType.toLowerCase() == _metalTab)
        .toList();
  }

  void _openProduct(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      barrierLabel: "Close",
      backgroundColor: const Color(0xFFF6F0E4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _productDetails(product),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            "assets/images/showroom_bg.png",
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: const Color(0xFFF5EBDD).withOpacity(0.55),
            ),
          ),
        ),
        SafeArea(
          // Wrapped the main column in DefaultTabController
          child: DefaultTabController(
            length: 2,
            initialIndex: _metalTab == "gold" ? 0 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        headingLevel: 1,
                        child: Text(
                          "Our Collection",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3B2A1F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        header: true,
                        headingLevel: 2,
                        child: Text(
                          "Crafted with love, priced for you",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF8E8578),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Native Metal TabBar ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE0CC),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      onTap: (index) {
                        setState(() {
                          _metalTab = index == 0 ? "gold" : "silver";
                        });
                      },
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent, // Hides native underline
                      indicator: BoxDecoration(
                        color: const Color(0xFFD4AF37), // Matches your active color
                        borderRadius: BorderRadius.circular(26),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF6E665A),
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(
                          height: 38,
                          text: "✦ Gold",
                        ),
                        Tab(
                          height: 38,
                          text: "✦ Silver",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Grid ─────────────────────────────────────────────
                Expanded(
                  child: _isLoading
                      ? _buildSkeletonGrid()
                      : _filteredProducts.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (_, index) {
                                final product = _filteredProducts[index];
                                return ProductCard(
                                  product: product,
                                  onTap: () => _openProduct(product),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0E4).withOpacity(0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.3), width: 0.6),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE7DBC9),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Column(
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7DBC9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7DBC9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 52,
            color: const Color(0xFFD4AF37).withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            "No ${_metalTab == 'gold' ? 'Gold' : 'Silver'} products yet",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF8E8578),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productDetails(Product product) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.topRight,
            child: Semantics(
              button: true,
              label: "Close",
              excludeSemantics: true,
              child: IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF6E665A)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Semantics(
            header: true,
            label: "${product.name}",
            headingLevel: 2,
            excludeSemantics: true,
            child: Text(
              product.name,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              base64Decode(product.image.split(',').last),
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            product.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF5E5548),
            ),
          ),
          const SizedBox(height: 20),
          _detail("Metal", product.metalType),
          _detail("Purity", product.carats),
          _detail("Weight", "${product.weight} g"),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13)),
          Text(
            value,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}