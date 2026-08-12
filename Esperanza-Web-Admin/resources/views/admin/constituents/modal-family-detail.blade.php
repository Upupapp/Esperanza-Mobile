{{-- modal-family-detail.blade.php --}}
{{-- Family detail modal — 4 tabs: Overview | Members | Programs | History --}}

<div x-data="{
    get open() { return showFamilyDetail },
    set open(v) { showFamilyDetail = v }
}">
<x-ui.modal maxWidth="2xl">

    <template x-if="selectedFamily">
        <div class="flex flex-col h-full max-h-[90vh]">

            {{-- ── Modal Header ── --}}
            <div class="flex-shrink-0 px-6 pt-6 pb-4 border-b border-slate-200">
                <div class="flex items-start justify-between gap-4">
                    <div class="flex items-start gap-4 min-w-0">
                        {{-- Family avatar --}}
                        <div class="flex-shrink-0 w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center shadow-md">
                            <span class="text-white font-bold text-base" x-text="selectedFamily.surname?.substring(0,2).toUpperCase()"></span>
                        </div>
                        <div class="min-w-0">
                            <div class="flex items-center flex-wrap gap-2">
                                <h2 class="text-lg font-bold text-navy-900 truncate" x-text="selectedFamily.label"></h2>
                                {{-- Family type chip --}}
                                <span
                                    class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold"
                                    :class="{
                                        'bg-slate-100 text-slate-600': selectedFamily.family_type === 'Nuclear',
                                        'bg-purple-100 text-purple-700': selectedFamily.family_type === 'Extended',
                                        'bg-amber-100 text-amber-700': selectedFamily.family_type === 'Single Parent'
                                    }"
                                    x-text="selectedFamily.family_type"
                                ></span>
                                {{-- Verification badge --}}
                                <span
                                    class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium"
                                    :class="verificationBadge(selectedFamily.verification).class"
                                    x-text="verificationBadge(selectedFamily.verification).label"
                                ></span>
                            </div>
                            <div class="flex items-center flex-wrap gap-x-3 gap-y-1 mt-1">
                                <span class="inline-flex items-center gap-1 text-xs text-slate-500">
                                    <i data-lucide="map-pin" class="w-3 h-3 text-slate-400"></i>
                                    <span x-text="selectedFamily.barangay"></span>
                                </span>
                                <template x-if="selectedFamily.household_id">
                                    <span class="inline-flex items-center gap-1 text-xs text-blue-600">
                                        <i data-lucide="house" class="w-3 h-3"></i>
                                        <span x-text="'Household HH-' + selectedFamily.household_id"></span>
                                    </span>
                                </template>
                                <span class="text-xs text-slate-400 font-mono" x-text="'ID: ' + selectedFamily.id"></span>
                            </div>
                            {{-- Profile completion bar --}}
                            <div class="flex items-center gap-2 mt-2">
                                <div class="flex-1 h-1.5 bg-slate-100 rounded-full overflow-hidden max-w-[180px]">
                                    <div
                                        class="h-full rounded-full transition-all"
                                        :class="completionColor(selectedFamily.profile_pct)"
                                        :style="'width:' + (selectedFamily.profile_pct||0) + '%'"
                                    ></div>
                                </div>
                                <span class="text-xs font-semibold" :class="completionTextColor(selectedFamily.profile_pct)" x-text="(selectedFamily.profile_pct||0) + '% Complete'"></span>
                            </div>
                        </div>
                    </div>
                    {{-- Close button --}}
                    <button @click="showFamilyDetail = false" class="flex-shrink-0 p-2 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors">
                        <i data-lucide="x" class="w-5 h-5"></i>
                    </button>
                </div>

                {{-- Tab nav --}}
                <div class="flex gap-1 mt-4 -mb-4 border-b-0">
                    <template x-for="tab in [{id:'overview',icon:'layout-list',label:'Overview'},{id:'members',icon:'users',label:'Members'},{id:'programs',icon:'heart-handshake',label:'Programs'},{id:'history',icon:'clock',label:'History'}]" :key="tab.id">
                        <button
                            @click="familyTab = tab.id"
                            class="inline-flex items-center gap-1.5 px-3 py-2 text-sm font-medium rounded-t-lg border-b-2 transition-colors"
                            :class="familyTab === tab.id
                                ? 'text-blue-600 border-blue-600 bg-blue-50/50'
                                : 'text-slate-500 border-transparent hover:text-slate-700 hover:border-slate-300'"
                        >
                            <i :data-lucide="tab.icon" class="w-3.5 h-3.5"></i>
                            <span x-text="tab.label"></span>
                            <template x-if="tab.id === 'members'">
                                <span class="ml-0.5 px-1.5 py-0.5 rounded-full text-xs font-semibold bg-slate-100 text-slate-600" x-text="selectedFamily.member_count"></span>
                            </template>
                        </button>
                    </template>
                </div>
            </div>

            {{-- ── Tab Content (scrollable) ── --}}
            <div class="flex-1 overflow-y-auto px-6 py-5 space-y-4">

                {{-- ── OVERVIEW TAB ── --}}
                <div x-show="familyTab === 'overview'" x-cloak>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        {{-- Left column --}}
                        <div class="space-y-3">
                            <x-ui.card class="p-4">
                                <h4 class="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">Family Details</h4>
                                <dl class="space-y-2.5">
                                    <div class="flex justify-between items-start gap-2">
                                        <dt class="text-xs text-slate-500 flex items-center gap-1.5"><i data-lucide="users-round" class="w-3.5 h-3.5 text-slate-400"></i> Family Type</dt>
                                        <dd class="text-xs font-semibold text-navy-900" x-text="selectedFamily.family_type"></dd>
                                    </div>
                                    <div class="flex justify-between items-start gap-2">
                                        <dt class="text-xs text-slate-500 flex items-center gap-1.5"><i data-lucide="map-pin" class="w-3.5 h-3.5 text-slate-400"></i> Barangay</dt>
                                        <dd class="text-xs font-semibold text-navy-900" x-text="selectedFamily.barangay"></dd>
                                    </div>
                                    <div class="flex justify-between items-start gap-2">
                                        <dt class="text-xs text-slate-500 flex items-center gap-1.5"><i data-lucide="milestone" class="w-3.5 h-3.5 text-slate-400"></i> Sitio / Purok</dt>
                                        <dd class="text-xs font-semibold text-navy-900" x-text="selectedFamily.sitio || '—'"></dd>
                                    </div>
                                    <div class="flex justify-between items-start gap-2">
                                        <dt class="text-xs text-slate-500 flex items-center gap-1.5"><i data-lucide="house" class="w-3.5 h-3.5 text-slate-400"></i> Household ID</dt>
                                        <dd class="text-xs font-semibold text-blue-600" x-text="selectedFamily.household_id ? ('HH-' + selectedFamily.household_id) : 'Unlinked'"></dd>
                                    </div>
                                    <div class="flex justify-between items-start gap-2">
                                        <dt class="text-xs text-slate-500 flex items-center gap-1.5"><i data-lucide="user" class="w-3.5 h-3.5 text-slate-400"></i> Head of Family</dt>
                                        <dd class="text-xs font-semibold text-navy-900" x-text="selectedFamily.head_name || '—'"></dd>
                                    </div>
                                    <div class="flex justify-between items-start gap-2">
                                        <dt class="text-xs text-slate-500 flex items-center gap-1.5"><i data-lucide="users" class="w-3.5 h-3.5 text-slate-400"></i> Member Count</dt>
                                        <dd class="text-xs font-semibold text-navy-900" x-text="selectedFamily.member_count"></dd>
                                    </div>
                                </dl>
                            </x-ui.card>
                        </div>

                        {{-- Right column --}}
                        <div class="space-y-3">
                            <x-ui.card class="p-4">
                                <h4 class="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">Status & Verification</h4>
                                <dl class="space-y-2.5">
                                    <div class="flex justify-between items-center gap-2">
                                        <dt class="text-xs text-slate-500">Record Status</dt>
                                        <dd>
                                            <x-ui.badge :status="''" x-bind:data-status="selectedFamily.status" />
                                        </dd>
                                    </div>
                                    <div class="flex justify-between items-center gap-2">
                                        <dt class="text-xs text-slate-500">Verification</dt>
                                        <dd>
                                            <span
                                                class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium"
                                                :class="verificationBadge(selectedFamily.verification).class"
                                                x-text="verificationBadge(selectedFamily.verification).label"
                                            ></span>
                                        </dd>
                                    </div>
                                    <div class="flex justify-between items-start gap-2">
                                        <dt class="text-xs text-slate-500">Profile Completion</dt>
                                        <dd class="text-xs font-bold" :class="completionTextColor(selectedFamily.profile_pct)" x-text="(selectedFamily.profile_pct||0) + '%'"></dd>
                                    </div>
                                </dl>
                            </x-ui.card>

                            {{-- Programs chips --}}
                            <x-ui.card class="p-4">
                                <h4 class="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">Enrolled Programs</h4>
                                <div class="flex flex-wrap gap-1.5">
                                    <template x-if="!selectedFamily.programs || selectedFamily.programs.length === 0">
                                        <span class="text-xs text-slate-400 italic">No enrolled programs</span>
                                    </template>
                                    <template x-for="prog in (selectedFamily.programs || [])" :key="prog">
                                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700" x-text="prog"></span>
                                    </template>
                                </div>
                            </x-ui.card>

                            {{-- Notes --}}
                            <x-ui.card class="p-4">
                                <h4 class="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">Notes / Remarks</h4>
                                <p class="text-xs text-slate-600 leading-relaxed" x-text="selectedFamily.notes || 'No notes recorded.'"></p>
                            </x-ui.card>
                        </div>
                    </div>
                </div>

                {{-- ── MEMBERS TAB ── --}}
                <div x-show="familyTab === 'members'" x-cloak>
                    <div class="flex items-center justify-between mb-3">
                        <h3 class="text-sm font-semibold text-navy-900">
                            All Family Members
                            <span class="ml-1.5 px-2 py-0.5 rounded-full text-xs bg-blue-100 text-blue-700 font-semibold" x-text="selectedFamily.member_count"></span>
                        </h3>
                    </div>

                    <x-ui.card class="overflow-hidden">
                        <template x-if="(individuals.filter(r => selectedFamily?.member_ids?.includes(r.id))).length === 0">
                            <div class="py-10 text-center">
                                <div class="flex flex-col items-center gap-2">
                                    <i data-lucide="user-x" class="w-8 h-8 text-slate-300"></i>
                                    <p class="text-sm text-slate-400">No members linked to this family yet.</p>
                                </div>
                            </div>
                        </template>

                        <ul class="divide-y divide-slate-100">
                            <template x-for="r in individuals.filter(r => selectedFamily?.member_ids?.includes(r.id))" :key="r.id">
                                <li
                                    class="flex items-center gap-3 px-4 py-3 hover:bg-blue-50/40 cursor-pointer transition-colors"
                                    @click="openIndividual(r)"
                                >
                                    <div class="w-8 h-8 text-xs rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold ring-2 ring-white shadow-sm shrink-0" x-text="(r.name || '').split(/\s+/).filter(Boolean).map(w => w[0]).slice(0,2).join('').toUpperCase()"></div>
                                    <div class="flex-1 min-w-0">
                                        <p class="text-sm font-semibold text-navy-900 truncate" x-text="r.name"></p>
                                        <p class="text-xs text-slate-400">
                                            <span x-text="r.age ? r.age + ' yrs' : ''"></span>
                                            <template x-if="r.relation"><span> · <span x-text="r.relation"></span></span></template>
                                        </p>
                                    </div>
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

                {{-- ── PROGRAMS TAB ── --}}
                <div x-show="familyTab === 'programs'" x-cloak>
                    <h3 class="text-sm font-semibold text-navy-900 mb-3">Program Enrollments</h3>

                    <template x-if="!selectedFamily.programs || selectedFamily.programs.length === 0">
                        <x-ui.card class="py-10 text-center">
                            <div class="flex flex-col items-center gap-2">
                                <i data-lucide="heart-handshake" class="w-8 h-8 text-slate-300"></i>
                                <p class="text-sm text-slate-400">No programs enrolled.</p>
                            </div>
                        </x-ui.card>
                    </template>

                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <template x-for="prog in (selectedFamily.programs || [])" :key="prog">
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
                <div x-show="familyTab === 'history'" x-cloak>
                    <h3 class="text-sm font-semibold text-navy-900 mb-3">Record History</h3>
                    <x-ui.card class="p-4 space-y-4">
                        <div class="flex items-start gap-3">
                            <div class="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                                <i data-lucide="file-plus" class="w-4 h-4 text-blue-600"></i>
                            </div>
                            <div>
                                <p class="text-xs font-semibold text-navy-900">Record Created</p>
                                <p class="text-xs text-slate-500 mt-0.5" x-text="selectedFamily.created || 'Date not recorded'"></p>
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
                                <p class="text-xs text-slate-500 mt-0.5" x-text="selectedFamily.last_updated || 'No updates recorded'"></p>
                                <p class="text-xs text-slate-400 mt-0.5">Updated by: <span class="font-medium text-slate-600">System</span></p>
                            </div>
                        </div>
                        <div class="border-t border-slate-100"></div>
                        <div class="flex items-start gap-3">
                            <div class="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                                <i data-lucide="hash" class="w-4 h-4 text-slate-500"></i>
                            </div>
                            <div>
                                <p class="text-xs font-semibold text-navy-900">Record ID</p>
                                <p class="text-xs text-slate-500 font-mono mt-0.5" x-text="selectedFamily.id"></p>
                            </div>
                        </div>
                    </x-ui.card>
                </div>

            </div>

            {{-- ── Modal Footer ── --}}
            <div class="flex-shrink-0 px-6 py-4 border-t border-slate-200 bg-slate-50/50 flex items-center justify-between gap-3 rounded-b-2xl">
                <button
                    @click="showFamilyDetail = false"
                    class="px-4 py-2 text-sm font-medium text-slate-600 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors shadow-sm"
                >
                    Close
                </button>
                <button
                    @click="$dispatch('toast', {message: 'Add member feature coming soon.', type: 'info'})"
                    class="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium rounded-lg shadow-sm transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                >
                    <i data-lucide="user-plus" class="w-4 h-4"></i>
                    Add Member
                </button>
            </div>

        </div>
    </template>

    {{-- Placeholder when no family selected --}}
    <template x-if="!selectedFamily">
        <div class="flex items-center justify-center h-48 text-slate-400 text-sm">
            <i data-lucide="loader-circle" class="w-6 h-6 animate-spin mr-2"></i>
            Loading family details…
        </div>
    </template>

</x-ui.modal>
</div>
