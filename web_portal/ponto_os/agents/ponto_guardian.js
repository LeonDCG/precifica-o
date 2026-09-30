/**
 * AGENTE: PONTO GUARDIAN
 * Guardião de segurança, conformidade e integridade operacional.
 * Intercepta intenções de ação de todos os agentes, bloqueia incongruências e garante aprovação humana.
 */

class PontoGuardian {
  constructor(tools, memory) {
    this.name = 'PONTO GUARDIAN';
    this.tools = tools;
    this.memory = memory;
  }

  /**
   * Valida uma ação proposta contra as regras de negócio ativas
   */
  async inspectAction(actionIntent) {
    const { agentName, actionType, payload } = actionIntent;

    // 1. Verificação de Permissão via Matriz
    const permEval = PermissionGuard.evaluateAction(actionIntent);

    // 2. Verificar regras específicas do negócio
    const activeRules = this.memory.getRules();
    const violations = [];

    if (actionType === 'APPLY_DISCOUNT_PROMOTION') {
      const marginRule = activeRules.find(r => r.rule_code === 'RULE_MIN_MARGIN');
      const minMargin = marginRule?.condition_config?.threshold || 20;
      if (payload.resultingMargin < minMargin) {
        violations.push(`Violação da regra ${marginRule.name}: margem estimada (${payload.resultingMargin}%) é inferior a ${minMargin}%.`);
      }
    }

    if (actionType === 'PROMOTE_PRODUCT_CAMPAIGN') {
      const stockRule = activeRules.find(r => r.rule_code === 'RULE_UNAVAILABLE_CAMPAIGN');
      if (payload.currentStock <= 0) {
        violations.push(`Violação da regra ${stockRule.name}: impossível promover item sem estoque.`);
      }
    }

    const isValid = violations.length === 0;

    await this.tools.logAgent(
      this.name,
      isValid ? 'info' : 'warning',
      'inspectAction',
      `Inspeção da ação [${actionType}] do agente [${agentName}]: ${isValid ? 'APROVADA PARA SUBMISSÃO' : 'VETADA PELO GUARDIAN'}`,
      { violations, actionIntent }
    );

    return {
      agent: this.name,
      isValid,
      permEval,
      violations,
      status: isValid ? 'CLEARED' : 'BLOCKED',
      summary: isValid 
        ? 'Ação em conformidade com as políticas operacionais e regras financeiras da Doce & Ponto.' 
        : `Ação VETADA pelo Guardian: ${violations.join(' | ')}`,
    };
  }
}

window.PontoGuardian = PontoGuardian;
