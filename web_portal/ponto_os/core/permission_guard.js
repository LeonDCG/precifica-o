/**
 * PONTO OS - PERMISSION GUARD & AUDIT MATRIX
 * Implementa os 4 níveis de autonomia e a proteção estrita de ações críticas.
 * 
 * NÍVEIS DE AUTONOMIA:
 * NÍVEL 0 — SOMENTE LEITURA: Consultar, analisar, gerar relatórios. Sem modificações.
 * NÍVEL 1 — RECOMENDAÇÃO: Analisar e sugerir ações estruturadas, sem executar.
 * NÍVEL 2 — APROVAÇÃO HUMANA: Prepara a ação com proposta, motivo, impacto, risco e dados.
 * NÍVEL 3 — AUTOMAÇÃO CONTROLADA: Execução automática apenas para tarefas rotineiras pré-autorizadas.
 */

class PermissionGuard {
  static LEVELS = {
    READ_ONLY: 0,
    RECOMMENDATION: 1,
    HUMAN_APPROVAL: 2,
    CONTROLLED_AUTOMATION: 3,
  };

  static RISK_LEVELS = {
    LOW: 'low',
    MEDIUM: 'medium',
    HIGH: 'high',
    CRITICAL: 'critical',
  };

  // Catálogo de ações críticas que OBRIGATORIAMENTE exigem aprovação humana (Nível 2)
  static CRITICAL_ACTIONS = [
    'UPDATE_PRODUCT_PRICE',
    'UPDATE_IFOOD_PRICE',
    'APPLY_DISCOUNT_PROMOTION',
    'INCREASE_ADS_BUDGET',
    'PAUSE_STORE_MERCHANT',
    'BULK_CANCEL_ORDERS',
    'FINANCIAL_ADJUSTMENT',
    'DELETE_CATALOG_ITEM',
    'UPDATE_BUSINESS_RULE',
  ];

  /**
   * Avalia uma intenção de ação de um agente antes de qualquer execução.
   * @param {Object} actionIntent
   * @returns {Object} { allowed: boolean, requiresApproval: boolean, riskLevel: string, reason: string }
   */
  static evaluateAction(actionIntent) {
    const { actionType, agentName, payload } = actionIntent;

    // Se for uma ação crítica, nunca permite automação direta
    if (this.CRITICAL_ACTIONS.includes(actionType)) {
      return {
        allowed: false, // Não pode executar direto
        requiresApproval: true,
        riskLevel: this.determineRisk(actionType, payload),
        permissionLevel: this.LEVELS.HUMAN_APPROVAL,
        message: `Ação crítica "${actionType}" do agente ${agentName} submetida para aprovação humana obrigatória.`,
      };
    }

    // Ações rotineiras de baixo risco (ex: log, leitura, notificação)
    if (actionType.startsWith('READ_') || actionType.startsWith('ANALYZE_')) {
      return {
        allowed: true,
        requiresApproval: false,
        riskLevel: this.RISK_LEVELS.LOW,
        permissionLevel: this.LEVELS.READ_ONLY,
        message: 'Ação de leitura concedida.',
      };
    }

    // Ações de recomendação padrão
    return {
      allowed: false,
      requiresApproval: true,
      riskLevel: this.RISK_LEVELS.MEDIUM,
      permissionLevel: this.LEVELS.HUMAN_APPROVAL,
      message: 'Ação requer confirmação do operador.',
    };
  }

  /**
   * Determina o nível de risco de acordo com o impacto financeiro/operacional
   */
  static determineRisk(actionType, payload = {}) {
    if (actionType === 'PAUSE_STORE_MERCHANT' || actionType === 'BULK_CANCEL_ORDERS') {
      return this.RISK_LEVELS.CRITICAL;
    }
    if (actionType === 'UPDATE_PRODUCT_PRICE' || actionType === 'INCREASE_ADS_BUDGET') {
      return this.RISK_LEVELS.HIGH;
    }
    if (actionType === 'APPLY_DISCOUNT_PROMOTION') {
      const discount = payload.discountPercent || 0;
      return discount > 15 ? this.RISK_LEVELS.HIGH : this.RISK_LEVELS.MEDIUM;
    }
    return this.RISK_LEVELS.MEDIUM;
  }
}

window.PermissionGuard = PermissionGuard;
