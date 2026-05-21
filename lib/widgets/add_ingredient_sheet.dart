import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../database/db_helper.dart';

class AddIngredientSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final Ingredient? ingredient; // Opcional para edição

  const AddIngredientSheet({
    Key? key,
    required this.onSaved,
    this.ingredient,
  }) : super(key: key);

  @override
  State<AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends State<AddIngredientSheet> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _unit = 'kg';
  double _price = 0;
  double _quantity = 1;
  String _type = 'ingredient'; // ingredient, packaging, operational
  String _category = 'SECOS';
  double _stock = 0;

  final List<String> _units = ['g', 'kg', 'ml', 'L', 'unidade'];
  final List<String> _categories = ['SECOS', 'ADOÇANTES', 'LATICÍNIOS', 'DIVERSOS'];

  @override
  void initState() {
    super.initState();
    if (widget.ingredient != null) {
      final ing = widget.ingredient!;
      _name = ing.name;
      _unit = ing.unit;
      _price = ing.price;
      _quantity = ing.quantity;
      _type = ing.type;
      _category = ing.category.isEmpty ? 'SECOS' : ing.category;
      _stock = ing.stock;
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newIngredient = Ingredient(
        id: widget.ingredient?.id,
        name: _name,
        unit: _unit,
        price: _price,
        quantity: _quantity,
        type: _type,
        category: _category,
        stock: _stock,
      );

      if (widget.ingredient != null) {
        await DatabaseHelper.instance.updateIngredient(newIngredient);
      } else {
        await DatabaseHelper.instance.createIngredient(newIngredient);
      }

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.ingredient != null ? 'Editar Insumo' : 'Novo Insumo',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Tipo de Insumo'),
              value: _type,
              items: const [
                DropdownMenuItem(value: 'ingredient', child: Text('Ingrediente')),
                DropdownMenuItem(value: 'packaging', child: Text('Embalagem')),
                DropdownMenuItem(value: 'operational', child: Text('Custo Operacional')),
              ],
              onChanged: (val) => setState(() => _type = val!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Nome da Descrição'),
              validator: (value) => value == null || value.isEmpty ? 'Informe o nome' : null,
              onSaved: (value) => _name = value!,
            ),
            if (_type == 'ingredient') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Categoria'),
                value: _category,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: _quantity.toString(),
                    decoration: const InputDecoration(labelText: 'Qtd na Embalagem'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _quantity = double.tryParse(value!.replaceAll(',', '.')) ?? 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Unidade'),
                    value: _unit,
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) => setState(() => _unit = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: widget.ingredient != null ? _price.toString() : null,
                    decoration: const InputDecoration(labelText: 'Preço Pago (R\$)'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Obrigatório' : null,
                    onSaved: (value) => _price = double.tryParse(value!.replaceAll(',', '.')) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _stock.toString(),
                    decoration: const InputDecoration(labelText: 'Estoque Atual'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _stock = double.tryParse(value!.replaceAll(',', '.')) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Text(widget.ingredient != null ? 'SALVAR ALTERAÇÕES' : 'SALVAR'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
