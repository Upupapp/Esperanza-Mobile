@php
    $permissionModules = config('esperanza_rbac.permission_modules');

    $docStatus = [
        ['label' => 'Completed', 'value' => 612, 'color' => '#22c55e'],
        ['label' => 'Processing', 'value' => 348, 'color' => '#2f62f5'],
        ['label' => 'Pending Review', 'value' => 254, 'color' => '#f59e0b'],
        ['label' => 'Rejected', 'value' => 70, 'color' => '#f43f5e'],
    ];
    $docStatusTotal = array_sum(array_column($docStatus, 'value'));

    $assistStatus = [
        ['label' => 'Released', 'value' => 168, 'color' => '#0d9488'],
        ['label' => 'Approved', 'value' => 96, 'color' => '#22c55e'],
        ['label' => 'Processing', 'value' => 104, 'color' => '#2f62f5'],
        ['label' => 'Waiting Requirements', 'value' => 49, 'color' => '#f97316'],
    ];
    $assistStatusTotal = array_sum(array_column($assistStatus, 'value'));

    $barangayRequests = [
        ['name' => 'Poblacion', 'count' => 182, 'pct' => 78],
        ['name' => 'Masbaranon', 'count' => 146, 'pct' => 64],
        ['name' => 'Baras', 'count' => 121, 'pct' => 58],
        ['name' => 'Domorog', 'count' => 108, 'pct' => 52],
        ['name' => 'Agoho', 'count' => 97, 'pct' => 46],
        ['name' => 'Iligan', 'count' => 89, 'pct' => 41],
    ];

    $trendLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
    $trendDocuments = [140, 168, 190, 205, 230, 255, 268];
    $trendAssistance = [40, 52, 58, 66, 71, 80, 86];

    $alerts = [
        ['icon' => 'triangle-alert', 'color' => 'text-rose-600 bg-rose-50', 'title' => '23 document requests pending over 5 days', 'body' => 'Immediate attention required', 'time' => 'Jul 10, 2026', 'link' => 'admin.document-requests'],
        ['icon' => 'circle-alert', 'color' => 'text-amber-600 bg-amber-50', 'title' => 'Resident profiling in 4 barangays below 60%', 'body' => 'Field verification needed', 'time' => 'Jul 10, 2026', 'link' => 'admin.resident-profiling'],
        ['icon' => 'file-clock', 'color' => 'text-brand-600 bg-brand-50', 'title' => '9 assistance requests awaiting budget clearance', 'body' => 'Action needed to avoid delays', 'time' => 'Jul 9, 2026', 'link' => 'admin.assistance-requests'],
        ['icon' => 'circle-check', 'color' => 'text-emerald-600 bg-emerald-50', 'title' => 'Q2 citizen satisfaction survey results are in', 'body' => 'Ready to share with department heads', 'time' => 'Jul 8, 2026', 'link' => 'admin.reports'],
    ];

    $activities = [
        ['icon' => 'circle-check', 'color' => 'text-emerald-600 bg-emerald-50', 'title' => 'Barangay Clearance released', 'body' => 'Request #DR-2026-1042 — Brgy. Poblacion', 'time' => '12 minutes ago', 'link' => 'admin.document-requests'],
        ['icon' => 'file-text', 'color' => 'text-brand-600 bg-brand-50', 'title' => 'New document request submitted', 'body' => 'Business Permit — Rosemarie Tan, Brgy. Baras', 'time' => '38 minutes ago', 'link' => 'admin.document-requests'],
        ['icon' => 'hand-heart', 'color' => 'text-purple-600 bg-purple-50', 'title' => 'Assistance request approved', 'body' => 'Medical Assistance — Rodrigo Palma, Brgy. Domorog', 'time' => '1 hour ago', 'link' => 'admin.assistance-requests'],
        ['icon' => 'megaphone', 'color' => 'text-gold-700 bg-gold-50', 'title' => 'Announcement published', 'body' => '"Fiesta ng Esperanza 2026" schedule posted', 'time' => '3 hours ago', 'link' => 'admin.communications'],
        ['icon' => 'user-round-search', 'color' => 'text-indigo-600 bg-indigo-50', 'title' => 'Resident profile updated', 'body' => '12 new records added — Brgy. Masbaranon', 'time' => '5 hours ago', 'link' => 'admin.constituents'],
    ];
@endphp

<x-layouts.admin title="Executive Dashboard" subtitle="Overview of citizen services and municipal operations." active="dashboard">
    <div x-data="{ ready: false, modules: @js($permissionModules) }" x-init="setTimeout(() => ready = true, 550)">

        <!-- Welcome hero — reflects whichever sample account is signed in -->
        <div x-show="$store.session.account" x-cloak class="relative rounded-2xl overflow-hidden mb-4 bg-gradient-to-br from-navy-900 via-navy-800 to-brand-700 shadow-card animate-fade-up">
            <div class="absolute inset-0 opacity-20 bg-[radial-gradient(circle_at_top_right,theme(colors.white),transparent_55%)] pointer-events-none"></div>
            <div class="relative px-5 py-6 sm:px-7 sm:py-7 flex flex-col lg:flex-row lg:items-center gap-5">
                <div class="flex items-center gap-4 flex-1 min-w-0">
                    <div class="w-14 h-14 text-lg rounded-full bg-white/15 backdrop-blur border-2 border-white/40 text-white flex items-center justify-center font-semibold shadow-lg shrink-0" x-text="$store.session.initials()"></div>
                    <div class="min-w-0">
                        <p class="text-[11px] font-medium text-white/50 uppercase tracking-wide">{{ now()->format('l, F j') }}</p>
                        <h2 class="text-xl font-semibold text-white truncate">
                            <span x-text="'Good day, ' + $store.session.account?.name"></span>
                        </h2>
                        <p class="text-sm text-white/60 mt-0.5 flex flex-wrap items-center gap-x-2 gap-y-1">
                            <span x-text="$store.session.account?.role + ' · ' + $store.session.account?.dept"></span>
                            <span class="text-white/30">·</span>
                            <span class="font-mono" x-text="$store.session.account?.id"></span>
                        </p>
                    </div>
                </div>

                <div class="flex flex-wrap items-center gap-1.5">
                    <span
                        class="inline-flex items-center gap-1.5 text-[11px] font-medium rounded-full px-2.5 py-1 shrink-0 bg-white/10 text-white border border-white/20"
                    >
                        <i :data-lucide="$store.session.account?.scope === 'Municipal' ? 'landmark' : 'map-pin'" class="w-3 h-3"></i>
                        <span x-text="$store.session.account?.scope === 'Municipal' ? 'Municipality-wide access' : 'Brgy. ' + $store.session.account?.scope + ' only'"></span>
                    </span>
                    <template x-for="mod in modules.filter(m => $store.session.can(m.key))" :key="mod.key">
                        <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-white/10 text-white/80 text-[10.5px] font-medium border border-white/10">
                            <i :data-lucide="mod.icon" class="w-3 h-3"></i>
                            <span x-text="mod.name"></span>
                        </span>
                    </template>
                </div>
            </div>
        </div>

        <div class="flex items-center justify-between mb-4">
            <p class="text-sm text-slate-400">Real-time overview of citizen services and municipal operations.</p>
            <div class="flex items-center gap-2">
                <div class="relative" x-data="{ open: false, range: 'This Quarter (Jul–Sep 2026)' }" @click.outside="open = false">
                    <button
                        @click="open = !open"
                        class="inline-flex items-center gap-2 text-sm text-slate-500 bg-white border border-slate-200 rounded-xl px-3 py-1.5 shadow-card hover:border-slate-300 transition-colors"
                    >
                        <i data-lucide="calendar" class="w-4 h-4 text-slate-400"></i>
                        <span x-text="range"></span>
                        <i data-lucide="chevron-down" class="w-3.5 h-3.5 text-slate-400 transition-transform duration-200" :class="open && 'rotate-180'"></i>
                    </button>
                    <div
                        x-show="open"
                        x-cloak
                        x-transition:enter="transition ease-out duration-150"
                        x-transition:enter-start="opacity-0 scale-95 -translate-y-1"
                        x-transition:enter-end="opacity-100 scale-100 translate-y-0"
                        class="absolute right-0 mt-2 w-64 bg-white rounded-2xl shadow-float border border-slate-100 overflow-hidden z-30 origin-top-right py-1.5"
                    >
                        @foreach(['Today', 'This Week', 'This Month', 'This Quarter (Jul–Sep 2026)', 'This Year', 'All Time'] as $opt)
                            <button
                                @click="range = '{{ $opt }}'; open = false; $dispatch('toast', { message: 'Showing data for {{ $opt }}.', variant: 'info' })"
                                class="w-full text-left px-4 py-2 text-sm transition-colors hover:bg-slate-50"
                                :class="range === '{{ $opt }}' ? 'text-brand-600 font-medium bg-brand-50/60' : 'text-slate-600'"
                            >{{ $opt }}</button>
                        @endforeach
                    </div>
                </div>
                <x-ui.button :href="route('admin.reports')" variant="secondary" size="sm" icon="download">Export Report</x-ui.button>
            </div>
        </div>

        <!-- Skeleton state -->
        <div x-show="!ready" x-transition.opacity.duration.300ms>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-3.5 mb-4">
                @for ($i = 0; $i < 6; $i++)
                    <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4 space-y-3">
                        <x-ui.skeleton class="w-10 h-10 rounded-xl" />
                        <x-ui.skeleton class="h-6 w-16" />
                        <x-ui.skeleton class="h-3 w-24" />
                    </div>
                @endfor
            </div>
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-4">
                @for ($i = 0; $i < 3; $i++)
                    <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-5 space-y-4">
                        <x-ui.skeleton class="h-4 w-40" />
                        <x-ui.skeleton class="h-40 w-40 rounded-full mx-auto" />
                    </div>
                @endfor
            </div>
        </div>

        <!-- Real content -->
        <div x-show="ready" x-cloak x-transition:enter="transition ease-out duration-500" x-transition:enter-start="opacity-0 translate-y-2" x-transition:enter-end="opacity-100 translate-y-0">

            <!-- KPI row -->
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-3.5 mb-4">
                <div x-show="$store.session.can('constituents')" x-cloak><x-ui.stat-card :href="route('admin.constituents')" label="Registered Residents" value="17,842" icon="users" color="brand" trend="+312" sublabel="Across 20 barangays" :delay="0" /></div>
                <div x-show="$store.session.can('dokyu')" x-cloak><x-ui.stat-card :href="route('admin.document-requests')" label="Dokyu" value="1,284" icon="file-text" color="green" trend="+8.4%" sublabel="This month" :delay="40" /></div>
                <div x-show="$store.session.can('dokyu') || $store.session.can('tulong')" x-cloak><x-ui.stat-card :href="route('admin.document-requests')" label="Pending Approvals" value="63" icon="inbox" color="orange" sublabel="Needs action today" :delay="80" /></div>
                <div x-show="$store.session.can('tulong')" x-cloak><x-ui.stat-card :href="route('admin.assistance-requests')" label="Tulong" value="417" icon="hand-heart" color="purple" sublabel="Currently active" :delay="120" /></div>
                <div x-show="$store.session.can('communications')" x-cloak><x-ui.stat-card :href="route('admin.communications')" label="Balita" value="28" icon="megaphone" color="gold" sublabel="Published this year" :delay="160" /></div>
                <div x-show="$store.session.can('dokyu')" x-cloak><x-ui.stat-card :href="route('admin.analytics')" label="Avg. Processing Time" value="2.4 days" icon="timer" color="red" trend="-0.6 days" trendDirection="down" sublabel="Document requests" :delay="200" /></div>
            </div>

            <!-- Middle row: donuts + barangay list -->
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-4">
                <div x-show="$store.session.can('dokyu')" x-cloak>
                <x-ui.card>
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="font-semibold text-navy-900">Dokyu</h3>
                        <a href="{{ route('admin.document-requests') }}" class="text-xs font-medium text-brand-600 hover:underline">View Details</a>
                    </div>
                    <div
                        class="relative w-40 h-40 mx-auto"
                        x-data="donutChart({ labels: @js(array_column($docStatus, 'label')), values: @js(array_column($docStatus, 'value')), colors: @js(array_column($docStatus, 'color')) })"
                    >
                        <canvas x-ref="canvas"></canvas>
                        <div class="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                            <span class="text-2xl font-semibold text-navy-900 tabular-nums">{{ number_format($docStatusTotal) }}</span>
                            <span class="text-[11px] text-slate-400">Total Requests</span>
                        </div>
                    </div>
                    <div class="mt-4 space-y-2.5">
                        @foreach($docStatus as $row)
                            <div class="flex items-center justify-between text-sm">
                                <span class="flex items-center gap-2 text-slate-500">
                                    <span class="w-2 h-2 rounded-full" style="background-color: {{ $row['color'] }}"></span>
                                    {{ $row['label'] }}
                                </span>
                                <span class="font-medium text-navy-900 tabular-nums">{{ number_format($row['value']) }}</span>
                            </div>
                        @endforeach
                    </div>
                </x-ui.card>
                </div>

                <div x-show="$store.session.can('tulong')" x-cloak>
                <x-ui.card>
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="font-semibold text-navy-900">Tulong</h3>
                        <a href="{{ route('admin.assistance-requests') }}" class="text-xs font-medium text-brand-600 hover:underline">View Details</a>
                    </div>
                    <div
                        class="relative w-40 h-40 mx-auto"
                        x-data="donutChart({ labels: @js(array_column($assistStatus, 'label')), values: @js(array_column($assistStatus, 'value')), colors: @js(array_column($assistStatus, 'color')) })"
                    >
                        <canvas x-ref="canvas"></canvas>
                        <div class="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                            <span class="text-2xl font-semibold text-navy-900 tabular-nums">{{ number_format($assistStatusTotal) }}</span>
                            <span class="text-[11px] text-slate-400">Active Cases</span>
                        </div>
                    </div>
                    <div class="mt-4 space-y-2.5">
                        @foreach($assistStatus as $row)
                            <div class="flex items-center justify-between text-sm">
                                <span class="flex items-center gap-2 text-slate-500">
                                    <span class="w-2 h-2 rounded-full" style="background-color: {{ $row['color'] }}"></span>
                                    {{ $row['label'] }}
                                </span>
                                <span class="font-medium text-navy-900 tabular-nums">{{ number_format($row['value']) }}</span>
                            </div>
                        @endforeach
                    </div>
                </x-ui.card>
                </div>

                <div x-show="$store.session.can('dokyu') || $store.session.can('tulong') || $store.session.can('constituents')" x-cloak>
                <x-ui.card>
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="font-semibold text-navy-900">Requests by Barangay</h3>
                        <a href="{{ route('admin.directory') }}" class="text-xs font-medium text-brand-600 hover:underline">View All</a>
                    </div>
                    <div class="space-y-4">
                        @foreach($barangayRequests as $brgy)
                            <div x-show="$store.session.inScope('{{ $brgy['name'] }}')" x-cloak>
                                <div class="flex items-center justify-between text-sm mb-1.5">
                                    <span class="text-slate-600 font-medium">Brgy. {{ $brgy['name'] }}</span>
                                    <span class="text-slate-400">{{ $brgy['count'] }} requests</span>
                                </div>
                                <div class="h-1.5 rounded-full bg-slate-100 overflow-hidden">
                                    <div class="h-full rounded-full bg-gradient-to-r from-brand-500 to-brand-400 transition-all duration-700 ease-out" style="width: 0%" x-init="setTimeout(() => $el.style.width = '{{ $brgy['pct'] }}%', 100)"></div>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </x-ui.card>
                </div>
            </div>

            <!-- Bottom row: trend, alerts, activity -->
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
                <div x-show="$store.session.can('dokyu') || $store.session.can('tulong')" x-cloak>
                <x-ui.card>
                    <div class="flex items-center justify-between mb-1">
                        <h3 class="font-semibold text-navy-900">Requests Trend (YTD)</h3>
                    </div>
                    <div class="flex items-center gap-4 text-xs text-slate-400 mb-4">
                        <span class="flex items-center gap-1.5"><span class="w-2 h-2 rounded-full bg-brand-500"></span>Dokyu</span>
                        <span class="flex items-center gap-1.5"><span class="w-2 h-2 rounded-full bg-purple-500"></span>Tulong</span>
                    </div>
                    <div class="h-52" x-data="lineChart({
                        labels: @js($trendLabels),
                        datasets: [
                            { label: 'Dokyu', data: @js($trendDocuments), color: '#2f62f5', fill: 'rgba(47,98,245,0.08)' },
                            { label: 'Tulong', data: @js($trendAssistance), color: '#a855f7', fill: 'rgba(168,85,247,0.06)' },
                        ],
                    })">
                        <canvas x-ref="canvas"></canvas>
                    </div>
                </x-ui.card>
                </div>

                <x-ui.card padded="false">
                    <div class="flex items-center justify-between px-4 pt-3.5 pb-2">
                        <h3 class="font-semibold text-navy-900">Key Alerts</h3>
                        <span class="text-xs font-medium text-rose-600 bg-rose-50 px-2 py-0.5 rounded-full">{{ count($alerts) }}</span>
                    </div>
                    <div class="divide-y divide-slate-50">
                        @foreach($alerts as $alert)
                            <a href="{{ route($alert['link']) }}" class="flex items-start gap-3 px-4 py-2.5 hover:bg-slate-50/70 transition-colors">
                                <span class="w-8 h-8 rounded-lg {{ $alert['color'] }} flex items-center justify-center shrink-0">
                                    <i data-lucide="{{ $alert['icon'] }}" class="w-4 h-4"></i>
                                </span>
                                <div class="min-w-0">
                                    <p class="text-sm font-medium text-slate-700 leading-snug">{{ $alert['title'] }}</p>
                                    <p class="text-xs text-slate-400 mt-0.5">{{ $alert['body'] }}</p>
                                    <p class="text-[11px] text-slate-300 mt-1">{{ $alert['time'] }}</p>
                                </div>
                            </a>
                        @endforeach
                    </div>
                </x-ui.card>

                <x-ui.card padded="false">
                    <div class="flex items-center justify-between px-4 pt-3.5 pb-2">
                        <h3 class="font-semibold text-navy-900">Recent Activity</h3>
                        <a href="{{ route('admin.audit-logs') }}" class="text-xs font-medium text-brand-600 hover:underline">View All</a>
                    </div>
                    <div class="divide-y divide-slate-50">
                        @foreach($activities as $activity)
                            <a href="{{ route($activity['link']) }}" class="flex items-start gap-3 px-4 py-2.5 hover:bg-slate-50/70 transition-colors">
                                <span class="w-8 h-8 rounded-lg {{ $activity['color'] }} flex items-center justify-center shrink-0">
                                    <i data-lucide="{{ $activity['icon'] }}" class="w-4 h-4"></i>
                                </span>
                                <div class="min-w-0">
                                    <p class="text-sm font-medium text-slate-700 leading-snug">{{ $activity['title'] }}</p>
                                    <p class="text-xs text-slate-400 mt-0.5">{{ $activity['body'] }}</p>
                                    <p class="text-[11px] text-slate-300 mt-1">{{ $activity['time'] }}</p>
                                </div>
                            </a>
                        @endforeach
                    </div>
                </x-ui.card>
            </div>
        </div>
    </div>
</x-layouts.admin>
