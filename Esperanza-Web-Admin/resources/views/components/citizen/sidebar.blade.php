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
            <p class="text-[10.5px] text-slate-400 truncate" x-text="$store.lang.current === 'en' ? 'Citizen Portal' : 'Portal ng Mamamayan'"></p>
        </div>
        <button @click="mobileOpen = false" class="ml-auto lg:hidden p-1.5 rounded-lg text-slate-400 hover:bg-white/10 hover:text-white">
            <i data-lucide="x" class="w-5 h-5"></i>
        </button>
    </div>

    <!-- My Barangay identity strip -->
    <div x-show="!collapsed && $store.barangay.mine" x-cloak class="flex items-center gap-2 px-4 py-2.5 border-b border-white/10 bg-white/[0.03] shrink-0">
        <div class="relative w-6 h-6 shrink-0">
            <div class="absolute inset-0 rounded-full bg-white/10 flex items-center justify-center text-white/40"><i data-lucide="map-pinned" class="w-3 h-3"></i></div>
            <img
                :src="$store.barangay.mine?.seal ? '{{ rtrim(asset(''), '/') }}/' + $store.barangay.mine.seal : ''"
                x-show="$store.barangay.mine?.seal" onerror="this.style.display='none'" alt=""
                class="relative w-6 h-6 rounded-full object-cover"
            >
        </div>
        <p class="text-[11px] text-white/70 truncate">
            Brgy. <span class="font-medium text-white" x-text="$store.barangay.mine?.label"></span>
        </p>
    </div>

    <nav class="flex-1 overflow-y-auto scrollbar-dark px-2.5 py-4 space-y-0.5">
        <x-ui.nav-item dense :href="route('citizen.dashboard')" icon="layout-dashboard" label="Home" labelEn="Dashboard" :active="$active === 'dashboard'" />
        <x-ui.nav-item dense :href="route('citizen.document-requests')" icon="file-text" label="Dokyu" badge="2" :active="$active === 'document-requests'" />
        <x-ui.nav-item dense :href="route('citizen.assistance-requests')" icon="hand-heart" label="Tulong" badge="1" :active="$active === 'assistance-requests'" />
        <x-ui.nav-item dense :href="route('citizen.announcements')" icon="megaphone" label="Balita" :active="$active === 'announcements'" />
        <x-ui.nav-item dense :href="route('citizen.events')" icon="calendar-days" label="Kaganapan" labelEn="Events" :active="$active === 'events'" />
        <x-ui.nav-item dense :href="route('citizen.directory')" icon="building-2" label="Direktoryo" labelEn="Directory" :active="$active === 'directory'" />
        <x-ui.nav-item dense :href="route('citizen.faqs')" icon="life-buoy" label="Suporta" labelEn="Help" :active="$active === 'help'" />
    </nav>

    <div class="border-t border-white/10 p-2.5 shrink-0">
        <button
            @click="collapsed = !collapsed"
            class="w-full hidden lg:flex items-center justify-center gap-2 text-xs text-slate-400 hover:text-white py-2 rounded-xl hover:bg-white/[0.06] transition-colors"
        >
            <i data-lucide="panel-left-close" class="w-4 h-4 transition-transform duration-300" :class="collapsed && 'rotate-180'"></i>
            <span x-show="!collapsed" x-text="$store.lang.current === 'en' ? 'Collapse' : 'I-collapse'"></span>
        </button>
    </div>
</aside>
