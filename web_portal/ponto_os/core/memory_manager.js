/**
 * PONTO OS - MEMORY MANAGER (5 CAMADAS ESTRUTURADAS)
 * 1. Memória Operacional: dados e estados em tempo real da loja.
 * 2. Memória Histórica: métricas consolidadas de períodos anteriores.
 * 3. Memória de Decisões: histórico de escolhas e aprovações do proprietário.
 * 4. Memória de Regras: regras de negócio configuradas no Supabase.
 * 5. Memória de Preferências: parâmetros e metas estratégicas da Doce & Ponto.
 */

class MemoryManager {
  constructor(supabaseClient) {
    this.supabase = supabaseClient;
    this.cache = {
      operational: new Map(),
      historical: new Map(),
      decisions: new Map(),
      rules: new Map(),
      preferences: new Map(),
    };
  }

  /**
   * Inicializa e carrega memórias permanentes do Supabase
   */
  async init() {
    try {
      // 1. Carregar regras de negócio ativas
      const { data: rules } = await this.supabase
        .from('business_rules')
        .select('*')
        .eq('is_active', true);

      if (rules) {
        rules.forEach(r => this.cache.rules.set(r.rule_code, r));
      }

      // 2. Carregar memória persistida do Supabase
      const { data: memEntries } = await this.supabase
        .from('agent_memory')
        .select('*');

      if (memEntries) {
        memEntries.forEach(entry => {
          const typeMap = this.cache[entry.memory_type];
          if (typeMap) {
            typeMap.set(`${entry.agent_name}:${entry.key}`, entry.value);
          }
        });
      }

      // 3. Carregar preferências das configurações gerais
      const { data: settings } = await this.supabase.from('settings').select('*');
      if (settings) {
        settings.forEach(s => {
          this.cache.preferences.set(`GLOBAL:${s.key}`, s.value);
        });
      }
    } catch (e) {
      console.warn('[MemoryManager] Aviso ao carregar memória do Supabase:', e);
    }
  }

  /**
   * Grava valor na memória (local e persiste no Supabase)
   */
  async set(agentName, memoryType, key, value, persist = true) {
    if (!this.cache[memoryType]) {
      throw new Error(`Tipo de memória inválido: ${memoryType}`);
    }

    const mapKey = `${agentName}:${key}`;
    this.cache[memoryType].set(mapKey, value);

    if (persist && this.supabase) {
      try {
        await this.supabase.from('agent_memory').upsert({
          agent_name: agentName,
          memory_type: memoryType,
          key: key,
          value: value,
          updated_at: new Date().toISOString(),
        }, { onConflict: 'agent_name,memory_type,key' });
      } catch (e) {
        console.error(`[MemoryManager] Erro ao persistir memória [${memoryType}/${mapKey}]:`, e);
      }
    }
  }

  /**
   * Recupera valor da memória
   */
  get(agentName, memoryType, key) {
    if (!this.cache[memoryType]) return null;
    const mapKey = `${agentName}:${key}`;
    if (this.cache[memoryType].has(mapKey)) {
      return this.cache[memoryType].get(mapKey);
    }
    // Fallback global
    return this.cache[memoryType].get(`GLOBAL:${key}`) || null;
  }

  /**
   * Retorna todas as regras de negócio ativas
   */
  getRules(category = null) {
    const list = Array.from(this.cache.rules.values());
    if (category) {
      return list.filter(r => r.category === category);
    }
    return list;
  }

  /**
   * Registra uma decisão do proprietário para aprendizado dos agentes
   */
  async recordDecision(agentName, actionId, approved, userComments = '') {
    const decisionPayload = {
      actionId,
      approved,
      timestamp: new Date().toISOString(),
      userComments,
    };
    await this.set(agentName, 'decisions', `action_${actionId}`, decisionPayload, true);
  }
}

window.MemoryManager = MemoryManager;
