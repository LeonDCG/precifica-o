class UnitConverter {
  static double getCost(double quantityUsed, String unitUsed, double pricePerBaseUnit, String baseUnit) {
    String from = unitUsed.trim().toLowerCase();
    String to = baseUnit.trim().toLowerCase();

    if (from == to) return quantityUsed * pricePerBaseUnit;

    // Weight
    if ((from == 'kg' || from == 'kilo' || from == 'quilo') && (to == 'g' || to == 'grama' || to == 'gramas')) {
      return (quantityUsed * 1000) * pricePerBaseUnit;
    }
    if ((from == 'g' || from == 'grama' || from == 'gramas') && (to == 'kg' || to == 'kilo' || to == 'quilo')) {
      return (quantityUsed / 1000) * pricePerBaseUnit;
    }

    // Volume
    if ((from == 'l' || from == 'litro' || from == 'litros') && (to == 'ml' || to == 'mililitro' || to == 'mililitros')) {
      return (quantityUsed * 1000) * pricePerBaseUnit;
    }
    if ((from == 'ml' || from == 'mililitro' || from == 'mililitros') && (to == 'l' || to == 'litro' || to == 'litros')) {
      return (quantityUsed / 1000) * pricePerBaseUnit;
    }

    // Default
    return quantityUsed * pricePerBaseUnit;
  }

  static double getQuantityInBaseUnit(double quantityUsed, String unitUsed, String baseUnit) {
    String from = unitUsed.trim().toLowerCase();
    String to = baseUnit.trim().toLowerCase();

    if (from == to) return quantityUsed;

    // Weight
    if ((from == 'kg' || from == 'kilo' || from == 'quilo') && (to == 'g' || to == 'grama' || to == 'gramas')) {
      return quantityUsed * 1000;
    }
    if ((from == 'g' || from == 'grama' || from == 'gramas') && (to == 'kg' || to == 'kilo' || to == 'quilo')) {
      return quantityUsed / 1000;
    }

    // Volume
    if ((from == 'l' || from == 'litro' || from == 'litros') && (to == 'ml' || to == 'mililitro' || to == 'mililitros')) {
      return quantityUsed * 1000;
    }
    if ((from == 'ml' || from == 'mililitro' || from == 'mililitros') && (to == 'l' || to == 'litro' || to == 'litros')) {
      return quantityUsed / 1000;
    }

    return quantityUsed;
  }
}
