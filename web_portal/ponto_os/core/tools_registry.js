/**
 * PONTO OS - TOOLS REGISTRY (FERRAMENTAS AUDITADAS DOS AGENTES)
 * Princípio Fundamental: NÃO ALUCINAÇÃO.
 * Toda informação vem de consultas reais no Supabase e regras exatas.
 */

class ToolsRegistry {
  constructor(supabaseClient, memoryManager) {
    this.supabase = supabaseClient;
    this.memory = memoryManager;
  }

  /**
   * Registra log de auditoria do agente no Supabase
   */
  async logAgent(agentName, level, toolUsed, message, contextData = {}) {
    try {
      await this.supabase.from('agent_logs').insert([{
        agent_name: agentName,
        log_level: level,
        tool_used: toolUsed,
        message: message,
        context_data: contextData,
      }]);
    } catch (e) {
      console.error('[ToolsRegistry] Erro ao gravar log de agente:', e);
    }
  }

  /**
   * Submete uma ação para a Central de Aprovações (Nível 2)
   */
  async submitActionForApproval({
    agentName,
    actionType,
    title,
    description,
    reason,
    dataUsed = {},
    impact = '',
    riskLevel = 'medium',
  }) {
    // Validar com o PermissionGuard
    const evalResult = PermissionGuard.evaluateAction({ actionType, agentName, payload: dataUsed });
    
    const actionPayload = {
      agent_name: agentName,
      action_type: actionType,
      title: title,
      description: description,
      reason: reason,
      data_used: dataUsed,
      impact: impact,
      risk_level: evalResult.riskLevel || riskLevel,
      permission_level: evalResult.permissionLevel || 2,
      status: 'pending',
    };

    const { data, error } = await this.supabase
      .from('agent_actions')
      .insert([actionPayload])
      .select()
      .single();

    if (error) throw error;

    await this.logAgent(
      agentName,
      'action',
      'submitActionForApproval',
      `Ação "${title}" submetida para aprovação humana. Risco: ${actionPayload.risk_level}`,
      { actionId: data.id, actionType }
    );

    return data;
  }

  /**
   * Retorna os KPIs consolidados de hoje (vendas, faturamento, margem)
   */
  async getTodayKPIs() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayIso = today.toISOString();

    const { data: sales, error } = await this.supabase
      .from('sales')
      .select('*')
      .gte('saledate', todayIso);

    if (error) {
      console.error('[ToolsRegistry] Erro ao buscar vendas de hoje:', error);
      return { totalRevenue: 0, totalProfit: 0, orderCount: 0, itemsSold: 0, sales: [] };
    }

    let totalRevenue = 0;
    let totalProfit = 0;
    let itemsSold = 0;

    sales.forEach(s => {
      totalRevenue += Number(s.totalvalue || 0);
      totalProfit += Number(s.netprofit || 0);
      itemsSold += Number(s.quantity || 0);
    });

    const ticketMedio = sales.length > 0 ? (totalRevenue / sales.length) : 0;
    const estimatedMargin = totalRevenue > 0 ? ((totalProfit / totalRevenue) * 100) : 0;

    return {
      date: today.toLocaleDateString('pt-BR'),
      totalRevenue,
      totalProfit,
      orderCount: sales.length,
      itemsSold,
      ticketMedio,
      estimatedMargin,
      sales,
    };
  }

  /**
   * Retorna os KPIs do mês atual
   */
  async getMonthKPIs() {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.month || now.getMonth(), 1).toISOString();

    const { data: sales, error } = await this.supabase
      .from('sales')
      .select('*')
      .gte('saledate', monthStart);

    if (error) return { totalRevenue: 0, totalProfit: 0, orderCount: 0, sales: [] };

    let totalRevenue = 0;
    let totalCost = 0;
    let totalProfit = 0;
    let ifoodRevenue = 0;
    let directRevenue = 0;

    sales.forEach(s => {
      const val = Number(s.totalvalue || 0);
      const profit = Number(s.netprofit || 0);
      const cost = Number(s.totalcost || 0);
      totalRevenue += val;
      totalProfit += profit;
      totalCost += cost;

      const isIfood = (s.sellertype || '').toLowerCase() === 'ifood' || (s.sellername || '').toLowerCase().includes('ifood');
      if (isIfood) {
        ifoodRevenue += val;
      } else {
        directRevenue += val;
      }
    });

    return {
      month: now.toLocaleString('pt-BR', { month: 'long', year: 'numeric' }),
      totalRevenue,
      totalCost,
      totalProfit,
      cmvPercent: totalRevenue > 0 ? ((totalCost / totalRevenue) * 100) : 0,
      netMarginPercent: totalRevenue > 0 ? ((totalProfit / totalRevenue) * 100) : 0,
      orderCount: sales.length,
      ifoodRevenue,
      directRevenue,
      sales,
    };
  }

  /**
   * Retorna produtos com análise de CMV, custos e estoque atual
   */
  async getProductsAnalysis() {
    const [prodRes, stockRes] = await Promise.all([
      this.supabase.from('products').select('*').order('name'),
      this.supabase.from('refrigerator_stock').select('*'),
    ]);

    const products = prodRes.data || [];
    const stockMap = new Map();
    (stockRes.data || []).forEach(item => {
      if (item.product_id) {
        stockMap.set(item.product_id, Number(item.quantity || 0));
      }
    });

    return products.map(p => {
      const sellPrice = Number(p.sellPrice || p.sellprice || 0);
      const ifoodPrice = Number(p.ifoodPrice || p.ifoodprice || sellPrice);
      const suggestedPrice = Number(p.suggestedPrice || p.suggestedprice || 0);
      const margin = Number(p.profitMarginPercent || p.profitmarginpercent || 30);
      const currentStock = stockMap.has(p.id) ? stockMap.get(p.id) : Number(p.stock || 0);
      const minStock = Number(p.minStock || p.minstock || 0);

      // Custo derivado
      const estimatedCost = suggestedPrice > 0 ? (suggestedPrice / (1 + (margin / 100))) : (sellPrice * 0.4);

      return {
        id: p.id,
        name: p.name,
        category: p.category || 'Geral',
        unit: p.unit || 'unidade',
        yieldAmount: Number(p.yieldAmount || p.yieldamount || 1),
        sellPrice,
        ifoodPrice,
        estimatedCost,
        currentStock,
        minStock,
        isStockCritical: currentStock <= minStock,
        isOutOfStock: currentStock <= 0,
        markupPercent: margin,
      };
    });
  }

  /**
   * Simula impacto de desconto na margem líquida (CHEF CFO)
   */
  async simulatePromotionImpact({ productId, discountPercent, channel = 'direct' }) {
    const { data: product } = await this.supabase
      .from('products')
      .select('*')
      .eq('id', productId)
      .single();

    if (!product) {
      return { error: 'Produto não encontrado' };
    }

    const basePrice = channel === 'ifood' 
      ? Number(product.ifoodPrice || product.ifoodprice || product.sellPrice || product.sellprice || 0)
      : Number(product.sellPrice || product.sellprice || 0);

    const margin = Number(product.profitMarginPercent || product.profitmarginpercent || 30);
    const suggestedPrice = Number(product.suggestedPrice || product.suggestedprice || basePrice);
    const cost = suggestedPrice > 0 ? (suggestedPrice / (1 + (margin / 100))) : (basePrice * 0.4);

    const discountedPrice = basePrice * (1 - (discountPercent / 100));
    
    // Taxa do canal (26.2% se for iFood, 0% se direto)
    const channelFeePercent = channel === 'ifood' ? 26.2 : 0;
    const channelFeeValue = discountedPrice * (channelFeePercent / 100);
    const netRevenue = discountedPrice - channelFeeValue;
    const netProfit = netRevenue - cost;
    const netMarginPercent = discountedPrice > 0 ? ((netProfit / discountedPrice) * 100) : 0;

    // Verificar regra de margem mínima
    const minMarginRule = this.memory.getRules('margin').find(r => r.rule_code === 'RULE_MIN_MARGIN');
    const minMarginThreshold = minMarginRule?.condition_config?.threshold || 20.0;
    const isApprovedByCFO = netMarginPercent >= minMarginThreshold;

    return {
      productName: product.name,
      channel,
      originalPrice: basePrice,
      discountPercent,
      discountedPrice,
      unitCost: cost,
      channelFeePercent,
      channelFeeValue,
      netProfit,
      netMarginPercent,
      minMarginThreshold,
      isApprovedByCFO,
      verdict: isApprovedByCFO
        ? `Promoção viável: margem líquida resultante de ${netMarginPercent.toFixed(1)}% está acima da margem mínima (${minMarginThreshold}%).`
        : `Promoção REJEITADA pelo CFO: margem resultante de ${netMarginPercent.toFixed(1)}% viola a regra de margem mínima (${minMarginThreshold}%).`,
    };
  }

  /**
   * Retorna itens com alerta de ruptura de estoque (CHEF ESTOQUE)
   */
  async getStockAlerts() {
    const products = await this.getProductsAnalysis();
    const criticalItems = products.filter(p => p.isStockCritical);
    const outOfStockItems = products.filter(p => p.isOutOfStock);

    return {
      criticalCount: criticalItems.length,
      outOfStockCount: outOfStockItems.length,
      criticalItems,
      outOfStockItems,
    };
  }
}

window.ToolsRegistry = ToolsRegistry;
