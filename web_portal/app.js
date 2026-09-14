// CONFIGURAÇÃO CENTRAL DO SUPABASE (DOCE & PONTO)
const SUPABASE_URL = 'https://jfpswioaikpflvjiylqa.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpmcHN3aW9haWtwZmx2aml5bHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMzA3ODQsImV4cCI6MjA5NDkwNjc4NH0.lZmckQNXdD99KAWpdYoY9Eb5rRdcmVzQh9S67rXXPdM';

const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// CACHE EM MEMÓRIA LOCAL
let ingredientsList = [];
let recipesList = [];
let recipeIngredientsList = [];
let productRecipesList = [];
let productExpensesList = [];
let productsList = [];
let salesList = [];
let movementsList = [];

// MODOS E AGRUPAMENTOS
let collapsedRecipeGroups = new Set();
let isRecipeGroupingEnabled = true;
let activeProductViewMode = 'catalog'; // 'catalog' (cards do App) ou 'table' (estoque)

// CHARTS INSTANCES
let revenueProfitChartInstance = null;
let channelChartInstance = null;

// ESTADO DE VISIBILIDADE DE VALORES
let hideValues = localStorage.getItem('hideDashboardValues') === 'true';

function updateEyeButtonUI() {
  const btnText = document.getElementById('eyeBtnText');
  const iconWrap = document.getElementById('eyeIconWrapper');
  if (btnText) {
    btnText.textContent = hideValues ? 'Mostrar Valores' : 'Ocultar Valores';
  }
  if (iconWrap) {
    if (hideValues) {
      iconWrap.innerHTML = `
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path>
          <line x1="1" y1="1" x2="23" y2="23"></line>
        </svg>
      `;
    } else {
      iconWrap.innerHTML = `
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
          <circle cx="12" cy="12" r="3"></circle>
        </svg>
      `;
    }
  }
}

function toggleHideValues() {
  hideValues = !hideValues;
  localStorage.setItem('hideDashboardValues', hideValues ? 'true' : 'false');
  updateEyeButtonUI();
  renderDashboard();
  if (typeof showToast === 'function') {
    showToast(hideValues ? 'Valores ocultados na tela.' : 'Valores visíveis na tela.', 'info');
  }
}

// INICIALIZAÇÃO DA APLICAÇÃO
document.addEventListener('DOMContentLoaded', async () => {
  checkDeviceRestriction();
  setupNavigation();
  initDateInputs();
  updateEyeButtonUI();
  await loadAllData();
});

// RESTRIÇÃO DE DISPOSITIVO: EXCLUSIVO PARA COMPUTADOR (DESKTOP/NOTEBOOK)
function checkDeviceRestriction() {
  const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || window.innerWidth < 1024;
  const blocker = document.getElementById('mobileBlocker');
  if (isMobile && blocker) {
    blocker.style.display = 'flex';
  }
}


// NAVEGAÇÃO ENTRE TELAS (SIDEBAR)
function setupNavigation() {
  const navItems = document.querySelectorAll('.nav-item');
  navItems.forEach(item => {
    item.addEventListener('click', () => {
      const viewId = item.getAttribute('data-view');
      switchView(viewId);
    });
  });
}

function switchView(viewId) {
  document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
  document.querySelectorAll('.content-view').forEach(v => v.classList.remove('active'));

  const activeBtn = document.querySelector(`.nav-item[data-view="${viewId}"]`);
  const activeView = document.getElementById(`view-${viewId}`);

  if (activeBtn) activeBtn.classList.add('active');
  if (activeView) activeView.classList.add('active');

  const titles = {
    dashboard: { title: 'Dashboard Geral', subtitle: 'Visão geral do faturamento, lucros e saúde do estoque pronto' },
    ingredients: { title: 'Cadastro de Ingredientes', subtitle: 'Gerencie insumos, custos unitários e fornecedores' },
    recipes: { title: 'Cadastro de Receitas', subtitle: 'Fichas técnicas com cálculo dinâmico de custo e rendimento' },
    products: { title: 'Catálogo de Produtos & Estoque Pronto', subtitle: 'Composição de receitas, insumos extras, precificação inteligente e estoque' },
    'quick-stock': { title: 'Estoque Rápido (+ / -)', subtitle: 'Painel visual de 2 colunas com botões rápidos de controle de estoque' },
    sales: { title: 'Registro de Vendas', subtitle: 'Lançamento de vendas com baixa automática de estoque e cálculo de lucro' },
  };

  const meta = titles[viewId] || titles.dashboard;
  document.getElementById('pageTitle').textContent = meta.title;
  document.getElementById('pageSubtitle').textContent = meta.subtitle;

  if (viewId === 'dashboard') {
    renderDashboard();
  } else if (viewId === 'products') {
    renderProductsCatalogGrid(productsList);
    renderProductsTable(productsList);
  } else if (viewId === 'quick-stock') {
    renderQuickStock(productsList);
  }
}

function initDateInputs() {
  const now = new Date();
  const isoLocal = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
  const saleDateEl = document.getElementById('saleDate');
  if (saleDateEl) saleDateEl.value = isoLocal;
}

// CARREGAMENTO CENTRALIZADO DE DADOS
async function loadAllData() {
  try {
    const [ingRes, recRes, recIngRes, prodRes, prodRecRes, prodExpRes, salesRes, movRes] = await Promise.all([
      supabaseClient.from('ingredients').select('*').order('name', { ascending: true }),
      supabaseClient.from('recipes').select('*').order('name', { ascending: true }),
      supabaseClient.from('recipe_ingredients').select('*'),
      supabaseClient.from('products').select('*').order('name', { ascending: true }),
      supabaseClient.from('product_recipes').select('*'),
      supabaseClient.from('product_expenses').select('*'),
      supabaseClient.from('sales').select('*').order('saledate', { ascending: false }),
      supabaseClient.from('stock_movements').select('*').order('created_at', { ascending: false }),
    ]);

    ingredientsList = ingRes.data || [];
    recipesList = recRes.data || [];
    recipeIngredientsList = recIngRes.data || [];
    productsList = prodRes.data || [];
    productRecipesList = prodRecRes.data || [];
    productExpensesList = prodExpRes.data || [];
    salesList = salesRes.data || [];
    movementsList = movRes.data || [];

    renderDashboard();
    renderIngredientsTable(ingredientsList);
    renderRecipesTable(recipesList);
    renderProductsCatalogGrid(productsList);
    renderProductsTable(productsList);
    renderQuickStock(productsList);
    renderSalesTable(salesList);
    updateStockAlerts();
    populateProductSelects();

  } catch (error) {
    console.error('Erro ao carregar dados do Supabase:', error);
    showToast('Erro ao carregar dados do servidor.', 'error');
  }
}

function updateStockAlerts() {
  const lowStockProducts = productsList.filter(p => (Number(p.stock) || 0) <= (Number(p.minStock) || 0));
  const badge = document.getElementById('stockAlertBadge');
  const banner = document.getElementById('lowStockBanner');
  const alertCountEl = document.getElementById('dashStockAlertCount');
  const textEl = document.getElementById('lowStockText');

  if (badge) {
    if (lowStockProducts.length > 0) {
      badge.style.display = 'inline-block';
      badge.textContent = lowStockProducts.length;
    } else {
      badge.style.display = 'none';
    }
  }

  if (banner && alertCountEl) {
    if (lowStockProducts.length > 0) {
      banner.style.display = 'flex';
      if (textEl) {
        textEl.textContent = `Há ${lowStockProducts.length} produto(s) no limite ou abaixo do estoque mínimo: ${lowStockProducts.map(p => p.name).slice(0, 3).join(', ')}${lowStockProducts.length > 3 ? '...' : ''}`;
      }
      alertCountEl.textContent = `${lowStockProducts.length} produto(s) em alerta!`;
      alertCountEl.style.color = '#ef4444';
    } else {
      banner.style.display = 'none';
      alertCountEl.textContent = 'Estoque regular e seguro';
      alertCountEl.style.color = '#059669';
    }
  }

  // Atualiza contadores do Estoque Rápido
  const totalUnits = productsList.reduce((acc, p) => acc + (Number(p.stock) || 0), 0);
  const totalEl = document.getElementById('quickStockTotalUnits');
  const lowEl = document.getElementById('quickStockLowCount');
  if (totalEl) totalEl.textContent = `${totalUnits} un`;
  if (lowEl) lowEl.textContent = `${lowStockProducts.length} itens`;
}

// ==========================================
// 1. DASHBOARD & MÉTRICAS
// ==========================================
function renderDashboard() {
  const now = new Date();
  const currentYear = now.getFullYear();
  const currentMonth = now.getMonth();

  // Filtrar vendas do mês atual
  const monthSales = salesList.filter(s => {
    const d = new Date(s.saledate || s.saleDate);
    return d.getFullYear() === currentYear && d.getMonth() === currentMonth;
  });

  const totalRev = monthSales.reduce((acc, s) => acc + (Number(s.totalvalue || s.totalValue) || 0), 0);
  const totalNetProfit = monthSales.reduce((acc, s) => acc + (Number(s.netprofit || s.netProfit) || 0), 0);

  document.getElementById('dashTotalRevenue').textContent = hideValues ? 'R$ •••••' : formatBRL(totalRev);
  document.getElementById('dashNetProfit').textContent = hideValues ? 'R$ •••••' : formatBRL(totalNetProfit);
  document.getElementById('dashTotalSales').textContent = hideValues ? '••' : monthSales.length;

  const totalStockUnits = productsList.reduce((acc, p) => acc + (Number(p.stock) || 0), 0);
  document.getElementById('dashTotalStock').textContent = `${totalStockUnits} un`;

  // Atualiza alertas
  updateStockAlerts();

  // Tabela de Vendas Recentes no Dashboard
  const recentSalesBody = document.getElementById('dashRecentSalesBody');
  const topSales = salesList.slice(0, 5);
  if (topSales.length === 0) {
    recentSalesBody.innerHTML = '<tr><td colspan="6" class="text-center py-4 text-muted">Nenhuma venda registrada.</td></tr>';
  } else {
    recentSalesBody.innerHTML = topSales.map(s => {
      const isIfood = (s.sellertype || s.sellerType || '').toLowerCase() === 'ifood';
      const channelLabel = isIfood ? '<span class="badge-stock warning">iFood</span>' : '<span class="badge-stock ok">Balcão</span>';
      return `
        <tr>
          <td>${formatDate(s.saledate || s.saleDate)}</td>
          <td><strong>${escapeHtml(s.productname || s.productName)}</strong></td>
          <td>${s.quantity} un</td>
          <td>${channelLabel}</td>
          <td><strong>${hideValues ? 'R$ •••••' : formatBRL(s.totalvalue || s.totalValue)}</strong></td>
          <td class="text-green font-bold">${hideValues ? 'R$ •••••' : formatBRL(s.netprofit || s.netProfit)}</td>
        </tr>
      `;
    }).join('');
  }

  renderCharts();
}

// RENDERIZAÇÃO DE GRÁFICOS COM CHART.JS
function renderCharts() {
  const revCtx = document.getElementById('revenueProfitChart')?.getContext('2d');
  const chanCtx = document.getElementById('channelChart')?.getContext('2d');
  if (!revCtx || !chanCtx) return;

  // Agrupar faturamento e lucro por dia dos últimos 10 dias de vendas
  const dateMap = {};
  salesList.slice(0, 30).reverse().forEach(s => {
    const d = new Date(s.saledate || s.saleDate);
    const key = `${d.getDate().toString().padStart(2, '0')}/${(d.getMonth() + 1).toString().padStart(2, '0')}`;
    if (!dateMap[key]) dateMap[key] = { revenue: 0, profit: 0 };
    dateMap[key].revenue += Number(s.totalvalue || s.totalValue) || 0;
    dateMap[key].profit += Number(s.netprofit || s.netProfit) || 0;
  });

  const labels = Object.keys(dateMap);
  const revData = labels.map(k => dateMap[k].revenue);
  const profitData = labels.map(k => dateMap[k].profit);

  if (revenueProfitChartInstance) revenueProfitChartInstance.destroy();
  revenueProfitChartInstance = new Chart(revCtx, {
    type: 'bar',
    data: {
      labels: labels.length > 0 ? labels : ['Sem dados'],
      datasets: [
        {
          label: 'Faturamento Bruto (R$)',
          data: revData.length > 0 ? revData : [0],
          backgroundColor: '#0284c7',
          borderRadius: 6,
        },
        {
          label: 'Lucro Líquido (R$)',
          data: profitData.length > 0 ? profitData : [0],
          backgroundColor: '#10b981',
          borderRadius: 6,
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { position: 'top' } },
      scales: { y: { beginAtZero: true } }
    }
  });

  // Gráfico de Canais
  const ifoodCount = salesList.filter(s => (s.sellertype || s.sellerType || '').toLowerCase() === 'ifood').length;
  const directCount = salesList.length - ifoodCount;

  if (channelChartInstance) channelChartInstance.destroy();
  channelChartInstance = new Chart(chanCtx, {
    type: 'doughnut',
    data: {
      labels: ['Venda Direta', 'iFood'],
      datasets: [{
        data: [directCount, ifoodCount],
        backgroundColor: ['#0f4c81', '#ea1d2c'],
        borderWidth: 2
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { position: 'bottom' } }
    }
  });
}

// ==========================================
// 2. MÓDULO DE INGREDIENTES
// ==========================================
function renderIngredientsTable(list) {
  const tbody = document.getElementById('ingredientsTableBody');
  if (!tbody) return;

  if (list.length === 0) {
    tbody.innerHTML = '<tr><td colspan="8" class="text-center py-6 text-muted">Nenhum ingrediente cadastrado.</td></tr>';
    return;
  }

  tbody.innerHTML = list.map(ing => {
    return `
      <tr>
        <td><strong>${escapeHtml(ing.name)}</strong></td>
        <td><span class="stat-badge blue">${escapeHtml(ing.category || 'Geral')}</span></td>
        <td>${ing.quantity} ${ing.unit}</td>
        <td>${formatBRL(ing.price)}</td>
        <td class="text-green font-bold">${formatUnitCost(ing.price, ing.quantity, ing.unit)}</td>
        <td>${escapeHtml(ing.supplier || '-')}</td>
        <td>${ing.expirationDate ? formatDateOnly(ing.expirationDate) : '-'}</td>
        <td class="text-right">
          <button class="btn-icon" title="Editar" onclick="editIngredient(${ing.id})">
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
          </button>
          <button class="btn-icon delete" title="Excluir" onclick="deleteIngredient(${ing.id})">
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
          </button>
        </td>
      </tr>
    `;
  }).join('');
}

function filterIngredients() {
  const q = document.getElementById('ingSearchInput').value.toLowerCase();
  const filtered = ingredientsList.filter(i => 
    i.name.toLowerCase().includes(q) || 
    (i.category || '').toLowerCase().includes(q) || 
    (i.supplier || '').toLowerCase().includes(q)
  );
  renderIngredientsTable(filtered);
}

function calcIngUnitCost() {
  const price = parseFloat(document.getElementById('ingPrice').value) || 0;
  const qty = parseFloat(document.getElementById('ingQuantity').value) || 0;
  const unit = (document.getElementById('ingUnit').value || '').trim();

  if (qty <= 0) {
    document.getElementById('ingUnitCostPreview').textContent = 'R$ 0,00';
    return;
  }
  const unitPrice = price / qty;
  const u = unit.toLowerCase();
  if (u === 'g') {
    document.getElementById('ingUnitCostPreview').textContent = `${formatBRL4(unitPrice)}/g (${formatBRL(unitPrice * 1000)}/kg)`;
  } else if (u === 'ml') {
    document.getElementById('ingUnitCostPreview').textContent = `${formatBRL4(unitPrice)}/ml (${formatBRL(unitPrice * 1000)}/L)`;
  } else {
    document.getElementById('ingUnitCostPreview').textContent = `${formatBRL(unitPrice)} por ${unit}`;
  }
}

function openIngredientModal(ing = null) {
  document.getElementById('ingId').value = ing ? ing.id : '';
  document.getElementById('ingName').value = ing ? ing.name : '';
  document.getElementById('ingUnit').value = ing ? ing.unit : 'g';
  document.getElementById('ingCategory').value = ing ? ing.category || '' : '';
  document.getElementById('ingPrice').value = ing ? ing.price : '';
  document.getElementById('ingQuantity').value = ing ? ing.quantity : '';
  document.getElementById('ingSupplier').value = ing ? ing.supplier || '' : '';
  document.getElementById('ingExpirationDate').value = ing && ing.expirationDate ? ing.expirationDate : '';

  document.getElementById('ingredientModalTitle').textContent = ing ? 'Editar Ingrediente' : 'Cadastrar Ingrediente';
  calcIngUnitCost();
  openModal('ingredientModal');
}

async function editIngredient(id) {
  const ing = ingredientsList.find(i => i.id === id);
  if (ing) openIngredientModal(ing);
}

async function saveIngredient(e) {
  e.preventDefault();
  const id = document.getElementById('ingId').value;
  const payload = {
    name: document.getElementById('ingName').value.trim(),
    unit: document.getElementById('ingUnit').value,
    category: document.getElementById('ingCategory').value.trim() || 'Geral',
    price: parseFloat(document.getElementById('ingPrice').value) || 0,
    quantity: parseFloat(document.getElementById('ingQuantity').value) || 1,
    supplier: document.getElementById('ingSupplier').value.trim(),
    expirationDate: document.getElementById('ingExpirationDate').value || null,
  };

  try {
    if (id) {
      await supabaseClient.from('ingredients').update(payload).eq('id', id);
      showToast('Ingrediente atualizado com sucesso!', 'success');
    } else {
      await supabaseClient.from('ingredients').insert([payload]);
      showToast('Ingrediente cadastrado com sucesso!', 'success');
    }
    closeModal('ingredientModal');
    await loadAllData();
  } catch (error) {
    console.error('Erro ao salvar ingrediente:', error);
    showToast('Erro ao salvar ingrediente.', 'error');
  }
}

async function deleteIngredient(id) {
  if (!confirm('Tem certeza que deseja excluir este ingrediente?')) return;
  try {
    await supabaseClient.from('ingredients').delete().eq('id', id);
    showToast('Ingrediente excluído.', 'success');
    await loadAllData();
  } catch (error) {
    console.error('Erro ao excluir ingrediente:', error);
    showToast('Erro ao excluir ingrediente.', 'error');
  }
}

// ==========================================
// 3. MÓDULO DE RECEITAS
// ==========================================
let currentRecipeItems = [];

// Funções de Apoio para Identificação e Agrupamento de Receitas
function parseRecipeName(name) {
  const clean = (name || '').trim();
  const match = clean.match(/^(.*?)\s*\(\s*(\d+)\s*(?:ovos|ovo)\s*(?:-\s*(.*?))?\s*\)$/i);
  if (match) {
    const family = match[1].trim();
    const eggCount = parseInt(match[2], 10);
    const extra = match[3] ? ' - ' + match[3].trim() : '';
    return {
      isGrouped: true,
      familyName: family,
      eggCount: eggCount,
      variantLabel: `${eggCount} Ovos${extra}`,
      cleanName: clean
    };
  }
  return {
    isGrouped: false,
    familyName: clean,
    eggCount: null,
    variantLabel: null,
    cleanName: clean
  };
}

function getRecipeCategory(name) {
  const n = (name || '').toLowerCase();
  if (n.startsWith('massa')) return 'Massas';
  if (n.startsWith('brigadeiro')) return 'Brigadeiros';
  if (n.startsWith('recheio')) return 'Recheios';
  if (n.includes('geléia') || n.includes('geleia')) return 'Geléias';
  if (n.includes('chantininho') || n.includes('chantilly')) return 'Chantillys';
  if (n.includes('brownie')) return 'Brownies';
  return 'Geral';
}

function getRecipeIcon(name, category) {
  const cat = category || getRecipeCategory(name);
  if (cat === 'Massas') return '🥣';
  if (cat === 'Brigadeiros') return '🍫';
  if (cat === 'Recheios') return '🍯';
  if (cat === 'Geléias') return '🍓';
  if (cat === 'Chantillys') return '🥛';
  if (cat === 'Brownies') return '🧁';
  return '🍰';
}

function getRecipeTotalCost(rec) {
  if (!rec) return 0;
  // Se temos a lista de ingredientes da receita carregada na memória
  const items = recipeIngredientsList.filter(ri => (ri.recipeid || ri.recipeId) === rec.id);
  if (items.length > 0) {
    let sum = 0;
    for (const item of items) {
      const ing = ingredientsList.find(i => i.id === (item.ingredientid || item.ingredientId));
      if (ing && ing.quantity > 0) {
        sum += ((Number(ing.price) || 0) / Number(ing.quantity)) * (Number(item.quantityused) || 0);
      } else if (item.cost) {
        sum += Number(item.cost);
      }
    }
    if (sum > 0) return sum;
  }
  return Number(rec.laborcost) || 0;
}

function toggleRecipeGrouping() {
  isRecipeGroupingEnabled = !isRecipeGroupingEnabled;
  const btn = document.getElementById('btnToggleRecipeGrouping');
  const txt = document.getElementById('toggleGroupingText');
  if (btn && txt) {
    if (isRecipeGroupingEnabled) {
      btn.classList.remove('btn-outline');
      btn.classList.add('btn-secondary');
      txt.textContent = 'Agrupado por Proporção';
    } else {
      btn.classList.remove('btn-secondary');
      btn.classList.add('btn-outline');
      txt.textContent = 'Lista Individual (Todas)';
    }
  }
  filterRecipes();
}

function toggleRecipeGroupAccordion(groupKey) {
  if (collapsedRecipeGroups.has(groupKey)) {
    collapsedRecipeGroups.delete(groupKey);
  } else {
    collapsedRecipeGroups.add(groupKey);
  }
  filterRecipes();
}

function renderRecipesTable(list) {
  const tbody = document.getElementById('recipesTableBody');
  if (!tbody) return;

  if (list.length === 0) {
    tbody.innerHTML = '<tr><td colspan="5" class="text-center py-6 text-muted">Nenhuma receita encontrada.</td></tr>';
    return;
  }

  if (!isRecipeGroupingEnabled) {
    // Modo Lista Plana Individual
    tbody.innerHTML = list.map(rec => {
      const totalCost = getRecipeTotalCost(rec);
      const yieldAmt = Number(rec.yieldamount) || 1;
      const unitCost = yieldAmt > 0 ? (totalCost / yieldAmt) : totalCost;
      const cat = getRecipeCategory(rec.name);
      const icon = getRecipeIcon(rec.name, cat);

      return `
        <tr>
          <td>
            <div style="display:flex; align-items:center; gap:10px;">
              <span class="recipe-single-icon">${icon}</span>
              <div>
                <strong>${escapeHtml(rec.name)}</strong>
                <div><span class="stat-badge blue" style="font-size:11px;">${cat}</span></div>
              </div>
            </div>
          </td>
          <td>${yieldAmt} ${escapeHtml(rec.yieldunit || 'un')}</td>
          <td><strong>${formatBRL(totalCost)}</strong></td>
          <td class="text-green font-bold">${formatBRL(unitCost)} / ${escapeHtml(rec.yieldunit || 'un')}</td>
          <td class="text-right" style="white-space: nowrap;">
            <button class="btn btn-sm btn-secondary" onclick="openProductionFromRecipe(${rec.id})" title="Registrar produção desta receita">+ Produzir</button>
            <button class="btn-icon" title="Editar Receita" onclick="openEditRecipeModal(${rec.id})">
              <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
            </button>
            <button class="btn-icon delete" title="Excluir Receita" onclick="deleteRecipe(${rec.id}, '${escapeHtml(rec.name)}')">
              <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
            </button>
          </td>
        </tr>
      `;
    }).join('');
    return;
  }

  // MODO AGRUPADO POR FAMÍLIA E PROPORÇÃO
  const groups = new Map();
  const standalones = [];

  list.forEach(rec => {
    const parsed = parseRecipeName(rec.name);
    if (parsed.isGrouped) {
      if (!groups.has(parsed.familyName)) {
        groups.set(parsed.familyName, []);
      }
      groups.get(parsed.familyName).push({ ...rec, parsed });
    } else {
      standalones.push({ ...rec, parsed });
    }
  });

  let html = '';

  // 1. Renderiza Famílias Agrupadas
  groups.forEach((variants, familyName) => {
    variants.sort((a, b) => (a.parsed.eggCount || 0) - (b.parsed.eggCount || 0));

    const totalCosts = variants.map(v => getRecipeTotalCost(v));
    const minCost = Math.min(...totalCosts);
    const maxCost = Math.max(...totalCosts);

    const unitCosts = variants.map(v => {
      const c = getRecipeTotalCost(v);
      const y = Number(v.yieldamount) || 1;
      return y > 0 ? c / y : c;
    });
    const minUnitCost = Math.min(...unitCosts);
    const maxUnitCost = Math.max(...unitCosts);

    const isCollapsed = collapsedRecipeGroups.has(familyName);
    const cat = getRecipeCategory(familyName);
    const icon = getRecipeIcon(familyName, cat);

    const eggCounts = variants.map(v => v.parsed.eggCount).filter(Boolean);
    const eggMin = Math.min(...eggCounts);
    const eggMax = Math.max(...eggCounts);
    const badgeText = `${variants.length} proporções (${eggMin} a ${eggMax} ovos)`;

    const costRangeStr = minCost === maxCost ? formatBRL(minCost) : `${formatBRL(minCost)} ~ ${formatBRL(maxCost)}`;
    const unitCostRangeStr = minUnitCost === maxUnitCost ? `${formatBRL(minUnitCost)} / un` : `${formatBRL(minUnitCost)} ~ ${formatBRL(maxUnitCost)} / un`;

    html += `
      <tr class="recipe-group-header-row" onclick="toggleRecipeGroupAccordion('${escapeHtml(familyName)}')" style="cursor: pointer;" title="Clique para expandir/recolher as proporções">
        <td>
          <div class="recipe-group-title-box">
            <span class="recipe-group-chevron ${isCollapsed ? 'collapsed' : ''}">${isCollapsed ? '▶' : '▼'}</span>
            <span class="recipe-group-icon">${icon}</span>
            <div>
              <span class="recipe-group-name">${escapeHtml(familyName)}</span>
              <span class="recipe-group-badge">🥚 ${badgeText}</span>
              <span class="stat-badge blue" style="margin-left: 6px; font-size: 11px;">${cat}</span>
            </div>
          </div>
        </td>
        <td><span style="color:#64748b; font-size:13px;">Varia por proporção</span></td>
        <td><span class="recipe-group-cost-range">${costRangeStr}</span></td>
        <td><span class="recipe-group-cost-range text-green font-bold">${unitCostRangeStr}</span></td>
        <td class="text-right" style="white-space: nowrap;">
          <button class="btn btn-sm btn-secondary" onclick="event.stopPropagation(); toggleRecipeGroupAccordion('${escapeHtml(familyName)}');">
            ${isCollapsed ? 'Ver Proporções (' + variants.length + ')' : 'Recolher'}
          </button>
        </td>
      </tr>
    `;

    if (!isCollapsed) {
      variants.forEach(v => {
        const vCost = getRecipeTotalCost(v);
        const vYield = Number(v.yieldamount) || 1;
        const vUnitCost = vYield > 0 ? (vCost / vYield) : vCost;

        html += `
          <tr class="recipe-variant-row">
            <td>
              <div style="display:flex; align-items:center; padding-left: 36px;">
                <span class="variant-branch-line">└─</span>
                <span class="variant-egg-badge">🥚 ${escapeHtml(v.parsed.variantLabel)}</span>
                <span style="font-size:13px; color:#475569; margin-left: 8px;">${escapeHtml(v.name)}</span>
              </div>
            </td>
            <td>${vYield} ${escapeHtml(v.yieldunit || 'un')}</td>
            <td><strong>${formatBRL(vCost)}</strong></td>
            <td class="text-green font-bold">${formatBRL(vUnitCost)} / ${escapeHtml(v.yieldunit || 'un')}</td>
            <td class="text-right" style="white-space: nowrap;">
              <button class="btn btn-sm btn-secondary" onclick="openProductionFromRecipe(${v.id})" title="Registrar produção desta proporção">+ Produzir</button>
              <button class="btn-icon" title="Editar Receita" onclick="openEditRecipeModal(${v.id})">
                <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
              </button>
              <button class="btn-icon delete" title="Excluir Receita" onclick="deleteRecipe(${v.id}, '${escapeHtml(v.name)}')">
                <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
              </button>
            </td>
          </tr>
        `;
      });
    }
  });

  // 2. Renderiza Receitas Individuais (Recheios, Brigadeiros, Geléias, etc.)
  standalones.forEach(rec => {
    const totalCost = getRecipeTotalCost(rec);
    const yieldAmt = Number(rec.yieldamount) || 1;
    const unitCost = yieldAmt > 0 ? (totalCost / yieldAmt) : totalCost;
    const cat = getRecipeCategory(rec.name);
    const icon = getRecipeIcon(rec.name, cat);

    html += `
      <tr>
        <td>
          <div style="display:flex; align-items:center; gap:10px;">
            <span class="recipe-single-icon">${icon}</span>
            <div>
              <strong>${escapeHtml(rec.name)}</strong>
              <div><span class="stat-badge blue" style="font-size:11px;">${cat}</span></div>
            </div>
          </div>
        </td>
        <td>${yieldAmt} ${escapeHtml(rec.yieldunit || 'un')}</td>
        <td><strong>${formatBRL(totalCost)}</strong></td>
        <td class="text-green font-bold">${formatBRL(unitCost)} / ${escapeHtml(rec.yieldunit || 'un')}</td>
        <td class="text-right" style="white-space: nowrap;">
          <button class="btn btn-sm btn-secondary" onclick="openProductionFromRecipe(${rec.id})" title="Registrar produção">+ Produzir</button>
          <button class="btn-icon" title="Editar Receita" onclick="openEditRecipeModal(${rec.id})">
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
          </button>
          <button class="btn-icon delete" title="Excluir Receita" onclick="deleteRecipe(${rec.id}, '${escapeHtml(rec.name)}')">
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
          </button>
        </td>
      </tr>
    `;
  });

  tbody.innerHTML = html;
}

function filterRecipes() {
  const q = (document.getElementById('recipeSearchInput')?.value || '').toLowerCase().trim();
  const selectedCat = document.getElementById('recipeCategoryFilter')?.value || 'all';

  const filtered = recipesList.filter(r => {
    const nameMatch = r.name.toLowerCase().includes(q);
    const parsed = parseRecipeName(r.name);
    const familyMatch = parsed.familyName.toLowerCase().includes(q);
    const variantMatch = parsed.variantLabel ? parsed.variantLabel.toLowerCase().includes(q) : false;
    const cat = getRecipeCategory(r.name);
    const categoryMatch = selectedCat === 'all' || cat.toLowerCase().startsWith(selectedCat.toLowerCase().trim());

    return (nameMatch || familyMatch || variantMatch) && categoryMatch;
  });

  renderRecipesTable(filtered);
}

function openRecipeModal() {
  document.getElementById('recipeModalTitle').textContent = 'Cadastrar Ficha Técnica / Receita';
  document.getElementById('recipeId').value = '';
  document.getElementById('recipeName').value = '';
  document.getElementById('recipeYieldAmount').value = '1';
  document.getElementById('recipeIngredientsList').innerHTML = '';
  addRecipeIngredientRow();
  calcRecipeTotalCost();
  openModal('recipeModal');
}

async function openEditRecipeModal(recipeId) {
  const rec = recipesList.find(r => r.id === recipeId);
  if (!rec) return;

  document.getElementById('recipeModalTitle').textContent = 'Editar Ficha Técnica / Receita';
  document.getElementById('recipeId').value = rec.id;
  document.getElementById('recipeName').value = rec.name;
  document.getElementById('recipeYieldAmount').value = rec.yieldamount || 1;
  document.getElementById('recipeIngredientsList').innerHTML = '<div class="text-center py-4 text-muted">Carregando ingredientes da receita...</div>';

  openModal('recipeModal');

  try {
    const { data: items, error } = await supabaseClient
      .from('recipe_ingredients')
      .select('*')
      .eq('recipeid', recipeId);

    if (error) throw error;

    document.getElementById('recipeIngredientsList').innerHTML = '';

    if (items && items.length > 0) {
      items.forEach(item => {
        addRecipeIngredientRow(item.ingredientid, item.quantityused);
      });
    } else {
      addRecipeIngredientRow();
    }
    calcRecipeTotalCost();
  } catch (err) {
    console.error('Erro ao carregar ingredientes da receita:', err);
    document.getElementById('recipeIngredientsList').innerHTML = '';
    addRecipeIngredientRow();
    calcRecipeTotalCost();
    showToast('Erro ao carregar lista de ingredientes da receita.', 'error');
  }
}

function addRecipeIngredientRow(ingId = '', qty = 0) {
  const container = document.getElementById('recipeIngredientsList');
  const rowIndex = container.children.length;

  const div = document.createElement('div');
  div.className = 'recipe-ingredient-row';
  div.id = `recRow_${rowIndex}`;

  const options = ingredientsList.map(i => `<option value="${i.id}" ${i.id == ingId ? 'selected' : ''}>${escapeHtml(i.name)} (${i.unit})</option>`).join('');

  div.innerHTML = `
    <select class="form-select" onchange="calcRecipeTotalCost()">
      <option value="">Selecione o ingrediente...</option>
      ${options}
    </select>
    <input type="number" step="0.01" class="form-input" placeholder="Quantidade" value="${qty > 0 ? qty : ''}" oninput="calcRecipeTotalCost()">
    <span class="recipe-ingredient-cost" id="recRowCost_${rowIndex}">R$ 0,00</span>
    <button type="button" class="btn-icon delete" onclick="removeRecipeRow('${div.id}')">
      <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
    </button>
  `;
  container.appendChild(div);
  calcRecipeTotalCost();
}

function removeRecipeRow(rowId) {
  const el = document.getElementById(rowId);
  if (el) el.remove();
  calcRecipeTotalCost();
}

function calcRecipeTotalCost() {
  const rows = document.querySelectorAll('.recipe-ingredient-row');
  let total = 0;

  rows.forEach(row => {
    const sel = row.querySelector('select');
    const input = row.querySelector('input');
    const costSpan = row.querySelector('.recipe-ingredient-cost');

    const ingId = sel.value;
    const qty = parseFloat(input.value) || 0;
    const ing = ingredientsList.find(i => i.id == ingId);

    let rowCost = 0;
    if (ing && ing.quantity > 0) {
      rowCost = (ing.price / ing.quantity) * qty;
    }
    costSpan.textContent = formatBRL(rowCost);
    total += rowCost;
  });

  const yieldAmount = parseFloat(document.getElementById('recipeYieldAmount').value) || 1;
  const unitCost = yieldAmount > 0 ? total / yieldAmount : 0;

  document.getElementById('recipeTotalCostPreview').textContent = formatBRL(total);
  document.getElementById('recipeUnitCostPreview').textContent = `${formatBRL(unitCost)} / un`;
}

async function saveRecipe(e) {
  e.preventDefault();
  const id = document.getElementById('recipeId').value;
  const name = document.getElementById('recipeName').value.trim();
  const yieldAmount = parseFloat(document.getElementById('recipeYieldAmount').value) || 1;

  // Calcular custo total
  const rows = document.querySelectorAll('.recipe-ingredient-row');
  let totalCost = 0;
  const itemsToSave = [];

  rows.forEach(row => {
    const ingId = row.querySelector('select').value;
    const qty = parseFloat(row.querySelector('input').value) || 0;
    if (ingId && qty > 0) {
      const ing = ingredientsList.find(i => i.id == ingId);
      const cost = ing && ing.quantity > 0 ? (ing.price / ing.quantity) * qty : 0;
      totalCost += cost;
      itemsToSave.push({ ingredientid: ingId, quantityused: qty, cost: cost });
    }
  });

  try {
    if (id) {
      // 1. Atualiza dados principais da receita existente
      const { error: updateErr } = await supabaseClient.from('recipes').update({
        name: name,
        yieldamount: yieldAmount,
        yieldunit: 'unidade',
        laborcost: totalCost,
      }).eq('id', id);

      if (updateErr) throw updateErr;

      // 2. Remove ingredientes antigos desta receita
      await supabaseClient.from('recipe_ingredients').delete().eq('recipeid', id);

      // 3. Insere os novos ingredientes atualizados
      if (itemsToSave.length > 0) {
        const itemsPayload = itemsToSave.map(item => ({ ...item, recipeid: id }));
        await supabaseClient.from('recipe_ingredients').insert(itemsPayload);
      }

      showToast(`Receita "${name}" atualizada com sucesso!`, 'success');
    } else {
      // 1. Cadastra nova receita
      const { data: recipeData, error: recipeErr } = await supabaseClient.from('recipes').insert([{
        name: name,
        yieldamount: yieldAmount,
        yieldunit: 'unidade',
        laborcost: totalCost,
      }]).select();

      if (recipeErr) throw recipeErr;

      const newRecipeId = recipeData[0].id;
      if (itemsToSave.length > 0) {
        const itemsPayload = itemsToSave.map(item => ({ ...item, recipeid: newRecipeId }));
        await supabaseClient.from('recipe_ingredients').insert(itemsPayload);
      }

      showToast('Receita cadastrada com sucesso!', 'success');
    }

    closeModal('recipeModal');
    await loadAllData();
  } catch (error) {
    console.error('Erro ao salvar receita:', error);
    showToast('Erro ao salvar receita.', 'error');
  }
}

async function deleteRecipe(recipeId, recipeName) {
  if (!confirm(`Tem certeza que deseja excluir a receita "${recipeName}"?\nEsta ação não poderá ser desfeita.`)) {
    return;
  }

  try {
    const { error } = await supabaseClient.from('recipes').delete().eq('id', recipeId);
    if (error) throw error;

    showToast(`Receita "${recipeName}" excluída com sucesso!`, 'info');
    await loadAllData();
  } catch (err) {
    console.error('Erro ao excluir receita:', err);
    showToast('Erro ao excluir receita.', 'error');
  }
}

// ==========================================
// 4. MÓDULO DE PRODUTOS & CATÁLOGO (CONCEITO DO APP)
// ==========================================

// Imagens gourmet de fallback (inspiradas no Catálogo do App)
const GOURMET_PLACEHOLDERS = [
  'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=800&q=80', // Bolo Trufado
  'https://images.unsplash.com/photo-1464305795204-6f5bbfc7fb81?auto=format&fit=crop&w=800&q=80', // Torta Morango
  'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80', // Confeitaria Croissant
  'https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?auto=format&fit=crop&w=800&q=80', // Macarons Gourmet
  'https://images.unsplash.com/photo-1550617931-e17a7b70dce2?auto=format&fit=crop&w=800&q=80', // Cupcakes
];

function getProductPlaceholderImage(idx) {
  return GOURMET_PLACEHOLDERS[Math.abs(idx) % GOURMET_PLACEHOLDERS.length];
}

function getProductRecipesDetails(prodId) {
  const links = productRecipesList.filter(pr => (pr.productid || pr.productId) === prodId);
  return links.map(link => {
    const rec = recipesList.find(r => r.id === (link.recipeid || link.recipeId));
    const qty = Number(link.quantityused) || 1;
    let cost = 0;
    if (link.cost && Number(link.cost) > 0) {
      cost = Number(link.cost);
    } else if (rec) {
      cost = getRecipeTotalCost(rec) * qty;
    }
    return {
      recipeId: link.recipeid || link.recipeId,
      recipeName: rec ? rec.name : (link.recipename || 'Receita'),
      quantityUsed: qty,
      cost: cost,
      yieldUnit: rec ? (rec.yieldunit || 'un') : 'un'
    };
  });
}

function getProductExpensesDetails(prodId) {
  const exps = productExpensesList.filter(pe => (pe.productid || pe.productId) === prodId);
  return exps.map(e => ({
    name: e.name || 'Insumo/Embalagem',
    cost: Number(e.cost) || 0
  }));
}

function getProductProductionCost(prod) {
  if (!prod) return 0;

  // 1. Procurar nas fichas técnicas vinculadas (product_recipes) e gastos extras (product_expenses)
  const recipes = getProductRecipesDetails(prod.id);
  const expenses = getProductExpensesDetails(prod.id);

  let totalBatchCost = 0;
  for (const r of recipes) {
    totalBatchCost += r.cost;
  }
  for (const e of expenses) {
    totalBatchCost += e.cost;
  }

  const yieldAmt = Number(prod.yieldAmount) || 1;
  if (totalBatchCost > 0) {
    return yieldAmt > 0 ? (totalBatchCost / yieldAmt) : totalBatchCost;
  }

  // 2. Se o produto tem suggestedPrice e margem configurada
  if (prod.suggestedPrice && Number(prod.suggestedPrice) > 0) {
    const margin = Number(prod.profitMarginPercent) || 30;
    const baseCost = Number(prod.suggestedPrice) / (1 + (margin / 100));
    return yieldAmt > 0 ? (baseCost / yieldAmt) : baseCost;
  }

  // 3. Estimativa a partir do preço de venda
  if (prod.sellPrice && Number(prod.sellPrice) > 0) {
    const margin = Number(prod.profitMarginPercent) || 30;
    if (yieldAmt > 1 && Number(prod.sellPrice) > 50) {
      return (Number(prod.sellPrice) / (1 + (margin / 100))) / yieldAmt;
    }
    return (Number(prod.sellPrice) * 0.40) / (yieldAmt > 1 ? yieldAmt : 1);
  }

  return 0;
}

function switchProductViewMode(mode) {
  activeProductViewMode = mode;
  const btnCat = document.getElementById('btnViewCatalog');
  const btnTab = document.getElementById('btnViewTable');
  const catCont = document.getElementById('productsCatalogViewContainer');
  const tabCont = document.getElementById('productsTableViewContainer');

  if (mode === 'catalog') {
    if (btnCat) btnCat.classList.add('active');
    if (btnTab) btnTab.classList.remove('active');
    if (catCont) catCont.style.display = 'block';
    if (tabCont) tabCont.style.display = 'none';
  } else {
    if (btnCat) btnCat.classList.remove('active');
    if (btnTab) btnTab.classList.add('active');
    if (catCont) catCont.style.display = 'none';
    if (tabCont) tabCont.style.display = 'block';
  }
}

// RENDERIZAÇÃO DO CATÁLOGO DE PRODUTOS (CARDS GOURMET INSPIRADOS NO APP)
function renderProductsCatalogGrid(list) {
  const container = document.getElementById('productsCatalogGrid');
  if (!container) return;

  if (list.length === 0) {
    container.innerHTML = `
      <div style="grid-column: 1 / -1; text-align: center; padding: 48px 16px; color: #64748b;">
        <div style="font-size: 40px; margin-bottom: 12px;">🍰</div>
        <h3 style="font-size: 18px; color: #1e293b; margin-bottom: 6px;">Nenhum produto cadastrado no catálogo</h3>
        <p style="font-size: 14px; margin-bottom: 20px;">Cadastre seu primeiro produto compondo receitas e embalagens.</p>
        <button class="btn btn-primary" onclick="openProductModal()">+ Novo Produto</button>
      </div>
    `;
    return;
  }

  // Agrupar produtos por categoria (como no App)
  const grouped = new Map();
  list.forEach(p => {
    const cat = (p.category || 'Geral').trim() || 'Geral';
    if (!grouped.has(cat)) grouped.set(cat, []);
    grouped.get(cat).push(p);
  });

  let html = '';

  grouped.forEach((categoryProducts, categoryName) => {
    html += `
      <div class="catalog-category-header">
        <h3 class="catalog-category-title">${escapeHtml(categoryName)}</h3>
        <span class="catalog-category-count">${categoryProducts.length} itens</span>
      </div>
    `;

    categoryProducts.forEach((prod, idx) => {
      const yieldAmt = Number(prod.yieldAmount) || 1;
      const unitName = escapeHtml(prod.unit || 'unidade');
      const unitCost = getProductProductionCost(prod);
      
      const recipes = getProductRecipesDetails(prod.id);
      const expenses = getProductExpensesDetails(prod.id);

      const totalBatchCost = unitCost * yieldAmt;
      const sellPrice = Number(prod.sellPrice) || 0;
      const ifoodPrice = Number(prod.ifoodPrice) || 0;

      const profitTotal = sellPrice - totalBatchCost;
      const profitPerUnit = yieldAmt > 0 ? (profitTotal / yieldAmt) : profitTotal;
      const isPositive = profitTotal >= 0;

      const stock = Number(prod.stock) || 0;
      const minStock = Number(prod.minStock) || 0;
      let stockClass = 'badge-success';
      let stockText = `${stock} ${unitName}`;

      if (stock === 0) {
        stockClass = 'badge-danger';
        stockText = 'ZERADO';
      } else if (stock <= minStock) {
        stockClass = 'badge-warning';
        stockText = `BAIXO (${stock})`;
      }

      const imageUrl = prod.imagePath && prod.imagePath.trim().length > 0 
        ? escapeHtml(prod.imagePath) 
        : getProductPlaceholderImage(prod.id || idx);

      // Pills de composição (receitas e insumos)
      let compChipsHtml = '';
      if (recipes.length > 0) {
        recipes.forEach(r => {
          compChipsHtml += `<span class="composition-chip recipe" title="Ficha Técnica: ${escapeHtml(r.recipeName)} (Custo: ${formatBRL(r.cost)})">🥣 ${escapeHtml(r.recipeName)} ${r.quantityUsed > 1 ? '(x' + r.quantityUsed + ')' : ''}</span>`;
        });
      }
      if (expenses.length > 0) {
        expenses.forEach(e => {
          compChipsHtml += `<span class="composition-chip expense" title="Insumo/Gasto: ${escapeHtml(e.name)} (${formatBRL(e.cost)})">📦 ${escapeHtml(e.name)}</span>`;
        });
      }
      if (!compChipsHtml) {
        compChipsHtml = `<span style="font-size: 12px; color: #94a3b8; font-style: italic;">Nenhuma receita associada (custo manual)</span>`;
      }

      html += `
        <div class="catalog-product-card" id="catalog-card-${prod.id}">
          <!-- MÍDIA DO CARD -->
          <div class="catalog-card-media">
            <img src="${imageUrl}" alt="${escapeHtml(prod.name)}" class="catalog-card-img" onerror="this.src='${getProductPlaceholderImage(idx)}'">
            <div class="catalog-card-gradient"></div>

            <!-- BADGES FLUTUANTES -->
            <div class="catalog-media-badges">
              ${(prod.isFeatured || idx === 0) ? `<span class="catalog-badge-featured">⭐ Destaque</span>` : ''}
              <span class="catalog-badge-profit ${isPositive ? 'positive' : 'negative'}">
                ${yieldAmt > 1 ? `LUCRO: ${formatBRL(profitPerUnit)} / ${unitName}` : `LUCRO: ${formatBRL(profitTotal)}`}
              </span>
            </div>

            <!-- STATUS DO ESTOQUE FLUTUANTE -->
            <div class="catalog-media-stock">
              <span class="quick-status-badge ${stockClass}">📦 ${stockText}</span>
            </div>

            <!-- TÍTULO SOBREPOSTO AO GRADIENTE -->
            <div class="catalog-media-title-overlay">
              <div class="catalog-media-name">${escapeHtml(prod.name)}</div>
              <div class="catalog-media-yield">Rende ${yieldAmt} ${unitName} • Custo Unitário: <strong>${formatBRL(unitCost)} / ${unitName}</strong></div>
            </div>
          </div>

          <!-- CORPO DO CARD -->
          <div class="catalog-card-body">
            <!-- COMPOSIÇÃO DE RECEITAS E INSUMOS -->
            <div class="catalog-composition-wrap">
              <div class="catalog-composition-label">Composição Culinária & Insumos:</div>
              <div class="catalog-composition-chips">
                ${compChipsHtml}
              </div>
            </div>

            <!-- RODAPÉ DE PREÇOS -->
            <div class="catalog-pricing-row">
              <div class="catalog-price-block">
                <span class="catalog-price-label">Preço Balcão</span>
                <span class="catalog-price-val">${formatBRL(sellPrice)}</span>
                ${yieldAmt > 1 ? `<span style="font-size:11px; color:#64748b;">${formatBRL(sellPrice / yieldAmt)} por ${unitName}</span>` : ''}
              </div>

              ${ifoodPrice > 0 ? `
                <div class="catalog-price-block" style="text-align: right;">
                  <span class="catalog-price-label" style="color: #ea1d2c;">iFood</span>
                  <span class="catalog-price-val ifood">${formatBRL(ifoodPrice)}</span>
                  ${yieldAmt > 1 ? `<span style="font-size:11px; color:#ea1d2c;">${formatBRL(ifoodPrice / yieldAmt)} por ${unitName}</span>` : ''}
                </div>
              ` : ''}
            </div>
          </div>

          <!-- AÇÕES DO CARD -->
          <div class="catalog-card-actions">
            <button class="btn btn-sm btn-secondary" onclick="openProductionForSpecificProduct(${prod.id})" title="Registrar produção deste produto">
              + Produzir
            </button>
            <button class="btn btn-sm btn-primary" onclick="openProductModal(${prod.id})" title="Editar Produto, Receitas e Preço">
              <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
              <span>Editar</span>
            </button>
            <button class="btn-icon delete" style="min-height:44px; width:44px;" title="Excluir Produto" onclick="deleteProduct(${prod.id}, '${escapeHtml(prod.name)}')">
              <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
            </button>
          </div>
        </div>
      `;
    });
  });

  container.innerHTML = html;
}

function renderProductsTable(list) {
  const tbody = document.getElementById('productsTableBody');
  if (!tbody) return;

  if (list.length === 0) {
    tbody.innerHTML = '<tr><td colspan="9" class="text-center py-6 text-muted">Nenhum produto cadastrado.</td></tr>';
    return;
  }

  tbody.innerHTML = list.map(prod => {
    const stock = Number(prod.stock) || 0;
    const minStock = Number(prod.minStock) || 0;
    const prodUnitCost = getProductProductionCost(prod);
    let badgeClass = 'ok';
    let statusText = 'Estoque Regular';

    if (stock === 0) {
      badgeClass = 'danger';
      statusText = 'ZERADO';
    } else if (stock <= minStock) {
      badgeClass = 'warning';
      statusText = 'BAIXO';
    }

    return `
      <tr>
        <td>
          <div style="display:flex; align-items:center; gap:12px;">
            ${prod.imagePath 
              ? `<img src="${escapeHtml(prod.imagePath)}" alt="${escapeHtml(prod.name)}" class="prod-avatar-img" onerror="this.outerHTML='<div class=\\'prod-avatar-fallback\\'>🍰</div>'">`
              : `<div class="prod-avatar-fallback">🍰</div>`
            }
            <div>
              <strong>${escapeHtml(prod.name)}</strong>
              <div style="font-size:11px; color:#64748b;">Rende ${prod.yieldAmount || 1} ${prod.unit || 'un'}</div>
            </div>
          </div>
        </td>
        <td><span class="stat-badge blue">${escapeHtml(prod.category || 'Geral')}</span></td>
        <td><strong>${formatBRL(prod.sellPrice)}</strong></td>
        <td><span style="color:#ea1d2c; font-weight:700;">${prod.ifoodPrice > 0 ? formatBRL(prod.ifoodPrice) : '-'}</span></td>
        <td class="text-green font-bold">${formatBRL(prodUnitCost)} / ${escapeHtml(prod.unit || 'un')}</td>
        <td><span class="badge-stock ${badgeClass}">${stock} ${prod.unit || 'un'}</span></td>
        <td>${minStock} ${prod.unit || 'un'}</td>
        <td><span class="badge-stock ${badgeClass}">${statusText}</span></td>
        <td class="text-right" style="white-space: nowrap;">
          <button class="btn btn-sm btn-secondary" onclick="openProductionForSpecificProduct(${prod.id})">+ Produzir</button>
          <button class="btn-icon" title="Editar Produto" onclick="openProductModal(${prod.id})">
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
          </button>
          <button class="btn-icon delete" title="Excluir Produto" onclick="deleteProduct(${prod.id}, '${escapeHtml(prod.name)}')">
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
          </button>
        </td>
      </tr>
    `;
  }).join('');
}

function filterProducts() {
  const q = (document.getElementById('prodSearchInput')?.value || '').toLowerCase().trim();
  const filtered = productsList.filter(p => 
    p.name.toLowerCase().includes(q) || 
    (p.category || '').toLowerCase().includes(q)
  );
  renderProductsCatalogGrid(filtered);
  renderProductsTable(filtered);
}

async function deleteProduct(prodId, prodName) {
  if (!confirm(`Tem certeza que deseja excluir o produto "${prodName}" do catálogo e do estoque?\nEsta ação excluirá também suas receitas e gastos vinculados.`)) {
    return;
  }

  try {
    // 1. Remove dependências relacionais
    await supabaseClient.from('product_recipes').delete().eq('productid', prodId);
    await supabaseClient.from('product_expenses').delete().eq('productid', prodId);

    // 2. Remove o produto principal
    const { error } = await supabaseClient.from('products').delete().eq('id', prodId);
    if (error) throw error;

    showToast(`Produto "${prodName}" excluído com sucesso!`, 'info');
    await loadAllData();
  } catch (err) {
    console.error('Erro ao excluir produto:', err);
    showToast('Erro ao excluir produto.', 'error');
  }
}

// ==========================================================================
// 4.1 MÓDULO DE ESTOQUE RÁPIDO (2 COLUNAS: PRODUTO & QUANTIDADE)
// ==========================================================================
const PRODUCT_THEMES = [
  { keywords: ['chocolate', 'cacau', 'choc'], bg: '#fdf7f2', border: '#854d0e', text: '#78350f', badgeBg: '#fef3c7', badgeText: '#92400e', icon: '🍫' },
  { keywords: ['red velvet', 'velvet', 'vermelho'], bg: '#fdf2f2', border: '#dc2626', text: '#991b1b', badgeBg: '#fee2e2', badgeText: '#b91c1c', icon: '🌹' },
  { keywords: ['maracuja', 'maracujá', 'tropical'], bg: '#fefce8', border: '#d97706', text: '#854d0e', badgeBg: '#fef08a', badgeText: '#854d0e', icon: '🟡' },
  { keywords: ['cenoura', 'brigadeiro'], bg: '#fff7ed', border: '#ea580c', text: '#9a3412', badgeBg: '#ffedd5', badgeText: '#c2410c', icon: '🥕' },
  { keywords: ['coco', 'beijinho', 'baunilha'], bg: '#f0fdf4', border: '#059669', text: '#065f46', badgeBg: '#d1fae5', badgeText: '#047857', icon: '🥥' },
  { keywords: ['doce de leite', 'caramelo', 'ameixa'], bg: '#fef9c3', border: '#ca8a04', text: '#713f12', badgeBg: '#fef08a', badgeText: '#a16207', icon: '🍯' },
  { keywords: ['cafe', 'café', 'moca', 'cappuccino'], bg: '#fdf8f6', border: '#573926', text: '#451a03', badgeBg: '#f5ebe0', badgeText: '#573926', icon: '☕' },
  { keywords: ['morango', 'frutas vermelhas', 'amora'], bg: '#fff1f2', border: '#e11d48', text: '#9f1239', badgeBg: '#ffe4e6', badgeText: '#be123c', icon: '🍓' },
  { keywords: ['limao', 'limão'], bg: '#f7fee7', border: '#65a30d', text: '#3f6212', badgeBg: '#ecfccb', badgeText: '#4d7c0f', icon: '🍋' },
  { keywords: ['leite ninho', 'ninho', 'nutella'], bg: '#f8fafc', border: '#0284c7', text: '#0369a1', badgeBg: '#e0f2fe', badgeText: '#0284c7', icon: '🥛' },
];

const FALLBACK_PALETTES = [
  { bg: '#eff6ff', border: '#2563eb', text: '#1e40af', badgeBg: '#dbeafe', badgeText: '#1d4ed8', icon: '🍰' },
  { bg: '#f5f3ff', border: '#7c3aed', text: '#5b21b6', badgeBg: '#ede9fe', badgeText: '#6d28d9', icon: '🧁' },
  { bg: '#ecfdf5', border: '#059669', text: '#065f46', badgeBg: '#d1fae5', badgeText: '#047857', icon: '🎂' },
  { bg: '#fff1f2', border: '#e11d48', text: '#9f1239', badgeBg: '#ffe4e6', badgeText: '#be123c', icon: '🥧' },
  { bg: '#fffbeb', border: '#d97706', text: '#92400e', badgeBg: '#fef3c7', badgeText: '#b45309', icon: '🍪' },
  { bg: '#fdf4ff', border: '#c026d3', text: '#86198f', badgeBg: '#fae8ff', badgeText: '#a21caf', icon: '🍮' },
];

function getProductTheme(productName, index = 0) {
  const norm = (productName || '').toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  for (const t of PRODUCT_THEMES) {
    if (t.keywords.some(k => norm.includes(k.normalize("NFD").replace(/[\u0300-\u036f]/g, "")))) {
      return t;
    }
  }
  let hash = 0;
  for (let i = 0; i < norm.length; i++) hash = norm.charCodeAt(i) + ((hash << 5) - hash);
  const idx = Math.abs(hash + index) % FALLBACK_PALETTES.length;
  return FALLBACK_PALETTES[idx];
}

function renderQuickStock(list = productsList) {
  const container = document.getElementById('quickStockList');
  if (!container) return;

  updateStockAlerts();

  if (!list || list.length === 0) {
    container.innerHTML = '<div class="text-center py-10 text-muted" style="font-size: 18px; padding: 40px 0;">Nenhum produto cadastrado no estoque.</div>';
    return;
  }

  container.innerHTML = list.map((prod, idx) => {
    const theme = getProductTheme(prod.name, idx);
    const stock = Number(prod.stock) || 0;
    const minStock = Number(prod.minStock) || 0;

    let alertBadgeHtml = '';
    let cardStatusClass = 'status-normal';

    if (stock === 0) {
      cardStatusClass = 'status-danger';
      alertBadgeHtml = `<span class="quick-status-badge badge-danger">⚠️ ESGOTADO</span>`;
    } else if (stock <= minStock) {
      cardStatusClass = 'status-warning';
      alertBadgeHtml = `<span class="quick-status-badge badge-warning">⚠️ BAIXO (Mín: ${minStock})</span>`;
    } else {
      alertBadgeHtml = `<span class="quick-status-badge badge-success">✓ DISPONÍVEL</span>`;
    }

    return `
      <div class="quick-stock-row ${cardStatusClass}" id="quick-row-${prod.id}" style="border-left: 10px solid ${theme.border};">
        <!-- COLUNA 1: PRODUTO -->
        <div class="quick-col-product" style="background: linear-gradient(90deg, ${theme.bg} 0%, #ffffff 100%);">
          ${prod.imagePath
            ? `<img src="${escapeHtml(prod.imagePath)}" alt="${escapeHtml(prod.name)}" class="quick-prod-thumb-img" style="border: 2px solid ${theme.border};" onerror="this.outerHTML='<div class=\\'quick-prod-icon\\' style=\\'background:${theme.border}; color:#ffffff;\\'>${theme.icon}</div>'">`
            : `<div class="quick-prod-icon" style="background: ${theme.border}; color: #ffffff;">${theme.icon}</div>`
          }
          <div class="quick-prod-info">
            <div class="quick-prod-name" style="color: ${theme.text};">
              ${escapeHtml(prod.name)}
            </div>
            <div class="quick-prod-details">
              <span class="quick-detail-tag" style="background:${theme.badgeBg}; color:${theme.badgeText}; border: 1px solid ${theme.border}40;">
                ${escapeHtml(prod.category || 'Geral')}
              </span>
              <span class="quick-price-tag">Balcão: <strong>${formatBRL(prod.sellPrice)}</strong></span>
              ${prod.ifoodPrice > 0 ? `<span class="quick-price-tag ifood">iFood: <strong>${formatBRL(prod.ifoodPrice)}</strong></span>` : ''}
              <span id="quick-badge-container-${prod.id}">${alertBadgeHtml}</span>
            </div>
          </div>
        </div>

        <!-- COLUNA 2: QUANTIDADE (+ / -) -->
        <div class="quick-col-quantity">
          <button type="button" 
                  class="quick-btn-step btn-minus" 
                  title="Diminuir 1 unidade do estoque"
                  onclick="adjustQuickStock(${prod.id}, -1)">
            <svg viewBox="0 0 24 24" width="28" height="28" fill="none" stroke="currentColor" stroke-width="3.5" stroke-linecap="round"><line x1="5" y1="12" x2="19" y2="12"/></svg>
          </button>

          <div class="quick-qty-box">
            <span class="quick-qty-number" id="quick-qty-${prod.id}" style="color: ${stock === 0 ? '#ef4444' : stock <= minStock ? '#d97706' : '#0f172a'};">
              ${stock}
            </span>
            <span class="quick-qty-unit">${escapeHtml(prod.unit || 'un')}</span>
          </div>

          <button type="button" 
                  class="quick-btn-step btn-plus" 
                  title="Adicionar 1 unidade ao estoque"
                  onclick="adjustQuickStock(${prod.id}, 1)">
            <svg viewBox="0 0 24 24" width="28" height="28" fill="none" stroke="currentColor" stroke-width="3.5" stroke-linecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          </button>
        </div>
      </div>
    `;
  }).join('');
}

function filterQuickStock() {
  const input = document.getElementById('quickStockSearchInput');
  const query = input ? input.value.toLowerCase().trim() : '';
  if (!query) {
    renderQuickStock(productsList);
    return;
  }
  const filtered = productsList.filter(p => 
    (p.name || '').toLowerCase().includes(query) || 
    (p.category || '').toLowerCase().includes(query)
  );
  renderQuickStock(filtered);
}

async function adjustQuickStock(prodId, delta) {
  const prod = productsList.find(p => p.id === prodId);
  if (!prod) return;

  const prevStock = Number(prod.stock) || 0;
  const newStock = prevStock + delta;

  if (newStock < 0) {
    showToast(`O estoque de "${prod.name}" já está zerado!`, 'warning');
    return;
  }

  // 1. Atualização Otimista Imediata
  prod.stock = newStock;

  const qtyEl = document.getElementById(`quick-qty-${prodId}`);
  if (qtyEl) {
    qtyEl.textContent = newStock;
    qtyEl.style.color = newStock === 0 ? '#ef4444' : newStock <= (Number(prod.minStock) || 0) ? '#d97706' : '#0f172a';
    qtyEl.classList.remove('pulse-anim');
    void qtyEl.offsetWidth; // trigger reflow
    qtyEl.classList.add('pulse-anim');
  }

  const badgeContainer = document.getElementById(`quick-badge-container-${prodId}`);
  const rowEl = document.getElementById(`quick-row-${prodId}`);
  const minStock = Number(prod.minStock) || 0;

  if (badgeContainer && rowEl) {
    rowEl.classList.remove('status-normal', 'status-warning', 'status-danger');
    if (newStock === 0) {
      rowEl.classList.add('status-danger');
      badgeContainer.innerHTML = `<span class="quick-status-badge badge-danger">⚠️ ESGOTADO</span>`;
    } else if (newStock <= minStock) {
      rowEl.classList.add('status-warning');
      badgeContainer.innerHTML = `<span class="quick-status-badge badge-warning">⚠️ BAIXO (Mín: ${minStock})</span>`;
    } else {
      rowEl.classList.add('status-normal');
      badgeContainer.innerHTML = `<span class="quick-status-badge badge-success">✓ DISPONÍVEL</span>`;
    }
  }

  updateStockAlerts();

  // 2. Persistência Assíncrona no Supabase
  try {
    const { error: updateErr } = await supabaseClient
      .from('products')
      .update({ stock: newStock })
      .eq('id', prodId);

    if (updateErr) throw updateErr;

    // Registra no histórico de movimentações
    await supabaseClient.from('stock_movements').insert([{
      product_id: prodId,
      product_name: prod.name,
      type: delta > 0 ? 'entrada' : 'saida',
      quantity: Math.abs(delta),
      previous_stock: prevStock,
      new_stock: newStock,
      reason: delta > 0 ? 'Ajuste Rápido (+1)' : 'Ajuste Rápido (-1)'
    }]);

    showToast(`Estoque de "${prod.name}": ${newStock} ${prod.unit || 'un'}`, 'info', 1600);
  } catch (error) {
    console.error('Erro ao atualizar estoque:', error);
    // Reverter em caso de falha
    prod.stock = prevStock;
    renderQuickStock(productsList);
    showToast(`Erro ao sincronizar estoque de "${prod.name}".`, 'error');
  }
}


function populateProductSelects() {
  // Select no modal de produção
  const prodSelect = document.getElementById('prodModalSelect');
  if (prodSelect) {
    prodSelect.innerHTML = '<option value="">Selecione um produto...</option>' + 
      productsList.map(p => `<option value="${p.id}">${escapeHtml(p.name)} (Atual: ${p.stock || 0} un)</option>`).join('');
  }

  // Select no modal de venda
  const saleSelect = document.getElementById('saleProductSelect');
  if (saleSelect) {
    saleSelect.innerHTML = '<option value="">Selecione o produto...</option>' + 
      productsList.map(p => `<option value="${p.id}">${escapeHtml(p.name)} [Estoque: ${p.stock || 0} un]</option>`).join('');
  }

  // Select de receita no modal de produto
  const recSelect = document.getElementById('prodRecipeSelect');
  if (recSelect) {
    recSelect.innerHTML = '<option value="">Sem receita vinculada (custo manual)</option>' + 
      recipesList.map(r => `<option value="${r.id}">${escapeHtml(r.name)} (Custo: ${formatBRL(r.laborcost || 0)})</option>`).join('');
  }
}

// ==========================================================================
// GESTÃO DE FOTOS E IMAGENS DE PRODUTOS
// ==========================================================================
function handleProductImageFile(event) {
  const file = event.target.files && event.target.files[0];
  if (!file) return;

  if (!file.type.startsWith('image/')) {
    showToast('Por favor selecione um arquivo de imagem válido (JPG, PNG, WebP).', 'warning');
    return;
  }

  const reader = new FileReader();
  reader.onload = (e) => {
    const img = new Image();
    img.onload = () => {
      // Redimensiona para no máximo 600px mantendo a proporção para garantir leveza e rapidez
      const maxDim = 600;
      let width = img.width;
      let height = img.height;

      if (width > maxDim || height > maxDim) {
        if (width > height) {
          height = Math.round((height * maxDim) / width);
          width = maxDim;
        } else {
          width = Math.round((width * maxDim) / height);
          height = maxDim;
        }
      }

      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      const ctx = canvas.getContext('2d');
      ctx.drawImage(img, 0, 0, width, height);

      const compressedDataUrl = canvas.toDataURL('image/jpeg', 0.82);
      document.getElementById('prodImagePath').value = compressedDataUrl;

      // Atualiza visualização da prévia
      const previewImg = document.getElementById('prodImagePreview');
      const placeholder = document.getElementById('prodImagePlaceholder');
      const btnRemove = document.getElementById('btnRemoveImage');

      if (previewImg) {
        previewImg.src = compressedDataUrl;
        previewImg.style.display = 'block';
      }
      if (placeholder) placeholder.style.display = 'none';
      if (btnRemove) btnRemove.style.display = 'inline-flex';

      showToast('Foto do produto carregada com sucesso!', 'success');
    };
    img.src = e.target.result;
  };
  reader.readAsDataURL(file);
}

function handleProductImageUrl(url) {
  const trimmed = (url || '').trim();
  const previewImg = document.getElementById('prodImagePreview');
  const placeholder = document.getElementById('prodImagePlaceholder');
  const btnRemove = document.getElementById('btnRemoveImage');

  if (trimmed) {
    if (previewImg) {
      previewImg.src = trimmed;
      previewImg.style.display = 'block';
    }
    if (placeholder) placeholder.style.display = 'none';
    if (btnRemove) btnRemove.style.display = 'inline-flex';
  } else {
    removeProductImage();
  }
}

function removeProductImage() {
  document.getElementById('prodImagePath').value = '';
  const fileInput = document.getElementById('prodImageFile');
  if (fileInput) fileInput.value = '';

  const previewImg = document.getElementById('prodImagePreview');
  const placeholder = document.getElementById('prodImagePlaceholder');
  const btnRemove = document.getElementById('btnRemoveImage');

  if (previewImg) {
    previewImg.src = '';
    previewImg.style.display = 'none';
  }
  if (placeholder) placeholder.style.display = 'flex';
  if (btnRemove) btnRemove.style.display = 'none';
}

function getRecipeOptionsForProduct(selectedRecipeId = '') {
  const groups = new Map();
  recipesList.forEach(r => {
    const cat = getRecipeCategory(r.name);
    if (!groups.has(cat)) groups.set(cat, []);
    groups.get(cat).push(r);
  });

  let optionsHtml = '';
  groups.forEach((recs, catName) => {
    optionsHtml += `<optgroup label="${escapeHtml(catName)}">`;
    recs.forEach(r => {
      const cost = getRecipeTotalCost(r);
      const isSel = (r.id == selectedRecipeId) ? 'selected' : '';
      optionsHtml += `<option value="${r.id}" data-cost="${cost.toFixed(2)}" ${isSel}>${escapeHtml(r.name)} (${formatBRL(cost)})</option>`;
    });
    optionsHtml += `</optgroup>`;
  });
  return optionsHtml;
}

function addProductRecipeRow(recipeId = '', qty = 1) {
  const container = document.getElementById('productRecipesListContainer');
  if (!container) return;
  const uniqueId = `prodRec_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;

  const div = document.createElement('div');
  div.className = 'product-component-row';
  div.id = uniqueId;

  div.innerHTML = `
    <div>
      <select class="form-select prod-recipe-select" onchange="onProductRecipeRowChange('${uniqueId}')" required>
        <option value="">Selecione uma receita da ficha técnica...</option>
        ${getRecipeOptionsForProduct(recipeId)}
      </select>
    </div>
    <div>
      <input type="number" step="0.1" min="0.1" class="form-input prod-recipe-qty" value="${qty || 1}" placeholder="Qtd" oninput="onProductRecipeRowChange('${uniqueId}')" required title="Quantidade de lotes/receitas usadas">
    </div>
    <div class="component-cost-display prod-recipe-cost">
      R$ 0,00
    </div>
    <div class="text-right">
      <button type="button" class="btn-icon delete" title="Remover Receita" onclick="removeProductRecipeRow('${uniqueId}')">
        <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
      </button>
    </div>
  `;

  container.appendChild(div);
  onProductRecipeRowChange(uniqueId);
}

function removeProductRecipeRow(rowId) {
  const el = document.getElementById(rowId);
  if (el) el.remove();
  calcProductFullPricing();
}

function onProductRecipeRowChange(rowId) {
  const row = document.getElementById(rowId);
  if (!row) return;

  const sel = row.querySelector('.prod-recipe-select');
  const qtyInput = row.querySelector('.prod-recipe-qty');
  const costDiv = row.querySelector('.prod-recipe-cost');

  const recId = sel ? parseInt(sel.value, 10) : null;
  const qty = parseFloat(qtyInput ? qtyInput.value : 1) || 0;

  let cost = 0;
  if (recId) {
    const rec = recipesList.find(r => r.id === recId);
    if (rec) {
      cost = getRecipeTotalCost(rec) * qty;
    }
  }
  if (costDiv) costDiv.textContent = formatBRL(cost);
  calcProductFullPricing();
}

function addProductExpenseRow(expenseName = '', cost = 0) {
  const container = document.getElementById('productExpensesListContainer');
  if (!container) return;
  const uniqueId = `prodExp_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;

  const div = document.createElement('div');
  div.className = 'product-component-row';
  div.id = uniqueId;

  // Sugestões automáticas dos insumos de embalagem cadastrados
  const packagingSuggestions = ingredientsList.filter(i => {
    const n = (i.name || '').toLowerCase();
    return n.includes('embalag') || n.includes('saco') || n.includes('caixa') || n.includes('fita') || n.includes('acrílico') || (i.category || '').toLowerCase().includes('embalag');
  });

  const suggestionsOptions = packagingSuggestions.map(p => {
    const unitPrice = p.quantity > 0 ? (p.price / p.quantity) : 0;
    return `<option value="${escapeHtml(p.name)}">${escapeHtml(p.name)} (${formatBRL(unitPrice)})</option>`;
  }).join('');

  div.innerHTML = `
    <div>
      <input type="text" class="form-input prod-expense-name" list="expList_${uniqueId}" placeholder="Ex: Embalagem Slice Cake, Saco Kraft" value="${escapeHtml(expenseName)}" oninput="onProductExpenseNameInput('${uniqueId}')" required>
      <datalist id="expList_${uniqueId}">
        <option value="Embalagem Slice Cake">
        <option value="Saco Kraft">
        <option value="Caixa de Transporte">
        <option value="Etiqueta Personalizada">
        <option value="Fita de Cetim">
        <option value="Colherzinha / Guardanapo">
        ${suggestionsOptions}
      </datalist>
    </div>
    <div>
      <input type="number" step="1" min="1" class="form-input prod-expense-qty" value="1" placeholder="Qtd" oninput="onProductExpenseRowChange('${uniqueId}')" title="Quantidade de unidades usadas">
    </div>
    <div>
      <input type="number" step="0.01" min="0" class="form-input prod-expense-cost" value="${cost > 0 ? Number(cost).toFixed(2) : ''}" placeholder="Custo R$" oninput="onProductExpenseRowChange('${uniqueId}')" required>
    </div>
    <div class="text-right">
      <button type="button" class="btn-icon delete" title="Remover Insumo/Gasto" onclick="removeProductExpenseRow('${uniqueId}')">
        <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
      </button>
    </div>
  `;

  container.appendChild(div);
  onProductExpenseRowChange(uniqueId);
}

function removeProductExpenseRow(rowId) {
  const el = document.getElementById(rowId);
  if (el) el.remove();
  calcProductFullPricing();
}

function onProductExpenseNameInput(rowId) {
  const row = document.getElementById(rowId);
  if (!row) return;

  const nameInput = row.querySelector('.prod-expense-name');
  const costInput = row.querySelector('.prod-expense-cost');

  if (nameInput && costInput && (!costInput.value || parseFloat(costInput.value) === 0)) {
    const val = nameInput.value.trim().toLowerCase();
    const matchedIng = ingredientsList.find(i => i.name.toLowerCase() === val);
    if (matchedIng && matchedIng.quantity > 0) {
      const unitPrice = matchedIng.price / matchedIng.quantity;
      costInput.value = unitPrice.toFixed(2);
    } else if (val.includes('embalagem slice')) {
      costInput.value = '0.55';
    } else if (val.includes('saco kraft')) {
      costInput.value = '1.00';
    }
  }
  onProductExpenseRowChange(rowId);
}

function onProductExpenseRowChange(rowId) {
  calcProductFullPricing();
}

function calcProductFullPricing() {
  // 1. Somar receitas
  let recipesSubtotal = 0;
  const recRows = document.querySelectorAll('#productRecipesListContainer .product-component-row');
  recRows.forEach(row => {
    const sel = row.querySelector('.prod-recipe-select');
    const qtyInput = row.querySelector('.prod-recipe-qty');
    const costDiv = row.querySelector('.prod-recipe-cost');

    const recId = sel ? parseInt(sel.value, 10) : null;
    const qty = parseFloat(qtyInput ? qtyInput.value : 1) || 0;

    let rowCost = 0;
    if (recId) {
      const rec = recipesList.find(r => r.id === recId);
      if (rec) {
        rowCost = getRecipeTotalCost(rec) * qty;
      }
    }
    if (costDiv) costDiv.textContent = formatBRL(rowCost);
    recipesSubtotal += rowCost;
  });

  const recSubEl = document.getElementById('productRecipesSubtotalPreview');
  if (recSubEl) recSubEl.textContent = formatBRL(recipesSubtotal);

  // 2. Somar gastos extras
  let expensesSubtotal = 0;
  const expRows = document.querySelectorAll('#productExpensesListContainer .product-component-row');
  expRows.forEach(row => {
    const qtyInput = row.querySelector('.prod-expense-qty');
    const costInput = row.querySelector('.prod-expense-cost');

    const qty = parseFloat(qtyInput ? qtyInput.value : 1) || 1;
    const unitCost = parseFloat(costInput ? costInput.value : 0) || 0;
    const rowCost = unitCost * qty;
    expensesSubtotal += rowCost;
  });

  const expSubEl = document.getElementById('productExpensesSubtotalPreview');
  if (expSubEl) expSubEl.textContent = formatBRL(expensesSubtotal);

  // 3. Custo total do lote e por fatia
  const totalBatchCost = recipesSubtotal + expensesSubtotal;
  const yieldAmt = parseFloat(document.getElementById('prodYieldAmount')?.value) || 1;
  const unitName = document.getElementById('prodUnit')?.value.trim() || 'fatia';
  const unitCost = yieldAmt > 0 ? (totalBatchCost / yieldAmt) : totalBatchCost;

  const totalCostEl = document.getElementById('previewProdTotalBatchCost');
  const unitCostEl = document.getElementById('previewProdUnitCost');
  if (totalCostEl) totalCostEl.textContent = formatBRL(totalBatchCost);
  if (unitCostEl) unitCostEl.textContent = `${formatBRL(unitCost)} / ${unitName}`;

  // 4. Margem de lucro e preço sugerido
  const marginPercent = parseFloat(document.getElementById('prodMargin')?.value) || 30;
  const suggestedBatchPrice = totalBatchCost * (1 + (marginPercent / 100));
  const suggestedUnitPrice = yieldAmt > 0 ? (suggestedBatchPrice / yieldAmt) : suggestedBatchPrice;

  const sugBatchEl = document.getElementById('previewProdSuggestedBatch');
  const sugUnitEl = document.getElementById('previewProdSuggestedUnit');
  if (sugBatchEl) sugBatchEl.textContent = formatBRL(suggestedBatchPrice);
  if (sugUnitEl) sugUnitEl.textContent = `${formatBRL(suggestedUnitPrice)} / ${unitName}`;

  // 5. Preço praticado de venda Balcão
  const sellPriceInput = document.getElementById('prodSellPrice');
  const sellPriceVal = parseFloat(sellPriceInput?.value) || 0;

  const sellHelp = document.getElementById('previewSellPricePerUnitHelp');
  if (sellHelp) {
    if (sellPriceVal > 0) {
      const sellPerUnit = yieldAmt > 0 ? (sellPriceVal / yieldAmt) : sellPriceVal;
      sellHelp.textContent = `Venda por ${unitName}: ${formatBRL(sellPerUnit)}`;
    } else {
      sellHelp.textContent = `Venda por ${unitName}: R$ 0,00`;
    }
  }

  // 6. Preço iFood sugerido (taxa 23%)
  const ifoodHelp = document.getElementById('previewIfoodSuggestedHelp');
  if (ifoodHelp) {
    if (sellPriceVal > 0) {
      const suggestedIfood = sellPriceVal / (1 - 0.23);
      ifoodHelp.textContent = `Sugerido iFood (taxa 23%): ${formatBRL(suggestedIfood)}`;
      const ifoodInput = document.getElementById('prodIfoodPrice');
      if (ifoodInput && (!ifoodInput.value || parseFloat(ifoodInput.value) === 0)) {
        ifoodInput.value = suggestedIfood.toFixed(2);
      }
    } else {
      ifoodHelp.textContent = `Sugerido iFood (taxa 23%): R$ 0,00`;
    }
  }

  // 7. Lucro projetado real (positivo ou negativo)
  const realProfitBatch = sellPriceVal - totalBatchCost;
  const realProfitUnit = yieldAmt > 0 ? (realProfitBatch / yieldAmt) : realProfitBatch;
  const isPositive = realProfitBatch >= 0;

  const profitBox = document.getElementById('productProfitBox');
  const profitTitle = document.getElementById('profitCalloutTitle');
  const profitBatchEl = document.getElementById('previewProfitBatch');
  const profitUnitEl = document.getElementById('previewProfitUnit');

  if (profitBox) {
    if (isPositive) {
      profitBox.className = 'product-profit-callout positive';
      if (profitTitle) profitTitle.textContent = '✓ LUCRO PROJETADO (LOJA / BALCÃO)';
    } else {
      profitBox.className = 'product-profit-callout negative';
      if (profitTitle) profitTitle.textContent = '⚠️ PREJUÍZO DETECTADO - AUMENTE O PREÇO DE VENDA';
    }
  }

  if (profitBatchEl) profitBatchEl.textContent = formatBRL(realProfitBatch);
  if (profitUnitEl) profitUnitEl.textContent = `${formatBRL(realProfitUnit)} / ${unitName}`;
}

function openProductModal(prodId = null) {
  const prod = productsList.find(p => p.id === prodId);

  document.getElementById('prodId').value = prod ? prod.id : '';
  document.getElementById('prodName').value = prod ? prod.name : '';
  document.getElementById('prodCategory').value = prod ? (prod.category || 'Slice Cakes') : 'Slice Cakes';
  document.getElementById('prodYieldAmount').value = prod ? (prod.yieldAmount || 10) : 10;
  document.getElementById('prodUnit').value = prod ? (prod.unit || 'fatia') : 'fatia';
  document.getElementById('prodIsFeatured').checked = prod ? (prod.isFeatured == 1 || prod.isFeatured === true) : false;
  document.getElementById('prodMargin').value = prod ? (prod.profitMarginPercent || 30) : 30;
  document.getElementById('prodSellPrice').value = prod && prod.sellPrice ? prod.sellPrice : '';
  document.getElementById('prodIfoodPrice').value = prod && prod.ifoodPrice ? prod.ifoodPrice : '';
  document.getElementById('prodStock').value = prod ? (prod.stock || 0) : 0;
  document.getElementById('prodMinStock').value = prod ? (prod.minStock || 5) : 5;

  // Configuração da Imagem do Produto
  const imagePath = prod && prod.imagePath ? prod.imagePath : '';
  document.getElementById('prodImagePath').value = imagePath;
  const fileInput = document.getElementById('prodImageFile');
  if (fileInput) fileInput.value = '';

  const previewImg = document.getElementById('prodImagePreview');
  const placeholder = document.getElementById('prodImagePlaceholder');
  const btnRemove = document.getElementById('btnRemoveImage');

  if (imagePath) {
    if (previewImg) {
      previewImg.src = imagePath;
      previewImg.style.display = 'block';
    }
    if (placeholder) placeholder.style.display = 'none';
    if (btnRemove) btnRemove.style.display = 'inline-flex';
  } else {
    if (previewImg) {
      previewImg.src = '';
      previewImg.style.display = 'none';
    }
    if (placeholder) placeholder.style.display = 'flex';
    if (btnRemove) btnRemove.style.display = 'none';
  }

  // Limpa containers dinâmicos de receitas e gastos
  const recContainer = document.getElementById('productRecipesListContainer');
  const expContainer = document.getElementById('productExpensesListContainer');
  if (recContainer) recContainer.innerHTML = '';
  if (expContainer) expContainer.innerHTML = '';

  if (prod) {
    // Carrega receitas vinculadas existentes
    const linkedRecs = productRecipesList.filter(pr => (pr.productid || pr.productId) === prod.id);
    if (linkedRecs.length > 0) {
      linkedRecs.forEach(pr => {
        addProductRecipeRow(pr.recipeid || pr.recipeId, pr.quantityused || 1);
      });
    } else {
      addProductRecipeRow();
    }

    // Carrega gastos extras vinculados existentes
    const linkedExps = productExpensesList.filter(pe => (pe.productid || pe.productId) === prod.id);
    if (linkedExps.length > 0) {
      linkedExps.forEach(pe => {
        addProductExpenseRow(pe.name, pe.cost);
      });
    } else {
      addProductExpenseRow('Embalagem Slice Cake', 0.55);
    }
  } else {
    // Novo Produto: Adiciona linhas iniciais limpas
    addProductRecipeRow();
    addProductExpenseRow('Embalagem Slice Cake', 0.55);
  }

  calcProductFullPricing();
  document.getElementById('productModalTitle').textContent = prod ? 'Editar Produto & Precificação' : 'Cadastrar Produto & Precificação';
  openModal('productModal');
}

async function saveProduct(e) {
  e.preventDefault();
  const id = document.getElementById('prodId').value;
  const yieldAmount = parseFloat(document.getElementById('prodYieldAmount').value) || 1;
  const margin = parseFloat(document.getElementById('prodMargin').value) || 30;
  const sellPrice = parseFloat(document.getElementById('prodSellPrice').value) || 0;
  const ifoodPrice = parseFloat(document.getElementById('prodIfoodPrice').value) || 0;
  const stock = parseFloat(document.getElementById('prodStock').value) || 0;
  const minStock = parseFloat(document.getElementById('prodMinStock').value) || 0;
  const unit = document.getElementById('prodUnit').value.trim() || 'fatia';
  const isFeatured = document.getElementById('prodIsFeatured').checked ? 1 : 0;
  const name = document.getElementById('prodName').value.trim();
  const category = document.getElementById('prodCategory').value.trim() || 'Slice Cakes';
  const imagePath = document.getElementById('prodImagePath').value.trim() || '';

  // 1. Coletar receitas
  const recipesToSave = [];
  let totalCostFromRecipes = 0;
  const recRows = document.querySelectorAll('#productRecipesListContainer .product-component-row');
  recRows.forEach(row => {
    const sel = row.querySelector('.prod-recipe-select');
    const qtyInput = row.querySelector('.prod-recipe-qty');
    const recId = sel ? parseInt(sel.value, 10) : null;
    const qty = parseFloat(qtyInput ? qtyInput.value : 1) || 1;
    if (recId) {
      const rec = recipesList.find(r => r.id === recId);
      const cost = rec ? (getRecipeTotalCost(rec) * qty) : 0;
      totalCostFromRecipes += cost;
      recipesToSave.push({
        recipeid: recId,
        quantityused: qty,
        cost: cost
      });
    }
  });

  // 2. Coletar gastos extras
  const expensesToSave = [];
  let totalCostFromExpenses = 0;
  const expRows = document.querySelectorAll('#productExpensesListContainer .product-component-row');
  expRows.forEach(row => {
    const nameInput = row.querySelector('.prod-expense-name');
    const qtyInput = row.querySelector('.prod-expense-qty');
    const costInput = row.querySelector('.prod-expense-cost');

    const expName = nameInput ? nameInput.value.trim() : '';
    const qty = parseFloat(qtyInput ? qtyInput.value : 1) || 1;
    const unitCost = parseFloat(costInput ? costInput.value : 0) || 0;
    const totalRowCost = unitCost * qty;

    if (expName && totalRowCost > 0) {
      totalCostFromExpenses += totalRowCost;
      expensesToSave.push({
        name: expName,
        cost: totalRowCost
      });
    }
  });

  const totalCost = totalCostFromRecipes + totalCostFromExpenses;
  const suggestedPrice = totalCost * (1 + (margin / 100));

  const prodPayload = {
    name,
    category,
    yieldAmount,
    unit,
    profitMarginPercent: margin,
    suggestedPrice,
    sellPrice,
    ifoodPrice,
    stock,
    minStock,
    isFeatured,
    imagePath
  };

  try {
    let savedProdId = id ? parseInt(id, 10) : null;
    if (savedProdId) {
      // 1. Atualiza produto existente
      const { error: prodErr } = await supabaseClient.from('products').update(prodPayload).eq('id', savedProdId);
      if (prodErr) throw prodErr;
    } else {
      // 1. Cadastra novo produto
      const { data: newProd, error: insertErr } = await supabaseClient.from('products').insert([prodPayload]).select().single();
      if (insertErr) throw insertErr;
      savedProdId = newProd.id;
    }

    // 2. Atualiza atomicamente product_recipes
    await supabaseClient.from('product_recipes').delete().eq('productid', savedProdId);
    if (recipesToSave.length > 0) {
      const prPayload = recipesToSave.map(pr => ({ ...pr, productid: savedProdId }));
      const { error: prErr } = await supabaseClient.from('product_recipes').insert(prPayload);
      if (prErr) console.warn('Aviso ao salvar product_recipes:', prErr);
    }

    // 3. Atualiza atomicamente product_expenses
    await supabaseClient.from('product_expenses').delete().eq('productid', savedProdId);
    if (expensesToSave.length > 0) {
      const pePayload = expensesToSave.map(pe => ({ ...pe, productid: savedProdId }));
      const { error: peErr } = await supabaseClient.from('product_expenses').insert(pePayload);
      if (peErr) console.warn('Aviso ao salvar product_expenses:', peErr);
    }

    showToast(id ? `Produto "${name}" atualizado com sucesso!` : `Produto "${name}" cadastrado com sucesso!`, 'success');
    closeModal('productModal');
    await loadAllData();
  } catch (error) {
    console.error('Erro ao salvar produto:', error);
    showToast('Erro ao salvar produto no banco: ' + (error.message || error), 'error');
  }
}

// ==========================================
// 5. REGISTRO DE PRODUÇÃO (INCREMENTO RÁPIDO)
// ==========================================
function openProductionModal() {
  populateProductSelects();
  document.getElementById('prodModalQty').value = '';
  document.getElementById('prodModalReason').value = '';
  document.getElementById('prodModalCurrentStock').value = '0 un';
  openModal('productionModal');
}

function openProductionForSpecificProduct(prodId) {
  openProductionModal();
  document.getElementById('prodModalSelect').value = prodId;
  updateProductionCurrentStock();
}

function updateProductionCurrentStock() {
  const prodId = document.getElementById('prodModalSelect').value;
  const prod = productsList.find(p => p.id == prodId);
  document.getElementById('prodModalCurrentStock').value = prod ? `${prod.stock || 0} ${prod.unit || 'un'}` : '0 un';
}

async function submitProduction(e) {
  e.preventDefault();
  const prodId = document.getElementById('prodModalSelect').value;
  const qty = parseFloat(document.getElementById('prodModalQty').value) || 0;
  const reason = document.getElementById('prodModalReason').value.trim() || 'Produção de Lote';

  if (!prodId || qty <= 0) {
    showToast('Selecione o produto e informe a quantidade.', 'warning');
    return;
  }

  const prod = productsList.find(p => p.id == prodId);
  const prevStock = Number(prod ? prod.stock : 0) || 0;
  const newStock = prevStock + qty;

  try {
    // 1. Atualiza estoque no produto
    await supabaseClient.from('products').update({ stock: newStock }).eq('id', prodId);

    // 2. Registra histórico na tabela stock_movements
    await supabaseClient.from('stock_movements').insert([{
      product_id: prodId,
      product_name: prod ? prod.name : 'Produto',
      type: 'entrada',
      quantity: qty,
      previous_stock: prevStock,
      new_stock: newStock,
      reason: reason
    }]);

    showToast(`Produção registrada! +${qty} un adicionadas ao estoque.`, 'success');
    closeModal('productionModal');
    await loadAllData();
  } catch (error) {
    console.error('Erro ao registrar produção:', error);
    showToast('Erro ao atualizar estoque de produção.', 'error');
  }
}

// ==========================================
// 6. REGISTRO DE VENDAS (BAIXA AUTOMÁTICA)
// ==========================================
function openSaleModal() {
  populateProductSelects();
  initDateInputs();
  document.getElementById('saleQuantity').value = '1';
  document.getElementById('saleNotes').value = '';
  onSaleProductChange();
  openModal('saleModal');
}

function onSaleProductChange() {
  const prodId = document.getElementById('saleProductSelect').value;
  const channel = document.getElementById('saleChannel').value;
  const prod = productsList.find(p => p.id == prodId);

  const stockInput = document.getElementById('saleStockAvailable');
  const priceInput = document.getElementById('saleUnitPrice');

  if (prod) {
    stockInput.value = `${prod.stock || 0} ${prod.unit || 'un'}`;
    if (channel === 'ifood' && prod.ifoodPrice > 0) {
      priceInput.value = prod.ifoodPrice.toFixed(2);
    } else {
      priceInput.value = (prod.sellPrice || 15.00).toFixed(2);
    }
  } else {
    stockInput.value = '-';
    priceInput.value = '15.00';
  }
  calcSaleTotals();
}

function calcSaleTotals() {
  const qty = parseFloat(document.getElementById('saleQuantity').value) || 1;
  const unitPrice = parseFloat(document.getElementById('saleUnitPrice').value) || 0;
  const channel = document.getElementById('saleChannel').value;
  const prodId = document.getElementById('saleProductSelect').value;
  const prod = productsList.find(p => p.id == prodId);

  const totalValue = qty * unitPrice;
  let commissionValue = 0;
  if (channel === 'ifood') {
    commissionValue = totalValue * 0.262; // Taxa 26,2%
  }

  const cost = qty * 4.50; // Custo estimado
  const netProfit = (totalValue - commissionValue) - cost;

  document.getElementById('saleTotalValuePreview').textContent = formatBRL(totalValue);
  document.getElementById('saleCommissionPreview').textContent = `- ${formatBRL(commissionValue)}`;
  document.getElementById('saleNetProfitPreview').textContent = formatBRL(netProfit);
}

async function submitSale(e) {
  e.preventDefault();
  const prodId = document.getElementById('saleProductSelect').value;
  const qty = parseFloat(document.getElementById('saleQuantity').value) || 1;
  const unitPrice = parseFloat(document.getElementById('saleUnitPrice').value) || 0;
  const channel = document.getElementById('saleChannel').value;
  const payment = document.getElementById('salePaymentMethod').value;
  const notes = document.getElementById('saleNotes').value.trim();
  const saleDateStr = document.getElementById('saleDate').value;

  if (!prodId) {
    showToast('Selecione o produto vendido.', 'warning');
    return;
  }

  const prod = productsList.find(p => p.id == prodId);
  const totalValue = qty * unitPrice;
  const isIfood = channel === 'ifood';
  const commissionPercent = isIfood ? 26.2 : 0;
  const commissionValue = isIfood ? (totalValue * 0.262) : 0;
  const cost = qty * 4.50;
  const netProfit = (totalValue - commissionValue) - cost;
  const saleDate = saleDateStr ? new Date(saleDateStr).toISOString() : new Date().toISOString();

  // 1. Inserir Venda na tabela sales
  try {
    await supabaseClient.from('sales').insert([{
      productid: prodId,
      productname: prod ? prod.name : 'Venda',
      quantity: qty,
      totalvalue: totalValue,
      totalcost: cost,
      totalprofit: totalValue - cost,
      sellertype: channel,
      sellername: isIfood ? 'iFood (Plano Entrega)' : 'Você',
      commissionpercent: commissionPercent,
      commissionvalue: commissionValue,
      netprofit: netProfit,
      saledate: saleDate,
      notes: notes ? `${notes} | Pgto: ${payment}` : `Pgto: ${payment}`
    }]);

    // 2. BAIXA AUTOMÁTICA DE ESTOQUE
    const prevStock = Number(prod ? prod.stock : 0) || 0;
    const newStock = Math.max(0, prevStock - qty);

    await supabaseClient.from('products').update({ stock: newStock }).eq('id', prodId);

    // 3. REGISTRO NO HISTÓRICO DE MOVIMENTAÇÃO DE ESTOQUE
    await supabaseClient.from('stock_movements').insert([{
      product_id: prodId,
      product_name: prod ? prod.name : 'Produto',
      type: 'saida',
      quantity: qty,
      previous_stock: prevStock,
      new_stock: newStock,
      reason: `Venda ${channel.toUpperCase()} (${payment})`
    }]);

    showToast(`Venda registrada! ${qty} un baixadas do estoque automaticamente.`, 'success');
    closeModal('saleModal');
    await loadAllData();
  } catch (error) {
    console.error('Erro ao registrar venda:', error);
    showToast('Erro ao processar venda e baixa de estoque.', 'error');
  }
}

// ==========================================
// 7. TABELA DE VENDAS & FILTROS
// ==========================================
function renderSalesTable(list) {
  const tbody = document.getElementById('salesTableBody');
  if (!tbody) return;

  if (list.length === 0) {
    tbody.innerHTML = '<tr><td colspan="8" class="text-center py-6 text-muted">Nenhuma venda encontrada.</td></tr>';
    return;
  }

  tbody.innerHTML = list.map(s => {
    const isIfood = (s.sellertype || s.sellerType || '').toLowerCase() === 'ifood';
    const channelBadge = isIfood ? '<span class="badge-stock warning">iFood (26,2%)</span>' : '<span class="badge-stock ok">Venda Direta</span>';

    return `
      <tr>
        <td>${formatDate(s.saledate || s.saleDate)}</td>
        <td><strong>${escapeHtml(s.productname || s.productName)}</strong></td>
        <td>${s.quantity} un</td>
        <td>${channelBadge}</td>
        <td><strong>${formatBRL(s.totalvalue || s.totalValue)}</strong></td>
        <td class="text-red">- ${formatBRL(s.commissionvalue || s.commissionValue || 0)}</td>
        <td class="text-green font-bold">${formatBRL(s.netprofit || s.netProfit)}</td>
        <td style="font-size:12px; color:#64748b;">${escapeHtml(s.notes || '-')}</td>
      </tr>
    `;
  }).join('');
}

function filterSales() {
  const q = document.getElementById('salesSearchInput').value.toLowerCase();
  const channel = document.getElementById('salesChannelFilter').value;

  const filtered = salesList.filter(s => {
    const nameMatch = (s.productname || s.productName || '').toLowerCase().includes(q) || 
                      (s.notes || '').toLowerCase().includes(q);
    const channelType = (s.sellertype || s.sellerType || 'me').toLowerCase();
    const channelMatch = channel === 'all' || channelType === channel;

    return nameMatch && channelMatch;
  });

  renderSalesTable(filtered);
}

// ==========================================
// 8. HISTÓRICO DE MOVIMENTAÇÕES DE ESTOQUE
// ==========================================
async function openMovementsHistoryModal() {
  const tbody = document.getElementById('movementsTableBody');
  tbody.innerHTML = '<tr><td colspan="7" class="text-center py-4">Carregando movimentações...</td></tr>';
  openModal('movementsModal');

  try {
    const { data, error } = await supabaseClient
      .from('stock_movements')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) throw error;

    if (!data || data.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" class="text-center py-6 text-muted">Nenhuma movimentação registrada até o momento.</td></tr>';
      return;
    }

    tbody.innerHTML = data.map(m => {
      const isEntrada = m.type === 'entrada';
      const badge = isEntrada 
        ? '<span class="badge-stock ok">ENTRADA (+)</span>' 
        : '<span class="badge-stock danger">SAÍDA (-)</span>';

      return `
        <tr>
          <td>${formatDate(m.created_at)}</td>
          <td><strong>${escapeHtml(m.product_name)}</strong></td>
          <td>${badge}</td>
          <td class="font-bold ${isEntrada ? 'text-green' : 'text-red'}">${isEntrada ? '+' : '-'}${m.quantity} un</td>
          <td>${m.previous_stock ?? '-'} un</td>
          <td><strong>${m.new_stock ?? '-'} un</strong></td>
          <td>${escapeHtml(m.reason || '-')}</td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    console.error('Erro ao carregar histórico:', err);
    tbody.innerHTML = '<tr><td colspan="7" class="text-center text-red py-4">Erro ao carregar histórico.</td></tr>';
  }
}

// ==========================================
// 9. FUNÇÕES UTILITÁRIAS & UI
// ==========================================
function openModal(id) {
  const el = document.getElementById(id);
  if (el) el.classList.add('active');
}

function closeModal(id) {
  const el = document.getElementById(id);
  if (el) el.classList.remove('active');
}

function formatBRL(val) {
  const num = Number(val) || 0;
  return num.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

function formatBRL4(val) {
  const num = Number(val) || 0;
  return 'R$ ' + num.toLocaleString('pt-BR', { minimumFractionDigits: 4, maximumFractionDigits: 4 });
}

function formatUnitCost(price, qty, unit) {
  const p = Number(price) || 0;
  const q = Number(qty) || 0;
  if (q <= 0) return 'R$ 0,00';
  const u = (unit || '').toLowerCase().trim();
  const unitPrice = p / q;

  if (u === 'g') {
    const perKg = unitPrice * 1000;
    return `${formatBRL4(unitPrice)}/g <span style="font-size:11px; font-weight:normal; color:#64748b;">(${formatBRL(perKg)}/kg)</span>`;
  }
  if (u === 'ml') {
    const perLiter = unitPrice * 1000;
    return `${formatBRL4(unitPrice)}/ml <span style="font-size:11px; font-weight:normal; color:#64748b;">(${formatBRL(perLiter)}/L)</span>`;
  }
  return `${formatBRL(unitPrice)} / ${unit || 'un'}`;
}

function formatDate(dateStr) {
  if (!dateStr) return '-';
  const d = new Date(dateStr);
  return d.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

function formatDateOnly(dateStr) {
  if (!dateStr) return '-';
  const parts = dateStr.split('-');
  if (parts.length === 3) return `${parts[2]}/${parts[1]}/${parts[0]}`;
  const d = new Date(dateStr);
  return d.toLocaleDateString('pt-BR');
}

function escapeHtml(text) {
  if (!text) return '';
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function showToast(message, type = 'success') {
  const container = document.getElementById('toastContainer');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `
    <span>${type === 'success' ? '✅' : type === 'warning' ? '⚠️' : '❌'}</span>
    <span>${escapeHtml(message)}</span>
  `;

  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(100%)';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}
