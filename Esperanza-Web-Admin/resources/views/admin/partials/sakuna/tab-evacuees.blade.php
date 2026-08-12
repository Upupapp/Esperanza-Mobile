{{--
    tab-evacuees.blade.php
    Evacuee Registration & Occupancy Management
    Included by sakuna.blade.php — NO x-data at root.
    Alpine state lives in parent: evacueeSearch, evCenterFilter, evStatusFilter, evHealthFilter,
    selectedEvacuee, showEvacueeDetail, showEvacueeReg, evacueeRegStep
--}}

{{-- ── Check-out confirmation sub-state (scoped here to avoid polluting parent) ──────── --}}
<div x-data="{
    showCheckoutConfirm: false,
    checkoutEvacuee: null,
    showAddResourceModal: false,
    selectedResidentSearch: '',
    selectedResident: null,
    regStep1Search: '',

    openCheckout(ev) {
        this.checkoutEvacuee = ev;
        this.showCheckoutConfirm = true;
        this.$nextTick(() => window.renderIcons?.());
    },

    healthFlagClass(flag) {
        const medical = ['Chronic Medication','Bedridden Resident','Medical Equipment'];
        if (medical.includes(flag)) return 'bg-rose-100 text-rose-700';
        if (flag === 'PWD') return 'bg-purple-100 text-purple-700';
        if (flag === 'Pregnant') return 'bg-pink-100 text-pink-700';
        if (flag === 'Senior Citizen') return 'bg-amber-100 text-amber-700';
        if (flag.startsWith('Infant') || flag.startsWith('Children')) return 'bg-sky-100 text-sky-700';
        return 'bg-slate-100 text-slate-600';
    },

    matchesSearch(ev) {
        const q = evacueeSearch.toLowerCase();
        if (!q) return true;
        return ev.id.toLowerCase().includes(q) || ev.head.toLowerCase().includes(q);
    },
    matchesCenter(ev) {
        if (!evCenterFilter) return true;
        return ev.center === evCenterFilter;
    },
    matchesStatus(ev) {
        if (!evStatusFilter) return true;
        return ev.status === evStatusFilter;
    },
    matchesHealth(ev) {
        if (!evHealthFilter) return true;
        const flags = ev.health_flags;
        if (evHealthFilter === 'With Special Needs') return flags.length > 0;
        if (evHealthFilter === 'Senior Citizen') return flags.includes('Senior Citizen');
        if (evHealthFilter === 'PWD') return flags.includes('PWD');
        if (evHealthFilter === 'Pregnant') return flags.includes('Pregnant');
        if (evHealthFilter === 'Infants') return flags.some(f => f.startsWith('Infant'));
        return true;
    },
}" class="space-y-4">

{{-- ── Header ─────────────────────────────────────────────────────────────────────────── --}}
<div class="flex flex-wrap items-center justify-between gap-3">
    <div>
        <h2 class="text-base font-semibold text-slate-800">Evacuee Registration & Tracking</h2>
        <p class="text-sm text-slate-500 mt-0.5">Southwest Monsoon and Localized Flooding — July 2026</p>
    </div>
    <div class="flex items-center gap-2 flex-wrap">
        <button @click="toast('Evacuee list exported.', 'success')"
            class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-2 shadow-card hover:border-slate-300 transition-colors">
            <i data-lucide="download" class="w-4 h-4 text-slate-400"></i> Export
        </button>
        <button @click="toast('QR scan is available in the mobile MDRRMO app.', 'info')"
            class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-2 shadow-card hover:border-slate-300 transition-colors">
            <i data-lucide="scan-qr-code" class="w-4 h-4 text-slate-400"></i> Scan ID/QR
        </button>
        <button @click="showEvacueeReg = true; evacueeRegStep = 1; $nextTick(() => window.renderIcons?.())"
            class="inline-flex items-center gap-1.5 text-sm font-medium text-white bg-brand-600 hover:bg-brand-700 rounded-xl px-3 py-2 shadow-card transition-colors">
            <i data-lucide="user-plus" class="w-4 h-4"></i> Register Evacuee
        </button>
    </div>
</div>

{{-- ── Summary Cards ───────────────────────────────────────────────────────────────────── --}}
<div class="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-6 gap-3">
    <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4 col-span-2 md:col-span-1">
        <p class="text-xs text-slate-500 font-medium uppercase tracking-wide">Total Individuals</p>
        <p class="text-2xl font-bold text-slate-800 mt-1">89</p>
        <p class="text-xs text-slate-400 mt-0.5">14 families checked in</p>
    </div>
    <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4">
        <p class="text-xs text-slate-500 font-medium uppercase tracking-wide">Children</p>
        <p class="text-2xl font-bold text-sky-600 mt-1">24</p>
        <p class="text-xs text-slate-400 mt-0.5">0–5 + school age</p>
    </div>
    <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4">
        <p class="text-xs text-slate-500 font-medium uppercase tracking-wide">Senior Citizens</p>
        <p class="text-2xl font-bold text-amber-600 mt-1">12</p>
        <p class="text-xs text-slate-400 mt-0.5">60 years and above</p>
    </div>
    <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-xs text-slate-500 font-medium uppercase tracking-wide">PWD</p>
                <p class="text-2xl font-bold text-purple-600 mt-1">5</p>
            </div>
            <div class="text-right">
                <p class="text-xs text-slate-500 font-medium uppercase tracking-wide">Pregnant</p>
                <p class="text-2xl font-bold text-pink-600 mt-1">2</p>
            </div>
        </div>
    </div>
    <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4">
        <p class="text-xs text-slate-500 font-medium uppercase tracking-wide">Need Medication</p>
        <p class="text-2xl font-bold text-rose-600 mt-1">8</p>
        <p class="text-xs text-slate-400 mt-0.5">Chronic conditions</p>
    </div>
    <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4">
        <p class="text-xs text-slate-500 font-medium uppercase tracking-wide">Checked Out Today</p>
        <p class="text-2xl font-bold text-emerald-600 mt-1">1</p>
        <p class="text-xs text-slate-400 mt-0.5">Returned home / transferred</p>
    </div>
</div>

{{-- ── Filter Bar ──────────────────────────────────────────────────────────────────────── --}}
<div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4">
    <div class="flex flex-wrap gap-3 items-center">
        <div class="relative flex-1 min-w-48">
            <i data-lucide="search" class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none"></i>
            <input type="text" x-model="evacueeSearch" placeholder="Search by name or ID…"
                class="w-full pl-9 pr-3 py-2 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
        </div>
        <select x-model="evCenterFilter"
            class="text-sm border border-slate-200 rounded-xl px-3 py-2 bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
            <option value="">All Centers</option>
            @foreach($centers as $c)
                <option value="{{ $c['name'] }}">{{ $c['name'] }}</option>
            @endforeach
        </select>
        <select x-model="evStatusFilter"
            class="text-sm border border-slate-200 rounded-xl px-3 py-2 bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
            <option value="">All Statuses</option>
            <option value="Checked In">Checked In</option>
            <option value="Temporarily Out">Temporarily Out</option>
            <option value="Transferred">Transferred</option>
            <option value="Returned Home">Returned Home</option>
            <option value="Referred to Hospital">Referred to Hospital</option>
        </select>
        <select x-model="evHealthFilter"
            class="text-sm border border-slate-200 rounded-xl px-3 py-2 bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
            <option value="">All Health Flags</option>
            <option value="With Special Needs">With Special Needs</option>
            <option value="Senior Citizen">Senior Citizen</option>
            <option value="PWD">PWD</option>
            <option value="Pregnant">Pregnant</option>
            <option value="Infants">Infants</option>
        </select>
        <button @click="evacueeSearch = ''; evCenterFilter = ''; evStatusFilter = ''; evHealthFilter = ''"
            class="text-sm text-slate-500 hover:text-slate-700 px-3 py-2 rounded-xl hover:bg-slate-100 transition-colors">
            Clear filters
        </button>
    </div>
</div>

{{-- ── Evacuee Table ───────────────────────────────────────────────────────────────────── --}}
<div class="bg-white rounded-2xl border border-slate-100 shadow-card overflow-hidden">
    <div class="overflow-x-auto">
        <table class="w-full text-sm">
            <thead>
                <tr class="border-b border-slate-100 bg-slate-50/60">
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">ID</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Household Head</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Home Barangay</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Evacuation Center</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Check-in Time</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Health Flags</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Status</th>
                    <th class="text-right px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-50">
                @foreach($evacuees as $ev)
                <tr
                    x-show="
                        $store.session.inScope('{{ $ev['home_brgy'] }}') &&
                        (evacueeSearch === '' || '{{ strtolower($ev['id']) }}'.includes(evacueeSearch.toLowerCase()) || '{{ strtolower($ev['head']) }}'.includes(evacueeSearch.toLowerCase())) &&
                        (evCenterFilter === '' || evCenterFilter === '{{ $ev['center'] }}') &&
                        (evStatusFilter === '' || evStatusFilter === '{{ $ev['status'] }}') &&
                        (evHealthFilter === '' ||
                            (evHealthFilter === 'With Special Needs' && {{ count($ev['health_flags']) }} > 0) ||
                            (evHealthFilter === 'Senior Citizen' && {{ in_array('Senior Citizen', $ev['health_flags']) ? 'true' : 'false' }}) ||
                            (evHealthFilter === 'PWD' && {{ in_array('PWD', $ev['health_flags']) ? 'true' : 'false' }}) ||
                            (evHealthFilter === 'Pregnant' && {{ in_array('Pregnant', $ev['health_flags']) ? 'true' : 'false' }}) ||
                            (evHealthFilter === 'Infants' && {{ (collect($ev['health_flags'])->filter(fn($f) => str_starts_with($f, 'Infant'))->count() > 0) ? 'true' : 'false' }})
                        )
                    "
                    class="hover:bg-slate-50/60 transition-colors"
                >
                    <td class="px-4 py-3 whitespace-nowrap">
                        <span class="font-mono text-xs text-slate-500">{{ $ev['id'] }}</span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap">
                        <div class="font-medium text-slate-800">{{ $ev['head'] }}</div>
                        <div class="text-xs text-slate-400">{{ $ev['members'] }} {{ $ev['members'] === 1 ? 'member' : 'members' }}</div>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap">
                        <div class="text-slate-700">{{ $ev['home_brgy'] }}</div>
                        <div class="text-xs text-slate-400">{{ $ev['home_sitio'] }}</div>
                    </td>
                    <td class="px-4 py-3">
                        <div class="text-slate-700 max-w-[180px] truncate">{{ $ev['center'] }}</div>
                        <div class="text-xs text-slate-400">{{ $ev['zone'] }}</div>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-slate-600 text-xs">
                        {{ \Carbon\Carbon::parse($ev['checkin'])->format('M d, Y') }}<br>
                        <span class="text-slate-400">{{ \Carbon\Carbon::parse($ev['checkin'])->format('h:i A') }}</span>
                    </td>
                    <td class="px-4 py-3">
                        <div class="flex flex-wrap gap-1">
                            @forelse($ev['health_flags'] as $flag)
                                @php
                                    $fc = match(true) {
                                        in_array($flag, ['Chronic Medication','Bedridden Resident','Medical Equipment']) => 'bg-rose-100 text-rose-700',
                                        $flag === 'PWD' => 'bg-purple-100 text-purple-700',
                                        $flag === 'Pregnant' => 'bg-pink-100 text-pink-700',
                                        $flag === 'Senior Citizen' => 'bg-amber-100 text-amber-700',
                                        str_starts_with($flag, 'Infant') || str_starts_with($flag, 'Children') => 'bg-sky-100 text-sky-700',
                                        default => 'bg-slate-100 text-slate-600',
                                    };
                                @endphp
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium {{ $fc }}">{{ $flag }}</span>
                            @empty
                                <span class="text-xs text-slate-400">—</span>
                            @endforelse
                        </div>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap">
                        <span class="{{ match($ev['status']) {
                            'Checked In' => 'bg-emerald-100 text-emerald-700',
                            'Temporarily Out' => 'bg-amber-100 text-amber-700',
                            'Transferred' => 'bg-blue-100 text-blue-700',
                            'Returned Home' => 'bg-slate-100 text-slate-500',
                            'Referred to Hospital' => 'bg-pink-100 text-pink-700',
                            default => 'bg-slate-100 text-slate-600',
                        } }} px-2.5 py-0.5 rounded-full text-xs font-medium">{{ $ev['status'] }}</span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap">
                        <div class="flex items-center justify-end gap-1" x-data="{ open: false }" @click.outside="open = false">
                            <button
                                @click="selectedEvacuee = {{ json_encode($ev) }}; showEvacueeDetail = true; $nextTick(() => window.renderIcons?.())"
                                class="p-1.5 rounded-lg text-slate-500 hover:text-brand-600 hover:bg-brand-50 transition-colors" title="View Details">
                                <i data-lucide="eye" class="w-4 h-4"></i>
                            </button>
                            <button
                                @click="toast('Editing evacuee record.', 'info')"
                                class="p-1.5 rounded-lg text-slate-500 hover:text-slate-700 hover:bg-slate-100 transition-colors" title="Edit">
                                <i data-lucide="pencil" class="w-4 h-4"></i>
                            </button>
                            <div class="relative">
                                <button @click="open = !open; $nextTick(() => window.renderIcons?.())"
                                    class="p-1.5 rounded-lg text-slate-500 hover:text-slate-700 hover:bg-slate-100 transition-colors" title="More actions">
                                    <i data-lucide="ellipsis" class="w-4 h-4"></i>
                                </button>
                                <div x-show="open" x-cloak
                                    x-transition:enter="transition ease-out duration-100"
                                    x-transition:enter-start="opacity-0 scale-95"
                                    x-transition:enter-end="opacity-100 scale-100"
                                    class="absolute right-0 mt-1 w-48 bg-white rounded-xl shadow-float border border-slate-100 py-1 z-20 text-sm">
                                    <button @click="toast('Item issued and logged.', 'success'); open = false"
                                        class="w-full text-left px-4 py-2 text-slate-600 hover:bg-slate-50 flex items-center gap-2">
                                        <i data-lucide="package-check" class="w-4 h-4 text-slate-400"></i> Issue Item
                                    </button>
                                    <button @click="toast('Transfer request created.', 'info'); open = false"
                                        class="w-full text-left px-4 py-2 text-slate-600 hover:bg-slate-50 flex items-center gap-2">
                                        <i data-lucide="arrow-right-left" class="w-4 h-4 text-slate-400"></i> Transfer Center
                                    </button>
                                    <div class="border-t border-slate-100 my-1"></div>
                                    <button @click="openCheckout({{ json_encode(['id' => $ev['id'], 'head' => $ev['head'], 'members' => $ev['members']]) }}); open = false"
                                        class="w-full text-left px-4 py-2 text-rose-600 hover:bg-rose-50 flex items-center gap-2">
                                        <i data-lucide="log-out" class="w-4 h-4"></i> Check Out
                                    </button>
                                </div>
                            </div>
                        </div>
                    </td>
                </tr>
                @endforeach

                {{-- Empty state --}}
                <tr>
                    <td colspan="8"
                        x-show="
                            {{ collect($evacuees)->filter(fn($ev) => true)->count() }} === 0 ||
                            !Array.from(document.querySelectorAll('tbody tr:not([x-show])')).some(r => r.style.display !== 'none')
                        "
                        class="px-4 py-12 text-center">
                        <div class="flex flex-col items-center gap-3 text-slate-400">
                            <i data-lucide="users" class="w-10 h-10 opacity-30"></i>
                            <p class="text-sm font-medium text-slate-500">No evacuees match your filters.</p>
                            <button @click="evacueeSearch = ''; evCenterFilter = ''; evStatusFilter = ''; evHealthFilter = ''"
                                class="text-sm text-brand-600 hover:underline">Clear Filters</button>
                        </div>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    {{-- Table footer --}}
    <div class="px-4 py-3 border-t border-slate-100 bg-slate-50/40 flex items-center justify-between">
        <p class="text-xs text-slate-500">Showing <strong>{{ count($evacuees) }}</strong> households &bull; <strong>89</strong> individuals</p>
        <p class="text-xs text-slate-400">Last updated: Jul 15, 2026 — 08:26 AM</p>
    </div>
</div>

{{-- ── Check-out Confirmation Modal ───────────────────────────────────────────────────── --}}
<div x-show="showCheckoutConfirm" x-cloak
    x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100"
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
    @click.self="showCheckoutConfirm = false">
    <div x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 scale-95" x-transition:enter-end="opacity-100 scale-100"
        class="bg-white rounded-2xl shadow-float w-full max-w-md p-6">
        <div class="flex items-center gap-3 mb-4">
            <div class="w-11 h-11 rounded-2xl bg-amber-100 flex items-center justify-center flex-shrink-0">
                <i data-lucide="log-out" class="w-5 h-5 text-amber-600"></i>
            </div>
            <div>
                <h3 class="text-base font-semibold text-slate-800">Confirm Check-Out</h3>
                <p class="text-xs text-slate-500" x-text="checkoutEvacuee ? checkoutEvacuee.id : ''"></p>
            </div>
        </div>
        <p class="text-sm text-slate-600 mb-5">
            Confirm that <strong x-text="checkoutEvacuee ? checkoutEvacuee.head + '\'s' : ''"></strong> household has safely returned home or been transferred to another facility. This action will mark <strong x-text="checkoutEvacuee ? checkoutEvacuee.members + ' members' : ''"></strong> as checked out.
        </p>
        <div class="flex gap-3">
            <button @click="showCheckoutConfirm = false; checkoutEvacuee = null"
                class="flex-1 px-4 py-2.5 text-sm font-medium text-slate-600 bg-slate-100 rounded-xl hover:bg-slate-200 transition-colors">
                Cancel
            </button>
            <button @click="toast('Household ' + (checkoutEvacuee?.id ?? '') + ' successfully checked out.', 'success'); showCheckoutConfirm = false; checkoutEvacuee = null"
                class="flex-1 px-4 py-2.5 text-sm font-semibold text-white bg-amber-600 rounded-xl hover:bg-amber-700 transition-colors">
                Confirm Check-Out
            </button>
        </div>
    </div>
</div>

{{-- ── Evacuee Detail Modal ─────────────────────────────────────────────────────────────── --}}
<div x-show="showEvacueeDetail" x-cloak
    x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100"
    class="fixed inset-0 z-50 flex items-start justify-center p-4 pt-12 bg-slate-900/50 backdrop-blur-sm overflow-y-auto"
    @click.self="showEvacueeDetail = false">
    <div x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 scale-95" x-transition:enter-end="opacity-100 scale-100"
        class="bg-white rounded-2xl shadow-float w-full max-w-2xl mb-8">

        {{-- Modal Header --}}
        <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-brand-50 flex items-center justify-center">
                    <i data-lucide="user" class="w-5 h-5 text-brand-600"></i>
                </div>
                <div>
                    <h3 class="font-semibold text-slate-800" x-text="selectedEvacuee?.head ?? '—'"></h3>
                    <div class="flex items-center gap-2 mt-0.5">
                        <span class="font-mono text-xs text-slate-400" x-text="selectedEvacuee?.id ?? ''"></span>
                        <span class="text-slate-300">·</span>
                        <span class="text-xs" :class="statusBadge(selectedEvacuee?.status)" x-text="selectedEvacuee?.status"></span>
                    </div>
                </div>
            </div>
            <button @click="showEvacueeDetail = false" class="p-2 rounded-xl text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors">
                <i data-lucide="x" class="w-5 h-5"></i>
            </button>
        </div>

        <div class="p-6 space-y-5">

            {{-- Section 1: Household Information --}}
            <div>
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3 flex items-center gap-1.5">
                    <i data-lucide="house" class="w-3.5 h-3.5"></i> Household Information
                </h4>
                <div class="grid grid-cols-2 gap-3">
                    <div class="bg-slate-50 rounded-xl p-3">
                        <p class="text-xs text-slate-400">Household Head</p>
                        <p class="text-sm font-medium text-slate-800 mt-0.5" x-text="selectedEvacuee?.head ?? '—'"></p>
                    </div>
                    <div class="bg-slate-50 rounded-xl p-3">
                        <p class="text-xs text-slate-400">Total Members</p>
                        <p class="text-sm font-medium text-slate-800 mt-0.5" x-text="(selectedEvacuee?.members ?? 0) + ' persons'"></p>
                    </div>
                    <div class="bg-slate-50 rounded-xl p-3">
                        <p class="text-xs text-slate-400">Home Barangay</p>
                        <p class="text-sm font-medium text-slate-800 mt-0.5" x-text="selectedEvacuee?.home_brgy ?? '—'"></p>
                    </div>
                    <div class="bg-slate-50 rounded-xl p-3">
                        <p class="text-xs text-slate-400">Home Sitio/Purok</p>
                        <p class="text-sm font-medium text-slate-800 mt-0.5" x-text="selectedEvacuee?.home_sitio ?? '—'"></p>
                    </div>
                </div>
            </div>

            {{-- Section 2: Current Location --}}
            <div>
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3 flex items-center gap-1.5">
                    <i data-lucide="map-pin" class="w-3.5 h-3.5"></i> Current Location
                </h4>
                <div class="grid grid-cols-3 gap-3">
                    <div class="bg-slate-50 rounded-xl p-3 col-span-2">
                        <p class="text-xs text-slate-400">Evacuation Center</p>
                        <p class="text-sm font-medium text-slate-800 mt-0.5" x-text="selectedEvacuee?.center ?? '—'"></p>
                    </div>
                    <div class="bg-slate-50 rounded-xl p-3">
                        <p class="text-xs text-slate-400">Zone / Room</p>
                        <p class="text-sm font-medium text-slate-800 mt-0.5" x-text="selectedEvacuee?.zone ?? '—'"></p>
                    </div>
                    <div class="bg-slate-50 rounded-xl p-3 col-span-3">
                        <p class="text-xs text-slate-400">Check-in Time</p>
                        <p class="text-sm font-medium text-slate-800 mt-0.5" x-text="selectedEvacuee?.checkin ?? '—'"></p>
                    </div>
                </div>
            </div>

            {{-- Section 3: Health & Special Needs --}}
            <div>
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3 flex items-center gap-1.5">
                    <i data-lucide="heart-pulse" class="w-3.5 h-3.5"></i> Health & Special Needs
                </h4>
                <div class="bg-slate-50 rounded-xl p-3">
                    <template x-if="selectedEvacuee?.health_flags?.length > 0">
                        <div class="flex flex-wrap gap-2">
                            <template x-for="flag in (selectedEvacuee?.health_flags ?? [])">
                                <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-medium bg-white border border-slate-200 text-slate-700">
                                    <i data-lucide="circle-alert" class="w-3 h-3 text-rose-400"></i>
                                    <span x-text="flag"></span>
                                </span>
                            </template>
                        </div>
                    </template>
                    <template x-if="!selectedEvacuee?.health_flags?.length">
                        <p class="text-sm text-slate-400 italic">No special health flags recorded.</p>
                    </template>
                </div>
            </div>

            {{-- Section 4: Needs & Assistance Received --}}
            <div>
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3 flex items-center gap-1.5">
                    <i data-lucide="package" class="w-3.5 h-3.5"></i> Needs & Assistance Received
                </h4>
                <div class="space-y-1.5">
                    <div class="flex items-center justify-between bg-slate-50 rounded-xl px-3 py-2">
                        <div class="flex items-center gap-2">
                            <i data-lucide="circle-check" class="w-4 h-4 text-emerald-500"></i>
                            <span class="text-sm text-slate-700">1x Hygiene Kit</span>
                        </div>
                        <span class="text-xs text-slate-400">Jul 15 — 08:00</span>
                    </div>
                    <div class="flex items-center justify-between bg-slate-50 rounded-xl px-3 py-2">
                        <div class="flex items-center gap-2">
                            <i data-lucide="circle-check" class="w-4 h-4 text-emerald-500"></i>
                            <span class="text-sm text-slate-700">1x Blanket</span>
                        </div>
                        <span class="text-xs text-slate-400">Jul 15 — 08:00</span>
                    </div>
                    <template x-for="need in (selectedEvacuee?.needs ?? [])" :key="need">
                        <div class="flex items-center gap-2 bg-amber-50 rounded-xl px-3 py-2">
                            <i data-lucide="clock" class="w-4 h-4 text-amber-400"></i>
                            <span class="text-sm text-slate-700" x-text="need + ' — pending'"></span>
                        </div>
                    </template>
                </div>
            </div>

            {{-- Section 5: Activity Log --}}
            <div>
                <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3 flex items-center gap-1.5">
                    <i data-lucide="activity" class="w-3.5 h-3.5"></i> Activity Log
                </h4>
                <div class="space-y-3 relative">
                    <div class="absolute left-[18px] top-2 bottom-2 w-px bg-slate-200"></div>
                    @foreach([
                        ['icon' => 'log-in', 'color' => 'text-brand-600 bg-brand-50', 'label' => 'Checked in at evacuation center', 'time' => '08:00'],
                        ['icon' => 'package-check', 'color' => 'text-emerald-600 bg-emerald-50', 'label' => 'Hygiene Kit issued by MSWD Officer', 'time' => '08:10'],
                        ['icon' => 'stethoscope', 'color' => 'text-rose-600 bg-rose-50', 'label' => 'Medical check conducted by RHU Nurse', 'time' => '09:30'],
                    ] as $log)
                    <div class="flex items-start gap-3 relative">
                        <div class="w-9 h-9 rounded-xl {{ $log['color'] }} flex items-center justify-center flex-shrink-0 z-10">
                            <i data-lucide="{{ $log['icon'] }}" class="w-4 h-4"></i>
                        </div>
                        <div class="flex-1 pt-1.5">
                            <p class="text-sm text-slate-700">{{ $log['label'] }}</p>
                            <p class="text-xs text-slate-400 mt-0.5">Jul 15, 2026 — {{ $log['time'] }} AM</p>
                        </div>
                    </div>
                    @endforeach
                </div>
            </div>
        </div>

        {{-- Modal Actions --}}
        <div class="px-6 py-4 border-t border-slate-100 bg-slate-50/60 rounded-b-2xl flex flex-wrap items-center gap-2">
            <button @click="toast('Editing evacuee record.', 'info')"
                class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-2 hover:border-slate-300 transition-colors">
                <i data-lucide="pencil" class="w-4 h-4"></i> Edit
            </button>
            <button @click="toast('Item issued and logged.', 'success')"
                class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-2 hover:border-slate-300 transition-colors">
                <i data-lucide="package-check" class="w-4 h-4"></i> Issue Item
            </button>
            <button @click="toast('Transfer request created.', 'info')"
                class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-2 hover:border-slate-300 transition-colors">
                <i data-lucide="arrow-right-left" class="w-4 h-4"></i> Transfer Center
            </button>
            <button @click="toast('Temporary leave recorded.', 'info')"
                class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-2 hover:border-slate-300 transition-colors">
                <i data-lucide="door-open" class="w-4 h-4"></i> Temp. Leave
            </button>
            <button @click="toast('Return to center recorded.', 'success')"
                class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-2 hover:border-slate-300 transition-colors">
                <i data-lucide="undo-2" class="w-4 h-4"></i> Return to Center
            </button>
            <button @click="toast('Referred to hospital. Record updated.', 'info')"
                class="inline-flex items-center gap-1.5 text-sm text-rose-600 bg-rose-50 border border-rose-200 rounded-xl px-3 py-2 hover:bg-rose-100 transition-colors">
                <i data-lucide="ambulance" class="w-4 h-4"></i> Refer to Hospital
            </button>
            <button @click="toast('Family card sent to printer.', 'success')"
                class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-2 hover:border-slate-300 transition-colors ml-auto">
                <i data-lucide="printer" class="w-4 h-4"></i> Print Family Card
            </button>
            <button @click="openCheckout({id: selectedEvacuee?.id, head: selectedEvacuee?.head, members: selectedEvacuee?.members}); showEvacueeDetail = false"
                class="inline-flex items-center gap-1.5 text-sm font-medium text-amber-700 bg-amber-100 border border-amber-200 rounded-xl px-3 py-2 hover:bg-amber-200 transition-colors">
                <i data-lucide="log-out" class="w-4 h-4"></i> Check Out
            </button>
        </div>
    </div>
</div>

{{-- ── Evacuee Registration Modal (Multi-step) ─────────────────────────────────────────── --}}
<div x-show="showEvacueeReg" x-cloak
    x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100"
    class="fixed inset-0 z-50 flex items-start justify-center p-4 pt-12 bg-slate-900/50 backdrop-blur-sm overflow-y-auto"
    @click.self="showEvacueeReg = false">
    <div x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 scale-95" x-transition:enter-end="opacity-100 scale-100"
        class="bg-white rounded-2xl shadow-float w-full max-w-2xl mb-8">

        {{-- Modal Header --}}
        <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <div>
                <h3 class="font-semibold text-slate-800">Register Evacuee</h3>
                <p class="text-xs text-slate-500 mt-0.5"
                    x-text="{
                        1: 'Step 1 of 6 — Search Resident',
                        2: 'Step 2 of 6 — Select Members',
                        3: 'Step 3 of 6 — Health & Special Needs',
                        4: 'Step 4 of 6 — Center Assignment',
                        5: 'Step 5 of 6 — Kit Issuance',
                        6: 'Step 6 of 6 — Complete',
                    }[evacueeRegStep]">
                </p>
            </div>
            <button @click="showEvacueeReg = false" class="p-2 rounded-xl text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors">
                <i data-lucide="x" class="w-5 h-5"></i>
            </button>
        </div>

        {{-- Step Progress Indicator --}}
        <div class="px-6 pt-4">
            <div class="flex items-center gap-1">
                @foreach([1,2,3,4,5,6] as $s)
                <div class="flex-1 h-1.5 rounded-full transition-colors duration-300"
                    :class="evacueeRegStep >= {{ $s }} ? 'bg-brand-500' : 'bg-slate-200'"></div>
                @endforeach
            </div>
            <div class="flex justify-between mt-1.5">
                @foreach(['Search','Members','Health','Center','Kits','Done'] as $sl)
                <span class="text-[10px] text-slate-400">{{ $sl }}</span>
                @endforeach
            </div>
        </div>

        {{-- Step Contents --}}
        <div class="p-6 min-h-[320px]">

            {{-- Step 1: Search Resident --}}
            <div x-show="evacueeRegStep === 1" class="space-y-4">
                <div class="relative">
                    <i data-lucide="search" class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none"></i>
                    <input type="text" x-model="regStep1Search" placeholder="Search resident by name or ID…"
                        class="w-full pl-9 pr-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
                </div>
                <div class="space-y-2">
                    <p class="text-xs text-slate-500 font-medium">Resident Records</p>
                    @foreach([
                        ['id' => 'ESP-2021-045123', 'name' => 'Rodrigo Santos', 'brgy' => 'Masbaranon', 'sitio' => 'Purok 3'],
                        ['id' => 'ESP-2021-045124', 'name' => 'Maria Santos', 'brgy' => 'Masbaranon', 'sitio' => 'Purok 3'],
                    ] as $res)
                    <button @click="selectedResident = '{{ $res['name'] }}'; $nextTick(() => window.renderIcons?.())"
                        :class="selectedResident === '{{ $res['name'] }}' ? 'border-brand-400 bg-brand-50/40' : 'border-slate-200 bg-white hover:border-slate-300'"
                        class="w-full flex items-center gap-3 p-3 rounded-xl border transition-colors text-left">
                        <div class="w-9 h-9 rounded-xl bg-slate-100 flex items-center justify-center flex-shrink-0">
                            <i data-lucide="user" class="w-4 h-4 text-slate-500"></i>
                        </div>
                        <div class="flex-1">
                            <p class="text-sm font-medium text-slate-800">{{ $res['name'] }}</p>
                            <p class="text-xs text-slate-400">{{ $res['id'] }} · {{ $res['brgy'] }}, {{ $res['sitio'] }}</p>
                        </div>
                        <template x-if="selectedResident === '{{ $res['name'] }}'">
                            <i data-lucide="circle-check" class="w-5 h-5 text-brand-600 flex-shrink-0"></i>
                        </template>
                    </button>
                    @endforeach
                    <button @click="selectedResident = 'walk-in'; $nextTick(() => window.renderIcons?.())"
                        :class="selectedResident === 'walk-in' ? 'border-amber-400 bg-amber-50/40' : 'border-slate-200 bg-white hover:border-slate-300'"
                        class="w-full flex items-center gap-3 p-3 rounded-xl border transition-colors text-left">
                        <div class="w-9 h-9 rounded-xl bg-amber-100 flex items-center justify-center flex-shrink-0">
                            <i data-lucide="user-plus" class="w-4 h-4 text-amber-600"></i>
                        </div>
                        <div>
                            <p class="text-sm font-medium text-slate-700">Walk-in from another municipality</p>
                            <p class="text-xs text-slate-400">Register without an existing resident record</p>
                        </div>
                    </button>
                </div>
            </div>

            {{-- Step 2: Select Members --}}
            <div x-show="evacueeRegStep === 2" class="space-y-4">
                <div class="flex items-center justify-between p-3 bg-slate-50 rounded-xl border border-slate-200">
                    <label class="text-sm font-medium text-slate-700">Select all present members</label>
                    <input type="checkbox" class="w-4 h-4 rounded border-slate-300 text-brand-600 focus:ring-brand-500">
                </div>
                <div class="space-y-2">
                    @foreach([
                        ['name' => 'Rodrigo Santos', 'age' => 54, 'rel' => 'Head'],
                        ['name' => 'Elena Santos', 'age' => 50, 'rel' => 'Spouse'],
                        ['name' => 'Marco Santos', 'age' => 22, 'rel' => 'Son'],
                        ['name' => 'Ana Santos', 'age' => 17, 'rel' => 'Daughter'],
                        ['name' => 'Lola Minda Santos', 'age' => 78, 'rel' => 'Mother'],
                    ] as $m)
                    <label class="flex items-center gap-3 p-3 rounded-xl border border-slate-200 bg-white hover:border-slate-300 cursor-pointer transition-colors">
                        <input type="checkbox" checked class="w-4 h-4 rounded border-slate-300 text-brand-600 focus:ring-brand-500">
                        <div class="flex-1">
                            <p class="text-sm font-medium text-slate-800">{{ $m['name'] }}</p>
                            <p class="text-xs text-slate-400">Age {{ $m['age'] }} · {{ $m['rel'] }}</p>
                        </div>
                    </label>
                    @endforeach
                </div>
            </div>

            {{-- Step 3: Health & Special Needs --}}
            <div x-show="evacueeRegStep === 3" class="space-y-4">
                <p class="text-sm text-slate-600">Check all that apply to household members:</p>
                <div class="grid grid-cols-2 gap-2">
                    @foreach(['Senior Citizen', 'PWD', 'Pregnant', 'Infant (under 1 yr)', 'Chronic Medication', 'Medical Equipment', 'Food Allergy', 'Psychosocial Support Needed'] as $hf)
                    <label class="flex items-center gap-2.5 p-3 rounded-xl border border-slate-200 bg-white hover:border-brand-300 cursor-pointer transition-colors">
                        <input type="checkbox" class="w-4 h-4 rounded border-slate-300 text-brand-600 focus:ring-brand-500">
                        <span class="text-sm text-slate-700">{{ $hf }}</span>
                    </label>
                    @endforeach
                </div>
                <div>
                    <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Additional Notes</label>
                    <textarea rows="3" placeholder="Describe specific needs or conditions…"
                        class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors resize-none"></textarea>
                </div>
            </div>

            {{-- Step 4: Center Assignment --}}
            <div x-show="evacueeRegStep === 4" class="space-y-4">
                <div class="flex items-center gap-2 p-3 bg-amber-50 border border-amber-200 rounded-xl">
                    <i data-lucide="triangle-alert" class="w-4 h-4 text-amber-500 flex-shrink-0"></i>
                    <p class="text-xs text-amber-700">Household ESP-2021-045123 is not currently checked in at any center.</p>
                </div>
                <div>
                    <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Select Evacuation Center</label>
                    <select class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
                        <option value="">— Choose center —</option>
                        @foreach($centers as $c)
                            @if(in_array($c['status'], ['Open', 'Near Capacity']))
                            <option value="{{ $c['id'] }}">{{ $c['name'] }} — {{ $c['occupants'] }}/{{ $c['capacity'] }} ({{ $c['status'] }})</option>
                            @endif
                        @endforeach
                    </select>
                </div>
                <div>
                    <label class="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1.5 block">Zone / Room Assignment</label>
                    <select class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-slate-50 focus:bg-white focus:border-brand-400 focus:outline-none transition-colors">
                        <option value="">— Choose zone —</option>
                        <option>Zone A</option>
                        <option>Zone B</option>
                        <option>Room 1-A</option>
                        <option>Room 1-B</option>
                        <option>Main Hall</option>
                        <option>Sector 1</option>
                        <option>Sector 2</option>
                    </select>
                </div>
            </div>

            {{-- Step 5: Kit Issuance --}}
            <div x-show="evacueeRegStep === 5" class="space-y-4">
                <p class="text-sm text-slate-600">Select initial relief items to issue upon check-in:</p>
                <div class="space-y-2">
                    @foreach([
                        ['label' => 'Hygiene Kit', 'icon' => 'droplets', 'note' => '210 in stock'],
                        ['label' => 'Blanket', 'icon' => 'wind', 'note' => '290 in stock'],
                        ['label' => 'Sleeping Mat', 'icon' => 'layers', 'note' => '380 in stock'],
                        ['label' => 'Family Food Pack', 'icon' => 'package', 'note' => '95 in stock'],
                        ['label' => 'Water (1.5L × 6)', 'icon' => 'droplet', 'note' => '480 bottles in stock'],
                    ] as $kit)
                    <label class="flex items-center gap-3 p-3 rounded-xl border border-slate-200 bg-white hover:border-brand-300 cursor-pointer transition-colors">
                        <input type="checkbox" checked class="w-4 h-4 rounded border-slate-300 text-brand-600 focus:ring-brand-500">
                        <i data-lucide="{{ $kit['icon'] }}" class="w-4 h-4 text-slate-400"></i>
                        <div class="flex-1">
                            <p class="text-sm font-medium text-slate-700">{{ $kit['label'] }}</p>
                            <p class="text-xs text-slate-400">{{ $kit['note'] }}</p>
                        </div>
                    </label>
                    @endforeach
                </div>
            </div>

            {{-- Step 6: Complete --}}
            <div x-show="evacueeRegStep === 6" class="space-y-4">
                <div class="flex flex-col items-center text-center gap-3 py-4">
                    <div class="w-14 h-14 rounded-2xl bg-emerald-100 flex items-center justify-center">
                        <i data-lucide="circle-check" class="w-7 h-7 text-emerald-600"></i>
                    </div>
                    <h4 class="text-base font-semibold text-slate-800">Ready to Complete Check-In</h4>
                    <p class="text-sm text-slate-500">Review the summary below, then click Complete Check-In to register the household.</p>
                </div>
                <div class="bg-slate-50 rounded-xl p-4 space-y-2 text-sm">
                    <div class="flex justify-between">
                        <span class="text-slate-500">Household Head</span>
                        <span class="font-medium text-slate-800">Rodrigo Santos</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-slate-500">Members Checked In</span>
                        <span class="font-medium text-slate-800">5 persons</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-slate-500">Home Barangay</span>
                        <span class="font-medium text-slate-800">Masbaranon, Purok 3</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-slate-500">Assigned Center</span>
                        <span class="font-medium text-slate-800">Masbaranon Elementary School</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-slate-500">Zone</span>
                        <span class="font-medium text-slate-800">Room 1-A</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-slate-500">Health Flags</span>
                        <span class="font-medium text-slate-800">Senior Citizen, Chronic Medication</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-slate-500">Kits to Issue</span>
                        <span class="font-medium text-slate-800">Hygiene Kit, Blanket, Sleeping Mat</span>
                    </div>
                </div>
            </div>

        </div>

        {{-- Modal Navigation --}}
        <div class="px-6 py-4 border-t border-slate-100 bg-slate-50/60 rounded-b-2xl flex items-center justify-between">
            <button @click="evacueeRegStep > 1 ? evacueeRegStep-- : (showEvacueeReg = false); $nextTick(() => window.renderIcons?.())"
                class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-4 py-2 hover:border-slate-300 transition-colors">
                <i data-lucide="chevron-left" class="w-4 h-4"></i>
                <span x-text="evacueeRegStep > 1 ? 'Back' : 'Cancel'"></span>
            </button>
            <template x-if="evacueeRegStep < 6">
                <button @click="evacueeRegStep++; $nextTick(() => window.renderIcons?.())"
                    :disabled="evacueeRegStep === 1 && !selectedResident"
                    :class="evacueeRegStep === 1 && !selectedResident ? 'opacity-40 cursor-not-allowed' : 'hover:bg-brand-700'"
                    class="inline-flex items-center gap-1.5 text-sm font-medium text-white bg-brand-600 rounded-xl px-4 py-2 transition-colors">
                    Next <i data-lucide="chevron-right" class="w-4 h-4"></i>
                </button>
            </template>
            <template x-if="evacueeRegStep === 6">
                <button @click="toast('Household EVA-015 successfully checked in at Masbaranon Elementary School.', 'success'); showEvacueeReg = false; evacueeRegStep = 1; selectedResident = null"
                    class="inline-flex items-center gap-1.5 text-sm font-medium text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl px-4 py-2 transition-colors">
                    <i data-lucide="circle-check" class="w-4 h-4"></i> Complete Check-In
                </button>
            </template>
        </div>
    </div>
</div>

</div>{{-- end x-data wrapper --}}
