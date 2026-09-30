/**
 * PONTO OS - IFOOD GATEWAY
 * Camada de integração segura com a API Oficial do iFood.
 * 
 * Arquitetura de Segurança:
 * Agentes NUNCA acessam diretamente tokens, secrets ou credenciais privadas.
 * O fluxo é estritamente:
 * AGENTE -> PONTO MASTER -> PERMISSION LAYER -> IFOOD GATEWAY -> SUPABASE / IFOOD API
 */

class IFoodGateway {
  constructor(supabaseClient) {
    this.supabase = supabaseClient;
    this.isConfigured = false;
    this.cachedOrders = [];
    this.merchantStatus = 'OPEN'; // 'OPEN' ou 'CLOSED'
  }

  /**
   * Inicializa o status do gateway consultando a tabela ifood_merchants no Supabase
   */
  async init() {
    try {
      const { data: merchants } = await this.supabase
        .from('ifood_merchants')
        .select('*')
        .limit(1);

      if (merchants && merchants.length > 0) {
        this.merchantStatus = merchants[0].status || 'OPEN';
        this.isConfigured = true;
      }
    } catch (e) {
      console.warn('[IFoodGateway] Falha ao verificar merchant status no Supabase:', e);
    }
  }

  /**
   * Retorna os pedidos ativos sincronizados do iFood
   */
  async getActiveOrders() {
    try {
      const { data: orders, error } = await this.supabase
        .from('ifood_orders')
        .select('*')
        .in('status', ['PLACED', 'CONFIRMED', 'DISPATCHED'])
        .order('order_created_at', { ascending: false });

      if (error) throw error;
      this.cachedOrders = orders || [];
      return this.cachedOrders;
    } catch (e) {
      console.error('[IFoodGateway] Erro ao carregar pedidos ativos:', e);
      return [];
    }
  }

  /**
   * Retorna o status da operação do restaurante
   */
  async getMerchantStatus() {
    return {
      status: this.merchantStatus,
      isConfigured: this.isConfigured,
      platform: 'iFood Merchant API Oficial v2',
      averagePreparationMinutes: 25,
      deliveryPlan: 'Entrega Própria / iFood Parceiro (26,2%)',
    };
  }

  /**
   * Sincroniza novo pedido capturado oficialmente para a tabela de vendas e estoque do PONTO OS
   */
  async processIncomingOrder(orderPayload) {
    // 1. Gravar em ifood_orders
    const { error: orderErr } = await this.supabase
      .from('ifood_orders')
      .upsert({
        id: orderPayload.id,
        order_code: orderPayload.order_code,
        status: orderPayload.status || 'CONFIRMED',
        customer_name: orderPayload.customer_name || 'Cliente iFood',
        items: orderPayload.items || [],
        total_value: orderPayload.total_value || 0,
        subtotal: orderPayload.subtotal || orderPayload.total_value,
        payment_method: orderPayload.payment_method || 'iFood Pay',
        order_created_at: orderPayload.order_created_at || new Date().toISOString(),
      });

    if (orderErr) {
      console.error('[IFoodGateway] Erro ao gravar pedido ifood_orders:', orderErr);
      return { success: false, error: orderErr.message };
    }

    // 2. Criação correspondente na tabela sales para consolidação financeira com taxa de 26.2%
    const ifoodRate = 26.2;
    const grossVal = Number(orderPayload.total_value || 0);
    const commVal = grossVal * (ifoodRate / 100);
    const estimatedCost = grossVal * 0.35; // Custo estimado aproximado
    const netVal = grossVal - commVal - estimatedCost;

    const { error: saleErr } = await this.supabase.from('sales').insert([{
      productname: `Pedido iFood #${orderPayload.order_code}`,
      quantity: (orderPayload.items || []).length || 1,
      totalvalue: grossVal,
      totalcost: estimatedCost,
      totalprofit: grossVal - estimatedCost,
      sellertype: 'ifood',
      sellername: 'iFood Loja Oficial',
      commissionpercent: ifoodRate,
      commissionvalue: commVal,
      netprofit: netVal,
      saledate: new Date().toISOString(),
      notes: `[Pedido iFood #${orderPayload.order_code}] Importado automaticamente pelo iFood Gateway`,
    }]);

    if (saleErr) {
      console.warn('[IFoodGateway] Aviso ao espelhar em sales:', saleErr);
    }

    return { success: true, orderId: orderPayload.id };
  }
}

window.IFoodGateway = IFoodGateway;
