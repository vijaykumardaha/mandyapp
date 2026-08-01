import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:krishimandi/blocs/vegetable/vegetable_bloc.dart';
import 'package:krishimandi/models/product_variant_model.dart';
import 'package:krishimandi/services/sync_service.dart';
import 'package:krishimandi/utils/constants.dart';
import 'package:krishimandi/utils/info_controller.dart';
import 'package:krishimandi/widgets/common/dropdown_option.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class VariantFormSheet extends StatefulWidget {
  final int productId;
  final ProductVariant? existingVariant;

  const VariantFormSheet({
    super.key,
    required this.productId,
    this.existingVariant,
  });

  static Future<ProductVariant?> show(
    BuildContext context, {
    required int productId,
    ProductVariant? existingVariant,
  }) async {
    context.read<VegetableBloc>().add(const FetchVegetables());
    return showModalBottomSheet<ProductVariant>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<VegetableBloc>(),
        child: VariantFormSheet(
          productId: productId,
          existingVariant: existingVariant,
        ),
      ),
    );
  }

  @override
  State<VariantFormSheet> createState() => _VariantFormSheetState();
}

class _VariantFormSheetState extends State<VariantFormSheet> {
  late TextEditingController nameController;
  late TextEditingController sellingPriceController;
  late TextEditingController quantityController;
  String selectedUnit = 'Kilogram';
  String imagePath = '';
  StreamSubscription<String>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    final v = widget.existingVariant;
    nameController = TextEditingController(text: v?.variantName ?? '');
    sellingPriceController =
        TextEditingController(text: v != null ? v.sellingPrice.toString() : '');
    quantityController =
        TextEditingController(text: v != null ? v.quantity.toString() : '');
    selectedUnit = v?.unit ?? 'Kilogram';
    imagePath = v?.imagePath ?? '';

    _syncSubscription = SyncService.instance.tableUpdates.listen((table) {
      if (!mounted) return;
      if (table == DbTables.vegetables) {
        final state = context.read<VegetableBloc>().state;
        if (state is VegetableLoaded) {
          context.read<VegetableBloc>().add(const FetchVegetables());
        }
      }
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    nameController.dispose();
    sellingPriceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingVariant != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MyText.titleMedium(
              isEditing ? 'Edit Variant' : 'Add Variant',
              fontWeight: 600,
            ),
            MySpacing.height(16),
            if (imagePath.isNotEmpty)
              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imagePath.startsWith('assets/')
                        ? Image.asset(imagePath, fit: BoxFit.cover)
                        : Image.file(File(imagePath), fit: BoxFit.cover),
                  ),
                ),
              ),
            MySpacing.height(12),
            BlocBuilder<VegetableBloc, VegetableState>(
              builder: (context, vegState) {
                if (vegState is VegetableLoaded) {
                  return SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: vegState.vegetables.length,
                      separatorBuilder: (_, __) => MySpacing.width(8),
                      itemBuilder: (context, index) {
                        final veg = vegState.vegetables[index];
                        final isSelected = imagePath == veg.path;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              imagePath = veg.path;
                              nameController.text = veg.name;
                            });
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline
                                            .withValues(alpha: 0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.asset(
                                    veg.path,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              MySpacing.height(2),
                              SizedBox(
                                width: 56,
                                child: Text(
                                  veg.name,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            MySpacing.height(12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Variant Name',
                hintText: 'e.g., 500g, 1Kg, Small, Medium',
                border: OutlineInputBorder(),
              ),
            ),
            MySpacing.height(12),
            TextField(
              controller: sellingPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Selling Price',
                border: OutlineInputBorder(),
              ),
            ),
            MySpacing.height(12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                MySpacing.width(12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedUnit,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    menuMaxHeight: 300,
                    elevation: 4,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'Gram',
                      'Kilogram',
                      'Quintal',
                      'Metric Ton',
                      'Piece',
                      'Dozen',
                      'Box',
                      'Bag',
                      'Crate',
                      'Bundle',
                      'Tray',
                    ]
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: DropdownOption(
                                selected: selectedUnit == unit,
                                child: Text(unit),
                              ),
                            ))
                        .toList(),
                    selectedItemBuilder: (context) => [
                      'Gram',
                      'Kilogram',
                      'Quintal',
                      'Metric Ton',
                      'Piece',
                      'Dozen',
                      'Box',
                      'Bag',
                      'Crate',
                      'Bundle',
                      'Tray',
                    ].map((unit) => Text(unit)).toList(),
                    onChanged: (value) {
                      setState(() => selectedUnit = value!);
                    },
                  ),
                ),
              ],
            ),
            MySpacing.height(20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const MyText.bodyMedium('Cancel'),
                  ),
                ),
                MySpacing.width(12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSubmit,
                    child: MyText.bodyMedium(isEditing ? 'Update' : 'Add'),
                  ),
                ),
              ],
            ),
            MySpacing.height(16),
          ],
        ),
      ),
    );
  }

  void _onSubmit() {
    final name = nameController.text.trim();
    final sellingPriceText = sellingPriceController.text.trim();
    final quantityText = quantityController.text.trim();

    if (name.isEmpty ||
        imagePath.isEmpty ||
        sellingPriceText.isEmpty ||
        quantityText.isEmpty) {
      Info.message('Please fill all required fields', context: context);
      return;
    }

    final sellingPrice = double.tryParse(sellingPriceText);
    final quantity = double.tryParse(quantityText);

    if (sellingPrice == null || quantity == null) {
      Info.message('Please enter valid numbers', context: context);
      return;
    }

    final variant = ProductVariant(
      id: widget.existingVariant?.id,
      productId: widget.productId,
      variantName: name,
      sellingPrice: sellingPrice,
      quantity: quantity,
      unit: selectedUnit,
      imagePath: imagePath,
    );

    Navigator.pop(context, variant);
  }
}
