/**
 * PONTO OS - CHAT COM O PONTO MASTER
 * Interface de diálogo interativo executivo com o orquestrador geral.
 */

class MasterChatUI {
  constructor(pontoMaster, containerId) {
    this.master = pontoMaster;
    this.container = document.getElementById(containerId);
    this.history = [];
  }

  render() {
    if (!this.container) return;

    this.container.innerHTML = `
      <div class="master-chat-container">
        <!-- HEADER DO CHAT -->
        <div class="chat-header">
          <div class="chat-header-info">
            <div class="master-avatar">🤖</div>
            <div>
              <h3>PONTO MASTER</h3>
              <span class="chat-status"><span class="live-dot"></span> Orquestrador Geral Online</span>
            </div>
          </div>
          <div class="chat-header-meta">
            <span class="badge badge-teal">9 Agentes Conectados</span>
          </div>
        </div>

        <!-- SUGESTÕES RÁPIDAS DE PERGUNTAS -->
        <div class="chat-quick-suggestions">
          <button class="chip-suggestion" onclick="window.pontoOS.sendChatMessage('Como está minha loja hoje?')">
            Como está minha loja hoje?
          </button>
          <button class="chip-suggestion" onclick="window.pontoOS.sendChatMessage('Quais produtos estão em risco de ruptura?')">
            Risco de ruptura no estoque?
          </button>
          <button class="chip-suggestion" onclick="window.pontoOS.sendChatMessage('O que devo produzir amanhã?')">
            O que produzir amanhã?
          </button>
          <button class="chip-suggestion" onclick="window.pontoOS.sendChatMessage('Qual produto tem a maior margem?')">
            Qual produto tem maior margem?
          </button>
          <button class="chip-suggestion" onclick="window.pontoOS.sendChatMessage('Posso fazer uma promoção de 15%?')">
            Simular promoção de 15%
          </button>
          <button class="chip-suggestion" onclick="window.pontoOS.sendChatMessage('Quanto posso gastar em Ads hoje?')">
            Orçamento de Ads hoje?
          </button>
        </div>

        <!-- HISTÓRICO DE MENSAGENS -->
        <div class="chat-messages-box" id="chatMessagesBox">
          <div class="chat-message agent-message">
            <div class="message-avatar">🍰</div>
            <div class="message-bubble">
              <div class="message-sender">PONTO MASTER • Gerente Geral</div>
              <div class="message-content">
                Olá! Sou o <strong>PONTO MASTER</strong>, a inteligência que administra a Doce & Ponto.
                <br><br>
                Estou conectado ao <strong>Chef CFO</strong>, <strong>Chef Estoque</strong>, <strong>Chef Executivo</strong>, <strong>Ponto Analytics</strong>, <strong>Marketing</strong>, <strong>Ads</strong> e ao <strong>Ponto Guardian</strong>.
                <br><br>
                Você pode me perguntar sobre vendas, estoque, produção, margens ou solicitar análises de promoções.
              </div>
              <div class="message-time">${new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}</div>
            </div>
          </div>
        </div>

        <!-- BARRA DE INPUT -->
        <form class="chat-input-bar" id="masterChatForm" onsubmit="window.pontoOS.onChatSubmit(event)">
          <input 
            type="text" 
            id="chatInputText" 
            class="chat-input" 
            placeholder="Pergunte ao Ponto Master (ex: Como estão as vendas? O que produzir hoje?)..." 
            autocomplete="off"
            required
          />
          <button type="submit" class="btn btn-primary chat-send-btn" id="chatSendBtn">
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
            <span>Enviar</span>
          </button>
        </form>
      </div>
    `;
  }

  appendUserMessage(text) {
    const box = document.getElementById('chatMessagesBox');
    if (!box) return;

    const time = new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
    const el = document.createElement('div');
    el.className = 'chat-message user-message';
    el.innerHTML = `
      <div class="message-bubble">
        <div class="message-content">${escapeHtml(text)}</div>
        <div class="message-time">${time}</div>
      </div>
    `;
    box.appendChild(el);
    box.scrollTop = box.scrollHeight;
  }

  appendAgentMessage(agentName, markdownText) {
    const box = document.getElementById('chatMessagesBox');
    if (!box) return;

    const time = new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
    const el = document.createElement('div');
    el.className = 'chat-message agent-message';
    
    // Converte markdown simples para HTML seguro
    const htmlContent = formatMarkdown(markdownText);

    el.innerHTML = `
      <div class="message-avatar">🍰</div>
      <div class="message-bubble">
        <div class="message-sender">${escapeHtml(agentName)}</div>
        <div class="message-content">${htmlContent}</div>
        <div class="message-time">${time}</div>
      </div>
    `;
    box.appendChild(el);
    box.scrollTop = box.scrollHeight;
  }

  showTypingIndicator() {
    const box = document.getElementById('chatMessagesBox');
    if (!box) return;

    const el = document.createElement('div');
    el.id = 'chatTypingIndicator';
    el.className = 'chat-message agent-message typing';
    el.innerHTML = `
      <div class="message-avatar">🤖</div>
      <div class="message-bubble typing-dots">
        <span></span><span></span><span></span>
      </div>
    `;
    box.appendChild(el);
    box.scrollTop = box.scrollHeight;
  }

  hideTypingIndicator() {
    const ind = document.getElementById('chatTypingIndicator');
    if (ind) ind.remove();
  }
}

function escapeHtml(text) {
  const map = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' };
  return String(text).replace(/[&<>"']/g, m => map[m]);
}

function formatMarkdown(text) {
  let html = text
    .replace(/^### (.*$)/gim, '<h4>$1</h4>')
    .replace(/^## (.*$)/gim, '<h3>$1</h3>')
    .replace(/^\> (.*$)/gim, '<blockquote>$1</blockquote>')
    .replace(/\*\*(.*?)\*\*/gim, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/gim, '<em>$1</em>')
    .replace(/\n/gim, '<br>');
  return html;
}

window.MasterChatUI = MasterChatUI;
