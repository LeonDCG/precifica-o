import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../database/db_helper.dart';

class AddIngredientSheet extends StatefulWidget {
  final Ingredient? ingredient;
  final VoidCallback onSaved;

  const AddIngredientSheet({Key? key, this.ingredient, required this.onSaved}) : super(key: key);

  @override
  State<AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends State<AddIngredientSheet> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String unit = 'unidade';
  double price = 0.0;
  double quantity = 1.0;
  String type = 'ingredient';
  String category = '';

  @override
  void initState() {
    super.initState();
    if (widget.ingredient != null) {
      name = widget.ingredient!.name;
      unit = widget.ingredient!.unit;
      price = widget.ingredient!.price;
      quantity = widget.ingredient!.quantity;
      type = widget.ingredient!.type;
      category = widget.ingredient!.category;
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final ingredient = Ingredient(
        id: widget.ingredient?.id,
        name: name,
        unit: unit,
        price: price,
        quantity: quantity,
        type: type,
        category: category,
      );
      if (ingredient.id == null) {
        await DatabaseHelper.instance.createIngredient(ingredient);
      } else {
        await DatabaseHelper.instance.updateIngredient(ingredient);
      }
      widget.onSaved();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.ingredient == null ? 'Novo Insumo' : 'Editar Insumo',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Nome do Insumo', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                onSaved: (v) => name = v!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: price > 0 ? price.toString() : '',
                      decoration: const InputDecoration(labelText: 'Preço Pago (R\$)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      onSaved: (v) => price = double.parse(v!.replaceAll(',', '.')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: quantity > 0 ? quantity.toString() : '',
                      decoration: const InputDecoration(labelText: 'Quantidade da Embalagem', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      onSaved: (v) => quantity = double.parse(v!.replaceAll(',', '.')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: unit,
                decoration: const InputDecoration(labelText: 'Unidade (ex: kg, g, L, ml, unidade)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                onSaved: (v) => unit = v!,
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'ingredient', child: Text('Ingrediente')),
                  DropdownMenuItem(value: 'packaging', child: Text('Embalagem')),
                  DropdownMenuItem(value: 'operational', child: Text('Custo Operacional')),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Categoria (Opcional)', border: OutlineInputBorder()),
                onSaved: (v) => category = v ?? '',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Salvar'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
