@props(['active' => 'dashboard'])

<div
    x-show="mobileOpen"
    x-transition.opacity
    x-cloak
    @click="mobileOpen = false"
    class="fixed inset-0 bg-navy-950/60 z-40 lg:hidden"
></div>

<aside
    class="fixed lg:static inset-y-0 left-0 z-50 flex flex-col bg-navy-900 text-white shrink-0 w-64 transition-transform duration-300 ease-out -translate-x-full lg:translate-x-0"
    :class="[collapsed ? 'lg:w-[76px]' : 'lg:w-64', mobileOpen ? 'translate-x-0' : '-translate-x-full']"
>
    <div class="flex items-center gap-2.5 px-4 h-16 border-b border-white/10 shrink-0">
        <img
            src="{{ asset('images/esperanza/esperanza-seal.png') }}"
            alt="Municipality of Esperanza Seal"
            class="w-9 h-9 rounded-full ring-2 ring-white/15 shrink-0 object-cover"
        >
        <div x-show="!collapsed" x-transition.opacity.duration.150ms class="min-w-0">
            <p class="text-[13px] font-semibold tracking-wide leading-tight truncate">Esperanza LGU</p>
            <p class="text-[10.5px] text-slate-400 truncate">Administrative Portal</p>
        </div>
        <button @click="mobileOpen = false" class="ml-auto lg:hidden p-1.5 rounded-lg text-slate-400 hover:bg-white/10 hover:text-white">
            <i data-lucide="x" class="w-5 h-5"></i>
        </button>
    </div>

    <!-- Signed-in account + access scope -->
    <div x-show="$store.session.account" x-cloak class="mx-2.5 mt-2.5 mb-1 px-3 py-2.5 rounded-xl bg-white/[0.06] border border-white/10">
        <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400 mb-1" x-show="!collapsed">Signed in as</p>
        <p class="text-xs font-semibold text-white truncate" x-show="!collapsed" x-text="$store.session.account?.name"></p>
        <p class="text-[10.5px] text-slate-400 truncate mb-1.5" x-show="!collapsed" x-text="$store.session.account?.id + ' · ' + $store.session.account?.role"></p>
        <span
            class="inline-flex items-center gap-1 text-[10px] font-medium rounded-full px-2 py-0.5"
            :class="$store.session.account?.scope === 'Municipal' ? 'bg-brand-500/20 text-brand-300' : 'bg-purple-500/20 text-purple-300'"
            x-show="!collapsed"
        >
            <i :data-lucide="$store.session.account?.scope === 'Municipal' ? 'landmark' : 'map-pin'" class="w-2.5 h-2.5"></i>
            <span x-text="$store.session.account?.scope === 'Municipal' ? 'Municipality-wide' : 'Brgy. ' + $store.session.account?.scope"></span>
        </span>
    </div>

    <nav class="flex-1 overflow-y-auto scrollbar-dark px-2.5 py-3 space-y-0.5">
        <x-ui.nav-item dense :href="route('admin.dashboard')" icon="layout-dashboard" label="Dashboard" :active="$active === 'dashboard'" />
        <x-ui.nav-item dense :href="route('admin.constituents')" icon="users" label="Constituents" :active="$active === 'constituents'" moduleKey="constituents" />
        <x-ui.nav-item dense :href="route('admin.document-requests')" icon="file-text" label="Dokyu" badge="18" :active="$active === 'document-requests'" moduleKey="dokyu" />
        <x-ui.nav-item dense :href="route('admin.assistance-requests')" icon="hand-heart" label="Tulong" badge="9" :active="$active === 'assistance-requests'" moduleKey="tulong" />
        <x-ui.nav-item dense :href="route('admin.sakuna')" icon="shield-alert" label="Sakuna" :active="$active === 'sakuna'" moduleKey="sakuna" />
        <x-ui.nav-item dense :href="route('admin.payments')" icon="receipt" label="Payments" :active="$active === 'payments'" moduleKey="payments" />
        <x-ui.nav-item dense :href="route('admin.communications')" icon="megaphone" label="Balita" :active="$active === 'communications'" moduleKey="communications" />
        <x-ui.nav-item dense :href="route('admin.reports')" icon="file-chart-column" label="Reports & Analytics" :active="$active === 'reports'" moduleKey="reports" />
        <x-ui.nav-item dense :href="route('admin.users')" icon="user-cog" label="User Management" :active="$active === 'users'" moduleKey="user_management" />
        <x-ui.nav-item dense :href="route('admin.internal-forms')" icon="clipboard-list" label="Internal Forms" :active="$active === 'internal-forms'" />
    </nav>

    <div class="border-t border-white/10 p-2.5 shrink-0">
        <x-ui.nav-item dense :href="route('admin.settings')" icon="settings" label="Settings" :active="$active === 'settings'" moduleKey="settings" />
        <button
            @click="collapsed = !collapsed"
            class="mt-0.5 w-full hidden lg:flex items-center justify-center gap-2 text-xs text-slate-400 hover:text-white py-2 rounded-xl hover:bg-white/[0.06] transition-colors"
        >
            <i data-lucide="panel-left-close" class="w-4 h-4 transition-transform duration-300" :class="collapsed && 'rotate-180'"></i>
            <span x-show="!collapsed">Collapse</span>
        </button>
    </div>
</aside>
