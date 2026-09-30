/**
 * AGENTE: PONTO ANALYTICS
 * Analista de inteligência de dados da Doce & Ponto.
 * Monitora tendências, ticket médio, curva ABC, sazonalidade e projeções.
 */

class PontoAnalytics {
  constructor(tools, memory) {
    this.name = 'PONTO ANALYTICS';
    this.tools = tools;
    this.memory = memory;
  }

  async getPerformanceReport() {
    const monthKPIs = await this.tools.getMonthKPIs();
    const sales = monthKPIs.sales || [];

    // Agrupamento por produto (Curva ABC de Vendas)
    const productSales = new Map();
    sales.forEach(s => {
      const name = s.productname || 'Desconhecido';
      const current = productSales.get(name) || { name, quantity: 0, revenue: 0, profit: 0 };
      current.quantity += Number(s.quantity || 0);
      current.revenue += Number(s.totalvalue || 0);
      current.profit += Number(s.netprofit || 0);
      productSales.set(name, current);
    });

    const ranking = Array.from(productSales.values())
      .sort((a, b) => b.revenue - a.revenue);

    const topProduct = ranking[0] || null;
    const ticketMedio = sales.length > 0 ? (monthKPIs.totalRevenue / sales.length) : 0;

    return {
      agent: this.name,
      totalOrders: sales.length,
      faturamentoTotal: monthKPIs.totalRevenue,
      ticketMedio,
      topRanking: ranking.slice(0, 5),
      topProduct,
      canalDistribuicao: {
        direto: monthKPIs.directRevenue,
        ifood: monthKPIs.ifoodRevenue,
        ifoodSharePercent: monthKPIs.totalRevenue > 0 
          ? ((monthKPIs.ifoodRevenue / monthKPIs.totalRevenue) * 100) 
          : 0,
      },
      insights: [
        topProduct ? `Carro-chefe do mês: "${topProduct.name}" com R$ ${topProduct.revenue.toFixed(2)} faturados.` : 'Histórico de vendas ainda incipiente.',
        ticketMedio > 0 ? `Ticket médio praticado: R$ ${ticketMedio.toFixed(2)} por pedido.` : 'Aguardando pedidos.',
      ],
    };
  }
}

window.PontoAnalytics = PontoAnalytics;
