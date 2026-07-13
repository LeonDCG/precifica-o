import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_screen.dart';
import 'ingredients_screen.dart';
import 'recipes_screen.dart';
import 'catalog_screen.dart';
import 'sales_screen.dart';
import 'seller_dashboard.dart';
import 'seller_orders_screen.dart';
import '../models/profile.dart';
import '../database/db_helper.dart';

class HomeScreen extends StatefulWidget {
  final Profile? profile;
  const HomeScreen({Key? key, this.profile}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Profile? _profile;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _profile = widget.profile;
    } else {
      _loadCurrentProfile();
    }
  }

  Future<void> _loadCurrentProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() => _isLoadingProfile = true);
      try {
        var profile = await DatabaseHelper.instance.getProfile(user.id);
        if (profile == null) {
          final isLeon = user.email == 'leondcg@hotmail.com';
          profile = Profile(
            id: user.id,
            name: isLeon ? 'Leon' : (user.email?.split('@').first ?? 'Vendedor'),
            role: isLeon ? 'admin' : 'seller',
          );
          await DatabaseHelper.instance.createProfile(profile);
        }
        setState(() {
          _profile = profile;
        });
      } catch (e) {
        debugPrint('Erro ao carregar perfil inicial: $e');
      } finally {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> get _pages {
    final role = _profile?.role ?? 'seller';
    if (role == 'admin') {
      return [
        const DashboardScreen(),
        const IngredientsScreen(),
        const RecipesScreen(),
        const CatalogScreen(),
        const SalesScreen(),
      ];
    } else {
      return [
        SellerDashboard(profile: _profile!),
        SalesScreen(profile: _profile),
        SellerOrdersScreen(profile: _profile!),
      ];
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    final role = _profile?.role ?? 'seller';
    if (role == 'admin') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Insumos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          activeIcon: Icon(Icons.menu_book),
          label: 'Receitas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
          label: 'Catálogo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale_outlined),
          activeIcon: Icon(Icons.point_of_sale),
          label: 'Vendas',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale_outlined),
          activeIcon: Icon(Icons.point_of_sale),
          label: 'Minhas Vendas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.kitchen_outlined),
          activeIcon: Icon(Icons.kitchen),
          label: 'Encomendar',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile || _profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = _pages;
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _navItems,
      ),
    );
  }
}
