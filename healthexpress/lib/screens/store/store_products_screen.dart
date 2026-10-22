import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/store_provider.dart';

class StoreProductsScreen extends StatefulWidget {
  const StoreProductsScreen({super.key});

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Fever & Pain Relief',
    'Antibiotics',
    'Cold & Allergy',
    'Antacid / Digestion',
    'Pain Relief Spray / Gel',
    'Diabetes Care',
    'General Medicine',
  ];

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final discountCtrl = TextEditingController(text: '10');
    final stockCtrl = TextEditingController(text: '50');
    String selectedCat = 'General Medicine';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Medicine to Catalog',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Medicine Name
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Medicine / Product Name *',
                      hintText: 'e.g. Paracetamol 650mg (Dolo)',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedCat,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    items: _categories.where((c) => c != 'All').map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedCat = val!),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Price (₹) *',
                            hintText: '45.00',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: discountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Discount %',
                            hintText: '10',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Stock Qty',
                            hintText: '50',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter name and price')),
                          );
                          return;
                        }

                        context.read<StoreProvider>().addProduct(
                          name: nameCtrl.text.trim(),
                          category: selectedCat,
                          price: double.tryParse(priceCtrl.text.trim()) ?? 50.0,
                          discountPercent: int.tryParse(discountCtrl.text.trim()) ?? 10,
                          stockCount: int.tryParse(stockCtrl.text.trim()) ?? 50,
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('"${nameCtrl.text.trim()}" added to inventory!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add Medicine to Store', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();

    final filteredProducts = storeProvider.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Store Products & Stock',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        backgroundColor: const Color(0xFF0D9488),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Medicine', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search medicines, antibiotics, syrups...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0D9488)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, idx) {
                      final cat = _categories[idx];
                      final isSelected = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Catalog Status Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredProducts.length} Products Found',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                Text(
                  '${storeProvider.inStockCount} In Stock • ${storeProvider.totalProductsCount - storeProvider.inStockCount} Out',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Text('No medicines found matching your criteria.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final prod = filteredProducts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: prod.inStock ? Colors.grey.shade200 : Colors.red.shade100,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                prod.imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.medication_rounded, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prod.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    prod.category,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '₹${prod.price.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0D9488)),
                                      ),
                                      const SizedBox(width: 6),
                                      if (prod.discountPercent > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${prod.discountPercent}% OFF',
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                          ),
                                        ),
                                      const Spacer(),
                                      Text(
                                        prod.inStock ? '${prod.stockCount} in stock' : 'Out of stock',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: prod.inStock ? Colors.grey : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Quick In-Stock Switch
                            Switch(
                              value: prod.inStock,
                              onChanged: (val) {
                                storeProvider.toggleStock(prod.id);
                              },
                              activeThumbColor: const Color(0xFF0D9488),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
