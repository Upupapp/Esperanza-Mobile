{{--
    tab-resources.blade.php
    Response Resource & Deployment Management
    Included by sakuna.blade.php — NO x-data at root.
    Alpine state lives in parent: resourceSearch, resourceCategoryFilter, resourceStatusFilter,
    selectedResource, showResourceDetail, showDeployModal, deployTarget
--}}

<div x-data="{
    showAddResourceModal: false,
    deployAssignTo: 'incident',
    deployPriority: 'Normal',
    deployPersonnel: '',
    deployInstructions: '',
    deployETA: '',
    deployIncident: '',
    deployCenter: '',

    conditionClass(c) {
        if (c === 'Good') return 'text-emerald-600 font-medium';
        if (c === 'Fair') return 'text-amber-600 font-medium';
        if (c === 'Poor') return 'text-rose-600 font-medium';
        return 'text-slate-500';
    },

    categoryBadgeClass(cat) {
        const map = {
            'Response Teams': 'bg-brand-100 text-brand-700',
            'Boats': 'bg-sky-100 text-sky-700',
            'Ambulances': 'bg-rose-100 text-rose-700',
            'Rescue Trucks': 'bg-orange-100 text-orange-700',
            'Vehicles': 'bg-slate-100 text-slate-600',
            'Generators': 'bg-amber-100 text-amber-700',
            'Radios': 'bg-indigo-100 text-indigo-700',
            'Heavy Equipment': 'bg-zinc-100 text-zinc-700',
            'Medical Equipment': 'bg-pink-100 text-pink-700',
            'Rescue Equipment': 'bg-teal-100 text-teal-700',
        };
        return (map[cat] || 'bg-slate-100 text-slate-600') + ' px-2 py-0.5 rounded-full text-xs font-medium';
    },

    isDeployed(status) {
        return ['On Scene','En Route','Deployed','Dispatched','Assigned'].includes(status);
    },

    fuelBarClass(fuel) {
        if (fuel >= 70) return 'bg-emerald-500';
        if (fuel >= 40) return 'bg-amber-400';
        return 'bg-rose-500';
    },
}" class="space-y-4">

{{-- ── Header ─────────────────────────────────────────────────────────────────────────── --}}
<div class="flex flex-wrap items-center justify-between gap-3">
    <div>
        <h2 class="text-base font-semibold text-slate-800">Response Assets &amp; Resources</h2>
        <p class="text-sm text-slate-500 mt-0.5">Track, deploy, and manage all MDRRMO response assets and partner agency resources.</p>
    </div>
    <div class="flex items-center gap-2">
        <button @click="toast('Resource inventory exported.', 'success')"
            class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-2 shadow-card hover:border-slate-300 transition-colors">
            <i data-lucide="download" class="w-4 h-4 text-slate-400"></i> Export
        </button>
        <button @click="showAddResourceModal = true; $nextTick(() => window.renderIcons?.())"
            class="inline-flex items-center gap-1.5 text-sm font-medium text-white bg-brand-600 hover:bg-brand-700 rounded-xl px-3 py-2 shadow-card transition-colors">
            <i data-lucide="plus" class="w-4 h-4"></i> Add Resource
        </button>
    </div>
</div>

{{-- ── Status Summary Pills ─────────────────────────────────────────────────────────────── --}}
<div class="flex flex-wrap items-center gap-2">
    @php
        $resStatCounts = [
            'available'    => collect($resources)->whereIn('status', ['Available'])->count(),
            'active'       => collect($resources)->whereIn('status', ['Deployed','On Scene','En Route','Dispatched'])->count(),
            'standby'      => collect($resources)->whereIn('status', ['Standby','Assigned'])->count(),
            'maintenance'  => collect($resources)->whereIn('status', ['Under Maintenance'])->count(),
        ];
    @endphp
    <div class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-50 border border-emerald-200">
        <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
        <span class="text-xs font-medium text-emerald-700">Available: <strong>{{ $resStatCounts['available'] }}</strong></span>
    </div>
    <div class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-orange-50 border border-orange-200">
        <span class="w-2 h-2 rounded-full bg-orange-400"></span>
        <span class="text-xs font-medium text-orange-700">Deployed/On Scene/En Route: <strong>{{ $resStatCounts['active'] }}</strong></span>
    </div>
    <div class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-blue-50 border border-blue-200">
        <span class="w-2 h-2 rounded-full bg-blue-400"></span>
        <span class="text-xs font-medium text-blue-700">Standby/Assigned: <strong>{{ $resStatCounts['standby'] }}</strong></span>
    </div>
    <div class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-100 border border-slate-200">
        <span class="w-2 h-2 rounded-full bg-slate-400"></span>
        <span class="text-xs font-medium text-slate-600">Maintenance: <strong>{{ $resStatCounts['maintenance'] }}</strong></span>
    </div>
    <div class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-50 border border-slate-200 ml-auto">
        <span class="text-xs text-slate-500">Total Resources: <strong class="text-slate-700">{{ count($resources) }}</strong></span>
    </div>
</div>

{{-- ── Team Readiness Board ─────────────────────────────────────────────────────────────── --}}
<div class="grid grid-cols-2 md:grid-cols-4 gap-3">
    @foreach([
        ['name' => 'Rescue Team Alpha', 'personnel' => 8, 'status' => 'On Scene', 'deployment' => 'INC-2026-0084 — Masbaranon Flood', 'readiness' => 95, 'color' => 'bg-orange-100 text-orange-700', 'icon' => 'shield-alert'],
        ['name' => 'Rescue Team Bravo', 'personnel' => 6, 'status' => 'En Route', 'deployment' => 'INC-2026-0083 — Domorog Landslide', 'readiness' => 88, 'color' => 'bg-fuchsia-100 text-fuchsia-700', 'icon' => 'shield-alert'],
        ['name' => 'Medical Team RHU', 'personnel' => 4, 'status' => 'On Scene', 'deployment' => 'EC-006 — Municipal Gymnasium', 'readiness' => 100, 'color' => 'bg-rose-100 text-rose-700', 'icon' => 'stethoscope'],
        ['name' => 'MSWD Team', 'personnel' => 3, 'status' => 'On Scene', 'deployment' => 'EC-006 — Municipal Gymnasium', 'readiness' => 100, 'color' => 'bg-violet-100 text-violet-700', 'icon' => 'heart-handshake'],
    ] as $team)
    <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4">
        <div class="flex items-start gap-3">
            <div class="w-9 h-9 rounded-xl {{ $team['color'] }} flex items-center justify-center flex-shrink-0">
                <i data-lucide="{{ $team['icon'] }}" class="w-4 h-4"></i>
            </div>
            <div class="flex-1 min-w-0">
                <p class="text-sm font-semibold text-slate-800 leading-tight">{{ $team['name'] }}</p>
                <p class="text-xs text-slate-400 mt-0.5">{{ $team['personnel'] }} personnel</p>
            </div>
        </div>
        <div class="mt-3 space-y-2">
            <span class="{{ match($team['status']) {
                'On Scene' => 'bg-orange-100 text-orange-700',
                'En Route' => 'bg-fuchsia-100 text-fuchsia-700',
                'Available' => 'bg-emerald-100 text-emerald-700',
                default => 'bg-slate-100 text-slate-600',
            } }} px-2.5 py-0.5 rounded-full text-xs font-medium">{{ $team['status'] }}</span>
            <p class="text-xs text-slate-500 truncate" title="{{ $team['deployment'] }}">{{ $team['deployment'] }}</p>
            <div>
                <div class="flex items-center justify-between mb-1">
                    <span class="text-xs text-slate-400">Readiness</span>
                    <span class="text-xs font-medium {{ $team['readiness'] >= 90 ? 'text-emerald-600' : ($team['readiness'] >= 70 ? 'text-amber-600' : 'text-rose-600') }}">{{ $team['readiness'] }}%</span>
                </div>
                <div class="h-1.5 bg-slate-100 rounded-full overflow-hidden">
                    <div class="h-full rounded-full {{ $team['readiness'] >= 90 ? 'bg-emerald-500' : ($team['readiness'] >= 70 ? 'bg-amber-400' : 'bg-rose-500') }}" style="width: {{ $team['readiness'] }}%"></div>
                </div>
            </div>
        </div>
    </div>
    @endforeach
</div>

{{-- ── Filter Bar ──────────────────────────────────────────────────────────────────────── --}}
<div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4">
    <div class="flex flex-wrap gap-3 items-center">
        <div class="relative flex-1 min-w-48">
            <i data-lucide="search" class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none"></i>
            <input type="text" x-model="resourceSearch" placeholder="Search by name or ID…"
                class="w-full pl-9 pr-3 py-2 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
        </div>
        <select x-model="resourceCategoryFilter"
            class="text-sm border border-slate-200 rounded-xl px-3 py-2 bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
            <option value="">All Categories</option>
            @foreach(['Response Teams','Vehicles','Ambulances','Rescue Trucks','Boats','Motorcycles','Heavy Equipment','Radios','Generators','Medical Equipment','Rescue Equipment','PPE','Shelters & Tents'] as $cat)
            <option value="{{ $cat }}">{{ $cat }}</option>
            @endforeach
        </select>
        <select x-model="resourceStatusFilter"
            class="text-sm border border-slate-200 rounded-xl px-3 py-2 bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
            <option value="">All Statuses</option>
            @foreach(['Available','Standby','Assigned','Deployed','En Route','On Scene','Returning','Dispatched','Under Maintenance'] as $st)
            <option value="{{ $st }}">{{ $st }}</option>
            @endforeach
        </select>
        <button @click="resourceSearch = ''; resourceCategoryFilter = ''; resourceStatusFilter = ''"
            class="text-sm text-slate-500 hover:text-slate-700 px-3 py-2 rounded-xl hover:bg-slate-100 transition-colors">
            Clear filters
        </button>
    </div>
</div>

{{-- ── Resources Table ─────────────────────────────────────────────────────────────────── --}}
<div class="bg-white rounded-2xl border border-slate-100 shadow-card overflow-hidden">
    <div class="overflow-x-auto">
        <table class="w-full text-sm">
            <thead>
                <tr class="border-b border-slate-100 bg-slate-50/60">
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">ID</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Resource Name</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Category</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Office</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Status</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Condition</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Personnel</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Deployment</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Fuel</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Last Inspection</th>
                    <th class="text-right px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-50">
                @foreach($resources as $res)
                <tr
                    x-show="
                        $store.session.inScope('{{ $res['barangay'] }}') &&
                        (resourceSearch === '' || '{{ strtolower($res['id']) }}'.includes(resourceSearch.toLowerCase()) || '{{ strtolower($res['name']) }}'.includes(resourceSearch.toLowerCase())) &&
                        (resourceCategoryFilter === '' || resourceCategoryFilter === '{{ $res['category'] }}') &&
                        (resourceStatusFilter === '' || resourceStatusFilter === '{{ $res['status'] }}')
                    "
                    class="hover:bg-slate-50/60 transition-colors"
                >
                    <td class="px-4 py-3 whitespace-nowrap">
                        <span class="font-mono text-xs text-slate-500">{{ $res['id'] }}</span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap">
                        <span class="font-medium text-slate-800">{{ $res['name'] }}</span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap">
                        @php
                            $catClass = match($res['category']) {
                                'Response Teams' => 'bg-brand-100 text-brand-700',
                                'Boats' => 'bg-sky-100 text-sky-700',
                                'Ambulances' => 'bg-rose-100 text-rose-700',
                                'Rescue Trucks' => 'bg-orange-100 text-orange-700',
                                'Generators' => 'bg-amber-100 text-amber-700',
                                'Radios' => 'bg-indigo-100 text-indigo-700',
                                'Heavy Equipment' => 'bg-zinc-100 text-zinc-700',
                                'Medical Equipment' => 'bg-pink-100 text-pink-700',
                                'Rescue Equipment' => 'bg-teal-100 text-teal-700',
                                default => 'bg-slate-100 text-slate-600',
                            };
                        @endphp
                        <span class="{{ $catClass }} px-2 py-0.5 rounded-full text-xs font-medium">{{ $res['category'] }}</span>
                    </td>
                    <td class="px-4 py-3">
                        <span class="text-slate-600 max-w-[140px] block truncate" title="{{ $res['office'] }}">{{ $res['office'] }}</span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap">
                        <span class="{{ match($res['status']) {
                            'Available' => 'bg-emerald-100 text-emerald-700',
                            'On Scene' => 'bg-orange-100 text-orange-700',
                            'En Route' => 'bg-fuchsia-100 text-fuchsia-700',
                            'Deployed' => 'bg-orange-100 text-orange-700',
                            'Dispatched' => 'bg-purple-100 text-purple-700',
                            'Standby' => 'bg-blue-100 text-blue-700',
                            'Assigned' => 'bg-violet-100 text-violet-700',
                            'Returning' => 'bg-teal-100 text-teal-700',
                            'Under Maintenance' => 'bg-slate-100 text-slate-500',
                            default => 'bg-slate-100 text-slate-600',
                        } }} px-2.5 py-0.5 rounded-full text-xs font-medium">{{ $res['status'] }}</span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap">
                        <span class="{{ match($res['condition']) {
                            'Good' => 'text-emerald-600',
                            'Fair' => 'text-amber-600',
                            'Poor' => 'text-rose-600',
                            default => 'text-slate-500',
                        } }} text-sm font-medium">{{ $res['condition'] }}</span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-slate-600 text-center">
                        {{ $res['personnel'] > 0 ? $res['personnel'] : '—' }}
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap">
                        @if($res['deployment'] !== '—' && $res['deployment'] !== '')
                            <span class="font-mono text-xs text-brand-600">{{ $res['deployment'] }}</span>
                        @else
                            <span class="text-slate-400 text-xs">—</span>
                        @endif
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap">
                        @if($res['fuel'] !== null)
                        <div class="flex items-center gap-2 min-w-[70px]">
                            <div class="flex-1 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                                <div class="h-full rounded-full {{ match(true) {
                                    $res['fuel'] >= 70 => 'bg-emerald-500',
                                    $res['fuel'] >= 40 => 'bg-amber-400',
                                    default => 'bg-rose-500',
                                } }}" style="width: {{ $res['fuel'] }}%"></div>
                            </div>
                            <span class="text-xs text-slate-500">{{ $res['fuel'] }}%</span>
                        </div>
                        @else
                            <span class="text-xs text-slate-400">N/A</span>
                        @endif
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-xs text-slate-500">
                        {{ $res['last_inspection'] }}
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap">
                        <div class="flex items-center justify-end gap-1" x-data="{ open: false }" @click.outside="open = false">
                            <button
                                @click="selectedResource = {{ json_encode($res) }}; showResourceDetail = true; $nextTick(() => window.renderIcons?.())"
                                class="p-1.5 rounded-lg text-slate-500 hover:text-brand-600 hover:bg-brand-50 transition-colors" title="View Details">
                                <i data-lucide="eye" class="w-4 h-4"></i>
                            </button>
                            @if(in_array($res['status'], ['Available', 'Standby']))
                            <button
                                @click="selectedResource = {{ json_encode($res) }}; showDeployModal = true; $nextTick(() => window.renderIcons?.())"
                                class="p-1.5 rounded-lg text-slate-500 hover:text-emerald-600 hover:bg-emerald-50 transition-colors" title="Deploy">
                                <i data-lucide="send" class="w-4 h-4"></i>
                            </button>
                            @else
                            <button
                                title="Already deployed — cannot re-deploy"
                                disabled
                                class="p-1.5 rounded-lg text-slate-300 cursor-not-allowed" >
                                <i data-lucide="send" class="w-4 h-4"></i>
                            </button>
                            @endif
                            <div class="relative">
                                <button @click="open = !open; $nextTick(() => window.renderIcons?.())"
                                    class="p-1.5 rounded-lg text-slate-500 hover:text-slate-700 hover:bg-slate-100 transition-colors" title="More">
                                    <i data-lucide="ellipsis" class="w-4 h-4"></i>
                                </button>
                                <div x-show="open" x-cloak
                                    x-transition:enter="transition ease-out duration-100"
                                    x-transition:enter-start="opacity-0 scale-95"
                                    x-transition:enter-end="opacity-100 scale-100"
                                    class="absolute right-0 mt-1 w-44 bg-white rounded-xl shadow-float border border-slate-100 py-1 z-20 text-sm">
                                    @if(in_array($res['status'], ['Deployed','On Scene','En Route','Dispatched']))
                                    <button @click="toast('{{ $res['name'] }} marked as returning.', 'info'); open = false"
                                        class="w-full text-left px-4 py-2 text-slate-600 hover:bg-slate-50 flex items-center gap-2">
                                        <i data-lucide="undo-2" class="w-4 h-4 text-slate-400"></i> Return Asset
                                    </button>
                                    @endif
                                    <button @click="toast('Inspection record added.', 'success'); open = false"
                                        class="w-full text-left px-4 py-2 text-slate-600 hover:bg-slate-50 flex items-center gap-2">
                                        <i data-lucide="clipboard-check" class="w-4 h-4 text-slate-400"></i> Log Inspection
                                    </button>
                                    <button @click="toast('{{ $res['name'] }} marked for maintenance.', 'info'); open = false"
                                        class="w-full text-left px-4 py-2 text-amber-600 hover:bg-amber-50 flex items-center gap-2">
                                        <i data-lucide="wrench" class="w-4 h-4"></i> Mark Maintenance
                                    </button>
                                </div>
                            </div>
                        </div>
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    <div class="px-4 py-3 border-t border-slate-100 bg-slate-50/40 flex items-center justify-between">
        <p class="text-xs text-slate-500">Showing <strong>{{ count($resources) }}</strong> resources total</p>
        <p class="text-xs text-slate-400">Last updated: Jul 15, 2026 — 08:26 AM</p>
    </div>
</div>

{{-- ── Deploy Modal ────────────────────────────────────────────────────────────────────── --}}
<div x-show="showDeployModal" x-cloak
    x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100"
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
    @click.self="showDeployModal = false">
    <div x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 scale-95" x-transition:enter-end="opacity-100 scale-100"
        class="bg-white rounded-2xl shadow-float w-full max-w-xl">

        <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-brand-50 flex items-center justify-center">
                    <i data-lucide="send" class="w-5 h-5 text-brand-600"></i>
                </div>
                <div>
                    <h3 class="font-semibold text-slate-800">Deploy Resource</h3>
                    <p class="text-xs text-slate-400" x-text="selectedResource?.name ?? '—'"></p>
                </div>
            </div>
            <button @click="showDeployModal = false" class="p-2 rounded-xl text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors">
                <i data-lucide="x" class="w-5 h-5"></i>
            </button>
        </div>

        <div class="p-6 space-y-4">

            {{-- Status conflict warning --}}
            <template x-if="selectedResource && !['Available','Standby'].includes(selectedResource.status)">
                <div class="flex items-start gap-2 p-3 bg-amber-50 border border-amber-200 rounded-xl">
                    <i data-lucide="triangle-alert" class="w-4 h-4 text-amber-500 flex-shrink-0 mt-0.5"></i>
                    <p class="text-xs text-amber-700">
                        This resource is currently <strong x-text="selectedResource?.status"></strong>.
                        Reassigning may create a conflict. Confirm only if the existing deployment is resolved.
                    </p>
                </div>
            </template>

            {{-- Assign To Toggle --}}
            <div>
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2 block">Assign To</label>
                <div class="flex rounded-xl border border-slate-200 overflow-hidden">
                    <button @click="deployAssignTo = 'incident'"
                        :class="deployAssignTo === 'incident' ? 'bg-brand-600 text-white' : 'bg-white text-slate-600 hover:bg-slate-50'"
                        class="flex-1 py-2.5 text-sm font-medium transition-colors">
                        <i data-lucide="flame" class="w-4 h-4 inline mr-1.5"></i> Incident
                    </button>
                    <button @click="deployAssignTo = 'center'"
                        :class="deployAssignTo === 'center' ? 'bg-brand-600 text-white' : 'bg-white text-slate-600 hover:bg-slate-50'"
                        class="flex-1 py-2.5 text-sm font-medium transition-colors border-l border-slate-200">
                        <i data-lucide="house" class="w-4 h-4 inline mr-1.5"></i> Evacuation Center
                    </button>
                </div>
            </div>

            {{-- Incident selector --}}
            <div x-show="deployAssignTo === 'incident'">
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Active Incident</label>
                <select x-model="deployIncident" class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
                    <option value="">— Select incident —</option>
                    @foreach($incidents as $inc)
                        @if(!in_array($inc['status'], ['Resolved', 'Closed']))
                        <option value="{{ $inc['id'] }}">{{ $inc['id'] }} — {{ $inc['type'] }}, {{ $inc['barangay'] }} ({{ $inc['status'] }})</option>
                        @endif
                    @endforeach
                </select>
            </div>

            {{-- Center selector --}}
            <div x-show="deployAssignTo === 'center'">
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Evacuation Center</label>
                <select x-model="deployCenter" class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
                    <option value="">— Select center —</option>
                    @foreach($centers as $c)
                        @if(in_array($c['status'], ['Open', 'Near Capacity']))
                        <option value="{{ $c['id'] }}">{{ $c['id'] }} — {{ $c['name'] }}</option>
                        @endif
                    @endforeach
                </select>
            </div>

            {{-- Priority --}}
            <div>
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Priority</label>
                <div class="flex gap-2">
                    @foreach(['Normal' => 'slate', 'Urgent' => 'amber', 'Emergency' => 'rose'] as $pri => $color)
                    <button @click="deployPriority = '{{ $pri }}'"
                        :class="deployPriority === '{{ $pri }}' ? 'border-{{ $color }}-400 bg-{{ $color }}-50 text-{{ $color }}-700' : 'border-slate-200 bg-white text-slate-600 hover:border-slate-300'"
                        class="flex-1 py-2 text-sm font-medium rounded-xl border transition-colors">
                        {{ $pri }}
                    </button>
                    @endforeach
                </div>
            </div>

            {{-- Personnel --}}
            <div>
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Assigned Personnel</label>
                <input type="text" x-model="deployPersonnel" placeholder="e.g. Sgt. Dela Vega + 7 members"
                    class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
            </div>

            {{-- Instructions --}}
            <div>
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Deployment Instructions</label>
                <textarea x-model="deployInstructions" rows="2" placeholder="Special instructions, route, contact on site…"
                    class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors resize-none"></textarea>
            </div>

            {{-- ETA --}}
            <div>
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Expected Arrival Time</label>
                <input type="datetime-local"
                    class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
            </div>
        </div>

        <div class="px-6 py-4 border-t border-slate-100 bg-slate-50/60 rounded-b-2xl flex gap-3">
            <button @click="showDeployModal = false"
                class="flex-1 py-2.5 text-sm font-medium text-slate-600 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors">
                Cancel
            </button>
            <button @click="
                let target = deployAssignTo === 'incident' ? (deployIncident || 'selected incident') : (deployCenter || 'selected center');
                if (deployAssignTo === 'incident' && deployIncident) {
                    let otherDeployed = {{ collect($resources)->where('category', $res['category'])->whereIn('status', ['Deployed','On Scene','En Route','Dispatched'])->count() }};
                    /* Conflict check simplified — toast a warning if same category unit already on same incident */
                }
                toast((selectedResource?.name ?? 'Resource') + ' deployed to ' + target + '.', 'success');
                showDeployModal = false;
                $nextTick(() => window.renderIcons?.());
            "
                class="flex-1 py-2.5 text-sm font-semibold text-white bg-brand-600 hover:bg-brand-700 rounded-xl transition-colors">
                <i data-lucide="send" class="w-4 h-4 inline mr-1.5"></i> Deploy
            </button>
        </div>
    </div>
</div>

{{-- ── Resource Detail Modal ───────────────────────────────────────────────────────────── --}}
<div x-show="showResourceDetail" x-cloak
    x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100"
    class="fixed inset-0 z-50 flex items-start justify-center p-4 pt-12 bg-slate-900/50 backdrop-blur-sm overflow-y-auto"
    @click.self="showResourceDetail = false">
    <div x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 scale-95" x-transition:enter-end="opacity-100 scale-100"
        class="bg-white rounded-2xl shadow-float w-full max-w-2xl mb-8">

        <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-brand-50 flex items-center justify-center">
                    <i data-lucide="truck" class="w-5 h-5 text-brand-600"></i>
                </div>
                <div>
                    <h3 class="font-semibold text-slate-800" x-text="selectedResource?.name ?? '—'"></h3>
                    <div class="flex items-center gap-2 mt-0.5">
                        <span class="font-mono text-xs text-slate-400" x-text="selectedResource?.id ?? ''"></span>
                        <span class="text-slate-300">·</span>
                        <span class="text-xs px-2.5 py-0.5 rounded-full font-medium"
                            :class="statusBadge(selectedResource?.status)" x-text="selectedResource?.status"></span>
                    </div>
                </div>
            </div>
            <button @click="showResourceDetail = false" class="p-2 rounded-xl text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors">
                <i data-lucide="x" class="w-5 h-5"></i>
            </button>
        </div>

        <div class="p-6 space-y-5">

            {{-- Resource Details --}}
            <div>
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3 flex items-center gap-1.5">
                    <i data-lucide="info" class="w-3.5 h-3.5"></i> Resource Details
                </h4>
                <div class="grid grid-cols-2 gap-3">
                    <div class="bg-slate-50 rounded-xl p-3">
                        <p class="text-xs text-slate-400">Office / Agency</p>
                        <p class="text-sm font-medium text-slate-800 mt-0.5" x-text="selectedResource?.office ?? '—'"></p>
                    </div>
                    <div class="bg-slate-50 rounded-xl p-3">
                        <p class="text-xs text-slate-400">Station / Base</p>
                        <p class="text-sm font-medium text-slate-800 mt-0.5" x-text="selectedResource?.station ?? '—'"></p>
                    </div>
                    <div class="bg-slate-50 rounded-xl p-3">
                        <p class="text-xs text-slate-400">Category</p>
                        <p class="text-sm font-medium text-slate-800 mt-0.5" x-text="selectedResource?.category ?? '—'"></p>
                    </div>
                    <div class="bg-slate-50 rounded-xl p-3">
                        <p class="text-xs text-slate-400">Condition</p>
                        <p class="text-sm font-medium mt-0.5"
                            :class="{
                                'text-emerald-600': selectedResource?.condition === 'Good',
                                'text-amber-600': selectedResource?.condition === 'Fair',
                                'text-rose-600': selectedResource?.condition === 'Poor',
                                'text-slate-600': !['Good','Fair','Poor'].includes(selectedResource?.condition)
                            }"
                            x-text="selectedResource?.condition ?? '—'"></p>
                    </div>
                    <div class="bg-slate-50 rounded-xl p-3">
                        <p class="text-xs text-slate-400">Assigned Personnel</p>
                        <p class="text-sm font-medium text-slate-800 mt-0.5" x-text="selectedResource?.personnel ? selectedResource.personnel + ' persons' : '—'"></p>
                    </div>
                    <div class="bg-slate-50 rounded-xl p-3">
                        <p class="text-xs text-slate-400">Current Deployment</p>
                        <p class="text-sm font-medium text-brand-700 mt-0.5 font-mono" x-text="selectedResource?.deployment ?? '—'"></p>
                    </div>
                </div>
            </div>

            {{-- Fuel / Level --}}
            <template x-if="selectedResource?.fuel !== null && selectedResource?.fuel !== undefined">
                <div>
                    <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3 flex items-center gap-1.5">
                        <i data-lucide="fuel" class="w-3.5 h-3.5"></i> Fuel Level
                    </h4>
                    <div class="bg-slate-50 rounded-xl p-4">
                        <div class="flex items-center justify-between mb-2">
                            <span class="text-sm text-slate-600" x-text="selectedResource?.fuel + '%'"></span>
                            <span class="text-xs" :class="{
                                'text-emerald-600': selectedResource?.fuel >= 70,
                                'text-amber-600': selectedResource?.fuel >= 40 && selectedResource?.fuel < 70,
                                'text-rose-600': selectedResource?.fuel < 40,
                            }" x-text="selectedResource?.fuel >= 70 ? 'Sufficient' : (selectedResource?.fuel >= 40 ? 'Moderate' : 'Low — refuel needed')"></span>
                        </div>
                        <div class="h-2.5 bg-slate-200 rounded-full overflow-hidden">
                            <div class="h-full rounded-full transition-all duration-500"
                                :class="{
                                    'bg-emerald-500': selectedResource?.fuel >= 70,
                                    'bg-amber-400': selectedResource?.fuel >= 40 && selectedResource?.fuel < 70,
                                    'bg-rose-500': selectedResource?.fuel < 40,
                                }"
                                :style="'width: ' + selectedResource?.fuel + '%'"></div>
                        </div>
                    </div>
                </div>
            </template>

            {{-- Deployment History --}}
            <div>
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3 flex items-center gap-1.5">
                    <i data-lucide="clock" class="w-3.5 h-3.5"></i> Deployment History
                </h4>
                <div class="space-y-2">
                    @foreach([
                        ['date' => 'Jul 14, 2026', 'target' => 'INC-2026-0077 — Magsaysay Flood', 'duration' => '4h 22m', 'outcome' => 'Resolved'],
                        ['date' => 'May 28, 2026', 'target' => 'INC-2026-0041 — Typhoon Amang, Baras', 'duration' => '8h 10m', 'outcome' => 'Resolved'],
                        ['date' => 'Feb 10, 2026', 'target' => 'INC-2026-0012 — Flash Flood, Santiago', 'duration' => '3h 45m', 'outcome' => 'Resolved'],
                    ] as $dh)
                    <div class="flex items-center gap-3 p-3 bg-slate-50 rounded-xl">
                        <div class="w-8 h-8 rounded-lg bg-white border border-slate-200 flex items-center justify-center flex-shrink-0">
                            <i data-lucide="send" class="w-3.5 h-3.5 text-slate-400"></i>
                        </div>
                        <div class="flex-1">
                            <p class="text-xs font-medium text-slate-700">{{ $dh['target'] }}</p>
                            <p class="text-xs text-slate-400">{{ $dh['date'] }} · Duration: {{ $dh['duration'] }}</p>
                        </div>
                        <span class="text-xs bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded-full">{{ $dh['outcome'] }}</span>
                    </div>
                    @endforeach
                </div>
            </div>

            {{-- Inspection History --}}
            <div>
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3 flex items-center gap-1.5">
                    <i data-lucide="clipboard-check" class="w-3.5 h-3.5"></i> Inspection History
                </h4>
                <div class="space-y-2">
                    @foreach([
                        ['date' => 'Jul 10, 2026', 'by' => 'MDRRMO Inspector', 'result' => 'Passed', 'notes' => 'All equipment operational. Fuel refilled.'],
                        ['date' => 'Jun 5, 2026', 'by' => 'MDRRMO Inspector', 'result' => 'Passed', 'notes' => 'Minor wear noted. No action needed.'],
                    ] as $ins)
                    <div class="flex items-start gap-3 p-3 bg-slate-50 rounded-xl">
                        <div class="w-8 h-8 rounded-lg bg-white border border-slate-200 flex items-center justify-center flex-shrink-0">
                            <i data-lucide="square-check" class="w-3.5 h-3.5 text-emerald-500"></i>
                        </div>
                        <div class="flex-1">
                            <div class="flex items-center gap-2">
                                <p class="text-xs font-medium text-slate-700">{{ $ins['date'] }}</p>
                                <span class="text-xs bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded-full">{{ $ins['result'] }}</span>
                            </div>
                            <p class="text-xs text-slate-500 mt-0.5">{{ $ins['by'] }} · {{ $ins['notes'] }}</p>
                        </div>
                    </div>
                    @endforeach
                </div>
            </div>

        </div>

        {{-- Detail Modal Actions --}}
        <div class="px-6 py-4 border-t border-slate-100 bg-slate-50/60 rounded-b-2xl flex flex-wrap gap-2 items-center">
            <button @click="toast('Editing resource record.', 'info')"
                class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-2 hover:border-slate-300 transition-colors">
                <i data-lucide="pencil" class="w-4 h-4"></i> Edit
            </button>
            <button @click="toast('Inspection record added.', 'success')"
                class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-2 hover:border-slate-300 transition-colors">
                <i data-lucide="clipboard-check" class="w-4 h-4"></i> Log Inspection
            </button>
            <button @click="toast('Asset return recorded.', 'info')"
                class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-2 hover:border-slate-300 transition-colors">
                <i data-lucide="undo-2" class="w-4 h-4"></i> Return Asset
            </button>
            <button @click="toast('Resource marked for maintenance.', 'info')"
                class="inline-flex items-center gap-1.5 text-sm text-amber-700 bg-amber-50 border border-amber-200 rounded-xl px-3 py-2 hover:bg-amber-100 transition-colors">
                <i data-lucide="wrench" class="w-4 h-4"></i> Mark for Maintenance
            </button>
            <button @click="showResourceDetail = false; showDeployModal = true"
                class="inline-flex items-center gap-1.5 text-sm font-medium text-white bg-brand-600 hover:bg-brand-700 rounded-xl px-3 py-2 transition-colors ml-auto">
                <i data-lucide="send" class="w-4 h-4"></i> Deploy
            </button>
        </div>
    </div>
</div>

{{-- ── Add Resource Modal ──────────────────────────────────────────────────────────────── --}}
<div x-show="showAddResourceModal" x-cloak
    x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100"
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
    @click.self="showAddResourceModal = false">
    <div x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 scale-95" x-transition:enter-end="opacity-100 scale-100"
        class="bg-white rounded-2xl shadow-float w-full max-w-xl">

        <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <h3 class="font-semibold text-slate-800">Add Resource to Inventory</h3>
            <button @click="showAddResourceModal = false" class="p-2 rounded-xl text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors">
                <i data-lucide="x" class="w-5 h-5"></i>
            </button>
        </div>

        <div class="p-6 grid grid-cols-2 gap-4">
            <div class="col-span-2">
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Resource Name</label>
                <input type="text" placeholder="e.g. MDRRMO Rescue Boat C"
                    class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
            </div>
            <div>
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Category</label>
                <select class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
                    <option>Response Teams</option>
                    <option>Boats</option>
                    <option>Ambulances</option>
                    <option>Rescue Trucks</option>
                    <option>Vehicles</option>
                    <option>Heavy Equipment</option>
                    <option>Generators</option>
                    <option>Radios</option>
                    <option>Medical Equipment</option>
                    <option>Rescue Equipment</option>
                    <option>PPE</option>
                    <option>Shelters &amp; Tents</option>
                </select>
            </div>
            <div>
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Office / Agency</label>
                <input type="text" placeholder="e.g. MDRRMO"
                    class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
            </div>
            <div>
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Station / Base</label>
                <input type="text" placeholder="e.g. MDRRMO Bodega"
                    class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
            </div>
            <div>
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Condition</label>
                <select class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
                    <option>Good</option>
                    <option>Fair</option>
                    <option>Poor</option>
                </select>
            </div>
            <div class="col-span-2">
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Serial / Plate Number</label>
                <input type="text" placeholder="e.g. ABC-1234 or SN-00123"
                    class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
            </div>
            <div class="col-span-2">
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Remarks</label>
                <textarea rows="2" placeholder="Additional notes or special features…"
                    class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors resize-none"></textarea>
            </div>
        </div>

        <div class="px-6 py-4 border-t border-slate-100 bg-slate-50/60 rounded-b-2xl flex gap-3">
            <button @click="showAddResourceModal = false"
                class="flex-1 py-2.5 text-sm font-medium text-slate-600 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors">
                Cancel
            </button>
            <button @click="toast('Resource added to inventory.', 'success'); showAddResourceModal = false"
                class="flex-1 py-2.5 text-sm font-semibold text-white bg-brand-600 hover:bg-brand-700 rounded-xl transition-colors">
                Add Resource
            </button>
        </div>
    </div>
</div>

</div>{{-- end x-data wrapper --}}
