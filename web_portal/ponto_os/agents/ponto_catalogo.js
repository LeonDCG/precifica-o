/**
 * AGENTE: PONTO CATÁLOGO
 * Administrador do mix de produtos, vitrine e precificação da Doce & Ponto.
 * Regras: Antes de alterar preço -> consultar CFO. Antes de promover -> consultar Estoque.
 */

class PontoCatalogo {
  constructor(tools, memory) {
    this.name = 'PONTO CATÁLOGO';
    this.tools = tools;
    this.memory = memory;
  }

  async auditCatalogHealth() {
    const products = await this.tools.getProductsAnalysis();

    const issues = [];
    const missingPhotos = [];
    const lowMarginProducts = [];

    products.forEach(p => {
      if (p.markupPercent < 20) {
        lowMarginProducts.push({ name: p.name, margin: p.markupPercent });
        issues.push(`Produto "${p.name}" com markup de apenas ${p.markupPercent}% (Abaixo do mínimo recomendado de 20%).`);
      }
      if (p.ifoodPrice > 0 && p.ifoodPrice <= p.sellPrice) {
        issues.push(`Produto "${p.name}": Preço iFood (R$ ${p.ifoodPrice.toFixed(2)}) igual ou menor que balcão (R$ ${p.sellPrice.toFixed(2)}). Risco de erosão de margem pelas taxas de 26,2%.`);
      }
    });

    return {
      agent: this.name,
      totalCatalogItems: products.length,
      issuesFound: issues.length,
      issuesList: issues,
      recommendations: [
        'Revisar repasse da taxa do iFood (26,2%) nos produtos onde o preço iFood está defasado.',
        'Manter fotos com iluminação natural em todos os produtos para elevar conversão na vitrine.',
      ],
    };
  }
}

window.PontoCatalogo = PontoCatalogo;
