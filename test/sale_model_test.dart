import 'package:flutter_test/flutter_test.dart';
import 'package:precificacao/models/sale.dart';

void main() {
  group('Sale model and iFood channel tests', () {
    test('Direct sale is correctly identified as direct', () {
      final sale = Sale(
        productName: 'Bolo de Cenoura',
        quantity: 1,
        totalValue: 50.0,
        totalCost: 15.0,
        totalProfit: 35.0,
        sellerType: 'me',
        sellerName: 'Você',
        netProfit: 35.0,
        saleDate: DateTime.now(),
      );

      expect(sale.isDirect, isTrue);
      expect(sale.isIfood, isFalse);
      expect(sale.isSeller, isFalse);
      expect(sale.commissionValue, equals(0.0));
      expect(sale.netProfit, equals(35.0));
    });

    test('iFood Plano Entrega sale calculates commission and net profit correctly', () {
      // Pedido no iFood: R$ 60,00
      // Taxa Plano Entrega: 26.2% => 60 * 0.262 = R$ 15,72
      // Custo dos insumos: R$ 18,00
      // Repasse Líquido: 60 - 15.72 = R$ 44,28
      // Lucro Líquido Real: 44.28 - 18.00 = R$ 26,28
      const totalValue = 60.0;
      const totalCost = 18.0;
      const ifoodRate = 26.2;
      const commissionValue = totalValue * (ifoodRate / 100);
      const totalProfit = totalValue - totalCost; // 42.0
      const netProfit = totalProfit - commissionValue; // 26.28

      final ifoodSale = Sale(
        productId: 38,
        productName: 'Bolo de Cenoura',
        quantity: 1,
        totalValue: totalValue,
        totalCost: totalCost,
        totalProfit: totalProfit,
        sellerType: 'ifood',
        sellerName: 'iFood (Plano Entrega)',
        commissionPercent: ifoodRate,
        commissionValue: commissionValue,
        netProfit: netProfit,
        saleDate: DateTime.now(),
        notes: '[Pedido iFood #4821] Entregar com laço',
      );

      expect(ifoodSale.isIfood, isTrue);
      expect(ifoodSale.isDirect, isFalse);
      expect(ifoodSale.isSeller, isFalse);
      expect(ifoodSale.commissionPercent, equals(26.2));
      expect(ifoodSale.commissionValue, closeTo(15.72, 0.001));
      expect(ifoodSale.netProfit, closeTo(26.28, 0.001));
      expect(ifoodSale.notes, contains('#4821'));

      // Test Serialization / Deserialization toMap and fromMap
      final map = ifoodSale.toMap();
      final restored = Sale.fromMap(map);

      expect(restored.sellerType, equals('ifood'));
      expect(restored.sellerName, equals('iFood (Plano Entrega)'));
      expect(restored.isIfood, isTrue);
      expect(restored.netProfit, closeTo(26.28, 0.001));
      expect(restored.commissionPercent, equals(26.2));
    });

    test('Partner seller sale is correctly identified as seller', () {
      final sellerSale = Sale(
        productName: 'Bolo de Morango',
        quantity: 2,
        totalValue: 100.0,
        totalCost: 30.0,
        totalProfit: 70.0,
        sellerType: 'other',
        sellerName: 'Maria Vendedora',
        commissionPercent: 30.0,
        commissionValue: 21.0,
        netProfit: 49.0,
        saleDate: DateTime.now(),
      );

      expect(sellerSale.isSeller, isTrue);
      expect(sellerSale.isIfood, isFalse);
      expect(sellerSale.isDirect, isFalse);
      expect(sellerSale.commissionValue, equals(21.0));
      expect(sellerSale.netProfit, equals(49.0));
    });
  });
}
