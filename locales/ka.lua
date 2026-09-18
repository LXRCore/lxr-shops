--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-SHOPS — Locale: Georgian (ქართული)
     Developer   : iBoss21 | Brand : LXRCore | https://www.lxrcore.com
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

Locale.Register('ka', {
    error = {
        rate = 'შენელდი.', invalid = 'მოთხოვნა არასწორია.', too_far = 'დახლს მიუახლოვდი.', staff_only = 'მხოლოდ პერსონალისთვის.', closed = 'დახლი ღამით დაკეტილია.',
        out_of_stock = '%{label} მარაგში არ არის.', no_money = 'ეს არ გაქვს. სულ: $%{amount}.', too_heavy = 'ჩანთა ვერ დაიტევს — %{label}.', not_wanted = 'მაღაზია ამას არ ყიდულობს.',
    },
    info = { paid = 'გადახდილია $%{amount}.', sold = 'გაიყიდა $%{amount}-ად.' },
    kind = { general = 'საერთო მაღაზია', gunsmith = 'მეიარაღე', saloon = 'სალუნი', doctor = 'ექიმი', butcher = 'ყასაბი', fence = 'გადამყიდველი', trapper = 'მონადირე' },
    ui = {
        browse = 'დახლის დათვალიერება', closed = 'სამუშაო საათების შემდეგ', hint_close = 'წასვლა', cart = 'დახლზე', clear = 'გასუფთავება', total = 'სულ', cash = 'ნაღდი', pay = 'გადახდა', close = 'წასვლა',
        sell = 'გაყიდვა', you_carry = 'რაც თან გაქვს', nothing_to_sell = 'აქ მაღაზიას არაფერი უნდა.', nothing_for_sale = 'ეს დახლი მხოლოდ ყიდულობს.', owned = 'გაქვს', quality = 'მდგომარეობა',
        each = 'თითო', in_stock = 'მარაგშია', out_of_stock = 'მარაგში არ არის', add = 'დამატება', cart_empty = 'დახლზე ჯერ არაფერია.',
    },
})
