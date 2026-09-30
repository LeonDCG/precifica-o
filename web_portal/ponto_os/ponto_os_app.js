/**
 * PONTO OS - BOOTLOADER & APPLICATION COORDINATOR
 * Inicializa todos os módulos, agentes especialistas, memórias e interfaces.
 */

class PontoOSApplication {
  constructor(supabaseClient) {
    this.supabase = supabaseClient;
    this.memory = null;
    this.tools = null;
    this.master = null;
    this.gateway = null;
    this.commandUI = null;
    this.approvalsUI = null;
    this.chatUI = null;
    this.isInitialized = false;
  }

  async init() {
    if (this.isInitialized) return;

    try {
      // 1. Memória Estruturada
      this.memory = new MemoryManager(this.supabase);
      await this.memory.init();

      // 2. Tools Registry
      this.tools = new ToolsRegistry(this.supabase, this.memory);

      // 3. Agentes Especialistas
      const cfo = new ChefCFO(this.tools, this.memory);
      const estoque = new ChefEstoque(this.tools, this.memory);
      const analytics = new PontoAnalytics(this.tools, this.memory);
      const executivo = new ChefExecutivo(this.tools, this.memory);
      const operations = new PontoOperations(this.tools, this.memory);
      const catalogo = new PontoCatalogo(this.tools, this.memory);
      const marketing = new PontoMarketing(this.tools, this.memory, cfo, estoque);
      const ads = new PontoAds(this.tools, this.memory);
      const customer = new PontoCustomer(this.tools, this.memory);
      const guardian = new PontoGuardian(this.tools, this.memory);

      // 4. Orquestrador PONTO MASTER
      this.master = new PontoMaster({
        supabase: this.supabase,
        tools: this.tools,
        memory: this.memory,
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
      });

      // 5. iFood Gateway Oficial
      this.gateway = new IFoodGateway(this.supabase);
      await this.gateway.init();

      // 6. Interfaces do PONTO OS
      this.commandUI = new CommandCenterUI(this.master, 'view-ponto-command');
      this.approvalsUI = new ApprovalsCenterUI(this.supabase, 'view-ponto-approvals');
      this.chatUI = new MasterChatUI(this.master, 'view-ponto-chat');

      // Render inicial das UIs se o container existir
      this.chatUI.render();

      this.isInitialized = true;
      console.log('🍰 PONTO OS inicializado com sucesso. 9 Agentes ativos.');
    } catch (e) {
      console.error('Falha ao inicializar PONTO OS:', e);
    }
  }

  async refreshCommandCenter() {
    if (this.commandUI) {
      await this.commandUI.render();
      if (typeof showToast === 'function') {
        showToast('Central de Comando sincronizada com os agentes.', 'success');
      }
    }
  }

  async refreshApprovals() {
    if (this.approvalsUI) {
      await this.approvalsUI.render();
      if (typeof showToast === 'function') {
        showToast('Fila de aprovações atualizada.', 'info');
      }
    }
  }

  async approveAction(actionId) {
    try {
      const { error } = await this.supabase
        .from('agent_actions')
        .update({
          status: 'approved',
          approved_by: 'Proprietário (Leon)',
          approved_at: new Date().toISOString(),
        })
        .eq('id', actionId);

      if (error) throw error;

      await this.tools.logAgent(
        'PONTO GUARDIAN',
        'action',
        'approveAction',
        `Ação #${actionId} APROVADA pelo proprietário.`,
        { actionId }
      );

      if (typeof showToast === 'function') {
        showToast(`Ação #${actionId} aprovada com sucesso!`, 'success');
      }

      await this.refreshApprovals();
    } catch (e) {
      console.error('Erro ao aprovar ação:', e);
      if (typeof showToast === 'function') {
        showToast('Erro ao aprovar ação: ' + e.message, 'error');
      }
    }
  }

  async rejectAction(actionId) {
    try {
      const { error } = await this.supabase
        .from('agent_actions')
        .update({
          status: 'rejected',
          approved_by: 'Proprietário (Leon)',
          approved_at: new Date().toISOString(),
        })
        .eq('id', actionId);

      if (error) throw error;

      await this.tools.logAgent(
        'PONTO GUARDIAN',
        'action',
        'rejectAction',
        `Ação #${actionId} RECUSADA pelo proprietário.`,
        { actionId }
      );

      if (typeof showToast === 'function') {
        showToast(`Ação #${actionId} recusada pelo operador.`, 'info');
      }

      await this.refreshApprovals();
    } catch (e) {
      console.error('Erro ao recusar ação:', e);
      if (typeof showToast === 'function') {
        showToast('Erro ao recusar ação: ' + e.message, 'error');
      }
    }
  }

  async sendChatMessage(text) {
    if (!text || !this.chatUI || !this.master) return;

    this.chatUI.appendUserMessage(text);
    this.chatUI.showTypingIndicator();

    try {
      const response = await this.master.handleUserQuery(text);
      this.chatUI.hideTypingIndicator();
      this.chatUI.appendAgentMessage(response.agent, response.text);
    } catch (e) {
      this.chatUI.hideTypingIndicator();
      this.chatUI.appendAgentMessage(
        'PONTO MASTER',
        `Ocorreu um erro ao processar sua solicitação: ${e.message}`
      );
    }
  }

  onChatSubmit(event) {
    event.preventDefault();
    const input = document.getElementById('chatInputText');
    if (!input) return;
    const val = input.value.trim();
    if (!val) return;
    input.value = '';
    this.sendChatMessage(val);
  }
}

// Cria instância global
window.initPontoOS = async function(supabaseInstance) {
  if (!window.pontoOS) {
    window.pontoOS = new PontoOSApplication(supabaseInstance);
    await window.pontoOS.init();
  }
  return window.pontoOS;
};
