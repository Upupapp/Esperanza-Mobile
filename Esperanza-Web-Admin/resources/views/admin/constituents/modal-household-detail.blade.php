{{-- modal-household-detail.blade.php --}}
{{-- Household detail modal — 5 tabs: Overview | Members | Amenities | Programs | History --}}

<div x-data="{
    get open() { return showHouseholdDetail },
    set open(v) { showHouseholdDetail = v }
}">
<x-ui.modal maxWidth="2xl">

    <template x-if="selectedHousehold">
        <div class="flex flex-col h-full max-h-[90vh]">

            {{-- ── Modal Header ── --}}
            <div class="flex-shrink-0 px-6 pt-6 pb-4 border-b border-slate-200">
                <div class="flex items-start justify-between gap-4">
                    <div class="flex items-start gap-4 min-w-0">
                        {{-- Household icon --}}
                        <div class="flex-shrink-0 w-12 h-12 rounded-xl bg-gradient-to-br from-indigo-500 to-violet-600 flex items-center justify-center shadow-md">
                            <i data-lucide="house" class="w-6 h-6 text-white"></i>
                        </div>
                        <div class="min-w-0">
                            <div class="flex items-center flex-wrap gap-2">
                                <h2 class="text-lg font-bold text-navy-900 truncate" x-text="selectedHousehold.label"></h2>
                                {{-- Flood risk chip --}}
                                <span
                                    class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold"
                                    :class="{
                                        'bg-emerald-100 text-emerald-700': selectedHousehold.flood_risk === 'Low',
                                        'bg-amber-100 text-amber-700': selectedHousehold.flood_risk === 'Medium',
                                        'bg-rose-100 text-rose-700': selectedHousehold.flood_risk === 'High'
                                    }"
                                >
                                    <i data-lucide="waves-horizontal" class="w-3 h-3"></i>
                                    <span x-text="(selectedHousehold.flood_risk || 'Unknown') + ' Flood Risk'"></span>
                                </span>
                                {{-- Verification badge --}}
                                <span
                                    class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium"
                                    :class="verificationBadge(selectedHousehold.verification).class"
                                    x-text="verificationBadge(selectedHousehold.verification).label"
                                ></span>
                            </div>
                            <div class="flex items-center flex-wrap gap-x-3 gap-y-1 mt-1">
                                <span class="inline-flex items-center gap-1 text-xs text-slate-500">
                                    <i data-lucide="map-pin" class="w-3 h-3 text-slate-400"></i>
                                    <span x-text="selectedHousehold.barangay"></span>
                                    <template x-if="selectedHousehold.sitio">
                                        <span x-text="' · Sitio ' + selectedHousehold.sitio"></span>
                                    </template>
                                </span>
                                <span class="inline-flex items-center gap-1 text-xs text-slate-500">
                                    <i data-lucide="user" class="w-3 h-3 text-slate-400"></i>
                                    <span x-text="selectedHousehold.head_name || 'No head listed'"></span>
                                </span>
                                <span class="text-xs text-slate-400 font-mono" x-text="'ID: ' + selectedHousehold.id"></span>
                            </div>
                            {{-- Profile completion bar --}}
                            <div class="flex items-center gap-2 mt-2">
                                <div class="flex-1 h-1.5 bg-slate-100 rounded-full overflow-hidden max-w-[180px]">
                                    <div
                                        class="h-full rounded-full transition-all"
                                        :class="completionColor(selectedHousehold.profile_pct)"
                                        :style="'width:' + (selectedHousehold.profile_pct||0) + '%'"
                                    ></div>
                                </div>
                                <span class="text-xs font-semibold" :class="completionTextColor(selectedHousehold.profile_pct)" x-text="(selectedHousehold.profile_pct||0) + '% Complete'"></span>
                            </div>
                        </div>
                    </div>
                    {{-- Close button --}}
                    <button @click="showHouseholdDetail = false" class="flex-shrink-0 p-2 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors">
                        <i data-lucide="x" class="w-5 h-5"></i>
                    </button>
                </div>

                {{-- Tab nav --}}
                <div class="flex gap-1 mt-4 overflow-x-auto">
                    <template x-for="tab in [
                        {id:'overview',icon:'layout-list',label:'Overview'},
                        {id:'members',icon:'users',label:'Members'},
                        {id:'amenities',icon:'plug-zap',label:'Amenities'},
                        {id:'programs',icon:'heart-handshake',label:'Programs'},
                        {id:'history',icon:'clock',label:'History'}
                    ]" :key="tab.id">
                        <button
                            @click="householdTab = tab.id"
                            class="inline-flex items-center gap-1.5 px-3 py-2 text-sm font-medium rounded-t-lg border-b-2 transition-colors whitespace-nowrap"
                            :class="householdTab === tab.id
                                ? 'text-indigo-600 border-indigo-600 bg-indigo-50/50'
                                : 'text-slate-500 border-transparent hover:text-slate-700 hover:border-slate-300'"
                        >
                            <i :data-lucide="tab.icon" class="w-3.5 h-3.5"></i>
                            <span x-text="tab.label"></span>
                            <template x-if="tab.id === 'members'">
                                <span class="ml-0.5 px-1.5 py-0.5 rounded-full text-xs font-semibold bg-slate-100 text-slate-600" x-text="selectedHousehold.member_count"></span>
                            </template>
                        </button>
                    </template>
                </div>
            </div>

            {{-- ── Tab Content (scrollable) ── --}}
            <div class="flex-1 overflow-y-auto px-6 py-5 space-y-4">

                {{-- ── OVERVIEW TAB ── --}}
                <div x-show="householdTab === 'overview'" x-cloak>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        {{-- Left column --}}
                        <x-ui.card class="p-4">
                            <h4 class="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">Location & Identification</h4>
                            <dl class="space-y-2.5">
                                <div class="flex justify-between items-start gap-2">
                                    <dt class="text-xs text-slate-500 flex items-center gap-1.5 flex-shrink-0"><i data-lucide="locate" class="w-3.5 h-3.5 text-slate-400"></i> Address</dt>
                                    <dd class="text-xs font-semibold text-navy-900 text-right" x-text="selectedHousehold.address || '—'"></dd>
                                </div>
                                <div class="flex justify-between items-start gap-2">
                                    <dt class="text-xs text-slate-500 flex items-center gap-1.5 flex-shrink-0"><i data-lucide="hash" class="w-3.5 h-3.5 text-slate-400"></i> Household ID</dt>
                                    <dd class="text-xs font-mono font-semibold text-navy-900" x-text="selectedHousehold.id"></dd>
                                </div>
                                <div class="flex justify-between items-start gap-2">
                                    <dt class="text-xs text-slate-500 flex items-center gap-1.5 flex-shrink-0"><i data-lucide="map-pin" class="w-3.5 h-3.5 text-slate-400"></i> Barangay</dt>
                                    <dd class="text-xs font-semibold text-navy-900" x-text="selectedHousehold.barangay"></dd>
                                </div>
                                <div class="flex justify-between items-start gap-2">
                                    <dt class="text-xs text-slate-500 flex items-center gap-1.5 flex-shrink-0"><i data-lucide="milestone" class="w-3.5 h-3.5 text-slate-400"></i> Sitio / Purok</dt>
                                    <dd class="text-xs font-semibold text-navy-900" x-text="selectedHousehold.sitio || '—'"></dd>
                                </div>
                                <div class="flex justify-between items-start gap-2">
                                    <dt class="text-xs text-slate-500 flex items-center gap-1.5 flex-shrink-0"><i data-lucide="user" class="w-3.5 h-3.5 text-slate-400"></i> Head of Household</dt>
                                    <dd class="text-xs font-semibold text-navy-900" x-text="selectedHousehold.head_name || '—'"></dd>
                                </div>
                                <div class="flex justify-between items-center gap-2">
                                    <dt class="text-xs text-slate-500 flex items-center gap-1.5 flex-shrink-0"><i data-lucide="users" class="w-3.5 h-3.5 text-slate-400"></i> Total Members</dt>
                                    <dd class="text-xs font-bold text-navy-900" x-text="selectedHousehold.member_count"></dd>
                                </div>
                                <div class="flex justify-between items-center gap-2">
                                    <dt class="text-xs text-slate-500 flex items-center gap-1.5 flex-shrink-0"><i data-lucide="users-round" class="w-3.5 h-3.5 text-slate-400"></i> Family Count</dt>
                                    <dd class="text-xs font-bold text-navy-900" x-text="selectedHousehold.family_count"></dd>
                                </div>
                            </dl>
                        </x-ui.card>

                        {{-- Right column --}}
                        <div class="space-y-3">
                            <x-ui.card class="p-4">
                                <h4 class="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">Dwelling & Tenure</h4>
                                <dl class="space-y-2.5">
                                    <div class="flex justify-between items-start gap-2">
                                        <dt class="text-xs text-slate-500 flex items-center gap-1.5"><i data-lucide="building-2" class="w-3.5 h-3.5 text-slate-400"></i> Dwelling Type</dt>
                                        <dd class="text-xs font-semibold text-navy-900" x-text="selectedHousehold.dwelling_type || '—'"></dd>
                                    </div>
                                    <div class="flex justify-between items-start gap-2">
                                        <dt class="text-xs text-slate-500 flex items-center gap-1.5"><i data-lucide="key" class="w-3.5 h-3.5 text-slate-400"></i> Housing Tenure</dt>
                                        <dd class="text-xs font-semibold text-navy-900" x-text="selectedHousehold.housing_tenure || '—'"></dd>
                                    </div>
                                    <div class="flex justify-between items-center gap-2">
                                        <dt class="text-xs text-slate-500 flex items-center gap-1.5"><i data-lucide="waves-horizontal" class="w-3.5 h-3.5 text-slate-400"></i> Flood Risk</dt>
                                        <dd>
                                            <span
                                                class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold"
                                                :class="{
                                                    'bg-emerald-100 text-emerald-700': selectedHousehold.flood_risk === 'Low',
                                                    'bg-amber-100 text-amber-700': selectedHousehold.flood_risk === 'Medium',
                                                    'bg-rose-100 text-rose-700': selectedHousehold.flood_risk === 'High'
                                                }"
                                                x-text="selectedHousehold.flood_risk || '—'"
                                            ></span>
                                        </dd>
                                    </div>
                                    <div class="flex justify-between items-start gap-2">
                                        <dt class="text-xs text-slate-500 flex items-center gap-1.5"><i data-lucide="triangle-alert" class="w-3.5 h-3.5 text-slate-400"></i> Hazard Zone</dt>
                                        <dd class="text-xs font-semibold text-navy-900 text-right" x-text="selectedHousehold.hazard_zone || '—'"></dd>
                                    </div>
                                </dl>
                            </x-ui.card>

                            <x-ui.card class="p-4">
                                <h4 class="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">Tags</h4>
                                <div class="flex flex-wrap gap-1.5">
                                    <template x-if="!selectedHousehold.tags || selectedHousehold.tags.length === 0">
                                        <span class="text-xs text-slate-400 italic">No tags assigned</span>
                                    </template>
                                    <template x-for="tag in (selectedHousehold.tags || [])" :key="tag">
                                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-600" x-text="tag"></span>
                                    </template>
                                </div>
                            </x-ui.card>

                            <x-ui.card class="p-4">
                                <dl class="space-y-1.5">
                                    <div class="flex justify-between items-center gap-2">
                                        <dt class="text-xs text-slate-500">Record Status</dt>
                                        <dd>
                                            <x-ui.badge :status="''" x-bind:data-status="selectedHousehold.status" />
                                        </dd>
                                    </div>
                                    <div class="flex justify-between items-start gap-2">
                                        <dt class="text-xs text-slate-500">Profile Completion</dt>
                                        <dd class="text-xs font-bold" :class="completionTextColor(selectedHousehold.profile_pct)" x-text="(selectedHousehold.profile_pct||0) + '%'"></dd>
                                    </div>
                                    <div class="flex justify-between items-start gap-2">
                                        <dt class="text-xs text-slate-500">Registered</dt>
                                        <dd class="text-xs text-slate-600" x-text="selectedHousehold.created || '—'"></dd>
                                    </div>
                                    <div class="flex justify-between items-start gap-2">
                                        <dt class="text-xs text-slate-500">Last Updated</dt>
                                        <dd class="text-xs text-slate-600" x-text="selectedHousehold.last_updated || '—'"></dd>
                                    </div>
                                </dl>
                            </x-ui.card>
                        </div>
                    </div>
                </div>

                {{-- ── MEMBERS TAB ── --}}
                <div x-show="householdTab === 'members'" x-cloak>
                    <div class="flex items-center justify-between mb-3">
                        <h3 class="text-sm font-semibold text-navy-900">
                            All Household Members
                            <span
                                class="ml-1.5 px-2 py-0.5 rounded-full text-xs bg-indigo-100 text-indigo-700 font-semibold"
                                x-text="individuals.filter(r => r.household_id === selectedHousehold?.id).length"
                            ></span>
                        </h3>
                    </div>

                    <x-ui.card class="overflow-hidden">
                        <template x-if="individuals.filter(r => r.household_id === selectedHousehold?.id).length === 0">
                            <div class="py-10 text-center">
                                <div class="flex flex-col items-center gap-2">
                                    <i data-lucide="user-x" class="w-8 h-8 text-slate-300"></i>
                                    <p class="text-sm text-slate-400">No individuals linked to this household.</p>
                                </div>
                            </div>
                        </template>

                        <ul class="divide-y divide-slate-100">
                            <template x-for="r in individuals.filter(r => r.household_id === selectedHousehold?.id)" :key="r.id">
                                <li
                                    class="flex items-center gap-3 px-4 py-3 hover:bg-indigo-50/40 cursor-pointer transition-colors"
                                    @click="openIndividual(r)"
                                >
                                    <div class="w-8 h-8 text-xs rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold ring-2 ring-white shadow-sm shrink-0" x-text="(r.name || '').split(/\s+/).filter(Boolean).map(w => w[0]).slice(0,2).join('').toUpperCase()"></div>
                                    <div class="flex-1 min-w-0">
                                        <p class="text-sm font-semibold text-navy-900 truncate" x-text="r.name"></p>
                                        <div class="flex items-center gap-2 mt-0.5">
                                            <span class="text-xs text-slate-400" x-text="r.age ? (r.age + ' yrs') : ''"></span>
                                            <template x-if="r.sex"><span class="text-xs text-slate-400" x-text="'· ' + r.sex"></span></template>
                                            <template x-if="r.relation"><span class="text-xs text-slate-500 font-medium" x-text="'· ' + r.relation"></span></template>
                                        </div>
                                    </div>
                                    {{-- Family label --}}
                                    <template x-if="r.family_label">
                                        <span class="text-xs text-slate-500 bg-slate-100 px-2 py-0.5 rounded-full hidden sm:inline-flex" x-text="r.family_label"></span>
                                    </template>
                                    {{-- Verification --}}
                                    <span
                                        class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium flex-shrink-0"
                                        :class="verificationBadge(r.verification).class"
                                        x-text="verificationBadge(r.verification).label"
                                    ></span>
                                    <i data-lucide="chevron-right" class="w-4 h-4 text-slate-300 flex-shrink-0"></i>
                                </li>
                            </template>
                        </ul>
                    </x-ui.card>
                </div>

                {{-- ── AMENITIES TAB ── --}}
                <div x-show="householdTab === 'amenities'" x-cloak>
                    <h3 class="text-sm font-semibold text-navy-900 mb-4">Household Amenities</h3>

                    {{-- 3 amenity cards --}}
                    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
                        {{-- Water --}}
                        <x-ui.card class="p-5 flex flex-col items-center text-center gap-3">
                            <div
                                class="w-16 h-16 rounded-2xl flex items-center justify-center"
                                :class="selectedHousehold.water ? 'bg-blue-100' : 'bg-slate-100'"
                            >
                                <i data-lucide="droplets" class="w-8 h-8" :class="selectedHousehold.water ? 'text-blue-500' : 'text-slate-300'"></i>
                            </div>
                            <div>
                                <p class="text-sm font-semibold text-navy-900">Water Source</p>
                                <span
                                    class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold mt-1.5"
                                    :class="selectedHousehold.water ? 'bg-blue-100 text-blue-700' : 'bg-slate-100 text-slate-500'"
                                >
                                    <i :data-lucide="selectedHousehold.water ? 'check-circle' : 'x-circle'" class="w-3.5 h-3.5"></i>
                                    <span x-text="selectedHousehold.water ? 'Available' : 'Not Available'"></span>
                                </span>
                            </div>
                        </x-ui.card>

                        {{-- Electricity --}}
                        <x-ui.card class="p-5 flex flex-col items-center text-center gap-3">
                            <div
                                class="w-16 h-16 rounded-2xl flex items-center justify-center"
                                :class="selectedHousehold.electricity ? 'bg-amber-100' : 'bg-slate-100'"
                            >
                                <i data-lucide="zap" class="w-8 h-8" :class="selectedHousehold.electricity ? 'text-amber-500' : 'text-slate-300'"></i>
                            </div>
                            <div>
                                <p class="text-sm font-semibold text-navy-900">Electricity</p>
                                <span
                                    class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold mt-1.5"
                                    :class="selectedHousehold.electricity ? 'bg-amber-100 text-amber-700' : 'bg-slate-100 text-slate-500'"
                                >
                                    <i :data-lucide="selectedHousehold.electricity ? 'check-circle' : 'x-circle'" class="w-3.5 h-3.5"></i>
                                    <span x-text="selectedHousehold.electricity ? 'Available' : 'Not Available'"></span>
                                </span>
                            </div>
                        </x-ui.card>

                        {{-- Toilet --}}
                        <x-ui.card class="p-5 flex flex-col items-center text-center gap-3">
                            <div
                                class="w-16 h-16 rounded-2xl flex items-center justify-center"
                                :class="selectedHousehold.toilet ? 'bg-emerald-100' : 'bg-slate-100'"
                            >
                                <i data-lucide="toilet" class="w-8 h-8" :class="selectedHousehold.toilet ? 'text-emerald-500' : 'text-slate-300'"></i>
                            </div>
                            <div>
                                <p class="text-sm font-semibold text-navy-900">Toilet Facility</p>
                                <span
                                    class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold mt-1.5"
                                    :class="selectedHousehold.toilet ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-500'"
                                >
                                    <i :data-lucide="selectedHousehold.toilet ? 'check-circle' : 'x-circle'" class="w-3.5 h-3.5"></i>
                                    <span x-text="selectedHousehold.toilet ? 'Available' : 'Not Available'"></span>
                                </span>
                            </div>
                        </x-ui.card>
                    </div>

                    {{-- Risk information blocks --}}
                    <h3 class="text-sm font-semibold text-navy-900 mb-3">Disaster Risk Profile</h3>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        {{-- Flood risk block --}}
                        <div
                            class="rounded-xl p-4 flex items-start gap-3"
                            :class="{
                                'bg-emerald-50 border border-emerald-200': selectedHousehold.flood_risk === 'Low',
                                'bg-amber-50 border border-amber-200': selectedHousehold.flood_risk === 'Medium',
                                'bg-rose-50 border border-rose-200': selectedHousehold.flood_risk === 'High'
                            }"
                        >
                            <div
                                class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0"
                                :class="{
                                    'bg-emerald-100': selectedHousehold.flood_risk === 'Low',
                                    'bg-amber-100': selectedHousehold.flood_risk === 'Medium',
                                    'bg-rose-100': selectedHousehold.flood_risk === 'High'
                                }"
                            >
                                <i data-lucide="waves-horizontal" class="w-5 h-5"
                                    :class="{
                                        'text-emerald-600': selectedHousehold.flood_risk === 'Low',
                                        'text-amber-600': selectedHousehold.flood_risk === 'Medium',
                                        'text-rose-600': selectedHousehold.flood_risk === 'High'
                                    }"
                                ></i>
                            </div>
                            <div>
                                <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide">Flood Risk Level</p>
                                <p class="text-sm font-bold mt-0.5"
                                    :class="{
                                        'text-emerald-700': selectedHousehold.flood_risk === 'Low',
                                        'text-amber-700': selectedHousehold.flood_risk === 'Medium',
                                        'text-rose-700': selectedHousehold.flood_risk === 'High'
                                    }"
                                    x-text="selectedHousehold.flood_risk || '—'"
                                ></p>
                            </div>
                        </div>

                        {{-- Hazard zone block --}}
                        <div class="rounded-xl p-4 flex items-start gap-3 bg-slate-50 border border-slate-200">
                            <div class="w-10 h-10 rounded-lg bg-slate-100 flex items-center justify-center flex-shrink-0">
                                <i data-lucide="triangle-alert" class="w-5 h-5 text-slate-500"></i>
                            </div>
                            <div>
                                <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide">Hazard Zone Classification</p>
                                <p class="text-sm font-bold text-slate-800 mt-0.5" x-text="selectedHousehold.hazard_zone || '—'"></p>
                            </div>
                        </div>
                    </div>
                </div>

                {{-- ── PROGRAMS TAB ── --}}
                <div x-show="householdTab === 'programs'" x-cloak>
                    <h3 class="text-sm font-semibold text-navy-900 mb-3">Program Enrollments</h3>

                    <template x-if="!selectedHousehold.programs || selectedHousehold.programs.length === 0">
                        <x-ui.card class="py-10 text-center">
                            <div class="flex flex-col items-center gap-2">
                                <i data-lucide="heart-handshake" class="w-8 h-8 text-slate-300"></i>
                                <p class="text-sm text-slate-400">No programs enrolled for this household.</p>
                            </div>
                        </x-ui.card>
                    </template>

                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <template x-for="prog in (selectedHousehold.programs || [])" :key="prog">
                            <x-ui.card class="p-4 flex items-center gap-3">
                                <div class="flex-shrink-0 w-10 h-10 rounded-lg bg-emerald-100 flex items-center justify-center">
                                    <i data-lucide="heart-handshake" class="w-5 h-5 text-emerald-600"></i>
                                </div>
                                <div class="min-w-0">
                                    <p class="text-sm font-semibold text-navy-900" x-text="prog"></p>
                                    <span class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-xs font-medium bg-emerald-50 text-emerald-700 mt-0.5">
                                        <i data-lucide="circle-check" class="w-3 h-3"></i>
                                        Active
                                    </span>
                                </div>
                            </x-ui.card>
                        </template>
                    </div>
                </div>

                {{-- ── HISTORY TAB ── --}}
                <div x-show="householdTab === 'history'" x-cloak>
                    <h3 class="text-sm font-semibold text-navy-900 mb-3">Record History</h3>
                    <x-ui.card class="p-4 space-y-4">
                        <div class="flex items-start gap-3">
                            <div class="w-8 h-8 rounded-full bg-indigo-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                                <i data-lucide="file-plus" class="w-4 h-4 text-indigo-600"></i>
                            </div>
                            <div>
                                <p class="text-xs font-semibold text-navy-900">Record Created</p>
                                <p class="text-xs text-slate-500 mt-0.5" x-text="selectedHousehold.created || 'Date not recorded'"></p>
                                <p class="text-xs text-slate-400 mt-0.5">Encoded by: <span class="font-medium text-slate-600">System</span></p>
                            </div>
                        </div>
                        <div class="border-t border-slate-100"></div>
                        <div class="flex items-start gap-3">
                            <div class="w-8 h-8 rounded-full bg-amber-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                                <i data-lucide="pencil" class="w-4 h-4 text-amber-600"></i>
                            </div>
                            <div>
                                <p class="text-xs font-semibold text-navy-900">Last Updated</p>
                                <p class="text-xs text-slate-500 mt-0.5" x-text="selectedHousehold.last_updated || 'No updates recorded'"></p>
                                <p class="text-xs text-slate-400 mt-0.5">Updated by: <span class="font-medium text-slate-600">System</span></p>
                            </div>
                        </div>
                        <div class="border-t border-slate-100"></div>
                        <div class="flex items-start gap-3">
                            <div class="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                                <i data-lucide="hash" class="w-4 h-4 text-slate-500"></i>
                            </div>
                            <div>
                                <p class="text-xs font-semibold text-navy-900">Household Record ID</p>
                                <p class="text-xs text-slate-500 font-mono mt-0.5" x-text="selectedHousehold.id"></p>
                            </div>
                        </div>
                    </x-ui.card>
                </div>

            </div>

            {{-- ── Modal Footer ── --}}
            <div class="flex-shrink-0 px-6 py-4 border-t border-slate-200 bg-slate-50/50 flex items-center justify-between gap-3 rounded-b-2xl">
                <button
                    @click="showHouseholdDetail = false"
                    class="px-4 py-2 text-sm font-medium text-slate-600 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors shadow-sm"
                >
                    Close
                </button>
                <button
                    @click="$dispatch('toast', {message: 'Edit household feature coming soon.', type: 'info'})"
                    class="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-medium rounded-lg shadow-sm transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
                >
                    <i data-lucide="pencil" class="w-4 h-4"></i>
                    Edit Household
                </button>
            </div>

        </div>
    </template>

    {{-- Loading placeholder --}}
    <template x-if="!selectedHousehold">
        <div class="flex items-center justify-center h-48 text-slate-400 text-sm">
            <i data-lucide="loader-circle" class="w-6 h-6 animate-spin mr-2"></i>
            Loading household details…
        </div>
    </template>

</x-ui.modal>
</div>
