import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/db_helper.dart';
import '../models/profile.dart';
import '../models/sale.dart';
import '../theme/app_theme.dart';

class AdminSellersScreen extends StatefulWidget {
  const AdminSellersScreen({Key? key}) : super(key: key);

  @override
  State<AdminSellersScreen> createState() => _AdminSellersScreenState();
}

class _AdminSellersScreenState extends State<AdminSellersScreen> {
  bool _isLoading = true;
  List<Profile> _sellers = [];
  List<Sale> _allSales = [];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _commissionController = TextEditingController(text: '30');
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadSellers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _loadSellers() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DatabaseHelper.instance.getSellers(),
        DatabaseHelper.instance.readAllSales(),
      ]);
      setState(() {
        _sellers = results[0] as List<Profile>;
        _allSales = results[1] as List<Sale>;
      });
    } catch (e) {
      debugPrint('Erro ao carregar vendedores: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerSeller() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final commissionPercent = double.tryParse(_commissionController.text.replaceAll(',', '.')) ?? 30.0;

      // Usando cliente temporário para não deslogar o Admin
      final tempClient = SupabaseClient(
        DatabaseHelper.supabaseUrl,
        DatabaseHelper.supabaseAnonKey,
      );

      final authResponse = await tempClient.auth.signUp(
        email: email,
        password: password,
      );

      final newUser = authResponse.user;
      if (newUser != null) {
        final newProfile = Profile(
          id: newUser.id,
          name: name,
          role: 'seller',
          commissionPercent: commissionPercent,
        );
        await DatabaseHelper.instance.createProfile(newProfile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vendedor cadastrado com sucesso!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Fechar formulário
          _nameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _loadSellers();
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.brandRed),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao cadastrar vendedor.'), backgroundColor: AppTheme.brandRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showAddSellerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Cadastrar Novo Vendedor',
                        style: GoogleFonts.merriweather(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail de Acesso',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha Inicial',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.length < 6 ? 'Mínimo de 6 caracteres' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _commissionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Comissão Padrão (% sobre o lucro)',
                          border: OutlineInputBorder(),
                          suffixText: '%',
                        ),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isCreating ? null : () async {
                          // Sincronizar o estado de carregamento do bottomSheet com o dialog
                          setSheetState(() => _isCreating = true);
                          await _registerSeller();
                          setSheetState(() => _isCreating = false);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isCreating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Text('Cadastrar Vendedor', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditSellerDialog(Profile seller) {
    final editNameController = TextEditingController(text: seller.name);
    final editEmailController = TextEditingController(text: seller.email ?? '');
    final editPasswordController = TextEditingController();
    final editCommissionController = TextEditingController(text: seller.commissionPercent.toStringAsFixed(0));
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Editar Vendedor', style: GoogleFonts.merriweather(fontSize: 18, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: editNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail de Acesso',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editCommissionController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Comissão Padrão (% sobre o lucro)',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nova Senha (deixe em branco para manter)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    final newName = editNameController.text.trim();
                    final newEmail = editEmailController.text.trim();
                    final newPassword = editPasswordController.text;
                    final newCommission = double.tryParse(editCommissionController.text.replaceAll(',', '.')) ?? seller.commissionPercent;

                    if (newName.isEmpty || newEmail.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nome e E-mail não podem ficar vazios.'), backgroundColor: AppTheme.brandRed),
                      );
                      return;
                    }

                    setDialogState(() => isSaving = true);
                    try {
                      // 1. Atualizar nome e comissão no perfil (e sincronizar vendas legadas se o nome mudou)
                      if (newName != seller.name || newCommission != seller.commissionPercent) {
                        await DatabaseHelper.instance.updateProfileName(
                          seller.id,
                          newName,
                          oldName: seller.name,
                          commissionPercent: newCommission,
                        );
                      }
                      
                      // 2. Atualizar email e/ou senha se alterados
                      final currentEmail = seller.email ?? '';
                      if (newEmail != currentEmail || newPassword.isNotEmpty) {
                        await DatabaseHelper.instance.adminUpdateUser(
                          seller.id,
                          email: newEmail != currentEmail ? newEmail : null,
                          password: newPassword.isNotEmpty ? newPassword : null,
                        );
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dados do vendedor atualizados com sucesso!'), backgroundColor: Colors.green),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao salvar alterações: $e'), backgroundColor: AppTheme.brandRed),
                        );
                      }
                    } finally {
                      setDialogState(() => isSaving = false);
                      _loadSellers();
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text('Salvar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _confirmDeleteSeller(Profile seller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Excluir Vendedor?', style: GoogleFonts.merriweather(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text('Tem certeza de que deseja excluir ${seller.name}? Esta ação removerá o perfil do vendedor e o estoque associado.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandRed, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await DatabaseHelper.instance.deleteProfile(seller.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vendedor excluído com sucesso!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro ao excluir vendedor.'), backgroundColor: AppTheme.brandRed),
                    );
                  }
                } finally {
                  _loadSellers();
                }
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Gerenciar Vendedores', style: GoogleFonts.merriweather(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sellers.isEmpty
              ? const Center(
                  child: Text('Nenhum vendedor cadastrado ainda.', style: TextStyle(color: Colors.grey)),
                )
              : RefreshIndicator(
                  onRefresh: _loadSellers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _sellers.length,
                    itemBuilder: (context, index) {
                      final seller = _sellers[index];
                      final sellerNameNorm = seller.name.trim().toLowerCase();
                      final sellerSales = _allSales.where((s) => s.sellerName.trim().toLowerCase() == sellerNameNorm).toList();
                      
                      double totalRevenue = 0.0;
                      double totalCommission = 0.0;
                      double totalNetProfit = 0.0;
                      for (var s in sellerSales) {
                        totalRevenue += s.totalValue;
                        totalCommission += s.commissionValue;
                        totalNetProfit += s.netProfit;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  backgroundColor: AppTheme.brandGold,
                                  child: Icon(Icons.person, color: Colors.black),
                                ),
                                title: Text(seller.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${seller.email != null ? 'E-mail: ${seller.email}' : 'Vendedor'}  •  Comissão: ${seller.commissionPercent.toStringAsFixed(0)}%'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Ativo',
                                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showEditSellerDialog(seller);
                                        } else if (value == 'delete') {
                                          _confirmDeleteSeller(seller);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Text('Editar Vendedor'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                              SizedBox(width: 8),
                                              Text('Excluir', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 16),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.brown.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Text('Total Vendido', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text('R\$ ${totalRevenue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Text('Comissão Acumulada', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text('R\$ ${totalCommission.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Text('Lucro Confeitaria', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text('R\$ ${totalNetProfit.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSellerSheet,
        tooltip: 'Cadastrar Vendedor',
        child: const Icon(Icons.add),
      ),
    );
  }
}
