@props(['title' => 'Dashboard', 'subtitle' => null])

@php
    $notifications = [
        ['icon' => 'file-text', 'color' => 'text-brand-600 bg-brand-50', 'title' => 'New document request', 'body' => 'Maria Fe Bacaltos requested a Barangay Clearance.', 'time' => '6 min ago'],
        ['icon' => 'hand-heart', 'color' => 'text-emerald-600 bg-emerald-50', 'title' => 'Assistance request approved', 'body' => 'Medical assistance for Rodrigo Palma was approved.', 'time' => '42 min ago'],
        ['icon' => 'megaphone', 'color' => 'text-gold-700 bg-gold-50', 'title' => 'Announcement published', 'body' => '"Fiesta ng Esperanza 2026" is now live on the citizen portal.', 'time' => '2 hours ago'],
        ['icon' => 'user-round-search', 'color' => 'text-purple-600 bg-purple-50', 'title' => 'Resident profile updated', 'body' => 'Barangay Poblacion submitted 12 new resident records.', 'time' => 'Yesterday'],
    ];
@endphp

<header
    class="relative z-20 h-16 bg-white/90 backdrop-blur border-b border-slate-200/70 flex items-center justify-between px-4 lg:px-6 shrink-0"
    x-data="{ time: '' }"
    x-init="setInterval(() => time = new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit' }), 1000)"
>
    <div class="flex items-center gap-3 min-w-0">
        <button @click="mobileOpen = true" class="lg:hidden p-2 -ml-2 rounded-lg text-slate-500 hover:bg-slate-100">
            <i data-lucide="menu" class="w-5 h-5"></i>
        </button>
        <div class="min-w-0">
            <h1 class="text-base lg:text-lg font-semibold text-navy-900 truncate">{{ $title }}</h1>
            @if($subtitle)
                <p class="text-xs text-slate-400 truncate">{{ $subtitle }}</p>
            @endif
        </div>
    </div>

    <div class="flex items-center gap-1.5 lg:gap-2.5">
        <div class="hidden xl:flex items-center gap-1.5 font-mono text-xs text-slate-400 tabular-nums px-2.5 py-1.5 rounded-xl bg-slate-100/70">
            <i data-lucide="clock" class="w-3.5 h-3.5"></i>
            <span x-text="time"></span>
        </div>

        <div class="hidden md:flex items-center relative">
            <i data-lucide="search" class="w-4 h-4 text-slate-400 absolute left-3.5 pointer-events-none"></i>
            <input
                type="text"
                placeholder="Search residents, requests, barangays..."
                class="w-52 lg:w-72 pl-10 pr-4 py-2 text-sm rounded-xl bg-slate-100/80 border border-transparent focus:bg-white focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200"
            >
        </div>

        <div class="relative" x-data="dropdown" @click.outside="close">
            <button @click="toggle" class="relative p-2.5 rounded-xl text-slate-500 hover:bg-slate-100 transition-colors">
                <i data-lucide="bell" class="w-5 h-5"></i>
                <span class="absolute top-1.5 right-1.5 flex w-2 h-2">
                    <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75"></span>
                    <span class="relative inline-flex rounded-full w-2 h-2 bg-rose-500 ring-2 ring-white"></span>
                </span>
            </button>

            <div
                x-show="open"
                x-transition:enter="transition ease-out duration-150"
                x-transition:enter-start="opacity-0 scale-95 -translate-y-1"
                x-transition:enter-end="opacity-100 scale-100 translate-y-0"
                x-cloak
                class="absolute right-0 mt-2 w-[22rem] bg-white rounded-2xl shadow-float border border-slate-100 overflow-hidden z-50 origin-top-right"
            >
                <div class="flex items-center justify-between px-4 py-3 border-b border-slate-100">
                    <p class="text-sm font-semibold text-navy-900">Notifications</p>
                    <span class="text-xs font-medium text-brand-600 bg-brand-50 px-2 py-0.5 rounded-full">{{ count($notifications) }} new</span>
                </div>
                <div class="max-h-80 overflow-y-auto scrollbar-thin divide-y divide-slate-50">
                    @foreach($notifications as $n)
                        <a href="#" class="flex items-start gap-3 px-4 py-3 hover:bg-slate-50 transition-colors">
                            <span class="w-9 h-9 rounded-lg {{ $n['color'] }} flex items-center justify-center shrink-0">
                                <i data-lucide="{{ $n['icon'] }}" class="w-4 h-4"></i>
                            </span>
                            <span class="min-w-0">
                                <span class="block text-sm font-medium text-slate-700 truncate">{{ $n['title'] }}</span>
                                <span class="block text-xs text-slate-400 mt-0.5 line-clamp-2">{{ $n['body'] }}</span>
                                <span class="block text-[11px] text-slate-300 mt-1">{{ $n['time'] }}</span>
                            </span>
                        </a>
                    @endforeach
                </div>
                <a href="{{ route('admin.reports') }}" class="block text-center text-sm font-medium text-brand-600 py-3 border-t border-slate-100 hover:bg-slate-50 transition-colors">
                    View all notifications
                </a>
            </div>
        </div>

        <div class="w-px h-8 bg-slate-200 hidden sm:block"></div>

        <div class="relative" x-data="dropdown" @click.outside="close">
            <button @click="toggle" class="flex items-center gap-2 pl-1 pr-2.5 py-1 rounded-xl hover:bg-slate-100 transition-colors">
                <div class="w-8 h-8 rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold ring-2 ring-white shadow-sm shrink-0 text-xs" x-text="$store.session.initials()"></div>
                <span class="hidden lg:block text-left max-w-[120px]">
                    <span class="block text-sm font-medium text-navy-900 leading-tight truncate" x-text="$store.session.account?.name ?? 'Guest Preview'"></span>
                    <span class="block text-xs text-slate-400 leading-tight truncate" x-text="$store.session.account?.role ?? 'Not signed in'"></span>
                </span>
                <i data-lucide="chevron-down" class="w-4 h-4 text-slate-400 hidden lg:block transition-transform duration-200" :class="open && 'rotate-180'"></i>
            </button>

            <div
                x-show="open"
                x-transition:enter="transition ease-out duration-150"
                x-transition:enter-start="opacity-0 scale-95 -translate-y-1"
                x-transition:enter-end="opacity-100 scale-100 translate-y-0"
                x-cloak
                class="absolute right-0 mt-2 w-64 bg-white rounded-2xl shadow-float border border-slate-100 overflow-hidden z-50 origin-top-right py-1.5"
            >
                <div class="px-4 py-3 border-b border-slate-100">
                    <p class="text-sm font-semibold text-navy-900" x-text="$store.session.account?.name ?? 'Guest Preview'"></p>
                    <p class="text-xs text-slate-400 font-mono" x-text="$store.session.account?.id ?? 'No account selected'"></p>
                    <span
                        x-show="$store.session.account"
                        x-cloak
                        class="inline-flex items-center gap-1 text-[10.5px] font-medium rounded-full px-2 py-0.5 mt-1.5"
                        :class="$store.session.account?.scope === 'Municipal' ? 'bg-brand-50 text-brand-700' : 'bg-purple-50 text-purple-700'"
                    >
                        <i :data-lucide="$store.session.account?.scope === 'Municipal' ? 'landmark' : 'map-pin'" class="w-2.5 h-2.5"></i>
                        <span x-text="$store.session.account?.scope === 'Municipal' ? 'Municipality-wide' : 'Brgy. ' + $store.session.account?.scope"></span>
                    </span>
                </div>
                <a href="#" class="flex items-center gap-2.5 px-4 py-2.5 text-sm text-slate-600 hover:bg-slate-50 transition-colors">
                    <i data-lucide="user" class="w-4 h-4 text-slate-400"></i>My Profile
                </a>
                <a href="{{ route('admin.settings') }}" class="flex items-center gap-2.5 px-4 py-2.5 text-sm text-slate-600 hover:bg-slate-50 transition-colors">
                    <i data-lucide="settings" class="w-4 h-4 text-slate-400"></i>Settings
                </a>
                <div class="border-t border-slate-100 my-1.5"></div>
                <a href="{{ route('logout') }}" @click="$store.session.logout()" class="flex items-center gap-2.5 px-4 py-2.5 text-sm text-rose-600 hover:bg-rose-50 transition-colors">
                    <i data-lucide="log-out" class="w-4 h-4"></i>Sign Out
                </a>
            </div>
        </div>
    </div>
</header>
