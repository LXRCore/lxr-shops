/* LXR-SHOPS — the counter | © 2026 iBoss21 / LXRCore
   Works on the server's counter: { store, shelves[{label, items[]}], sells[], purses, accounts, closed, maxPerPurchase }. */
import { useEffect, useMemo, useState } from 'react';
import { onMessage, applyChrome, makeT, post, money, pad, type Msg } from './nui';

type Item = { name: string; label: string; description?: string; category: string; price: number; stock?: number; weight: number; rarity?: string };
type Shelf = { label: string; items: Item[] };
type Sell = { slot: number; name: string; label: string; amount: number; offer: number; quality?: number };
type Counter = { store: { id: string; label: string; kind: string }; shelves: Shelf[]; sells: Sell[]; purses: Record<string, number>; accounts: string[]; closed: boolean; maxPerPurchase: number; cash: number };
type Receipt = { name: string; label: string; amount: number; price: number; at: number };

const sound = (name = 'NAV_UP') => post('sound', { name });

export function App() {
  const [D, setD] = useState<Counter | null>(null);
  const [locale, setLocale] = useState<Record<string, string>>({});
  const [images, setImages] = useState('');
  const [tab, setTab] = useState<'buy' | 'sell' | 'history'>('buy');
  const [cat, setCat] = useState(-1);
  const [q, setQ] = useState('');
  const [cart, setCart] = useState<Record<string, number>>({});
  const [account, setAccount] = useState('cash');
  const [history, setHistory] = useState<Receipt[]>([]);
  const [busy, setBusy] = useState(false);
  const t = makeT(locale);

  useEffect(() => onMessage((m: Msg) => {
    applyChrome(m);
    if (m.locale) setLocale(m.locale);
    if (m.images) setImages(m.images);
    if (m.action === 'open') { setD(m.data); setCart({}); setCat(-1); setQ(''); setTab(m.data && m.data.shelves.length ? 'buy' : 'sell'); setAccount((m.data && m.data.accounts && m.data.accounts[0]) || 'cash'); }
    if (m.action === 'close') setD(null);
  }), []);
  useEffect(() => {
    const k = (e: KeyboardEvent) => { if (e.key === 'Escape' || (e.key === 'Backspace' && (e.target as HTMLElement).tagName !== 'INPUT')) post('close'); };
    document.addEventListener('keydown', k); return () => document.removeEventListener('keydown', k);
  }, []);

  const items = useMemo(() => {
    if (!D) return [] as (Item & { shelf: number })[];
    const all: (Item & { shelf: number })[] = [];
    D.shelves.forEach((s, i) => s.items.forEach((it) => all.push({ ...it, shelf: i })));
    const needle = q.trim().toLowerCase();
    return all.filter((it) => (cat < 0 || it.shelf === cat) && (!needle || it.label.toLowerCase().includes(needle) || (it.description || '').toLowerCase().includes(needle)));
  }, [D, cat, q]);
  const byName = useMemo(() => { const m: Record<string, Item> = {}; D?.shelves.forEach((s) => s.items.forEach((it) => { m[it.name] = it; })); return m; }, [D]);
  const lines = Object.entries(cart).filter(([, n]) => n > 0).map(([name, n]) => ({ item: byName[name], n }));
  const total = lines.reduce((a, l) => a + (l.item ? l.item.price * l.n : 0), 0);

  if (!D) return null;
  const img = (name: string) => images + name + '.png';
  const add = (it: Item, d: number) => {
    setCart((c) => { const cur = c[it.name] || 0; let n = cur + d; if (n < 0) n = 0; if (n > D.maxPerPurchase) n = D.maxPerPurchase; if (it.stock != null && n > it.stock) n = it.stock; return { ...c, [it.name]: n }; });
    sound(d > 0 ? 'NAV_UP' : 'NAV_DOWN');
  };
  const pay = async () => {
    if (busy || !lines.length) return; setBusy(true);
    const r = await post<{ ok: boolean; data?: Counter }>('buy', { cart: lines.map((l) => ({ name: l.item.name, amount: l.n })), account });
    setBusy(false);
    if (r.ok && r.data) { setHistory((h) => [...lines.map((l) => ({ name: l.item.name, label: l.item.label, amount: l.n, price: l.item.price, at: Date.now() })), ...h]); setCart({}); setD(r.data); sound('PURCHASE'); }
  };
  const sell = async (s: Sell, amount: number) => {
    if (busy) return; setBusy(true);
    const r = await post<{ ok: boolean; data?: Counter }>('sell', { slot: s.slot, amount });
    setBusy(false);
    if (r.ok && r.data) setD(r.data);
  };

  return (
    <div id="app">
      <header className="sh-top lxr-hit">
        <button className="lxr-btn lxr-btn-ghost lxr-btn-sm" onClick={() => post('close')}>‹ {t('ui.close')}</button>
        <div className="sh-brand">
          <img className="sh-logo" src="img/lxrcore-logo.png" alt="" />
          <div><h1 className="lxr-cut sh-title">{D.store.label}</h1><div className="sh-sub">{D.closed ? t('ui.closed') : t('ui.browse')}</div></div>
        </div>
        <span className="lxr-grow" />
        <div className="sh-purses">
          {D.accounts.map((a) => (
            <button key={a} className={'sh-purse lxr-chip' + (account === a ? ' is-on' : '')} onClick={() => setAccount(a)} title={t('ui.pay_with', { purse: t('purse.' + a) })}>
              <span className="lxr-mono lxr-t-smoke">{t('purse.' + a)}</span><span className="lxr-num">{money(D.purses[a] || 0)}</span>
            </button>
          ))}
        </div>
        <span className="sh-hint lxr-mono lxr-t-smoke"><span className="lxr-key">Esc</span> {t('ui.hint_close')}</span>
      </header>

      <nav className="sh-tabs lxr-hit">
        {D.shelves.length > 0 && <button className={'sh-tab' + (tab === 'buy' ? ' is-on' : '')} onClick={() => setTab('buy')}>{t('ui.buy')}</button>}
        <button className={'sh-tab' + (tab === 'sell' ? ' is-on' : '')} onClick={() => setTab('sell')}>{t('ui.sell')}<span className="sh-tab__n">{pad(D.sells.length)}</span></button>
        <button className={'sh-tab' + (tab === 'history' ? ' is-on' : '')} onClick={() => setTab('history')}>{t('ui.purchases')}<span className="sh-tab__n">{pad(history.length)}</span></button>
        <span className="lxr-grow" />
        {tab === 'buy' && <input className="lxr-input sh-search" placeholder={t('ui.search')} value={q} onChange={(e) => setQ(e.target.value)} />}
      </nav>

      {tab === 'buy' && (
        <>
          <aside className="sh-side lxr-hit">
            <div className="sh-side__head lxr-mono lxr-t-ash">{t('ui.shelves')}</div>
            <button className={'sh-cat' + (cat < 0 ? ' is-on' : '')} onClick={() => setCat(-1)}><span>{t('ui.all')}</span><span className="sh-cat__n lxr-mono">{D.shelves.reduce((a, s) => a + s.items.length, 0)}</span></button>
            {D.shelves.map((s, i) => (
              <button key={i} className={'sh-cat' + (cat === i ? ' is-on' : '')} onClick={() => { setCat(i); sound(); }}><span>{s.label}</span><span className="sh-cat__n lxr-mono">{s.items.length}</span></button>
            ))}
          </aside>

          <section className="sh-grid lxr-hit">
            {items.length === 0 && <div className="sh-empty lxr-t-smoke">{t('ui.nothing_for_sale')}</div>}
            {items.map((it) => {
              const n = cart[it.name] || 0; const out = it.stock != null && it.stock <= 0;
              return (
                <article key={it.name} className={'sh-card' + (out ? ' is-out' : '') + (n > 0 ? ' is-in' : '') + (it.rarity && it.rarity !== 'common' ? ' is-' + it.rarity : '')}>
                  <div className="sh-card__pic">
                    <img src={img(it.name)} alt="" onError={(e) => { (e.target as HTMLImageElement).style.visibility = 'hidden'; }} />
                    {it.stock != null && !out && <span className="sh-badge lxr-mono">{t('ui.n_in_stock', { n: it.stock })}</span>}
                    {out && <span className="sh-out lxr-cut">{t('ui.out_of_stock')}</span>}
                  </div>
                  <div className="sh-card__name">{it.label}</div>
                  <div className="sh-card__desc">{it.description || ''}</div>
                  <div className="sh-card__foot">
                    <div><div className="lxr-mono lxr-t-smoke sh-card__k">{t('ui.price')}</div><div className="sh-card__price lxr-num">{money(it.price)}</div></div>
                    <span className="lxr-grow" />
                    {n > 0 ? (
                      <div className="sh-step"><button className="lxr-btn lxr-btn-ghost lxr-btn-sm" onClick={() => add(it, -1)}>−</button><span className="lxr-num">{n}</span><button className="lxr-btn lxr-btn-ghost lxr-btn-sm" onClick={() => add(it, 1)}>+</button></div>
                    ) : (
                      <button className="lxr-btn lxr-btn-sm" disabled={out} onClick={() => add(it, 1)}>{t('ui.add')}</button>
                    )}
                  </div>
                </article>
              );
            })}
          </section>

          <aside className={'sh-cart lxr-hit' + (lines.length ? '' : ' is-empty')}>
            <div className="sh-cart__head lxr-rule-b"><span className="lxr-mono lxr-t-ash">{t('ui.cart')}</span><span className="lxr-grow" />{lines.length > 0 && <button className="lxr-btn lxr-btn-ghost lxr-btn-sm" onClick={() => setCart({})}>{t('ui.clear')}</button>}</div>
            <div className="sh-cart__lines">
              {lines.length === 0 && <div className="sh-empty lxr-t-smoke">{t('ui.cart_empty')}</div>}
              {lines.map((l, i) => (
                <div key={l.item.name} className="lxr-row sh-line">
                  <span className="lxr-row-index">{pad(i + 1)}</span>
                  <span className="lxr-row-name">{l.item.label}</span>
                  <span className="sh-line__n lxr-mono">×{l.n}</span>
                  <span className="sh-line__p lxr-num">{money(l.item.price * l.n)}</span>
                </div>
              ))}
            </div>
            <div className="sh-cart__foot">
              <div className="sh-total"><span className="lxr-mono lxr-t-smoke">{t('ui.total')}</span><span className="lxr-num sh-total__n">{money(total)}</span></div>
              <button className="lxr-btn sh-pay" disabled={!lines.length || busy || (D.purses[account] || 0) < total} onClick={pay}>{t('ui.pay_with', { purse: t('purse.' + account) })}</button>
            </div>
          </aside>
        </>
      )}

      {tab === 'sell' && (
        <section className="sh-sell lxr-hit">
          <div className="sh-side__head lxr-mono lxr-t-ash">{t('ui.you_carry')}</div>
          {D.sells.length === 0 && <div className="sh-empty lxr-t-smoke">{t('ui.nothing_to_sell')}</div>}
          {D.sells.map((s, i) => (
            <div key={s.slot} className="lxr-row sh-sellrow">
              <span className="lxr-row-index">{pad(i + 1)}</span>
              <img className="sh-sellrow__img" src={img(s.name)} alt="" onError={(e) => { (e.target as HTMLImageElement).style.visibility = 'hidden'; }} />
              <span className="lxr-row-name">{s.label}</span>
              <span className="lxr-row-sub lxr-mono">{t('ui.owned')} {s.amount}{s.quality ? ' · ' + t('ui.quality') + ' ' + s.quality : ''}</span>
              <span className="lxr-grow" />
              <span className="lxr-num">{money(s.offer)} <small className="lxr-mono lxr-t-smoke">{t('ui.each')}</small></span>
              <button className="lxr-btn lxr-btn-ghost lxr-btn-sm" disabled={busy || s.offer <= 0} onClick={() => sell(s, 1)}>{t('ui.sell_one')}</button>
              <button className="lxr-btn lxr-btn-sm" disabled={busy || s.offer <= 0} onClick={() => sell(s, s.amount)}>{t('ui.sell_all')}</button>
            </div>
          ))}
        </section>
      )}

      {tab === 'history' && (
        <section className="sh-sell lxr-hit">
          <div className="sh-side__head lxr-mono lxr-t-ash">{t('ui.purchases')}</div>
          {history.length === 0 && <div className="sh-empty lxr-t-smoke">{t('ui.no_purchases')}</div>}
          {history.map((r, i) => (
            <div key={r.at + r.name} className="lxr-row sh-sellrow">
              <span className="lxr-row-index">{pad(i + 1)}</span>
              <img className="sh-sellrow__img" src={img(r.name)} alt="" onError={(e) => { (e.target as HTMLImageElement).style.visibility = 'hidden'; }} />
              <span className="lxr-row-name">{r.label}</span>
              <span className="lxr-row-sub lxr-mono">×{r.amount}</span>
              <span className="lxr-grow" />
              <span className="lxr-num">{money(r.price * r.amount)}</span>
            </div>
          ))}
        </section>
      )}
    </div>
  );
}
