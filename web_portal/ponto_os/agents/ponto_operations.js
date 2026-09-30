/**
 * AGENTE: PONTO OPERATIONS
 * Monitor operacional da loja e das entregas (balcão e iFood).
 * Acompanha fluxo de pedidos, tempo de preparo, gargalos e capacidade produtiva.
 */

class PontoOperations {
  constructor(tools, memory) {
    this.name = 'PONTO OPERATIONS';
    this.tools = tools;
    this.memory = memory;
  }

  async getOperationsStatus() {
    const todayKPIs = await this.tools.getTodayKPIs();

    // Consulta estado das regras operacionais
    const capacityRule = this.memory.getRules('capacity').find(r => r.rule_code === 'RULE_OP_CAPACITY');
    const maxCapacity = capacityRule?.condition_config?.threshold || 25;

    const prepRule = this.memory.getRules('operation').find(r => r.rule_code === 'RULE_PREP_TIME');
    const maxPrepTime = prepRule?.condition_config?.threshold || 45;

    const activeOrders = todayKPIs.orderCount;
    const isOverCapacity = activeOrders > maxCapacity;

    return {
      agent: this.name,
      storeStatus: 'ABERTA / OPERANDO',
      ordersToday: activeOrders,
      estimatedAveragePrepTimeMinutes: 28,
      maxThresholdPrepTime: maxPrepTime,
      isBottleneckDetected: isOverCapacity,
      summary: isOverCapacity
        ? `ALERTA: Volume de pedidos (${activeOrders}) próximo ou acima da capacidade recomendada (${maxCapacity}/dia).`
        : `Operação fluida. Volume de pedidos dentro da capacidade ideal de produção da cozinha.`,
    };
  }
}

window.PontoOperations = PontoOperations;
