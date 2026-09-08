import 'package:flutter_test/flutter_test.dart';
import 'package:precificacao/models/product.dart';

void main() {
  group('Product model tests', () {
    test('Calculates totalCost from recipes and expenses when present', () {
      final product = Product(
        name: 'Bolo Caseiro',
        suggestedPrice: 100,
        sellPrice: 120,
        profitMarginPercent: 50,
        recipes: [
          ProductRecipe(productId: 1, recipeId: 1, quantityUsed: 1, cost: 25.0),
          ProductRecipe(productId: 1, recipeId: 2, quantityUsed: 1, cost: 15.0),
        ],
        extraExpenses: [
          ProductExpense(productId: 1, name: 'Embalagem', cost: 5.0),
        ],
      );

      expect(product.totalCost, equals(45.0));
      expect(product.actualProfit, equals(75.0)); // 120 - 45
    });

    test('Deduces totalCost from suggestedPrice and profitMarginPercent when recipes not loaded', () {
      // In light queries (readProductsSummary), recipes and expenses are not fetched.
      // If suggestedPrice is 60 and margin is 50%, cost must be 40 (40 * 1.5 = 60).
      final lightProduct = Product(
        name: 'Bolo Light',
        suggestedPrice: 60.0,
        sellPrice: 70.0,
        profitMarginPercent: 50.0,
        recipes: const [],
        extraExpenses: const [],
      );

      expect(lightProduct.totalCost, closeTo(40.0, 0.001));
      expect(lightProduct.actualProfit, closeTo(30.0, 0.001)); // 70 - 40
    });

    test('calculateSuggestedPrice correctly updates suggestedPrice', () {
      final product = Product(
        name: 'Torta',
        profitMarginPercent: 100.0,
        recipes: [
          ProductRecipe(productId: 1, recipeId: 1, quantityUsed: 1, cost: 30.0),
        ],
      );

      product.calculateSuggestedPrice();
      expect(product.suggestedPrice, equals(60.0)); // 30 * (1 + 100/100) = 60
    });

    test('ifoodPrice serialization and effectiveIfoodPrice fallback', () {
      final productWithIfood = Product(
        name: 'Torta Trufada',
        sellPrice: 50.0,
        ifoodPrice: 68.50,
      );

      expect(productWithIfood.effectiveIfoodPrice, equals(68.50));

      final map = productWithIfood.toMap();
      expect(map['ifoodPrice'], equals(68.50));

      final fromMapProd = Product.fromMap(map);
      expect(fromMapProd.ifoodPrice, equals(68.50));
      expect(fromMapProd.effectiveIfoodPrice, equals(68.50));

      final productWithoutIfood = Product(
        name: 'Bolo Simples',
        sellPrice: 40.0,
        ifoodPrice: 0.0,
      );
      expect(productWithoutIfood.effectiveIfoodPrice, equals(40.0));
    });
  });
}
