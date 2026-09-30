/**
 * AGENTE: CHEF EXECUTIVO
 * Mestre de produção da confeitaria.
 * Responsável pelo planejamento diário/semanal de massas, recheios, montagem e rendimentos.
 */

class ChefExecutivo {
  constructor(tools, memory) {
    this.name = 'CHEF EXECUTIVO';
    this.tools = tools;
    this.memory = memory;
  }

  async generateDailyProductionPlan() {
    const alerts = await this.tools.getStockAlerts();
    const critical = alerts.criticalItems;

    if (critical.length === 0) {
      return {
        agent: this.name,
        hasTasks: false,
        message: 'Geladeira abastecida. Não há produtos com estoque abaixo do mínimo de segurança hoje.',
        batchesToProduce: [],
      };
    }

    const batchesToProduce = critical.map(item => {
      const deficit = Math.max(0, item.minStock - item.currentStock);
      const unitsNeeded = deficit > 0 ? deficit * 2 : 5; // Margem de segurança
      return {
        productName: item.name,
        currentStock: item.currentStock,
        minStock: item.minStock,
        suggestedProduction: unitsNeeded,
        priority: item.currentStock <= 0 ? 'URGENTE' : 'NORMAL',
        stage: 'MONTAGEM E PREPARO',
      };
    });

    return {
      agent: this.name,
      hasTasks: true,
      message: `Planejamento de produção montado para ${batchesToProduce.length} produto(s) prioritário(s).`,
      batchesToProduce,
      recommendation: 'Priorizar o preparo dos itens em estado URGENTE antes da abertura dos canais de entrega.',
    };
  }
}

window.ChefExecutivo = ChefExecutivo;
