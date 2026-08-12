@php
    $data            = config('esperanza_constituents');
    $individuals     = $data['individuals'];
    $families        = $data['families'];
    $households      = $data['households'];
    $barangayCoverage= $data['barangayCoverage'];
    $qualityIssues   = $data['dataQualityIssues'];
    $municipalStats  = $data['municipalStats'];
    $barangayStats   = $data['barangayStats'];
    $barangayOptions = config('esperanza.barangays');
    $tab  = $tab  ?? 'registry';
    $view = $view ?? 'individuals';
@endphp

<x-layouts.admin title="Constituents" subtitle="LGU constituent registry — residents, families, households." active="constituents">
<div
    x-data="{
        tab:  '{{ $tab }}',
        view: '{{ $view }}',
        individuals:    @js($individuals),
        families:       @js($families),
        households:     @js($households),
        qualityIssues:  @js($qualityIssues),
        municipalStats: @js($municipalStats),
        barangayStats:  @js($barangayStats),
        search:             '',
        barangayFilter:     '',
        verificationFilter: '',
        statusFilter:       '',
        tagFilter:          '',
        dqTypeFilter:       '',
        dqStatusFilter:     '',
        sortField: 'name',
        sortDir:   'asc',
        showIndividualDetail: false,
        showAddIndividual:    false,
        showFamilyDetail:     false,
        showAddFamily:        false,
        showHouseholdDetail:  false,
        showAddHousehold:     false,
        showLifecycle:        false,
        showMerge:            false,
        showAdvancedFilters:  false,
        showDQDetail:         false,
        showAddMenu:          false,
        selectedIndividual:   null,
        selectedFamily:       null,
        selectedHousehold:    null,
        selectedDQIssue:      null,
        lifecycleAction:      '',
        addIndividualStep: 1,
        addFamilyStep:     1,
        addHouseholdStep:  1,
        individualTab: 'overview',
        familyTab:     'overview',
        householdTab:  'overview',
        get activeStats() {
            const s = this.$store.session.account?.scope;
            return (!s || s === 'Municipal') ? this.municipalStats : (this.barangayStats[s] ?? this.municipalStats);
        },
        get isMunicipalScope() {
            const s = this.$store.session.account?.scope;
            return !s || s === 'Municipal';
        },
        get filteredIndividuals() {
            let list = this.individuals.filter(r => {
                if (!this.$store.session.inScope(r.barangay)) return false;
                if (this.barangayFilter && r.barangay !== this.barangayFilter) return false;
                if (this.verificationFilter && r.verification !== this.verificationFilter) return false;
                if (this.tagFilter && !(r.tags||[]).includes(this.tagFilter)) return false;
                if (this.search) {
                    const q = this.search.toLowerCase();
                    return (r.name||'').toLowerCase().includes(q)||(r.id||'').toLowerCase().includes(q)||(r.barangay||'').toLowerCase().includes(q)||(r.occupation||'').toLowerCase().includes(q)||(r.contact||'').includes(q);
                }
                return true;
            });
            if (this.sortField) {
                list = [...list].sort((a,b) => this.sortDir==='asc' ? String(a[this.sortField]??'').localeCompare(String(b[this.sortField]??'')) : String(b[this.sortField]??'').localeCompare(String(a[this.sortField]??'')));
            }
            return list;
        },
        get filteredFamilies() {
            return this.families.filter(f => {
                if (!this.$store.session.inScope(f.barangay)) return false;
                if (this.barangayFilter && f.barangay !== this.barangayFilter) return false;
                if (this.search) { const q=this.search.toLowerCase(); return (f.label||'').toLowerCase().includes(q)||(f.head_name||'').toLowerCase().includes(q)||(f.id||'').toLowerCase().includes(q); }
                return true;
            });
        },
        get filteredHouseholds() {
            return this.households.filter(h => {
                if (!this.$store.session.inScope(h.barangay)) return false;
                if (this.barangayFilter && h.barangay !== this.barangayFilter) return false;
                if (this.search) { const q=this.search.toLowerCase(); return (h.label||'').toLowerCase().includes(q)||(h.head_name||'').toLowerCase().includes(q)||(h.id||'').toLowerCase().includes(q); }
                return true;
            });
        },
        get filteredQualityIssues() {
            return this.qualityIssues.filter(i => {
                if (!this.$store.session.inScope(i.barangay)) return false;
                if (this.dqTypeFilter && i.type !== this.dqTypeFilter) return false;
                if (this.dqStatusFilter && i.status !== this.dqStatusFilter) return false;
                if (this.search) { const q=this.search.toLowerCase(); return (i.record_name||'').toLowerCase().includes(q)||(i.description||'').toLowerCase().includes(q)||(i.barangay||'').toLowerCase().includes(q); }
                return true;
            });
        },
        openIndividual(r) { this.selectedIndividual=r; this.individualTab='overview'; this.showIndividualDetail=true; this.$nextTick(()=>window.renderIcons?.()); },
        openFamily(f)     { this.selectedFamily=f;     this.familyTab='overview';     this.showFamilyDetail=true;     this.$nextTick(()=>window.renderIcons?.()); },
        openHousehold(h)  { this.selectedHousehold=h;  this.householdTab='overview';  this.showHouseholdDetail=true;  this.$nextTick(()=>window.renderIcons?.()); },
        openLifecycle(r, action) { this.selectedIndividual=r; this.lifecycleAction=action; this.showLifecycle=true; this.$nextTick(()=>window.renderIcons?.()); },
        openDQIssue(issue)       { this.selectedDQIssue=issue; this.showDQDetail=true; this.$nextTick(()=>window.renderIcons?.()); },
        verificationBadge(v) {
            const m={'Verified':'text-emerald-700 bg-emerald-50 ring-1 ring-emerald-200','Partially Verified':'text-amber-700 bg-amber-50 ring-1 ring-amber-200','For Validation':'text-indigo-700 bg-indigo-50 ring-1 ring-indigo-200','Missing Documents':'text-orange-700 bg-orange-50 ring-1 ring-orange-200','Unverified':'text-slate-500 bg-slate-100 ring-1 ring-slate-200','Rejected':'text-rose-700 bg-rose-50 ring-1 ring-rose-200'};
            return m[v]||m['Unverified'];
        },
        statusBadge(s) {
            const m={'Active':'text-emerald-700 bg-emerald-50','New Resident':'text-brand-700 bg-brand-50','Transferred':'text-indigo-700 bg-indigo-50','Temporarily Away':'text-amber-700 bg-amber-50','Overseas':'text-teal-700 bg-teal-50','Deceased':'text-slate-500 bg-slate-100','Archived':'text-slate-400 bg-slate-50','Under Review':'text-purple-700 bg-purple-50'};
            return m[s]||m['Active'];
        },
        severityBadge(s) {
            const m={'Critical':'text-rose-700 bg-rose-50 ring-1 ring-rose-200','High':'text-orange-700 bg-orange-50 ring-1 ring-orange-200','Medium':'text-amber-700 bg-amber-50 ring-1 ring-amber-200','Low':'text-slate-600 bg-slate-100 ring-1 ring-slate-200'};
            return m[s]||m['Low'];
        },
        completionColor(pct) { return pct>=90?'bg-emerald-500':pct>=70?'bg-amber-500':'bg-rose-500'; },
        completionTextColor(pct) { return pct>=90?'text-emerald-700':pct>=70?'text-amber-700':'text-rose-700'; },
        exportCSV(rows, filename) {
            if (!rows.length) { this.$dispatch('toast',{message:'No records to export.',variant:'warning'}); return; }
            const keys=Object.keys(rows[0]).filter(k=>!['services','emergency','member_ids','family_ids'].includes(k));
            const csv=[keys.join(','),...rows.map(r=>keys.map(k=>JSON.stringify(r[k]??'')).join(','))].join('\n');
            const a=Object.assign(document.createElement('a'),{href:URL.createObjectURL(new Blob([csv],{type:'text/csv'})),download:filename});
            a.click(); this.$dispatch('toast',{message:'Exported successfully.',variant:'success'});
        },
        can(sub,perm) { return this.$store.session.canPerm?this.$store.session.canPerm(sub,perm):true; },
        clearFilters() { this.search='';this.barangayFilter='';this.verificationFilter='';this.statusFilter='';this.tagFilter='';this.dqTypeFilter='';this.dqStatusFilter=''; },
    }"
    class="animate-fade-up"
>

    <div x-show="!$store.session.can('constituents')" x-cloak>
        <x-admin.access-restricted module="Constituent Management" icon="users" />
    </div>

    <div x-show="$store.session.can('constituents')" x-cloak>

        {{-- Scope banner --}}
        <div x-show="$store.session.account && $store.session.account.scope !== 'Municipal'" x-cloak
             class="flex items-center gap-2.5 rounded-xl bg-purple-50 border border-purple-100 px-3.5 py-2.5 mb-4">
            <i data-lucide="map-pin" class="w-4 h-4 text-purple-500 shrink-0"></i>
            <p class="text-xs text-purple-700">Barangay-scoped access — data outside <strong x-text="'Brgy. '+$store.session.account?.scope"></strong> is hidden.</p>
        </div>

        {{-- Page header --}}
        <div class="flex flex-wrap items-start justify-between gap-3 mb-5">
            <div>
                <h1 class="text-lg font-bold text-navy-900">Constituent Registry</h1>
                <p class="text-xs text-slate-400 mt-0.5">Municipality of Esperanza · 20 barangays · <span x-text="isMunicipalScope?'Municipality-wide view':'Brgy. '+$store.session.account?.scope+' view'"></span></p>
            </div>
            <div class="flex items-center gap-2 relative">
                <button @click="showAddMenu=!showAddMenu" @click.outside="showAddMenu=false"
                        class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold bg-brand-600 text-white hover:bg-brand-700 shadow-sm shadow-brand-200 transition-all">
                    <i data-lucide="plus" class="w-3.5 h-3.5"></i>Add Record
                    <i data-lucide="chevron-down" class="w-3 h-3 opacity-70 transition-transform" :class="showAddMenu&&'rotate-180'"></i>
                </button>
                <div x-show="showAddMenu" x-transition.origin.top.right x-cloak
                     class="absolute right-0 top-full mt-1.5 w-44 bg-white rounded-xl border border-slate-200 shadow-lg z-30 overflow-hidden">
                    <button @click="addIndividualStep=1;showAddIndividual=true;showAddMenu=false;$nextTick(()=>window.renderIcons?.())"
                            class="w-full text-left px-4 py-2.5 text-xs text-slate-700 hover:bg-slate-50 flex items-center gap-2.5">
                        <i data-lucide="user-plus" class="w-3.5 h-3.5 text-brand-500"></i>New Resident
                    </button>
                    <button @click="addFamilyStep=1;showAddFamily=true;showAddMenu=false;$nextTick(()=>window.renderIcons?.())"
                            class="w-full text-left px-4 py-2.5 text-xs text-slate-700 hover:bg-slate-50 flex items-center gap-2.5">
                        <i data-lucide="users-round" class="w-3.5 h-3.5 text-purple-500"></i>New Family
                    </button>
                    <button @click="addHouseholdStep=1;showAddHousehold=true;showAddMenu=false;$nextTick(()=>window.renderIcons?.())"
                            class="w-full text-left px-4 py-2.5 text-xs text-slate-700 hover:bg-slate-50 flex items-center gap-2.5">
                        <i data-lucide="house" class="w-3.5 h-3.5 text-emerald-500"></i>New Household
                    </button>
                </div>
            </div>
        </div>

        {{-- Summary cards --}}
        <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 mb-5">
            <x-ui.stat-card @click="tab='registry';view='individuals';clearFilters()" class="cursor-pointer" label="Registered Residents" valueBind="activeStats.residents"  icon="users"          color="brand"  :delay="0"   />
            <x-ui.stat-card @click="tab='registry';view='households';clearFilters()" class="cursor-pointer" label="Active Households"    valueBind="activeStats.households" icon="house"           color="green"  :delay="40"  />
            <x-ui.stat-card @click="tab='registry';view='families';clearFilters()" class="cursor-pointer" label="Recorded Families"    valueBind="activeStats.families"   icon="users-round"    color="purple" :delay="80"  />
            <x-ui.stat-card @click="tab='registry';view='individuals';clearFilters();verificationFilter='Verified'" class="cursor-pointer" label="ID Verified"          valueBind="activeStats.verified"   icon="badge-check"    color="gold"   :delay="120" />
            <x-ui.stat-card @click="tab='registry';view='individuals';clearFilters();verificationFilter='For Validation'" class="cursor-pointer" label="Pending Validation"   valueBind="activeStats.pending"    icon="clock"          color="orange" :delay="160" />
            <x-ui.stat-card @click="tab='data-quality';clearFilters()" class="cursor-pointer" label="Data Quality Issues"  valueBind="activeStats.issues"     icon="triangle-alert" color="red"    :delay="200" sublabel="Needs attention" />
        </div>

        {{-- Primary tab bar --}}
        <div class="flex items-center gap-1.5 bg-white border border-slate-200 rounded-xl p-1 shadow-card w-fit mb-5">
            <button @click="tab='registry';clearFilters()"
                    class="px-3.5 py-1.5 text-xs font-medium rounded-lg transition-colors flex items-center gap-1.5"
                    :class="tab==='registry'     ? 'bg-brand-600 text-white shadow-sm' : 'text-slate-500 hover:bg-slate-50'">
                <i data-lucide="users" class="w-3.5 h-3.5"></i>Registry
            </button>
            <button @click="tab='profiling';clearFilters()"
                    class="px-3.5 py-1.5 text-xs font-medium rounded-lg transition-colors flex items-center gap-1.5"
                    :class="tab==='profiling'    ? 'bg-brand-600 text-white shadow-sm' : 'text-slate-500 hover:bg-slate-50'">
                <i data-lucide="user-round-search" class="w-3.5 h-3.5"></i>Profiling Coverage
            </button>
            <button @click="tab='data-quality';clearFilters()"
                    class="px-3.5 py-1.5 text-xs font-medium rounded-lg transition-colors flex items-center gap-1.5 relative"
                    :class="tab==='data-quality' ? 'bg-brand-600 text-white shadow-sm' : 'text-slate-500 hover:bg-slate-50'">
                <i data-lucide="triangle-alert" class="w-3.5 h-3.5"></i>Data Quality
                <span class="text-[10px] font-bold px-1.5 py-0.5 rounded-full"
                      :class="tab==='data-quality' ? 'bg-white/25 text-white' : 'bg-rose-100 text-rose-600'">{{ count($qualityIssues) }}</span>
            </button>
        </div>

        {{-- ── Registry tab ────────────────────────────────────────── --}}
        <div x-show="tab === 'registry'">
            {{-- Unified toolbar: view switcher on top, search/filters/actions below --}}
            <div class="bg-white border border-slate-200 rounded-2xl shadow-card p-3 mb-4 space-y-3">
                <div class="flex items-center gap-1.5 bg-slate-100/70 rounded-xl p-1 w-fit overflow-x-auto">
                    <button @click="view='individuals';clearFilters()"
                            class="px-3.5 py-1.5 text-xs font-medium rounded-lg transition-colors flex items-center gap-1.5 whitespace-nowrap"
                            :class="view==='individuals' ? 'bg-white text-navy-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'">
                        <i data-lucide="user" class="w-3.5 h-3.5"></i>Individuals
                        <span class="text-[10px] font-semibold px-1.5 py-0.5 rounded-full bg-slate-200 text-slate-600" x-text="filteredIndividuals.length"></span>
                    </button>
                    <button @click="view='families';clearFilters()"
                            class="px-3.5 py-1.5 text-xs font-medium rounded-lg transition-colors flex items-center gap-1.5 whitespace-nowrap"
                            :class="view==='families'    ? 'bg-white text-navy-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'">
                        <i data-lucide="users-round" class="w-3.5 h-3.5"></i>Families
                        <span class="text-[10px] font-semibold px-1.5 py-0.5 rounded-full bg-slate-200 text-slate-600" x-text="filteredFamilies.length"></span>
                    </button>
                    <button @click="view='households';clearFilters()"
                            class="px-3.5 py-1.5 text-xs font-medium rounded-lg transition-colors flex items-center gap-1.5 whitespace-nowrap"
                            :class="view==='households'  ? 'bg-white text-navy-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'">
                        <i data-lucide="house" class="w-3.5 h-3.5"></i>Households
                        <span class="text-[10px] font-semibold px-1.5 py-0.5 rounded-full bg-slate-200 text-slate-600" x-text="filteredHouseholds.length"></span>
                    </button>
                </div>

                <div class="flex flex-wrap items-center justify-between gap-3 pt-3 border-t border-slate-100">
                <div class="flex flex-wrap items-center gap-2">
                    <div class="relative">
                        <i data-lucide="search" class="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"></i>
                        <input x-model="search" type="text"
                               :placeholder="view==='individuals'?'Search residents...':view==='families'?'Search families...':'Search households...'"
                               class="w-52 sm:w-64 pl-9 pr-3 py-2 text-xs rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all">
                    </div>
                    <select x-show="isMunicipalScope" x-model="barangayFilter"
                            class="text-xs rounded-xl border border-slate-200 bg-slate-50 py-2 px-3 focus:bg-white focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all">
                        <option value="">All Barangays</option>
                        @foreach($barangayOptions as $b)
                            <option value="{{ $b }}">{{ $b }}</option>
                        @endforeach
                    </select>
                    <span x-show="!isMunicipalScope" x-cloak
                          class="inline-flex items-center gap-1.5 text-xs font-medium text-purple-700 bg-purple-50 border border-purple-100 rounded-xl px-3 py-2">
                        <i data-lucide="lock" class="w-3 h-3"></i>Brgy. <span x-text="$store.session.account?.scope"></span>
                    </span>
                    <div x-show="view==='individuals'" class="flex items-center gap-2">
                        <select x-model="verificationFilter"
                                class="text-xs rounded-xl border border-slate-200 bg-slate-50 py-2 px-3 focus:bg-white focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all">
                            <option value="">All Verification</option>
                            <option>Verified</option>
                            <option>Partially Verified</option>
                            <option>For Validation</option>
                            <option>Unverified</option>
                        </select>
                        <select x-model="tagFilter"
                                class="text-xs rounded-xl border border-slate-200 bg-slate-50 py-2 px-3 focus:bg-white focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all">
                            <option value="">All Tags</option>
                            <option value="senior">Senior Citizen</option>
                            <option value="pwd">PWD</option>
                            <option value="4ps">4Ps Beneficiary</option>
                            <option value="solo_parent">Solo Parent</option>
                            <option value="youth">Youth</option>
                            <option value="child">Child</option>
                            <option value="osy">Out-of-School Youth</option>
                        </select>
                    </div>
                    <button x-show="search||barangayFilter||verificationFilter||tagFilter" @click="clearFilters()"
                            class="text-xs text-slate-500 hover:text-rose-600 flex items-center gap-1 transition-colors">
                        <i data-lucide="circle-x" class="w-3.5 h-3.5"></i>Clear
                    </button>
                </div>
                <div class="flex items-center gap-2">
                    <button @click="exportCSV(view==='individuals'?filteredIndividuals:view==='families'?filteredFamilies:filteredHouseholds,view+'-export.csv')"
                            class="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-medium text-slate-600 bg-slate-50 border border-slate-200 hover:bg-white hover:border-slate-300 transition-all">
                        <i data-lucide="download" class="w-3.5 h-3.5"></i>Export CSV
                    </button>
                    <button onclick="window.print()"
                            class="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-medium text-slate-600 bg-slate-50 border border-slate-200 hover:bg-white hover:border-slate-300 transition-all">
                        <i data-lucide="printer" class="w-3.5 h-3.5"></i>Print
                    </button>
                </div>
                </div>
            </div>

            <div x-show="view==='individuals'">@include('admin.constituents.view-individuals')</div>
            <div x-show="view==='families'"    x-cloak>@include('admin.constituents.view-families')</div>
            <div x-show="view==='households'"  x-cloak>@include('admin.constituents.view-households')</div>
        </div>

        {{-- ── Profiling Coverage tab ──────────────────────────────── --}}
        <div x-show="tab === 'profiling'" x-cloak>
            @include('admin.constituents.tab-profiling')
        </div>

        {{-- ── Data Quality tab ────────────────────────────────────── --}}
        <div x-show="tab === 'data-quality'" x-cloak>
            @include('admin.constituents.tab-data-quality')
        </div>

    </div>

    {{-- ── Modals ──────────────────────────────────────────────────── --}}
    <div x-show="showIndividualDetail" x-cloak>@include('admin.constituents.modal-individual-detail')</div>
    <div x-show="showAddIndividual"    x-cloak>@include('admin.constituents.modal-add-individual')</div>
    <div x-show="showFamilyDetail"     x-cloak>@include('admin.constituents.modal-family-detail')</div>
    <div x-show="showAddFamily"        x-cloak>@include('admin.constituents.modal-add-family')</div>
    <div x-show="showHouseholdDetail"  x-cloak>@include('admin.constituents.modal-household-detail')</div>
    <div x-show="showAddHousehold"     x-cloak>@include('admin.constituents.modal-add-household')</div>
    <div x-show="showLifecycle"        x-cloak>@include('admin.constituents.modal-lifecycle')</div>
    <div x-show="showMerge"            x-cloak>@include('admin.constituents.modal-merge')</div>
    <div x-show="showDQDetail"         x-cloak>@include('admin.constituents.modal-dq-detail')</div>

</div>
</x-layouts.admin>
