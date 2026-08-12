{{--
    tab-centers.blade.php
    Evacuation Center Management — SAKUNA Disaster Management Module
    Included by sakuna.blade.php — NO x-data at root.
    Parent Alpine state: centerSearch, centerStatusFilter, selectedCenter, showCenterDetail,
    showCreateCenter, showOpenCenterConfirm, showCloseCenterConfirm, pendingCenterAction
    Helpers: statusBadge(st), occupancyBar(pct), toast(msg, variant)
--}}

<div x-data="{
    viewMode: 'grid',
    centerBarangayFilter: '',
    closeCenterConfirmed: false,

    centerRowVisible(name, barangay, status) {
        const q = centerSearch.toLowerCase();
        const matchSearch = !q || name.toLowerCase().includes(q) || barangay.toLowerCase().includes(q);
        const matchStatus = !centerStatusFilter || status === centerStatusFilter;
        const matchBrgy   = !this.centerBarangayFilter || barangay === this.centerBarangayFilter;
        return matchSearch && matchStatus && matchBrgy;
    },

    occupancyPct(occupants, capacity) {
        if (!capacity) return 0;
        return Math.min(100, Math.round((occupants / capacity) * 100));
    },

    occupancyLabel(pct) {
        if (pct >= 90) return 'Full';
        if (pct >= 75) return 'Near Capacity';
        return 'Available';
    },
}" class="space-y-5">

{{-- ── Header ──────────────────────────────────────────────────────────────────────────── --}}
<div class="flex flex-wrap items-start justify-between gap-3">
    <div>
        <h2 class="text-lg font-semibold text-slate-800">Evacuation Centers</h2>
        <p class="text-sm text-slate-500 mt-0.5">Manage facility registration, occupancy, services, and center operations.</p>
    </div>
    <div class="flex items-center gap-2 flex-wrap">
        <button @click="toast('Center directory exported.', 'success')"
            class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-2 shadow-card hover:border-slate-300 transition-colors">
            <i data-lucide="download" class="w-4 h-4 text-slate-400"></i> Export
        </button>
        <button @click="showCreateCenter = true; $nextTick(() => window.renderIcons?.())"
            class="inline-flex items-center gap-1.5 text-sm font-medium text-white bg-brand-600 hover:bg-brand-700 rounded-xl px-3 py-2 shadow-card transition-colors">
            <i data-lucide="plus" class="w-4 h-4"></i> Add Center
        </button>
    </div>
</div>

{{-- ── Status + Occupancy Summary ──────────────────────────────────────────────────────── --}}
<div class="flex flex-wrap gap-2 items-center">
    <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">
        <i data-lucide="door-open" class="w-3.5 h-3.5"></i> Open: 6
    </span>
    <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-orange-100 text-orange-700">
        <i data-lucide="triangle-alert" class="w-3.5 h-3.5"></i> Near Capacity: 2
    </span>
    <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-sky-100 text-sky-700">
        <i data-lucide="clock" class="w-3.5 h-3.5"></i> Standby: 2
    </span>
    <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-slate-100 text-slate-600">
        <i data-lucide="circle-x" class="w-3.5 h-3.5"></i> Closed: 1
    </span>
    <span class="mx-1 text-slate-200 select-none">|</span>
    <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-slate-100 text-slate-700">
        <i data-lucide="users" class="w-3.5 h-3.5"></i> Total Cap: 1,820
    </span>
    <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-slate-100 text-slate-700">
        <i data-lucide="user-check" class="w-3.5 h-3.5"></i> Current: 1,028
    </span>
    <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700">
        <i data-lucide="bed" class="w-3.5 h-3.5"></i> Available: 792
    </span>
</div>

{{-- ── Filter Bar ───────────────────────────────────────────────────────────────────────── --}}
<div class="flex flex-wrap gap-2 items-center">
    <div class="relative">
        <i data-lucide="search" class="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"></i>
        <input type="text" x-model="centerSearch"
            placeholder="Search by name or barangay..."
            class="pl-9 pr-3 py-2 text-sm bg-white border border-slate-200 rounded-xl shadow-card focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 w-60 transition-colors">
    </div>
    <select x-model="centerStatusFilter"
        class="text-sm bg-white border border-slate-200 rounded-xl shadow-card px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
        <option value="">All Statuses</option>
        <option>Open</option>
        <option>Near Capacity</option>
        <option>Full</option>
        <option>Standby</option>
        <option>Preparing</option>
        <option>Closed</option>
        <option>Under Inspection</option>
    </select>
    <select x-model="centerBarangayFilter"
        class="text-sm bg-white border border-slate-200 rounded-xl shadow-card px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
        <option value="">All Barangays</option>
        @foreach($barangays as $brgy)
            <option>{{ $brgy }}</option>
        @endforeach
    </select>
    <button @click="centerSearch=''; centerStatusFilter=''; centerBarangayFilter='';"
        class="inline-flex items-center gap-1.5 text-sm text-slate-500 bg-white border border-slate-200 rounded-xl px-3 py-2 shadow-card hover:border-slate-300 transition-colors">
        <i data-lucide="x" class="w-3.5 h-3.5"></i> Clear
    </button>
    {{-- View Toggle --}}
    <div class="ml-auto flex items-center bg-white border border-slate-200 rounded-xl overflow-hidden shadow-card">
        <button @click="viewMode = 'grid'"
            :class="viewMode === 'grid' ? 'bg-brand-50 text-brand-600' : 'text-slate-400 hover:text-slate-600'"
            class="px-3 py-2 transition-colors">
            <i data-lucide="layout-grid" class="w-4 h-4"></i>
        </button>
        <button @click="viewMode = 'table'"
            :class="viewMode === 'table' ? 'bg-brand-50 text-brand-600' : 'text-slate-400 hover:text-slate-600'"
            class="px-3 py-2 border-l border-slate-200 transition-colors">
            <i data-lucide="table" class="w-4 h-4"></i>
        </button>
    </div>
</div>

{{-- ── Centers Grid View ────────────────────────────────────────────────────────────────── --}}
<div x-show="viewMode === 'grid'" class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
    @foreach($centers as $center)
    @php
        $pct = min(100, round($center['occupants'] / max(1, $center['capacity']) * 100));
        $avail = $center['capacity'] - $center['occupants'];
    @endphp
    <div x-show="$store.session.inScope('{{ $center['barangay'] }}') && centerRowVisible('{{ addslashes($center['name']) }}', '{{ $center['barangay'] }}', '{{ $center['status'] }}')"
        class="bg-white rounded-2xl shadow-card border border-slate-100 p-5 flex flex-col gap-3 hover:shadow-md transition-shadow">

        {{-- Top: name + status --}}
        <div class="flex items-start justify-between gap-2">
            <div>
                <h3 class="text-sm font-semibold text-slate-800 leading-tight">{{ $center['name'] }}</h3>
                <p class="text-xs text-slate-500 mt-0.5">{{ $center['barangay'] }} · {{ $center['type'] }}</p>
            </div>
            <span :class="statusBadge('{{ $center['status'] }}')" class="flex-shrink-0">{{ $center['status'] }}</span>
        </div>

        {{-- Occupancy --}}
        <div class="space-y-1.5">
            <div class="flex justify-between text-xs text-slate-500">
                <span>Occupancy</span>
                <span class="{{ $pct >= 90 ? 'text-rose-600 font-semibold' : ($pct >= 75 ? 'text-amber-600 font-medium' : 'text-slate-600') }}">{{ $pct }}%</span>
            </div>
            <div class="h-2 rounded-full bg-slate-100 overflow-hidden">
                <div class="h-2 rounded-full transition-all {{ $pct >= 90 ? 'bg-rose-500' : ($pct >= 75 ? 'bg-amber-500' : 'bg-emerald-500') }}"
                    style="width: {{ $pct }}%"></div>
            </div>
            <p class="text-xs text-slate-500">{{ number_format($center['occupants']) }} / {{ number_format($center['capacity']) }} persons</p>
        </div>

        {{-- Stats Row --}}
        <div class="grid grid-cols-3 gap-2 border-t border-slate-50 pt-3">
            <div class="text-center">
                <p class="text-sm font-semibold text-slate-800">{{ $center['families'] }}</p>
                <p class="text-xs text-slate-400">Families</p>
            </div>
            <div class="text-center border-x border-slate-100">
                <p class="text-sm font-semibold text-slate-800">{{ $center['pwsn'] }}</p>
                <p class="text-xs text-slate-400">PWSN</p>
            </div>
            <div class="text-center">
                <p class="text-sm font-semibold {{ $avail > 0 ? 'text-emerald-600' : 'text-rose-600' }}">{{ number_format($avail) }}</p>
                <p class="text-xs text-slate-400">Available</p>
            </div>
        </div>

        {{-- Manager + Inspection --}}
        <div class="space-y-1 text-xs text-slate-500">
            <div class="flex items-center gap-1.5">
                <i data-lucide="user" class="w-3.5 h-3.5 flex-shrink-0"></i>
                <span class="truncate">{{ $center['manager'] }} · {{ $center['contact'] }}</span>
            </div>
            <div class="flex items-center gap-1.5">
                <i data-lucide="calendar-check" class="w-3.5 h-3.5 flex-shrink-0"></i>
                <span>Last inspected: {{ $center['last_inspection'] }}</span>
            </div>
        </div>

        {{-- Footer Actions --}}
        <div class="flex items-center gap-2 border-t border-slate-50 pt-3 mt-auto">
            <button
                @click="selectedCenter = {{ json_encode($center) }}; showCenterDetail = true; $nextTick(() => window.renderIcons?.())"
                class="flex-1 inline-flex items-center justify-center gap-1.5 text-xs font-medium text-brand-600 bg-brand-50 hover:bg-brand-100 px-3 py-2 rounded-xl transition-colors">
                <i data-lucide="eye" class="w-3.5 h-3.5"></i> View Details
            </button>
            @if(in_array($center['status'], ['Standby', 'Closed']))
                <button
                    @click="pendingCenterAction = {{ json_encode($center) }}; showOpenCenterConfirm = true; $nextTick(() => window.renderIcons?.())"
                    class="flex-1 inline-flex items-center justify-center gap-1.5 text-xs font-medium text-emerald-700 bg-emerald-50 hover:bg-emerald-100 px-3 py-2 rounded-xl transition-colors">
                    <i data-lucide="door-open" class="w-3.5 h-3.5"></i> Open
                </button>
            @elseif(in_array($center['status'], ['Open', 'Near Capacity', 'Full']))
                <button
                    @click="pendingCenterAction = {{ json_encode($center) }}; closeCenterConfirmed = false; showCloseCenterConfirm = true; $nextTick(() => window.renderIcons?.())"
                    class="flex-1 inline-flex items-center justify-center gap-1.5 text-xs font-medium text-slate-600 border border-slate-200 hover:bg-slate-50 px-3 py-2 rounded-xl transition-colors">
                    <i data-lucide="circle-x" class="w-3.5 h-3.5"></i> Close
                </button>
            @endif
        </div>
    </div>
    @endforeach
</div>

{{-- ── Centers Table View ───────────────────────────────────────────────────────────────── --}}
<div x-show="viewMode === 'table'" class="bg-white rounded-2xl shadow-card border border-slate-100 overflow-hidden">
    <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-slate-100">
            <thead>
                <tr class="bg-slate-50">
                    <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">Center</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">Barangay</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">Status</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">Occupancy</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">Families / PWSN</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">Manager</th>
                    <th class="px-4 py-3 text-right text-xs font-semibold text-slate-500 uppercase tracking-wider">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-50">
                @foreach($centers as $center)
                @php $pct = min(100, round($center['occupants'] / max(1, $center['capacity']) * 100)); @endphp
                <tr x-show="$store.session.inScope('{{ $center['barangay'] }}') && centerRowVisible('{{ addslashes($center['name']) }}', '{{ $center['barangay'] }}', '{{ $center['status'] }}')"
                    class="hover:bg-slate-50/60 transition-colors">
                    <td class="px-4 py-3">
                        <p class="text-sm font-medium text-slate-800">{{ $center['name'] }}</p>
                        <p class="text-xs text-slate-400">{{ $center['type'] }}</p>
                    </td>
                    <td class="px-4 py-3 text-sm text-slate-600 whitespace-nowrap">{{ $center['barangay'] }}</td>
                    <td class="px-4 py-3 whitespace-nowrap">
                        <span :class="statusBadge('{{ $center['status'] }}')">{{ $center['status'] }}</span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap">
                        <div class="flex items-center gap-2">
                            <div class="w-24 h-1.5 rounded-full bg-slate-100 overflow-hidden">
                                <div class="h-1.5 rounded-full {{ $pct >= 90 ? 'bg-rose-500' : ($pct >= 75 ? 'bg-amber-500' : 'bg-emerald-500') }}"
                                    style="width: {{ $pct }}%"></div>
                            </div>
                            <span class="text-xs text-slate-600">{{ $center['occupants'] }}/{{ $center['capacity'] }}</span>
                        </div>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-sm text-slate-600">{{ $center['families'] }} fam · {{ $center['pwsn'] }} PWSN</td>
                    <td class="px-4 py-3 whitespace-nowrap text-sm text-slate-600">{{ $center['manager'] }}</td>
                    <td class="px-4 py-3 whitespace-nowrap text-right">
                        <div class="flex items-center justify-end gap-1.5">
                            <button
                                @click="selectedCenter = {{ json_encode($center) }}; showCenterDetail = true; $nextTick(() => window.renderIcons?.())"
                                class="inline-flex items-center gap-1 text-xs font-medium text-brand-600 bg-brand-50 hover:bg-brand-100 px-2.5 py-1.5 rounded-lg transition-colors">
                                <i data-lucide="eye" class="w-3.5 h-3.5"></i> View
                            </button>
                            @if(in_array($center['status'], ['Standby', 'Closed']))
                                <button
                                    @click="pendingCenterAction = {{ json_encode($center) }}; showOpenCenterConfirm = true; $nextTick(() => window.renderIcons?.())"
                                    class="inline-flex items-center gap-1 text-xs font-medium text-emerald-700 bg-emerald-50 hover:bg-emerald-100 px-2.5 py-1.5 rounded-lg transition-colors">
                                    <i data-lucide="door-open" class="w-3.5 h-3.5"></i> Open
                                </button>
                            @elseif(in_array($center['status'], ['Open', 'Near Capacity', 'Full']))
                                <button
                                    @click="pendingCenterAction = {{ json_encode($center) }}; closeCenterConfirmed = false; showCloseCenterConfirm = true; $nextTick(() => window.renderIcons?.())"
                                    class="inline-flex items-center gap-1 text-xs font-medium text-slate-600 border border-slate-200 hover:bg-slate-50 px-2.5 py-1.5 rounded-lg transition-colors">
                                    <i data-lucide="circle-x" class="w-3.5 h-3.5"></i> Close
                                </button>
                            @endif
                        </div>
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</div>

{{-- ────────────────────────────────────────────────────────────────────────────────────── --}}
{{-- CENTER DETAIL MODAL                                                                    --}}
{{-- ────────────────────────────────────────────────────────────────────────────────────── --}}
<div x-show="showCenterDetail" x-cloak
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
    @click.self="showCenterDetail = false"
    x-transition:enter="transition ease-out duration-200"
    x-transition:enter-start="opacity-0"
    x-transition:enter-end="opacity-100"
    x-transition:leave="transition ease-in duration-150"
    x-transition:leave-start="opacity-100"
    x-transition:leave-end="opacity-0">

    <div x-data="{ centerTab: 'overview' }"
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0 scale-95"
        x-transition:enter-end="opacity-100 scale-100"
        class="bg-white rounded-2xl shadow-float w-full max-w-4xl max-h-[90vh] overflow-y-auto">

        {{-- Header --}}
        <div class="flex items-start justify-between px-6 pt-6 pb-4 border-b border-slate-100 sticky top-0 bg-white rounded-t-2xl z-10">
            <div class="flex items-start gap-3">
                <div class="flex-shrink-0 w-10 h-10 rounded-xl bg-emerald-50 flex items-center justify-center mt-0.5">
                    <i data-lucide="building-2" class="w-5 h-5 text-emerald-600"></i>
                </div>
                <div>
                    <h3 class="text-base font-semibold text-slate-800" x-text="selectedCenter?.name || '—'"></h3>
                    <p class="text-xs text-slate-400 mt-0.5" x-text="(selectedCenter?.barangay || '') + ' · ' + (selectedCenter?.type || '')"></p>
                </div>
            </div>
            <button @click="showCenterDetail = false"
                class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-100 text-slate-400 transition-colors">
                <i data-lucide="x" class="w-4 h-4"></i>
            </button>
        </div>

        {{-- Mini Tabs --}}
        <div class="flex overflow-x-auto border-b border-slate-100 px-6 scrollbar-none">
            @foreach(['overview' => 'Overview', 'services' => 'Services', 'personnel' => 'Personnel', 'occupants' => 'Occupants', 'history' => 'History', 'activity' => 'Activity'] as $tab => $label)
            <button @click="centerTab = '{{ $tab }}'"
                :class="centerTab === '{{ $tab }}' ? 'border-b-2 border-brand-600 text-brand-600 font-medium' : 'text-slate-500 hover:text-slate-700'"
                class="text-sm px-4 py-3 whitespace-nowrap transition-colors flex-shrink-0">{{ $label }}</button>
            @endforeach
        </div>

        {{-- Tab: Overview --}}
        <div x-show="centerTab === 'overview'" class="p-6 space-y-5">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                {{-- Identity --}}
                <div class="bg-slate-50 rounded-xl p-4 space-y-2.5">
                    <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Facility Identity</h4>
                    <div class="space-y-2 text-sm">
                        <div class="flex justify-between"><span class="text-slate-500">Center ID</span><span class="font-medium text-slate-800" x-text="selectedCenter?.id || '—'"></span></div>
                        <div class="flex justify-between"><span class="text-slate-500">Name</span><span class="font-medium text-slate-800 text-right max-w-[60%]" x-text="selectedCenter?.name || '—'"></span></div>
                        <div class="flex justify-between"><span class="text-slate-500">Barangay</span><span class="font-medium text-slate-800" x-text="selectedCenter?.barangay || '—'"></span></div>
                        <div class="flex justify-between"><span class="text-slate-500">Type</span><span class="font-medium text-slate-800" x-text="selectedCenter?.type || '—'"></span></div>
                        <div class="flex justify-between"><span class="text-slate-500">Manager</span><span class="font-medium text-slate-800" x-text="selectedCenter?.manager || '—'"></span></div>
                        <div class="flex justify-between"><span class="text-slate-500">Contact</span><span class="font-medium text-slate-800" x-text="selectedCenter?.contact || '—'"></span></div>
                    </div>
                </div>
                {{-- Capacity --}}
                <div class="bg-slate-50 rounded-xl p-4 space-y-2.5">
                    <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Capacity & Occupancy</h4>
                    <div class="space-y-2 text-sm">
                        <div class="flex justify-between"><span class="text-slate-500">Recommended</span><span class="font-medium text-slate-800" x-text="selectedCenter?.capacity || '—'"></span></div>
                        <div class="flex justify-between"><span class="text-slate-500">Max Emergency</span><span class="font-medium text-slate-800" x-text="selectedCenter?.max_capacity || '—'"></span></div>
                        <div class="flex justify-between"><span class="text-slate-500">Current Occupants</span><span class="font-medium text-slate-800" x-text="selectedCenter?.occupants || 0"></span></div>
                        <div class="flex justify-between"><span class="text-slate-500">Families</span><span class="font-medium text-slate-800" x-text="selectedCenter?.families || 0"></span></div>
                        <div class="flex justify-between"><span class="text-slate-500">PWSN</span><span class="font-medium text-slate-800" x-text="selectedCenter?.pwsn || 0"></span></div>
                        <div class="flex justify-between"><span class="text-slate-500">Available Spaces</span>
                            <span class="font-medium text-emerald-600" x-text="selectedCenter ? (selectedCenter.capacity - selectedCenter.occupants) : '—'"></span>
                        </div>
                    </div>
                </div>
            </div>

            {{-- Structural --}}
            <div class="bg-slate-50 rounded-xl p-4">
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">Structural Assessment</h4>
                <div class="flex flex-wrap items-center gap-4 text-sm">
                    <div class="flex items-center gap-2">
                        <span class="text-slate-500">Safety Rating:</span>
                        <span :class="{
                            'bg-emerald-100 text-emerald-700': selectedCenter?.safety_rating === 'Very Good' || selectedCenter?.safety_rating === 'Excellent',
                            'bg-sky-100 text-sky-700': selectedCenter?.safety_rating === 'Good',
                            'bg-amber-100 text-amber-700': selectedCenter?.safety_rating === 'Fair',
                            'bg-rose-100 text-rose-700': selectedCenter?.safety_rating === 'Poor'
                        }" class="px-2.5 py-0.5 rounded-full text-xs font-semibold" x-text="selectedCenter?.safety_rating || '—'"></span>
                    </div>
                    <div class="flex items-center gap-2">
                        <span class="text-slate-500">Last Inspection:</span>
                        <span class="font-medium text-slate-800" x-text="selectedCenter?.last_inspection || '—'"></span>
                    </div>
                    <div class="flex items-center gap-2">
                        <span class="text-slate-500">Hazard Exposure:</span>
                        <span class="inline-flex gap-1">
                            <span class="bg-sky-100 text-sky-700 px-2 py-0.5 rounded-full text-xs font-medium">Flooding</span>
                            <span class="bg-orange-100 text-orange-700 px-2 py-0.5 rounded-full text-xs font-medium">Fire</span>
                        </span>
                    </div>
                </div>
            </div>

            {{-- Zone Breakdown --}}
            <div class="bg-slate-50 rounded-xl p-4">
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">Zone / Room Breakdown</h4>
                <div class="overflow-x-auto">
                    <table class="min-w-full text-sm">
                        <thead>
                            <tr class="text-left">
                                <th class="pb-2 text-xs font-semibold text-slate-400 pr-6">Zone</th>
                                <th class="pb-2 text-xs font-semibold text-slate-400 pr-6">Capacity</th>
                                <th class="pb-2 text-xs font-semibold text-slate-400 pr-6">Occupants</th>
                                <th class="pb-2 text-xs font-semibold text-slate-400">Utilization</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100">
                            @foreach([
                                ['Room 1-A', 50, 42],
                                ['Room 1-B', 50, 45],
                                ['Main Hall', 100, 88],
                                ['Stage Area', 50, 23],
                            ] as [$zone, $cap, $occ])
                            @php $zpct = round($occ / $cap * 100); @endphp
                            <tr>
                                <td class="py-2 pr-6 font-medium text-slate-700">{{ $zone }}</td>
                                <td class="py-2 pr-6 text-slate-600">{{ $cap }}</td>
                                <td class="py-2 pr-6 text-slate-600">{{ $occ }}</td>
                                <td class="py-2">
                                    <div class="flex items-center gap-2">
                                        <div class="w-20 h-1.5 rounded-full bg-slate-200 overflow-hidden">
                                            <div class="h-1.5 rounded-full {{ $zpct >= 90 ? 'bg-rose-500' : ($zpct >= 75 ? 'bg-amber-500' : 'bg-emerald-500') }}" style="width: {{ $zpct }}%"></div>
                                        </div>
                                        <span class="text-xs text-slate-500">{{ $zpct }}%</span>
                                    </div>
                                </td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        {{-- Tab: Services --}}
        <div x-show="centerTab === 'services'" class="p-6 space-y-6">
            @php
            $serviceGroups = [
                'Water & Sanitation' => [
                    ['Potable Water', 'droplets', 'Available'],
                    ['Toilets', 'toilet', 'Available'],
                    ['Bathing Facilities', 'shower-head', 'Limited'],
                    ['Handwashing Stations', 'hand-metal', 'Available'],
                    ['Drainage', 'filter', 'Available'],
                    ['Waste Collection', 'trash-2', 'Available'],
                ],
                'Power & Connectivity' => [
                    ['Electricity', 'zap', 'Available'],
                    ['Backup Generator', 'battery-charging', 'Limited'],
                    ['Charging Area', 'plug', 'Limited'],
                    ['Mobile Signal', 'signal', 'Available'],
                    ['Internet / WiFi', 'wifi', 'Unavailable'],
                ],
                'Food & Shelter' => [
                    ['Kitchen Facility', 'utensils', 'Unavailable'],
                    ['Food Preparation Area', 'chef-hat', 'Limited'],
                    ['Sleeping Spaces', 'bed', 'Available'],
                    ['Family Spaces', 'users', 'Available'],
                    ['Relief Distribution Point', 'package', 'Available'],
                ],
                'Medical' => [
                    ['Medical Station', 'heart-pulse', 'Available'],
                    ['First-Aid Supplies', 'first-aid', 'Available'],
                    ['Medicine Storage', 'pill', 'Limited'],
                    ['Isolation Room', 'shield', 'Unavailable'],
                    ['Ambulance Access', 'truck', 'Available'],
                ],
                'Special Spaces' => [
                    ['Child-Friendly Space', 'smile', 'Limited'],
                    ['Women-Friendly Space', 'heart', 'Available'],
                    ['Breastfeeding Area', 'baby', 'Limited'],
                    ['Senior Citizen Area', 'person-standing', 'Available'],
                    ['Psychosocial Support', 'brain', 'Limited'],
                    ['Pet Holding Area', 'paw-print', 'Unavailable'],
                    ['Livestock Area', 'fence', 'Unavailable'],
                ],
                'Access & Safety' => [
                    ['PWD-Accessible Entrance', 'accessibility', 'Available'],
                    ['PWD-Accessible Toilet', 'accessibility', 'Limited'],
                    ['Security Post', 'shield-check', 'Available'],
                    ['Help Desk', 'info', 'Available'],
                    ['Registration Desk', 'clipboard', 'Available'],
                    ['Transport Loading Zone', 'map-pin', 'Available'],
                ],
            ];
            @endphp

            @foreach($serviceGroups as $groupName => $services)
            <div>
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">{{ $groupName }}</h4>
                <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-2">
                    @foreach($services as [$name, $icon, $status])
                    <div class="flex items-center justify-between bg-slate-50 rounded-xl px-3 py-2.5 gap-2">
                        <div class="flex items-center gap-2">
                            <i data-lucide="{{ $icon }}" class="w-4 h-4 text-slate-400 flex-shrink-0"></i>
                            <span class="text-xs text-slate-700">{{ $name }}</span>
                        </div>
                        <span class="text-xs font-medium px-2 py-0.5 rounded-full flex-shrink-0 {{ match($status) {
                            'Available'   => 'bg-emerald-100 text-emerald-700',
                            'Limited'     => 'bg-amber-100 text-amber-700',
                            'Unavailable' => 'bg-rose-100 text-rose-700',
                            default       => 'bg-slate-100 text-slate-500',
                        } }}">{{ $status }}</span>
                    </div>
                    @endforeach
                </div>
            </div>
            @endforeach
        </div>

        {{-- Tab: Personnel --}}
        <div x-show="centerTab === 'personnel'" class="p-6 space-y-4">
            <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Assigned Personnel</h4>
            @foreach([
                ['Elvira N. Sison', 'Center Manager', '09175551234', '07:00 AM – 07:00 PM', 'building-2'],
                ['Carla M. Magtibay', 'MSWD Social Worker', '09185552345', '08:00 AM – 05:00 PM', 'heart-handshake'],
                ['Rowena T. Dela Cruz', 'RHU Nurse on Duty', '09195553456', '07:00 AM – 07:00 PM', 'heart-pulse'],
            ] as [$name, $role, $contact, $shift, $icon])
            <div class="flex items-start gap-4 bg-slate-50 rounded-xl p-4">
                <div class="w-10 h-10 rounded-xl bg-brand-50 flex items-center justify-center flex-shrink-0">
                    <i data-lucide="{{ $icon }}" class="w-5 h-5 text-brand-600"></i>
                </div>
                <div class="flex-1 min-w-0">
                    <p class="text-sm font-semibold text-slate-800">{{ $name }}</p>
                    <p class="text-xs text-slate-500 mt-0.5">{{ $role }}</p>
                    <div class="flex flex-wrap gap-3 mt-2 text-xs text-slate-500">
                        <span class="flex items-center gap-1"><i data-lucide="phone" class="w-3 h-3"></i>{{ $contact }}</span>
                        <span class="flex items-center gap-1"><i data-lucide="clock" class="w-3 h-3"></i>{{ $shift }}</span>
                    </div>
                </div>
            </div>
            @endforeach
        </div>

        {{-- Tab: Occupants --}}
        <div x-show="centerTab === 'occupants'" class="p-6 space-y-5">
            <div class="grid grid-cols-2 sm:grid-cols-3 gap-4">
                <div class="bg-slate-50 rounded-xl p-4 text-center">
                    <p class="text-2xl font-bold text-slate-800" x-text="selectedCenter?.occupants ?? '—'"></p>
                    <p class="text-xs text-slate-500 mt-0.5">Total Individuals</p>
                </div>
                <div class="bg-slate-50 rounded-xl p-4 text-center">
                    <p class="text-2xl font-bold text-slate-800" x-text="selectedCenter?.families ?? '—'"></p>
                    <p class="text-xs text-slate-500 mt-0.5">Families</p>
                </div>
                <div class="bg-slate-50 rounded-xl p-4 text-center">
                    <p class="text-2xl font-bold text-rose-600" x-text="selectedCenter?.pwsn ?? '—'"></p>
                    <p class="text-xs text-slate-500 mt-0.5">PWSN</p>
                </div>
            </div>
            <div class="bg-slate-50 rounded-xl p-4">
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">Demographics</h4>
                <div class="overflow-x-auto">
                    <table class="min-w-full text-sm">
                        <thead>
                            <tr class="text-left border-b border-slate-200">
                                <th class="pb-2 text-xs font-semibold text-slate-400">Group</th>
                                <th class="pb-2 text-xs font-semibold text-slate-400 text-right">Count</th>
                                <th class="pb-2 text-xs font-semibold text-slate-400 text-right pl-8">Group</th>
                                <th class="pb-2 text-xs font-semibold text-slate-400 text-right">Count</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100">
                            <tr>
                                <td class="py-2 text-slate-600">Children (0–5 yrs)</td>
                                <td class="py-2 text-slate-800 font-medium text-right">18</td>
                                <td class="py-2 text-slate-600 pl-8">Adults (18–59 yrs)</td>
                                <td class="py-2 text-slate-800 font-medium text-right">132</td>
                            </tr>
                            <tr>
                                <td class="py-2 text-slate-600">School-Age (6–17 yrs)</td>
                                <td class="py-2 text-slate-800 font-medium text-right">24</td>
                                <td class="py-2 text-slate-600 pl-8">Senior Citizens (60+)</td>
                                <td class="py-2 text-slate-800 font-medium text-right">15</td>
                            </tr>
                            <tr>
                                <td class="py-2 text-slate-600">PWD</td>
                                <td class="py-2 text-rose-600 font-medium text-right">6</td>
                                <td class="py-2 text-slate-600 pl-8">Pregnant Women</td>
                                <td class="py-2 text-rose-600 font-medium text-right">2</td>
                            </tr>
                            <tr>
                                <td class="py-2 text-slate-600">Need Medication</td>
                                <td class="py-2 text-amber-600 font-medium text-right">11</td>
                                <td class="py-2"></td>
                                <td class="py-2"></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
            <div class="flex justify-end">
                <button @click="toast('Full evacuee list view coming in Evacuees tab.', 'info')"
                    class="inline-flex items-center gap-1.5 text-sm font-medium text-brand-600 bg-brand-50 hover:bg-brand-100 px-4 py-2 rounded-xl transition-colors">
                    <i data-lucide="users" class="w-4 h-4"></i> View Full Evacuee List
                </button>
            </div>
        </div>

        {{-- Tab: History --}}
        <div x-show="centerTab === 'history'" class="p-6 space-y-4">
            <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Inspection History</h4>
            @foreach([
                ['Jul 1, 2026', 'MDRRMO Inspector', 'Very Good', 'bg-emerald-100 text-emerald-700', 'Electrical wiring checked and cleared. Drainage system verified clean. No structural issues found.'],
                ['Apr 15, 2026', 'MDRRMO Inspector', 'Good', 'bg-sky-100 text-sky-700', 'Minor repairs needed on CR drainage. Toilet facilities require regrouting. Recommended repair within 30 days.'],
                ['Jan 10, 2026', 'LGU Inspection Team', 'Good', 'bg-sky-100 text-sky-700', 'Annual pre-disaster readiness inspection. Roof structure sound. Generator functional. Exit signage added.'],
            ] as [$date, $inspector, $rating, $ratingClass, $notes])
            <div class="bg-slate-50 rounded-xl p-4 space-y-2">
                <div class="flex flex-wrap items-center justify-between gap-2">
                    <div class="flex items-center gap-2">
                        <span class="text-sm font-semibold text-slate-800">{{ $date }}</span>
                        <span class="{{ $ratingClass }} text-xs font-semibold px-2.5 py-0.5 rounded-full">{{ $rating }}</span>
                    </div>
                    <span class="text-xs text-slate-500">{{ $inspector }}</span>
                </div>
                <p class="text-xs text-slate-600 leading-relaxed">{{ $notes }}</p>
            </div>
            @endforeach
        </div>

        {{-- Tab: Activity --}}
        <div x-show="centerTab === 'activity'" class="p-6">
            <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-4">Activity Log</h4>
            <ol class="relative border-l border-slate-200 space-y-5 ml-3">
                @foreach([
                    ['Jul 15, 2026 08:20 AM', 'Relief goods staging commenced', 'DSWD/MSWD field team arrived with food packs and hygiene kits.', 'package', 'bg-amber-100 text-amber-600'],
                    ['Jul 15, 2026 08:15 AM', 'Generator activated', 'Backup power enabled to support medical station equipment.', 'zap', 'bg-yellow-100 text-yellow-600'],
                    ['Jul 15, 2026 08:10 AM', 'Medical team deployed', 'RHU nurse and MSWD social worker reported to center.', 'heart-pulse', 'bg-rose-100 text-rose-600'],
                    ['Jul 15, 2026 07:30 AM', '7 families (35 persons) checked in', 'Initial evacuees from Sitio Lawod, Barangay Rizal.', 'users', 'bg-brand-50 text-brand-600'],
                    ['Jul 15, 2026 08:00 AM', 'Center opened by MDRRMO Head', 'EOC activation issued. Center officially opened for displaced families.', 'door-open', 'bg-emerald-100 text-emerald-600'],
                    ['Jul 14, 2026 08:30 PM', 'Center placed on Standby', 'MDRRMO pre-positioned personnel and supplies ahead of monsoon surge.', 'clock', 'bg-slate-100 text-slate-500'],
                ] as [$time, $title, $desc, $icon, $iconClass])
                <li class="ml-6">
                    <span class="absolute -left-3 flex items-center justify-center w-6 h-6 {{ $iconClass }} rounded-full ring-4 ring-white">
                        <i data-lucide="{{ $icon }}" class="w-3 h-3"></i>
                    </span>
                    <p class="text-xs text-slate-400 mb-0.5">{{ $time }}</p>
                    <p class="text-sm font-medium text-slate-800">{{ $title }}</p>
                    <p class="text-xs text-slate-500 mt-0.5">{{ $desc }}</p>
                </li>
                @endforeach
            </ol>
        </div>

        {{-- Modal Footer --}}
        <div class="flex flex-wrap items-center justify-between gap-2 px-6 py-4 border-t border-slate-100 bg-slate-50/70 rounded-b-2xl sticky bottom-0">
            <div class="flex flex-wrap gap-2">
                <button @click="toast('Edit mode for evacuation centers coming soon.', 'info')"
                    class="inline-flex items-center gap-1.5 text-xs font-medium text-slate-700 bg-white border border-slate-200 hover:border-slate-300 px-3 py-1.5 rounded-lg transition-colors">
                    <i data-lucide="pencil" class="w-3.5 h-3.5"></i> Edit
                </button>
                <button @click="toast('Inspection scheduled for this center.', 'success')"
                    class="inline-flex items-center gap-1.5 text-xs font-medium text-brand-600 bg-brand-50 hover:bg-brand-100 px-3 py-1.5 rounded-lg transition-colors">
                    <i data-lucide="clipboard-check" class="w-3.5 h-3.5"></i> Inspect
                </button>
                <button @click="toast('Supply request created. DSWD liaison notified.', 'success')"
                    class="inline-flex items-center gap-1.5 text-xs font-medium text-amber-700 bg-amber-50 hover:bg-amber-100 px-3 py-1.5 rounded-lg transition-colors">
                    <i data-lucide="package-plus" class="w-3.5 h-3.5"></i> Request Supplies
                </button>
                <button @click="toast('Center profile sent to printer.', 'info')"
                    class="inline-flex items-center gap-1.5 text-xs font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 px-3 py-1.5 rounded-lg transition-colors">
                    <i data-lucide="printer" class="w-3.5 h-3.5"></i> Print Profile
                </button>
            </div>
            <button @click="showCenterDetail = false"
                class="text-sm text-slate-500 hover:text-slate-700 px-3 py-1.5 rounded-lg hover:bg-slate-100 transition-colors">
                Close
            </button>
        </div>
    </div>
</div>

{{-- ────────────────────────────────────────────────────────────────────────────────────── --}}
{{-- OPEN CENTER CONFIRMATION MODAL                                                         --}}
{{-- ────────────────────────────────────────────────────────────────────────────────────── --}}
<div x-show="showOpenCenterConfirm" x-cloak
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
    @click.self="showOpenCenterConfirm = false"
    x-transition:enter="transition ease-out duration-200"
    x-transition:enter-start="opacity-0"
    x-transition:enter-end="opacity-100"
    x-transition:leave="transition ease-in duration-150"
    x-transition:leave-start="opacity-100"
    x-transition:leave-end="opacity-0">

    <div x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0 scale-95"
        x-transition:enter-end="opacity-100 scale-100"
        class="bg-white rounded-2xl shadow-float w-full max-w-md p-6">

        <div class="flex items-center gap-3 mb-4">
            <span class="w-10 h-10 rounded-xl bg-emerald-50 flex items-center justify-center flex-shrink-0">
                <i data-lucide="door-open" class="w-5 h-5 text-emerald-600"></i>
            </span>
            <h3 class="text-base font-semibold text-slate-800">Open Evacuation Center</h3>
        </div>

        <p class="text-sm text-slate-600 leading-relaxed mb-1">
            You are about to open
            <strong class="text-slate-800" x-text="pendingCenterAction?.name || 'this center'"></strong>
            as an official evacuation center for this operational period.
        </p>
        <p class="text-sm text-slate-500 leading-relaxed mb-5">
            This action will notify the center manager and relevant MDRRMO personnel. The center will appear as active in the evacuation directory.
        </p>

        <div class="flex items-center justify-end gap-3">
            <button @click="showOpenCenterConfirm = false"
                class="text-sm text-slate-600 bg-white border border-slate-200 hover:border-slate-300 px-4 py-2 rounded-xl transition-colors">
                Cancel
            </button>
            <button @click="toast('Center opened. Center manager and DSWD have been notified.', 'success'); showOpenCenterConfirm = false; $nextTick(() => window.renderIcons?.())"
                class="inline-flex items-center gap-1.5 text-sm font-medium text-white bg-emerald-600 hover:bg-emerald-700 px-5 py-2 rounded-xl transition-colors">
                <i data-lucide="check" class="w-4 h-4"></i> Confirm Open
            </button>
        </div>
    </div>
</div>

{{-- ────────────────────────────────────────────────────────────────────────────────────── --}}
{{-- CLOSE CENTER CONFIRMATION MODAL                                                        --}}
{{-- ────────────────────────────────────────────────────────────────────────────────────── --}}
<div x-show="showCloseCenterConfirm" x-cloak
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
    @click.self="showCloseCenterConfirm = false"
    x-transition:enter="transition ease-out duration-200"
    x-transition:enter-start="opacity-0"
    x-transition:enter-end="opacity-100"
    x-transition:leave="transition ease-in duration-150"
    x-transition:leave-start="opacity-100"
    x-transition:leave-end="opacity-0">

    <div x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0 scale-95"
        x-transition:enter-end="opacity-100 scale-100"
        class="bg-white rounded-2xl shadow-float w-full max-w-md p-6">

        <div class="flex items-center gap-3 mb-4">
            <span class="w-10 h-10 rounded-xl bg-rose-50 flex items-center justify-center flex-shrink-0">
                <i data-lucide="circle-x" class="w-5 h-5 text-rose-600"></i>
            </span>
            <h3 class="text-base font-semibold text-slate-800">Close Evacuation Center</h3>
        </div>

        {{-- Warning if center has occupants --}}
        <template x-if="pendingCenterAction && pendingCenterAction.occupants > 0">
            <div class="bg-amber-50 border border-amber-100 rounded-xl p-3.5 mb-4 flex items-start gap-2.5">
                <i data-lucide="triangle-alert" class="w-4 h-4 text-amber-600 flex-shrink-0 mt-0.5"></i>
                <div>
                    <p class="text-sm font-semibold text-amber-800">Center has active occupants</p>
                    <p class="text-xs text-amber-700 mt-0.5">
                        This center currently has <span class="font-bold" x-text="pendingCenterAction.occupants"></span> occupants
                        across <span class="font-bold" x-text="pendingCenterAction.families"></span> families.
                        All occupants must be checked out or transferred before closing.
                        Override close requires supervisor authorization.
                    </p>
                </div>
            </div>
        </template>

        <p class="text-sm text-slate-600 leading-relaxed mb-4">
            Closing <strong class="text-slate-800" x-text="pendingCenterAction?.name || 'this center'"></strong> will remove it from the active evacuation directory and notify the center manager.
        </p>

        {{-- Confirmation checkbox --}}
        <label class="flex items-start gap-3 cursor-pointer mb-5 select-none">
            <input type="checkbox" x-model="closeCenterConfirmed"
                class="w-4 h-4 mt-0.5 rounded border-slate-300 text-brand-600 focus:ring-brand-400 flex-shrink-0">
            <span class="text-sm text-slate-700">
                I confirm that all occupants have been safely transferred or checked out, and this center is cleared for closure.
            </span>
        </label>

        <div class="flex items-center justify-end gap-3">
            <button @click="showCloseCenterConfirm = false; closeCenterConfirmed = false;"
                class="text-sm text-slate-600 bg-white border border-slate-200 hover:border-slate-300 px-4 py-2 rounded-xl transition-colors">
                Cancel
            </button>
            <button
                :disabled="!closeCenterConfirmed"
                :class="closeCenterConfirmed ? 'bg-rose-600 hover:bg-rose-700 text-white cursor-pointer' : 'bg-slate-100 text-slate-400 cursor-not-allowed'"
                @click="if(closeCenterConfirmed){ toast('Center closed and removed from active operations.', 'success'); showCloseCenterConfirm = false; closeCenterConfirmed = false; $nextTick(() => window.renderIcons?.()); }"
                class="inline-flex items-center gap-1.5 text-sm font-medium px-5 py-2 rounded-xl transition-colors">
                <i data-lucide="circle-x" class="w-4 h-4"></i> Confirm Close
            </button>
        </div>
    </div>
</div>

{{-- ────────────────────────────────────────────────────────────────────────────────────── --}}
{{-- ADD CENTER MODAL                                                                       --}}
{{-- ────────────────────────────────────────────────────────────────────────────────────── --}}
<div x-show="showCreateCenter" x-cloak
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
    @click.self="showCreateCenter = false"
    x-transition:enter="transition ease-out duration-200"
    x-transition:enter-start="opacity-0"
    x-transition:enter-end="opacity-100"
    x-transition:leave="transition ease-in duration-150"
    x-transition:leave-start="opacity-100"
    x-transition:leave-end="opacity-0">

    <div x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0 scale-95"
        x-transition:enter-end="opacity-100 scale-100"
        class="bg-white rounded-2xl shadow-float w-full max-w-xl max-h-[90vh] overflow-y-auto">

        {{-- Header --}}
        <div class="flex items-center justify-between px-6 pt-6 pb-4 border-b border-slate-100 sticky top-0 bg-white rounded-t-2xl z-10">
            <div class="flex items-center gap-3">
                <span class="w-9 h-9 rounded-xl bg-brand-50 flex items-center justify-center">
                    <i data-lucide="building-2" class="w-5 h-5 text-brand-600"></i>
                </span>
                <div>
                    <h3 class="text-base font-semibold text-slate-800">Register Evacuation Center</h3>
                    <p class="text-xs text-slate-400">Add a new facility to the evacuation center directory.</p>
                </div>
            </div>
            <button @click="showCreateCenter = false"
                class="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-100 text-slate-400 transition-colors">
                <i data-lucide="x" class="w-4 h-4"></i>
            </button>
        </div>

        {{-- Form --}}
        <div class="px-6 py-5 space-y-4">
            {{-- Center Name --}}
            <div>
                <label class="block text-xs font-medium text-slate-700 mb-1.5">Center Name <span class="text-rose-500">*</span></label>
                <input type="text" placeholder="e.g. Poblacion Elementary School"
                    class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {{-- Barangay --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Barangay <span class="text-rose-500">*</span></label>
                    <select class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                        <option value="">Select barangay...</option>
                        @foreach($barangays as $brgy)
                            <option>{{ $brgy }}</option>
                        @endforeach
                    </select>
                </div>
                {{-- Facility Type --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Facility Type <span class="text-rose-500">*</span></label>
                    <select class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                        <option value="">Select type...</option>
                        <option>School</option>
                        <option>Barangay Hall</option>
                        <option>Covered Court</option>
                        <option>Municipal Building</option>
                        <option>Multi-Purpose Hall</option>
                        <option>Church Facility</option>
                        <option>Temporary Tent Site</option>
                        <option>Other</option>
                    </select>
                </div>
            </div>

            {{-- Full Address --}}
            <div>
                <label class="block text-xs font-medium text-slate-700 mb-1.5">Full Address</label>
                <input type="text" placeholder="Street / Sitio, Barangay, Esperanza, Masbate"
                    class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {{-- Recommended Capacity --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Recommended Capacity <span class="text-rose-500">*</span></label>
                    <input type="number" min="0" placeholder="e.g. 200"
                        class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                </div>
                {{-- Max Emergency Capacity --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Max Emergency Capacity</label>
                    <input type="number" min="0" placeholder="e.g. 250"
                        class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                </div>
                {{-- Center Manager Name --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Center Manager Name <span class="text-rose-500">*</span></label>
                    <input type="text" placeholder="Full name"
                        class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                </div>
                {{-- Contact Number --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Contact Number</label>
                    <input type="tel" placeholder="09XXXXXXXXX"
                        class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                </div>
            </div>

            {{-- Managing Office --}}
            <div>
                <label class="block text-xs font-medium text-slate-700 mb-1.5">Managing Office</label>
                <input type="text" placeholder="e.g. MDRRMO, MSWD, DepEd Esperanza"
                    class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
            </div>

            {{-- Safety Assessment --}}
            <div>
                <label class="block text-xs font-medium text-slate-700 mb-1.5">Initial Safety Assessment</label>
                <select class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                    <option>Good</option>
                    <option>Fair</option>
                    <option>Needs Inspection</option>
                </select>
            </div>
        </div>

        {{-- Footer --}}
        <div class="flex items-center justify-end gap-3 px-6 py-4 border-t border-slate-100 bg-slate-50/70 rounded-b-2xl">
            <button @click="showCreateCenter = false"
                class="text-sm text-slate-600 bg-white border border-slate-200 hover:border-slate-300 px-4 py-2 rounded-xl transition-colors">
                Cancel
            </button>
            <button @click="toast('Evacuation center EC-011 registered.', 'success'); showCreateCenter = false; $nextTick(() => window.renderIcons?.())"
                class="inline-flex items-center gap-1.5 text-sm font-medium text-white bg-brand-600 hover:bg-brand-700 px-5 py-2 rounded-xl transition-colors">
                <i data-lucide="save" class="w-4 h-4"></i> Register Center
            </button>
        </div>
    </div>
</div>

</div>{{-- end local x-data --}}
