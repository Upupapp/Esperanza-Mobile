{{-- Damage & Needs Assessment Tab --}}
<div class="space-y-6">

    {{-- Header --}}
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
            <h2 class="text-xl font-bold text-navy-900">Damage & Needs Assessment</h2>
            <p class="text-sm text-slate-500 mt-0.5">Barangay-level damage assessments, needs prioritization, and municipal consolidation.</p>
        </div>
        <div class="flex items-center gap-2 self-start sm:self-auto">
            <button
                @click="showCreateAssessment = true"
                class="inline-flex items-center gap-2 px-4 py-2 bg-brand-blue text-white rounded-xl text-sm font-medium hover:bg-brand-blue/90 transition-colors shadow-sm">
                <i data-lucide="plus" class="w-4 h-4"></i>
                New Assessment
            </button>
            <button
                @click="$dispatch('toast', { message: 'Assessment report exported.', variant: 'success' })"
                class="inline-flex items-center gap-2 px-4 py-2 bg-white border border-slate-200 rounded-xl text-sm font-medium text-slate-700 hover:bg-slate-50 transition-colors shadow-sm">
                <i data-lucide="download" class="w-4 h-4"></i>
                Export
            </button>
        </div>
    </div>

    {{-- Summary Pills --}}
    <div class="flex flex-wrap gap-3">
        <div class="flex items-center gap-2 px-4 py-2 bg-white rounded-xl border border-slate-100 shadow-card text-sm">
            <i data-lucide="clipboard-list" class="w-4 h-4 text-slate-400"></i>
            <span class="text-slate-500">Total:</span>
            <span class="font-bold text-slate-800">8</span>
        </div>
        <div class="flex items-center gap-2 px-4 py-2 bg-emerald-50 rounded-xl border border-emerald-100 shadow-card text-sm">
            <i data-lucide="circle-check" class="w-4 h-4 text-emerald-500"></i>
            <span class="text-emerald-700">Approved:</span>
            <span class="font-bold text-emerald-800">1</span>
        </div>
        <div class="flex items-center gap-2 px-4 py-2 bg-blue-50 rounded-xl border border-blue-100 shadow-card text-sm">
            <i data-lucide="shield-check" class="w-4 h-4 text-blue-500"></i>
            <span class="text-blue-700">Validated:</span>
            <span class="font-bold text-blue-800">1</span>
        </div>
        <div class="flex items-center gap-2 px-4 py-2 bg-indigo-50 rounded-xl border border-indigo-100 shadow-card text-sm">
            <i data-lucide="search" class="w-4 h-4 text-indigo-500"></i>
            <span class="text-indigo-700">For Validation:</span>
            <span class="font-bold text-indigo-800">2</span>
        </div>
        <div class="flex items-center gap-2 px-4 py-2 bg-amber-50 rounded-xl border border-amber-100 shadow-card text-sm">
            <i data-lucide="file-text" class="w-4 h-4 text-amber-500"></i>
            <span class="text-amber-700">Draft / Submitted:</span>
            <span class="font-bold text-amber-800">4</span>
        </div>
        <div class="flex items-center gap-2 px-4 py-2 bg-rose-50 rounded-xl border border-rose-100 shadow-card text-sm">
            <i data-lucide="banknote" class="w-4 h-4 text-rose-500"></i>
            <span class="text-rose-700">Est. Total Damage:</span>
            <span class="font-bold text-rose-800">₱9,570,000</span>
        </div>
    </div>

    {{-- Filter Bar --}}
    <div class="flex flex-wrap gap-3 items-center">
        <div class="relative flex-1 min-w-[200px]">
            <i data-lucide="search" class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"></i>
            <input
                type="text"
                x-model="damageSearch"
                placeholder="Search by ID or barangay…"
                class="w-full pl-9 pr-4 py-2 rounded-xl border border-slate-200 text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand-blue/30 focus:border-brand-blue bg-white">
        </div>
        <select
            x-model="damageTypeFilter"
            class="px-3 py-2 rounded-xl border border-slate-200 text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
            <option value="">All Types</option>
            <option>Initial Rapid Assessment</option>
            <option>Barangay Damage Assessment</option>
            <option>Infrastructure Assessment</option>
            <option>Housing Assessment</option>
            <option>Agriculture Assessment</option>
            <option>Livelihood Assessment</option>
            <option>Evacuation Center Assessment</option>
            <option>Post-Disaster Needs Assessment</option>
        </select>
        <select
            x-model="damageStatusFilter"
            class="px-3 py-2 rounded-xl border border-slate-200 text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
            <option value="">All Statuses</option>
            <option>Draft</option>
            <option>Submitted</option>
            <option>For Validation</option>
            <option>Validated</option>
            <option>For Approval</option>
            <option>Approved</option>
            <option>Returned for Revision</option>
            <option>Consolidated</option>
        </select>
        <select
            x-model="damageBarangayFilter"
            class="px-3 py-2 rounded-xl border border-slate-200 text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
            <option value="">All Barangays</option>
            @foreach($barangays as $brgy)
            <option value="{{ $brgy }}">{{ $brgy }}</option>
            @endforeach
        </select>
    </div>

    {{-- Assessment Table --}}
    <div class="bg-white rounded-2xl shadow-card border border-slate-100 overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-sm">
                <thead>
                    <tr class="bg-slate-50 border-b border-slate-100">
                        <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">ID</th>
                        <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Incident</th>
                        <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Barangay</th>
                        <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Type</th>
                        <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Date</th>
                        <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Assessor</th>
                        <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Affected Fam.</th>
                        <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Est. Damage</th>
                        <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Priority Needs</th>
                        <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Status</th>
                        <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-50">
                    @foreach($assessments as $a)
                    @php
                        $statusBadgeClass = match($a['status'] ?? 'Draft') {
                            'Approved'             => 'bg-emerald-100 text-emerald-700',
                            'Validated'            => 'bg-blue-100 text-blue-700',
                            'For Validation'       => 'bg-indigo-100 text-indigo-700',
                            'For Approval'         => 'bg-violet-100 text-violet-700',
                            'Draft'                => 'bg-slate-100 text-slate-600',
                            'Submitted'            => 'bg-amber-100 text-amber-700',
                            'Returned for Revision'=> 'bg-rose-100 text-rose-700',
                            'Consolidated'         => 'bg-teal-100 text-teal-700',
                            default                => 'bg-slate-100 text-slate-600',
                        };
                        $needs = $a['priority_needs'] ?? [];
                        $shownNeeds = array_slice($needs, 0, 2);
                        $extraNeeds = count($needs) > 2 ? count($needs) - 2 : 0;
                        $isEditable = in_array($a['status'] ?? 'Draft', ['Draft', 'Submitted', 'Returned for Revision']);
                    @endphp
                    <tr
                        x-show="
                            $store.session.inScope('{{ $a['barangay'] }}') &&
                            (damageSearch === '' || '{{ strtolower($a['id']) }}'.includes(damageSearch.toLowerCase()) || '{{ strtolower($a['barangay']) }}'.includes(damageSearch.toLowerCase())) &&
                            (damageTypeFilter === '' || '{{ $a['type'] }}' === damageTypeFilter) &&
                            (damageStatusFilter === '' || '{{ $a['status'] }}' === damageStatusFilter) &&
                            (damageBarangayFilter === '' || '{{ $a['barangay'] }}' === damageBarangayFilter)
                        "
                        class="hover:bg-slate-50 transition-colors">
                        <td class="px-4 py-3">
                            <span class="font-mono text-xs text-slate-500 bg-slate-100 px-2 py-0.5 rounded">{{ $a['id'] }}</span>
                        </td>
                        <td class="px-4 py-3 text-xs text-slate-600 max-w-[120px]">
                            <span class="line-clamp-1" title="{{ $a['incident'] }}">{{ $a['incident'] }}</span>
                        </td>
                        <td class="px-4 py-3 font-medium text-slate-800 text-xs">{{ $a['barangay'] }}</td>
                        <td class="px-4 py-3 text-xs text-slate-600 max-w-[140px]">
                            <span class="line-clamp-2">{{ $a['type'] }}</span>
                        </td>
                        <td class="px-4 py-3 text-xs text-slate-600 whitespace-nowrap">{{ $a['date'] }}</td>
                        <td class="px-4 py-3 text-xs text-slate-500">{{ $a['assessor'] }}</td>
                        <td class="px-4 py-3 text-center font-semibold text-slate-800">{{ number_format($a['affected_families']) }}</td>
                        <td class="px-4 py-3 font-semibold text-slate-800 text-xs whitespace-nowrap">₱{{ number_format($a['estimated_damage']) }}</td>
                        <td class="px-4 py-3">
                            <div class="flex flex-wrap gap-1">
                                @foreach($shownNeeds as $need)
                                <span class="px-1.5 py-0.5 bg-blue-50 text-blue-700 rounded text-xs">{{ $need }}</span>
                                @endforeach
                                @if($extraNeeds > 0)
                                <span class="px-1.5 py-0.5 bg-slate-100 text-slate-500 rounded text-xs">+{{ $extraNeeds }} more</span>
                                @endif
                            </div>
                        </td>
                        <td class="px-4 py-3">
                            <span class="px-2 py-0.5 rounded-full text-xs font-medium {{ $statusBadgeClass }}">{{ $a['status'] }}</span>
                        </td>
                        <td class="px-4 py-3">
                            <div class="flex items-center gap-1">
                                <button
                                    @click="selectedAssessment = {{ json_encode($a) }}; showAssessmentDetail = true"
                                    class="p-1.5 text-brand-blue hover:bg-blue-50 rounded-lg transition-colors" title="View">
                                    <i data-lucide="eye" class="w-3.5 h-3.5"></i>
                                </button>
                                @if($isEditable)
                                <button
                                    @click="$dispatch('toast', { message: 'Editing {{ $a['id'] }}...', variant: 'info' })"
                                    class="p-1.5 text-slate-500 hover:bg-slate-100 rounded-lg transition-colors" title="Edit">
                                    <i data-lucide="pencil" class="w-3.5 h-3.5"></i>
                                </button>
                                <button
                                    @click="$dispatch('toast', { message: '{{ $a['id'] }} submitted for validation.', variant: 'success' })"
                                    class="p-1.5 text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors" title="Submit">
                                    <i data-lucide="send" class="w-3.5 h-3.5"></i>
                                </button>
                                @endif
                                @if($a['status'] === 'For Validation')
                                <button
                                    @click="$dispatch('toast', { message: '{{ $a['id'] }} validated successfully.', variant: 'success' })"
                                    class="p-1.5 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors" title="Validate">
                                    <i data-lucide="shield-check" class="w-3.5 h-3.5"></i>
                                </button>
                                @endif
                                @if($a['status'] === 'Validated' || $a['status'] === 'For Approval')
                                <button
                                    @click="$dispatch('toast', { message: '{{ $a['id'] }} approved.', variant: 'success' })"
                                    class="p-1.5 text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors" title="Approve">
                                    <i data-lucide="circle-check" class="w-3.5 h-3.5"></i>
                                </button>
                                @endif
                                <button
                                    @click="$dispatch('toast', { message: '{{ $a['id'] }} returned for revision. Assessor notified.', variant: 'info' })"
                                    class="p-1.5 text-amber-500 hover:bg-amber-50 rounded-lg transition-colors" title="Return">
                                    <i data-lucide="undo-2" class="w-3.5 h-3.5"></i>
                                </button>
                                <button
                                    @click="$dispatch('toast', { message: '{{ $a['id'] }} exported.', variant: 'success' })"
                                    class="p-1.5 text-slate-400 hover:bg-slate-100 rounded-lg transition-colors" title="Export">
                                    <i data-lucide="download" class="w-3.5 h-3.5"></i>
                                </button>
                            </div>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>

    {{-- ================================================================ --}}
    {{-- Municipal Consolidated Summary --}}
    {{-- ================================================================ --}}
    <div class="bg-white rounded-2xl shadow-card border border-slate-100 overflow-hidden">
        <div class="p-5 border-b border-slate-100">
            <div class="flex items-center gap-2">
                <i data-lucide="chart-column" class="w-5 h-5 text-brand-blue"></i>
                <h3 class="text-base font-bold text-navy-900">Municipal Consolidated Summary — SWM-2026-07</h3>
            </div>
            <p class="text-xs text-slate-500 mt-1">Estimates subject to validation. Assessment coverage: 8 of 20 barangays.</p>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-sm">
                <thead>
                    <tr class="bg-slate-50 border-b border-slate-100">
                        <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Barangay</th>
                        <th class="text-right px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Affected Fam.</th>
                        <th class="text-right px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Housing Damage</th>
                        <th class="text-right px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Infrastructure</th>
                        <th class="text-right px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Agriculture</th>
                        <th class="text-right px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Total</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-50">
                    @foreach([
                        ['Masbaranon',  48,  '₱1,840,000', '₱640,000',   '—',         '₱2,480,000'],
                        ['Baras',       22,  '₱520,000',   '₱370,000',   '—',         '₱890,000'],
                        ['Santiago',    '—', '—',           '₱3,200,000', '—',         '₱3,200,000'],
                        ['Domorog',     8,   '—',           '₱1,200,000', '—',         '₱1,200,000'],
                        ['Magsaysay',   28,  '₱680,000',   '₱470,000',   '—',         '₱1,150,000'],
                        ['Guadalupe',   45,  '—',           '—',          '₱560,000',  '₱560,000'],
                        ['Rizal',       14,  '₱280,000',   '₱140,000',   '—',         '₱420,000'],
                        ['Poblacion',   84,  '₱1,240,000', '₱630,000',   '—',         '₱1,870,000'],
                    ] as [$brgy,$fam,$housing,$infra,$agri,$total])
                    <tr class="hover:bg-slate-50 transition-colors">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ $brgy }}</td>
                        <td class="px-4 py-3 text-right text-slate-700">{{ is_numeric($fam) ? number_format($fam) : $fam }}</td>
                        <td class="px-4 py-3 text-right text-slate-700 {{ $housing !== '—' ? 'font-medium' : 'text-slate-400' }}">{{ $housing }}</td>
                        <td class="px-4 py-3 text-right text-slate-700 {{ $infra !== '—' ? 'font-medium' : 'text-slate-400' }}">{{ $infra }}</td>
                        <td class="px-4 py-3 text-right text-slate-700 {{ $agri !== '—' ? 'font-medium' : 'text-slate-400' }}">{{ $agri }}</td>
                        <td class="px-4 py-3 text-right font-bold text-slate-900">{{ $total }}</td>
                    </tr>
                    @endforeach
                </tbody>
                <tfoot>
                    <tr class="bg-slate-50 border-t-2 border-slate-200">
                        <td class="px-4 py-3 font-bold text-slate-900">TOTAL</td>
                        <td class="px-4 py-3 text-right font-bold text-slate-900">249</td>
                        <td class="px-4 py-3 text-right font-bold text-slate-900">₱4,560,000</td>
                        <td class="px-4 py-3 text-right font-bold text-slate-900">₱6,650,000</td>
                        <td class="px-4 py-3 text-right font-bold text-slate-900">₱560,000</td>
                        <td class="px-4 py-3 text-right font-bold text-rose-700 text-base">₱11,770,000</td>
                    </tr>
                </tfoot>
            </table>
        </div>
    </div>

    {{-- ================================================================ --}}
    {{-- MODAL: Assessment Detail --}}
    {{-- ================================================================ --}}
    <div
        x-show="showAssessmentDetail"
        x-cloak
        x-data="{ assessTab: 'population', showApproveConfirm: false }"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
        @click.self="showAssessmentDetail = false; showApproveConfirm = false">
        <div class="bg-white rounded-2xl shadow-float w-full max-w-4xl max-h-[90vh] overflow-y-auto p-6">

            {{-- Modal Header --}}
            <div class="flex items-start justify-between mb-5">
                <div>
                    <div class="flex items-center gap-2 mb-1">
                        <h3 class="text-base font-bold text-navy-900" x-text="selectedAssessment?.id ?? 'Assessment Detail'"></h3>
                        <span class="px-2 py-0.5 bg-indigo-100 text-indigo-700 rounded-full text-xs font-medium" x-text="selectedAssessment?.status ?? ''"></span>
                    </div>
                    <p class="text-xs text-slate-500" x-text="(selectedAssessment?.type ?? '') + ' · ' + (selectedAssessment?.barangay ?? '') + ' · ' + (selectedAssessment?.date ?? '')"></p>
                </div>
                <button @click="showAssessmentDetail = false; showApproveConfirm = false" class="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                    <i data-lucide="x" class="w-4 h-4 text-slate-500"></i>
                </button>
            </div>

            {{-- Mini Tabs --}}
            <div class="flex flex-wrap gap-1.5 mb-5 pb-4 border-b border-slate-100">
                @foreach([['population','Population'],['housing','Housing'],['infrastructure','Infrastructure'],['agriculture','Agriculture'],['needs','Needs'],['financial','Financial'],['certification','Certification']] as [$tabKey,$tabLabel])
                <button
                    @click="assessTab = '{{ $tabKey }}'"
                    :class="assessTab === '{{ $tabKey }}' ? 'bg-brand-blue text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'"
                    class="px-3 py-1.5 rounded-lg text-xs font-medium transition-colors">
                    {{ $tabLabel }}
                </button>
                @endforeach
            </div>

            {{-- Tab: Population --}}
            <div x-show="assessTab === 'population'" class="space-y-3">
                <h4 class="text-sm font-semibold text-navy-900">Affected Population</h4>
                <div class="bg-white rounded-xl border border-slate-100 overflow-hidden">
                    <table class="w-full text-sm">
                        <thead>
                            <tr class="bg-slate-50 border-b border-slate-100">
                                <th class="text-left px-4 py-2.5 text-xs font-semibold text-slate-500">Category</th>
                                <th class="text-right px-4 py-2.5 text-xs font-semibold text-slate-500">Count</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-50">
                            @foreach([
                                ['Affected Families', 48, 'emerald'],
                                ['Displaced Families', 32, 'amber'],
                                ['Injured', 3, 'orange'],
                                ['Missing', 1, 'rose'],
                                ['Deceased', 0, 'slate'],
                                ['Rescued', 38, 'blue'],
                                ['Evacuated', 48, 'indigo'],
                            ] as [$cat, $val, $clr])
                            <tr class="hover:bg-slate-50 transition-colors">
                                <td class="px-4 py-2.5 text-slate-700">{{ $cat }}</td>
                                <td class="px-4 py-2.5 text-right">
                                    @php
                                        $numClass = match($clr) {
                                            'emerald' => 'text-emerald-700 font-bold',
                                            'amber'   => 'text-amber-700 font-bold',
                                            'orange'  => 'text-orange-600 font-semibold',
                                            'rose'    => 'text-rose-600 font-semibold',
                                            'blue'    => 'text-blue-700 font-semibold',
                                            'indigo'  => 'text-indigo-700 font-semibold',
                                            default   => 'text-slate-500',
                                        };
                                    @endphp
                                    <span class="{{ $numClass }}">{{ number_format($val) }}</span>
                                </td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>

            {{-- Tab: Housing --}}
            <div x-show="assessTab === 'housing'" x-cloak class="space-y-3">
                <h4 class="text-sm font-semibold text-navy-900">Housing Damage Assessment</h4>
                <div class="bg-white rounded-xl border border-slate-100 overflow-hidden">
                    <table class="w-full text-sm">
                        <thead>
                            <tr class="bg-slate-50 border-b border-slate-100">
                                <th class="text-left px-4 py-2.5 text-xs font-semibold text-slate-500">Category</th>
                                <th class="text-center px-4 py-2.5 text-xs font-semibold text-slate-500">Count</th>
                                <th class="text-left px-4 py-2.5 text-xs font-semibold text-slate-500">Notes</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-50">
                            <tr class="hover:bg-slate-50">
                                <td class="px-4 py-2.5 text-slate-700">Partially Damaged</td>
                                <td class="px-4 py-2.5 text-center font-semibold text-amber-700">12</td>
                                <td class="px-4 py-2.5 text-slate-500 text-xs">Roof/walls</td>
                            </tr>
                            <tr class="hover:bg-slate-50">
                                <td class="px-4 py-2.5 text-slate-700">Totally Damaged</td>
                                <td class="px-4 py-2.5 text-center font-semibold text-rose-700">4</td>
                                <td class="px-4 py-2.5 text-slate-500 text-xs">Collapsed/uninhabitable</td>
                            </tr>
                            <tr class="hover:bg-slate-50">
                                <td class="px-4 py-2.5 text-slate-700">Unsafe for Occupancy</td>
                                <td class="px-4 py-2.5 text-center font-semibold text-orange-700">6</td>
                                <td class="px-4 py-2.5 text-slate-500 text-xs">Pending structural check</td>
                            </tr>
                            <tr class="bg-rose-50 border-t border-slate-200">
                                <td class="px-4 py-2.5 font-semibold text-slate-800">Estimated Housing Damage</td>
                                <td class="px-4 py-2.5 text-center text-slate-400">—</td>
                                <td class="px-4 py-2.5 font-bold text-rose-700 text-base">₱1,840,000</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            {{-- Tab: Infrastructure --}}
            <div x-show="assessTab === 'infrastructure'" x-cloak class="space-y-3">
                <h4 class="text-sm font-semibold text-navy-900">Infrastructure Damage</h4>
                <div class="bg-white rounded-xl border border-slate-100 overflow-hidden">
                    <table class="w-full text-sm">
                        <thead>
                            <tr class="bg-slate-50 border-b border-slate-100">
                                <th class="text-left px-4 py-2.5 text-xs font-semibold text-slate-500">Type</th>
                                <th class="text-left px-4 py-2.5 text-xs font-semibold text-slate-500">Affected</th>
                                <th class="text-right px-4 py-2.5 text-xs font-semibold text-slate-500">Est. Damage</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-50">
                            @foreach([
                                ['Roads',               '2 sections',                   '₱380,000'],
                                ['Bridges',             '1 bridge',                     '₱450,000'],
                                ['Schools',             '1 (flooding only)',             '₱120,000'],
                                ['Health Facilities',   'None',                          '—'],
                                ['Gov. Buildings',      'None',                          '—'],
                                ['Water System',        '1 pumping station interrupted', '₱45,000'],
                                ['Power',               'Interrupted (utility)',          '—'],
                                ['Communications',      'Degraded',                      '—'],
                                ['Drainage',            '3 sections clogged',            '₱85,000'],
                            ] as [$type,$affected,$damage])
                            <tr class="hover:bg-slate-50 transition-colors">
                                <td class="px-4 py-2.5 text-slate-700">{{ $type }}</td>
                                <td class="px-4 py-2.5 text-slate-600 text-xs">{{ $affected }}</td>
                                <td class="px-4 py-2.5 text-right font-semibold {{ $damage === '—' ? 'text-slate-400' : 'text-slate-800' }}">{{ $damage }}</td>
                            </tr>
                            @endforeach
                            <tr class="bg-rose-50 border-t border-slate-200">
                                <td class="px-4 py-2.5 font-bold text-slate-900" colspan="2">Total Infrastructure Damage</td>
                                <td class="px-4 py-2.5 text-right font-bold text-rose-700 text-base">₱1,080,000</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            {{-- Tab: Agriculture --}}
            <div x-show="assessTab === 'agriculture'" x-cloak class="space-y-3">
                <h4 class="text-sm font-semibold text-navy-900">Agriculture & Livelihood</h4>
                <div class="bg-white rounded-xl border border-slate-100 overflow-hidden">
                    <table class="w-full text-sm">
                        <thead>
                            <tr class="bg-slate-50 border-b border-slate-100">
                                <th class="text-left px-4 py-2.5 text-xs font-semibold text-slate-500">Category</th>
                                <th class="text-right px-4 py-2.5 text-xs font-semibold text-slate-500">Value</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-50">
                            <tr class="hover:bg-slate-50"><td class="px-4 py-2.5 text-slate-700">Crop Area Affected</td><td class="px-4 py-2.5 text-right text-slate-600">0 ha (residential area)</td></tr>
                            <tr class="hover:bg-slate-50"><td class="px-4 py-2.5 text-slate-700">Estimated Crop Loss</td><td class="px-4 py-2.5 text-right text-slate-600">₱0</td></tr>
                            <tr class="hover:bg-slate-50"><td class="px-4 py-2.5 text-slate-700">Livestock Affected</td><td class="px-4 py-2.5 text-right text-slate-600">0</td></tr>
                            <tr class="hover:bg-slate-50"><td class="px-4 py-2.5 text-slate-700">Livelihood Interruption</td><td class="px-4 py-2.5 text-right text-slate-600">8 households (fishing/vending)</td></tr>
                            <tr class="bg-amber-50 border-t border-slate-200"><td class="px-4 py-2.5 font-semibold text-slate-800">Estimated Livelihood Loss</td><td class="px-4 py-2.5 text-right font-bold text-amber-700">₱85,000</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>

            {{-- Tab: Needs --}}
            <div x-show="assessTab === 'needs'" x-cloak class="space-y-3">
                <h4 class="text-sm font-semibold text-navy-900">Immediate Needs Checklist</h4>
                <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                    @foreach([
                        ['Food', true],
                        ['Water', true],
                        ['Shelter', true],
                        ['Medicine', true],
                        ['Rescue', true],
                        ['Sanitation', true],
                        ['Psychosocial Support', false],
                        ['Livelihood Assistance', false],
                        ['Road Clearing', true],
                        ['Power Restoration', false],
                    ] as [$need, $checked])
                    <div class="flex items-center gap-2.5 px-3 py-2.5 rounded-xl border {{ $checked ? 'border-emerald-200 bg-emerald-50' : 'border-slate-100 bg-white' }}">
                        <div class="flex-shrink-0 w-5 h-5 rounded-full flex items-center justify-center {{ $checked ? 'bg-emerald-500' : 'bg-slate-200' }}">
                            @if($checked)
                            <i data-lucide="check" class="w-3 h-3 text-white"></i>
                            @else
                            <i data-lucide="minus" class="w-3 h-3 text-slate-400"></i>
                            @endif
                        </div>
                        <span class="text-xs font-medium {{ $checked ? 'text-emerald-800' : 'text-slate-500' }}">{{ $need }}</span>
                    </div>
                    @endforeach
                </div>
            </div>

            {{-- Tab: Financial --}}
            <div x-show="assessTab === 'financial'" x-cloak class="space-y-3">
                <h4 class="text-sm font-semibold text-navy-900">Financial Damage Breakdown</h4>
                <div class="bg-white rounded-xl border border-slate-100 overflow-hidden">
                    <table class="w-full text-sm">
                        <thead>
                            <tr class="bg-slate-50 border-b border-slate-100">
                                <th class="text-left px-4 py-2.5 text-xs font-semibold text-slate-500">Category</th>
                                <th class="text-right px-4 py-2.5 text-xs font-semibold text-slate-500">Estimate</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-50">
                            <tr class="hover:bg-slate-50"><td class="px-4 py-2.5 text-slate-700">Housing Damage</td><td class="px-4 py-2.5 text-right font-semibold text-slate-800">₱1,840,000</td></tr>
                            <tr class="hover:bg-slate-50"><td class="px-4 py-2.5 text-slate-700">Infrastructure</td><td class="px-4 py-2.5 text-right font-semibold text-slate-800">₱1,080,000</td></tr>
                            <tr class="hover:bg-slate-50"><td class="px-4 py-2.5 text-slate-700">Agriculture / Livelihood</td><td class="px-4 py-2.5 text-right font-semibold text-slate-800">₱85,000</td></tr>
                            <tr class="hover:bg-slate-50"><td class="px-4 py-2.5 text-slate-700">Other</td><td class="px-4 py-2.5 text-right text-slate-400">₱0</td></tr>
                            <tr class="bg-rose-50 border-t-2 border-rose-200">
                                <td class="px-4 py-3 font-bold text-slate-900 text-base">Estimated Total</td>
                                <td class="px-4 py-3 text-right font-extrabold text-rose-700 text-xl">₱2,480,000 <span class="text-xs font-medium text-rose-500">est.</span></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <p class="text-xs text-slate-400 italic">Preliminary estimate. Subject to technical validation.</p>
            </div>

            {{-- Tab: Certification --}}
            <div x-show="assessTab === 'certification'" x-cloak class="space-y-5">
                <h4 class="text-sm font-semibold text-navy-900">Certification & Approval</h4>
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    {{-- Assessor --}}
                    <div class="bg-slate-50 rounded-xl p-4 space-y-2">
                        <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide">Assessor</p>
                        <p class="text-sm font-semibold text-slate-800" x-text="selectedAssessment?.assessor ?? 'Barangay DRRM Officer'"></p>
                        <p class="text-xs text-slate-500">Barangay DRRM Officer</p>
                        <div class="border-2 border-dashed border-slate-300 rounded-lg h-16 flex items-center justify-center">
                            <span class="text-xs text-slate-400">Signature placeholder</span>
                        </div>
                    </div>
                    {{-- Validator --}}
                    <div class="bg-slate-50 rounded-xl p-4 space-y-2">
                        <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide">Validator</p>
                        <input type="text" placeholder="Validator name" value="MDRRMO Officer Salinas" class="w-full px-2.5 py-1.5 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        <p class="text-xs text-slate-500">Municipal DRRM Officer</p>
                        <span class="px-2 py-0.5 bg-amber-100 text-amber-700 rounded-full text-xs font-medium">Pending Validation</span>
                    </div>
                    {{-- Approving Officer --}}
                    <div class="bg-slate-50 rounded-xl p-4 space-y-2">
                        <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide">Approving Officer</p>
                        <input type="text" placeholder="Officer name" value="Mayor Reyes" class="w-full px-2.5 py-1.5 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        <p class="text-xs text-slate-500">Local Chief Executive</p>
                        <span class="px-2 py-0.5 bg-slate-100 text-slate-600 rounded-full text-xs font-medium">Awaiting</span>
                    </div>
                </div>

                {{-- Attachments --}}
                <div>
                    <div class="flex items-center justify-between mb-3">
                        <h5 class="text-sm font-semibold text-navy-900">Attachments</h5>
                        <button
                            @click="$dispatch('toast', { message: 'Attachment upload dialog opened.', variant: 'info' })"
                            class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-brand-blue text-white rounded-lg text-xs font-medium hover:bg-brand-blue/90 transition-colors">
                            <i data-lucide="upload" class="w-3.5 h-3.5"></i>
                            Add Attachment
                        </button>
                    </div>
                    <div class="space-y-2">
                        @foreach([
                            ['Photo 1 — Flood damage Purok 3.jpg', 'Jul 15, 2026', '2.4 MB'],
                            ['Photo 2 — Roof damage sample.jpg',    'Jul 15, 2026', '1.8 MB'],
                            ['Site map sketch.jpg',                  'Jul 15, 2026', '890 KB'],
                        ] as [$fname,$fdate,$fsize])
                        <div class="flex items-center justify-between p-3 bg-slate-50 rounded-xl border border-slate-100">
                            <div class="flex items-center gap-2.5">
                                <i data-lucide="image" class="w-4 h-4 text-blue-400"></i>
                                <div>
                                    <p class="text-xs font-medium text-slate-800">{{ $fname }}</p>
                                    <p class="text-xs text-slate-400">Uploaded {{ $fdate }} · {{ $fsize }}</p>
                                </div>
                            </div>
                            <div class="flex items-center gap-1">
                                <button
                                    @click="$dispatch('toast', { message: 'Opening {{ $fname }}...', variant: 'info' })"
                                    class="px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-medium text-brand-blue hover:bg-blue-50 transition-colors">
                                    View
                                </button>
                                <button
                                    @click="$dispatch('toast', { message: '{{ $fname }} removed.', variant: 'info' })"
                                    class="px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-medium text-rose-500 hover:bg-rose-50 transition-colors">
                                    Remove
                                </button>
                            </div>
                        </div>
                        @endforeach
                    </div>
                </div>
            </div>

            {{-- Approve Confirm Banner --}}
            <div x-show="showApproveConfirm" x-cloak class="mt-4 p-4 bg-emerald-50 border border-emerald-200 rounded-xl">
                <p class="text-sm font-semibold text-emerald-800 mb-1">Confirm Approval</p>
                <p class="text-xs text-emerald-700 mb-3">Approving this assessment marks it as the official record for the barangay. This action cannot be undone.</p>
                <div class="flex gap-2">
                    <button
                        @click="$dispatch('toast', { message: 'Assessment approved successfully.', variant: 'success' }); showAssessmentDetail = false; showApproveConfirm = false"
                        class="px-4 py-2 bg-emerald-600 text-white rounded-xl text-xs font-semibold hover:bg-emerald-700 transition-colors">
                        Confirm Approve
                    </button>
                    <button
                        @click="showApproveConfirm = false"
                        class="px-4 py-2 bg-white border border-emerald-200 text-emerald-700 rounded-xl text-xs font-semibold hover:bg-emerald-50 transition-colors">
                        Cancel
                    </button>
                </div>
            </div>

            {{-- Modal Footer Actions --}}
            <div class="flex flex-wrap items-center gap-2 mt-6 pt-4 border-t border-slate-100">
                <button
                    @click="$dispatch('toast', { message: 'Assessment submitted for validation.', variant: 'success' })"
                    class="px-3 py-2 bg-indigo-600 text-white rounded-xl text-xs font-semibold hover:bg-indigo-700 transition-colors">
                    Submit for Validation
                </button>
                <button
                    @click="$dispatch('toast', { message: 'Assessment validated.', variant: 'success' })"
                    class="px-3 py-2 bg-blue-600 text-white rounded-xl text-xs font-semibold hover:bg-blue-700 transition-colors">
                    Validate
                </button>
                <button
                    @click="showApproveConfirm = true"
                    class="px-3 py-2 bg-emerald-600 text-white rounded-xl text-xs font-semibold hover:bg-emerald-700 transition-colors">
                    Approve
                </button>
                <button
                    @click="$dispatch('toast', { message: 'Returned for revision. Assessor has been notified.', variant: 'info' })"
                    class="px-3 py-2 bg-amber-500 text-white rounded-xl text-xs font-semibold hover:bg-amber-600 transition-colors">
                    Return for Revision
                </button>
                <button
                    @click="$dispatch('toast', { message: 'Assessment report exported.', variant: 'success' })"
                    class="px-3 py-2 bg-white border border-slate-200 text-slate-600 rounded-xl text-xs font-semibold hover:bg-slate-50 transition-colors">
                    <i data-lucide="download" class="w-3.5 h-3.5 inline-block mr-1"></i>
                    Export PDF
                </button>
                <button
                    @click="$dispatch('toast', { message: 'Sent to printer.', variant: 'success' })"
                    class="px-3 py-2 bg-white border border-slate-200 text-slate-600 rounded-xl text-xs font-semibold hover:bg-slate-50 transition-colors">
                    <i data-lucide="printer" class="w-3.5 h-3.5 inline-block mr-1"></i>
                    Print
                </button>
                <button
                    @click="showAssessmentDetail = false; showApproveConfirm = false"
                    class="ml-auto px-4 py-2 bg-slate-100 text-slate-600 rounded-xl text-xs font-semibold hover:bg-slate-200 transition-colors">
                    Close
                </button>
            </div>
        </div>
    </div>

    {{-- ================================================================ --}}
    {{-- MODAL: Create Assessment --}}
    {{-- ================================================================ --}}
    <div
        x-show="showCreateAssessment"
        x-cloak
        x-data="{
            newType: '',
            newIncident: '',
            newBarangay: '',
            newDate: '{{ date('Y-m-d') }}',
            newAssessor: '',
            newOffice: '',
            popAffected: 0, popDisplaced: 0, popInjured: 0, popMissing: 0, popDeceased: 0, popRescued: 0, popEvacuated: 0,
            housingPartial: 0, housingTotal: 0, housingUnsafe: 0, housingEstimate: 0,
            infraRoads: false, infraRoadsAmt: 0,
            infraBridges: false, infraBridgesAmt: 0,
            infraSchools: false, infraSchoolsAmt: 0,
            infraHealth: false, infraHealthAmt: 0,
            infraGov: false, infraGovAmt: 0,
            infraWater: false, infraWaterAmt: 0,
            infraPower: false, infraPowerAmt: 0,
            infraComms: false, infraCommsAmt: 0,
            infraDrainage: false, infraDrainageAmt: 0,
            needFood: false, needWater: false, needShelter: false, needMedicine: false,
            needRescue: false, needSanitation: false, needPsycho: false, needLivelihood: false,
            needRoadClearing: false, needPowerRestoration: false,
            totalDamage: 0
        }"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
        @click.self="showCreateAssessment = false">
        <div class="bg-white rounded-2xl shadow-float w-full max-w-2xl max-h-[90vh] overflow-y-auto p-6">

            <div class="flex items-center justify-between mb-5">
                <div>
                    <h3 class="text-base font-bold text-navy-900">New Damage Assessment</h3>
                    <p class="text-xs text-slate-500 mt-0.5">Complete all sections. Save as draft or submit directly.</p>
                </div>
                <button @click="showCreateAssessment = false" class="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                    <i data-lucide="x" class="w-4 h-4 text-slate-500"></i>
                </button>
            </div>

            <div class="space-y-5">

                {{-- Section 1: Basic Info --}}
                <details open class="group">
                    <summary class="flex items-center justify-between cursor-pointer list-none py-2.5 border-b border-slate-100">
                        <span class="text-sm font-semibold text-navy-900 flex items-center gap-2">
                            <span class="w-5 h-5 bg-brand-blue text-white rounded-full text-xs flex items-center justify-center font-bold">1</span>
                            Basic Information
                        </span>
                        <i data-lucide="chevron-down" class="w-4 h-4 text-slate-400 group-open:rotate-180 transition-transform"></i>
                    </summary>
                    <div class="pt-4 grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div class="sm:col-span-2">
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Assessment Type</label>
                            <select x-model="newType" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
                                <option value="">Select type…</option>
                                <option>Initial Rapid Assessment</option>
                                <option>Barangay Damage Assessment</option>
                                <option>Infrastructure Assessment</option>
                                <option>Housing Assessment</option>
                                <option>Agriculture Assessment</option>
                                <option>Livelihood Assessment</option>
                                <option>Evacuation Center Assessment</option>
                                <option>Post-Disaster Needs Assessment</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Incident</label>
                            <select x-model="newIncident" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
                                <option value="">Select incident…</option>
                                @foreach($incidents as $incident)
                                <option value="{{ $incident['id'] }}">{{ $incident['id'] }} — {{ $incident['type'] }} ({{ $incident['barangay'] }})</option>
                                @endforeach
                            </select>
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Barangay</label>
                            <select x-model="newBarangay" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
                                <option value="">Select barangay…</option>
                                @foreach($barangays as $brgy)
                                <option value="{{ $brgy }}">{{ $brgy }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Assessment Date</label>
                            <input type="date" x-model="newDate" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Assessor Name</label>
                            <input type="text" x-model="newAssessor" placeholder="Full name" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                        <div class="sm:col-span-2">
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Office / Designation</label>
                            <input type="text" x-model="newOffice" placeholder="e.g. Barangay DRRM Officer" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                    </div>
                </details>

                {{-- Section 2: Affected Population --}}
                <details open class="group">
                    <summary class="flex items-center justify-between cursor-pointer list-none py-2.5 border-b border-slate-100">
                        <span class="text-sm font-semibold text-navy-900 flex items-center gap-2">
                            <span class="w-5 h-5 bg-brand-blue text-white rounded-full text-xs flex items-center justify-center font-bold">2</span>
                            Affected Population
                        </span>
                        <i data-lucide="chevron-down" class="w-4 h-4 text-slate-400 group-open:rotate-180 transition-transform"></i>
                    </summary>
                    <div class="pt-4 grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                        @foreach([
                            ['popAffected',  'Affected Families'],
                            ['popDisplaced', 'Displaced Families'],
                            ['popInjured',   'Injured'],
                            ['popMissing',   'Missing'],
                            ['popDeceased',  'Deceased'],
                            ['popRescued',   'Rescued'],
                            ['popEvacuated', 'Evacuated'],
                        ] as [$model, $label])
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">{{ $label }}</label>
                            <input type="number" min="0" x-model="{{ $model }}" placeholder="0" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                        @endforeach
                    </div>
                </details>

                {{-- Section 3: Housing Damage --}}
                <details class="group">
                    <summary class="flex items-center justify-between cursor-pointer list-none py-2.5 border-b border-slate-100">
                        <span class="text-sm font-semibold text-navy-900 flex items-center gap-2">
                            <span class="w-5 h-5 bg-brand-blue text-white rounded-full text-xs flex items-center justify-center font-bold">3</span>
                            Housing Damage
                        </span>
                        <i data-lucide="chevron-down" class="w-4 h-4 text-slate-400 group-open:rotate-180 transition-transform"></i>
                    </summary>
                    <div class="pt-4 grid grid-cols-2 sm:grid-cols-4 gap-3">
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Partially Damaged</label>
                            <input type="number" min="0" x-model="housingPartial" placeholder="0" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Totally Damaged</label>
                            <input type="number" min="0" x-model="housingTotal" placeholder="0" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Unsafe for Occupancy</label>
                            <input type="number" min="0" x-model="housingUnsafe" placeholder="0" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Est. Housing Damage (₱)</label>
                            <input type="number" min="0" x-model="housingEstimate" placeholder="0" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                    </div>
                </details>

                {{-- Section 4: Infrastructure Damage --}}
                <details class="group">
                    <summary class="flex items-center justify-between cursor-pointer list-none py-2.5 border-b border-slate-100">
                        <span class="text-sm font-semibold text-navy-900 flex items-center gap-2">
                            <span class="w-5 h-5 bg-brand-blue text-white rounded-full text-xs flex items-center justify-center font-bold">4</span>
                            Infrastructure Damage
                        </span>
                        <i data-lucide="chevron-down" class="w-4 h-4 text-slate-400 group-open:rotate-180 transition-transform"></i>
                    </summary>
                    <div class="pt-4 space-y-2">
                        @foreach([
                            ['infraRoads',    'infraRoadsAmt',    'Roads'],
                            ['infraBridges',  'infraBridgesAmt',  'Bridges'],
                            ['infraSchools',  'infraSchoolsAmt',  'Schools'],
                            ['infraHealth',   'infraHealthAmt',   'Health Facilities'],
                            ['infraGov',      'infraGovAmt',      'Government Buildings'],
                            ['infraWater',    'infraWaterAmt',    'Water System'],
                            ['infraPower',    'infraPowerAmt',    'Power'],
                            ['infraComms',    'infraCommsAmt',    'Communications'],
                            ['infraDrainage', 'infraDrainageAmt', 'Drainage'],
                        ] as [$check, $amt, $label])
                        <div class="flex items-center gap-3 py-2 border-b border-slate-50 last:border-0">
                            <label class="flex items-center gap-2 w-44 flex-shrink-0 cursor-pointer">
                                <input type="checkbox" x-model="{{ $check }}" class="rounded text-brand-blue">
                                <span class="text-sm text-slate-700">{{ $label }}</span>
                            </label>
                            <div x-show="{{ $check }}" x-cloak class="flex-1">
                                <div class="relative">
                                    <span class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-sm">₱</span>
                                    <input type="number" min="0" x-model="{{ $amt }}" placeholder="0" class="w-full pl-7 pr-3 py-1.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                                </div>
                            </div>
                            <div x-show="!{{ $check }}" class="flex-1 text-xs text-slate-400">Check to enter damage amount</div>
                        </div>
                        @endforeach
                    </div>
                </details>

                {{-- Section 5: Immediate Needs --}}
                <details class="group">
                    <summary class="flex items-center justify-between cursor-pointer list-none py-2.5 border-b border-slate-100">
                        <span class="text-sm font-semibold text-navy-900 flex items-center gap-2">
                            <span class="w-5 h-5 bg-brand-blue text-white rounded-full text-xs flex items-center justify-center font-bold">5</span>
                            Immediate Needs
                        </span>
                        <i data-lucide="chevron-down" class="w-4 h-4 text-slate-400 group-open:rotate-180 transition-transform"></i>
                    </summary>
                    <div class="pt-4 grid grid-cols-2 sm:grid-cols-3 gap-2">
                        @foreach([
                            ['needFood',             'Food'],
                            ['needWater',            'Water'],
                            ['needShelter',          'Shelter'],
                            ['needMedicine',         'Medicine'],
                            ['needRescue',           'Rescue'],
                            ['needSanitation',       'Sanitation'],
                            ['needPsycho',           'Psychosocial Support'],
                            ['needLivelihood',       'Livelihood Assistance'],
                            ['needRoadClearing',     'Road Clearing'],
                            ['needPowerRestoration', 'Power Restoration'],
                        ] as [$model, $label])
                        <label
                            :class="{{ $model }} ? 'bg-emerald-50 border-emerald-200' : 'bg-white border-slate-100'"
                            class="flex items-center gap-2.5 px-3 py-2.5 rounded-xl border cursor-pointer transition-colors">
                            <input type="checkbox" x-model="{{ $model }}" class="rounded text-emerald-600">
                            <span class="text-sm text-slate-700">{{ $label }}</span>
                        </label>
                        @endforeach
                    </div>
                </details>

                {{-- Section 6: Total Financial Damage --}}
                <div class="bg-rose-50 rounded-xl p-4 border border-rose-100">
                    <label class="block text-sm font-semibold text-rose-800 mb-1.5">
                        <span class="w-5 h-5 bg-rose-500 text-white rounded-full text-xs inline-flex items-center justify-center font-bold mr-1.5">6</span>
                        Estimated Total Financial Damage (₱)
                    </label>
                    <div class="relative">
                        <span class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 font-semibold">₱</span>
                        <input
                            type="number"
                            min="0"
                            x-model="totalDamage"
                            placeholder="0"
                            class="w-full pl-8 pr-3 py-2.5 rounded-xl border border-rose-200 text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-rose-400/30 bg-white text-rose-900">
                    </div>
                    <p class="text-xs text-rose-600 mt-1.5">Auto-sum hint: sum of housing + infrastructure + agriculture estimates entered above.</p>
                </div>

            </div>

            {{-- Modal Footer --}}
            <div class="flex flex-wrap items-center gap-2 mt-6 pt-4 border-t border-slate-100">
                <button @click="showCreateAssessment = false" class="px-4 py-2 rounded-xl border border-slate-200 text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors">Cancel</button>
                <button
                    @click="$dispatch('toast', { message: 'Assessment draft saved. You can continue editing later.', variant: 'info' })"
                    class="px-4 py-2 bg-slate-100 text-slate-700 rounded-xl text-sm font-semibold hover:bg-slate-200 transition-colors">
                    <i data-lucide="save" class="w-4 h-4 inline-block mr-1"></i>
                    Save as Draft
                </button>
                <button
                    @click="$dispatch('toast', { message: 'Assessment submitted for validation.', variant: 'success' }); showCreateAssessment = false"
                    class="px-5 py-2 bg-brand-blue text-white rounded-xl text-sm font-semibold hover:bg-brand-blue/90 transition-colors shadow-sm ml-auto">
                    <i data-lucide="send" class="w-4 h-4 inline-block mr-1"></i>
                    Submit for Validation
                </button>
            </div>

        </div>
    </div>

</div>

@once
<script>
document.addEventListener('DOMContentLoaded', function () {
    window.renderIcons?.();
});
</script>
@endonce
