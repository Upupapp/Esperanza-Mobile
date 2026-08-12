{{-- ============================================================
     FILE: view-individuals.blade.php
     Partial: Individuals table — rendered inside constituents.blade.php
     Alpine scope: parent x-data (filteredIndividuals, openIndividual, etc.)
     ============================================================ --}}

<div class="flex flex-col gap-4">

    {{-- ── Result count bar ── --}}
    <div class="flex items-center justify-between px-1">
        <p class="text-sm text-slate-500">
            Showing
            <span class="font-semibold text-navy-900" x-text="filteredIndividuals.length"></span>
            of
            <span class="font-semibold text-navy-900" x-text="individuals.length"></span>
            residents
        </p>
        <div class="flex items-center gap-2 text-xs text-slate-400">
            <i data-lucide="refresh-cw" class="w-3.5 h-3.5"></i>
            <span>Last synced: just now</span>
        </div>
    </div>

    {{-- ── Table card ── --}}
    <x-ui.table>
        <table class="w-full text-sm">
            <thead>
                <tr class="bg-slate-50 border-b border-slate-200">
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">
                        Resident
                    </th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap hidden sm:table-cell">
                        Barangay / Sitio
                    </th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap hidden md:table-cell">
                        Household
                    </th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap hidden lg:table-cell">
                        Verification
                    </th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap hidden lg:table-cell">
                        Profile
                    </th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">
                        Status
                    </th>
                    <th class="text-right px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                        Actions
                    </th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-50 bg-white">

                {{-- ── Empty state ── --}}
                <template x-if="filteredIndividuals.length === 0">
                    <tr>
                        <td colspan="7" class="py-16">
                            <div class="flex flex-col items-center gap-3 text-center px-8">
                                <div class="w-14 h-14 rounded-full bg-slate-100 flex items-center justify-center text-slate-400">
                                    <i data-lucide="users" class="w-7 h-7"></i>
                                </div>
                                <div>
                                    <p class="font-semibold text-navy-900 text-base">No residents found</p>
                                    <p class="text-sm text-slate-500 mt-0.5">
                                        Try adjusting your search filters, or add a new resident record.
                                    </p>
                                </div>
                                <template x-if="can('individuals','create')">
                                    <button
                                        @click="showAddIndividual = true"
                                        class="mt-1 inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-brand-600 text-white text-sm font-medium hover:bg-brand-700 transition-colors"
                                    >
                                        <i data-lucide="user-plus" class="w-4 h-4"></i>
                                        Add Resident
                                    </button>
                                </template>
                            </div>
                        </td>
                    </tr>
                </template>

                {{-- ── Individual rows ── --}}
                <template x-for="r in filteredIndividuals" :key="r.id">
                    <tr
                        class="hover:bg-slate-50/70 transition-colors cursor-pointer group"
                        @click="openIndividual(r)"
                    >

                        {{-- Resident: avatar + name + ID + tags --}}
                        <td class="px-4 py-3">
                            <div class="flex items-start gap-3 min-w-0">
                                <div class="flex-shrink-0 relative">
                                    <div class="w-10 h-10 text-sm rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold ring-2 ring-white shadow-sm shrink-0" x-text="(r.name || '').split(/\s+/).filter(Boolean).map(w => w[0]).slice(0,2).join('').toUpperCase()"></div>
                                    {{-- Sex indicator dot --}}
                                    <span
                                        class="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 rounded-full border-2 border-white flex items-center justify-center text-white"
                                        :class="r.sex === 'F' ? 'bg-pink-400' : 'bg-blue-400'"
                                        :title="r.sex === 'F' ? 'Female' : 'Male'"
                                    ></span>
                                </div>
                                <div class="min-w-0 flex-1">
                                    <p
                                        class="font-semibold text-navy-900 text-sm leading-tight truncate group-hover:text-brand-600 transition-colors"
                                        x-text="r.name"
                                    ></p>
                                    <p class="text-xs text-slate-400 mt-0.5" x-text="'ID: ' + r.id"></p>
                                    {{-- Tag chips --}}
                                    <div class="flex flex-wrap gap-1 mt-1.5">
                                        <template x-for="tag in (r.tags || [])" :key="tag">
                                            <span
                                                class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-semibold tracking-wide uppercase"
                                                :class="{
                                                    'bg-amber-100 text-amber-700': tag === 'senior' || tag === 'osca',
                                                    'bg-blue-100 text-blue-700': tag === 'pwd',
                                                    'bg-green-100 text-green-700': tag === 'youth',
                                                    'bg-violet-100 text-violet-700': tag === 'child',
                                                    'bg-orange-100 text-orange-700': tag === 'osy',
                                                    'bg-cyan-100 text-cyan-700': tag === '4ps',
                                                    'bg-rose-100 text-rose-700': tag === 'solo_parent',
                                                    'bg-lime-100 text-lime-700': tag === 'farmer',
                                                    'bg-red-100 text-red-700': tag === 'high_risk',
                                                }"
                                                x-text="tag === 'solo_parent' ? 'Solo Parent' : tag === 'high_risk' ? 'High Risk' : tag.toUpperCase()"
                                            ></span>
                                        </template>
                                    </div>
                                </div>
                            </div>
                        </td>

                        {{-- Barangay / Sitio --}}
                        <td class="px-4 py-3 hidden sm:table-cell">
                            <div class="min-w-0">
                                <p class="text-sm font-medium text-slate-800 truncate" x-text="'Brgy. ' + r.barangay"></p>
                                <p class="text-xs text-slate-400 mt-0.5 truncate" x-text="r.sitio ? 'Sitio ' + r.sitio : '—'"></p>
                            </div>
                        </td>

                        {{-- Household / Family --}}
                        <td class="px-4 py-3 hidden md:table-cell">
                            <div class="min-w-0">
                                <p class="text-xs text-slate-600 font-medium">
                                    HH: <span class="text-slate-800 font-semibold" x-text="r.household_id || '—'"></span>
                                </p>
                                <p class="text-xs text-slate-400 mt-0.5">
                                    Fam: <span x-text="r.family_id || '—'"></span>
                                </p>
                                <p
                                    class="text-[10px] font-semibold uppercase text-slate-500 mt-1 bg-slate-100 rounded px-1 py-0.5 inline-block"
                                    x-text="r.relation || 'Member'"
                                ></p>
                            </div>
                        </td>

                        {{-- Verification badge --}}
                        <td class="px-4 py-3 hidden lg:table-cell">
                            <span
                                class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold"
                                :class="verificationBadge(r.verification)"
                            >
                                <template x-if="r.verification === 'Verified'">
                                    <i data-lucide="shield-check" class="w-3 h-3"></i>
                                </template>
                                <template x-if="r.verification === 'Pending'">
                                    <i data-lucide="clock" class="w-3 h-3"></i>
                                </template>
                                <template x-if="r.verification === 'Unverified'">
                                    <i data-lucide="shield-x" class="w-3 h-3"></i>
                                </template>
                                <template x-if="r.verification === 'For Validation'">
                                    <i data-lucide="search" class="w-3 h-3"></i>
                                </template>
                                <span x-text="r.verification"></span>
                            </span>
                        </td>

                        {{-- Profile completion --}}
                        <td class="px-4 py-3 hidden lg:table-cell">
                            <div class="flex items-center gap-2">
                                <div class="w-16 h-1.5 rounded-full bg-slate-100 overflow-hidden">
                                    <div
                                        class="h-full rounded-full transition-all duration-500"
                                        :class="completionColor(r.profile_pct)"
                                        :style="'width:' + r.profile_pct + '%'"
                                    ></div>
                                </div>
                                <span
                                    class="text-xs font-semibold tabular-nums"
                                    :class="completionTextColor(r.profile_pct)"
                                    x-text="r.profile_pct + '%'"
                                ></span>
                            </div>
                        </td>

                        {{-- Status badge --}}
                        <td class="px-4 py-3">
                            <span
                                class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold"
                                :class="statusBadge(r.status)"
                                x-text="r.status"
                            ></span>
                        </td>

                        {{-- Actions: 3-dot dropdown --}}
                        <td class="px-4 py-3 text-right" @click.stop>
                            <div class="relative inline-block" x-data="{ open: false }">
                                <button
                                    @click="open = !open"
                                    class="w-8 h-8 rounded-lg flex items-center justify-center text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors focus:outline-none focus:ring-2 focus:ring-brand-400 focus:ring-offset-1"
                                    :aria-expanded="open"
                                    aria-haspopup="true"
                                    title="More actions"
                                >
                                    <i data-lucide="ellipsis" class="w-4 h-4"></i>
                                </button>

                                {{-- Dropdown --}}
                                <div
                                    x-show="open"
                                    @click.outside="open = false"
                                    x-transition:enter="transition ease-out duration-100"
                                    x-transition:enter-start="opacity-0 scale-95 translate-y-1"
                                    x-transition:enter-end="opacity-100 scale-100 translate-y-0"
                                    x-transition:leave="transition ease-in duration-75"
                                    x-transition:leave-start="opacity-100 scale-100 translate-y-0"
                                    x-transition:leave-end="opacity-0 scale-95 translate-y-1"
                                    class="absolute right-0 z-50 mt-1 w-52 rounded-xl bg-white border border-slate-200 shadow-lg shadow-slate-200/60 divide-y divide-slate-100 overflow-hidden"
                                    style="display:none"
                                >
                                    {{-- View Details --}}
                                    <div class="py-1">
                                        <button
                                            @click="open=false; openIndividual(r)"
                                            class="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm text-slate-700 hover:bg-slate-50 hover:text-navy-900 transition-colors text-left"
                                        >
                                            <i data-lucide="eye" class="w-4 h-4 text-slate-400"></i>
                                            View Details
                                        </button>
                                    </div>

                                    {{-- Lifecycle actions --}}
                                    <div class="py-1">
                                        <button
                                            @click="open=false; openLifecycle(r, 'Transfer')"
                                            class="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm text-slate-700 hover:bg-slate-50 hover:text-navy-900 transition-colors text-left"
                                            x-show="can('individuals','transfer')"
                                        >
                                            <i data-lucide="arrow-right-from-line" class="w-4 h-4 text-indigo-400"></i>
                                            Transfer Resident
                                        </button>
                                        <button
                                            @click="open=false; openLifecycle(r, 'Deceased')"
                                            class="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm text-slate-700 hover:bg-slate-50 hover:text-navy-900 transition-colors text-left"
                                            x-show="can('individuals','mark_deceased')"
                                        >
                                            <i data-lucide="flower" class="w-4 h-4 text-slate-400"></i>
                                            Mark as Deceased
                                        </button>
                                    </div>

                                    {{-- Archive / Restore --}}
                                    <div class="py-1">
                                        <template x-if="r.status !== 'Archived'">
                                            <button
                                                @click="open=false; openLifecycle(r, 'Archive')"
                                                class="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm text-amber-600 hover:bg-amber-50 transition-colors text-left"
                                                x-show="can('individuals','archive')"
                                            >
                                                <i data-lucide="archive" class="w-4 h-4"></i>
                                                Archive Record
                                            </button>
                                        </template>
                                        <template x-if="r.status === 'Archived'">
                                            <button
                                                @click="open=false; openLifecycle(r, 'Restore')"
                                                class="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm text-emerald-600 hover:bg-emerald-50 transition-colors text-left"
                                                x-show="can('individuals','restore')"
                                            >
                                                <i data-lucide="refresh-cw" class="w-4 h-4"></i>
                                                Restore Record
                                            </button>
                                        </template>
                                    </div>
                                </div>
                            </div>

                            {{-- Chevron for row tap on mobile --}}
                            <button
                                @click="openIndividual(r)"
                                class="ml-1 w-8 h-8 rounded-lg flex items-center justify-center text-slate-300 hover:text-brand-500 hover:bg-slate-100 transition-colors sm:hidden"
                                title="Open details"
                            >
                                <i data-lucide="chevron-right" class="w-4 h-4"></i>
                            </button>
                        </td>

                    </tr>
                </template>

            </tbody>
        </table>
    </x-ui.table>

</div>
