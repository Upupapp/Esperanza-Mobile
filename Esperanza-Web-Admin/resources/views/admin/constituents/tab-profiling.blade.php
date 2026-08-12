{{-- tab-profiling.blade.php — Profiling Coverage Tab --}}
{{-- Rendered inside constituents.blade.php Alpine x-data scope --}}

<div class="space-y-6">

    {{-- ── SUMMARY STAT CARDS ─────────────────────────────────────────────── --}}
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <x-ui.stat-card
            label="Barangays Profiled"
            value="20/20"
            icon="map-pin"
            color="brand"
            :delay="0"
        />
        <x-ui.stat-card
            label="Households Recorded"
            value="4,918"
            icon="house"
            color="green"
            :delay="75"
        />
        <x-ui.stat-card
            label="Avg. Completion Rate"
            value="74%"
            icon="clipboard-check"
            color="purple"
            :delay="150"
        />
        <x-ui.stat-card
            label="Barangays Below 60%"
            value="4"
            icon="triangle-alert"
            color="red"
            sublabel="Needs field verification"
            :delay="225"
        />
    </div>

    {{-- ── COVERAGE STATUS DONUT + LEGEND ROW ────────────────────────────── --}}
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">

        {{-- Donut chart card --}}
        <x-ui.card class="flex flex-col items-center justify-center py-6 gap-4">
            <h3 class="text-sm font-semibold text-navy-900 tracking-tight self-start px-1">
                Status Breakdown
            </h3>

            <div
                x-data="donutChart({
                    labels: ['Complete', 'In Progress', 'Needs Follow-up', 'Not Started'],
                    datasets: [{
                        data: [1, 12, 6, 1],
                        backgroundColor: ['#10b981','#3b82f6','#f59e0b','#f43f5e'],
                        borderColor: '#ffffff',
                        borderWidth: 3,
                        hoverOffset: 6
                    }],
                    options: {
                        cutout: '68%',
                        plugins: {
                            legend: { display: false },
                            tooltip: {
                                callbacks: {
                                    label: function(ctx) {
                                        return ' ' + ctx.label + ': ' + ctx.raw + ' barangay' + (ctx.raw > 1 ? 's' : '');
                                    }
                                }
                            }
                        }
                    }
                })"
                class="relative w-40 h-40"
            >
                <canvas x-ref="canvas" class="w-full h-full"></canvas>
                <div class="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                    <span class="text-2xl font-bold text-navy-900">20</span>
                    <span class="text-[10px] text-slate-500 uppercase tracking-wider mt-0.5">Barangays</span>
                </div>
            </div>

            {{-- Legend --}}
            <div class="grid grid-cols-2 gap-x-6 gap-y-2 text-xs w-full px-2">
                <div class="flex items-center gap-2">
                    <span class="w-2.5 h-2.5 rounded-full bg-emerald-500 shrink-0"></span>
                    <span class="text-slate-600">Complete <span class="font-semibold text-navy-900">(1)</span></span>
                </div>
                <div class="flex items-center gap-2">
                    <span class="w-2.5 h-2.5 rounded-full bg-blue-500 shrink-0"></span>
                    <span class="text-slate-600">In Progress <span class="font-semibold text-navy-900">(12)</span></span>
                </div>
                <div class="flex items-center gap-2">
                    <span class="w-2.5 h-2.5 rounded-full bg-amber-400 shrink-0"></span>
                    <span class="text-slate-600">Needs Follow-up <span class="font-semibold text-navy-900">(6)</span></span>
                </div>
                <div class="flex items-center gap-2">
                    <span class="w-2.5 h-2.5 rounded-full bg-rose-500 shrink-0"></span>
                    <span class="text-slate-600">Not Started <span class="font-semibold text-navy-900">(1)</span></span>
                </div>
            </div>
        </x-ui.card>

        {{-- Coverage progress overview --}}
        <x-ui.card class="lg:col-span-2 flex flex-col gap-3 py-5 px-5">
            <h3 class="text-sm font-semibold text-navy-900 tracking-tight mb-1">
                Overall Municipal Coverage
            </h3>

            <div class="space-y-3">
                {{-- Resident profiling bar --}}
                <div>
                    <div class="flex justify-between text-xs text-slate-600 mb-1">
                        <span>Residents Profiled</span>
                        <span class="font-semibold text-navy-900">3,421 / 5,012 &mdash; <span class="text-emerald-600">68%</span></span>
                    </div>
                    <div class="w-full h-2.5 bg-slate-100 rounded-full overflow-hidden">
                        <div class="h-full bg-emerald-500 rounded-full transition-all duration-700" style="width: 68%"></div>
                    </div>
                </div>
                {{-- Household profiling bar --}}
                <div>
                    <div class="flex justify-between text-xs text-slate-600 mb-1">
                        <span>Households Profiled</span>
                        <span class="font-semibold text-navy-900">3,628 / 4,918 &mdash; <span class="text-blue-600">74%</span></span>
                    </div>
                    <div class="w-full h-2.5 bg-slate-100 rounded-full overflow-hidden">
                        <div class="h-full bg-blue-500 rounded-full transition-all duration-700" style="width: 74%"></div>
                    </div>
                </div>
                {{-- Barangays with ≥80% bar --}}
                <div>
                    <div class="flex justify-between text-xs text-slate-600 mb-1">
                        <span>Barangays ≥ 80% Complete</span>
                        <span class="font-semibold text-navy-900">9 / 20 &mdash; <span class="text-purple-600">45%</span></span>
                    </div>
                    <div class="w-full h-2.5 bg-slate-100 rounded-full overflow-hidden">
                        <div class="h-full bg-purple-500 rounded-full transition-all duration-700" style="width: 45%"></div>
                    </div>
                </div>
                {{-- Field visits this month --}}
                <div>
                    <div class="flex justify-between text-xs text-slate-600 mb-1">
                        <span>Field Visits This Month</span>
                        <span class="font-semibold text-navy-900">14 completed</span>
                    </div>
                    <div class="w-full h-2.5 bg-slate-100 rounded-full overflow-hidden">
                        <div class="h-full bg-amber-400 rounded-full transition-all duration-700" style="width: 70%"></div>
                    </div>
                </div>
            </div>

            <p class="text-[11px] text-slate-400 mt-auto pt-2 border-t border-slate-100">
                <i data-lucide="info" class="w-3 h-3 inline -mt-0.5 mr-0.5"></i>
                Data as of {{ \Carbon\Carbon::now()->format('F j, Y') }}. Figures are based on submitted profiling forms.
            </p>
        </x-ui.card>
    </div>

    {{-- ── BARANGAY COVERAGE TABLE ─────────────────────────────────────────── --}}
    <x-ui.card class="overflow-hidden">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 px-5 py-4 border-b border-slate-100">
            <div>
                <h3 class="text-sm font-semibold text-navy-900 tracking-tight">Barangay-Level Coverage</h3>
                <p class="text-xs text-slate-500 mt-0.5">All 20 barangays of Esperanza, Masbate</p>
            </div>
            <div class="flex items-center gap-2 shrink-0">
                <button
                    @click="$dispatch('toast',{message:'Profiling report export initiated. Your file will download shortly.',variant:'info'})"
                    class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg border border-slate-200 text-slate-600 bg-white hover:bg-slate-50 hover:border-slate-300 transition"
                >
                    <i data-lucide="download" class="w-3.5 h-3.5"></i> Export Report
                </button>
                <button
                    @click="$dispatch('toast',{message:'Batch field visit scheduling is being prepared.',variant:'info'})"
                    class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg bg-brand-600 text-white hover:bg-brand-700 transition shadow-sm"
                >
                    <i data-lucide="calendar-plus" class="w-3.5 h-3.5"></i> Schedule All Pending
                </button>
            </div>
        </div>

        <x-ui.table>
            <table class="min-w-full divide-y divide-slate-100 text-sm">
                <thead class="bg-slate-50">
                    <tr>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Barangay</th>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Residents Profiled</th>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Households Profiled</th>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap w-40">Coverage %</th>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Last Visit</th>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Assigned Encoder</th>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Status</th>
                        <th class="px-4 py-3 text-right text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-50 bg-white">
                    @foreach ($barangayCoverage as $b)
                        @php
                            $pct     = (int) $b['pct'];
                            $hhPct   = (int) $b['hh_pct'];
                            $barColor = $pct >= 90 ? 'bg-emerald-500' : ($pct >= 70 ? 'bg-amber-400' : 'bg-rose-500');
                            $statusMap = [
                                'Complete'                          => ['text-emerald-700','bg-emerald-50','ring-emerald-200'],
                                'In Progress'                       => ['text-blue-700','bg-blue-50','ring-blue-200'],
                                'Needs Follow-up'                   => ['text-amber-700','bg-amber-50','ring-amber-200'],
                                'Not Started (Re-visit Required)'   => ['text-rose-700','bg-rose-50','ring-rose-200'],
                            ];
                            $sc = $statusMap[$b['status']] ?? ['text-slate-700','bg-slate-50','ring-slate-200'];

                            $lastVisit = \Carbon\Carbon::parse($b['last_visit']);
                            $visitLabel = $lastVisit->diffForHumans();
                            $visitFmt   = $lastVisit->format('M j, Y');
                        @endphp
                        <tr
                            x-show="$store.session.inScope('{{ $b['name'] }}')"
                            class="hover:bg-slate-50/70 transition-colors group"
                            x-cloak
                        >
                            {{-- Barangay name --}}
                            <td class="px-4 py-3 font-medium text-navy-900 whitespace-nowrap">
                                <div class="flex items-center gap-2">
                                    <span class="w-1.5 h-1.5 rounded-full {{ $barColor }} shrink-0"></span>
                                    Brgy. {{ $b['name'] }}
                                </div>
                            </td>

                            {{-- Residents --}}
                            <td class="px-4 py-3 text-slate-700 whitespace-nowrap tabular-nums">
                                <span class="font-semibold text-navy-900">{{ number_format($b['profiled']) }}</span>
                                <span class="text-slate-400 text-xs"> / {{ number_format($b['residents']) }}</span>
                            </td>

                            {{-- Households --}}
                            <td class="px-4 py-3 text-slate-700 whitespace-nowrap tabular-nums">
                                <span class="font-semibold text-navy-900">{{ number_format($b['hh_profiled']) }}</span>
                                <span class="text-slate-400 text-xs"> / {{ number_format($b['hh']) }}</span>
                            </td>

                            {{-- Coverage % with progress bar --}}
                            <td class="px-4 py-3">
                                <div class="flex items-center gap-2 min-w-[120px]">
                                    <div class="flex-1 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                                        <div class="h-full {{ $barColor }} rounded-full" style="width: {{ $pct }}%"></div>
                                    </div>
                                    <span class="text-xs font-semibold tabular-nums
                                        {{ $pct >= 90 ? 'text-emerald-600' : ($pct >= 70 ? 'text-amber-600' : 'text-rose-600') }}
                                        w-8 text-right shrink-0">
                                        {{ $pct }}%
                                    </span>
                                </div>
                            </td>

                            {{-- Last visit --}}
                            <td class="px-4 py-3 whitespace-nowrap">
                                <span class="text-slate-700 text-xs" title="{{ $visitFmt }}">{{ $visitLabel }}</span>
                                <div class="text-[10px] text-slate-400">{{ $visitFmt }}</div>
                            </td>

                            {{-- Encoder --}}
                            <td class="px-4 py-3 whitespace-nowrap">
                                <div class="flex items-center gap-2">
                                    <span class="w-6 h-6 rounded-full bg-brand-100 text-brand-700 text-[10px] font-bold flex items-center justify-center shrink-0 uppercase">
                                        {{ substr($b['encoder'], 0, 1) }}
                                    </span>
                                    <span class="text-xs text-slate-700">{{ $b['encoder'] }}</span>
                                </div>
                            </td>

                            {{-- Status chip --}}
                            <td class="px-4 py-3 whitespace-nowrap">
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium ring-1 {{ $sc[0] }} {{ $sc[1] }} {{ $sc[2] }}">
                                    {{ $b['status'] }}
                                </span>
                            </td>

                            {{-- Actions --}}
                            <td class="px-4 py-3 text-right whitespace-nowrap">
                                <div class="flex items-center justify-end gap-1.5">
                                    <button
                                        @click="$dispatch('toast',{message:'Barangay detail view coming soon.',variant:'info'})"
                                        class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[11px] font-medium text-brand-700 bg-brand-50 hover:bg-brand-100 ring-1 ring-brand-200 transition"
                                        title="View profiling details for Brgy. {{ $b['name'] }}"
                                    >
                                        <i data-lucide="eye" class="w-3 h-3"></i> View
                                    </button>
                                    <button
                                        @click="$dispatch('toast',{message:'Field visit scheduling for Brgy. {{ $b['name'] }} initiated.',variant:'success'})"
                                        class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[11px] font-medium text-slate-600 bg-slate-50 hover:bg-slate-100 ring-1 ring-slate-200 transition"
                                        title="Schedule field visit"
                                    >
                                        <i data-lucide="calendar" class="w-3 h-3"></i> Schedule
                                    </button>
                                </div>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </x-ui.table>

        {{-- Table footer --}}
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 px-5 py-3 border-t border-slate-100 bg-slate-50/50">
            <p class="text-xs text-slate-500">
                Showing all <span class="font-semibold text-navy-900">20</span> barangays &mdash; Municipality of Esperanza, Masbate
            </p>
            <div class="flex items-center gap-2">
                <button
                    @click="$dispatch('toast',{message:'Profiling report export initiated.',variant:'info'})"
                    class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg border border-slate-200 text-slate-600 bg-white hover:bg-slate-50 transition"
                >
                    <i data-lucide="file-spreadsheet" class="w-3.5 h-3.5"></i> Export CSV
                </button>
                <button
                    @click="$dispatch('toast',{message:'PDF report generation started.',variant:'info'})"
                    class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg border border-slate-200 text-slate-600 bg-white hover:bg-slate-50 transition"
                >
                    <i data-lucide="file-text" class="w-3.5 h-3.5"></i> Export PDF
                </button>
            </div>
        </div>
    </x-ui.card>

</div>
