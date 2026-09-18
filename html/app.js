/* LXR-SHOPS — the counter on the LXR UI Kit | © 2026 iBoss21 / LXRCore
   Works on the server's counter: { store, shelves[{label, items[]}], sells[], cash, closed, maxPerPurchase }. */
(function () {
  const $ = (id) => document.getElementById(id);
  const app = $('app');
  const RES = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'lxr-shops';
  let D = null, L = {}, tab = 0, cart = {};
  const t = (k, vars) => { let s = L[k] || k.split('.').pop().replace(/_/g, ' '); if (vars) for (const v in vars) s = s.replace('%{' + v + '}', vars[v]); return s; };
  const money = (n) => (Math.round((Number(n) || 0) * 100) / 100).toFixed(2);
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const post = (name, body) => fetch(`https://${RES}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }).then(r => r.json()).catch(() => ({ ok: false }));
  const sound = (name, set) => post('sound', { name, set });
  const pad = (i) => String(i).padStart(2, '0');

  let toastEl;
  function toast(msg, bad) {
    if (!toastEl) { toastEl = document.createElement('div'); toastEl.className = 'lxr-toast sh-toast'; document.body.appendChild(toastEl); }
    toastEl.textContent = msg; toastEl.classList.toggle('is-bad', !!bad); toastEl.classList.toggle('is-ok', !bad); toastEl.classList.add('show');
    setTimeout(() => toastEl.classList.remove('show'), 2500);
  }
  function applyLocale() { document.querySelectorAll('[data-l]').forEach(el => { const k = 'ui.' + el.dataset.l; if (L[k]) el.textContent = L[k]; }); }
  const SELL = -1;
  const itemByName = (name) => { for (const s of D.shelves) for (const i of s.items) if (i.name === name) return i; return null; };

  // ─── tabs ──────────────────────────────────────────────────────────────
  function renderTabs() {
    const host = $('tabs'); host.innerHTML = '';
    D.shelves.forEach((s, i) => {
      const b = document.createElement('button'); b.className = 'sh-tab' + (tab === i ? ' is-on' : '');
      b.innerHTML = `<span>${esc(s.label)}</span><span class="sh-tab__n">${pad(s.items.length)}</span>`;
      b.addEventListener('click', () => { tab = i; sound('NAV_UP'); renderTabs(); renderRows(); });
      host.appendChild(b);
    });
    if (D.sells) {
      const b = document.createElement('button'); b.className = 'sh-tab sh-tab--sell' + (tab === SELL ? ' is-on' : '');
      b.innerHTML = `<span>${esc(t('ui.sell'))}</span><span class="sh-tab__n">${pad(D.sells.length)}</span>`;
      b.addEventListener('click', () => { tab = SELL; sound('NAV_UP'); renderTabs(); renderRows(); });
      host.appendChild(b);
    }
  }

  // ─── rows ──────────────────────────────────────────────────────────────
  function renderRows() {
    const host = $('rows'); host.innerHTML = '';
    if (tab === SELL) {
      $('shelf-label').textContent = t('ui.you_carry'); $('count').textContent = pad(D.sells.length);
      if (!D.sells.length) { host.innerHTML = `<div class="sh-empty">${esc(t('ui.nothing_to_sell'))}</div>`; return; }
      D.sells.forEach((s, i) => {
        const row = document.createElement('div'); row.className = 'sh-row';
        row.innerHTML = `<span class="sh-row__i">${pad(i + 1)}</span><div><div class="sh-row__name">${esc(s.label)}</div><div class="sh-row__desc">${esc(t('ui.owned'))} ${Number(s.amount) || 0}${s.quality != null ? ' · ' + esc(t('ui.quality')) + ' ' + Math.floor(Number(s.quality)) : ''}</div></div><div class="sh-row__meta"><span class="sh-row__price">$${money(s.offer)}</span><span>${esc(t('ui.each'))}</span></div><div class="sh-row__ctl"><input class="sh-qty" type="number" min="1" max="${Number(s.amount) || 1}" value="1"><button class="lxr-btn lxr-btn-sm">${esc(t('ui.sell'))}</button></div>`;
        const qty = row.querySelector('.sh-qty');
        row.querySelector('button').addEventListener('click', () => act('sell', { slot: s.slot, amount: Math.max(1, Math.min(Number(s.amount) || 1, Number(qty.value) || 1)) }));
        host.appendChild(row);
      });
      return;
    }
    const shelf = D.shelves[tab];
    if (!shelf) { $('shelf-label').textContent = ''; $('count').textContent = ''; host.innerHTML = `<div class="sh-empty">${esc(t('ui.nothing_for_sale'))}</div>`; return; }
    $('shelf-label').textContent = shelf.label; $('count').textContent = pad(shelf.items.length);
    shelf.items.forEach((it, i) => {
      const out = it.stock != null && it.stock <= 0;
      const row = document.createElement('div'); row.className = 'sh-row' + (out ? ' is-out' : '');
      row.innerHTML = `<span class="sh-row__i">${pad(i + 1)}</span><div><div class="sh-row__name">${esc(it.label)}</div><div class="sh-row__desc">${esc(it.description || '')}</div></div><div class="sh-row__meta"><span class="sh-row__price">$${money(it.price)}</span><span>${it.stock != null ? (out ? esc(t('ui.out_of_stock')) : esc(t('ui.in_stock')) + ' ' + Number(it.stock)) : esc(t('ui.each'))}</span></div><div class="sh-row__ctl"><input class="sh-qty" type="number" min="1" max="${D.maxPerPurchase || 50}" value="1" ${out ? 'disabled' : ''}><button class="lxr-btn lxr-btn-ghost lxr-btn-sm" ${out ? 'disabled' : ''}>${esc(t('ui.add'))}</button></div>`;
      const qty = row.querySelector('.sh-qty');
      row.querySelector('button').addEventListener('click', () => { add(it.name, Number(qty.value) || 1); sound('NAV_UP'); });
      host.appendChild(row);
    });
  }

  // ─── cart ──────────────────────────────────────────────────────────────
  function add(name, n) {
    const it = itemByName(name); if (!it) return;
    const max = Math.min(D.maxPerPurchase || 50, it.stock != null ? it.stock : 999);
    cart[name] = Math.max(1, Math.min(max, (cart[name] || 0) + n));
    renderCart();
  }
  function total() { let s = 0; for (const n in cart) { const it = itemByName(n); if (it) s += it.price * cart[n]; } return Math.round(s * 100) / 100; }
  function renderCart() {
    const host = $('cart'); host.innerHTML = '';
    const names = Object.keys(cart);
    if (!names.length) host.innerHTML = `<div class="sh-empty">${esc(t('ui.cart_empty'))}</div>`;
    names.forEach(n => {
      const it = itemByName(n); if (!it) return;
      const row = document.createElement('div'); row.className = 'sh-cart__row';
      row.innerHTML = `<span><b>${esc(it.label)}</b> × ${cart[n]}</span><span class="lxr-num">$${money(it.price * cart[n])}</span><button class="lxr-btn lxr-btn-ghost lxr-btn-sm">×</button>`;
      row.querySelector('button').addEventListener('click', () => { delete cart[n]; renderCart(); });
      host.appendChild(row);
    });
    const sum = total();
    $('total').textContent = '$' + money(sum);
    $('total').classList.toggle('is-over', sum > (D.cash || 0));
    $('btn-pay').disabled = !names.length || sum > (D.cash || 0);
  }

  async function act(name, body) {
    const r = await post(name, body);
    if (!r.ok) { if (r.why) toast(t('error.' + r.why), true); return; }
    if (r.data) { D = Object.assign(D, r.data); $('cash').textContent = money(D.cash); if (name === 'buy') cart = {}; renderTabs(); renderRows(); renderCart(); }
    sound('PURCHASE', 'HUD_SHOP_SOUNDSET');
  }

  $('btn-pay').addEventListener('click', () => {
    const lines = Object.keys(cart).map(n => ({ name: n, amount: cart[n] }));
    if (!lines.length) return;
    if (total() > (D.cash || 0)) { sound('UNAFFORDABLE', 'Ledger_Sounds'); return toast(t('error.no_money', { amount: money(total()) }), true); }
    act('buy', { cart: lines });
  });
  $('btn-clear').addEventListener('click', () => { cart = {}; renderCart(); });
  $('btn-close').addEventListener('click', () => post('close'));
  document.addEventListener('keydown', (e) => { if (D && (e.key === 'Backspace' || e.key === 'Escape') && e.target.tagName !== 'INPUT') post('close'); });

  function open(m) {
    D = m.data; L = m.locale || {};
    document.body.classList.toggle('lang-ka', m.lang === 'ka');
    applyLocale();
    $('store-label').textContent = D.store.label;
    $('kind').textContent = t('kind.' + D.store.kind);
    $('closed').classList.toggle('lxr-hidden', !D.closed);
    $('cash').textContent = money(D.cash);
    tab = D.shelves.length ? 0 : SELL; cart = {};
    app.classList.remove('lxr-hidden');
    renderTabs(); renderRows(); renderCart();
  }
  window.addEventListener('message', e => {
    const m = e.data || {};
    if (m.theme || (m.brand && m.brand.theme)) document.documentElement.dataset.theme = m.theme || m.brand.theme;
    if (m.action === 'open') open(m);
    if (m.action === 'close') { app.classList.add('lxr-hidden'); D = null; }
  });
  if (window.__LXR_MOCK__) open(window.__LXR_MOCK__);
})();
