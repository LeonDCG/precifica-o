/**
 * PONTO OS - CENTRAL DE APROVAÇÕES (AÇÕES DA IA)
 * Tela de governança humana onde o proprietário avalia e decide sobre propostas de IA.
 */

class ApprovalsCenterUI {
  constructor(supabaseClient, containerId) {
    this.supabase = supabaseClient;
    this.container = document.getElementById(containerId);
  }

  async render() {
    if (!this.container) return;

    this.container.innerHTML = `
      <div class="command-loading">
        <div class="spinner"></div>
        <p>Buscando ações de IA pendentes de autorização humana...</p>
      </div>
    `;

    try {
      const { data: actions, error } = await this.supabase
        .from('agent_actions')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      this.renderList(actions || []);
    } catch (e) {
      console.error('[ApprovalsCenterUI] Erro ao carregar ações:', e);
      this.container.innerHTML = `
        <div class="alert-banner warning">
          <strong>Erro ao carregar ações da IA:</strong> ${e.message}
        </div>
      `;
    }
  }

  renderList(actions) {
    const pendingActions = actions.filter(a => a.status === 'pending');
    const pastActions = actions.filter(a => a.status !== 'pending');

    // Atualiza badge no cabeçalho
    const badge = document.getElementById('headerApprovalBadge');
    if (badge) {
      badge.textContent = pendingActions.length;
      badge.style.display = pendingActions.length > 0 ? 'inline-flex' : 'none';
    }

    const html = `
      <div class="ponto-os-approvals-center">
        <div class="approvals-header-row">
          <div>
            <h2>Central de Aprovações de IA</h2>
            <p>Governança e controle humano de ações recomendadas pelos agentes</p>
          </div>
          <button class="btn btn-secondary" onclick="window.pontoOS.refreshApprovals()">
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M23 4v6h-6M1 20v-6h6M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
            <span>Atualizar Fila</span>
          </button>
        </div>

        <!-- SEÇÃO: AÇÕES PENDENTES -->
        <h3 class="queue-section-title">
          <span>⏳</span> Ações Aguardando Decisão (${pendingActions.length})
        </h3>

        ${pendingActions.length === 0 ? `
          <div class="card empty-approvals-card">
            <div class="empty-icon">🛡️</div>
            <h4>Nenhuma ação pendente de aprovação</h4>
            <p class="text-muted">Todos os agentes estão operando dentro dos parâmetros de rotina ou as propostas já foram avaliadas.</p>
          </div>
        ` : `
          <div class="actions-cards-list">
            ${pendingActions.map(action => this.renderActionCard(action)).join('')}
          </div>
        `}

        <!-- SEÇÃO: HISTÓRICO DE AÇÕES DECIDIDAS -->
        ${pastActions.length > 0 ? `
          <h3 class="queue-section-title mt-5">
            <span>📋</span> Histórico de Decisões do Operador
          </h3>
          <div class="card">
            <div class="table-responsive">
              <table class="data-table">
                <thead>
                  <tr>
                    <th>Data</th>
                    <th>Agente</th>
                    <th>Ação Proposta</th>
                    <th>Risco</th>
                    <th>Status</th>
                    <th>Decisão Por</th>
                  </tr>
                </thead>
                <tbody>
                  ${pastActions.map(a => `
                    <tr>
                      <td>${new Date(a.created_at).toLocaleString('pt-BR')}</td>
                      <td><strong>${a.agent_name}</strong></td>
                      <td>${a.title}</td>
                      <td><span class="risk-pill ${a.risk_level}">${a.risk_level.toUpperCase()}</span></td>
                      <td>
                        <span class="status-pill status-${a.status}">
                          ${a.status === 'approved' ? 'APROVADA' : (a.status === 'rejected' ? 'RECUSADA' : a.status.toUpperCase())}
                        </span>
                      </td>
                      <td>${a.approved_by || 'Proprietário'}</td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>
            </div>
          </div>
        ` : ''}
      </div>
    `;

    this.container.innerHTML = html;
  }

  renderActionCard(action) {
    const riskClass = action.risk_level || 'medium';
    return `
      <div class="action-approval-card" id="action-card-${action.id}">
        <div class="action-card-header">
          <div class="action-agent-badge">
            <span class="agent-icon-dot"></span>
            <strong>${action.agent_name}</strong>
          </div>
          <div class="action-risk-badge risk-${riskClass}">
            RISCO: ${riskClass.toUpperCase()}
          </div>
        </div>

        <div class="action-card-body">
          <h4 class="action-title">${action.title}</h4>
          ${action.description ? `<p class="action-desc">${action.description}</p>` : ''}

          <div class="action-details-grid">
            <div class="detail-box">
              <span class="detail-label">Motivo Apresentado:</span>
              <p class="detail-text">${action.reason}</p>
            </div>
            <div class="detail-box">
              <span class="detail-label">Impacto Estimado:</span>
              <p class="detail-text text-highlight">${action.impact || 'Impacto operacional não informado.'}</p>
            </div>
          </div>

          ${action.data_used && Object.keys(action.data_used).length > 0 ? `
            <details class="action-raw-data-toggle">
              <summary>Ver dados operacionais utilizados pela IA</summary>
              <pre>${JSON.stringify(action.data_used, null, 2)}</pre>
            </details>
          ` : ''}
        </div>

        <div class="action-card-footer">
          <button class="btn btn-danger" onclick="window.pontoOS.rejectAction(${action.id})">
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            <span>[ RECUSAR ]</span>
          </button>
          <button class="btn btn-success" onclick="window.pontoOS.approveAction(${action.id})">
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
            <span>[ APROVAR AÇÃO ]</span>
          </button>
        </div>
      </div>
    `;
  }
}

window.ApprovalsCenterUI = ApprovalsCenterUI;
