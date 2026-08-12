{{--
    tab-incidents.blade.php
    Incident Management Workspace — SAKUNA Disaster Management Module
    Included by sakuna.blade.php — NO x-data at root.
    Parent Alpine state: incidentSearch, incidentTypeFilter, incidentSeverityFilter,
    incidentStatusFilter, selectedIncident, showIncidentDetail, showCreateIncident, showDispatch
    Helpers: statusBadge(st), severityBadge(sev), toast(msg, variant)
--}}

<div x-data="{
    incidentBarangayFilter: '',

    incidentTypeIcon(type) {
        const map = {
            'Flood': 'waves',
            'Landslide': 'triangle-alert',
            'Fire': 'flame',
            'Earthquake': 'activity',
            'Vehicular Accident': 'car-crash',
            'Medical Emergency': 'heart-pulse',
            'Missing Person': 'search',
            'Stranded Resident': 'anchor',
            'Fallen Tree': 'tree-pine',
            'Downed Power Line': 'zap',
            'Road Obstruction': 'cone',
            'Damaged Bridge': 'construction',
            'Rescue Request': 'life-buoy',
            'Drowning or Water Rescue': 'anchor',
            'Agricultural Damage': 'wheat',
            'Structural Damage': 'building-2',
            'Water Interruption': 'droplets',
            'Power Interruption': 'zap-off',
            'Public Health Emergency': 'shield-alert',
            'Other': 'alert-circle',
        };
        return map[type] || 'alert-circle';
    },

    rowVisible(incSearch, incType, incSev, incStat, incBrgy, rowId, rowType, rowBrgy, rowSev, rowStat) {
        const q = incSearch.toLowerCase();
        const matchSearch = !q || rowId.toLowerCase().includes(q) || rowType.toLowerCase().includes(q) || rowBrgy.toLowerCase().includes(q);
        const matchType   = !incType || rowType === incType;
        const matchSev    = !incSev  || rowSev  === incSev;
        const matchStat   = !incStat || rowStat === incStat;
        const matchBrgy   = !incBrgy || rowBrgy === incBrgy;
        return matchSearch && matchType && matchSev && matchStat && matchBrgy;
    },
}" class="space-y-5">

{{-- ── Header ──────────────────────────────────────────────────────────────────────────── --}}
<div class="flex flex-wrap items-start justify-between gap-3">
    <div>
        <h2 class="text-lg font-semibold text-slate-800">Incident Management</h2>
        <p class="text-sm text-slate-500 mt-0.5">Report, track, validate, and coordinate response to all active incidents.</p>
    </div>
    <div class="flex items-center gap-2 flex-wrap">
        <button @click="toast('Incident report exported.', 'success')"
            class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-2 shadow-card hover:border-slate-300 transition-colors">
            <i data-lucide="download" class="w-4 h-4 text-slate-400"></i> Export
        </button>
        <button @click="showCreateIncident = true; $nextTick(() => window.renderIcons?.())"
            class="inline-flex items-center gap-1.5 text-sm font-medium text-white bg-brand-600 hover:bg-brand-700 rounded-xl px-3 py-2 shadow-card transition-colors">
            <i data-lucide="plus" class="w-4 h-4"></i> New Incident
        </button>
    </div>
</div>

{{-- ── Stats Summary ────────────────────────────────────────────────────────────────────── --}}
<div class="flex flex-wrap gap-2">
    <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-slate-100 text-slate-700">
        <i data-lucide="list" class="w-3.5 h-3.5"></i> Total: 13
    </span>
    <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-rose-100 text-rose-700">
        <i data-lucide="flame" class="w-3.5 h-3.5"></i> Critical: 3
    </span>
    <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-orange-100 text-orange-700">
        <i data-lucide="truck" class="w-3.5 h-3.5"></i> Dispatched / On Scene: 5
    </span>
    <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">
        <i data-lucide="circle-check" class="w-3.5 h-3.5"></i> Resolved: 3
    </span>
    <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
        <i data-lucide="clock" class="w-3.5 h-3.5"></i> Pending Validation: 2
    </span>
</div>

{{-- ── Filter Bar ───────────────────────────────────────────────────────────────────────── --}}
<div class="flex flex-wrap gap-2 items-center">
    <div class="relative">
        <i data-lucide="search" class="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"></i>
        <input type="text" x-model="incidentSearch"
            placeholder="Search by ID, type, or barangay..."
            class="pl-9 pr-3 py-2 text-sm bg-white border border-slate-200 rounded-xl shadow-card focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 w-64 transition-colors">
    </div>
    <select x-model="incidentTypeFilter"
        class="text-sm bg-white border border-slate-200 rounded-xl shadow-card px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
        <option value="">All Types</option>
        <option>Flood</option>
        <option>Landslide</option>
        <option>Fire</option>
        <option>Earthquake</option>
        <option>Vehicular Accident</option>
        <option>Medical Emergency</option>
        <option>Missing Person</option>
        <option>Stranded Resident</option>
        <option>Fallen Tree</option>
        <option>Downed Power Line</option>
        <option>Road Obstruction</option>
        <option>Damaged Bridge</option>
        <option>Rescue Request</option>
        <option>Drowning or Water Rescue</option>
        <option>Agricultural Damage</option>
        <option>Structural Damage</option>
        <option>Water Interruption</option>
        <option>Power Interruption</option>
        <option>Public Health Emergency</option>
        <option>Other</option>
    </select>
    <select x-model="incidentSeverityFilter"
        class="text-sm bg-white border border-slate-200 rounded-xl shadow-card px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
        <option value="">All Severities</option>
        <option>Critical</option>
        <option>High</option>
        <option>Medium</option>
        <option>Low</option>
    </select>
    <select x-model="incidentStatusFilter"
        class="text-sm bg-white border border-slate-200 rounded-xl shadow-card px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
        <option value="">All Statuses</option>
        <option>New</option>
        <option>For Validation</option>
        <option>Validated</option>
        <option>Assigned</option>
        <option>Dispatched</option>
        <option>En Route</option>
        <option>On Scene</option>
        <option>Contained</option>
        <option>Resolved</option>
        <option>Closed</option>
    </select>
    <select x-model="incidentBarangayFilter"
        class="text-sm bg-white border border-slate-200 rounded-xl shadow-card px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
        <option value="">All Barangays</option>
        @foreach($barangays as $brgy)
            <option>{{ $brgy }}</option>
        @endforeach
    </select>
    <button @click="incidentSearch=''; incidentTypeFilter=''; incidentSeverityFilter=''; incidentStatusFilter=''; incidentBarangayFilter='';"
        class="inline-flex items-center gap-1.5 text-sm text-slate-500 bg-white border border-slate-200 rounded-xl px-3 py-2 shadow-card hover:border-slate-300 transition-colors">
        <i data-lucide="x" class="w-3.5 h-3.5"></i> Clear
    </button>
</div>

{{-- ── Incident Table ───────────────────────────────────────────────────────────────────── --}}
<div class="bg-white rounded-2xl shadow-card border border-slate-100 overflow-hidden">
    <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-slate-100">
            <thead>
                <tr class="bg-slate-50 text-left">
                    <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">ID</th>
                    <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Type</th>
                    <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Reported</th>
                    <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Barangay / Location</th>
                    <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Severity</th>
                    <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Affected / Vulnerable</th>
                    <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Assigned Team</th>
                    <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Status</th>
                    <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Elapsed</th>
                    <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap text-right">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-50">
                @foreach($incidents as $inc)
                <tr x-show="$store.session.inScope('{{ $inc['barangay'] }}') && rowVisible(
                        incidentSearch, incidentTypeFilter, incidentSeverityFilter, incidentStatusFilter, incidentBarangayFilter,
                        '{{ $inc['id'] }}',
                        '{{ $inc['type'] }}',
                        '{{ $inc['barangay'] }}',
                        '{{ $inc['severity'] }}',
                        '{{ $inc['status'] }}'
                    )"
                    class="hover:bg-slate-50/60 transition-colors">
                    {{-- ID --}}
                    <td class="px-4 py-3 whitespace-nowrap">
                        <span class="font-mono text-xs text-slate-500">{{ $inc['id'] }}</span>
                    </td>
                    {{-- Type --}}
                    <td class="px-4 py-3 whitespace-nowrap">
                        <div class="flex items-center gap-2">
                            <span class="flex-shrink-0 w-7 h-7 rounded-lg bg-brand-50 flex items-center justify-center">
                                <i data-lucide="{{ match($inc['type']) {
                                    'Flood'                     => 'waves',
                                    'Landslide'                 => 'triangle-alert',
                                    'Fire'                      => 'flame',
                                    'Earthquake'                => 'activity',
                                    'Vehicular Accident'        => 'car',
                                    'Medical Emergency'         => 'heart-pulse',
                                    'Missing Person'            => 'search',
                                    'Stranded Resident'         => 'anchor',
                                    'Fallen Tree'               => 'tree-pine',
                                    'Downed Power Line'         => 'zap',
                                    'Road Obstruction'          => 'cone',
                                    'Damaged Bridge'            => 'construction',
                                    'Rescue Request'            => 'life-buoy',
                                    'Drowning or Water Rescue'  => 'anchor',
                                    'Agricultural Damage'       => 'wheat',
                                    'Structural Damage'         => 'building-2',
                                    'Water Interruption'        => 'droplets',
                                    'Power Interruption'        => 'zap-off',
                                    'Public Health Emergency'   => 'shield-alert',
                                    default                     => 'alert-circle',
                                } }}" class="w-3.5 h-3.5 text-brand-600"></i>
                            </span>
                            <span class="text-sm font-medium text-slate-700">{{ $inc['type'] }}</span>
                        </div>
                    </td>
                    {{-- Reported --}}
                    <td class="px-4 py-3 whitespace-nowrap">
                        <span class="text-xs text-slate-600">{{ \Carbon\Carbon::parse($inc['reported'])->format('M j, Y') }}</span><br>
                        <span class="text-xs text-slate-400">{{ \Carbon\Carbon::parse($inc['reported'])->format('g:i A') }}</span>
                    </td>
                    {{-- Barangay / Location --}}
                    <td class="px-4 py-3">
                        <span class="text-sm font-medium text-slate-700">{{ $inc['barangay'] }}</span><br>
                        <span class="text-xs text-slate-400">{{ $inc['location'] }}</span>
                    </td>
                    {{-- Severity --}}
                    <td class="px-4 py-3 whitespace-nowrap">
                        <span :class="severityBadge('{{ $inc['severity'] }}')" class="px-2.5 py-0.5 rounded-full text-xs font-medium">{{ $inc['severity'] }}</span>
                    </td>
                    {{-- Affected / Vulnerable --}}
                    <td class="px-4 py-3 whitespace-nowrap">
                        <span class="text-sm text-slate-700">{{ number_format($inc['affected']) }}</span>
                        @if($inc['vulnerable'] > 0)
                            <br><span class="text-xs text-rose-600 font-medium">{{ $inc['vulnerable'] }} vulnerable</span>
                        @endif
                    </td>
                    {{-- Assigned Team --}}
                    <td class="px-4 py-3 whitespace-nowrap">
                        @if(!empty($inc['team']))
                            <span class="text-sm text-slate-700">{{ $inc['team'] }}</span><br>
                            <span class="text-xs text-slate-400">Lead: {{ $inc['lead'] }}</span>
                        @else
                            <span class="text-xs italic text-amber-600">Unassigned</span>
                        @endif
                    </td>
                    {{-- Status --}}
                    <td class="px-4 py-3 whitespace-nowrap">
                        <span :class="statusBadge('{{ $inc['status'] }}')">{{ $inc['status'] }}</span>
                    </td>
                    {{-- Elapsed --}}
                    <td class="px-4 py-3 whitespace-nowrap">
                        <span class="text-xs text-slate-500">{{ $inc['elapsed'] }}</span>
                    </td>
                    {{-- Actions --}}
                    <td class="px-4 py-3 whitespace-nowrap text-right">
                        <div class="flex items-center justify-end gap-1.5">
                            <button
                                @click="selectedIncident = {{ json_encode($inc) }}; showIncidentDetail = true; $nextTick(() => window.renderIcons?.())"
                                class="inline-flex items-center gap-1 text-xs font-medium text-brand-600 bg-brand-50 hover:bg-brand-100 px-2.5 py-1.5 rounded-lg transition-colors">
                                <i data-lucide="eye" class="w-3.5 h-3.5"></i> View
                            </button>
                            @if($inc['status'] === 'For Validation')
                                <button @click="toast('Incident {{ $inc['id'] }} validated.', 'success')"
                                    class="inline-flex items-center gap-1 text-xs font-medium text-emerald-700 bg-emerald-50 hover:bg-emerald-100 px-2.5 py-1.5 rounded-lg transition-colors">
                                    <i data-lucide="check" class="w-3.5 h-3.5"></i> Validate
                                </button>
                            @elseif($inc['status'] === 'Validated')
                                <button @click="selectedIncident = {{ json_encode($inc) }}; showDispatch = true; $nextTick(() => window.renderIcons?.())"
                                    class="inline-flex items-center gap-1 text-xs font-medium text-blue-700 bg-blue-50 hover:bg-blue-100 px-2.5 py-1.5 rounded-lg transition-colors">
                                    <i data-lucide="users" class="w-3.5 h-3.5"></i> Assign
                                </button>
                            @elseif($inc['status'] === 'Assigned')
                                <button @click="selectedIncident = {{ json_encode($inc) }}; showDispatch = true; $nextTick(() => window.renderIcons?.())"
                                    class="inline-flex items-center gap-1 text-xs font-medium text-orange-700 bg-orange-50 hover:bg-orange-100 px-2.5 py-1.5 rounded-lg transition-colors">
                                    <i data-lucide="truck" class="w-3.5 h-3.5"></i> Dispatch
                                </button>
                            @elseif(in_array($inc['status'], ['Dispatched', 'En Route']))
                                <button @click="toast('Incident {{ $inc['id'] }} marked On Scene.', 'success')"
                                    class="inline-flex items-center gap-1 text-xs font-medium text-purple-700 bg-purple-50 hover:bg-purple-100 px-2.5 py-1.5 rounded-lg transition-colors">
                                    <i data-lucide="map-pin" class="w-3.5 h-3.5"></i> On Scene
                                </button>
                            @elseif($inc['status'] === 'On Scene')
                                <button @click="toast('Incident {{ $inc['id'] }} marked as Resolved.', 'success')"
                                    class="inline-flex items-center gap-1 text-xs font-medium text-emerald-700 bg-emerald-50 hover:bg-emerald-100 px-2.5 py-1.5 rounded-lg transition-colors">
                                    <i data-lucide="circle-check" class="w-3.5 h-3.5"></i> Resolve
                                </button>
                            @elseif($inc['status'] === 'Resolved')
                                <button @click="toast('Incident {{ $inc['id'] }} closed.', 'info')"
                                    class="inline-flex items-center gap-1 text-xs font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 px-2.5 py-1.5 rounded-lg transition-colors">
                                    <i data-lucide="archive" class="w-3.5 h-3.5"></i> Close
                                </button>
                            @endif
                        </div>
                    </td>
                </tr>
                @endforeach

                {{-- Empty state row (always rendered; visible only when no real rows match) --}}
                <tr id="incidents-empty-state">
                    <td colspan="10" class="px-4 py-12 text-center">
                        <div class="flex flex-col items-center gap-2">
                            <span class="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center mb-1">
                                <i data-lucide="search-x" class="w-5 h-5 text-slate-400"></i>
                            </span>
                            <p class="text-sm text-slate-500 font-medium">No incidents match your filters.</p>
                            <button @click="incidentSearch=''; incidentTypeFilter=''; incidentSeverityFilter=''; incidentStatusFilter=''; incidentBarangayFilter='';"
                                class="text-sm text-brand-600 hover:underline mt-1">Clear filters</button>
                        </div>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</div>

{{-- ────────────────────────────────────────────────────────────────────────────────────── --}}
{{-- INCIDENT DETAIL MODAL                                                                  --}}
{{-- ────────────────────────────────────────────────────────────────────────────────────── --}}
<div x-show="showIncidentDetail" x-cloak
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
    @click.self="showIncidentDetail = false"
    x-transition:enter="transition ease-out duration-200"
    x-transition:enter-start="opacity-0"
    x-transition:enter-end="opacity-100"
    x-transition:leave="transition ease-in duration-150"
    x-transition:leave-start="opacity-100"
    x-transition:leave-end="opacity-0">

    <div x-data="{ detailTab: 'details', newNote: '' }"
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0 scale-95"
        x-transition:enter-end="opacity-100 scale-100"
        class="bg-white rounded-2xl shadow-float w-full max-w-4xl max-h-[90vh] overflow-y-auto">

        {{-- Modal Header --}}
        <div class="flex items-start justify-between px-6 pt-6 pb-4 border-b border-slate-100 sticky top-0 bg-white rounded-t-2xl z-10">
            <div class="flex items-start gap-3">
                <div class="flex-shrink-0 w-10 h-10 rounded-xl bg-brand-50 flex items-center justify-center mt-0.5">
                    <i data-lucide="siren" class="w-5 h-5 text-brand-600"></i>
                </div>
                <div>
                    <div class="flex items-center gap-2 flex-wrap">
                        <h3 class="text-base font-semibold text-slate-800" x-text="selectedIncident?.id || '—'"></h3>
                        <span class="text-sm text-slate-500" x-text="selectedIncident?.type || ''"></span>
                        <span :class="selectedIncident ? severityBadge(selectedIncident.severity) : ''" class="px-2.5 py-0.5 rounded-full text-xs font-medium" x-text="selectedIncident?.severity || ''"></span>
                        <span :class="selectedIncident ? statusBadge(selectedIncident.status) : ''" x-text="selectedIncident?.status || ''"></span>
                    </div>
                    <p class="text-xs text-slate-400 mt-0.5" x-text="(selectedIncident?.barangay || '') + (selectedIncident?.location ? ' · ' + selectedIncident.location : '')"></p>
                </div>
            </div>
            <button @click="showIncidentDetail = false"
                class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-100 text-slate-400 transition-colors ml-3">
                <i data-lucide="x" class="w-4 h-4"></i>
            </button>
        </div>

        {{-- Mini Tab Nav --}}
        <div class="flex border-b border-slate-100 px-6">
            <button @click="detailTab = 'details'"
                :class="detailTab === 'details' ? 'border-b-2 border-brand-600 text-brand-600 font-medium' : 'text-slate-500 hover:text-slate-700'"
                class="text-sm px-4 py-3 transition-colors">Details</button>
            <button @click="detailTab = 'response'"
                :class="detailTab === 'response' ? 'border-b-2 border-brand-600 text-brand-600 font-medium' : 'text-slate-500 hover:text-slate-700'"
                class="text-sm px-4 py-3 transition-colors">Response</button>
            <button @click="detailTab = 'timeline'"
                :class="detailTab === 'timeline' ? 'border-b-2 border-brand-600 text-brand-600 font-medium' : 'text-slate-500 hover:text-slate-700'"
                class="text-sm px-4 py-3 transition-colors">Timeline</button>
            <button @click="detailTab = 'notes'"
                :class="detailTab === 'notes' ? 'border-b-2 border-brand-600 text-brand-600 font-medium' : 'text-slate-500 hover:text-slate-700'"
                class="text-sm px-4 py-3 transition-colors">Notes</button>
        </div>

        {{-- Tab: Details --}}
        <div x-show="detailTab === 'details'" class="p-6 space-y-5">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                {{-- Reporter Info --}}
                <div class="bg-slate-50 rounded-xl p-4 space-y-3">
                    <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Reporter Information</h4>
                    <div class="space-y-2">
                        <div class="flex justify-between text-sm">
                            <span class="text-slate-500">Name</span>
                            <span class="font-medium text-slate-800" x-text="selectedIncident?.reporter || '—'"></span>
                        </div>
                        <div class="flex justify-between text-sm">
                            <span class="text-slate-500">Contact</span>
                            <span class="font-medium text-slate-800" x-text="selectedIncident?.contact || '—'"></span>
                        </div>
                        <div class="flex justify-between text-sm">
                            <span class="text-slate-500">Source</span>
                            <span class="font-medium text-slate-800" x-text="selectedIncident?.source || '—'"></span>
                        </div>
                        <div class="flex justify-between text-sm">
                            <span class="text-slate-500">Reported At</span>
                            <span class="font-medium text-slate-800" x-text="selectedIncident?.reported || '—'"></span>
                        </div>
                    </div>
                </div>
                {{-- Location Info --}}
                <div class="bg-slate-50 rounded-xl p-4 space-y-3">
                    <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Location Information</h4>
                    <div class="space-y-2">
                        <div class="flex justify-between text-sm">
                            <span class="text-slate-500">Barangay</span>
                            <span class="font-medium text-slate-800" x-text="selectedIncident?.barangay || '—'"></span>
                        </div>
                        <div class="flex justify-between text-sm">
                            <span class="text-slate-500">Exact Location</span>
                            <span class="font-medium text-slate-800 text-right max-w-[60%]" x-text="selectedIncident?.location || '—'"></span>
                        </div>
                        <div class="flex justify-between text-sm">
                            <span class="text-slate-500">Elapsed</span>
                            <span class="font-medium text-slate-800" x-text="selectedIncident?.elapsed || '—'"></span>
                        </div>
                    </div>
                </div>
            </div>

            {{-- Description --}}
            <div class="bg-slate-50 rounded-xl p-4">
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Description</h4>
                <p class="text-sm text-slate-700 leading-relaxed" x-text="selectedIncident?.description || 'No description provided.'"></p>
            </div>

            {{-- Affected Population --}}
            <div class="bg-rose-50 rounded-xl p-4">
                <h4 class="text-xs font-semibold text-rose-600 uppercase tracking-wider mb-3">Affected Population</h4>
                <div class="grid grid-cols-2 gap-4">
                    <div class="text-center">
                        <p class="text-2xl font-bold text-slate-800" x-text="selectedIncident?.affected ?? '—'"></p>
                        <p class="text-xs text-slate-500 mt-0.5">Total Affected</p>
                    </div>
                    <div class="text-center">
                        <p class="text-2xl font-bold text-rose-600" x-text="selectedIncident?.vulnerable ?? '—'"></p>
                        <p class="text-xs text-slate-500 mt-0.5">Vulnerable Persons</p>
                    </div>
                </div>
            </div>

            {{-- Immediate Requirements --}}
            <div class="bg-amber-50 rounded-xl p-4">
                <h4 class="text-xs font-semibold text-amber-700 uppercase tracking-wider mb-3">Immediate Requirements</h4>
                <div class="flex flex-wrap gap-2">
                    <span class="inline-flex items-center gap-1.5 text-xs font-medium text-amber-700 bg-amber-100 px-2.5 py-1 rounded-full">
                        <i data-lucide="anchor" class="w-3 h-3"></i> Rescue Boat
                    </span>
                    <span class="inline-flex items-center gap-1.5 text-xs font-medium text-amber-700 bg-amber-100 px-2.5 py-1 rounded-full">
                        <i data-lucide="life-buoy" class="w-3 h-3"></i> Life Vests (5)
                    </span>
                    <span class="inline-flex items-center gap-1.5 text-xs font-medium text-amber-700 bg-amber-100 px-2.5 py-1 rounded-full">
                        <i data-lucide="heart-pulse" class="w-3 h-3"></i> Medical Team Standby
                    </span>
                </div>
            </div>
        </div>

        {{-- Tab: Response --}}
        <div x-show="detailTab === 'response'" class="p-6 space-y-5">
            <div class="bg-slate-50 rounded-xl p-4 space-y-3">
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Assigned Response Team</h4>
                <div class="space-y-2">
                    <div class="flex justify-between text-sm">
                        <span class="text-slate-500">Team</span>
                        <span class="font-medium text-slate-800" x-text="selectedIncident?.team || 'Unassigned'"></span>
                    </div>
                    <div class="flex justify-between text-sm">
                        <span class="text-slate-500">Lead Responder</span>
                        <span class="font-medium text-slate-800" x-text="selectedIncident?.lead || '—'"></span>
                    </div>
                    <div class="flex justify-between text-sm">
                        <span class="text-slate-500">Vehicle Deployed</span>
                        <span class="font-medium text-slate-800">MDRRMO Rescue Truck 1</span>
                    </div>
                    <div class="flex justify-between text-sm">
                        <span class="text-slate-500">Equipment</span>
                        <span class="font-medium text-slate-800">Life Vests, Ropes, First Aid Kit</span>
                    </div>
                </div>
            </div>
            <div class="bg-slate-50 rounded-xl p-4">
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Current Status</h4>
                <div class="flex items-center gap-2">
                    <span class="w-2.5 h-2.5 rounded-full bg-orange-500 animate-pulse"></span>
                    <span class="text-sm font-semibold text-slate-800" x-text="selectedIncident?.status || '—'"></span>
                </div>
            </div>
            <div class="bg-slate-50 rounded-xl p-4">
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Response Notes</h4>
                <p class="text-sm text-slate-600 leading-relaxed">Team deployed via MDRRMO Rescue Truck 1. Requesting BFP support for water rescue. Ambulance on standby at LGU compound. Area still partially flooded — approach via Sitio Lawod road.</p>
            </div>
        </div>

        {{-- Tab: Timeline --}}
        <div x-show="detailTab === 'timeline'" class="p-6">
            <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-4">Incident Timeline</h4>
            <ol class="relative border-l border-slate-200 space-y-6 ml-3">
                <li class="ml-6">
                    <span class="absolute -left-3 flex items-center justify-center w-6 h-6 bg-rose-100 rounded-full ring-4 ring-white">
                        <i data-lucide="circle-alert" class="w-3 h-3 text-rose-600"></i>
                    </span>
                    <p class="text-xs text-slate-400 mb-0.5">Jul 15, 2026 — 06:12 AM</p>
                    <p class="text-sm font-medium text-slate-800">Incident reported</p>
                    <p class="text-xs text-slate-500">Filed by <span x-text="selectedIncident?.reporter || 'Unknown'"></span> via <span x-text="selectedIncident?.source || '—'"></span></p>
                </li>
                <li class="ml-6">
                    <span class="absolute -left-3 flex items-center justify-center w-6 h-6 bg-amber-100 rounded-full ring-4 ring-white">
                        <i data-lucide="check" class="w-3 h-3 text-amber-600"></i>
                    </span>
                    <p class="text-xs text-slate-400 mb-0.5">Jul 15, 2026 — 07:30 AM</p>
                    <p class="text-sm font-medium text-slate-800">Incident validated by EOC</p>
                    <p class="text-xs text-slate-500">Validated by EOC Officer J. Sanchez — classified as High severity</p>
                </li>
                <li class="ml-6">
                    <span class="absolute -left-3 flex items-center justify-center w-6 h-6 bg-blue-100 rounded-full ring-4 ring-white">
                        <i data-lucide="users" class="w-3 h-3 text-blue-600"></i>
                    </span>
                    <p class="text-xs text-slate-400 mb-0.5">Jul 15, 2026 — 07:45 AM</p>
                    <p class="text-sm font-medium text-slate-800">Rescue Team Alpha assigned</p>
                    <p class="text-xs text-slate-500">Authorized by MDRRMO Head R. Salinas</p>
                </li>
                <li class="ml-6">
                    <span class="absolute -left-3 flex items-center justify-center w-6 h-6 bg-orange-100 rounded-full ring-4 ring-white">
                        <i data-lucide="truck" class="w-3 h-3 text-orange-600"></i>
                    </span>
                    <p class="text-xs text-slate-400 mb-0.5">Jul 15, 2026 — 07:58 AM</p>
                    <p class="text-sm font-medium text-slate-800">Team dispatched</p>
                    <p class="text-xs text-slate-500">MDRRMO Rescue Truck 1 departed LGU compound</p>
                </li>
                <li class="ml-6">
                    <span class="absolute -left-3 flex items-center justify-center w-6 h-6 bg-purple-100 rounded-full ring-4 ring-white">
                        <i data-lucide="map-pin" class="w-3 h-3 text-purple-600"></i>
                    </span>
                    <p class="text-xs text-slate-400 mb-0.5">Jul 15, 2026 — 08:26 AM</p>
                    <p class="text-sm font-medium text-slate-800">Team On Scene — rescue operations underway</p>
                    <p class="text-xs text-slate-500">Reported by Team Lead via radio</p>
                </li>
            </ol>
        </div>

        {{-- Tab: Notes --}}
        <div x-show="detailTab === 'notes'" class="p-6 space-y-4">
            <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Incident Notes</h4>
            <div class="bg-amber-50 border border-amber-100 rounded-xl p-4">
                <div class="flex items-center gap-2 mb-1">
                    <span class="text-xs font-semibold text-amber-700">EOC Officer J. Sanchez</span>
                    <span class="text-xs text-slate-400">Jul 15, 2026 — 07:35 AM</span>
                </div>
                <p class="text-sm text-slate-700">Coordinate with BFP for water rescue support. Confirm ambulance standby at LGU compound. Alert RHU nurse on duty for potential trauma cases.</p>
            </div>
            <div class="border-t border-slate-100 pt-4">
                <label class="block text-xs font-medium text-slate-600 mb-1.5">Add a Note</label>
                <textarea x-model="newNote" rows="3"
                    placeholder="Enter your note or update..."
                    class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 resize-none transition-colors"></textarea>
                <button @click="if(newNote.trim()){ toast('Note added.', 'success'); newNote=''; } else { toast('Note cannot be empty.', 'error'); }"
                    class="mt-2 inline-flex items-center gap-1.5 text-sm font-medium text-white bg-brand-600 hover:bg-brand-700 px-4 py-2 rounded-xl transition-colors">
                    <i data-lucide="plus" class="w-4 h-4"></i> Add Note
                </button>
            </div>
        </div>

        {{-- Modal Footer --}}
        <div class="flex flex-wrap items-center justify-between gap-2 px-6 py-4 border-t border-slate-100 bg-slate-50/70 rounded-b-2xl sticky bottom-0">
            <div class="flex flex-wrap gap-2">
                <button @click="toast('Incident validated.', 'success')"
                    class="inline-flex items-center gap-1.5 text-xs font-medium text-emerald-700 bg-emerald-50 hover:bg-emerald-100 px-3 py-1.5 rounded-lg transition-colors">
                    <i data-lucide="check" class="w-3.5 h-3.5"></i> Validate
                </button>
                <button @click="showDispatch = true; $nextTick(() => window.renderIcons?.())"
                    class="inline-flex items-center gap-1.5 text-xs font-medium text-blue-700 bg-blue-50 hover:bg-blue-100 px-3 py-1.5 rounded-lg transition-colors">
                    <i data-lucide="users" class="w-3.5 h-3.5"></i> Assign Team
                </button>
                <button @click="showDispatch = true; $nextTick(() => window.renderIcons?.())"
                    class="inline-flex items-center gap-1.5 text-xs font-medium text-orange-700 bg-orange-50 hover:bg-orange-100 px-3 py-1.5 rounded-lg transition-colors">
                    <i data-lucide="truck" class="w-3.5 h-3.5"></i> Dispatch
                </button>
                <button @click="toast('Incident escalated to PDRRMO.', 'warning')"
                    class="inline-flex items-center gap-1.5 text-xs font-medium text-rose-700 bg-rose-50 hover:bg-rose-100 px-3 py-1.5 rounded-lg transition-colors">
                    <i data-lucide="arrow-up-right" class="w-3.5 h-3.5"></i> Escalate
                </button>
                <button @click="toast('Incident marked as Resolved.', 'success')"
                    class="inline-flex items-center gap-1.5 text-xs font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 px-3 py-1.5 rounded-lg transition-colors">
                    <i data-lucide="circle-check" class="w-3.5 h-3.5"></i> Resolve
                </button>
                <button @click="toast('Incident closed.', 'info')"
                    class="inline-flex items-center gap-1.5 text-xs font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 px-3 py-1.5 rounded-lg transition-colors">
                    <i data-lucide="archive" class="w-3.5 h-3.5"></i> Close
                </button>
            </div>
            <button @click="showIncidentDetail = false"
                class="text-sm text-slate-500 hover:text-slate-700 px-3 py-1.5 rounded-lg hover:bg-slate-100 transition-colors">
                Dismiss
            </button>
        </div>
    </div>
</div>

{{-- ────────────────────────────────────────────────────────────────────────────────────── --}}
{{-- CREATE INCIDENT MODAL                                                                  --}}
{{-- ────────────────────────────────────────────────────────────────────────────────────── --}}
<div x-show="showCreateIncident" x-cloak
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
    @click.self="showCreateIncident = false"
    x-transition:enter="transition ease-out duration-200"
    x-transition:enter-start="opacity-0"
    x-transition:enter-end="opacity-100"
    x-transition:leave="transition ease-in duration-150"
    x-transition:leave-start="opacity-100"
    x-transition:leave-end="opacity-0">

    <div x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0 scale-95"
        x-transition:enter-end="opacity-100 scale-100"
        class="bg-white rounded-2xl shadow-float w-full max-w-2xl max-h-[90vh] overflow-y-auto">

        {{-- Header --}}
        <div class="flex items-center justify-between px-6 pt-6 pb-4 border-b border-slate-100 sticky top-0 bg-white rounded-t-2xl z-10">
            <div class="flex items-center gap-3">
                <span class="w-9 h-9 rounded-xl bg-rose-50 flex items-center justify-center">
                    <i data-lucide="siren" class="w-5 h-5 text-rose-600"></i>
                </span>
                <div>
                    <h3 class="text-base font-semibold text-slate-800">Report New Incident</h3>
                    <p class="text-xs text-slate-400">Fill in all required fields to log an incident.</p>
                </div>
            </div>
            <button @click="showCreateIncident = false"
                class="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-100 text-slate-400 transition-colors">
                <i data-lucide="x" class="w-4 h-4"></i>
            </button>
        </div>

        {{-- Form Body --}}
        <div class="px-6 py-5 space-y-5">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {{-- Incident Type --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Incident Type <span class="text-rose-500">*</span></label>
                    <select class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                        <option value="">Select type...</option>
                        <option>Flood</option>
                        <option>Landslide</option>
                        <option>Fire</option>
                        <option>Earthquake</option>
                        <option>Vehicular Accident</option>
                        <option>Medical Emergency</option>
                        <option>Missing Person</option>
                        <option>Stranded Resident</option>
                        <option>Fallen Tree</option>
                        <option>Downed Power Line</option>
                        <option>Road Obstruction</option>
                        <option>Damaged Bridge</option>
                        <option>Rescue Request</option>
                        <option>Drowning or Water Rescue</option>
                        <option>Agricultural Damage</option>
                        <option>Structural Damage</option>
                        <option>Water Interruption</option>
                        <option>Power Interruption</option>
                        <option>Public Health Emergency</option>
                        <option>Other</option>
                    </select>
                </div>
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
                {{-- Sitio / Exact Location --}}
                <div class="sm:col-span-2">
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Sitio / Exact Location</label>
                    <input type="text" placeholder="e.g. Near the old bridge, Sitio Lawod"
                        class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                </div>
                {{-- Date and Time --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Date & Time of Incident <span class="text-rose-500">*</span></label>
                    <input type="datetime-local" value="{{ now()->format('Y-m-d\TH:i') }}"
                        class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                </div>
                {{-- Severity --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Severity <span class="text-rose-500">*</span></label>
                    <select class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                        <option value="">Select severity...</option>
                        <option>Critical</option>
                        <option>High</option>
                        <option>Medium</option>
                        <option>Low</option>
                    </select>
                </div>
                {{-- Description --}}
                <div class="sm:col-span-2">
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Description <span class="text-rose-500">*</span></label>
                    <textarea rows="4" placeholder="Describe the incident in detail — nature, current situation, immediate danger, etc."
                        class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 resize-none transition-colors"></textarea>
                </div>
                {{-- People Affected --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">People Affected (est.)</label>
                    <input type="number" min="0" placeholder="0"
                        class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                </div>
                {{-- Persons Needing Rescue --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Persons Needing Rescue</label>
                    <input type="number" min="0" placeholder="0"
                        class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                </div>
            </div>

            {{-- Special Needs --}}
            <div>
                <label class="block text-xs font-medium text-slate-700 mb-2">Special Needs Involved</label>
                <div class="flex flex-wrap gap-3">
                    @foreach(['Senior Citizen', 'PWD', 'Pregnant', 'Infant', 'Bedridden'] as $need)
                        <label class="flex items-center gap-2 text-sm text-slate-700 cursor-pointer">
                            <input type="checkbox" class="w-4 h-4 rounded border-slate-300 text-brand-600 focus:ring-brand-400">
                            {{ $need }}
                        </label>
                    @endforeach
                </div>
            </div>

            <div class="border-t border-slate-100 pt-5 grid grid-cols-1 sm:grid-cols-2 gap-4">
                {{-- Reporter Name --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Reporter Name <span class="text-rose-500">*</span></label>
                    <input type="text" placeholder="Full name of reporter"
                        class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                </div>
                {{-- Contact Number --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Contact Number</label>
                    <input type="tel" placeholder="09XXXXXXXXX"
                        class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                </div>
                {{-- Source --}}
                <div class="sm:col-span-2">
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Source / Channel <span class="text-rose-500">*</span></label>
                    <select class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                        <option value="">Select source...</option>
                        <option>Citizen Mobile App</option>
                        <option>Barangay</option>
                        <option>MDRRMO Hotline</option>
                        <option>Police</option>
                        <option>Fire</option>
                        <option>Health Office</option>
                        <option>Field Responder</option>
                        <option>Manual Encoding</option>
                    </select>
                </div>
            </div>

            {{-- Immediate Requirements --}}
            <div>
                <label class="block text-xs font-medium text-slate-700 mb-2">Immediate Requirements Needed</label>
                <div class="flex flex-wrap gap-3">
                    @foreach(['Food', 'Water', 'Rescue', 'Medical', 'Shelter', 'Road Clearing', 'Power Restoration'] as $req)
                        <label class="flex items-center gap-2 text-sm text-slate-700 cursor-pointer">
                            <input type="checkbox" class="w-4 h-4 rounded border-slate-300 text-brand-600 focus:ring-brand-400">
                            {{ $req }}
                        </label>
                    @endforeach
                </div>
            </div>
        </div>

        {{-- Footer --}}
        <div class="flex items-center justify-end gap-3 px-6 py-4 border-t border-slate-100 bg-slate-50/70 rounded-b-2xl">
            <button @click="showCreateIncident = false"
                class="text-sm text-slate-600 bg-white border border-slate-200 hover:border-slate-300 px-4 py-2 rounded-xl transition-colors">
                Cancel
            </button>
            <button @click="toast('Incident INC-2026-0085 created and logged.', 'success'); showCreateIncident = false; $nextTick(() => window.renderIcons?.())"
                class="inline-flex items-center gap-1.5 text-sm font-medium text-white bg-brand-600 hover:bg-brand-700 px-5 py-2 rounded-xl transition-colors">
                <i data-lucide="save" class="w-4 h-4"></i> Submit Incident
            </button>
        </div>
    </div>
</div>

{{-- ────────────────────────────────────────────────────────────────────────────────────── --}}
{{-- DISPATCH MODAL                                                                         --}}
{{-- ────────────────────────────────────────────────────────────────────────────────────── --}}
<div x-show="showDispatch" x-cloak
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
    @click.self="showDispatch = false"
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
        <div class="flex items-center justify-between px-6 pt-6 pb-4 border-b border-slate-100">
            <div class="flex items-center gap-3">
                <span class="w-9 h-9 rounded-xl bg-orange-50 flex items-center justify-center">
                    <i data-lucide="truck" class="w-5 h-5 text-orange-600"></i>
                </span>
                <div>
                    <h3 class="text-base font-semibold text-slate-800">Issue Dispatch Order</h3>
                    <p class="text-xs text-slate-400" x-text="'For incident ' + (selectedIncident?.id || '—')"></p>
                </div>
            </div>
            <button @click="showDispatch = false"
                class="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-100 text-slate-400 transition-colors">
                <i data-lucide="x" class="w-4 h-4"></i>
            </button>
        </div>

        {{-- Form --}}
        <div class="px-6 py-5 space-y-4">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {{-- Team --}}
                <div class="sm:col-span-2">
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Assign Team <span class="text-rose-500">*</span></label>
                    <select class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                        <option value="">Select team...</option>
                        <option>Rescue Team Alpha</option>
                        <option>Rescue Team Bravo</option>
                        <option>PNP Esperanza</option>
                        <option>BFP Esperanza</option>
                        <option>Municipal Health Team</option>
                        <option>DA Extension Team</option>
                        <option>MSWD Team</option>
                    </select>
                </div>
                {{-- Lead Responder --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Lead Responder</label>
                    <input type="text" placeholder="Full name"
                        class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                </div>
                {{-- Vehicle --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Vehicle <span class="text-rose-500">*</span></label>
                    <select class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                        <option value="">Select vehicle...</option>
                        <option>MDRRMO Rescue Truck 1</option>
                        <option>MDRRMO Rescue Boat A</option>
                        <option>Municipal Ambulance 1</option>
                        <option>MPDO Dump Truck</option>
                        <option>Motorcycle Unit</option>
                        <option>Other</option>
                    </select>
                </div>
                {{-- Destination --}}
                <div class="sm:col-span-2">
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Destination / Drop-off Point</label>
                    <input type="text" placeholder="Enter destination or address"
                        class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                </div>
                {{-- Dispatch Priority --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Dispatch Priority <span class="text-rose-500">*</span></label>
                    <select class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                        <option>Normal</option>
                        <option>Urgent</option>
                        <option>Emergency</option>
                    </select>
                </div>
                {{-- Expected Arrival --}}
                <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Expected Arrival (time)</label>
                    <input type="time" class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
                </div>
            </div>

            {{-- Equipment --}}
            <div>
                <label class="block text-xs font-medium text-slate-700 mb-2">Equipment to Deploy</label>
                <div class="flex flex-wrap gap-3">
                    @foreach(['Life Vests', 'Ropes', 'First Aid Kit', 'Chainsaw', 'Stretcher', 'Radio', 'Flashlights'] as $equip)
                        <label class="flex items-center gap-2 text-sm text-slate-700 cursor-pointer">
                            <input type="checkbox" class="w-4 h-4 rounded border-slate-300 text-brand-600 focus:ring-brand-400">
                            {{ $equip }}
                        </label>
                    @endforeach
                </div>
            </div>

            {{-- Special Instructions --}}
            <div>
                <label class="block text-xs font-medium text-slate-700 mb-1.5">Special Instructions</label>
                <textarea rows="3" placeholder="Enter any special instructions for the team..."
                    class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 resize-none transition-colors"></textarea>
            </div>

            {{-- Supporting Agency --}}
            <div>
                <label class="block text-xs font-medium text-slate-700 mb-1.5">Supporting Agency <span class="text-slate-400 font-normal">(optional)</span></label>
                <input type="text" placeholder="e.g. BFP, PNP, RHU"
                    class="w-full text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition-colors">
            </div>
        </div>

        {{-- Footer --}}
        <div class="flex items-center justify-end gap-3 px-6 py-4 border-t border-slate-100 bg-slate-50/70 rounded-b-2xl">
            <button @click="showDispatch = false"
                class="text-sm text-slate-600 bg-white border border-slate-200 hover:border-slate-300 px-4 py-2 rounded-xl transition-colors">
                Cancel
            </button>
            <button @click="toast('Dispatch order issued. Team en route.', 'success'); showDispatch = false; showIncidentDetail = false; $nextTick(() => window.renderIcons?.())"
                class="inline-flex items-center gap-1.5 text-sm font-medium text-white bg-orange-600 hover:bg-orange-700 px-5 py-2 rounded-xl transition-colors">
                <i data-lucide="send" class="w-4 h-4"></i> Issue Dispatch Order
            </button>
        </div>
    </div>
</div>

</div>{{-- end local x-data --}}
