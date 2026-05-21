import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/product.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  double _desiredSalary = 2000.0;
  double _workedHoursPerMonth = 160.0;
  List<Product> _products = [];

  double get _hourlyRate => _workedHoursPerMonth > 0 ? _desiredSalary / _workedHoursPerMonth : 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final salaryStr = await DatabaseHelper.instance.getSetting('desiredSalary');
    final hoursStr = await DatabaseHelper.instance.getSetting('workedHoursPerMonth');
    
    if (salaryStr != null) _desiredSalary = double.tryParse(salaryStr) ?? 2000.0;
    if (hoursStr != null) _workedHoursPerMonth = double.tryParse(hoursStr) ?? 160.0;
    
    _products = await DatabaseHelper.instance.readAllProducts();
    
    setState(() => _isLoading = false);
  }

  Future<void> _showLaborConfigDialog() async {
    final salaryController = TextEditingController(text: _desiredSalary.toStringAsFixed(2));
    final hoursController = TextEditingController(text: _workedHoursPerMonth.toStringAsFixed(0));

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Configurar Mão de Obra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: salaryController,
                decoration: const InputDecoration(labelText: 'Salário Desejado (R\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hoursController,
                decoration: const InputDecoration(
                  labelText: 'Horas trabalhadas no mês',
                  helperText: 'Ex: 40h/semana * 4 = 160h',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newSalary = double.tryParse(salaryController.text.replaceAll(',', '.')) ?? 0.0;
                final newHours = double.tryParse(hoursController.text.replaceAll(',', '.')) ?? 0.0;
                
                await DatabaseHelper.instance.saveSetting('desiredSalary', newSalary.toString());
                await DatabaseHelper.instance.saveSetting('workedHoursPerMonth', newHours.toString());
                
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('SALVAR'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doce & Ponto', style: TextStyle(fontSize: 18)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              decoration: BoxDecoration(
                color: Colors.white, // Fundo branco para combinar com o logo claro
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ]
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/logo_light_v3.png',
                  height: 180,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Text('Resumo financeiro e configurações globais.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            
            // Cartão de Mão de Obra
            Card(
              elevation: 4,
              shadowColor: Colors.brown.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('CUSTO DA MÃO DE OBRA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                          onPressed: _showLaborConfigDialog,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('R\$ ${_hourlyRate.toStringAsFixed(2)}', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 32, color: Theme.of(context).primaryColor)),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6.0, left: 4.0),
                          child: Text('/hora', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SALÁRIO DESEJADO', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              Text('R\$ ${_desiredSalary.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('HORAS/MÊS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              Text('${_workedHoursPerMonth.toStringAsFixed(0)}h', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Resumo do Catálogo', style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.brown.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cake, color: Colors.brown, size: 32),
                        const SizedBox(height: 8),
                        Text('${_products.length}', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24)),
                        const Text('Produtos', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.trending_up, color: Theme.of(context).primaryColor, size: 32),
                        const SizedBox(height: 8),
                        Text('100%', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24, color: Theme.of(context).primaryColor)),
                        Text('Lucro Médio', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
