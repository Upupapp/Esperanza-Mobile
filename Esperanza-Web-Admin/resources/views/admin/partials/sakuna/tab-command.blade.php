{{--
    resources/views/admin/partials/sakuna/tab-command.blade.php
    Emergency Command Center tab — SAKUNA Disaster Management Module
    @include'd from admin/sakuna.blade.php — Alpine state inherited from parent x-data.
    DO NOT add x-data at the root level of this file.
--}}

@php
    $openCenters = array_values(array_filter($centers, fn($c) => !in_array($c['status'], ['Closed', 'Standby'])));
    $topIncidents = array_slice($incidents, 0, 6);

    $mapMarkers = [
        ['name' => 'Agoho',        'status' => 'Normal',     'statusLabel' => 'No Active Incidents',  'dotColor' => 'bg-emerald-400', 'ringColor' => 'ring-emerald-200', 'pop' => '2,140', 'incidents' => 0, 'evacuees' => 0,   'center' => 'Agoho Covered Court (Standby)', 'pulse' => false],
        ['name' => 'Almero',       'status' => 'Normal',     'statusLabel' => 'No Active Incidents',  'dotColor' => 'bg-emerald-400', 'ringColor' => 'ring-emerald-200', 'pop' => '940',   'incidents' => 0, 'evacuees' => 0,   'center' => '—', 'pulse' => false],
        ['name' => 'Baras',        'status' => 'High Alert', 'statusLabel' => 'Flash Flood',          'dotColor' => 'bg-orange-500',  'ringColor' => 'ring-orange-300',  'pop' => '2,890', 'incidents' => 2, 'evacuees' => 87,  'center' => 'Baras Barangay Hall (Open)', 'pulse' => true],
        ['name' => 'Domorog',      'status' => 'High Alert', 'statusLabel' => 'Landslide',            'dotColor' => 'bg-orange-500',  'ringColor' => 'ring-orange-300',  'pop' => '1,980', 'incidents' => 1, 'evacuees' => 76,  'center' => 'Domorog Multi-Purpose Hall (Open)', 'pulse' => true],
        ['name' => 'Guadalupe',    'status' => 'Monitoring', 'statusLabel' => 'Agri Damage',          'dotColor' => 'bg-amber-400',   'ringColor' => 'ring-amber-200',   'pop' => '1,180', 'incidents' => 1, 'evacuees' => 0,   'center' => '—', 'pulse' => false],
        ['name' => 'Iligan',       'status' => 'Monitoring', 'statusLabel' => 'Power Interruption',   'dotColor' => 'bg-slate-300',   'ringColor' => 'ring-slate-200',   'pop' => '1,640', 'incidents' => 1, 'evacuees' => 54,  'center' => 'Iligan Elementary School (Open)', 'pulse' => false],
        ['name' => 'Labangtaytay', 'status' => 'High Alert', 'statusLabel' => 'Stranded Residents',  'dotColor' => 'bg-amber-500',   'ringColor' => 'ring-amber-300',   'pop' => '1,210', 'incidents' => 1, 'evacuees' => 0,   'center' => '—', 'pulse' => true],
        ['name' => 'Labrador',     'status' => 'Normal',     'statusLabel' => 'No Active Incidents',  'dotColor' => 'bg-emerald-400', 'ringColor' => 'ring-emerald-200', 'pop' => '1,480', 'incidents' => 0, 'evacuees' => 0,   'center' => '—', 'pulse' => false],
        ['name' => 'Libertad',     'status' => 'Normal',     'statusLabel' => 'No Active Incidents',  'dotColor' => 'bg-emerald-400', 'ringColor' => 'ring-emerald-200', 'pop' => '1,320', 'incidents' => 0, 'evacuees' => 0,   'center' => '—', 'pulse' => false],
        ['name' => 'Magsaysay',    'status' => 'Monitoring', 'statusLabel' => 'Flooding (subsiding)', 'dotColor' => 'bg-amber-500',   'ringColor' => 'ring-amber-300',   'pop' => '1,750', 'incidents' => 1, 'evacuees' => 103, 'center' => 'Magsaysay Brgy. Hall (Near Capacity)', 'pulse' => false],
        ['name' => 'Masbaranon',   'status' => 'Critical',   'statusLabel' => 'Severe Flooding',      'dotColor' => 'bg-rose-500',    'ringColor' => 'ring-rose-300',    'pop' => '3,210', 'incidents' => 3, 'evacuees' => 189, 'center' => 'Masbaranon Elem. School (Near Capacity)', 'pulse' => true],
        ['name' => 'Poblacion',    'status' => 'Monitoring', 'statusLabel' => 'Medical Emergency',    'dotColor' => 'bg-amber-400',   'ringColor' => 'ring-amber-200',   'pop' => '4,821', 'incidents' => 2, 'evacuees' => 519, 'center' => 'Poblacion Covered Court + Mun. Gymnasium', 'pulse' => false],
        ['name' => 'Potingbato',   'status' => 'Normal',     'statusLabel' => 'No Active Incidents',  'dotColor' => 'bg-emerald-400', 'ringColor' => 'ring-emerald-200', 'pop' => '980',   'incidents' => 0, 'evacuees' => 0,   'center' => '—', 'pulse' => false],
        ['name' => 'Rizal',        'status' => 'Normal',     'statusLabel' => 'Flood Resolved',       'dotColor' => 'bg-emerald-400', 'ringColor' => 'ring-emerald-200', 'pop' => '1,120', 'incidents' => 1, 'evacuees' => 0,   'center' => '—', 'pulse' => false],
        ['name' => 'San Roque',    'status' => 'High Alert', 'statusLabel' => 'Missing Person',       'dotColor' => 'bg-orange-400',  'ringColor' => 'ring-orange-200',  'pop' => '1,390', 'incidents' => 1, 'evacuees' => 0,   'center' => 'San Roque Parish Hall (Standby)', 'pulse' => true],
        ['name' => 'Santiago',     'status' => 'Monitoring', 'statusLabel' => 'Road Damage',          'dotColor' => 'bg-amber-400',   'ringColor' => 'ring-amber-200',   'pop' => '1,650', 'incidents' => 1, 'evacuees' => 0,   'center' => 'Santiago Brgy. Hall (Closed — No Inspection)', 'pulse' => false],
        ['name' => 'Sorosimbajan', 'status' => 'Normal',     'statusLabel' => 'No Active Incidents',  'dotColor' => 'bg-emerald-400', 'ringColor' => 'ring-emerald-200', 'pop' => '890',   'incidents' => 0, 'evacuees' => 0,   'center' => '—', 'pulse' => false],
        ['name' => 'Tawad',        'status' => 'Normal',     'statusLabel' => 'No Active Incidents',  'dotColor' => 'bg-emerald-400', 'ringColor' => 'ring-emerald-200', 'pop' => '760',   'incidents' => 0, 'evacuees' => 0,   'center' => '—', 'pulse' => false],
        ['name' => 'Tunga',        'status' => 'Normal',     'statusLabel' => 'No Active Incidents',  'dotColor' => 'bg-emerald-400', 'ringColor' => 'ring-emerald-200', 'pop' => '1,040', 'incidents' => 0, 'evacuees' => 0,   'center' => '—', 'pulse' => false],
        ['name' => 'Villa1',       'status' => 'Normal',     'statusLabel' => 'No Active Incidents',  'dotColor' => 'bg-emerald-400', 'ringColor' => 'ring-emerald-200', 'pop' => '830',   'incidents' => 0, 'evacuees' => 0,   'center' => '—', 'pulse' => false],
    ];
@endphp

{{-- ══════════════════════════════════════════════════════════════════════════ --}}
{{-- A. LOADING SKELETON                                                         --}}
{{-- ══════════════════════════════════════════════════════════════════════════ --}}
<div x-show="!ready" class="space-y-5">
    {{-- KPI skeleton --}}
    <div class="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-6 gap-3">
        @for ($i = 0; $i < 6; $i++)
            <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4 space-y-3 animate-pulse">
                <div class="w-10 h-10 bg-slate-100 rounded-xl"></div>
                <div class="h-6 bg-slate-100 rounded-lg w-14"></div>
                <div class="h-3 bg-slate-100 rounded w-20"></div>
                <div class="h-3 bg-slate-100 rounded w-16"></div>
            </div>
        @endfor
    </div>
    {{-- Map skeleton --}}
    <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-5 animate-pulse">
        <div class="flex items-center justify-between mb-4">
            <div class="h-5 bg-slate-100 rounded w-80"></div>
            <div class="flex gap-2">
                @for ($i = 0; $i < 5; $i++)<div class="h-7 bg-slate-100 rounded-lg w-24"></div>@endfor
            </div>
        </div>
        <div class="h-60 bg-slate-100 rounded-xl"></div>
    </div>
    {{-- Incident queue + evac overview skeleton --}}
    <div class="grid grid-cols-1 lg:grid-cols-5 gap-5">
        <div class="lg:col-span-3 bg-white rounded-2xl border border-slate-100 shadow-card p-5 space-y-3 animate-pulse">
            <div class="h-5 bg-slate-100 rounded w-48 mb-2"></div>
            @for ($i = 0; $i < 6; $i++)
                <div class="h-11 bg-slate-100 rounded-xl"></div>
            @endfor
        </div>
        <div class="lg:col-span-2 bg-white rounded-2xl border border-slate-100 shadow-card p-5 space-y-3 animate-pulse">
            <div class="h-5 bg-slate-100 rounded w-48 mb-2"></div>
            @for ($i = 0; $i < 5; $i++)
                <div class="h-16 bg-slate-100 rounded-xl"></div>
            @endfor
        </div>
    </div>
    {{-- Alerts skeleton --}}
    <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-5 space-y-3 animate-pulse">
        <div class="h-5 bg-slate-100 rounded w-40 mb-2"></div>
        @for ($i = 0; $i < 5; $i++)
            <div class="h-12 bg-slate-100 rounded-xl"></div>
        @endfor
    </div>
    {{-- Activity + decisions skeleton --}}
    <div class="grid grid-cols-1 lg:grid-cols-5 gap-5">
        <div class="lg:col-span-3 bg-white rounded-2xl border border-slate-100 shadow-card p-5 space-y-4 animate-pulse">
            <div class="h-5 bg-slate-100 rounded w-40 mb-2"></div>
            @for ($i = 0; $i < 6; $i++)
                <div class="h-12 bg-slate-100 rounded-xl"></div>
            @endfor
        </div>
        <div class="lg:col-span-2 bg-white rounded-2xl border border-slate-100 shadow-card p-5 space-y-3 animate-pulse">
            <div class="h-5 bg-slate-100 rounded w-40 mb-2"></div>
            @for ($i = 0; $i < 4; $i++)
                <div class="h-20 bg-slate-100 rounded-xl"></div>
            @endfor
        </div>
    </div>
</div>

{{-- ══════════════════════════════════════════════════════════════════════════ --}}
{{-- B. MAIN CONTENT                                                              --}}
{{-- ══════════════════════════════════════════════════════════════════════════ --}}
<div
    x-show="ready"
    x-cloak
    x-transition:enter="transition ease-out duration-500"
    x-transition:enter-start="opacity-0 translate-y-2"
    x-transition:enter-end="opacity-100 translate-y-0"
    class="space-y-5"
>

    {{-- ── B1. KPI Cards ──────────────────────────────────────────────────── --}}
    <div class="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-6 gap-3">

        {{-- Active Incidents --}}
        <div class="group bg-white rounded-2xl border border-slate-100 shadow-card hover:shadow-card-hover transition-all duration-300 p-4">
            <div class="w-10 h-10 rounded-xl bg-rose-50 flex items-center justify-center transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-3">
                <i data-lucide="flame" class="w-5 h-5 text-rose-600"></i>
            </div>
            <p class="mt-3 text-2xl font-bold text-slate-800 tabular-nums tracking-tight">14</p>
            <p class="text-[10px] font-semibold text-slate-400 uppercase tracking-wide mt-0.5">Active Incidents</p>
            <p class="text-xs text-rose-600 mt-0.5 font-medium">3 critical</p>
        </div>

        {{-- High-Risk Barangays --}}
        <div class="group bg-white rounded-2xl border border-slate-100 shadow-card hover:shadow-card-hover transition-all duration-300 p-4">
            <div class="w-10 h-10 rounded-xl bg-orange-50 flex items-center justify-center transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-3">
                <i data-lucide="map-pin" class="w-5 h-5 text-orange-600"></i>
            </div>
            <p class="mt-3 text-2xl font-bold text-slate-800 tabular-nums tracking-tight">7</p>
            <p class="text-[10px] font-semibold text-slate-400 uppercase tracking-wide mt-0.5">High-Risk Barangays</p>
            <p class="text-xs text-orange-600 mt-0.5 font-medium">2 elevated today</p>
        </div>

        {{-- Families Evacuated --}}
        <div class="group bg-white rounded-2xl border border-slate-100 shadow-card hover:shadow-card-hover transition-all duration-300 p-4">
            <div class="w-10 h-10 rounded-xl bg-blue-50 flex items-center justify-center transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-3">
                <i data-lucide="house" class="w-5 h-5 text-blue-600"></i>
            </div>
            <p class="mt-3 text-2xl font-bold text-slate-800 tabular-nums tracking-tight">312</p>
            <p class="text-[10px] font-semibold text-slate-400 uppercase tracking-wide mt-0.5">Families Evacuated</p>
            <p class="text-xs text-blue-600 mt-0.5 font-medium">68% center occupancy</p>
        </div>

        {{-- Open Evacuation Centers --}}
        <div class="group bg-white rounded-2xl border border-slate-100 shadow-card hover:shadow-card-hover transition-all duration-300 p-4">
            <div class="w-10 h-10 rounded-xl bg-emerald-50 flex items-center justify-center transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-3">
                <i data-lucide="building-2" class="w-5 h-5 text-emerald-600"></i>
            </div>
            <p class="mt-3 text-2xl font-bold text-slate-800 tabular-nums tracking-tight">8</p>
            <p class="text-[10px] font-semibold text-slate-400 uppercase tracking-wide mt-0.5">Evac. Centers Open</p>
            <p class="text-xs text-amber-600 mt-0.5 font-medium">4 near capacity</p>
        </div>

        {{-- Responders Deployed --}}
        <div class="group bg-white rounded-2xl border border-slate-100 shadow-card hover:shadow-card-hover transition-all duration-300 p-4">
            <div class="w-10 h-10 rounded-xl bg-purple-50 flex items-center justify-center transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-3">
                <i data-lucide="shield" class="w-5 h-5 text-purple-600"></i>
            </div>
            <p class="mt-3 text-2xl font-bold text-slate-800 tabular-nums tracking-tight">24</p>
            <p class="text-[10px] font-semibold text-slate-400 uppercase tracking-wide mt-0.5">Responders Deployed</p>
            <p class="text-xs text-purple-600 mt-0.5 font-medium">4 vehicles active</p>
        </div>

        {{-- Unresolved Priority Needs --}}
        <div class="group bg-white rounded-2xl border border-slate-100 shadow-card hover:shadow-card-hover transition-all duration-300 p-4">
            <div class="w-10 h-10 rounded-xl bg-amber-50 flex items-center justify-center transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-3">
                <i data-lucide="circle-alert" class="w-5 h-5 text-amber-600"></i>
            </div>
            <p class="mt-3 text-2xl font-bold text-slate-800 tabular-nums tracking-tight">7</p>
            <p class="text-[10px] font-semibold text-slate-400 uppercase tracking-wide mt-0.5">Priority Needs</p>
            <p class="text-xs text-amber-600 mt-0.5 font-medium">3 awaiting action</p>
        </div>

    </div>{{-- /KPI Cards --}}


    {{-- ── B2. Operational Map Panel ───────────────────────────────────────── --}}
    <div
        class="bg-white rounded-2xl border border-slate-100 shadow-card overflow-hidden"
        x-data="{
            layers: { incidents: true, hazard: true, centers: true, rescue: true, roads: false },
            layerLabels: { incidents: 'Incidents', hazard: 'Hazard Zones', centers: 'Evac. Centers', rescue: 'Rescue Units', roads: 'Blocked Roads' },
            layerIcons:  { incidents: 'flame', hazard: 'triangle-alert', centers: 'house', rescue: 'shield', roads: 'road' },
        }"
    >
        {{-- Map header --}}
        <div class="flex flex-wrap items-center justify-between gap-3 px-5 py-4 border-b border-slate-100">
            <div>
                <h3 class="text-sm font-semibold text-slate-800">Operational Map — Municipality of Esperanza</h3>
                <p class="text-xs text-slate-400 mt-0.5">Southwest Monsoon & Flooding — Jul 15, 2026 — 08:26 AM</p>
            </div>
            {{-- Layer toggles --}}
            <div class="flex flex-wrap items-center gap-1.5">
                <template x-for="(label, key) in layerLabels" :key="key">
                    <button
                        @click="layers[key] = !layers[key]"
                        :class="layers[key]
                            ? 'bg-brand-50 border-brand-200 text-brand-700'
                            : 'bg-white border-slate-200 text-slate-400'"
                        class="inline-flex items-center gap-1.5 text-xs font-medium border rounded-lg px-2.5 py-1 transition-colors"
                    >
                        <i :data-lucide="layerIcons[key]" class="w-3 h-3"></i>
                        <span x-text="label"></span>
                    </button>
                </template>
            </div>
        </div>

        {{-- Map grid area --}}
        <div class="p-5">
            <div class="relative bg-slate-50 rounded-2xl border border-slate-100 p-4 overflow-hidden">
                {{-- Background texture lines --}}
                <div class="absolute inset-0 opacity-30" style="background-image: linear-gradient(rgba(203,213,225,0.4) 1px, transparent 1px), linear-gradient(90deg, rgba(203,213,225,0.4) 1px, transparent 1px); background-size: 40px 40px;"></div>

                {{-- North indicator --}}
                <div class="absolute top-3 right-3 flex flex-col items-center gap-0.5 z-10">
                    <div class="w-0 h-0 border-l-4 border-r-4 border-b-8 border-l-transparent border-r-transparent border-b-slate-800 opacity-70"></div>
                    <span class="text-[9px] font-bold text-slate-400">N</span>
                </div>

                {{-- Barangay grid --}}
                <div class="relative z-10 grid grid-cols-4 gap-3 sm:gap-4 min-h-[220px]">
                    @foreach ($mapMarkers as $marker)
                        <div
                            class="flex flex-col items-center gap-1.5 py-2 px-1 rounded-xl transition-all hover:bg-white/70 cursor-default"
                            x-data="{ open: false }"
                            @mouseenter="open = true"
                            @mouseleave="open = false"
                        >
                            {{-- Dot --}}
                            <div class="relative">
                                <div class="w-4 h-4 rounded-full {{ $marker['dotColor'] }} ring-2 {{ $marker['ringColor'] }} ring-offset-1 {{ $marker['pulse'] ? 'animate-pulse' : '' }} shadow-sm"></div>
                                @if ($marker['incidents'] > 0)
                                    <span class="absolute -top-1.5 -right-1.5 w-3.5 h-3.5 bg-white rounded-full border border-slate-200 text-[8px] font-bold flex items-center justify-center text-slate-700">{{ $marker['incidents'] }}</span>
                                @endif
                            </div>
                            {{-- Label --}}
                            <span class="text-[9px] sm:text-[10px] text-center text-slate-600 font-medium leading-tight max-w-[60px]">{{ $marker['name'] }}</span>

                            {{-- Tooltip --}}
                            <div
                                x-show="open"
                                x-cloak
                                x-transition:enter="transition ease-out duration-150"
                                x-transition:enter-start="opacity-0 scale-90"
                                x-transition:enter-end="opacity-100 scale-100"
                                class="absolute z-30 bottom-full mb-2 left-1/2 -translate-x-1/2 bg-slate-800 text-white text-[11px] rounded-xl p-3 w-52 shadow-float pointer-events-none"
                                style="white-space: normal;"
                            >
                                <p class="font-semibold text-xs mb-1">{{ $marker['name'] }}</p>
                                <p class="text-slate-300 mb-0.5">Status: <span class="text-white font-medium">{{ $marker['status'] }}</span></p>
                                <p class="text-slate-300 mb-0.5">{{ $marker['statusLabel'] }}</p>
                                <div class="border-t border-slate-700 mt-1.5 pt-1.5 space-y-0.5">
                                    <p class="text-slate-300">Population: <span class="text-white">{{ $marker['pop'] }}</span></p>
                                    <p class="text-slate-300">Incidents: <span class="text-white">{{ $marker['incidents'] }}</span></p>
                                    <p class="text-slate-300">Evacuees: <span class="text-white">{{ $marker['evacuees'] }}</span></p>
                                </div>
                                @if ($marker['center'] !== '—')
                                    <p class="text-slate-400 text-[10px] mt-1.5 italic">{{ $marker['center'] }}</p>
                                @endif
                            </div>
                        </div>
                    @endforeach
                </div>

                {{-- Legend --}}
                <div class="mt-4 pt-3 border-t border-slate-200 flex flex-wrap gap-x-5 gap-y-1.5">
                    <span class="flex items-center gap-1.5 text-xs text-slate-500"><span class="w-2.5 h-2.5 rounded-full bg-rose-500 flex-shrink-0"></span>Critical Incident</span>
                    <span class="flex items-center gap-1.5 text-xs text-slate-500"><span class="w-2.5 h-2.5 rounded-full bg-orange-500 flex-shrink-0"></span>High Alert</span>
                    <span class="flex items-center gap-1.5 text-xs text-slate-500"><span class="w-2.5 h-2.5 rounded-full bg-amber-400 flex-shrink-0"></span>Monitoring</span>
                    <span class="flex items-center gap-1.5 text-xs text-slate-500"><span class="w-2.5 h-2.5 rounded-full bg-slate-300 flex-shrink-0"></span>Service Issue</span>
                    <span class="flex items-center gap-1.5 text-xs text-slate-500"><span class="w-2.5 h-2.5 rounded-full bg-emerald-400 flex-shrink-0"></span>Normal</span>
                    <span class="ml-auto text-[10px] text-slate-400 italic">Dot badge = active incident count</span>
                </div>
            </div>

            <p class="text-[11px] text-slate-400 mt-2 text-center italic">
                Note: This is a schematic operations panel. A GIS map will be integrated in production.
            </p>
        </div>
    </div>{{-- /Map Panel --}}


    {{-- ── B3. Priority Incident Queue + Evacuation Center Overview ─────────── --}}
    <div class="grid grid-cols-1 lg:grid-cols-5 gap-5">

        {{-- Left: Priority Incident Queue --}}
        <div class="lg:col-span-3 bg-white rounded-2xl border border-slate-100 shadow-card overflow-hidden">
            <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100">
                <div>
                    <h3 class="text-sm font-semibold text-slate-800">Priority Incident Queue</h3>
                    <p class="text-xs text-slate-400 mt-0.5">Top 6 active incidents by severity</p>
                </div>
                <button
                    @click="setTab('incidents')"
                    class="text-xs text-brand-600 hover:text-brand-700 font-medium flex items-center gap-1 transition-colors"
                >
                    View all <i data-lucide="arrow-right" class="w-3.5 h-3.5"></i>
                </button>
            </div>
            <div class="overflow-x-auto">
                <table class="w-full text-sm min-w-[640px]">
                    <thead>
                        <tr class="bg-slate-50 border-b border-slate-100">
                            <th class="text-left px-4 py-2.5 text-xs font-semibold text-slate-400 uppercase tracking-wide">ID</th>
                            <th class="text-left px-4 py-2.5 text-xs font-semibold text-slate-400 uppercase tracking-wide">Type</th>
                            <th class="text-left px-4 py-2.5 text-xs font-semibold text-slate-400 uppercase tracking-wide">Barangay</th>
                            <th class="text-left px-4 py-2.5 text-xs font-semibold text-slate-400 uppercase tracking-wide">Severity</th>
                            <th class="text-right px-4 py-2.5 text-xs font-semibold text-slate-400 uppercase tracking-wide">At Risk</th>
                            <th class="text-left px-4 py-2.5 text-xs font-semibold text-slate-400 uppercase tracking-wide">Status</th>
                            <th class="text-right px-4 py-2.5 text-xs font-semibold text-slate-400 uppercase tracking-wide">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-50">
                        @foreach ($topIncidents as $inc)
                            <tr class="hover:bg-slate-50/60 transition-colors group">
                                <td class="px-4 py-3">
                                    <span class="text-xs font-mono text-slate-500">{{ substr($inc['id'], -4) }}</span>
                                </td>
                                <td class="px-4 py-3">
                                    <span class="text-xs font-medium text-slate-700">{{ $inc['type'] }}</span>
                                </td>
                                <td class="px-4 py-3">
                                    <span class="text-xs text-slate-600">{{ $inc['barangay'] }}</span>
                                </td>
                                <td class="px-4 py-3">
                                    <span class="{{ in_array($inc['severity'], ['Critical', 'High', 'Medium', 'Low']) ? '' : '' }} px-2 py-0.5 rounded-full text-xs font-medium border {{ match($inc['severity']) {
                                        'Critical' => 'bg-rose-100 text-rose-700 border-rose-200',
                                        'High'     => 'bg-orange-100 text-orange-700 border-orange-200',
                                        'Medium'   => 'bg-amber-100 text-amber-700 border-amber-200',
                                        default    => 'bg-slate-100 text-slate-600 border-slate-200',
                                    } }}">{{ $inc['severity'] }}</span>
                                </td>
                                <td class="px-4 py-3 text-right">
                                    <span class="text-xs font-semibold text-slate-700 tabular-nums">{{ $inc['affected'] }}</span>
                                </td>
                                <td class="px-4 py-3">
                                    <span :class="statusBadge('{{ $inc['status'] }}')">{{ $inc['status'] }}</span>
                                </td>
                                <td class="px-4 py-3">
                                    <div class="flex items-center justify-end gap-1.5">
                                        <button
                                            @click="selectedIncident = @js($inc); showIncidentDetail = true; $nextTick(() => window.renderIcons?.())"
                                            class="p-1.5 text-slate-400 hover:text-brand-600 hover:bg-brand-50 rounded-lg transition-colors"
                                            title="View Details"
                                        >
                                            <i data-lucide="eye" class="w-3.5 h-3.5"></i>
                                        </button>
                                        <button
                                            @click="toast('INC {{ $inc['id'] }} validated.', 'success')"
                                            class="p-1.5 text-slate-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors"
                                            title="Validate"
                                        >
                                            <i data-lucide="circle-check" class="w-3.5 h-3.5"></i>
                                        </button>
                                        <button
                                            @click="dispatchTarget = @js($inc); showDispatch = true; $nextTick(() => window.renderIcons?.())"
                                            class="p-1.5 text-slate-400 hover:text-purple-600 hover:bg-purple-50 rounded-lg transition-colors"
                                            title="Dispatch Team"
                                        >
                                            <i data-lucide="send" class="w-3.5 h-3.5"></i>
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>

        {{-- Right: Evacuation Center Overview --}}
        <div class="lg:col-span-2 bg-white rounded-2xl border border-slate-100 shadow-card overflow-hidden">
            <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100">
                <div>
                    <h3 class="text-sm font-semibold text-slate-800">Evacuation Center Status</h3>
                    <p class="text-xs text-slate-400 mt-0.5">{{ count($openCenters) }} open centers</p>
                </div>
                <button
                    @click="setTab('evacuation-centers')"
                    class="text-xs text-brand-600 hover:text-brand-700 font-medium flex items-center gap-1 transition-colors"
                >
                    Manage <i data-lucide="arrow-right" class="w-3.5 h-3.5"></i>
                </button>
            </div>
            <div class="divide-y divide-slate-50 max-h-[340px] overflow-y-auto">
                @foreach ($openCenters as $center)
                    @php
                        $pct = $center['max_capacity'] > 0 ? round($center['occupants'] / $center['max_capacity'] * 100) : 0;
                        $barColor = $pct >= 90 ? 'bg-rose-500' : ($pct >= 75 ? 'bg-orange-400' : ($pct >= 50 ? 'bg-amber-400' : 'bg-emerald-500'));
                    @endphp
                    <div class="px-4 py-3 hover:bg-slate-50/60 transition-colors">
                        <div class="flex items-start justify-between gap-2 mb-2">
                            <div class="min-w-0">
                                <p class="text-xs font-semibold text-slate-700 truncate">{{ $center['name'] }}</p>
                                <p class="text-[11px] text-slate-400 truncate">{{ $center['barangay'] }} &bull; {{ $center['families'] }} families</p>
                            </div>
                            <span :class="statusBadge('{{ $center['status'] }}')">{{ $center['status'] }}</span>
                        </div>
                        <div class="flex items-center gap-2">
                            <div class="flex-1 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                                <div class="h-full {{ $barColor }} rounded-full transition-all" style="width: {{ $pct }}%"></div>
                            </div>
                            <span class="text-[11px] font-semibold text-slate-500 tabular-nums w-10 text-right">{{ $pct }}%</span>
                        </div>
                        <p class="text-[10px] text-slate-400 mt-0.5">{{ $center['occupants'] }} / {{ $center['max_capacity'] }} occupants &bull; {{ $center['pwsn'] }} PWSN</p>
                    </div>
                @endforeach
            </div>
        </div>

    </div>{{-- /Incident Queue + Evac Overview --}}


    {{-- ── B4. Operational Alerts ──────────────────────────────────────────── --}}
    <div class="bg-white rounded-2xl border border-slate-100 shadow-card overflow-hidden">
        <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100">
            <div class="flex items-center gap-2">
                <h3 class="text-sm font-semibold text-slate-800">Operational Alerts</h3>
                <span class="px-2 py-0.5 rounded-full text-xs font-semibold bg-rose-100 text-rose-700">8 active</span>
            </div>
            <button @click="toast('All alerts exported.', 'success')" class="text-xs text-slate-500 hover:text-slate-700 flex items-center gap-1 transition-colors">
                <i data-lucide="download" class="w-3.5 h-3.5"></i> Export
            </button>
        </div>
        <div class="divide-y divide-slate-50">
            @php
                $opAlerts = [
                    ['color' => 'rose',  'icon' => 'triangle-alert', 'msg' => 'Masbaranon Elementary School at 94% capacity — risk of overcrowding. Activate contingency center.', 'time' => '08:15 AM'],
                    ['color' => 'amber', 'icon' => 'package-x',      'msg' => 'ORS (Oral Rehydration) supply at 80 sachets — below reorder level of 100. Request restocking from RHU.', 'time' => '08:12 AM'],
                    ['color' => 'orange','icon' => 'truck',           'msg' => 'Rescue Team Bravo en route to Domorog — ETA unconfirmed due to blocked upland road.', 'time' => '08:05 AM'],
                    ['color' => 'rose',  'icon' => 'clock',           'msg' => 'INC-2026-0073 (Missing Person, San Roque) — unresolved for 17 hours. Escalation required.', 'time' => '07:50 AM'],
                    ['color' => 'amber', 'icon' => 'building',     'msg' => 'Santiago Barangay Hall not inspected in 2026 — cannot be activated as an evacuation center.', 'time' => '07:30 AM'],
                    ['color' => 'slate', 'icon' => 'zap-off',        'msg' => 'INC-2026-0076 (Power Interruption, Iligan) — pending validation. MASELCO follow-up needed.', 'time' => '07:20 AM'],
                    ['color' => 'amber', 'icon' => 'fuel',            'msg' => 'Generator G1 fuel at 40% — needs refueling before next deployment cycle.', 'time' => '07:10 AM'],
                    ['color' => 'orange','icon' => 'calendar-clock',  'msg' => 'EC-005 (Magsaysay) last inspected April 2026 — formal inspection recommended before continued operation.', 'time' => '06:55 AM'],
                ];
                $alertColorMap = [
                    'rose'   => ['bg' => 'bg-rose-50',   'border' => 'border-l-rose-400',   'icon' => 'text-rose-500',   'badge' => 'bg-rose-100 text-rose-700'],
                    'amber'  => ['bg' => 'bg-amber-50',  'border' => 'border-l-amber-400',  'icon' => 'text-amber-500',  'badge' => 'bg-amber-100 text-amber-700'],
                    'orange' => ['bg' => 'bg-orange-50', 'border' => 'border-l-orange-400', 'icon' => 'text-orange-500', 'badge' => 'bg-orange-100 text-orange-700'],
                    'slate'  => ['bg' => 'bg-slate-50',  'border' => 'border-l-slate-300',  'icon' => 'text-slate-400',  'badge' => 'bg-slate-100 text-slate-600'],
                ];
            @endphp
            @foreach ($opAlerts as $a)
                @php $ac = $alertColorMap[$a['color']]; @endphp
                <div class="flex items-start gap-3 px-5 py-3 {{ $ac['bg'] }} border-l-4 {{ $ac['border'] }} hover:brightness-[0.98] transition-all">
                    <i data-lucide="{{ $a['icon'] }}" class="w-4 h-4 {{ $ac['icon'] }} flex-shrink-0 mt-0.5"></i>
                    <p class="text-xs text-slate-700 flex-1 leading-relaxed">{{ $a['msg'] }}</p>
                    <span class="text-[10px] text-slate-400 whitespace-nowrap flex-shrink-0 mt-0.5">{{ $a['time'] }}</span>
                </div>
            @endforeach
        </div>
    </div>{{-- /Operational Alerts --}}


    {{-- ── B5. Recent Activity Feed + Decision Panel ──────────────────────── --}}
    <div class="grid grid-cols-1 lg:grid-cols-5 gap-5">

        {{-- Left: Activity Feed --}}
        <div class="lg:col-span-3 bg-white rounded-2xl border border-slate-100 shadow-card overflow-hidden">
            <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100">
                <h3 class="text-sm font-semibold text-slate-800">Recent Activity Feed</h3>
                <span class="text-[11px] text-slate-400">Last 10 actions</span>
            </div>
            <div class="px-5 py-4 space-y-0">
                @php
                    $feed = [
                        ['icon' => 'circle-check', 'color' => 'bg-emerald-50 text-emerald-600', 'text' => 'INC-2026-0084 validated — Masbaranon flooding confirmed active', 'time' => '08:10 AM'],
                        ['icon' => 'send',           'color' => 'bg-purple-50 text-purple-600',   'text' => 'Rescue Team Alpha dispatched to Masbaranon (INC-2026-0084)', 'time' => '07:58 AM'],
                        ['icon' => 'door-open',      'color' => 'bg-emerald-50 text-emerald-600', 'text' => 'EC-006 (Municipal Gymnasium) officially opened as evacuation center', 'time' => '07:30 AM'],
                        ['icon' => 'users',          'color' => 'bg-blue-50 text-blue-600',       'text' => '7 families checked in — EC-006, Sector 1', 'time' => '07:35 AM'],
                        ['icon' => 'package',        'color' => 'bg-amber-50 text-amber-600',     'text' => 'Relief goods staging commenced at EC-006 (Municipal Gymnasium)', 'time' => '07:40 AM'],
                        ['icon' => 'megaphone',      'color' => 'bg-orange-50 text-orange-600',   'text' => 'Advisory ALT-2026-0023 (Pre-emptive Evacuation, Masbaranon) published', 'time' => '05:30 AM'],
                        ['icon' => 'circle-alert',   'color' => 'bg-rose-50 text-rose-600',       'text' => 'EC-002 (Masbaranon Elem. School) near-capacity alert triggered at 94%', 'time' => '08:15 AM'],
                        ['icon' => 'clipboard-list', 'color' => 'bg-brand-50 text-brand-600',     'text' => 'DNA-2026-0018 (Rapid Assessment — Masbaranon) submitted to PDRRMO', 'time' => '08:20 AM'],
                        ['icon' => 'ambulance',      'color' => 'bg-pink-50 text-pink-600',       'text' => 'Municipal Ambulance dispatched to EC-001 — INC-2026-0080 (Medical)', 'time' => '08:22 AM'],
                        ['icon' => 'bell-ring',      'color' => 'bg-slate-50 text-slate-500',     'text' => 'ALT-2026-0022 (Class Suspension) published — Jul 14, 10:00 PM', 'time' => 'Jul 14'],
                    ];
                @endphp
                @foreach ($feed as $index => $item)
                    <div class="flex items-start gap-3 py-3 {{ !$loop->last ? 'border-b border-slate-50' : '' }}">
                        <div class="relative flex-shrink-0">
                            <div class="w-7 h-7 rounded-xl {{ $item['color'] }} flex items-center justify-center">
                                <i data-lucide="{{ $item['icon'] }}" class="w-3.5 h-3.5"></i>
                            </div>
                            @if (!$loop->last)
                                <div class="absolute left-1/2 -translate-x-1/2 top-7 w-px h-full bg-slate-100 mt-0.5 max-h-[20px]"></div>
                            @endif
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="text-xs text-slate-700 leading-relaxed">{{ $item['text'] }}</p>
                        </div>
                        <span class="text-[10px] text-slate-400 whitespace-nowrap flex-shrink-0 mt-0.5">{{ $item['time'] }}</span>
                    </div>
                @endforeach
            </div>
        </div>

        {{-- Right: Decision Panel --}}
        <div class="lg:col-span-2 bg-white rounded-2xl border border-slate-100 shadow-card overflow-hidden">
            <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100">
                <div class="flex items-center gap-2">
                    <h3 class="text-sm font-semibold text-slate-800">Pending Decisions</h3>
                    <span class="px-1.5 py-0.5 rounded-full text-xs font-bold bg-amber-100 text-amber-700">4</span>
                </div>
                <i data-lucide="gavel" class="w-4 h-4 text-slate-300"></i>
            </div>
            <div class="px-4 py-4 space-y-3">
                @php
                    $decisions = [
                        ['id' => 1, 'title' => 'Open San Roque Parish Hall as additional evacuation center', 'context' => 'Capacity 200 — inspection passed Jun 5, 2026', 'priority' => 'urgent'],
                        ['id' => 2, 'title' => 'Approve pre-emptive evacuation advisory for Santiago upland sitios', 'context' => '285 vulnerable residents, road damage confirmed', 'priority' => 'high'],
                        ['id' => 3, 'title' => 'Request PDRRMO provincial augmentation for rescue boats', 'context' => '2 boats deployed, 1 available — demand exceeds capacity', 'priority' => 'high'],
                        ['id' => 4, 'title' => 'Release 50 family food packs from emergency stockpile', 'context' => '95 packs available, 60 reserved — EC-002 and EC-006 priority', 'priority' => 'normal'],
                    ];
                @endphp
                @foreach ($decisions as $d)
                    <div class="p-3.5 rounded-xl border {{ $d['priority'] === 'urgent' ? 'border-rose-200 bg-rose-50/40' : ($d['priority'] === 'high' ? 'border-amber-200 bg-amber-50/30' : 'border-slate-100 bg-slate-50/40') }}">
                        <div class="flex items-start gap-2 mb-2">
                            <span class="w-5 h-5 rounded-full bg-slate-200 text-slate-600 text-[10px] font-bold flex items-center justify-center flex-shrink-0 mt-0.5">{{ $d['id'] }}</span>
                            <p class="text-xs font-medium text-slate-800 leading-relaxed">{{ $d['title'] }}</p>
                        </div>
                        <p class="text-[11px] text-slate-500 mb-2.5 pl-7">{{ $d['context'] }}</p>
                        <div class="flex gap-2 pl-7">
                            <button
                                @click="toast('Decision approved and logged.', 'success')"
                                class="flex-1 px-3 py-1.5 text-xs font-semibold bg-brand-600 hover:bg-brand-700 text-white rounded-lg transition-colors"
                            >Approve</button>
                            <button
                                @click="toast('Decision deferred.', 'info')"
                                class="flex-1 px-3 py-1.5 text-xs font-medium bg-white hover:bg-slate-50 text-slate-600 border border-slate-200 rounded-lg transition-colors"
                            >Defer</button>
                        </div>
                    </div>
                @endforeach
            </div>
        </div>

    </div>{{-- /Activity + Decisions --}}

</div>{{-- /Main Content --}}


{{-- ══════════════════════════════════════════════════════════════════════════ --}}
{{-- INCIDENT DETAIL MODAL                                                        --}}
{{-- ══════════════════════════════════════════════════════════════════════════ --}}
<div
    x-show="showIncidentDetail"
    x-cloak
    x-transition:enter="transition ease-out duration-200"
    x-transition:enter-start="opacity-0"
    x-transition:enter-end="opacity-100"
    x-transition:leave="transition ease-in duration-150"
    x-transition:leave-start="opacity-100"
    x-transition:leave-end="opacity-0"
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
    @click.self="showIncidentDetail = false"
    @keydown.escape.window="showIncidentDetail = false"
>
    <div
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0 scale-95 translate-y-2"
        x-transition:enter-end="opacity-100 scale-100 translate-y-0"
        x-transition:leave="transition ease-in duration-150"
        x-transition:leave-start="opacity-100 scale-100"
        x-transition:leave-end="opacity-0 scale-95"
        class="bg-white rounded-2xl shadow-float w-full max-w-3xl max-h-[90vh] flex flex-col overflow-hidden"
    >
        {{-- Modal Header --}}
        <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100 flex-shrink-0">
            <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-xl bg-rose-50 flex items-center justify-center">
                    <i data-lucide="flame" class="w-4.5 h-4.5 text-rose-600"></i>
                </div>
                <div>
                    <h2 class="text-base font-semibold text-slate-800" x-text="selectedIncident?.id ?? '—'"></h2>
                    <p class="text-xs text-slate-400 mt-0.5" x-text="(selectedIncident?.type ?? '') + ' — Brgy. ' + (selectedIncident?.barangay ?? '')"></p>
                </div>
            </div>
            <div class="flex items-center gap-2">
                <span :class="statusBadge(selectedIncident?.status ?? '')" x-text="selectedIncident?.status ?? ''"></span>
                <button @click="showIncidentDetail = false" class="w-8 h-8 rounded-xl hover:bg-slate-100 flex items-center justify-center text-slate-400 hover:text-slate-600 transition-colors ml-2">
                    <i data-lucide="x" class="w-4 h-4"></i>
                </button>
            </div>
        </div>

        {{-- Modal Body --}}
        <div class="flex-1 overflow-y-auto px-6 py-5 space-y-5">

            {{-- Section: Description --}}
            <div class="p-4 bg-slate-50 rounded-xl border border-slate-100">
                <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-1.5">Incident Description</p>
                <p class="text-sm text-slate-700 leading-relaxed" x-text="selectedIncident?.description ?? '—'"></p>
            </div>

            {{-- Two-column info --}}
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">

                {{-- Incident Info --}}
                <div class="space-y-3">
                    <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide flex items-center gap-1.5">
                        <i data-lucide="info" class="w-3.5 h-3.5"></i> Incident Information
                    </h4>
                    <dl class="space-y-2.5">
                        <div class="flex items-start justify-between gap-2">
                            <dt class="text-xs text-slate-500 flex-shrink-0">Type</dt>
                            <dd class="text-xs font-medium text-slate-800 text-right" x-text="selectedIncident?.type ?? '—'"></dd>
                        </div>
                        <div class="flex items-start justify-between gap-2">
                            <dt class="text-xs text-slate-500 flex-shrink-0">Severity</dt>
                            <dd>
                                <span
                                    :class="severityBadge(selectedIncident?.severity ?? '') + ' px-2 py-0.5 rounded-full text-xs font-medium border'"
                                    x-text="selectedIncident?.severity ?? '—'"
                                ></span>
                            </dd>
                        </div>
                        <div class="flex items-start justify-between gap-2">
                            <dt class="text-xs text-slate-500 flex-shrink-0">Date Reported</dt>
                            <dd class="text-xs font-medium text-slate-800 text-right" x-text="selectedIncident?.reported ?? '—'"></dd>
                        </div>
                        <div class="flex items-start justify-between gap-2">
                            <dt class="text-xs text-slate-500 flex-shrink-0">Source</dt>
                            <dd class="text-xs font-medium text-slate-800 text-right" x-text="selectedIncident?.source ?? '—'"></dd>
                        </div>
                        <div class="flex items-start justify-between gap-2">
                            <dt class="text-xs text-slate-500 flex-shrink-0">Elapsed</dt>
                            <dd class="text-xs font-semibold text-orange-600 text-right" x-text="selectedIncident?.elapsed ?? '—'"></dd>
                        </div>
                    </dl>
                </div>

                {{-- Location & Reporter --}}
                <div class="space-y-3">
                    <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide flex items-center gap-1.5">
                        <i data-lucide="map-pin" class="w-3.5 h-3.5"></i> Location & Reporter
                    </h4>
                    <dl class="space-y-2.5">
                        <div class="flex items-start justify-between gap-2">
                            <dt class="text-xs text-slate-500 flex-shrink-0">Barangay</dt>
                            <dd class="text-xs font-medium text-slate-800 text-right" x-text="selectedIncident?.barangay ?? '—'"></dd>
                        </div>
                        <div class="flex items-start justify-between gap-2">
                            <dt class="text-xs text-slate-500 flex-shrink-0">Location</dt>
                            <dd class="text-xs font-medium text-slate-800 text-right" x-text="selectedIncident?.location ?? '—'"></dd>
                        </div>
                        <div class="flex items-start justify-between gap-2">
                            <dt class="text-xs text-slate-500 flex-shrink-0">Reporter</dt>
                            <dd class="text-xs font-medium text-slate-800 text-right" x-text="selectedIncident?.reporter ?? '—'"></dd>
                        </div>
                        <div class="flex items-start justify-between gap-2">
                            <dt class="text-xs text-slate-500 flex-shrink-0">Contact</dt>
                            <dd class="text-xs font-medium text-slate-800 text-right" x-text="selectedIncident?.contact ?? '—'"></dd>
                        </div>
                    </dl>
                </div>

                {{-- Affected Population --}}
                <div class="space-y-3">
                    <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide flex items-center gap-1.5">
                        <i data-lucide="users" class="w-3.5 h-3.5"></i> Affected Population
                    </h4>
                    <dl class="space-y-2.5">
                        <div class="flex items-start justify-between gap-2">
                            <dt class="text-xs text-slate-500 flex-shrink-0">Persons Affected</dt>
                            <dd class="text-xs font-semibold text-slate-800 tabular-nums" x-text="selectedIncident?.affected ?? 0"></dd>
                        </div>
                        <div class="flex items-start justify-between gap-2">
                            <dt class="text-xs text-slate-500 flex-shrink-0">Vulnerable Persons</dt>
                            <dd class="text-xs font-semibold text-rose-600 tabular-nums" x-text="selectedIncident?.vulnerable ?? 0"></dd>
                        </div>
                    </dl>
                </div>

                {{-- Response Details --}}
                <div class="space-y-3">
                    <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide flex items-center gap-1.5">
                        <i data-lucide="shield" class="w-3.5 h-3.5"></i> Response Details
                    </h4>
                    <dl class="space-y-2.5">
                        <div class="flex items-start justify-between gap-2">
                            <dt class="text-xs text-slate-500 flex-shrink-0">Team Assigned</dt>
                            <dd class="text-xs font-medium text-slate-800 text-right" x-text="selectedIncident?.team ?? '—'"></dd>
                        </div>
                        <div class="flex items-start justify-between gap-2">
                            <dt class="text-xs text-slate-500 flex-shrink-0">Team Lead</dt>
                            <dd class="text-xs font-medium text-slate-800 text-right" x-text="selectedIncident?.lead ?? '—'"></dd>
                        </div>
                    </dl>
                </div>
            </div>

            {{-- Timeline --}}
            <div>
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide flex items-center gap-1.5 mb-3">
                    <i data-lucide="clock" class="w-3.5 h-3.5"></i> Incident Timeline
                </h4>
                <div class="space-y-0">
                    @php
                        $timelineEntries = [
                            ['status' => 'Reported',   'actor' => 'Barangay DRRM / Citizen',     'time' => '06:12 AM', 'note' => 'Initial report received via barangay hotline'],
                            ['status' => 'Validated',  'actor' => 'EOC Officer Sanchez',          'time' => '06:35 AM', 'note' => 'Incident verified and entered into system'],
                            ['status' => 'Dispatched', 'actor' => 'MDRRMO Operations',            'time' => '07:00 AM', 'note' => 'Rescue team and boat dispatched'],
                            ['status' => 'On Scene',   'actor' => 'Rescue Team Alpha',            'time' => '07:45 AM', 'note' => 'Team arrived on scene, rescue operations commenced'],
                            ['status' => 'Ongoing',    'actor' => 'EOC Monitoring',               'time' => '08:10 AM', 'note' => 'Operations ongoing — 38 families still to be evacuated'],
                        ];
                    @endphp
                    @foreach ($timelineEntries as $entry)
                        <div class="flex items-start gap-3 py-2.5 {{ !$loop->last ? 'border-b border-slate-50' : '' }}">
                            <div class="flex flex-col items-center flex-shrink-0">
                                <div class="w-2 h-2 rounded-full {{ $loop->last ? 'bg-orange-400 animate-pulse' : 'bg-brand-400' }} mt-1.5"></div>
                                @if (!$loop->last)<div class="w-px flex-1 bg-slate-100 mt-1 mb-0.5 h-5"></div>@endif
                            </div>
                            <div class="flex-1 min-w-0">
                                <div class="flex items-center gap-2 flex-wrap">
                                    <span class="text-xs font-semibold text-slate-700">{{ $entry['status'] }}</span>
                                    <span class="text-[11px] text-slate-400">by {{ $entry['actor'] }}</span>
                                </div>
                                <p class="text-[11px] text-slate-500 mt-0.5">{{ $entry['note'] }}</p>
                            </div>
                            <span class="text-[11px] text-slate-400 whitespace-nowrap flex-shrink-0 mt-0.5">{{ $entry['time'] }}</span>
                        </div>
                    @endforeach
                </div>
            </div>

            {{-- Notes --}}
            <div>
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2 flex items-center gap-1.5">
                    <i data-lucide="notebook" class="w-3.5 h-3.5"></i> Operational Notes
                </h4>
                <div class="p-3 bg-amber-50 border border-amber-100 rounded-xl">
                    <p class="text-xs text-amber-800 leading-relaxed">Coordinate with Masbaranon Brgy. Captain for updated family count. Request generator from EC-006 for use at staging area. Ensure RHU medical team is on standby at evacuation center.</p>
                </div>
            </div>

        </div>{{-- /Modal Body --}}

        {{-- Modal Footer Actions --}}
        <div class="flex flex-wrap items-center gap-2 px-6 py-4 border-t border-slate-100 bg-slate-50/60 flex-shrink-0">
            <button @click="toast('Incident validated.', 'success')"   class="px-3 py-1.5 text-xs font-semibold bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg transition-colors">Validate</button>
            <button @click="toast('Assign Team modal — coming soon.', 'info')" class="px-3 py-1.5 text-xs font-medium bg-white hover:bg-slate-50 text-slate-700 border border-slate-200 rounded-lg transition-colors">Assign Team</button>
            <button @click="toast('Dispatch initiated.', 'success')"   class="px-3 py-1.5 text-xs font-medium bg-white hover:bg-slate-50 text-slate-700 border border-slate-200 rounded-lg transition-colors">Dispatch</button>
            <button @click="toast('Incident escalated to PDRRMO.', 'warning')" class="px-3 py-1.5 text-xs font-medium bg-white hover:bg-slate-50 text-orange-700 border border-orange-200 rounded-lg transition-colors">Escalate</button>
            <button @click="toast('Incident marked as Resolved.', 'success')"  class="px-3 py-1.5 text-xs font-medium bg-white hover:bg-slate-50 text-emerald-700 border border-emerald-200 rounded-lg transition-colors">Resolve</button>
            <button @click="toast('Incident closed.', 'info')"          class="px-3 py-1.5 text-xs font-medium bg-slate-100 hover:bg-slate-200 text-slate-600 border border-slate-200 rounded-lg transition-colors">Close</button>
            <button @click="showIncidentDetail = false" class="ml-auto px-4 py-1.5 text-xs font-medium bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-lg transition-colors">Dismiss</button>
        </div>
    </div>
</div>{{-- /Incident Detail Modal --}}
