/**
 * AGENTE: PONTO MARKETING
 * Especialista em crescimento comercial, campanhas, promoções e copywriting.
 * REGRA ABSOLUTA: Nunca recomenda promoção sem prévia consulta e aprovação do CHEF CFO e do CHEF ESTOQUE.
 */

class PontoMarketing {
  constructor(tools, memory, cfoAgent, estoqueAgent) {
    this.name = 'PONTO MARKETING';
    this.tools = tools;
    this.memory = memory;
    this.cfo = cfoAgent;
    this.estoque = estoqueAgent;
  }

  /**
   * Elabora proposta de promoção integrada entre agentes
   */
  async proposeCampaign({ productId, discountPercent, channel = 'direct', campaignTitle = '' }) {
    // 1. Consultar CHEF ESTOQUE para verificar disponibilidade
    const stockEval = await this.estoque.validateStockForPromotion(productId, 10);
    if (!stockEval.hasStock) {
      return {
        approved: false,
        agent: this.name,
        stage: 'ESTOQUE VETOU',
        reason: stockEval.reason,
      };
    }

    // 2. Consultar CHEF CFO para validação de margem mínima
    const cfoEval = await this.cfo.evaluatePromotion(productId, discountPercent, channel);
    if (!cfoEval.isApprovedByCFO) {
      return {
        approved: false,
        agent: this.name,
        stage: 'CFO VETOU',
        reason: cfoEval.verdict,
        cfoData: cfoEval,
      };
    }

    // 3. Proposta aprovada no comitê interno de agentes
    return {
      approved: true,
      agent: this.name,
      campaignTitle: campaignTitle || `Ação Especial: Desconto de ${discountPercent}% no ${cfoEval.productName}`,
      summary: `Campanha aprovada pelo Estoque (${stockEval.currentStock} un disponíveis) e pelo CFO (Margem resultante: ${cfoEval.netMarginPercent.toFixed(1)}%).`,
      financialImpact: {
        precoOriginal: cfoEval.originalPrice,
        precoPromocional: cfoEval.discountedPrice,
        lucroLiquidoPorUnidade: cfoEval.netProfit,
        margemLiquidaPercent: cfoEval.netMarginPercent,
      },
      actionRequiresApproval: true, // Nível 2
      nextStep: 'Submeter à Central de Aprovações para autorização humana do proprietário.',
    };
  }

  getCommercialCalendarSuggestions() {
    const now = new Date();
    const month = now.getMonth() + 1;

    const calendar = {
      1: 'Férias de Verão: Combos individuais refrescantes e sobremesas geladas.',
      2: 'Carnaval: Copos da felicidade temáticos e fatias práticas para consumo rápido.',
      3: 'Dia da Mulher: Caixas presenteáveis sofisticadas com laços de cetim.',
      4: 'Páscoa: Ovos de colher artesanais, brigadeiros gourmet e caixas degustação.',
      5: 'Dia das Mães: A maior data do ano para bolos inteiros decorados e tortas.',
      6: 'Dia dos Namorados: Fondue box para dois e corações lapidados de chocolate.',
      7: 'Inverno: Fatias aquecidas com calda quente de brigadeiro cremoso.',
      8: 'Dia dos Pais: Sabores clássicos e opções com café/nozes.',
      9: 'Primavera: Geleias artesanais com frutas frescas e flores comestíveis.',
      10: 'Dia das Crianças e Halloween: Cores vibrantes, confeitos e edição limitada.',
      11: 'Black Friday: Descontos estratégicos em itens com margem > 40%.',
      12: 'Natal e Réveillon: Sobremesas de travessa e chocotones trufados sob encomenda.',
    };

    return {
      mesAtual: now.toLocaleString('pt-BR', { month: 'long' }),
      estrategiaSazonal: calendar[month] || 'Foco em Slice Cakes e pronta entrega.',
      dicaCopy: 'Destaque sempre os ingredientes nobres: chocolate nobre, leite condensado de primeira linha e sabor artesanal sem conservantes.',
    };
  }
}

window.PontoMarketing = PontoMarketing;
