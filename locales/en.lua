--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-SHOPS — Locale: English (canonical)
     Developer   : iBoss21 | Brand : LXRCore | https://www.lxrcore.com
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

Locale.Register('en', {
    error = {
        rate = 'Slow down.', invalid = 'That request is not valid.', too_far = 'Step up to the counter.', staff_only = 'Staff only.', closed = 'The counter is closed for the night.',
        out_of_stock = '%{label} is out of stock.', no_money = 'You cannot afford that. Total: $%{amount}.', too_heavy = 'Your satchel cannot take %{label}.', not_wanted = 'The store does not buy that.',
    },
    info = { paid = 'Paid $%{amount}.', sold = 'Sold for $%{amount}.' },
    kind = { general = 'General store', gunsmith = 'Gunsmith', saloon = 'Saloon', doctor = 'Doctor', butcher = 'Butcher', fence = 'Fence', trapper = 'Trapper' },
    ui = {
        browse = 'Browse the counter', closed = 'After hours', hint_close = 'leave', cart = 'On the counter', clear = 'Clear', total = 'Total', cash = 'Cash', pay = 'Pay', close = 'Leave',
        sell = 'Sell', you_carry = 'What you carry', nothing_to_sell = 'Nothing here the store wants.', nothing_for_sale = 'This counter only buys.', owned = 'you have', quality = 'condition',
        each = 'each', in_stock = 'in stock', out_of_stock = 'out of stock', add = 'Add', cart_empty = 'Nothing on the counter yet.',
    },
})
