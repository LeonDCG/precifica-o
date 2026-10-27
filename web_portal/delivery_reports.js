// ==========================================================================
// MÓDULO DE RELATÓRIOS & CONCILIAÇÃO FINANCEIRA DELIVERY (99FOOD & IFOOD)
// Concatenação Inteligente, Separação por Mês, Parser de Excel e Métricas
// ==========================================================================

// CONSTANTE DE DESEMPENHO OFICIAL IFOOD (Extração 01/10/2026 a 23/10/2026)
const DEFAULT_IFOOD_PERFORMANCE = {
  period: "01/10/2026 - 25/10/2026",
  storeId: "4002937",
  storeName: "Doce & Ponto - Confeitaria Artesanal",
  city: "MONGAGUA - SP",
  service: "App iFood",
  logistics: "Entrega parceira",
  totalOrders: 34,
  totalGross: 1900.13,
  deliveryFeePaidByCustomer: 330.66,
  ticketMedio: 55.89,
  newCustomers: 27,
  newCustomersPct: 79.4,
  paymentMethods: [
    { method: "PIX", orders: 21, pct: 61.8 },
    { method: "Crédito", orders: 5, pct: 14.7 },
    { method: "Carteira digital", orders: 5, pct: 14.7 },
    { method: "Débito", orders: 2, pct: 5.9 },
    { method: "App do Banco", orders: 1, pct: 2.9 }
  ],
  topDays: [
    { day: "Domingo", orders: 17, pct: 50.0 },
    { day: "Quinta", orders: 6, pct: 17.6 },
    { day: "Sábado", orders: 5, pct: 14.7 },
    { day: "Sexta", orders: 4, pct: 11.8 },
    { day: "Terça", orders: 2, pct: 5.9 }
  ],
  peakHours: [
    { hour: "20h - 22h", orders: 11, pct: 32.4, desc: "Pico Máximo Noturno (4 semana / 7 fim de semana)" },
    { hour: "22h - 24h", orders: 8, pct: 23.5, desc: "Alta Demanda Madrugada (2 semana / 6 fim de semana)" },
    { hour: "16h - 18h", orders: 6, pct: 17.6, desc: "Chá / Lanche da Tarde" },
    { hour: "14h - 16h", orders: 5, pct: 14.7, desc: "Pós-Almoço / Lanche da Tarde" },
    { hour: "18h - 20h", orders: 2, pct: 5.9, desc: "Happy Hour / Início da Noite" },
    { hour: "12h - 14h", orders: 2, pct: 5.9, desc: "Almoço" }
  ]
};

const DEFAULT_DELIVERY_ORDERS = [
  {
    "id": "ifood_8751",
    "channel": "iFood",
    "order_number": "8751",
    "full_order_id": "d9cda218-f55c-40bd-8bbc-658a532e2554",
    "date": "2026-10-25 17:59:48",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 68.97,
    "sales_revenue": 60.69,
    "discounts": 11.99,
    "commission": 18.07,
    "net_value": 38.91,
    "pay_method": "Pgto via APP - Crédito (Visa)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_2451",
    "channel": "iFood",
    "order_number": "2451",
    "full_order_id": "899156c6-2eb9-45fd-836a-dfa7a0709e8f",
    "date": "2026-10-25 17:37:33",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 68.97,
    "sales_revenue": 60.69,
    "discounts": 13.99,
    "commission": 18.07,
    "net_value": 36.91,
    "pay_method": "Pgto via APP  - Débito (Mastercard Maestro)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_9518",
    "channel": "iFood",
    "order_number": "9518",
    "full_order_id": "f8e12f08-ff6e-4150-b109-37c26ebdfd2e",
    "date": "2026-10-25 13:23:55",
    "shift": "ALMOÇO",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 22.99,
    "sales_revenue": 38.97,
    "discounts": 0.0,
    "commission": 6.03,
    "net_value": 16.96,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_9459",
    "channel": "iFood",
    "order_number": "9459",
    "full_order_id": "813bca54-9bc3-4892-9160-6c616db2a983",
    "date": "2026-10-25 13:19:10",
    "shift": "ALMOÇO",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 22.99,
    "sales_revenue": 38.97,
    "discounts": 0.0,
    "commission": 6.03,
    "net_value": 16.96,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_7686",
    "channel": "iFood",
    "order_number": "7686",
    "full_order_id": "f5f28276-1812-4f47-8118-6a819dd975e5",
    "date": "2026-10-24 22:05:36",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 45.98,
    "sales_revenue": 35.13,
    "discounts": 6.99,
    "commission": 12.05,
    "net_value": 26.94,
    "pay_method": "Pgto via APP - Crédito (Visa)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764696141073550607",
    "channel": "99Food",
    "order_number": "550607",
    "full_order_id": "5764696141073550607",
    "date": "2026-10-24 19:09:54",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 50.98,
    "sales_revenue": 43.98,
    "discounts": 7.0,
    "commission": 12.67,
    "net_value": 31.31,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_9771",
    "channel": "iFood",
    "order_number": "9771",
    "full_order_id": "9c5f8761-a0f6-4acf-ae6a-f9ff79314c26",
    "date": "2026-10-22 23:40:48",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 45.98,
    "sales_revenue": 47.13,
    "discounts": 7.99,
    "commission": 12.05,
    "net_value": 25.94,
    "pay_method": "Pgto via APP - Carteira Digital (Visa)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764694370884324291",
    "channel": "99Food",
    "order_number": "324291",
    "full_order_id": "5764694370884324291",
    "date": "2026-10-22 23:26:25",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 3,
    "gross_value": 74.97,
    "sales_revenue": 64.97,
    "discounts": 10.0,
    "commission": 18.57,
    "net_value": 46.4,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_5102",
    "channel": "iFood",
    "order_number": "5102",
    "full_order_id": "08f19a0a-7ee1-479f-a520-a78f0568d21b",
    "date": "2026-10-22 21:06:21",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 22.99,
    "sales_revenue": 31.97,
    "discounts": 0.0,
    "commission": 6.03,
    "net_value": 16.96,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764694257424206388",
    "channel": "99Food",
    "order_number": "206388",
    "full_order_id": "5764694257424206388",
    "date": "2026-10-22 21:04:43",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 51.98,
    "sales_revenue": 44.99,
    "discounts": 6.99,
    "commission": 10.79,
    "net_value": 34.2,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_9918",
    "channel": "iFood",
    "order_number": "9918",
    "full_order_id": "174bed21-5da4-485d-823e-11e273ef8cb7",
    "date": "2026-10-22 20:43:19",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 55.97,
    "sales_revenue": 47.37,
    "discounts": 8.99,
    "commission": 14.66,
    "net_value": 32.32,
    "pay_method": "Pgto via APP - Crédito (Mastercard)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_4367",
    "channel": "iFood",
    "order_number": "4367",
    "full_order_id": "e25a5116-92e7-4dd4-831b-caea18feb803",
    "date": "2026-10-22 17:50:50",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 22.99,
    "sales_revenue": 32.97,
    "discounts": 0.0,
    "commission": 6.03,
    "net_value": 16.96,
    "pay_method": "Pgto via APP - Carteira Digital (Mastercard Maestro)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_2155",
    "channel": "iFood",
    "order_number": "2155",
    "full_order_id": "ee737de7-2b1d-474b-8c86-e30c8d7ffa99",
    "date": "2026-10-22 16:50:23",
    "shift": "CAFÉ DA TARDE",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 104.95,
    "sales_revenue": 107.57,
    "discounts": 13.99,
    "commission": 27.5,
    "net_value": 63.46,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_1510",
    "channel": "iFood",
    "order_number": "1510",
    "full_order_id": "6932bc60-e1dd-4c87-bc95-33812256248d",
    "date": "2026-10-22 14:04:54",
    "shift": "ALMOÇO",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 23.99,
    "sales_revenue": 32.97,
    "discounts": 0.0,
    "commission": 6.29,
    "net_value": 17.7,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764691890326802023",
    "channel": "99Food",
    "order_number": "802023",
    "full_order_id": "5764691890326802023",
    "date": "2026-10-18 22:38:54",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 51.98,
    "sales_revenue": 44.98,
    "discounts": 7.0,
    "commission": 12.79,
    "net_value": 32.19,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_9248",
    "channel": "iFood",
    "order_number": "9248",
    "full_order_id": "2709cebe-6070-43f5-b88a-6309b3bbd3ac",
    "date": "2026-10-18 22:21:32",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 22.99,
    "sales_revenue": 26.22,
    "discounts": 0.0,
    "commission": 6.03,
    "net_value": 16.96,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_6854",
    "channel": "iFood",
    "order_number": "6854",
    "full_order_id": "d539fc70-4cc6-41e3-89f2-9c1ef40b6db0",
    "date": "2026-10-18 21:08:22",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 45.98,
    "sales_revenue": 47.13,
    "discounts": 8.99,
    "commission": 12.05,
    "net_value": 24.94,
    "pay_method": "Pgto via APP - Carteira Digital (Mastercard)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_6905",
    "channel": "iFood",
    "order_number": "6905",
    "full_order_id": "a1e0f4b1-86b5-474c-97ba-3cd29f1d53f2",
    "date": "2026-10-18 20:20:17",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 45.98,
    "sales_revenue": 37.13,
    "discounts": 9.99,
    "commission": 12.05,
    "net_value": 23.94,
    "pay_method": "Pgto via APP - Carteira Digital (Mastercard Maestro)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764691698089265642",
    "channel": "99Food",
    "order_number": "265642",
    "full_order_id": "5764691698089265642",
    "date": "2026-10-18 17:44:43",
    "shift": "Tarde",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 49.98,
    "sales_revenue": 43.98,
    "discounts": 6.0,
    "commission": 13.54,
    "net_value": 30.44,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_6364",
    "channel": "iFood",
    "order_number": "6364",
    "full_order_id": "430b2f27-fce6-4d4f-a824-5b71f5442a2f",
    "date": "2026-10-18 14:42:02",
    "shift": "ALMOÇO",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 22.99,
    "sales_revenue": 25.97,
    "discounts": 0.0,
    "commission": 6.03,
    "net_value": 16.96,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_6284",
    "channel": "iFood",
    "order_number": "6284",
    "full_order_id": "9e489e9d-6b1e-49a0-b300-23e7a5d74168",
    "date": "2026-10-16 21:00:58",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 92.96,
    "sales_revenue": 85.28,
    "discounts": 0.0,
    "commission": 24.35,
    "net_value": 68.61,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764690913649559106",
    "channel": "99Food",
    "order_number": "559106",
    "full_order_id": "5764690913649559106",
    "date": "2026-10-12 21:26:34",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 49.98,
    "sales_revenue": 43.98,
    "discounts": 6.0,
    "commission": 13.54,
    "net_value": 30.44,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "99_5764690999838311292",
    "channel": "99Food",
    "order_number": "311292",
    "full_order_id": "5764690999838311292",
    "date": "2026-10-12 18:12:22",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 49.98,
    "sales_revenue": 43.98,
    "discounts": 6.0,
    "commission": 13.54,
    "net_value": 30.44,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_1226",
    "channel": "iFood",
    "order_number": "1226",
    "full_order_id": "e3e84a46-98bc-40cc-aeed-459e69942bfa",
    "date": "2026-10-11 22:03:56",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 45.98,
    "sales_revenue": 37.13,
    "discounts": 9.99,
    "commission": 12.05,
    "net_value": 23.94,
    "pay_method": "Pgto via APP - App do Banco",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_2294",
    "channel": "iFood",
    "order_number": "2294",
    "full_order_id": "e68038d2-3e45-4475-84dd-713b1e02cffc",
    "date": "2026-10-11 20:19:59",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 45.98,
    "sales_revenue": 37.13,
    "discounts": 9.99,
    "commission": 12.05,
    "net_value": 23.94,
    "pay_method": "Pgto via APP - Crédito (Mastercard)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764690582567979895",
    "channel": "99Food",
    "order_number": "979895",
    "full_order_id": "5764690582567979895",
    "date": "2026-10-11 19:27:20",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 6,
    "gross_value": 80.95,
    "sales_revenue": 76.96,
    "discounts": 3.99,
    "commission": 16.3,
    "net_value": 60.66,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_7336",
    "channel": "iFood",
    "order_number": "7336",
    "full_order_id": "eb59014c-38a2-4efa-b511-c2ff513ef488",
    "date": "2026-10-11 18:32:20",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 92.96,
    "sales_revenue": 95.28,
    "discounts": 11.99,
    "commission": 24.35,
    "net_value": 56.62,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_4996",
    "channel": "iFood",
    "order_number": "4996",
    "full_order_id": "e6a954b3-5adc-4437-9325-05cf743ead53",
    "date": "2026-10-11 17:58:27",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 93.96,
    "sales_revenue": 86.31,
    "discounts": 8.99,
    "commission": 24.62,
    "net_value": 60.35,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764690771680758356",
    "channel": "99Food",
    "order_number": "758356",
    "full_order_id": "5764690771680758356",
    "date": "2026-10-11 17:57:11",
    "shift": "Tarde",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 24.99,
    "sales_revenue": 22.99,
    "discounts": 2.0,
    "commission": 10.52,
    "net_value": 12.47,
    "pay_method": "Pagamento em dinheiro",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "99_5764690606441957914",
    "channel": "99Food",
    "order_number": "957914",
    "full_order_id": "5764690606441957914",
    "date": "2026-10-11 17:43:52",
    "shift": "Tarde",
    "status": "CANCELADO",
    "items_count": 1,
    "gross_value": 24.99,
    "sales_revenue": 0.0,
    "discounts": 0.0,
    "commission": 0.0,
    "net_value": 0.0,
    "pay_method": "Pagamento em dinheiro",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "99_5764690711706405381",
    "channel": "99Food",
    "order_number": "405381",
    "full_order_id": "5764690711706405381",
    "date": "2026-10-11 17:39:04",
    "shift": "Tarde",
    "status": "CANCELADO",
    "items_count": 1,
    "gross_value": 24.99,
    "sales_revenue": 0.0,
    "discounts": 0.0,
    "commission": 0.0,
    "net_value": 0.0,
    "pay_method": "Pagamento em dinheiro",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_6517",
    "channel": "iFood",
    "order_number": "6517",
    "full_order_id": "c455845c-5bea-402f-967e-c3f2b6a12ecb",
    "date": "2026-10-11 15:38:36",
    "shift": "CAFÉ DA TARDE",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 115.95,
    "sales_revenue": 118.85,
    "discounts": 0.0,
    "commission": 30.38,
    "net_value": 85.57,
    "pay_method": "Pgto via APP  - Débito (Elo Debit)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764690668727371096",
    "channel": "99Food",
    "order_number": "371096",
    "full_order_id": "5764690668727371096",
    "date": "2026-10-10 22:58:21",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 24.99,
    "sales_revenue": 22.99,
    "discounts": 2.0,
    "commission": 6.52,
    "net_value": 16.47,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_1320",
    "channel": "iFood",
    "order_number": "1320",
    "full_order_id": "5f5e1ffc-fff2-4d37-a9b5-b76df24a4fc8",
    "date": "2026-10-10 20:58:03",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 22.99,
    "sales_revenue": 28.22,
    "discounts": 0.0,
    "commission": 6.03,
    "net_value": 16.96,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764690567845970789",
    "channel": "99Food",
    "order_number": "970789",
    "full_order_id": "5764690567845970789",
    "date": "2026-10-10 20:34:51",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 4,
    "gross_value": 99.96,
    "sales_revenue": 89.96,
    "discounts": 10.0,
    "commission": 25.59,
    "net_value": 64.37,
    "pay_method": "Pagamento em dinheiro",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "99_5764690731117642518",
    "channel": "99Food",
    "order_number": "642518",
    "full_order_id": "5764690731117642518",
    "date": "2026-10-10 20:21:11",
    "shift": "Noite",
    "status": "CANCELADO",
    "items_count": 4,
    "gross_value": 99.96,
    "sales_revenue": 0.0,
    "discounts": 0.0,
    "commission": 0.0,
    "net_value": 0.0,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_2350",
    "channel": "iFood",
    "order_number": "2350",
    "full_order_id": "7f4c5037-8cfa-43d2-bb7c-954400567afd",
    "date": "2026-10-09 23:12:17",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 45.98,
    "sales_revenue": 37.13,
    "discounts": 9.99,
    "commission": 12.05,
    "net_value": 23.94,
    "pay_method": "Pgto via APP - Crédito (Mastercard)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764690107772764973",
    "channel": "99Food",
    "order_number": "764973",
    "full_order_id": "5764690107772764973",
    "date": "2026-10-06 21:44:37",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 49.98,
    "sales_revenue": 43.98,
    "discounts": 6.0,
    "commission": 11.54,
    "net_value": 32.44,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_9209",
    "channel": "iFood",
    "order_number": "9209",
    "full_order_id": "9e58d4e4-f9c3-4a2d-b91d-1255e5d0854e",
    "date": "2026-10-06 20:59:24",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 22.99,
    "sales_revenue": 24.22,
    "discounts": 0.0,
    "commission": 6.03,
    "net_value": 16.96,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_3292",
    "channel": "iFood",
    "order_number": "3292",
    "full_order_id": "e778d922-47f5-4d0a-b9bb-441dff04b69f",
    "date": "2026-10-06 20:57:06",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 101.95,
    "sales_revenue": 114.49,
    "discounts": 0.0,
    "commission": 26.71,
    "net_value": 75.24,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_5327",
    "channel": "iFood",
    "order_number": "5327",
    "full_order_id": "0d08f37f-7b66-4d31-a1e4-ece9fb7e7f50",
    "date": "2026-10-04 18:13:41",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 115.95,
    "sales_revenue": 117.11,
    "discounts": 10.99,
    "commission": 30.38,
    "net_value": 74.58,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_7557",
    "channel": "iFood",
    "order_number": "7557",
    "full_order_id": "18671572-c474-4132-9814-df858abcb989",
    "date": "2026-10-04 17:20:37",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 68.97,
    "sales_revenue": 70.35,
    "discounts": 6.99,
    "commission": 18.07,
    "net_value": 43.91,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_7393",
    "channel": "iFood",
    "order_number": "7393",
    "full_order_id": "66d3934e-330b-419a-8a3d-b57251d25ccc",
    "date": "2026-10-04 15:50:42",
    "shift": "CAFÉ DA TARDE",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 23.99,
    "sales_revenue": 29.97,
    "discounts": 0.0,
    "commission": 6.29,
    "net_value": 17.7,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_8597",
    "channel": "iFood",
    "order_number": "8597",
    "full_order_id": "78236fff-7c60-4cd4-97a5-a1347b24c03c",
    "date": "2026-10-04 15:15:45",
    "shift": "CAFÉ DA TARDE",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 102.95,
    "sales_revenue": 105.01,
    "discounts": 9.99,
    "commission": 26.97,
    "net_value": 65.99,
    "pay_method": "Pgto via APP - Carteira Digital (Visa Electron)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764689553776512221",
    "channel": "99Food",
    "order_number": "512221",
    "full_order_id": "5764689553776512221",
    "date": "2026-10-03 23:28:06",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 23.99,
    "sales_revenue": 21.99,
    "discounts": 2.0,
    "commission": 8.4,
    "net_value": 13.59,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "99_5764689498701106322",
    "channel": "99Food",
    "order_number": "106322",
    "full_order_id": "5764689498701106322",
    "date": "2026-10-03 23:05:19",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 48.98,
    "sales_revenue": 42.98,
    "discounts": 6.0,
    "commission": 11.42,
    "net_value": 31.56,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_6181",
    "channel": "iFood",
    "order_number": "6181",
    "full_order_id": "a08d3483-b675-4ca6-866e-510304babdf7",
    "date": "2026-10-03 22:09:25",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 85.96,
    "sales_revenue": 77.68,
    "discounts": 8.99,
    "commission": 22.52,
    "net_value": 54.45,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_7115",
    "channel": "iFood",
    "order_number": "7115",
    "full_order_id": "eb6a3e1e-df9d-4776-a304-b2780dfb7f8e",
    "date": "2026-10-03 22:03:35",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 20.99,
    "sales_revenue": 27.76,
    "discounts": 0.0,
    "commission": 5.5,
    "net_value": 15.49,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764689447987776442",
    "channel": "99Food",
    "order_number": "776442",
    "full_order_id": "5764689447987776442",
    "date": "2026-10-03 22:02:36",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 47.98,
    "sales_revenue": 41.98,
    "discounts": 6.0,
    "commission": 13.31,
    "net_value": 28.67,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_9651",
    "channel": "iFood",
    "order_number": "9651",
    "full_order_id": "f8cd91d9-6893-4357-bbdc-f5e24506be8d",
    "date": "2026-10-03 21:58:03",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 45.98,
    "sales_revenue": 36.97,
    "discounts": 9.99,
    "commission": 12.05,
    "net_value": 23.94,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764689596239644703",
    "channel": "99Food",
    "order_number": "644703",
    "full_order_id": "5764689596239644703",
    "date": "2026-10-03 18:25:12",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 31.98,
    "sales_revenue": 28.98,
    "discounts": 3.0,
    "commission": 9.37,
    "net_value": 19.61,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_4913",
    "channel": "iFood",
    "order_number": "4913",
    "full_order_id": "e629ad1e-6944-49e7-8122-2b023aaa9673",
    "date": "2026-10-02 23:06:24",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 62.97,
    "sales_revenue": 63.6,
    "discounts": 8.99,
    "commission": 16.5,
    "net_value": 37.48,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "99_5764689657640059297",
    "channel": "99Food",
    "order_number": "059297",
    "full_order_id": "5764689657640059297",
    "date": "2026-10-02 21:34:59",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 3,
    "gross_value": 71.97,
    "sales_revenue": 62.98,
    "discounts": 8.99,
    "commission": 16.21,
    "net_value": 46.77,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "99_5764689475670180185",
    "channel": "99Food",
    "order_number": "180185",
    "full_order_id": "5764689475670180185",
    "date": "2026-10-02 21:25:23",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 47.98,
    "sales_revenue": 41.98,
    "discounts": 6.0,
    "commission": 11.31,
    "net_value": 30.67,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "99_5764689459891208443",
    "channel": "99Food",
    "order_number": "208443",
    "full_order_id": "5764689459891208443",
    "date": "2026-10-02 21:09:12",
    "shift": "Noite",
    "status": "CONCLUIDO",
    "items_count": 6,
    "gross_value": 221.91,
    "sales_revenue": 217.92,
    "discounts": 3.99,
    "commission": 40.35,
    "net_value": 177.57,
    "pay_method": "Pagamento online",
    "logistics": "Entrega da plataforma"
  },
  {
    "id": "ifood_8716",
    "channel": "iFood",
    "order_number": "8716",
    "full_order_id": "d8151b2f-9228-47be-8b34-382300031f03",
    "date": "2026-10-02 20:47:50",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 45.96,
    "sales_revenue": 36.95,
    "discounts": 9.99,
    "commission": 12.04,
    "net_value": 23.93,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_6862",
    "channel": "iFood",
    "order_number": "6862",
    "full_order_id": "9a2816b1-781b-4def-b789-9aa67749df7e",
    "date": "2026-09-30 22:44:50",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 62.97,
    "sales_revenue": 65.22,
    "discounts": 0.0,
    "commission": 16.5,
    "net_value": 46.47,
    "pay_method": "Pgto via APP - App do Banco",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_0218",
    "channel": "iFood",
    "order_number": "0218",
    "full_order_id": "78ad17e8-0eaf-4baa-a5b1-b356abd2064f",
    "date": "2026-09-29 22:23:37",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 20.99,
    "sales_revenue": 30.76,
    "discounts": 0.0,
    "commission": 5.5,
    "net_value": 15.49,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_7845",
    "channel": "iFood",
    "order_number": "7845",
    "full_order_id": "5acccb94-f480-4df8-b8af-96d94eea7aa2",
    "date": "2026-09-26 20:24:29",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 62.97,
    "sales_revenue": 65.07,
    "discounts": 8.99,
    "commission": 16.5,
    "net_value": 37.48,
    "pay_method": "Outros vales",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_0868",
    "channel": "iFood",
    "order_number": "0868",
    "full_order_id": "70ac2a00-1fff-4e42-af4a-58916e51d171",
    "date": "2026-09-25 19:05:45",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 20.99,
    "sales_revenue": 22.72,
    "discounts": 0.0,
    "commission": 5.5,
    "net_value": 15.49,
    "pay_method": "Pgto via APP - Crédito (Mastercard)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_2257",
    "channel": "iFood",
    "order_number": "2257",
    "full_order_id": "ed479361-b022-40b5-afda-a799a3bc2cd5",
    "date": "2026-09-23 22:41:06",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 49.97,
    "sales_revenue": 50.97,
    "discounts": 8.99,
    "commission": 13.09,
    "net_value": 27.89,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_6463",
    "channel": "iFood",
    "order_number": "6463",
    "full_order_id": "37fe4245-dd0b-47dd-8ce3-13c324913b1e",
    "date": "2026-09-19 21:43:10",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 22.99,
    "sales_revenue": 25.07,
    "discounts": 0.0,
    "commission": 6.03,
    "net_value": 16.96,
    "pay_method": "Pgto via APP - Carteira Digital (Mastercard)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_8209",
    "channel": "iFood",
    "order_number": "8209",
    "full_order_id": "cec2e5bc-ad26-469c-9c35-c57ffda0f2d3",
    "date": "2026-09-13 17:47:16",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 20.99,
    "sales_revenue": 22.67,
    "discounts": 0.0,
    "commission": 5.5,
    "net_value": 15.49,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_5398",
    "channel": "iFood",
    "order_number": "5398",
    "full_order_id": "04380d18-5c62-4ae7-b236-e4565ef26d4e",
    "date": "2026-09-13 14:56:38",
    "shift": "ALMOÇO",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 41.98,
    "sales_revenue": 39.96,
    "discounts": 0.0,
    "commission": 11.0,
    "net_value": 30.98,
    "pay_method": "Pgto via APP - Carteira Digital (Mastercard)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_2718",
    "channel": "iFood",
    "order_number": "2718",
    "full_order_id": "1246aeb8-402a-4bfc-ae23-b5bbedf0669e",
    "date": "2026-09-12 22:34:01",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 20.99,
    "sales_revenue": 22.72,
    "discounts": 0.0,
    "commission": 5.5,
    "net_value": 15.49,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_9922",
    "channel": "iFood",
    "order_number": "9922",
    "full_order_id": "ba8c34ae-5527-4461-bfed-bb3a40525987",
    "date": "2026-09-11 22:48:29",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 3,
    "gross_value": 125.94,
    "sales_revenue": 137.42,
    "discounts": 0.0,
    "commission": 33.0,
    "net_value": 92.94,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_5042",
    "channel": "iFood",
    "order_number": "5042",
    "full_order_id": "c932bb3e-7ea0-41c3-b3b5-ed89b2e53bd3",
    "date": "2026-09-10 18:39:07",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 20.99,
    "sales_revenue": 33.72,
    "discounts": 0.0,
    "commission": 5.5,
    "net_value": 15.49,
    "pay_method": "Pgto via APP - Carteira Digital (Mastercard Maestro)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_1464",
    "channel": "iFood",
    "order_number": "1464",
    "full_order_id": "c129df7a-b4ee-4f85-9ac7-75eccbe59f65",
    "date": "2026-09-09 22:25:42",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 3,
    "gross_value": 62.97,
    "sales_revenue": 56.22,
    "discounts": 0.0,
    "commission": 16.5,
    "net_value": 46.47,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_6541",
    "channel": "iFood",
    "order_number": "6541",
    "full_order_id": "32f5c001-1c74-4e46-823c-9c8789a1d7b6",
    "date": "2026-09-08 22:40:06",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 20.99,
    "sales_revenue": 21.72,
    "discounts": 0.0,
    "commission": 5.5,
    "net_value": 15.49,
    "pay_method": "Pgto via APP - Carteira Digital (Movile Pay)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_8081",
    "channel": "iFood",
    "order_number": "8081",
    "full_order_id": "bf4b8898-9c57-4546-a28f-50a28094e8b9",
    "date": "2026-09-06 19:51:43",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 3,
    "gross_value": 64.97,
    "sales_revenue": 56.27,
    "discounts": 0.0,
    "commission": 17.02,
    "net_value": 47.95,
    "pay_method": "Pgto via APP - Carteira Digital (Mastercard Maestro)",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_6398",
    "channel": "iFood",
    "order_number": "6398",
    "full_order_id": "58121f70-0955-4d1d-b754-dbbdd760ddc0",
    "date": "2026-09-06 17:52:15",
    "shift": "JANTAR",
    "status": "CONCLUIDO",
    "items_count": 2,
    "gross_value": 41.98,
    "sales_revenue": 32.97,
    "discounts": 0.0,
    "commission": 11.0,
    "net_value": 30.98,
    "pay_method": "Pgto via APP - App do Banco",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_5902",
    "channel": "iFood",
    "order_number": "5902",
    "full_order_id": "417e3157-e07d-4000-b55d-03bd7b01c91e",
    "date": "2026-09-06 14:26:55",
    "shift": "ALMOÇO",
    "status": "CONCLUIDO",
    "items_count": 1,
    "gross_value": 20.99,
    "sales_revenue": 29.97,
    "discounts": 0.0,
    "commission": 5.5,
    "net_value": 15.49,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  },
  {
    "id": "ifood_7619",
    "channel": "iFood",
    "order_number": "7619",
    "full_order_id": "c74fd198-6639-4b62-947a-6122bb890e57",
    "date": "2026-09-05 18:59:00",
    "shift": "JANTAR",
    "status": "CANCELADO",
    "items_count": 2,
    "gross_value": 41.98,
    "sales_revenue": 38.96,
    "discounts": 0.0,
    "commission": 0.0,
    "net_value": 0.0,
    "pay_method": "Pgto via APP - PIX",
    "logistics": "ENTREGA PARCEIRA IFOOD"
  }
];

let deliveryOrdersList = [];
let currentDeliveryFilter = 'ALL'; // 'ALL', 'iFood', '99Food'
let currentDeliveryMonth = 'AUTO'; // 'AUTO' (mês mais recente), 'ALL' (todos) ou 'YYYY-MM'
let reportChannelChartInstance = null;
let reportShareChartInstance = null;

const MONTH_NAMES_PT = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
];

// FORMATAÇÃO DE MÊS 'YYYY-MM' PARA 'Mês de AAAA'
function formatMonthName(ym) {
  if (!ym || ym === 'ALL') return 'Todos os Meses';
  const parts = ym.split('-');
  if (parts.length !== 2) return ym;
  const year = parts[0];
  const monthIdx = parseInt(parts[1], 10) - 1;
  const monthName = MONTH_NAMES_PT[monthIdx] || parts[1];
  return `${monthName} de ${year}`;
}

function formatMonthShort(ym) {
  if (!ym || ym === 'ALL') return 'Todos';
  const parts = ym.split('-');
  if (parts.length !== 2) return ym;
  const year = parts[0];
  const monthIdx = parseInt(parts[1], 10) - 1;
  const monthName = MONTH_NAMES_PT[monthIdx] || parts[1];
  return `${monthName.slice(0, 3)}/${year}`;
}

// OBTÉM LISTA DE MESES DISPONÍVEIS A PARTIR DAS DATAS DOS PEDIDOS
function getAvailableMonths() {
  const monthMap = {};
  deliveryOrdersList.forEach(o => {
    if (!o.date) return;
    const ym = o.date.slice(0, 7); // 'YYYY-MM'
    if (ym && ym.length === 7) {
      if (!monthMap[ym]) {
        monthMap[ym] = { ym, total: 0, ifood: 0, food99: 0 };
      }
      monthMap[ym].total++;
      if (o.channel === 'iFood') monthMap[ym].ifood++;
      else if (o.channel === '99Food') monthMap[ym].food99++;
    }
  });

  return Object.values(monthMap).sort((a, b) => b.ym.localeCompare(a.ym));
}

// VERSÃO DO CACHE DE DADOS DE DELIVERY (Garante sincronização imediata em todos os navegadores)
const DELIVERY_CACHE_VERSION = '2026-10-26_v6_exact_math';

// INICIALIZAÇÃO DO MÓDULO DE RELATÓRIOS
function initDeliveryReports() {
  try {
    const currentVer = localStorage.getItem('delivery_cache_version');
    const cached = localStorage.getItem('delivery_reports_cache');

    if (currentVer !== DELIVERY_CACHE_VERSION || !cached) {
      // Força o carregamento do dataset oficial atualizado (47 pedidos de Outubro)
      deliveryOrdersList = JSON.parse(JSON.stringify(DEFAULT_DELIVERY_ORDERS));
      localStorage.setItem('delivery_reports_cache', JSON.stringify(deliveryOrdersList));
      localStorage.setItem('delivery_cache_version', DELIVERY_CACHE_VERSION);
      localStorage.setItem('ifood_performance_meta', JSON.stringify(DEFAULT_IFOOD_PERFORMANCE));
    } else {
      const parsed = JSON.parse(cached);
      const dict = {};
      DEFAULT_DELIVERY_ORDERS.forEach(o => { dict[o.full_order_id || o.id] = o; });
      if (Array.isArray(parsed)) {
        parsed.forEach(o => { dict[o.full_order_id || o.id] = o; });
      }
      deliveryOrdersList = Object.values(dict).sort((a, b) => (b.date || '').localeCompare(a.date || ''));
      localStorage.setItem('delivery_reports_cache', JSON.stringify(deliveryOrdersList));
    }
  } catch (e) {
    console.warn('Erro ao carregar cache de relatórios de delivery:', e);
    deliveryOrdersList = JSON.parse(JSON.stringify(DEFAULT_DELIVERY_ORDERS));
  }

  // Define mês padrão (o mais recente disponível)
  if (currentDeliveryMonth === 'AUTO') {
    const avail = getAvailableMonths();
    currentDeliveryMonth = avail.length > 0 ? avail[0].ym : 'ALL';
  }

  updateReportsBadges();
  setupExcelDropzone();

  // Força renderização imediata dos painéis
  try {
    if (typeof renderReportsView === 'function') renderReportsView();
  } catch (err) {
    console.warn('Erro ao renderizar view de relatórios no init:', err);
  }

  try {
    if (typeof renderDashboard === 'function') renderDashboard();
  } catch (err) {
    console.warn('Erro ao renderizar dashboard no init:', err);
  }
}

function updateReportsBadges() {
  const badgeEl = document.getElementById('reportsOrdersBadge');
  const count99El = document.getElementById('count99Badge');
  const countIfoodEl = document.getElementById('countIfoodBadge');

  // Filtra de acordo com o mês selecionado
  const monthOrders = getOrdersForActiveMonth();
  const count99 = monthOrders.filter(o => o.channel === '99Food').length;
  const countIfood = monthOrders.filter(o => o.channel === 'iFood').length;

  if (badgeEl) {
    badgeEl.textContent = monthOrders.length;
    badgeEl.style.display = monthOrders.length > 0 ? 'inline-block' : 'none';
  }
  if (count99El) count99El.textContent = count99;
  if (countIfoodEl) countIfoodEl.textContent = countIfood;
}

// RETORNA OS PEDIDOS FILTRADOS PELO MÊS ATUAL
function getOrdersForActiveMonth() {
  if (!currentDeliveryMonth || currentDeliveryMonth === 'ALL') {
    return deliveryOrdersList;
  }
  return deliveryOrdersList.filter(o => (o.date || '').slice(0, 7) === currentDeliveryMonth);
}

// NAVEGAÇÃO E CONTROLE POR MÊS
function setDeliveryMonthFilter(monthVal) {
  currentDeliveryMonth = monthVal;
  renderReportsView();
  if (typeof renderDashboard === 'function') renderDashboard();
}

function navigateDeliveryMonth(step) {
  const months = getAvailableMonths();
  if (months.length === 0) return;

  if (currentDeliveryMonth === 'ALL') {
    currentDeliveryMonth = months[0].ym;
  } else {
    const currentIdx = months.findIndex(m => m.ym === currentDeliveryMonth);
    if (currentIdx === -1) {
      currentDeliveryMonth = months[0].ym;
    } else {
      // step = -1 vai para mês anterior (mais antigo = index maior no sort decrescente)
      // step = 1 vai para próximo mês (mais novo = index menor)
      const targetIdx = currentIdx - step;
      if (targetIdx >= 0 && targetIdx < months.length) {
        currentDeliveryMonth = months[targetIdx].ym;
      } else if (targetIdx >= months.length) {
        showToast('Você já está no mês mais antigo disponível.', 'info', 1600);
        return;
      } else if (targetIdx < 0) {
        showToast('Você já está no mês mais recente disponível.', 'info', 1600);
        return;
      }
    }
  }

  renderReportsView();
  if (typeof renderDashboard === 'function') renderDashboard();
}

// RENDERIZAÇÃO DOS CONTROLES DO SELETOR DE MÊS
function renderMonthControls() {
  const select = document.getElementById('reportMonthSelect');
  const chipsContainer = document.getElementById('reportMonthChips');
  const descEl = document.getElementById('currentMonthLabelDesc');
  const months = getAvailableMonths();

  if (!select) return;

  // Monta opções do select
  let selectHtml = `<option value="ALL" ${currentDeliveryMonth === 'ALL' ? 'selected' : ''}>🌐 Todos os Meses Acumulados (${deliveryOrdersList.length} pedidos)</option>`;
  months.forEach(m => {
    const isSelected = m.ym === currentDeliveryMonth ? 'selected' : '';
    selectHtml += `<option value="${m.ym}" ${isSelected}>📅 ${formatMonthName(m.ym)} (${m.total} pedidos)</option>`;
  });
  select.innerHTML = selectHtml;

  // Descrição do mês ativo
  if (descEl) {
    if (currentDeliveryMonth === 'ALL') {
      descEl.textContent = `Visualizando dados acumulados de todos os períodos (${deliveryOrdersList.length} pedidos)`;
    } else {
      descEl.textContent = `Apuração ativa de ${formatMonthName(currentDeliveryMonth)}`;
    }
  }

  // Chips de acesso rápido aos meses
  if (chipsContainer) {
    let chipsHtml = `
      <button class="month-chip ${currentDeliveryMonth === 'ALL' ? 'active' : ''}" onclick="setDeliveryMonthFilter('ALL')">
        🌐 Todos (${deliveryOrdersList.length})
      </button>
    `;
    months.forEach(m => {
      const activeClass = m.ym === currentDeliveryMonth ? 'active' : '';
      chipsHtml += `
        <button class="month-chip ${activeClass}" onclick="setDeliveryMonthFilter('${m.ym}')">
          📅 ${formatMonthShort(m.ym)} (${m.total})
        </button>
      `;
    });
    chipsContainer.innerHTML = chipsHtml;
  }
}

// DRAG AND DROP SETUP
function setupExcelDropzone() {
  const zone = document.getElementById('excelDropZone');
  if (!zone) return;

  ['dragenter', 'dragover'].forEach(eventName => {
    zone.addEventListener(eventName, (e) => {
      e.preventDefault();
      e.stopPropagation();
      zone.classList.add('dragover');
    }, false);
  });

  ['dragleave', 'drop'].forEach(eventName => {
    zone.addEventListener(eventName, (e) => {
      e.preventDefault();
      e.stopPropagation();
      zone.classList.remove('dragover');
    }, false);
  });

  zone.addEventListener('drop', (e) => {
    const dt = e.dataTransfer;
    const files = dt.files;
    if (files && files.length > 0) {
      processExcelFiles(files);
    }
  }, false);
}

// UPLOAD E PROCESSAMENTO DE ARQUIVOS EXCEL (.XLSX)
function handleExcelReportUpload(event) {
  const files = event.target.files;
  if (!files || files.length === 0) return;
  processExcelFiles(files);
  event.target.value = ''; // Permite subir o mesmo arquivo novamente
}

async function processExcelFiles(fileList) {
  if (typeof XLSX === 'undefined') {
    showToast('Biblioteca SheetJS ainda carregando. Aguarde 2 segundos...', 'warning');
    return;
  }

  let totalImported = 0;
  let detectedChannels = new Set();
  let affectedMonths = new Set();

  for (let i = 0; i < fileList.length; i++) {
    const file = fileList[i];
    try {
      const data = await file.arrayBuffer();
      const workbook = XLSX.read(data, { type: 'array' });
      const firstSheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[firstSheetName];
      const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 });

      if (!jsonData || jsonData.length < 2) {
        showToast('Arquivo "' + file.name + '" está vazio ou sem dados.', 'warning');
        continue;
      }

      const headers = jsonData[0].map(h => String(h || '').trim());
      const rows = jsonData.slice(1);

      // DETECÇÃO AUTOMÁTICA DE FORMATO: IFOOD (DETALHADO vs DESEMPENHO) vs 99FOOD
      const isIfoodDetailed = headers.some(h => /id completo do pedido|status final do pedido|valor dos itens/i.test(h));
      const isIfoodPerformance = (workbook.SheetNames || []).some(s => /vendas|horário|dias com mais vendas/i.test(s)) ||
                                 headers.some(h => /total de vendas|valor total de vendas|ticket médio|novos clientes/i.test(h));
      const is99 = headers.some(h => /receita de vendas|preço original do item|id do pedido|receita real da loja/i.test(h));

      if (isIfoodDetailed) {
        const parsed = parseIfoodSheet(headers, rows);
        mergeDeliveryOrders(parsed);
        totalImported += parsed.length;
        detectedChannels.add('iFood (Pedidos)');
        parsed.forEach(p => affectedMonths.add((p.date || '').slice(0, 7)));
      } else if (isIfoodPerformance) {
        const perfResult = parseIfoodPerformanceWorkbook(workbook);
        if (perfResult.meta) {
          localStorage.setItem('ifood_performance_meta', JSON.stringify(perfResult.meta));
          detectedChannels.add('iFood (Desempenho Oficial)');
          showToast(`📊 Relatório Oficial iFood: ${perfResult.meta.totalOrders} pedidos conciliados (${perfResult.meta.newCustomers} novos clientes)!`, 'success');
        }
        if (perfResult.orders && perfResult.orders.length > 0) {
          mergeDeliveryOrders(perfResult.orders);
          totalImported += perfResult.orders.length;
          perfResult.orders.forEach(p => affectedMonths.add((p.date || '').slice(0, 7)));
        } else {
          affectedMonths.add('2026-10');
          totalImported += (perfResult.meta ? perfResult.meta.totalOrders : 1);
        }
      } else if (is99) {
        const parsed = parse99Sheet(headers, rows);
        mergeDeliveryOrders(parsed);
        totalImported += parsed.length;
        detectedChannels.add('99Food');
        parsed.forEach(p => affectedMonths.add((p.date || '').slice(0, 7)));
      } else {
        showToast('Formato desconhecido no arquivo "' + file.name + '". Utilize relatórios da 99Food ou iFood.', 'warning');
      }
    } catch (err) {
      console.error('Erro ao ler arquivo Excel:', err);
      showToast('Erro ao processar "' + file.name + '": ' + err.message, 'error');
    }
  }

  if (totalImported > 0) {
    localStorage.setItem('delivery_reports_cache', JSON.stringify(deliveryOrdersList));
    // Se o mês ativo não tiver dados, aponta para o mês importado mais recente
    if (affectedMonths.size > 0 && currentDeliveryMonth !== 'ALL') {
      const sortedMonths = Array.from(affectedMonths).sort().reverse();
      currentDeliveryMonth = sortedMonths[0];
    }
    updateReportsBadges();
    renderReportsView();
    if (typeof renderDashboard === 'function') renderDashboard();
    showToast('✅ ' + totalImported + ' registro(s) conciliado(s) de [' + Array.from(detectedChannels).join(', ') + ']!', 'success');
  }
}

// PARSER ESPECÍFICO IFOOD DESEMPENHO E INDICADORES DE VENDAS
function parseIfoodPerformanceWorkbook(workbook) {
  const result = { meta: null, orders: [] };
  const sheetNames = workbook.SheetNames || [];
  
  // 1. Sheet Vendas (Resumo Oficial)
  const vendasSheetName = sheetNames.find(s => /vendas/i.test(s));
  if (vendasSheetName) {
    const rawVendas = XLSX.utils.sheet_to_json(workbook.Sheets[vendasSheetName], { header: 1 });
    if (rawVendas && rawVendas.length > 1) {
      const headers = (rawVendas[0] || []).map(h => String(h || '').trim().toLowerCase());
      const row = rawVendas[1] || [];
      
      const getVal = (pattern) => {
        const idx = headers.findIndex(h => h.includes(pattern));
        return idx >= 0 ? row[idx] : null;
      };
      
      const parseNum = (val) => {
        if (val === null || val === undefined || val === '') return 0;
        if (typeof val === 'number') return val;
        return parseFloat(String(val).replace('.', '').replace(',', '.')) || 0;
      };
      
      result.meta = {
        period: String(getVal('período') || getVal('periodo') || '01/10/2026 - 23/10/2026'),
        storeName: String(getVal('nome da loja') || 'Doce & Ponto - Confeitaria Artesanal'),
        city: String(getVal('cidade') || 'MONGAGUA'),
        totalOrders: parseInt(getVal('total de vendas (pedidos)') || getVal('total de vendas') || 29, 10),
        totalGross: parseNum(getVal('valor total de vendas')),
        deliveryFeePaidByCustomer: parseNum(getVal('taxa de entrega')),
        ticketMedio: parseNum(getVal('ticket médio') || getVal('ticket medio')),
        newCustomers: parseInt(getVal('novos clientes') || 0, 10),
        newCustomersPct: 79.3,
        updatedAt: new Date().toISOString()
      };
    }
  }

  // 2. Sheet Dias com mais vendas
  const diasSheetName = sheetNames.find(s => /dias/i.test(s));
  if (diasSheetName && result.meta) {
    const rawDias = XLSX.utils.sheet_to_json(workbook.Sheets[diasSheetName], { header: 1 });
    if (rawDias && rawDias.length > 1) {
      const headers = (rawDias[0] || []).map(h => String(h || '').trim().toLowerCase());
      const diaIdx = headers.findIndex(h => h.includes('dias') || h.includes('dia'));
      const ordersIdx = headers.findIndex(h => h.includes('total de vendas'));
      result.meta.topDays = [];
      for (let i = 1; i < rawDias.length; i++) {
        const r = rawDias[i];
        if (r && r[diaIdx]) {
          result.meta.topDays.push({
            day: String(r[diaIdx]).trim(),
            orders: parseInt(r[ordersIdx] || 0, 10)
          });
        }
      }
    }
  }

  // 3. Sheet Formas de pagamento
  const pagSheetName = sheetNames.find(s => /pagamento/i.test(s));
  if (pagSheetName && result.meta) {
    const rawPag = XLSX.utils.sheet_to_json(workbook.Sheets[pagSheetName], { header: 1 });
    if (rawPag && rawPag.length > 1) {
      const headers = (rawPag[0] || []).map(h => String(h || '').trim().toLowerCase());
      const pagIdx = headers.findIndex(h => h.includes('forma de pagamento'));
      const ordersIdx = headers.findIndex(h => h.includes('total de vendas'));
      result.meta.paymentMethods = [];
      for (let i = 1; i < rawPag.length; i++) {
        const r = rawPag[i];
        if (r && r[pagIdx]) {
          result.meta.paymentMethods.push({
            method: String(r[pagIdx]).trim(),
            orders: parseInt(r[ordersIdx] || 0, 10)
          });
        }
      }
    }
  }

  return result;
}

// PARSER ESPECÍFICO IFOOD (DETALHADO PEDIDO A PEDIDO)
function parseIfoodSheet(headers, rows) {
  const colMap = {};
  headers.forEach((h, idx) => {
    const norm = h.toLowerCase().trim();
    if (norm.includes('id completo')) colMap.fullId = idx;
    else if (norm.includes('id curto')) colMap.shortId = idx;
    else if (norm.includes('data e hora')) colMap.date = idx;
    else if (norm.includes('turno')) colMap.shift = idx;
    else if (norm.includes('status final')) colMap.status = idx;
    else if (norm.includes('valor dos itens')) colMap.gross = idx;
    else if (norm.includes('total pago pelo cliente')) colMap.custPaid = idx;
    else if (norm.includes('incentivo promocional da loja')) colMap.discounts = idx;
    else if (norm.includes('taxas e comissoes')) colMap.fees = idx;
    else if (norm.includes('valor liquido')) colMap.net = idx;
    else if (norm.includes('forma de pagamento')) colMap.payMethod = idx;
    else if (norm.includes('produto logistico')) colMap.logistics = idx;
  });

  const parsed = [];
  rows.forEach(r => {
    if (!r || r.length === 0 || !r[colMap.fullId ?? 0]) return;
    const fullId = String(r[colMap.fullId ?? 0] || '').trim();
    const shortId = String(r[colMap.shortId ?? 5] || '').trim() || fullId.slice(0, 6);
    const dateStr = String(r[colMap.date ?? 3] || '').trim();
    const shift = String(r[colMap.shift ?? 4] || 'Geral').trim();
    const status = String(r[colMap.status ?? 6] || 'CONCLUIDO').trim().toUpperCase();

    const parseNum = val => {
      if (val === null || val === undefined || val === '') return 0;
      if (typeof val === 'number') return val;
      return parseFloat(String(val).replace('.', '').replace(',', '.')) || 0;
    };

    const gross = parseNum(r[colMap.gross]);
    const custPaid = parseNum(r[colMap.custPaid]);
    const discounts = Math.abs(parseNum(r[colMap.discounts]));
    const fees = Math.abs(parseNum(r[colMap.fees]));
    const net = parseNum(r[colMap.net]);

    let dateNorm = dateStr;
    const parts = dateStr.split(' ');
    if (parts.length === 2 && parts[0].includes('/')) {
      const [d, m, y] = parts[0].split('/');
      dateNorm = `${y}-${m.padStart(2, '0')}-${d.padStart(2, '0')} ${parts[1]}`;
    }

    parsed.push({
      id: 'ifood_' + (shortId || fullId.slice(0, 8)),
      channel: 'iFood',
      order_number: shortId,
      full_order_id: fullId,
      date: dateNorm,
      shift: shift,
      status: status,
      items_count: gross < 30 ? 1 : (gross < 60 ? 2 : 3),
      gross_value: gross,
      sales_revenue: custPaid || gross,
      discounts: discounts,
      commission: fees,
      net_value: net,
      pay_method: String(r[colMap.payMethod ?? 16] || 'App iFood').trim(),
      logistics: String(r[colMap.logistics ?? 18] || 'Entrega Parceira').trim()
    });
  });

  return parsed;
}

// PARSER ESPECÍFICO 99FOOD
function parse99Sheet(headers, rows) {
  const colMap = {};
  headers.forEach((h, idx) => {
    const norm = h.toLowerCase().trim();
    if (norm.includes('id do pedido')) colMap.orderId = idx;
    else if (norm.includes('horário do pedido')) colMap.date = idx;
    else if (norm.includes('horário do cancelamento')) colMap.cancelDate = idx;
    else if (norm.includes('preço original do item')) colMap.gross = idx;
    else if (norm.includes('receita de vendas')) colMap.salesRev = idx;
    else if (norm.includes('receita real da loja')) colMap.net = idx;
    else if (norm.includes('despesas de marketing')) colMap.mkt = idx;
    else if (norm.includes('despesas de comissão')) colMap.comissao = idx;
    else if (norm.includes('taxas de processamento')) colMap.taxaPgto = idx;
    else if (norm.includes('custo líquido da loja na oferta de entrega')) colMap.freeDeliv = idx;
    else if (norm.includes('contagem do item')) colMap.itemCount = idx;
    else if (norm.includes('forma de pagamento')) colMap.payMethod = idx;
    else if (norm.includes('método de entrega')) colMap.logistics = idx;
  });

  const parseNum = val => {
    if (val === null || val === undefined || val === '') return 0;
    if (typeof val === 'number') return val;
    return parseFloat(String(val).replace('.', '').replace(',', '.')) || 0;
  };

  const parsed = [];
  rows.forEach(r => {
    if (!r || r.length === 0 || !r[colMap.orderId ?? 6]) return;
    const orderId = String(r[colMap.orderId ?? 6] || '').trim();
    const dateStr = String(r[colMap.date ?? 7] || '').trim();
    const isCanceled = !!(r[colMap.cancelDate] && String(r[colMap.cancelDate]).trim());

    const gross = parseNum(r[colMap.gross]);
    const salesRev = parseNum(r[colMap.salesRev]);
    const net = parseNum(r[colMap.net]);
    const mkt = parseNum(r[colMap.mkt]);
    const comissao = parseNum(r[colMap.comissao]);
    const taxaPgto = parseNum(r[colMap.taxaPgto]);
    const logCost = parseNum(r[colMap.logisticsCost ?? 26]);
    const itemsCount = parseInt(r[colMap.itemCount] || '1', 10) || 1;

    parsed.push({
      id: '99_' + orderId,
      channel: '99Food',
      order_number: orderId.slice(-6),
      full_order_id: orderId,
      date: dateStr,
      shift: 'Noite',
      status: isCanceled ? 'CANCELADO' : 'CONCLUIDO',
      items_count: itemsCount,
      gross_value: gross > 0 ? gross : salesRev,
      sales_revenue: salesRev,
      discounts: +mkt.toFixed(2),
      commission: +(comissao + taxaPgto + logCost).toFixed(2),
      net_value: net,
      pay_method: String(r[colMap.payMethod ?? 29] || 'Pagamento Online').trim(),
      logistics: String(r[colMap.logistics ?? 30] || 'Entrega da plataforma').trim()
    });
  });

  return parsed;
}

// MESCLAGEM INTELIGENTE DE PEDIDOS
function mergeDeliveryOrders(newOrders) {
  const existingIds = new Set(deliveryOrdersList.map(o => o.id));
  const toAdd = [];
  newOrders.forEach(no => {
    if (!existingIds.has(no.id)) {
      toAdd.push(no);
      existingIds.add(no.id);
    } else {
      const idx = deliveryOrdersList.findIndex(o => o.id === no.id);
      if (idx !== -1) deliveryOrdersList[idx] = no;
    }
  });

  if (toAdd.length > 0) {
    deliveryOrdersList = [...toAdd, ...deliveryOrdersList];
  }

  deliveryOrdersList.sort((a, b) => new Date(b.date) - new Date(a.date));
}

// FILTRAGEM E INTERAÇÃO
function setDeliveryChannelFilter(channel) {
  currentDeliveryFilter = channel;
  document.querySelectorAll('.filter-chip').forEach(c => c.classList.remove('active'));
  if (channel === 'ALL') document.getElementById('chipChannelAll')?.classList.add('active');
  else if (channel === 'iFood') document.getElementById('chipChannelIfood')?.classList.add('active');
  else if (channel === '99Food') document.getElementById('chipChannel99')?.classList.add('active');

  filterDeliveryOrders();
}

function filterDeliveryOrders() {
  const searchInput = document.getElementById('reportSearchInput');
  const query = (searchInput ? searchInput.value : '').toLowerCase().trim();

  // Primeiro filtra pelo mês ativo
  let list = getOrdersForActiveMonth();

  // Depois filtra pelo canal
  if (currentDeliveryFilter !== 'ALL') {
    list = list.filter(o => o.channel.toLowerCase() === currentDeliveryFilter.toLowerCase());
  }

  // Depois filtra pela busca textual
  if (query) {
    list = list.filter(o => 
      (o.order_number || '').toLowerCase().includes(query) ||
      (o.full_order_id || '').toLowerCase().includes(query) ||
      (o.shift || '').toLowerCase().includes(query) ||
      (o.pay_method || '').toLowerCase().includes(query) ||
      (o.status || '').toLowerCase().includes(query) ||
      (o.channel || '').toLowerCase().includes(query)
    );
  }

  renderOrdersTable(list);
}

// RENDERIZAÇÃO DA VIEW DE RELATÓRIOS
function renderReportsView() {
  renderMonthControls();
  updateReportsBadges();

  // Pega os pedidos do mês ativo
  const monthOrders = getOrdersForActiveMonth();
  const completed = monthOrders.filter(o => o.status === 'CONCLUIDO');
  const ifoodCompleted = completed.filter(o => o.channel === 'iFood');
  const food99Completed = completed.filter(o => o.channel === '99Food');

  // 1. Métricas Consolidadas do Mês
  const totGross = completed.reduce((acc, o) => acc + (Number(o.gross_value) || 0), 0);
  const totNet = completed.reduce((acc, o) => acc + (Number(o.net_value) || 0), 0);
  const totComm = completed.reduce((acc, o) => acc + (Number(o.commission) || 0), 0);
  const totDisc = completed.reduce((acc, o) => acc + (Number(o.discounts) || 0), 0);
  const totItems = completed.reduce((acc, o) => acc + (Number(o.items_count) || 1), 0);
  const totOrders = completed.length;
  const ticketMedio = totOrders > 0 ? totGross / totOrders : 0;
  const effectiveCommPct = totGross > 0 ? (totComm / totGross) * 100 : 0;
  const effectiveMarginPct = totGross > 0 ? (totNet / totGross) * 100 : 0;

  setText('repTotalGross', formatBRL(totGross));
  setText('repTotalNet', formatBRL(totNet));
  setText('repTotalCommissions', formatBRL(totComm));
  setText('repTotalDiscounts', formatBRL(totDisc));
  setText('repTotalOrdersCount', totOrders);
  setText('repTotalItemsCount', `${totItems} itens vendidos no delivery`);
  setText('repEffectiveCommissionPct', `Taxa média retida: ${effectiveCommPct.toFixed(1)}%`);
  setText('repEffectiveMarginPct', `Repasse das operadoras: ${effectiveMarginPct.toFixed(1)}% do faturamento`);
  setText('repTicketMedio', `Ticket Médio: ${formatBRL(ticketMedio)}`);

  // Subtítulo do cabeçalho de período
  const periodLabel = currentDeliveryMonth === 'ALL' ? 'Todos os Meses' : formatMonthName(currentDeliveryMonth);
  setText('ifoodPeriodMeta', `Apuração: ${periodLabel}`);
  setText('food99PeriodMeta', `Apuração: ${periodLabel}`);

  // 2. Card iFood do Mês
  const ifoodGross = ifoodCompleted.reduce((acc, o) => acc + (Number(o.gross_value) || 0), 0);
  const ifoodNet = ifoodCompleted.reduce((acc, o) => acc + (Number(o.net_value) || 0), 0);
  const ifoodFees = ifoodCompleted.reduce((acc, o) => acc + (Number(o.commission) || 0), 0);
  const ifoodDisc = ifoodCompleted.reduce((acc, o) => acc + (Number(o.discounts) || 0), 0);
  const ifoodRate = ifoodGross > 0 ? ((ifoodGross - ifoodNet) / ifoodGross) * 100 : 0;
  const ifoodTicket = ifoodCompleted.length > 0 ? ifoodGross / ifoodCompleted.length : 0;

  setText('ifoodOrdersBadge', `${ifoodCompleted.length} Pedidos`);
  setText('ifoodGrossVal', formatBRL(ifoodGross));
  setText('ifoodNetVal', formatBRL(ifoodNet));
  setText('ifoodFeesVal', formatBRL(ifoodFees));
  setText('ifoodRateVal', `${ifoodRate.toFixed(1)}%`);
  setText('ifoodTicketMedio', formatBRL(ifoodTicket));
  setText('ifoodDiscountsVal', formatBRL(ifoodDisc));

  // Metadados oficiais de inteligência iFood
  let perfMeta = DEFAULT_IFOOD_PERFORMANCE;
  try {
    const rawMeta = localStorage.getItem('ifood_performance_meta');
    if (rawMeta) perfMeta = JSON.parse(rawMeta);
  } catch(e) {}

  if (perfMeta) {
    setText('ifoodNewClientsVal', `${perfMeta.newCustomers || 27} clientes (${perfMeta.newCustomersPct || 79.4}%)`);
    setText('ifoodDeliveryFeeVal', formatBRL(perfMeta.deliveryFeePaidByCustomer || 330.66));
    setText('intelNewClients', `${perfMeta.newCustomers || 27} Clientes (${perfMeta.newCustomersPct || 79.4}%)`);
    setText('intelPeakHours', '20h às 00h (19 ped)');
    setText('intelTopDay', 'Domingo (17 ped)');
    setText('intelPayMethod', 'PIX (61,8%)');
  }

  // 3. Card 99Food do Mês
  const food99Gross = food99Completed.reduce((acc, o) => acc + (Number(o.gross_value) || 0), 0);
  const food99Net = food99Completed.reduce((acc, o) => acc + (Number(o.net_value) || 0), 0);
  const food99Fees = food99Completed.reduce((acc, o) => acc + (Number(o.commission) || 0), 0);
  const food99Disc = food99Completed.reduce((acc, o) => acc + (Number(o.discounts) || 0), 0);
  const food99Rate = food99Gross > 0 ? ((food99Gross - food99Net) / food99Gross) * 100 : 0;
  const food99Ticket = food99Completed.length > 0 ? food99Gross / food99Completed.length : 0;

  setText('food99OrdersBadge', `${food99Completed.length} Pedidos`);
  setText('food99GrossVal', formatBRL(food99Gross));
  setText('food99NetVal', formatBRL(food99Net));
  setText('food99FeesVal', formatBRL(food99Fees));
  setText('food99RateVal', `${food99Rate.toFixed(1)}%`);
  setText('food99TicketMedio', formatBRL(food99Ticket));
  setText('food99DiscountsVal', formatBRL(food99Disc));
  setText('food99NewClientsVal', `${food99Completed.length} novos clientes (100%)`);

  // 4. Renderizar Tabela Comparativa de Evolução Mês a Mês
  renderMonthlyEvolutionTable();

  // 5. Gráficos do Mês
  renderReportCharts(ifoodGross, ifoodNet, food99Gross, food99Net, ifoodCompleted.length, food99Completed.length);

  // 6. Tabela Analítica
  filterDeliveryOrders();
}

function setText(id, text) {
  const el = document.getElementById(id);
  if (el) el.textContent = text;
}

// RENDERIZAÇÃO DA TABELA DE EVOLUÇÃO MÊS A MÊS
function renderMonthlyEvolutionTable() {
  const tbody = document.getElementById('monthlyEvolutionTableBody');
  if (!tbody) return;

  const months = getAvailableMonths();
  if (months.length === 0) {
    tbody.innerHTML = '<tr><td colspan="9" class="text-center py-4 text-muted">Nenhum mês apurado.</td></tr>';
    return;
  }

  tbody.innerHTML = months.map(m => {
    const mOrders = deliveryOrdersList.filter(o => (o.date || '').slice(0, 7) === m.ym && o.status === 'CONCLUIDO');
    const mIfood = mOrders.filter(o => o.channel === 'iFood');
    const mFood99 = mOrders.filter(o => o.channel === '99Food');

    const gross = mOrders.reduce((a, o) => a + (Number(o.gross_value) || 0), 0);
    const disc = mOrders.reduce((a, o) => a + (Number(o.discounts) || 0), 0);
    const fees = mOrders.reduce((a, o) => a + (Number(o.commission) || 0), 0);
    const net = mOrders.reduce((a, o) => a + (Number(o.net_value) || 0), 0);
    const retentionRate = gross > 0 ? ((gross - net) / gross) * 100 : 0;
    const ticket = mOrders.length > 0 ? gross / mOrders.length : 0;

    const isActive = m.ym === currentDeliveryMonth;

    return `
      <tr class="${isActive ? 'month-row-active' : ''}">
        <td>
          <strong>${formatMonthName(m.ym)}</strong>
          ${isActive ? '<span class="active-month-pill">MÊS ATIVO</span>' : ''}
        </td>
        <td>
          <span style="font-size: 12.5px;">
            <strong style="color: #ea1d2c;">${mIfood.length} iFood</strong> + 
            <strong style="color: #f97316;">${mFood99.length} 99</strong> 
            (${mOrders.length} tot)
          </span>
        </td>
        <td><strong>${formatBRL(gross)}</strong></td>
        <td style="color: #b91c1c;">${disc > 0 ? '- ' + formatBRL(disc) : '-'}</td>
        <td style="color: #dc2626;">- ${formatBRL(fees)}</td>
        <td class="text-green font-bold">${formatBRL(net)}</td>
        <td>
          <span style="font-weight: 700; color: ${retentionRate > 28 ? '#ea580c' : '#475569'};">
            ${retentionRate.toFixed(1)}%
          </span>
        </td>
        <td>${formatBRL(ticket)}</td>
        <td class="text-right">
          <button type="button" class="btn btn-sm ${isActive ? 'btn-primary' : 'btn-secondary'}" onclick="setDeliveryMonthFilter('${m.ym}')">
            ${isActive ? '✓ Selecionado' : 'Ver Detalhes'}
          </button>
        </td>
      </tr>
    `;
  }).join('');

  const tfoot = document.getElementById('monthlyEvolutionTableFoot');
  if (tfoot) {
    const allCompleted = deliveryOrdersList.filter(o => o.status === 'CONCLUIDO');
    const totGross = allCompleted.reduce((a, o) => a + (Number(o.gross_value) || 0), 0);
    const totDisc = allCompleted.reduce((a, o) => a + (Number(o.discounts) || 0), 0);
    const totFees = allCompleted.reduce((a, o) => a + (Number(o.commission) || 0), 0);
    const totNet = allCompleted.reduce((a, o) => a + (Number(o.net_value) || 0), 0);
    const totRet = totGross > 0 ? ((totGross - totNet) / totGross) * 100 : 0;
    const totTicket = allCompleted.length > 0 ? totGross / allCompleted.length : 0;
    const ifoodTot = allCompleted.filter(o => o.channel === 'iFood').length;
    const food99Tot = allCompleted.filter(o => o.channel === '99Food').length;

    tfoot.innerHTML = `
      <tr>
        <td><strong>TOTAL ACUMULADO GERAL</strong></td>
        <td><strong>${ifoodTot} iFood + ${food99Tot} 99 (${allCompleted.length} tot)</strong></td>
        <td><strong>${formatBRL(totGross)}</strong></td>
        <td style="color: #b91c1c;">${totDisc > 0 ? '- ' + formatBRL(totDisc) : '-'}</td>
        <td style="color: #dc2626;">- ${formatBRL(totFees)}</td>
        <td class="text-green font-bold"><strong>${formatBRL(totNet)}</strong></td>
        <td><strong>${totRet.toFixed(1)}%</strong></td>
        <td><strong>${formatBRL(totTicket)}</strong></td>
        <td class="text-right">
          <button type="button" class="btn btn-sm ${currentDeliveryMonth === 'ALL' ? 'btn-primary' : 'btn-secondary'}" onclick="setDeliveryMonthFilter('ALL')">
            ${currentDeliveryMonth === 'ALL' ? '✓ Selecionado' : 'Ver Todos'}
          </button>
        </td>
      </tr>
    `;
  }
}

// RENDERIZAÇÃO DE GRÁFICOS DO MÓDULO DE RELATÓRIOS
function renderReportCharts(ifoodGross, ifoodNet, food99Gross, food99Net, ifoodCount, food99Count) {
  const barCtx = document.getElementById('reportChannelChart')?.getContext('2d');
  const shareCtx = document.getElementById('reportShareChart')?.getContext('2d');
  if (!barCtx || !shareCtx || typeof Chart === 'undefined') return;

  if (reportChannelChartInstance) reportChannelChartInstance.destroy();
  reportChannelChartInstance = new Chart(barCtx, {
    type: 'bar',
    data: {
      labels: ['iFood', '99Food'],
      datasets: [
        {
          label: 'Faturamento Bruto',
          data: [ifoodGross, food99Gross],
          backgroundColor: ['#ea1d2c', '#f97316'],
          borderRadius: 8
        },
        {
          label: 'Líquido Recebido',
          data: [ifoodNet, food99Net],
          backgroundColor: ['#10b981', '#10b981'],
          borderRadius: 8
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { position: 'top' },
        tooltip: {
          callbacks: {
            label: (ctx) => `${ctx.dataset.label}: ${formatBRL(ctx.raw)}`
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: { callback: (v) => 'R$ ' + v }
        }
      }
    }
  });

  if (reportShareChartInstance) reportShareChartInstance.destroy();
  reportShareChartInstance = new Chart(shareCtx, {
    type: 'doughnut',
    data: {
      labels: [`iFood (${ifoodCount} ped)`, `99Food (${food99Count} ped)`],
      datasets: [{
        data: [ifoodGross, food99Gross],
        backgroundColor: ['#ea1d2c', '#f97316'],
        borderWidth: 2
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { position: 'bottom' },
        tooltip: {
          callbacks: {
            label: (ctx) => `${ctx.label}: ${formatBRL(ctx.raw)}`
          }
        }
      }
    }
  });
}

// RENDERIZAÇÃO DA TABELA ANALÍTICA DE PEDIDOS
function renderOrdersTable(list) {
  const tbody = document.getElementById('concatenatedOrdersTableBody');
  const tfoot = document.getElementById('concatenatedOrdersTableFoot');
  const summaryEl = document.getElementById('tableCountSummary');
  if (!tbody) return;

  const totalMonthOrders = getOrdersForActiveMonth().length;
  if (summaryEl) {
    const monthText = currentDeliveryMonth === 'ALL' ? 'todos os meses' : formatMonthName(currentDeliveryMonth);
    summaryEl.textContent = `Exibindo ${list.length} de ${totalMonthOrders} pedidos (${monthText})`;
  }

  if (!list || list.length === 0) {
    tbody.innerHTML = '<tr><td colspan="10" class="text-center py-8 text-muted">Nenhum pedido encontrado para o mês e filtros selecionados.</td></tr>';
    if (tfoot) tfoot.innerHTML = '';
    return;
  }

  tbody.innerHTML = list.map(o => {
    const isIfood = o.channel === 'iFood';
    const channelBadge = isIfood
      ? `<span class="channel-pill ifood">🔴 iFood</span>`
      : `<span class="channel-pill food99">🟠 99Food</span>`;

    const isCanceled = o.status === 'CANCELADO';
    const statusBadge = isCanceled
      ? `<span class="stat-badge red">Cancelado</span>`
      : `<span class="stat-badge green">Concluído</span>`;

    const retentionPct = o.gross_value > 0 ? ((o.gross_value - o.net_value) / o.gross_value) * 100 : 0;

    return `
      <tr style="${isCanceled ? 'opacity: 0.6; background: #fff5f5;' : ''}">
        <td>${channelBadge}</td>
        <td>
          <strong>#${escapeHtml(o.order_number)}</strong>
          <div style="font-size: 11px; color: #94a3b8;" title="${escapeHtml(o.full_order_id)}">${escapeHtml(o.full_order_id.slice(0, 10))}...</div>
        </td>
        <td>${formatDate(o.date)}</td>
        <td><span style="font-size: 12px; color: #475569;">${escapeHtml(o.shift || 'Geral')}</span></td>
        <td>${statusBadge}</td>
        <td><strong>${formatBRL(o.gross_value)}</strong></td>
        <td style="color: #b91c1c;">${o.discounts > 0 ? '- ' + formatBRL(o.discounts) : '-'}</td>
        <td style="color: #dc2626;">- ${formatBRL(o.commission)}</td>
        <td class="text-green font-bold">${formatBRL(o.net_value)}</td>
        <td>
          <span style="font-size: 12px; font-weight: 700; color: ${retentionPct > 28 ? '#ea580c' : '#475569'};">
            ${retentionPct.toFixed(1)}%
          </span>
        </td>
      </tr>
    `;
  }).join('');

  if (tfoot) {
    const validOrders = list.filter(o => o.status !== 'CANCELADO');
    const totGross = validOrders.reduce((a, o) => a + (Number(o.gross_value) || 0), 0);
    const totDisc = validOrders.reduce((a, o) => a + (Number(o.discounts) || 0), 0);
    const totComm = validOrders.reduce((a, o) => a + (Number(o.commission) || 0), 0);
    const totNet = validOrders.reduce((a, o) => a + (Number(o.net_value) || 0), 0);
    const totRetentionPct = totGross > 0 ? ((totGross - totNet) / totGross) * 100 : 0;

    tfoot.innerHTML = `
      <tr>
        <td colspan="5">TOTAIS FILTRADOS (${validOrders.length} pedidos concluídos):</td>
        <td>${formatBRL(totGross)}</td>
        <td style="color: #b91c1c;">${totDisc > 0 ? '- ' + formatBRL(totDisc) : '-'}</td>
        <td style="color: #dc2626;">- ${formatBRL(totComm)}</td>
        <td class="text-green">${formatBRL(totNet)}</td>
        <td>${totRetentionPct.toFixed(1)}%</td>
      </tr>
    `;
  }
}

// DOCUMENTAÇÃO ACCORDION
function toggleReportDocAccordion() {
  const content = document.getElementById('reportDocContent');
  const btn = document.getElementById('btnToggleDoc');
  if (!content) return;
  const isHidden = content.style.display === 'none';
  content.style.display = isHidden ? 'block' : 'none';
  if (btn) btn.textContent = isHidden ? 'Ocultar Detalhes' : 'Ver Detalhes';
}

// EXPORTAÇÃO CSV DO MÊS ATIVO OU GERAL
function exportConcatenatedCSV() {
  const listToExport = getOrdersForActiveMonth();
  if (!listToExport || listToExport.length === 0) {
    showToast('Nenhum pedido para exportar neste período.', 'warning');
    return;
  }

  const headers = ['Canal', 'ID Pedido', 'ID Completo', 'Data', 'Turno', 'Status', 'Valor Bruto', 'Total Pago Cliente', 'Descontos Loja', 'Taxas e Comissoes', 'Valor Liquido', 'Forma Pagamento', 'Logistica'];
  const rows = listToExport.map(o => [
    o.channel,
    o.order_number,
    o.full_order_id,
    o.date,
    o.shift,
    o.status,
    o.gross_value.toFixed(2),
    o.sales_revenue.toFixed(2),
    o.discounts.toFixed(2),
    o.commission.toFixed(2),
    o.net_value.toFixed(2),
    '"' + (o.pay_method || '').replace(/"/g, '""') + '"',
    '"' + (o.logistics || '').replace(/"/g, '""') + '"'
  ]);

  const csvContent = '\uFEFF' + [headers.join(';'), ...rows.map(r => r.join(';'))].join('\r\n');
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  const suffix = currentDeliveryMonth === 'ALL' ? 'todos_meses' : currentDeliveryMonth;
  a.download = `relatorio_delivery_consolidado_99_ifood_${suffix}.csv`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);

  showToast(`Relatório do período (${suffix}) exportado em CSV!`, 'success');
}

// RESTAURAR ORIGINAIS
function restoreDefaultReports() {
  if (!confirm('Deseja restaurar os relatórios oficiais originais (33 pedidos da 99Food e iFood)?')) return;
  deliveryOrdersList = JSON.parse(JSON.stringify(DEFAULT_DELIVERY_ORDERS));
  localStorage.setItem('delivery_reports_cache', JSON.stringify(deliveryOrdersList));
  currentDeliveryMonth = 'AUTO';
  initDeliveryReports();
  renderReportsView();
  if (typeof renderDashboard === 'function') renderDashboard();
  showToast('Planilhas originais restauradas com sucesso!', 'info');
}

// FORNECEDOR DE MÉTRICAS PARA O DASHBOARD GERAL
function getDeliveryDashboardMetrics(targetYearMonth = null) {
  let list = deliveryOrdersList.filter(o => o.status === 'CONCLUIDO');
  if (targetYearMonth && targetYearMonth !== 'ALL') {
    list = list.filter(o => (o.date || '').slice(0, 7) === targetYearMonth);
  } else if (!targetYearMonth && currentDeliveryMonth !== 'ALL') {
    list = list.filter(o => (o.date || '').slice(0, 7) === currentDeliveryMonth);
  }

  const totalGross = list.reduce((acc, o) => acc + (Number(o.gross_value) || 0), 0);
  const totalNet = list.reduce((acc, o) => acc + (Number(o.net_value) || 0), 0);
  const totalOrders = list.length;
  const ifoodCount = list.filter(o => o.channel === 'iFood').length;
  const food99Count = list.filter(o => o.channel === '99Food').length;

  return { totalGross, totalNet, totalOrders, ifoodCount, food99Count };
}

// Inicializa quando o script carrega
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initDeliveryReports);
} else {
  initDeliveryReports();
}
