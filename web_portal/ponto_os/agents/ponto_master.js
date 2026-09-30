/**
 * AGENTE PRINCIPAL: PONTO MASTER
 * Gerente Geral e Orquestrador Central da Doce & Ponto.
 * 
 * Responsabilidades:
 * - Receber solicitações do usuário ou disparos periódicos
 * - Analisar o contexto global da confeitaria
 * - Delegar para os agentes especialistas apropriados
 * - Consolidar dados e resolver divergências
 * - Priorizar e apresentar recomendações claras
 * - Encaminhar ações para aprovação humana (Nível 2) ou execução controlada (Nível 3)
 */

class PontoMaster {
  constructor({
    supabase,
    tools,
    memory,
    cfo,
    estoque,
    analytics,
    executivo,
    operations,
    catalogo,
    marketing,
    ads,
    customer,
    guardian,
  }) {
    this.name = 'PONTO MASTER';
    this.supabase = supabase;
    this.tools = tools;
    this.memory = memory;

    // Agentes especialistas
    this.cfo = cfo;
    this.estoque = estoque;
    this.analytics = analytics;
    this.executivo = executivo;
    this.operations = operations;
    this.catalogo = catalogo;
    this.marketing = marketing;
    this.ads = ads;
    this.customer = customer;
    this.guardian = guardian;
  }

  /**
   * Visão Geral de 360° da loja (Central de Comando)
   */
  async getConsolidatedStatus() {
    // Consulta paralela a todos os agentes especialistas
    const [
      financeiro,
      estoqueStatus,
      analyticsData,
      producao,
      operacao,
      catalogoAudit,
      adsData,
      customerData,
    ] = await Promise.all([
      this.cfo.analyzeFinancialHealth(),
      this.estoque.checkStockStatus(),
      this.analytics.getPerformanceReport(),
      this.executivo.generateDailyProductionPlan(),
      this.operations.getOperationsStatus(),
      this.catalogo.auditCatalogHealth(),
      this.ads.analyzeAdsPerformance(),
      this.customer.getCustomerSatisfactionReport(),
    ]);

    // Identificar ações críticas imediatas
    const priorityAlerts = [];
    if (estoqueStatus.hasRuptureRisk) {
      priorityAlerts.push({
        severity: 'HIGH',
        agent: this.estoque.name,
        message: `${estoqueStatus.criticalCount} produto(s) com estoque crítico ou zerado.`,
      });
    }

    if (financeiro.cmvPercent > 40) {
      priorityAlerts.push({
        severity: 'MEDIUM',
        agent: this.cfo.name,
        message: `CMV mensal em ${financeiro.cmvPercent.toFixed(1)}% (acima da meta ideal de 35%).`,
      });
    }

    return {
      masterVerdict: 'Central Doce & Ponto sincronizada em tempo real.',
      timestamp: new Date().toISOString(),
      priorityAlerts,
      financeiro,
      estoque: estoqueStatus,
      analytics: analyticsData,
      producao,
      operacao,
      catalogo: catalogoAudit,
      ads: adsData,
      customer: customerData,
    };
  }

  /**
   * Roteador inteligente de linguagem natural do Chat com PONTO MASTER
   */
  async handleUserQuery(query) {
    const q = query.toLowerCase().trim();

    // 1. Visão geral da loja ("como está minha loja hoje?")
    if (q.includes('loja hoje') || q.includes('como está') || q.includes('resumo') || q.includes('visão geral')) {
      const data = await this.getConsolidatedStatus();
      return {
        agent: this.name,
        text: `### 🍰 Visão Consolidada da Doce & Ponto — Hoje

**Faturamento:** R$ ${data.financeiro.todayRevenue.toFixed(2)} hoje | R$ ${data.financeiro.faturamentoMes.toFixed(2)} no mês (${data.analytics.totalOrders} pedidos).
**Margem Líquida do Mês:** ${data.financeiro.netMarginPercent.toFixed(1)}% | **CMV:** ${data.financeiro.cmvPercent.toFixed(1)}%.
**Saúde do Estoque:** ${data.estoque.summary}
**Operação & Cozinha:** ${data.operacao.summary}
**Satisfação:** Nota média ${data.customer.notaMediaLoja} ⭐ com ${data.customer.recorrenciaEstimadaPercent}% de clientes recorrentes.

${data.priorityAlerts.length > 0 ? `\n> ⚠️ **Atenção Prioritária:** ${data.priorityAlerts.map(a => a.message).join(' ')}` : '\n> ✅ Operação equilibrada sem alertas críticos.'}`,
        raw: data,
      };
    }

    // 2. Vendas e Desempenho
    if (q.includes('venda') || q.includes('faturamento') || q.includes('ticket')) {
      const rep = await this.analytics.getPerformanceReport();
      return {
        agent: this.analytics.name,
        text: `### 📊 Análise de Vendas (Ponto Analytics)

- **Faturamento Acumulado:** R$ ${rep.faturamentoTotal.toFixed(2)} em ${rep.totalOrders} pedidos.
- **Ticket Médio:** R$ ${rep.ticketMedio.toFixed(2)} por pedido.
- **Distribuição de Canais:** Venda Direta R$ ${rep.canalDistribuicao.direto.toFixed(2)} | iFood R$ ${rep.canalDistribuicao.ifood.toFixed(2)} (${rep.canalDistribuicao.ifoodSharePercent.toFixed(1)}%).
- **Destaque:** ${rep.insights[0]}`,
        raw: rep,
      };
    }

    // 3. Margem e Lucro ("qual produto tem maior margem?")
    if (q.includes('margem') || q.includes('lucro') || q.includes('cfo') || q.includes('rentabilidade')) {
      const fin = await this.cfo.analyzeFinancialHealth();
      const prods = await this.tools.getProductsAnalysis();
      prods.sort((a, b) => b.markupPercent - a.markupPercent);
      const topMargins = prods.slice(0, 3);

      return {
        agent: this.cfo.name,
        text: `### 💰 Rentabilidade & Margens (Chef CFO)

- **Margem Líquida Global da Loja:** ${fin.netMarginPercent.toFixed(1)}%.
- **CMV Atual:** ${fin.cmvPercent.toFixed(1)}% dos custos de insumos e embalagens.
- **Top Produtos por Markup Cadastrado:**
${topMargins.map((p, i) => `  ${i + 1}. **${p.name}** — Markup: ${p.markupPercent}% (Custo aprox: R$ ${p.estimatedCost.toFixed(2)} | Venda: R$ ${p.sellPrice.toFixed(2)})`).join('\n')}

*Recomendação:* Focar divulgação nos itens com markup superior a 35% para proteger a lucratividade líquida.`,
        raw: { fin, topMargins },
      };
    }

    // 4. Estoque e Ruptura ("quais produtos estão próximos de ruptura?")
    if (q.includes('estoque') || q.includes('ruptura') || q.includes('acabando') || q.includes('falta')) {
      const est = await this.estoque.checkStockStatus();
      if (est.criticalCount === 0) {
        return {
          agent: this.estoque.name,
          text: `### 📦 Situação do Estoque (Chef Estoque)

Nenhum produto em risco de ruptura no momento! Todos os itens cadastrados estão com estoque seguro acima do mínimo.`,
          raw: est,
        };
      }

      return {
        agent: this.estoque.name,
        text: `### ⚠️ Alerta de Ruptura de Estoque (Chef Estoque)

Existem **${est.criticalCount} item(ns)** em nível de alerta ou zerados:
${est.criticalList.map(item => `- **${item.name}**: Estoque atual: ${item.currentStock} un (Mínimo recomendado: ${item.minStock} un) -> Status: **${item.status}**`).join('\n')}

*Sugestão imediata:* Encaminhar ordem de preparo para a cozinha reabastecer a câmara fria.`,
        raw: est,
      };
    }

    // 5. Planejamento de Produção ("o que devo produzir amanhã?")
    if (q.includes('produzir') || q.includes('produção') || q.includes('cozinha') || q.includes('preparo')) {
      const prod = await this.executivo.generateDailyProductionPlan();
      if (!prod.hasTasks) {
        return {
          agent: this.executivo.name,
          text: `### 👨‍🍳 Planejamento de Produção (Chef Executivo)

${prod.message} A produção pode se concentrar em pedidos sob encomenda ou preparo de recheios base.`,
          raw: prod,
        };
      }

      return {
        agent: this.executivo.name,
        text: `### 👨‍🍳 Planejamento de Produção Recomendado (Chef Executivo)

${prod.message}

**Lotes Sugeridos:**
${prod.batchesToProduce.map(b => `- **${b.productName}**: Produzir **${b.suggestedProduction} unidades** [Prioridade: ${b.priority}]`).join('\n')}

*Observação:* ${prod.recommendation}`,
        raw: prod,
      };
    }

    // 6. Simulação de Promoção ("posso fazer uma promoção de X%?")
    if (q.includes('promoção') || q.includes('desconto')) {
      const products = await this.tools.getProductsAnalysis();
      const targetProd = products[0] || null;

      if (!targetProd) {
        return {
          agent: this.name,
          text: 'Não tenho dados de produtos suficientes cadastrados para simular essa promoção.',
        };
      }

      // Simula promoção de 15%
      const promoResult = await this.marketing.proposeCampaign({
        productId: targetProd.id,
        discountPercent: 15,
        channel: 'direct',
      });

      return {
        agent: this.marketing.name,
        text: `### 🎯 Avaliação de Promoção Interagentes

${promoResult.summary}
- **Produto:** ${targetProd.name}
- **Preço Original:** R$ ${promoResult.financialImpact?.precoOriginal?.toFixed(2) || '0.00'}
- **Preço com Desconto (15%):** R$ ${promoResult.financialImpact?.precoPromocional?.toFixed(2) || '0.00'}
- **Margem Líquida Resultante:** ${promoResult.financialImpact?.margemLiquidaPercent?.toFixed(1) || '0'}%
- **Status de Governança:** Esta ação requer autorização humana na Central de Aprovações para entrar no ar.`,
        raw: promoResult,
      };
    }

    // 7. Publicidade e Ads ("quanto posso gastar em Ads?")
    if (q.includes('ads') || q.includes('anúncio') || q.includes('publicidade') || q.includes('tráfego')) {
      const adsReport = await this.ads.analyzeAdsPerformance();
      return {
        agent: this.ads.name,
        text: `### 📢 Desempenho de Anúncios (Ponto Ads)

- **Retorno Atual (ROAS):** ${adsReport.roas} (${adsReport.status}).
- **Pedidos Atribuídos:** ${adsReport.pedidosAtribuidos} pedidos.
- **Recomendação de Orçamento:** Manter teto diário atual e investir apenas nos itens com margem comprovada superior a 35%.`,
        raw: adsReport,
      };
    }

    // Fallback com visão do Master
    const gen = await this.getConsolidatedStatus();
    return {
      agent: this.name,
      text: `Olá! Sou o **PONTO MASTER**, orquestrador geral da Doce & Ponto.

Como posso ajudar você neste momento?
- Digite: *"Como está minha loja hoje?"* para o diagnóstico consolidado de 360°.
- Digite: *"Quais produtos estão em risco de ruptura?"* para consulta ao Chef Estoque.
- Digite: *"O que devo produzir amanhã?"* para o plano de lotes do Chef Executivo.
- Digite: *"Qual produto tem maior margem?"* para o relatório de CMV do Chef CFO.
- Digite: *"Posso fazer uma promoção de 15%?"* para simulação financeira entre Marketing e CFO.`,
      raw: gen,
    };
  }
}

window.PontoMaster = PontoMaster;
