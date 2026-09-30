/**
 * PONTO OS - CENTRAL DE COMANDO
 * Painel Executivo 360° da Doce & Ponto
 * Seções: Hoje, Operação, Estoque, Financeiro, Marketing e Alertas de IA
 */

class CommandCenterUI {
  constructor(pontoMaster, containerId) {
    this.master = pontoMaster;
    this.container = document.getElementById(containerId);
  }

  async render() {
    if (!this.container) return;

    this.container.innerHTML = `
      <div class="command-loading">
        <div class="spinner"></div>
        <p>Sincronizando Central de Comando com os agentes especialistas...</p>
      </div>
    `;

    try {
      const data = await this.master.getConsolidatedStatus();
      this.renderDashboard(data);
    } catch (e) {
      console.error('[CommandCenterUI] Erro ao renderizar Central de Comando:', e);
      this.container.innerHTML = `
        <div class="alert-banner warning">
          <strong>Erro ao sincronizar Central de Comando:</strong> ${e.message}
        </div>
      `;
    }
  }

  renderDashboard(data) {
    const { financeiro, estoque, analytics, producao, operacao, ads, customer, priorityAlerts } = data;

    const html = `
      <div class="ponto-os-command-center">
        <!-- CABEÇALHO DA CENTRAL DE COMANDO -->
        <div class="command-header-bar">
          <div class="command-header-title">
            <div class="os-badge-pill">
              <span class="live-dot"></span>
              <span>PONTO OS 2.0 • INTELIGÊNCIA EM TEMPO REAL</span>
            </div>
            <h2>Central de Comando Operacional</h2>
            <p>Visão executiva integrada entre os 9 Agentes Especialistas da Doce & Ponto</p>
          </div>
          <div class="command-header-actions">
            <button class="btn btn-secondary" onclick="window.pontoOS.refreshCommandCenter()">
              <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M23 4v6h-6M1 20v-6h6M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
              <span>Sincronizar IA</span>
            </button>
            <button class="btn btn-primary" onclick="window.switchView('ponto-approvals')">
              <span>Central de Aprovações</span>
              <span class="approval-badge-count" id="headerApprovalBadge">0</span>
            </button>
          </div>
        </div>

        <!-- ALERTAS PRIORITÁRIOS DA IA -->
        ${priorityAlerts.length > 0 ? `
          <div class="os-alerts-section">
            ${priorityAlerts.map(alert => `
              <div class="os-alert-card ${alert.severity.toLowerCase()}">
                <div class="alert-tag">${alert.agent}</div>
                <div class="alert-desc">${alert.message}</div>
              </div>
            `).join('')}
          </div>
        ` : `
          <div class="os-alert-card positive">
            <div class="alert-tag">PONTO GUARDIAN</div>
            <div class="alert-desc">Operação equilibrada: Nenhum gargalo crítico identificado neste momento.</div>
          </div>
        `}

        <!-- GRID 1: HOJE (INDICADORES IMEDIATOS) -->
        <div class="command-section-title">
          <span>📅</span> <h3>1. Indicadores de Hoje</h3>
        </div>
        <div class="os-metrics-grid">
          <div class="os-metric-card">
            <span class="metric-label">FATURAMENTO HOJE</span>
            <span class="metric-value">R$ ${financeiro.todayRevenue.toFixed(2)}</span>
            <span class="metric-sub">${operacao.ordersToday} pedidos concluídos</span>
          </div>
          <div class="os-metric-card">
            <span class="metric-label">MARGEM ESTIMADA</span>
            <span class="metric-value text-green">${financeiro.netMarginPercent.toFixed(1)}%</span>
            <span class="metric-sub">CMV Médio: ${financeiro.cmvPercent.toFixed(1)}%</span>
          </div>
          <div class="os-metric-card">
            <span class="metric-label">TICKET MÉDIO</span>
            <span class="metric-value">R$ ${analytics.ticketMedio.toFixed(2)}</span>
            <span class="metric-sub">Venda direta + iFood</span>
          </div>
          <div class="os-metric-card">
            <span class="metric-label">STATUS DA LOJA</span>
            <span class="metric-value text-teal">${operacao.storeStatus}</span>
            <span class="metric-sub">Tempo Médio: ~${operacao.estimatedAveragePrepTimeMinutes} min</span>
          </div>
        </div>

        <!-- GRID 2: FINANCEIRO & ESTOQUE CRÍTICO -->
        <div class="os-split-grid">
          <!-- CARD FINANCEIRO (CHEF CFO) -->
          <div class="os-panel-card">
            <div class="panel-header">
              <div class="panel-title-group">
                <span class="agent-avatar">💰</span>
                <div>
                  <h4>CHEF CFO — Diagnóstico Financeiro</h4>
                  <span class="panel-subtitle">Mês: ${financeiro.period}</span>
                </div>
              </div>
              <span class="badge ${financeiro.healthStatus.includes('ATENÇÃO') ? 'badge-warning' : 'badge-success'}">${financeiro.healthStatus}</span>
            </div>
            <div class="panel-body">
              <div class="kpi-mini-row">
                <div>
                  <span class="kpi-mini-label">Faturamento do Mês:</span>
                  <strong class="kpi-mini-val">R$ ${financeiro.faturamentoMes.toFixed(2)}</strong>
                </div>
                <div>
                  <span class="kpi-mini-label">Lucro Líquido Real:</span>
                  <strong class="kpi-mini-val text-green">R$ ${financeiro.lucroLiquidoMes.toFixed(2)}</strong>
                </div>
                <div>
                  <span class="kpi-mini-label">CMV Atual:</span>
                  <strong class="kpi-mini-val ${financeiro.cmvPercent > 35 ? 'text-red' : ''}">${financeiro.cmvPercent.toFixed(1)}%</strong>
                </div>
              </div>
              <div class="agent-recommendation-box">
                <strong>Recomendação do CFO:</strong>
                <ul>
                  ${financeiro.recommendations.map(r => `<li>${r}</li>`).join('')}
                </ul>
              </div>
            </div>
          </div>

          <!-- CARD ESTOQUE & RUPTURA (CHEF ESTOQUE) -->
          <div class="os-panel-card">
            <div class="panel-header">
              <div class="panel-title-group">
                <span class="agent-avatar">📦</span>
                <div>
                  <h4>CHEF ESTOQUE — Saúde da Pronta Entrega</h4>
                  <span class="panel-subtitle">${estoque.totalProducts} produtos monitorados</span>
                </div>
              </div>
              <span class="badge ${estoque.hasRuptureRisk ? 'badge-danger' : 'badge-success'}">
                ${estoque.hasRuptureRisk ? `${estoque.criticalCount} Críticos` : 'Estoque 100%'}
              </span>
            </div>
            <div class="panel-body">
              <p class="panel-text">${estoque.summary}</p>
              ${estoque.criticalList.length > 0 ? `
                <div class="critical-items-table-wrapper">
                  <table class="os-mini-table">
                    <thead>
                      <tr>
                        <th>Produto</th>
                        <th>Atual</th>
                        <th>Mínimo</th>
                        <th>Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      ${estoque.criticalList.map(item => `
                        <tr>
                          <td><strong>${item.name}</strong></td>
                          <td>${item.currentStock} un</td>
                          <td>${item.minStock} un</td>
                          <td><span class="tag-status ${item.status.toLowerCase()}">${item.status}</span></td>
                        </tr>
                      `).join('')}
                    </tbody>
                  </table>
                </div>
              ` : `
                <div class="empty-state-positive">
                  <span>✅</span> Câmara fria abastecida com margem de segurança.
                </div>
              `}
            </div>
          </div>
        </div>

        <!-- GRID 3: PRODUÇÃO & OPERAÇÕES & MARKETING -->
        <div class="os-split-grid">
          <!-- CARD PRODUÇÃO (CHEF EXECUTIVO) -->
          <div class="os-panel-card">
            <div class="panel-header">
              <div class="panel-title-group">
                <span class="agent-avatar">👨‍🍳</span>
                <div>
                  <h4>CHEF EXECUTIVO — Plano de Produção</h4>
                  <span class="panel-subtitle">Planejamento diário da cozinha</span>
                </div>
              </div>
            </div>
            <div class="panel-body">
              <p class="panel-text">${producao.message}</p>
              ${producao.batchesToProduce.length > 0 ? `
                <ul class="production-batch-list">
                  ${producao.batchesToProduce.map(b => `
                    <li class="batch-item ${b.priority.toLowerCase()}">
                      <div class="batch-info">
                        <strong>${b.productName}</strong>
                        <span>Meta sugerida: <strong>${b.suggestedProduction} unidades</strong></span>
                      </div>
                      <span class="batch-priority-tag">${b.priority}</span>
                    </li>
                  `).join('')}
                </ul>
                <div class="mt-2 text-right">
                  <button class="btn btn-sm btn-secondary" onclick="window.openProductionModal()">Registrar Produção</button>
                </div>
              ` : `
                <div class="empty-state-positive">
                  <span>🍰</span> Nenhuma demanda urgente de fornada identificada.
                </div>
              `}
            </div>
          </div>

          <!-- CARD MARKETING & ADS (PONTO MARKETING + ADS) -->
          <div class="os-panel-card">
            <div class="panel-header">
              <div class="panel-title-group">
                <span class="agent-avatar">🎯</span>
                <div>
                  <h4>PONTO MARKETING & ADS — Performance Comercial</h4>
                  <span class="panel-subtitle">Retorno e posicionamento</span>
                </div>
              </div>
              <span class="badge badge-purple">ROAS: ${ads.roas}</span>
            </div>
            <div class="panel-body">
              <div class="kpi-mini-row">
                <div>
                  <span class="kpi-mini-label">Pedidos via Ads:</span>
                  <strong>${ads.pedidosAtribuidos}</strong>
                </div>
                <div>
                  <span class="kpi-mini-label">Faturamento Atribuído:</span>
                  <strong>R$ ${ads.faturamentoAtribuido.toFixed(2)}</strong>
                </div>
                <div>
                  <span class="kpi-mini-label">Satisfação Clientes:</span>
                  <strong>${customer.notaMediaLoja} ⭐</strong>
                </div>
              </div>
              <div class="agent-recommendation-box mt-3">
                <strong>Diretriz Comercial Ativa:</strong>
                <p class="mb-0 text-muted">${ads.recommendations[0]}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;

    this.container.innerHTML = html;
  }
}

window.CommandCenterUI = CommandCenterUI;
