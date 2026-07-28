import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandiapp/helpers/extensions/string.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/models/product_variant_model.dart';
import 'package:mandiapp/blocs/vegetable/vegetable_bloc.dart';
import 'package:mandiapp/utils/info_controller.dart';

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

  @override
  void initState() {
    super.initState();
    final v = widget.existingVariant;
    nameController = TextEditingController(text: v?.variantName ?? '');
    sellingPriceController = TextEditingController(
        text: v != null ? v.sellingPrice.toString() : '');
    quantityController = TextEditingController(
        text: v != null ? v.quantity.toString() : '');
    selectedUnit = v?.unit ?? 'Kilogram';
    imagePath = v?.imagePath ?? '';
  }

  @override
  void dispose() {
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
              isEditing ? 'edit_variant'.tr() : 'add_variant'.tr(),
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
                                            .withOpacity(0.3),
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
                                        : theme.colorScheme.onBackground,
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
              decoration: InputDecoration(
                labelText: 'variant_name'.tr(),
                hintText: 'e.g., 500g, 1Kg, Small, Medium',
                border: const OutlineInputBorder(),
              ),
            ),
            MySpacing.height(12),
            TextField(
              controller: sellingPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'selling_price'.tr(),
                border: const OutlineInputBorder(),
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
                    decoration: InputDecoration(
                      labelText: 'quantity'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                MySpacing.width(12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedUnit,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    decoration: InputDecoration(
                      labelText: 'unit'.tr(),
                      border: const OutlineInputBorder(),
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
                              child: Text(unit),
                            ))
                        .toList(),
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
                    child: MyText.bodyMedium('cancel'.tr()),
                  ),
                ),
                MySpacing.width(12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSubmit,
                    child: MyText.bodyMedium(
                        isEditing ? 'update'.tr() : 'add'.tr()),
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
      Info.message('please_fill_required_fields'.tr(), context: context);
      return;
    }

    final sellingPrice = double.tryParse(sellingPriceText);
    final quantity = double.tryParse(quantityText);

    if (sellingPrice == null || quantity == null) {
      Info.message('please_enter_valid_numbers'.tr(), context: context);
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
