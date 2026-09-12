// CONFIGURAÇÃO CENTRAL DO SUPABASE (DOCE & PONTO)
const SUPABASE_URL = 'https://jfpswioaikpflvjiylqa.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpmcHN3aW9haWtwZmx2aml5bHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMzA3ODQsImV4cCI6MjA5NDkwNjc4NH0.lZmckQNXdD99KAWpdYoY9Eb5rRdcmVzQh9S67rXXPdM';

const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// CACHE EM MEMÓRIA LOCAL
let ingredientsList = [];
let recipesList = [];
let productsList = [];
let salesList = [];
let movementsList = [];

// CHARTS INSTANCES
let revenueProfitChartInstance = null;
let channelChartInstance = null;

// INICIALIZAÇÃO DA APLICAÇÃO
document.addEventListener('DOMContentLoaded', async () => {
  checkDeviceRestriction();
  setupNavigation();
  initDateInputs();
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
    products: { title: 'Produtos & Estoque Pronto', subtitle: 'Preços, margens e controle completo de estoque de produtos acabados' },
    sales: { title: 'Registro de Vendas', subtitle: 'Lançamento de vendas com baixa automática de estoque e cálculo de lucro' },
  };

  const meta = titles[viewId] || titles.dashboard;
  document.getElementById('pageTitle').textContent = meta.title;
  document.getElementById('pageSubtitle').textContent = meta.subtitle;

  if (viewId === 'dashboard') {
    renderDashboard();
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
    const [ingRes, recRes, prodRes, salesRes, movRes] = await Promise.all([
      supabaseClient.from('ingredients').select('*').order('name', { ascending: true }),
      supabaseClient.from('recipes').select('*').order('name', { ascending: true }),
      supabaseClient.from('products').select('*').order('name', { ascending: true }),
      supabaseClient.from('sales').select('*').order('saledate', { ascending: false }),
      supabaseClient.from('stock_movements').select('*').order('created_at', { ascending: false }),
    ]);

    ingredientsList = ingRes.data || [];
    recipesList = recRes.data || [];
    productsList = prodRes.data || [];
    salesList = salesRes.data || [];
    movementsList = movRes.data || [];

    renderDashboard();
    renderIngredientsTable(ingredientsList);
    renderRecipesTable(recipesList);
    renderProductsTable(productsList);
    renderSalesTable(salesList);
    updateStockAlerts();
    populateProductSelects();

  } catch (error) {
    console.error('Erro ao carregar dados do Supabase:', error);
    showToast('Erro ao carregar dados do servidor.', 'error');
  }
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

  document.getElementById('dashTotalRevenue').textContent = formatBRL(totalRev);
  document.getElementById('dashNetProfit').textContent = formatBRL(totalNetProfit);
  document.getElementById('dashTotalSales').textContent = monthSales.length;

  const totalStockUnits = productsList.reduce((acc, p) => acc + (Number(p.stock) || 0), 0);
  document.getElementById('dashTotalStock').textContent = `${totalStockUnits} un`;

  // Alertas de estoque
  const lowStockProducts = productsList.filter(p => (Number(p.stock) || 0) <= (Number(p.minStock) || 0));
  const badge = document.getElementById('stockAlertBadge');
  const banner = document.getElementById('lowStockBanner');
  const alertCountEl = document.getElementById('dashStockAlertCount');

  if (lowStockProducts.length > 0) {
    badge.style.display = 'inline-block';
    badge.textContent = lowStockProducts.length;
    banner.style.display = 'flex';
    document.getElementById('lowStockText').textContent = 
      `Há ${lowStockProducts.length} produto(s) no limite ou abaixo do estoque mínimo: ${lowStockProducts.map(p => p.name).slice(0, 3).join(', ')}${lowStockProducts.length > 3 ? '...' : ''}`;
    alertCountEl.textContent = `${lowStockProducts.length} produto(s) em alerta!`;
    alertCountEl.style.color = '#ef4444';
  } else {
    badge.style.display = 'none';
    banner.style.display = 'none';
    alertCountEl.textContent = 'Estoque regular e seguro';
    alertCountEl.style.color = '#059669';
  }

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
          <td><strong>${formatBRL(s.totalvalue || s.totalValue)}</strong></td>
          <td class="text-green font-bold">${formatBRL(s.netprofit || s.netProfit)}</td>
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

function updateStockAlerts() {
  const lowStockProducts = productsList.filter(p => (Number(p.stock) || 0) <= (Number(p.minStock) || 0));
  const badge = document.getElementById('stockAlertBadge');
  if (badge) {
    badge.textContent = lowStockProducts.length;
    badge.style.display = lowStockProducts.length > 0 ? 'inline-block' : 'none';
  }
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
    const unitPrice = (ing.quantity && ing.quantity > 0) ? (ing.price / ing.quantity) : 0;
    return `
      <tr>
        <td><strong>${escapeHtml(ing.name)}</strong></td>
        <td><span class="stat-badge blue">${escapeHtml(ing.category || 'Geral')}</span></td>
        <td>${ing.quantity} ${ing.unit}</td>
        <td>${formatBRL(ing.price)}</td>
        <td class="text-green font-bold">${formatBRL(unitPrice)} / ${ing.unit}</td>
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
  const unit = document.getElementById('ingUnit').value;

  const cost = qty > 0 ? (price / qty) : 0;
  document.getElementById('ingUnitCostPreview').textContent = `${formatBRL(cost)} por ${unit}`;
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

function renderRecipesTable(list) {
  const tbody = document.getElementById('recipesTableBody');
  if (!tbody) return;

  if (list.length === 0) {
    tbody.innerHTML = '<tr><td colspan="5" class="text-center py-6 text-muted">Nenhuma receita cadastrada.</td></tr>';
    return;
  }

  tbody.innerHTML = list.map(rec => {
    const yieldAmount = rec.yieldamount || 1;
    const labor = rec.laborcost || 0;
    return `
      <tr>
        <td><strong>${escapeHtml(rec.name)}</strong></td>
        <td>${yieldAmount} ${escapeHtml(rec.yieldunit || 'un')}</td>
        <td>${formatBRL(labor)}</td>
        <td class="text-green font-bold">${formatBRL(yieldAmount > 0 ? labor / yieldAmount : 0)} / un</td>
        <td class="text-right">
          <button class="btn btn-sm btn-secondary" onclick="openProductionFromRecipe(${rec.id})">+ Produzir</button>
        </td>
      </tr>
    `;
  }).join('');
}

function filterRecipes() {
  const q = document.getElementById('recipeSearchInput').value.toLowerCase();
  const filtered = recipesList.filter(r => r.name.toLowerCase().includes(q));
  renderRecipesTable(filtered);
}

function openRecipeModal() {
  document.getElementById('recipeId').value = '';
  document.getElementById('recipeName').value = '';
  document.getElementById('recipeYieldAmount').value = '1';
  document.getElementById('recipeIngredientsList').innerHTML = '';
  currentRecipeItems = [];
  addRecipeIngredientRow();
  calcRecipeTotalCost();
  openModal('recipeModal');
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
    closeModal('recipeModal');
    await loadAllData();
  } catch (error) {
    console.error('Erro ao salvar receita:', error);
    showToast('Erro ao salvar receita.', 'error');
  }
}

// ==========================================
// 4. MÓDULO DE PRODUTOS & ESTOQUE PRONTO
// ==========================================
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
          <div style="display:flex; align-items:center; gap:10px;">
            <div style="width:36px; height:36px; border-radius:8px; background:#e0f2fe; display:flex; align-items:center; justify-content:center; font-size:18px;">🍰</div>
            <div>
              <strong>${escapeHtml(prod.name)}</strong>
              <div style="font-size:11px; color:#64748b;">Rende ${prod.yieldAmount || 1} ${prod.unit || 'un'}</div>
            </div>
          </div>
        </td>
        <td><span class="stat-badge blue">${escapeHtml(prod.category || 'Geral')}</span></td>
        <td><strong>${formatBRL(prod.sellPrice)}</strong></td>
        <td><span style="color:#ea1d2c; font-weight:700;">${prod.ifoodPrice > 0 ? formatBRL(prod.ifoodPrice) : '-'}</span></td>
        <td>${formatBRL(prod.suggestedPrice ? prod.suggestedPrice / 2 : 0)}</td>
        <td><span class="badge-stock ${badgeClass}">${stock} ${prod.unit || 'un'}</span></td>
        <td>${minStock} ${prod.unit || 'un'}</td>
        <td><span class="badge-stock ${badgeClass}">${statusText}</span></td>
        <td class="text-right">
          <button class="btn btn-sm btn-secondary" onclick="openProductionForSpecificProduct(${prod.id})">+ Produzir</button>
          <button class="btn-icon" title="Editar" onclick="openProductModal(${prod.id})">
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
          </button>
        </td>
      </tr>
    `;
  }).join('');
}

function filterProducts() {
  const q = document.getElementById('prodSearchInput').value.toLowerCase();
  const filtered = productsList.filter(p => p.name.toLowerCase().includes(q) || (p.category || '').toLowerCase().includes(q));
  renderProductsTable(filtered);
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

function openProductModal(prodId = null) {
  populateProductSelects();
  const prod = productsList.find(p => p.id === prodId);

  document.getElementById('prodId').value = prod ? prod.id : '';
  document.getElementById('prodName').value = prod ? prod.name : '';
  document.getElementById('prodCategory').value = prod ? prod.category || '' : 'Geral';
  document.getElementById('prodSellPrice').value = prod ? prod.sellPrice : '';
  document.getElementById('prodIfoodPrice').value = prod && prod.ifoodPrice ? prod.ifoodPrice : '20.99';
  document.getElementById('prodStock').value = prod ? prod.stock || 0 : '0';
  document.getElementById('prodMinStock').value = prod ? prod.minStock || 5 : '5';
  document.getElementById('prodUnit').value = prod ? prod.unit || 'unidade' : 'unidade';

  document.getElementById('productModalTitle').textContent = prod ? 'Editar Produto & Estoque' : 'Cadastrar Produto & Estoque';
  openModal('productModal');
}

function onProductRecipeChange() {
  const recId = document.getElementById('prodRecipeSelect').value;
  const rec = recipesList.find(r => r.id == recId);
  if (rec) {
    const yieldAmount = rec.yieldamount || 1;
    const unitCost = yieldAmount > 0 ? (rec.laborcost || 0) / yieldAmount : 0;
    document.getElementById('prodCost').value = unitCost.toFixed(2);
    calcProductPrices();
  }
}

function calcProductPrices() {
  const cost = parseFloat(document.getElementById('prodCost').value) || 0;
  const margin = parseFloat(document.getElementById('prodMargin').value) || 100;
  const sellPrice = cost * (1 + (margin / 100));

  if (!document.getElementById('prodSellPrice').value || document.getElementById('prodSellPrice').value == '0') {
    document.getElementById('prodSellPrice').value = sellPrice.toFixed(2);
  }

  // Preço iFood com taxa contratual de 26,2%
  const ifood = sellPrice / 0.738;
  document.getElementById('prodIfoodPrice').value = ifood.toFixed(2);
}

async function saveProduct(e) {
  e.preventDefault();
  const id = document.getElementById('prodId').value;
  const payload = {
    name: document.getElementById('prodName').value.trim(),
    category: document.getElementById('prodCategory').value.trim() || 'Geral',
    sellPrice: parseFloat(document.getElementById('prodSellPrice').value) || 0,
    ifoodPrice: parseFloat(document.getElementById('prodIfoodPrice').value) || 0,
    stock: parseFloat(document.getElementById('prodStock').value) || 0,
    minStock: parseFloat(document.getElementById('prodMinStock').value) || 0,
    unit: document.getElementById('prodUnit').value.trim() || 'unidade',
  };

  try {
    if (id) {
      await supabaseClient.from('products').update(payload).eq('id', id);
      showToast('Produto atualizado com sucesso!', 'success');
    } else {
      await supabaseClient.from('products').insert([payload]);
      showToast('Produto cadastrado com sucesso!', 'success');
    }
    closeModal('productModal');
    await loadAllData();
  } catch (error) {
    console.error('Erro ao salvar produto:', error);
    showToast('Erro ao salvar produto.', 'error');
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
