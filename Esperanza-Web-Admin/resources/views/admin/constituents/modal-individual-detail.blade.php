{{-- ============================================================
     FILE: modal-individual-detail.blade.php
     Partial: Comprehensive individual detail modal
     Alpine scope: parent x-data (showIndividualDetail, selectedIndividual, etc.)
     ============================================================ --}}

<div
    x-data="{
        get open() { return showIndividualDetail; },
        set open(v) { showIndividualDetail = v; }
    }"
>
    <x-ui.modal maxWidth="2xl">

        {{-- ════════════════════════════════════════════════════════
             MODAL HEADER
        ════════════════════════════════════════════════════════ --}}
        <div
            class="relative bg-gradient-to-br from-navy-900 via-navy-800 to-brand-900 text-white px-6 pt-6 pb-8 rounded-t-2xl overflow-hidden"
            x-show="selectedIndividual"
        >
            {{-- Decorative backdrop ring --}}
            <div class="absolute -top-8 -right-8 w-40 h-40 rounded-full bg-white/5 pointer-events-none"></div>
            <div class="absolute -bottom-6 -left-6 w-32 h-32 rounded-full bg-white/5 pointer-events-none"></div>

            {{-- Close button --}}
            <button
                @click="showIndividualDetail = false"
                class="absolute top-4 right-4 w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors z-10"
                title="Close"
            >
                <i data-lucide="x" class="w-4 h-4"></i>
            </button>

            <div class="flex items-start gap-5 relative z-10">

                {{-- Profile completion ring + avatar --}}
                <div class="flex-shrink-0 relative">
                    {{-- Outer ring (SVG donut) --}}
                    <div class="relative w-20 h-20">
                        <svg class="w-20 h-20 -rotate-90" viewBox="0 0 80 80">
                            <circle cx="40" cy="40" r="36" stroke="rgba(255,255,255,0.15)" stroke-width="5" fill="none"/>
                            <circle
                                cx="40" cy="40" r="36"
                                stroke="rgba(255,255,255,0.85)"
                                stroke-width="5"
                                fill="none"
                                stroke-linecap="round"
                                :stroke-dasharray="'226.2'"
                                :stroke-dashoffset="226.2 - (226.2 * (selectedIndividual?.profile_pct || 0) / 100)"
                                class="transition-all duration-700"
                            />
                        </svg>
                        {{-- Avatar inside ring --}}
                        <div class="absolute inset-2 rounded-full bg-white/10 flex items-center justify-center text-white font-bold text-xl uppercase">
                            <span x-text="(selectedIndividual?.name || '').split(' ').map(w=>w[0]).slice(0,2).join('')"></span>
                        </div>
                    </div>
                    {{-- Profile % label --}}
                    <div class="absolute -bottom-1 left-1/2 -translate-x-1/2 bg-white/20 rounded-full px-2 py-0.5 text-[10px] font-bold text-white whitespace-nowrap">
                        <span x-text="(selectedIndividual?.profile_pct || 0) + '%'"></span>
                    </div>
                </div>

                {{-- Identity block --}}
                <div class="flex-1 min-w-0 pt-1">
                    <div class="flex flex-wrap items-center gap-2 mb-1">
                        {{-- Status badge --}}
                        <span
                            class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-white/20 text-white"
                            x-text="selectedIndividual?.status"
                        ></span>
                        {{-- Verification badge --}}
                        <span
                            class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-white/10 text-white/80"
                        >
                            <i data-lucide="shield-check" class="w-3 h-3"></i>
                            <span x-text="selectedIndividual?.verification"></span>
                        </span>
                    </div>

                    <h2 class="text-xl font-bold text-white leading-tight truncate" x-text="selectedIndividual?.name"></h2>
                    <p class="text-sm text-white/60 mt-0.5">
                        ID: <span class="font-mono font-medium text-white/80" x-text="selectedIndividual?.id"></span>
                        &nbsp;·&nbsp;
                        <span x-text="selectedIndividual?.sex === 'F' ? 'Female' : 'Male'"></span>,
                        <span x-text="selectedIndividual?.age + ' years old'"></span>
                    </p>

                    {{-- Role / relation chip --}}
                    <div class="flex flex-wrap gap-1.5 mt-2">
                        <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-white/10 text-xs font-medium text-white/80">
                            <i data-lucide="house" class="w-3 h-3"></i>
                            <span x-text="selectedIndividual?.relation || 'Member'"></span>
                        </span>
                        <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-white/10 text-xs font-medium text-white/80">
                            <i data-lucide="map-pin" class="w-3 h-3"></i>
                            <span x-text="'Brgy. ' + (selectedIndividual?.barangay || '—')"></span>
                        </span>
                    </div>
                </div>
            </div>

            {{-- ── Tab bar ── --}}
            <div class="mt-6 flex gap-0.5 border-b border-white/10 overflow-x-auto scrollbar-none pb-px -mb-px">
                <template x-for="tab in ['Overview','Programs & Benefits','Services','Documents','History']" :key="tab">
                    <button
                        @click="individualTab = tab"
                        class="flex-shrink-0 px-4 py-2 text-sm font-medium rounded-t-lg transition-colors whitespace-nowrap"
                        :class="individualTab === tab
                            ? 'bg-white text-navy-900'
                            : 'text-white/60 hover:text-white hover:bg-white/10'"
                        x-text="tab"
                    ></button>
                </template>
            </div>
        </div>

        {{-- ════════════════════════════════════════════════════════
             TAB PANELS
        ════════════════════════════════════════════════════════ --}}
        <div class="px-6 py-5 overflow-y-auto max-h-[58vh] bg-slate-50/50" x-show="selectedIndividual">

            {{-- ── TAB 1: Overview ── --}}
            <div x-show="individualTab === 'Overview'" class="space-y-5">

                {{-- Personal info grid --}}
                <div class="bg-white rounded-xl border border-slate-200 shadow-card p-5">
                    <h3 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-4">Personal Information</h3>
                    <dl class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-4">

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Full Name</dt>
                            <dd class="text-sm font-semibold text-navy-900" x-text="selectedIndividual?.name || '—'"></dd>
                        </div>

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Date of Birth</dt>
                            <dd class="text-sm font-semibold text-navy-900" x-text="selectedIndividual?.dob || '—'"></dd>
                        </div>

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Age</dt>
                            <dd class="text-sm font-semibold text-navy-900">
                                <span x-text="(selectedIndividual?.age || '—') + (selectedIndividual?.age ? ' years old' : '')"></span>
                            </dd>
                        </div>

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Sex</dt>
                            <dd class="text-sm font-semibold text-navy-900">
                                <span x-text="selectedIndividual?.sex === 'F' ? 'Female' : selectedIndividual?.sex === 'M' ? 'Male' : '—'"></span>
                            </dd>
                        </div>

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Civil Status</dt>
                            <dd class="text-sm font-semibold text-navy-900" x-text="selectedIndividual?.civil_status || '—'"></dd>
                        </div>

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Contact Number</dt>
                            <dd class="text-sm font-semibold text-navy-900">
                                <a
                                    :href="'tel:' + selectedIndividual?.contact"
                                    class="text-brand-600 hover:underline"
                                    x-text="selectedIndividual?.contact || '—'"
                                ></a>
                            </dd>
                        </div>

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Email Address</dt>
                            <dd class="text-sm font-semibold text-navy-900" x-text="selectedIndividual?.email || '—'"></dd>
                        </div>

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Occupation</dt>
                            <dd class="text-sm font-semibold text-navy-900" x-text="selectedIndividual?.occupation || '—'"></dd>
                        </div>

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Highest Education</dt>
                            <dd class="text-sm font-semibold text-navy-900" x-text="selectedIndividual?.education || '—'"></dd>
                        </div>

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Income Range</dt>
                            <dd class="text-sm font-semibold text-navy-900" x-text="selectedIndividual?.income_range || '—'"></dd>
                        </div>

                    </dl>
                </div>

                {{-- Address & Household info --}}
                <div class="bg-white rounded-xl border border-slate-200 shadow-card p-5">
                    <h3 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-4">Address & Household</h3>
                    <dl class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-4">

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Barangay</dt>
                            <dd class="text-sm font-semibold text-navy-900" x-text="'Brgy. ' + (selectedIndividual?.barangay || '—')"></dd>
                        </div>

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Sitio / Purok</dt>
                            <dd class="text-sm font-semibold text-navy-900" x-text="selectedIndividual?.sitio || '—'"></dd>
                        </div>

                        <div class="sm:col-span-2">
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Full Address</dt>
                            <dd class="text-sm font-semibold text-navy-900" x-text="selectedIndividual?.address || '—'"></dd>
                        </div>

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Household ID</dt>
                            <dd class="text-sm font-mono font-semibold text-navy-900" x-text="selectedIndividual?.household_id || '—'"></dd>
                        </div>

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Family ID</dt>
                            <dd class="text-sm font-mono font-semibold text-navy-900" x-text="selectedIndividual?.family_id || '—'"></dd>
                        </div>

                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Relation in Household</dt>
                            <dd class="text-sm font-semibold text-navy-900" x-text="selectedIndividual?.relation || '—'"></dd>
                        </div>

                    </dl>
                </div>

                {{-- Vulnerable Sector Tags --}}
                <div class="bg-white rounded-xl border border-slate-200 shadow-card p-5" x-show="(selectedIndividual?.tags || []).length > 0">
                    <h3 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">Vulnerable Sector Classification</h3>
                    <div class="flex flex-wrap gap-2">
                        <template x-for="tag in (selectedIndividual?.tags || [])" :key="tag">
                            <span
                                class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-semibold"
                                :class="{
                                    'bg-amber-100 text-amber-800 ring-1 ring-amber-200': tag === 'senior' || tag === 'osca',
                                    'bg-blue-100 text-blue-800 ring-1 ring-blue-200': tag === 'pwd',
                                    'bg-green-100 text-green-800 ring-1 ring-green-200': tag === 'youth',
                                    'bg-violet-100 text-violet-800 ring-1 ring-violet-200': tag === 'child',
                                    'bg-orange-100 text-orange-800 ring-1 ring-orange-200': tag === 'osy',
                                    'bg-cyan-100 text-cyan-800 ring-1 ring-cyan-200': tag === '4ps',
                                    'bg-rose-100 text-rose-800 ring-1 ring-rose-200': tag === 'solo_parent',
                                    'bg-lime-100 text-lime-800 ring-1 ring-lime-200': tag === 'farmer',
                                    'bg-red-100 text-red-800 ring-1 ring-red-200': tag === 'high_risk',
                                }"
                            >
                                <i data-lucide="tag" class="w-3.5 h-3.5"></i>
                                <span x-text="
                                    tag === 'solo_parent' ? 'Solo Parent' :
                                    tag === 'high_risk' ? 'High Risk' :
                                    tag === 'osy' ? 'Out-of-School Youth' :
                                    tag === '4ps' ? '4Ps Beneficiary' :
                                    tag === 'osca' ? 'OSCA' :
                                    tag === 'pwd' ? 'PWD' :
                                    tag.charAt(0).toUpperCase() + tag.slice(1)
                                "></span>
                            </span>
                        </template>
                    </div>
                </div>

                {{-- Emergency Contact --}}
                <div class="bg-white rounded-xl border border-slate-200 shadow-card p-5">
                    <h3 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-4 flex items-center gap-2">
                        <i data-lucide="circle-alert" class="w-4 h-4 text-rose-400"></i>
                        Emergency Contact
                    </h3>
                    <dl class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Name</dt>
                            <dd class="text-sm font-semibold text-navy-900" x-text="selectedIndividual?.emergency?.name || '—'"></dd>
                        </div>
                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Contact</dt>
                            <dd class="text-sm font-semibold text-navy-900">
                                <a :href="'tel:' + selectedIndividual?.emergency?.contact"
                                   class="text-brand-600 hover:underline"
                                   x-text="selectedIndividual?.emergency?.contact || '—'"></a>
                            </dd>
                        </div>
                        <div>
                            <dt class="text-xs text-slate-400 uppercase tracking-wide mb-0.5">Relationship</dt>
                            <dd class="text-sm font-semibold text-navy-900" x-text="selectedIndividual?.emergency?.relation || '—'"></dd>
                        </div>
                    </dl>
                </div>

            </div>{{-- /Overview --}}


            {{-- ── TAB 2: Programs & Benefits ── --}}
            <div x-show="individualTab === 'Programs & Benefits'" class="space-y-3">

                <p class="text-xs text-slate-500 bg-blue-50 border border-blue-100 rounded-lg px-4 py-2.5 flex items-center gap-2">
                    <i data-lucide="info" class="w-4 h-4 text-blue-400 flex-shrink-0"></i>
                    Programs shown are based on vulnerable sector tags encoded on this resident's profile.
                </p>

                {{-- Program list derived from tags --}}
                <template x-if="(selectedIndividual?.tags || []).length === 0">
                    <div class="py-12 text-center">
                        <div class="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center mx-auto mb-3">
                            <i data-lucide="package-open" class="w-6 h-6 text-slate-400"></i>
                        </div>
                        <p class="text-sm font-medium text-slate-600">No program enrollments found</p>
                        <p class="text-xs text-slate-400 mt-1">Add sector tags on the resident's profile to reflect program eligibility.</p>
                    </div>
                </template>

                <template x-if="(selectedIndividual?.tags || []).length > 0">
                    <div class="space-y-3">
                        <template x-for="tag in (selectedIndividual?.tags || [])" :key="'prog-'+tag">
                            <div class="bg-white rounded-xl border border-slate-200 shadow-card p-4 flex items-center justify-between gap-4">
                                <div class="flex items-center gap-3">
                                    <div
                                        class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0"
                                        :class="{
                                            'bg-amber-100': tag === 'senior' || tag === 'osca',
                                            'bg-blue-100': tag === 'pwd',
                                            'bg-green-100': tag === 'youth',
                                            'bg-violet-100': tag === 'child',
                                            'bg-orange-100': tag === 'osy',
                                            'bg-cyan-100': tag === '4ps',
                                            'bg-rose-100': tag === 'solo_parent',
                                            'bg-lime-100': tag === 'farmer',
                                            'bg-red-100': tag === 'high_risk',
                                        }"
                                    >
                                        <i data-lucide="landmark" class="w-5 h-5"
                                            :class="{
                                                'text-amber-600': tag === 'senior' || tag === 'osca',
                                                'text-blue-600': tag === 'pwd',
                                                'text-green-600': tag === 'youth',
                                                'text-violet-600': tag === 'child',
                                                'text-orange-600': tag === 'osy',
                                                'text-cyan-600': tag === '4ps',
                                                'text-rose-600': tag === 'solo_parent',
                                                'text-lime-700': tag === 'farmer',
                                                'text-red-600': tag === 'high_risk',
                                            }"
                                        ></i>
                                    </div>
                                    <div>
                                        <p class="text-sm font-semibold text-navy-900" x-text="
                                            tag === '4ps' ? 'Pantawid Pamilyang Pilipino Program (4Ps)' :
                                            tag === 'osca' || tag === 'senior' ? 'OSCA / Senior Citizen Assistance' :
                                            tag === 'pwd' ? 'PWD Assistance & Benefits Program' :
                                            tag === 'solo_parent' ? 'Solo Parent Cash Assistance Program' :
                                            tag === 'youth' ? 'Youth Development Program' :
                                            tag === 'child' ? 'Child Protection & Early Childhood Program' :
                                            tag === 'osy' ? 'Alternative Learning System (ALS / OSY)' :
                                            tag === 'farmer' ? 'Farmers\' Assistance & Livelihood Program' :
                                            tag === 'high_risk' ? 'High-Risk Family Monitoring Program' :
                                            tag.toUpperCase() + ' Program'
                                        "></p>
                                        <p class="text-xs text-slate-500 mt-0.5">Barangay-administered &bull; MSWDO linked</p>
                                    </div>
                                </div>
                                <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-700 flex-shrink-0">
                                    <span class="w-1.5 h-1.5 rounded-full bg-green-500 mr-1.5 animate-pulse"></span>
                                    Active
                                </span>
                            </div>
                        </template>
                    </div>
                </template>

            </div>{{-- /Programs & Benefits --}}


            {{-- ── TAB 3: Services ── --}}
            <div x-show="individualTab === 'Services'" class="space-y-4">

                <template x-if="!(selectedIndividual?.services?.length)">
                    <div class="py-12 text-center">
                        <div class="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center mx-auto mb-3">
                            <i data-lucide="clipboard-list" class="w-6 h-6 text-slate-400"></i>
                        </div>
                        <p class="text-sm font-medium text-slate-600">No service records yet</p>
                        <p class="text-xs text-slate-400 mt-1">Service availed will appear here as transactions are processed.</p>
                    </div>
                </template>

                <template x-if="selectedIndividual?.services?.length">
                    <div class="relative">
                        {{-- Timeline line --}}
                        <div class="absolute left-[19px] top-3 bottom-3 w-0.5 bg-slate-200 rounded-full"></div>

                        <div class="space-y-4">
                            <template x-for="(svc, idx) in (selectedIndividual?.services || [])" :key="idx">
                                <div class="flex items-start gap-4 relative">
                                    {{-- Timeline dot --}}
                                    <div class="w-9 h-9 rounded-full bg-white border-2 border-slate-200 flex items-center justify-center flex-shrink-0 shadow-sm z-10">
                                        <i data-lucide="file-text" class="w-4 h-4 text-brand-500"></i>
                                    </div>
                                    <div class="flex-1 bg-white rounded-xl border border-slate-200 shadow-card p-4">
                                        <div class="flex items-start justify-between gap-3">
                                            <div>
                                                <p class="text-sm font-semibold text-navy-900" x-text="svc.type"></p>
                                                <p class="text-xs text-slate-400 mt-0.5" x-text="svc.date"></p>
                                            </div>
                                            <span
                                                class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold flex-shrink-0"
                                                :class="{
                                                    'bg-green-100 text-green-700': svc.status === 'Completed' || svc.status === 'Released',
                                                    'bg-amber-100 text-amber-700': svc.status === 'Processing' || svc.status === 'Pending',
                                                    'bg-blue-100 text-blue-700': svc.status === 'Approved',
                                                    'bg-red-100 text-red-700': svc.status === 'Rejected' || svc.status === 'Cancelled',
                                                    'bg-slate-100 text-slate-600': !['Completed','Released','Processing','Pending','Approved','Rejected','Cancelled'].includes(svc.status),
                                                }"
                                                x-text="svc.status"
                                            ></span>
                                        </div>
                                    </div>
                                </div>
                            </template>
                        </div>
                    </div>
                </template>

            </div>{{-- /Services --}}


            {{-- ── TAB 4: Documents ── --}}
            <div x-show="individualTab === 'Documents'" class="space-y-3">

                <p class="text-xs text-slate-500 bg-slate-50 border border-slate-200 rounded-lg px-4 py-2.5 flex items-center gap-2">
                    <i data-lucide="info" class="w-4 h-4 text-slate-400 flex-shrink-0"></i>
                    Document checklist status is derived from verification records. Upload to update.
                </p>

                {{-- Base required documents --}}
                <template x-for="doc in [
                    { label: 'PSA Birth Certificate', key: 'psa_birth', icon: 'scroll-text', required: true, tag: null },
                    { label: 'Valid Government-Issued ID', key: 'gov_id', icon: 'id-card', required: true, tag: null },
                    { label: 'PhilSys National ID', key: 'philsys', icon: 'credit-card', required: true, tag: null },
                    { label: 'Proof of Residency', key: 'proof_residency', icon: 'home', required: true, tag: null },
                    { label: 'School ID / Enrollment Form', key: 'school_id', icon: 'graduation-cap', required: false, tag: 'youth' },
                    { label: 'School ID / Enrollment Form', key: 'school_id_child', icon: 'graduation-cap', required: false, tag: 'child' },
                    { label: 'PWD Identification Card', key: 'pwd_id', icon: 'accessibility', required: false, tag: 'pwd' },
                    { label: 'OSCA Senior Citizen ID', key: 'osca_id', icon: 'award', required: false, tag: 'senior' },
                    { label: 'Solo Parent ID', key: 'solo_id', icon: 'heart', required: false, tag: 'solo_parent' },
                    { label: '4Ps Beneficiary Card', key: 'fourps_card', icon: 'wallet', required: false, tag: '4ps' },
                ]" :key="doc.key">
                    {{-- Show if no tag OR tag is present in resident's tags --}}
                    <template x-if="!doc.tag || (selectedIndividual?.tags || []).includes(doc.tag)">
                        <div class="bg-white rounded-xl border border-slate-200 shadow-card p-4 flex items-center gap-4">
                            <div
                                class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0"
                                :class="selectedIndividual?.verification === 'Verified' ? 'bg-green-100' : 'bg-slate-100'"
                            >
                                <i
                                    :data-lucide="doc.icon"
                                    class="w-5 h-5"
                                    :class="selectedIndividual?.verification === 'Verified' ? 'text-green-600' : 'text-slate-400'"
                                ></i>
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="text-sm font-semibold text-navy-900" x-text="doc.label"></p>
                                <p class="text-xs text-slate-400 mt-0.5" x-text="doc.required ? 'Required' : 'Conditional (sector-specific)'"></p>
                            </div>
                            <span
                                class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold flex-shrink-0"
                                :class="selectedIndividual?.verification === 'Verified'
                                    ? 'bg-green-100 text-green-700'
                                    : 'bg-slate-100 text-slate-500'"
                            >
                                <template x-if="selectedIndividual?.verification === 'Verified'">
                                    <i data-lucide="circle-check" class="w-3.5 h-3.5"></i>
                                </template>
                                <template x-if="selectedIndividual?.verification !== 'Verified'">
                                    <i data-lucide="circle-dashed" class="w-3.5 h-3.5"></i>
                                </template>
                                <span x-text="selectedIndividual?.verification === 'Verified' ? 'Submitted' : 'Missing'"></span>
                            </span>
                        </div>
                    </template>
                </template>

                <button
                    @click="$dispatch('toast', {message: 'Document upload feature — connect to document management module.', variant: 'info'})"
                    class="w-full mt-2 flex items-center justify-center gap-2 px-4 py-3 rounded-xl border-2 border-dashed border-slate-200 text-sm text-slate-500 hover:border-brand-400 hover:text-brand-600 hover:bg-brand-50 transition-colors"
                >
                    <i data-lucide="upload" class="w-4 h-4"></i>
                    Upload Document
                </button>

            </div>{{-- /Documents --}}


            {{-- ── TAB 5: History ── --}}
            <div x-show="individualTab === 'History'" class="space-y-4">

                <div class="bg-white rounded-xl border border-slate-200 shadow-card divide-y divide-slate-100">

                    <div class="p-4 flex items-center gap-4">
                        <div class="w-9 h-9 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
                            <i data-lucide="user-plus" class="w-4 h-4 text-blue-600"></i>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="text-sm font-semibold text-navy-900">Record Created</p>
                            <p class="text-xs text-slate-500 mt-0.5">
                                Resident profile encoded into the system.
                                Encoded by: <span class="font-medium text-slate-700">System</span>
                            </p>
                        </div>
                        <p class="text-xs text-slate-400 flex-shrink-0" x-text="selectedIndividual?.created || '—'"></p>
                    </div>

                    <div class="p-4 flex items-center gap-4">
                        <div class="w-9 h-9 rounded-full bg-amber-100 flex items-center justify-center flex-shrink-0">
                            <i data-lucide="pencil" class="w-4 h-4 text-amber-600"></i>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="text-sm font-semibold text-navy-900">Last Updated</p>
                            <p class="text-xs text-slate-500 mt-0.5">
                                Profile data last modified.
                                Updated by: <span class="font-medium text-slate-700">System</span>
                            </p>
                        </div>
                        <p class="text-xs text-slate-400 flex-shrink-0" x-text="selectedIndividual?.last_updated || '—'"></p>
                    </div>

                    <div class="p-4 flex items-center gap-4">
                        <div class="w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0"
                            :class="selectedIndividual?.verification === 'Verified' ? 'bg-green-100' : 'bg-slate-100'"
                        >
                            <i data-lucide="shield-check" class="w-4 h-4"
                                :class="selectedIndividual?.verification === 'Verified' ? 'text-green-600' : 'text-slate-400'"
                            ></i>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="text-sm font-semibold text-navy-900">Verification Status</p>
                            <p class="text-xs text-slate-500 mt-0.5">
                                Current verification level:
                                <span class="font-medium text-slate-700" x-text="selectedIndividual?.verification"></span>
                            </p>
                        </div>
                        <span
                            class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold"
                            :class="verificationBadge(selectedIndividual?.verification)"
                            x-text="selectedIndividual?.verification"
                        ></span>
                    </div>

                    <div class="p-4 flex items-center gap-4">
                        <div class="w-9 h-9 rounded-full bg-violet-100 flex items-center justify-center flex-shrink-0">
                            <i data-lucide="chart-bar" class="w-4 h-4 text-violet-600"></i>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="text-sm font-semibold text-navy-900">Profile Completion</p>
                            <p class="text-xs text-slate-500 mt-0.5">
                                Current profile completeness score.
                            </p>
                        </div>
                        <div class="flex items-center gap-2">
                            <div class="w-16 h-1.5 rounded-full bg-slate-100 overflow-hidden">
                                <div
                                    class="h-full rounded-full transition-all duration-500"
                                    :class="completionColor(selectedIndividual?.profile_pct)"
                                    :style="'width:' + (selectedIndividual?.profile_pct || 0) + '%'"
                                ></div>
                            </div>
                            <span
                                class="text-xs font-bold"
                                :class="completionTextColor(selectedIndividual?.profile_pct)"
                                x-text="(selectedIndividual?.profile_pct || 0) + '%'"
                            ></span>
                        </div>
                    </div>

                </div>

                {{-- Audit log placeholder --}}
                <div class="bg-slate-50 rounded-xl border border-dashed border-slate-200 p-5 text-center">
                    <i data-lucide="clock-2" class="w-6 h-6 text-slate-300 mx-auto mb-2"></i>
                    <p class="text-xs text-slate-400">Full audit log available once activity tracking module is active.</p>
                </div>

            </div>{{-- /History --}}

        </div>{{-- /tab panels --}}


        {{-- ════════════════════════════════════════════════════════
             FOOTER ACTIONS
        ════════════════════════════════════════════════════════ --}}
        <div class="px-6 py-4 border-t border-slate-200 bg-white rounded-b-2xl flex items-center justify-between gap-3 flex-wrap">

            <button
                @click="showIndividualDetail = false"
                class="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg border border-slate-200 text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors"
            >
                <i data-lucide="x" class="w-4 h-4"></i>
                Close
            </button>

            <div class="flex items-center gap-2">

                {{-- Edit button --}}
                <button
                    @click="$dispatch('toast', {message: 'Edit resident — connect to edit modal.', variant: 'info'})"
                    class="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg border border-slate-200 text-sm font-medium text-slate-700 hover:bg-slate-50 transition-colors"
                    x-show="can('individuals','update')"
                >
                    <i data-lucide="pencil" class="w-4 h-4"></i>
                    Edit
                </button>

                {{-- Lifecycle dropdown --}}
                <div class="relative" x-data="{ lopen: false }" x-show="can('individuals','manage_lifecycle')">
                    <button
                        @click="lopen = !lopen"
                        class="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-navy-900 text-white text-sm font-medium hover:bg-navy-800 transition-colors"
                    >
                        <i data-lucide="settings-2" class="w-4 h-4"></i>
                        Lifecycle
                        <i data-lucide="chevron-down" class="w-3.5 h-3.5 ml-0.5" :class="lopen ? 'rotate-180' : ''" class="transition-transform"></i>
                    </button>

                    <div
                        x-show="lopen"
                        @click.outside="lopen = false"
                        x-transition:enter="transition ease-out duration-100"
                        x-transition:enter-start="opacity-0 scale-95 translate-y-1"
                        x-transition:enter-end="opacity-100 scale-100 translate-y-0"
                        x-transition:leave="transition ease-in duration-75"
                        x-transition:leave-start="opacity-100 scale-100 translate-y-0"
                        x-transition:leave-end="opacity-0 scale-95 translate-y-1"
                        class="absolute bottom-full right-0 mb-2 w-52 rounded-xl bg-white border border-slate-200 shadow-lg divide-y divide-slate-100 overflow-hidden z-50"
                        style="display:none"
                    >
                        <div class="py-1">
                            <button
                                @click="lopen=false; openLifecycle(selectedIndividual, 'Transfer'); showIndividualDetail=false"
                                class="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm text-slate-700 hover:bg-slate-50 transition-colors text-left"
                            >
                                <i data-lucide="arrow-right-from-line" class="w-4 h-4 text-indigo-400"></i>
                                Transfer Resident
                            </button>
                            <button
                                @click="lopen=false; openLifecycle(selectedIndividual, 'Deceased'); showIndividualDetail=false"
                                class="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm text-slate-700 hover:bg-slate-50 transition-colors text-left"
                            >
                                <i data-lucide="flower" class="w-4 h-4 text-slate-400"></i>
                                Mark as Deceased
                            </button>
                        </div>
                        <div class="py-1">
                            <button
                                @click="lopen=false; openLifecycle(selectedIndividual, 'Archive'); showIndividualDetail=false"
                                class="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm text-amber-600 hover:bg-amber-50 transition-colors text-left"
                            >
                                <i data-lucide="archive" class="w-4 h-4"></i>
                                Archive Record
                            </button>
                        </div>
                    </div>
                </div>

            </div>
        </div>

    </x-ui.modal>
</div>
