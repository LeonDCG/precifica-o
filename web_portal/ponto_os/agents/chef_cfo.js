/**
 * AGENTE: CHEF CFO
 * Responsável financeiro e guardião da rentabilidade da Doce & Ponto.
 * Monitora custos, CMV, margens, preços e valida viabilidade de qualquer promoção.
 */

class ChefCFO {
  constructor(tools, memory) {
    this.name = 'CHEF CFO';
    this.tools = tools;
    this.memory = memory;
  }

  async analyzeFinancialHealth() {
    const [monthKPIs, todayKPIs] = await Promise.all([
      this.tools.getMonthKPIs(),
      this.tools.getTodayKPIs(),
    ]);

    const cmv = monthKPIs.cmvPercent;
    const netMargin = monthKPIs.netMarginPercent;

    let healthStatus = 'EXCELENTE';
    let recommendations = [];

    if (cmv > 40) {
      healthStatus = 'ATENÇÃO: CMV ELEVADO';
      recommendations.push('Revisar preços de compra com fornecedores de laticínios e embalagens.');
    } else if (cmv > 35) {
      healthStatus = 'BOM';
    }

    if (netMargin < 25) {
      recommendations.push('Margem líquida global abaixo de 25%. Priorizar produtos de maior valor agregado (Slice Cakes e Bolos Especiais).');
    }

    return {
      agent: this.name,
      period: monthKPIs.month,
      faturamentoMes: monthKPIs.totalRevenue,
      lucroLiquidoMes: monthKPIs.totalProfit,
      cmvPercent: cmv,
      netMarginPercent: netMargin,
      healthStatus,
      todayRevenue: todayKPIs.totalRevenue,
      todayProfit: todayKPIs.totalProfit,
      recommendations,
    };
  }

  /**
   * Avalia proposta promocional antes que qualquer agente de marketing avance
   */
  async evaluatePromotion(productId, discountPercent, channel = 'direct') {
    const simulation = await this.tools.simulatePromotionImpact({
      productId,
      discountPercent,
      channel,
    });

    await this.tools.logAgent(
      this.name,
      simulation.isApprovedByCFO ? 'info' : 'warning',
      'evaluatePromotion',
      simulation.verdict,
      simulation
    );

    return simulation;
  }
}

window.ChefCFO = ChefCFO;
