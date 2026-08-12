{{--
    resources/views/admin/partials/sakuna/tab-reports.blade.php
    Disaster Reports & Analytics Dashboard — SAKUNA Disaster Management Module
    @include'd from admin/sakuna.blade.php — Alpine state inherited from parent x-data.
    DO NOT add x-data at the root level of this file.
--}}

{{-- ══════════════════════════════════════════════════════════════════════════ --}}
{{-- A. HEADER ROW                                                              --}}
{{-- ══════════════════════════════════════════════════════════════════════════ --}}
<div class="flex items-start justify-between gap-4 mb-5 flex-wrap">
    <div>
        <h2 class="text-lg font-bold text-slate-800">Disaster Reports &amp; Analytics</h2>
        <p class="text-sm text-slate-500 mt-0.5">View analytics, generate official reports, and export data for the active operational period.</p>
    </div>
    <div class="flex items-center gap-2 flex-shrink-0 flex-wrap">
        {{-- Period selector --}}
        <select
            x-model="reportPeriodFilter"
            class="px-3 py-2 text-sm border border-slate-200 rounded-xl bg-white text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors">
            <option value="SWM-2026-07">SWM-2026-07 · Southwest Monsoon &amp; Flooding — July 2026</option>
            <option value="TY-2026-05">TY-2026-05 · Typhoon Amang — May 2026</option>
        </select>

        {{-- Barangay selector --}}
        <select
            x-model="reportBarangayFilter"
            class="px-3 py-2 text-sm border border-slate-200 rounded-xl bg-white text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors">
            <option value="">All Barangays</option>
            @foreach($barangays as $brgy)
                <option value="{{ $brgy }}">{{ $brgy }}</option>
            @endforeach
        </select>

        {{-- Export All --}}
        <button
            @click="$dispatch('toast', { message: 'Full report package exported to PDF.', variant: 'success' })"
            class="flex items-center gap-1.5 px-4 py-2 text-sm font-semibold text-white bg-brand-600 hover:bg-brand-700 rounded-xl transition-colors shadow-sm">
            <i data-lucide="download" class="w-4 h-4"></i>
            Export All
        </button>
    </div>
</div>

{{-- ══════════════════════════════════════════════════════════════════════════ --}}
{{-- B. ANALYTICS CHARTS (2×2 grid)                                             --}}
{{-- ══════════════════════════════════════════════════════════════════════════ --}}
<div class="grid grid-cols-1 lg:grid-cols-2 gap-5 mb-5">

    {{-- Chart 1: Incident Trend — Last 14 Days --}}
    <div class="bg-white rounded-2xl shadow-card border border-slate-100 p-5">
        <div class="flex items-center justify-between mb-4">
            <div>
                <h3 class="text-sm font-bold text-slate-800">Incident Trend</h3>
                <p class="text-xs text-slate-400 mt-0.5">Last 14 days · <span x-text="reportBarangayFilter || 'All Barangays'"></span></p>
            </div>
            <div class="flex items-center gap-1.5">
                <span class="w-2 h-2 rounded-full bg-brand-500"></span>
                <span class="text-xs text-slate-500">Incidents</span>
            </div>
        </div>
        <div x-data="lineChart({ labels: ['Jul 2','Jul 3','Jul 4','Jul 5','Jul 6','Jul 7','Jul 8','Jul 9','Jul 10','Jul 11','Jul 12','Jul 13','Jul 14','Jul 15'], datasets: [{ label: 'Incidents', data: [0,1,0,2,1,0,3,2,1,4,2,5,8,13], color: '#2f62f5', fill: 'rgba(47,98,245,0.08)' }] })" class="relative">
            <canvas x-ref="canvas" style="height:200px"></canvas>
        </div>
        <div class="flex items-center justify-between mt-3 pt-3 border-t border-slate-50">
            <span class="text-xs text-slate-400">Total: <strong class="text-slate-700">42 incidents</strong> this period</span>
            <span class="text-xs text-rose-600 font-medium flex items-center gap-1">
                <i data-lucide="trending-up" class="w-3 h-3"></i>
                +63% last 48h
            </span>
        </div>
    </div>

    {{-- Chart 2: Incidents by Category --}}
    <div class="bg-white rounded-2xl shadow-card border border-slate-100 p-5">
        <div class="flex items-center justify-between mb-4">
            <div>
                <h3 class="text-sm font-bold text-slate-800">Incidents by Category</h3>
                <p class="text-xs text-slate-400 mt-0.5">Current operational period</p>
            </div>
        </div>
        <div x-data="donutChart({ labels: ['Flood','Landslide','Road Obstruction','Medical Emergency','Agricultural Damage','Missing Person','Power Interruption','Other'], values: [4,2,1,1,1,1,1,2], colors: ['#2f62f5','#f59e0b','#f97316','#ec4899','#22c55e','#8b5cf6','#64748b','#94a3b8'] })" class="relative">
            <canvas x-ref="canvas" style="height:180px"></canvas>
        </div>
        {{-- Legend --}}
        <div class="flex flex-wrap gap-x-4 gap-y-1.5 mt-3 pt-3 border-t border-slate-50">
            @php
                $donutLegend = [
                    ['label' => 'Flood',               'color' => 'bg-blue-500',    'val' => 4],
                    ['label' => 'Landslide',           'color' => 'bg-amber-400',   'val' => 2],
                    ['label' => 'Road Obstruction',    'color' => 'bg-orange-400',  'val' => 1],
                    ['label' => 'Medical Emergency',   'color' => 'bg-pink-500',    'val' => 1],
                    ['label' => 'Agricultural Damage', 'color' => 'bg-emerald-500', 'val' => 1],
                    ['label' => 'Missing Person',      'color' => 'bg-violet-500',  'val' => 1],
                    ['label' => 'Power Interruption',  'color' => 'bg-slate-500',   'val' => 1],
                    ['label' => 'Other',               'color' => 'bg-slate-400',   'val' => 2],
                ];
            @endphp
            @foreach($donutLegend as $item)
                <div class="flex items-center gap-1.5">
                    <span class="w-2 h-2 rounded-full {{ $item['color'] }} flex-shrink-0"></span>
                    <span class="text-xs text-slate-500">{{ $item['label'] }}</span>
                    <span class="text-xs font-semibold text-slate-700">{{ $item['val'] }}</span>
                </div>
            @endforeach
        </div>
    </div>

    {{-- Chart 3: Center Occupancy vs Capacity --}}
    <div class="bg-white rounded-2xl shadow-card border border-slate-100 p-5">
        <div class="flex items-center justify-between mb-4">
            <div>
                <h3 class="text-sm font-bold text-slate-800">Center Occupancy vs Capacity</h3>
                <p class="text-xs text-slate-400 mt-0.5">8 open evacuation centers · real-time</p>
            </div>
            <div class="flex items-center gap-3">
                <div class="flex items-center gap-1.5">
                    <span class="w-2.5 h-2.5 rounded bg-brand-500"></span>
                    <span class="text-xs text-slate-500">Occupancy</span>
                </div>
                <div class="flex items-center gap-1.5">
                    <span class="w-2.5 h-2.5 rounded bg-slate-200"></span>
                    <span class="text-xs text-slate-500">Capacity</span>
                </div>
            </div>
        </div>
        <div x-data="barChart({ labels: ['Poblacion CC','Masbaranon ES','Baras BH','Domorog MPH','Magsaysay BH','Mun. Gymnasium','Iligan ES','Agoho CC'], datasets: [{ label: 'Occupancy', data: [198,189,87,76,103,321,54,0], color: '#2f62f5' }, { label: 'Capacity', data: [250,200,150,120,100,500,180,140], color: '#e2e8f0' }], showLegend: true })" class="relative">
            <canvas x-ref="canvas" style="height:200px"></canvas>
        </div>
        <div class="flex items-center justify-between mt-3 pt-3 border-t border-slate-50">
            <span class="text-xs text-slate-400">Total evacuees: <strong class="text-slate-700">1,028</strong></span>
            <span class="text-xs text-amber-600 font-medium">Masbaranon ES at 94.5% capacity</span>
        </div>
    </div>

    {{-- Chart 4: Readiness Score — Lowest Barangays --}}
    <div class="bg-white rounded-2xl shadow-card border border-slate-100 p-5">
        <div class="flex items-center justify-between mb-4">
            <div>
                <h3 class="text-sm font-bold text-slate-800">Readiness Score — Lowest Barangays</h3>
                <p class="text-xs text-slate-400 mt-0.5">Score out of 100 · barangays needing attention</p>
            </div>
            <span class="text-xs bg-rose-50 text-rose-700 border border-rose-100 px-2 py-0.5 rounded-full font-medium">Action Required</span>
        </div>
        <div x-data="barChart({ horizontal: true, labels: ['Tawad','Labangtaytay','Santiago','Magsaysay','Domorog','Almero','Rizal','Labrador'], values: [38,42,45,52,55,57,66,68], colors: ['#f43f5e','#f43f5e','#f97316','#f97316','#f59e0b','#f59e0b','#2f62f5','#2f62f5'], label: 'Readiness Score' })" class="relative">
            <canvas x-ref="canvas" style="height:220px"></canvas>
        </div>
        <div class="flex items-center justify-between mt-3 pt-3 border-t border-slate-50">
            <span class="text-xs text-slate-400">Municipal average: <strong class="text-slate-700">71.4</strong></span>
            <button @click="$dispatch('toast', { message: 'Readiness improvement plan opened.', variant: 'info' })" class="text-xs text-brand-600 hover:text-brand-700 font-medium">View Action Plan →</button>
        </div>
    </div>
</div>

{{-- ══════════════════════════════════════════════════════════════════════════ --}}
{{-- C. PERFORMANCE METRICS                                                     --}}
{{-- ══════════════════════════════════════════════════════════════════════════ --}}
<div class="bg-white rounded-2xl shadow-card border border-slate-100 p-5 mb-5">
    <h3 class="text-sm font-bold text-slate-800 mb-4">Response Performance</h3>
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-5">
        {{-- KPI tiles --}}
        @php
            $kpis = [
                ['label' => 'Avg. Validation Time', 'value' => '28',   'unit' => 'min',    'icon' => 'clock',          'color' => 'bg-blue-50 text-blue-600',    'change' => '-4 min vs last op', 'positive' => true],
                ['label' => 'Avg. Dispatch Time',   'value' => '14',   'unit' => 'min',    'icon' => 'zap',            'color' => 'bg-emerald-50 text-emerald-600','change' => '-2 min vs last op', 'positive' => true],
                ['label' => 'Avg. Arrival Time',    'value' => '42',   'unit' => 'min',    'icon' => 'map-pin',        'color' => 'bg-amber-50 text-amber-600',  'change' => '+5 min vs last op', 'positive' => false],
                ['label' => 'Incidents Resolved',   'value' => '3/13', 'unit' => '(23%)',  'icon' => 'circle-check',   'color' => 'bg-emerald-50 text-emerald-600','change' => '10 still active',   'positive' => null],
            ];
        @endphp
        @foreach($kpis as $kpi)
            <div class="bg-slate-50 rounded-xl p-4 border border-slate-100">
                <div class="w-8 h-8 rounded-lg {{ $kpi['color'] }} flex items-center justify-center mb-3">
                    <i data-lucide="{{ $kpi['icon'] }}" class="w-4 h-4"></i>
                </div>
                <div class="flex items-baseline gap-1.5">
                    <span class="text-2xl font-bold text-slate-800 leading-none">{{ $kpi['value'] }}</span>
                    <span class="text-sm text-slate-500">{{ $kpi['unit'] }}</span>
                </div>
                <p class="text-xs text-slate-500 mt-1">{{ $kpi['label'] }}</p>
                <p class="text-xs mt-1.5 {{ $kpi['positive'] === true ? 'text-emerald-600' : ($kpi['positive'] === false ? 'text-rose-500' : 'text-amber-600') }}">{{ $kpi['change'] }}</p>
            </div>
        @endforeach
    </div>

    {{-- Top requesting barangays --}}
    <div>
        <p class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">Top Requesting Barangays</p>
        <div class="space-y-2.5">
            @php
                $topBrgys = [
                    ['name' => 'Masbaranon', 'count' => 5, 'max' => 5],
                    ['name' => 'Baras',      'count' => 3, 'max' => 5],
                    ['name' => 'Domorog',    'count' => 2, 'max' => 5],
                    ['name' => 'Magsaysay',  'count' => 2, 'max' => 5],
                    ['name' => 'Poblacion',  'count' => 1, 'max' => 5],
                ];
            @endphp
            @foreach($topBrgys as $b)
                <div class="flex items-center gap-3">
                    <span class="text-xs text-slate-600 w-28 flex-shrink-0">{{ $b['name'] }}</span>
                    <div class="flex-1 h-2 bg-slate-100 rounded-full overflow-hidden">
                        <div
                            class="h-2 bg-brand-500 rounded-full transition-all duration-700"
                            style="width: {{ round(($b['count'] / $b['max']) * 100) }}%">
                        </div>
                    </div>
                    <span class="text-xs font-semibold text-slate-700 w-12 text-right flex-shrink-0">{{ $b['count'] }} req.</span>
                </div>
            @endforeach
        </div>
    </div>
</div>

{{-- ══════════════════════════════════════════════════════════════════════════ --}}
{{-- D. REPORT CATALOGUE                                                        --}}
{{-- ══════════════════════════════════════════════════════════════════════════ --}}

@php
    $activePeriod = 'SWM-2026-07';

    $reportCategories = [
        [
            'title'       => 'Vulnerability & Preparedness',
            'icon'        => 'map-pin',
            'icon_color'  => 'bg-rose-50 text-rose-600',
            'reports'     => [
                ['name' => 'Barangay Vulnerability and Readiness Report',  'desc' => 'Comprehensive vulnerability index across all barangays.'],
                ['name' => 'Hazard-Exposed Population Report',             'desc' => 'Population by hazard type and exposure level.'],
                ['name' => 'Assisted Evacuation Priority List',            'desc' => 'Households requiring transport for evacuation.'],
            ],
        ],
        [
            'title'       => 'Evacuation',
            'icon'        => 'house',
            'icon_color'  => 'bg-sky-50 text-sky-600',
            'reports'     => [
                ['name' => 'Evacuation Center Capacity Report',  'desc' => 'Capacity, utilization, and readiness status per center.'],
                ['name' => 'Evacuation Center Occupancy Report', 'desc' => 'Current and historical evacuee counts by center.'],
                ['name' => 'Evacuee Demographic Summary',        'desc' => 'Age, sex, and vulnerability breakdown of current evacuees.'],
            ],
        ],
        [
            'title'       => 'Incident & Response',
            'icon'        => 'flame',
            'icon_color'  => 'bg-orange-50 text-orange-600',
            'reports'     => [
                ['name' => 'Active Incident Report',         'desc' => 'All unresolved incidents with status, location, and assigned teams.'],
                ['name' => 'Incident Response-Time Report',  'desc' => 'Validation, dispatch, and arrival times per incident.'],
                ['name' => 'Rescue Deployment Report',       'desc' => 'Rescue unit assignments and deployment logs.'],
                ['name' => 'Resource Availability Report',   'desc' => 'Current inventory and deployment status of emergency resources.'],
            ],
        ],
        [
            'title'       => 'Relief & Logistics',
            'icon'        => 'package',
            'icon_color'  => 'bg-teal-50 text-teal-600',
            'reports'     => [
                ['name' => 'Relief Inventory Report',       'desc' => 'Current stock levels of relief goods and supplies.'],
                ['name' => 'Relief Distribution Report',    'desc' => 'Distribution records by barangay and beneficiary.'],
                ['name' => 'Duplicate Assistance Review',   'desc' => 'Cross-check report to detect duplicate beneficiary claims.'],
            ],
        ],
        [
            'title'       => 'Damage & Recovery',
            'icon'        => 'clipboard-list',
            'icon_color'  => 'bg-amber-50 text-amber-600',
            'reports'     => [
                ['name' => 'Affected Families and Individuals Report', 'desc' => 'Count and profile of disaster-affected households.'],
                ['name' => 'Damage and Needs Assessment Report',       'desc' => 'Assessed damage per sector and priority needs.'],
                ['name' => 'Agricultural Damage Report',               'desc' => 'Crop, livestock, and fishery damage by barangay.'],
                ['name' => 'Casualty and Missing Persons Report',      'desc' => 'Fatalities, injuries, and missing persons log.'],
            ],
        ],
        [
            'title'       => 'Operational',
            'icon'        => 'radio-tower',
            'icon_color'  => 'bg-violet-50 text-violet-600',
            'reports'     => [
                ['name' => 'Daily Situation Report (SitRep)', 'desc' => 'Official 24-hour situation summary for PDRRMC submission.'],
                ['name' => 'Operational Period Report',       'desc' => 'Full summary for the active operational period.'],
                ['name' => 'After-Action Report (AAR)',       'desc' => 'Post-operation lessons learned and recommendations.'],
            ],
        ],
    ];
@endphp

<div class="space-y-6">
    @foreach($reportCategories as $cat)
        <div>
            {{-- Category header --}}
            <div class="flex items-center gap-2.5 mb-3">
                <div class="w-7 h-7 rounded-lg {{ $cat['icon_color'] }} flex items-center justify-center flex-shrink-0">
                    <i data-lucide="{{ $cat['icon'] }}" class="w-3.5 h-3.5"></i>
                </div>
                <h3 class="text-sm font-bold text-slate-700">{{ $cat['title'] }}</h3>
                <div class="flex-1 h-px bg-slate-100"></div>
                <span class="text-xs text-slate-400">{{ count($cat['reports']) }} report{{ count($cat['reports']) !== 1 ? 's' : '' }}</span>
            </div>

            {{-- Report cards grid --}}
            <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-3">
                @foreach($cat['reports'] as $report)
                    <div class="bg-white rounded-2xl shadow-card border border-slate-100 p-4 hover:shadow-md transition-shadow">
                        <div class="flex items-start gap-3 mb-3">
                            <div class="w-9 h-9 rounded-xl {{ $cat['icon_color'] }} flex items-center justify-center flex-shrink-0">
                                <i data-lucide="{{ $cat['icon'] }}" class="w-4 h-4"></i>
                            </div>
                            <div class="min-w-0">
                                <p class="text-sm font-semibold text-slate-800 leading-snug">{{ $report['name'] }}</p>
                                <p class="text-xs text-slate-500 mt-0.5 leading-relaxed">{{ $report['desc'] }}</p>
                            </div>
                        </div>
                        <div class="flex items-center gap-1.5 flex-wrap mb-3">
                            <span class="text-xs bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full" x-text="reportPeriodFilter || '{{ $activePeriod }}'"></span>
                            <span class="text-xs bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full" x-text="reportBarangayFilter || 'All Barangays'"></span>
                        </div>
                        <div class="flex gap-2 pt-3 border-t border-slate-50">
                            <button
                                @click="$dispatch('toast', { message: '{{ addslashes($report['name']) }} generated successfully.', variant: 'success' })"
                                class="flex-1 text-xs font-medium text-brand-600 bg-brand-50 hover:bg-brand-100 rounded-lg py-1.5 transition-colors">
                                Generate
                            </button>
                            <button
                                @click="$dispatch('toast', { message: '{{ addslashes($report['name']) }} exported to PDF.', variant: 'success' })"
                                class="text-xs font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-lg px-3 py-1.5 transition-colors">
                                Export
                            </button>
                            <button
                                @click="$dispatch('toast', { message: 'Sent to printer.', variant: 'info' })"
                                class="text-xs font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-lg px-3 py-1.5 transition-colors">
                                Print
                            </button>
                        </div>
                    </div>
                @endforeach
            </div>
        </div>
    @endforeach
</div>

{{-- Bottom spacer --}}
<div class="h-6"></div>
