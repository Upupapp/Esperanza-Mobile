@props(['title' => 'Dashboard', 'subtitle' => null, 'active' => null])

@php
    $filTitles = [
        'dashboard' => 'Home',
        'document-requests' => 'Dokyu',
        'assistance-requests' => 'Tulong',
        'announcements' => 'Balita',
        'events' => 'Mga Kaganapan',
        'directory' => 'Direktoryo ng Pamahalaan',
        'help' => 'Suporta',
        'profile' => 'Aking Profile',
        'notifications' => 'Mga Abiso',
        'settings' => 'Mga Setting',
    ];
    $filSubtitles = [
        'dashboard' => "Narito ang buod ng iyong account.",
        'document-requests' => 'Humiling at subaybayan ang mga dokumento ng munisipyo online.',
        'assistance-requests' => 'Magsumite at subaybayan ang mga kahilingan para sa tulong.',
        'announcements' => 'Pinakabagong balita at abiso mula sa munisipyo.',
        'events' => 'Mga paparating na kaganapan sa Esperanza.',
        'directory' => 'Hanapin ang mga opisina at contact ng pamahalaan.',
        'help' => 'Mga tanong, gabay, at suporta.',
        'profile' => 'Pamahalaan ang iyong impormasyon bilang residente.',
        'notifications' => 'Lahat ng update sa iyong account, nasa isang lugar.',
        'settings' => 'Pamahalaan ang iyong mga kagustuhan sa account.',
    ];
    $filTitle = $filTitles[$active] ?? $title;
    $filSubtitle = $filSubtitles[$active] ?? $subtitle;
@endphp

@php
    $notifications = [
        ['icon' => 'cake', 'color' => 'text-gold-700 bg-gold-50', 'title' => 'Happy Birthday, Maria Fe! 🎉', 'body' => 'The Municipality of Esperanza wishes you a wonderful birthday!', 'time' => 'Today', 'pinned' => true, 'popup' => 'show-birthday-popup'],
        ['icon' => 'circle-check', 'color' => 'text-emerald-600 bg-emerald-50', 'title' => 'Barangay Clearance is ready for release', 'body' => 'Claim it at the Poblacion barangay hall.', 'time' => '18 min ago', 'pinned' => false, 'popup' => null],
        ['icon' => 'file-text', 'color' => 'text-brand-600 bg-brand-50', 'title' => 'Cedula request under verification', 'body' => 'Your request #DR-2026-2210 is being reviewed.', 'time' => '2 hours ago', 'pinned' => false, 'popup' => null],
        ['icon' => 'megaphone', 'color' => 'text-gold-700 bg-gold-50', 'title' => 'New announcement published', 'body' => '"Fiesta ng Esperanza 2026" schedule is now live.', 'time' => 'Yesterday', 'pinned' => false, 'popup' => 'show-fiesta-popup'],
        ['icon' => 'hand-heart', 'color' => 'text-purple-600 bg-purple-50', 'title' => 'Assistance request approved', 'body' => 'Your medical assistance request was approved.', 'time' => '2 days ago', 'pinned' => false, 'popup' => null],
    ];
@endphp

<header
    class="relative z-20 h-16 bg-white/90 backdrop-blur border-b border-slate-200/70 flex items-center justify-between px-4 lg:px-6 shrink-0"
    x-data="{
        time: '',
        searchQuery: '',
        searchOpen: false,
        searchIndex: [
            { en: 'Dashboard', fil: 'Home', icon: 'layout-dashboard', href: '{{ route('citizen.dashboard') }}' },
            { en: 'Dokyu — Document Requests', fil: 'Dokyu — Kahilingan sa Dokumento', icon: 'file-text', href: '{{ route('citizen.document-requests') }}' },
            { en: 'Tulong — Assistance Requests', fil: 'Tulong — Kahilingan sa Tulong', icon: 'hand-heart', href: '{{ route('citizen.assistance-requests') }}' },
            { en: 'Balita — Announcements', fil: 'Balita', icon: 'megaphone', href: '{{ route('citizen.announcements') }}' },
            { en: 'Events', fil: 'Mga Kaganapan', icon: 'calendar', href: '{{ route('citizen.events') }}' },
            { en: 'Government Directory', fil: 'Direktoryo ng Pamahalaan', icon: 'building-2', href: '{{ route('citizen.directory') }}' },
            { en: 'Help & Support', fil: 'Suporta', icon: 'life-buoy', href: '{{ route('citizen.faqs') }}' },
            { en: 'My Profile', fil: 'Aking Profile', icon: 'user-round', href: '{{ route('citizen.profile') }}' },
            { en: 'Notifications', fil: 'Mga Abiso', icon: 'bell', href: '{{ route('citizen.notifications') }}' },
            { en: 'Settings', fil: 'Mga Setting', icon: 'settings', href: '{{ route('citizen.settings') }}' },
        ],
        get filteredSearch() {
            const q = this.searchQuery.trim().toLowerCase();
            if (q === '') return [];
            return this.searchIndex.filter(i => i.en.toLowerCase().includes(q) || i.fil.toLowerCase().includes(q));
        },
    }"
    x-init="setInterval(() => time = new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit' }), 1000)"
>
    <div class="flex items-center gap-3 min-w-0">
        <button @click="mobileOpen = true" class="lg:hidden p-2 -ml-2 rounded-lg text-slate-500 hover:bg-slate-100">
            <i data-lucide="menu" class="w-5 h-5"></i>
        </button>
        <div class="min-w-0">
            <h1 class="text-base lg:text-lg font-semibold text-navy-900 truncate" x-text="$store.lang.current === 'en' ? @js($title) : @js($filTitle)">{{ $filTitle }}</h1>
            @if($subtitle)
                <p class="text-xs text-slate-400 truncate" x-text="$store.lang.current === 'en' ? @js($subtitle) : @js($filSubtitle)">{{ $filSubtitle }}</p>
            @endif
        </div>
    </div>

    <div class="flex items-center gap-1.5 lg:gap-2.5">
        <div class="hidden xl:flex items-center gap-1.5 font-mono text-xs text-slate-400 tabular-nums px-2.5 py-1.5 rounded-xl bg-slate-100/70">
            <i data-lucide="clock" class="w-3.5 h-3.5"></i>
            <span x-text="time"></span>
        </div>

        <div class="hidden md:block relative" @click.outside="searchOpen = false">
            <div class="flex items-center relative">
                <i data-lucide="search" class="w-4 h-4 text-slate-400 absolute left-3.5 pointer-events-none"></i>
                <input
                    type="text"
                    x-model="searchQuery"
                    @focus="searchOpen = true"
                    x-bind:placeholder="$store.lang.current === 'en' ? 'Search dokyu, tulong, balita...' : 'Maghanap ng dokyu, tulong, balita...'"
                    class="w-52 lg:w-72 pl-10 pr-4 py-2 text-sm rounded-xl bg-slate-100/80 border border-transparent focus:bg-white focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200"
                >
            </div>
            <div
                x-show="searchOpen && searchQuery.trim() !== ''"
                x-transition:enter="transition ease-out duration-150"
                x-transition:enter-start="opacity-0 scale-95 -translate-y-1"
                x-transition:enter-end="opacity-100 scale-100 translate-y-0"
                x-cloak
                class="absolute left-0 right-0 mt-2 bg-white rounded-2xl shadow-float border border-slate-100 overflow-hidden z-50 origin-top"
            >
                <template x-for="item in filteredSearch" :key="item.href">
                    <a :href="item.href" class="flex items-center gap-2.5 px-4 py-2.5 text-sm text-slate-600 hover:bg-slate-50 transition-colors">
                        <i :data-lucide="item.icon" class="w-4 h-4 text-slate-400 shrink-0"></i>
                        <span x-text="$store.lang.current === 'en' ? item.en : item.fil"></span>
                    </a>
                </template>
                <p class="px-4 py-3 text-xs text-slate-400" x-show="filteredSearch.length === 0">
                    <x-ui.t fil="Walang nahanap." en="No matches found." />
                </p>
            </div>
        </div>

        <div class="relative" x-data="dropdown" @click.outside="close">
            <div x-data="{ removed: [] }">
                <button @click="toggle" class="relative p-2.5 rounded-xl text-slate-500 hover:bg-slate-100 transition-colors">
                    <i data-lucide="bell" class="w-5 h-5"></i>
                    <span class="absolute top-1.5 right-1.5 flex w-2 h-2" x-show="removed.length < {{ count($notifications) }}">
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
                        <p class="text-sm font-semibold text-navy-900" x-text="$store.lang.current === 'en' ? 'Notifications' : 'Mga Abiso'"></p>
                        <span class="text-xs font-medium text-brand-600 bg-brand-50 px-2 py-0.5 rounded-full" x-text="({{ count($notifications) }} - removed.length) + ($store.lang.current === 'en' ? ' new' : ' bago')"></span>
                    </div>
                    <div class="max-h-80 overflow-y-auto scrollbar-thin divide-y divide-slate-50">
                        @foreach($notifications as $n)
                            <div x-show="!removed.includes({{ $loop->index }})" class="group relative flex items-start gap-3 px-4 py-3 hover:bg-slate-50 transition-colors">
                                <a
                                    href="{{ route('citizen.notifications') }}"
                                    @if($n['popup']) @click.prevent="$dispatch('{{ $n['popup'] }}'); close()" @endif
                                    class="flex items-start gap-3 flex-1 min-w-0"
                                >
                                    <span class="w-9 h-9 rounded-lg {{ $n['color'] }} flex items-center justify-center shrink-0">
                                        <i data-lucide="{{ $n['icon'] }}" class="w-4 h-4"></i>
                                    </span>
                                    <span class="min-w-0">
                                        <span
                                            class="block text-sm font-medium text-slate-700 truncate"
                                            @if($n['popup'] === 'show-birthday-popup') x-text="'Happy Birthday, ' + ($store.citizenSession.account?.firstName ?? 'Resident') + '! 🎉'" @endif
                                        >{{ $n['popup'] === 'show-birthday-popup' ? '' : $n['title'] }}</span>
                                        <span class="block text-xs text-slate-400 mt-0.5 line-clamp-2">{{ $n['body'] }}</span>
                                        <span class="block text-[11px] text-slate-300 mt-1">{{ $n['time'] }}</span>
                                    </span>
                                </a>
                                @if(!$n['pinned'])
                                    <button
                                        type="button"
                                        @click.prevent.stop="removed.push({{ $loop->index }})"
                                        class="opacity-0 group-hover:opacity-100 text-slate-300 hover:text-rose-500 transition-opacity shrink-0 mt-0.5"
                                    ><i data-lucide="x" class="w-3.5 h-3.5"></i></button>
                                @endif
                            </div>
                        @endforeach
                    </div>
                    <a href="{{ route('citizen.notifications') }}" class="block text-center text-sm font-medium text-brand-600 py-3 border-t border-slate-100 hover:bg-slate-50 transition-colors">
                        <x-ui.t fil="Tingnan lahat ng abiso" en="View all notifications" />
                    </a>
                </div>
            </div>
        </div>

        <div class="w-px h-8 bg-slate-200 hidden sm:block"></div>

        <div class="relative" x-data="dropdown" @click.outside="close">
            <button @click="toggle" class="flex items-center gap-2 pl-1 pr-2.5 py-1 rounded-xl hover:bg-slate-100 transition-colors">
                <div class="w-8 h-8 rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold ring-2 ring-white shadow-sm shrink-0 text-xs" x-text="$store.citizenSession.initials()"></div>
                <span class="hidden lg:block text-left max-w-[130px]">
                    <span class="block text-sm font-medium text-navy-900 leading-tight truncate" x-text="$store.citizenSession.account?.fullName ?? 'Guest Citizen'"></span>
                    <span class="block text-xs text-slate-400 leading-tight truncate" x-text="$store.citizenSession.account ? (($store.lang.current === 'en' ? 'Resident — Brgy. ' : 'Residente — Brgy. ') + $store.citizenSession.account.barangay) : ($store.lang.current === 'en' ? 'Not signed in' : 'Hindi naka-sign in')"></span>
                </span>
                <i data-lucide="chevron-down" class="w-4 h-4 text-slate-400 hidden lg:block transition-transform duration-200" :class="open && 'rotate-180'"></i>
            </button>

            <div
                x-show="open"
                x-transition:enter="transition ease-out duration-150"
                x-transition:enter-start="opacity-0 scale-95 -translate-y-1"
                x-transition:enter-end="opacity-100 scale-100 translate-y-0"
                x-cloak
                class="absolute right-0 mt-2 w-60 bg-white rounded-2xl shadow-float border border-slate-100 overflow-hidden z-50 origin-top-right py-1.5"
            >
                <div class="px-4 py-3 border-b border-slate-100">
                    <p class="text-sm font-semibold text-navy-900" x-text="$store.citizenSession.account?.fullName ?? 'Guest Citizen'"></p>
                    <p class="text-xs text-slate-400" x-text="$store.citizenSession.account?.email ?? 'No account selected'"></p>
                </div>
                <a href="{{ route('citizen.profile') }}" class="flex items-center gap-2.5 px-4 py-2.5 text-sm text-slate-600 hover:bg-slate-50 transition-colors">
                    <i data-lucide="user-round" class="w-4 h-4 text-slate-400"></i><x-ui.t fil="Aking Profile" en="My Profile" />
                </a>
                <a href="{{ route('citizen.settings') }}" class="flex items-center gap-2.5 px-4 py-2.5 text-sm text-slate-600 hover:bg-slate-50 transition-colors">
                    <i data-lucide="settings" class="w-4 h-4 text-slate-400"></i><x-ui.t fil="Mga Setting" en="Settings" />
                </a>
                <div class="border-t border-slate-100 my-1.5"></div>
                <a href="{{ route('logout') }}" @click="$store.citizenSession.logout()" class="flex items-center gap-2.5 px-4 py-2.5 text-sm text-rose-600 hover:bg-rose-50 transition-colors">
                    <i data-lucide="log-out" class="w-4 h-4"></i><x-ui.t fil="Mag-sign Out" en="Sign Out" />
                </a>
            </div>
        </div>
    </div>
</header>
