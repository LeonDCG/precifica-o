/**
 * AGENTE: CHEF ESTOQUE
 * Responsável pela integridade física do estoque e prevenção de rupturas.
 * Monitora ingredientes, embalagens, estoque pronto e sugere compras antes da falta.
 */

class ChefEstoque {
  constructor(tools, memory) {
    this.name = 'CHEF ESTOQUE';
    this.tools = tools;
    this.memory = memory;
  }

  async checkStockStatus() {
    const alerts = await this.tools.getStockAlerts();
    const products = await this.tools.getProductsAnalysis();

    const criticalList = alerts.criticalItems.map(item => ({
      id: item.id,
      name: item.name,
      currentStock: item.currentStock,
      minStock: item.minStock,
      deficit: Math.max(0, item.minStock - item.currentStock),
      status: item.currentStock <= 0 ? 'ZERADO' : 'CRÍTICO',
    }));

    const suggestedPurchases = criticalList.map(item => ({
      product: item.name,
      suggestedUnitsToProduce: Math.max(item.deficit * 2, 5),
      priority: item.status === 'ZERADO' ? 'MÁXIMA' : 'ALTA',
    }));

    return {
      agent: this.name,
      totalProducts: products.length,
      criticalCount: alerts.criticalCount,
      outOfStockCount: alerts.outOfStockCount,
      criticalList,
      suggestedPurchases,
      hasRuptureRisk: alerts.criticalCount > 0,
      summary: alerts.criticalCount === 0 
        ? 'Estoque saudável. Todos os produtos estão com níveis acima do mínimo operacional.'
        : `Atenção: ${alerts.criticalCount} item(ns) atingiram nível crítico ou zerado. Necessário programar produção imediata.`,
    };
  }

  /**
   * Verifica se há estoque suficiente para promover um determinado produto
   */
  async validateStockForPromotion(productId, estimatedDemand = 10) {
    const products = await this.tools.getProductsAnalysis();
    const product = products.find(p => p.id === productId);

    if (!product) {
      return { hasStock: false, reason: 'Produto não localizado no estoque.' };
    }

    if (product.currentStock <= 0) {
      return {
        hasStock: false,
        currentStock: 0,
        reason: `Produto "${product.name}" está com estoque esgotado (0 unidades). Promoção vetada pelo Chef Estoque.`,
      };
    }

    const isSufficient = product.currentStock >= estimatedDemand;

    return {
      hasStock: isSufficient,
      currentStock: product.currentStock,
      estimatedDemand,
      reason: isSufficient
        ? `Estoque de ${product.currentStock} unidades é suficiente para a demanda prevista de ${estimatedDemand}.`
        : `Estoque de apenas ${product.currentStock} unidades. Recomendado limitar volume da campanha ou produzir reposição.`,
    };
  }
}

window.ChefEstoque = ChefEstoque;
