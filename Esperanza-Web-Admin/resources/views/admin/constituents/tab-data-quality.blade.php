{{-- tab-data-quality.blade.php — Data Quality Management Tab --}}
{{-- Rendered inside constituents.blade.php Alpine x-data scope --}}

@php
    $totalIssues    = count($qualityIssues);
    $criticalHigh   = collect($qualityIssues)->whereIn('severity', ['Critical','High'])->count();
    $inReview       = collect($qualityIssues)->where('status', 'In Review')->count();
@endphp

<div class="space-y-6">

    {{-- ── SUMMARY STAT CARDS ─────────────────────────────────────────────── --}}
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <x-ui.stat-card
            label="Open Issues"
            value="{{ $totalIssues }}"
            icon="circle-alert"
            color="orange"
            :delay="0"
        />
        <x-ui.stat-card
            label="Critical / High"
            value="{{ $criticalHigh }}"
            icon="flame"
            color="red"
            :delay="75"
        />
        <x-ui.stat-card
            label="In Review"
            value="{{ $inReview }}"
            icon="search"
            color="brand"
            :delay="150"
        />
        <x-ui.stat-card
            label="Resolved This Month"
            value="2"
            icon="circle-check"
            color="green"
            sublabel="Keep up the pace"
            :delay="225"
        />
    </div>

    {{-- ── FILTER BAR ──────────────────────────────────────────────────────── --}}
    <x-ui.card class="px-5 py-4">
        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">

            {{-- Search --}}
            <div class="relative flex-1 min-w-0">
                <span class="absolute inset-y-0 left-3 flex items-center pointer-events-none text-slate-400">
                    <i data-lucide="search" class="w-3.5 h-3.5"></i>
                </span>
                <input
                    type="text"
                    x-model="search"
                    placeholder="Search by name, record ID, barangay…"
                    class="w-full pl-8 pr-4 py-2 text-sm rounded-lg border border-slate-200 bg-white placeholder-slate-400 text-navy-900 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition"
                />
            </div>

            {{-- Type filter --}}
            <div class="relative">
                <span class="absolute inset-y-0 left-3 flex items-center pointer-events-none text-slate-400">
                    <i data-lucide="tag" class="w-3.5 h-3.5"></i>
                </span>
                <select
                    x-model="dqTypeFilter"
                    class="pl-8 pr-8 py-2 text-sm rounded-lg border border-slate-200 bg-white text-navy-900 appearance-none focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition cursor-pointer"
                >
                    <option value="">All Types</option>
                    <option value="Duplicate Suspected">Duplicate Suspected</option>
                    <option value="Orphaned Record">Orphaned Record</option>
                    <option value="Incomplete Profile">Incomplete Profile</option>
                    <option value="Missing Documents">Missing Documents</option>
                    <option value="Stale Record">Stale Record</option>
                    <option value="Address Mismatch">Address Mismatch</option>
                </select>
                <span class="absolute inset-y-0 right-3 flex items-center pointer-events-none text-slate-400">
                    <i data-lucide="chevron-down" class="w-3.5 h-3.5"></i>
                </span>
            </div>

            {{-- Status filter --}}
            <div class="relative">
                <span class="absolute inset-y-0 left-3 flex items-center pointer-events-none text-slate-400">
                    <i data-lucide="list-filter" class="w-3.5 h-3.5"></i>
                </span>
                <select
                    x-model="dqStatusFilter"
                    class="pl-8 pr-8 py-2 text-sm rounded-lg border border-slate-200 bg-white text-navy-900 appearance-none focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition cursor-pointer"
                >
                    <option value="">All Statuses</option>
                    <option value="Open">Open</option>
                    <option value="In Review">In Review</option>
                    <option value="Resolved">Resolved</option>
                    <option value="Dismissed">Dismissed</option>
                </select>
                <span class="absolute inset-y-0 right-3 flex items-center pointer-events-none text-slate-400">
                    <i data-lucide="chevron-down" class="w-3.5 h-3.5"></i>
                </span>
            </div>

            {{-- Clear button --}}
            <button
                @click="search=''; dqTypeFilter=''; dqStatusFilter=''"
                x-show="search !== '' || dqTypeFilter !== '' || dqStatusFilter !== ''"
                x-cloak
                class="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-medium rounded-lg border border-slate-200 text-slate-600 bg-white hover:bg-slate-50 transition shrink-0"
                title="Clear all filters"
            >
                <i data-lucide="x" class="w-3.5 h-3.5"></i> Clear
            </button>

        </div>

        {{-- Result count --}}
        <div class="mt-3 pt-3 border-t border-slate-100 flex items-center justify-between">
            <p class="text-xs text-slate-500">
                Showing <span class="font-semibold text-navy-900" x-text="filteredQualityIssues.length"></span>
                <span x-text="filteredQualityIssues.length === 1 ? 'issue' : 'issues'"></span>
                <span x-show="search !== '' || dqTypeFilter !== '' || dqStatusFilter !== ''" x-cloak>
                    &mdash; filtered from <span class="font-semibold">{{ $totalIssues }}</span> total
                </span>
            </p>
            <button
                @click="$dispatch('toast',{message:'Data quality report exported.',variant:'info'})"
                class="inline-flex items-center gap-1.5 text-xs font-medium text-brand-600 hover:text-brand-700 transition"
            >
                <i data-lucide="download" class="w-3 h-3"></i> Export
            </button>
        </div>
    </x-ui.card>

    {{-- ── ISSUES TABLE ─────────────────────────────────────────────────────── --}}
    <x-ui.card class="overflow-hidden">
        <x-ui.table>
            <table class="min-w-full divide-y divide-slate-100 text-sm">
                <thead class="bg-slate-50">
                    <tr>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Issue ID</th>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Type</th>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Severity</th>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Barangay</th>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Record Name</th>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Assigned To</th>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Created</th>
                        <th class="px-4 py-3 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Status</th>
                        <th class="px-4 py-3 text-right text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-50 bg-white">

                    {{-- Alpine x-for loop over filteredQualityIssues --}}
                    <template x-for="issue in filteredQualityIssues" :key="issue.id">
                        <tr
                            @click="openDQIssue(issue)"
                            class="hover:bg-slate-50/80 transition-colors cursor-pointer group"
                        >
                            {{-- Issue ID --}}
                            <td class="px-4 py-3 whitespace-nowrap" @click.stop>
                                <span
                                    class="font-mono text-xs font-semibold text-navy-900"
                                    x-text="'#' + issue.id"
                                ></span>
                            </td>

                            {{-- Type chip --}}
                            <td class="px-4 py-3 whitespace-nowrap">
                                <span
                                    class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-medium ring-1"
                                    :class="{
                                        'text-rose-700 bg-rose-50 ring-rose-200':       issue.type === 'Duplicate Suspected',
                                        'text-orange-700 bg-orange-50 ring-orange-200': issue.type === 'Orphaned Record',
                                        'text-amber-700 bg-amber-50 ring-amber-200':    issue.type === 'Incomplete Profile',
                                        'text-indigo-700 bg-indigo-50 ring-indigo-200': issue.type === 'Missing Documents',
                                        'text-slate-600 bg-slate-50 ring-slate-200':    issue.type === 'Stale Record',
                                        'text-purple-700 bg-purple-50 ring-purple-200': issue.type === 'Address Mismatch',
                                    }"
                                    x-text="issue.type"
                                ></span>
                            </td>

                            {{-- Severity badge --}}
                            <td class="px-4 py-3 whitespace-nowrap">
                                <span
                                    class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold ring-1"
                                    :class="severityBadge(issue.severity)"
                                    x-text="issue.severity"
                                ></span>
                            </td>

                            {{-- Barangay --}}
                            <td class="px-4 py-3 whitespace-nowrap text-xs text-slate-700">
                                <span class="flex items-center gap-1.5">
                                    <i data-lucide="map-pin" class="w-3 h-3 text-slate-400 shrink-0"></i>
                                    <span x-text="issue.barangay"></span>
                                </span>
                            </td>

                            {{-- Record name --}}
                            <td class="px-4 py-3 whitespace-nowrap">
                                <div class="text-xs font-medium text-navy-900" x-text="issue.record_name"></div>
                                <div class="text-[10px] text-slate-400 font-mono" x-text="issue.record_id"></div>
                            </td>

                            {{-- Assigned to --}}
                            <td class="px-4 py-3 whitespace-nowrap">
                                <div class="flex items-center gap-2">
                                    <span
                                        class="w-5 h-5 rounded-full bg-slate-100 text-slate-600 text-[9px] font-bold flex items-center justify-center uppercase shrink-0"
                                        x-text="issue.assigned_to ? issue.assigned_to.charAt(0) : '?'"
                                    ></span>
                                    <span class="text-xs text-slate-700" x-text="issue.assigned_to || '—'"></span>
                                </div>
                            </td>

                            {{-- Created date --}}
                            <td class="px-4 py-3 whitespace-nowrap text-xs text-slate-500" x-text="issue.created"></td>

                            {{-- Status badge --}}
                            <td class="px-4 py-3 whitespace-nowrap">
                                <span
                                    class="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium ring-1"
                                    :class="{
                                        'text-rose-700 bg-rose-50 ring-rose-200':       issue.status === 'Open',
                                        'text-amber-700 bg-amber-50 ring-amber-200':    issue.status === 'In Review',
                                        'text-emerald-700 bg-emerald-50 ring-emerald-200': issue.status === 'Resolved',
                                        'text-slate-500 bg-slate-50 ring-slate-200':    issue.status === 'Dismissed',
                                    }"
                                    x-text="issue.status"
                                ></span>
                            </td>

                            {{-- Actions --}}
                            <td class="px-4 py-3 text-right whitespace-nowrap" @click.stop>
                                <div class="flex items-center justify-end gap-1.5">
                                    {{-- Review button --}}
                                    <button
                                        @click="openDQIssue(issue)"
                                        class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[11px] font-medium text-brand-700 bg-brand-50 hover:bg-brand-100 ring-1 ring-brand-200 transition"
                                        title="Open issue detail"
                                    >
                                        <i data-lucide="search" class="w-3 h-3"></i> Review
                                    </button>

                                    {{-- Compare & Merge (only for Duplicate Suspected) --}}
                                    <button
                                        x-show="issue.type === 'Duplicate Suspected' && issue.merge_candidate"
                                        @click="selectedDQIssue = issue; showMerge = true; $nextTick(() => window.renderIcons?.())"
                                        class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[11px] font-medium text-rose-700 bg-rose-50 hover:bg-rose-100 ring-1 ring-rose-200 transition"
                                        title="Compare records and merge"
                                    >
                                        <i data-lucide="git-merge" class="w-3 h-3"></i> Merge
                                    </button>
                                </div>
                            </td>
                        </tr>
                    </template>

                    {{-- Empty state --}}
                    <tr x-show="filteredQualityIssues.length === 0" x-cloak>
                        <td colspan="9" class="px-6 py-16 text-center">
                            <div class="flex flex-col items-center gap-3">
                                <div class="w-12 h-12 rounded-full bg-emerald-50 flex items-center justify-center">
                                    <i data-lucide="circle-check" class="w-6 h-6 text-emerald-500"></i>
                                </div>
                                <div>
                                    <p class="text-sm font-semibold text-navy-900">No issues found</p>
                                    <p class="text-xs text-slate-500 mt-1">
                                        <span x-show="search !== '' || dqTypeFilter !== '' || dqStatusFilter !== ''">
                                            No data quality issues match your current filters.
                                            <button @click="search=''; dqTypeFilter=''; dqStatusFilter=''" class="text-brand-600 underline hover:text-brand-700 ml-1">Clear filters</button>
                                        </span>
                                        <span x-show="search === '' && dqTypeFilter === '' && dqStatusFilter === ''">
                                            All data quality issues have been resolved.
                                        </span>
                                    </p>
                                </div>
                            </div>
                        </td>
                    </tr>

                </tbody>
            </table>
        </x-ui.table>

        {{-- Table footer --}}
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 px-5 py-3 border-t border-slate-100 bg-slate-50/50">
            <p class="text-xs text-slate-500">
                <span class="font-semibold text-navy-900" x-text="filteredQualityIssues.length"></span> issue(s) displayed
                &mdash; Click any row to view full issue detail
            </p>
            <div class="flex items-center gap-3 text-[11px] text-slate-400">
                <span class="flex items-center gap-1">
                    <span class="w-2 h-2 rounded-full bg-rose-400"></span> Open
                </span>
                <span class="flex items-center gap-1">
                    <span class="w-2 h-2 rounded-full bg-amber-400"></span> In Review
                </span>
                <span class="flex items-center gap-1">
                    <span class="w-2 h-2 rounded-full bg-emerald-400"></span> Resolved
                </span>
            </div>
        </div>
    </x-ui.card>

    {{-- ── INFO BANNER ──────────────────────────────────────────────────────── --}}
    <div class="flex items-start gap-3 p-4 rounded-xl bg-blue-50 border border-blue-200 text-sm text-blue-800">
        <i data-lucide="info" class="w-4 h-4 mt-0.5 shrink-0 text-blue-500"></i>
        <div>
            <p class="font-semibold">Data Quality Review Protocol</p>
            <p class="text-xs text-blue-700 mt-0.5">
                All Critical and High severity issues must be resolved within 5 business days per DILG MC 2023-012.
                Duplicate Suspected records require supervisor sign-off before merging.
                Contact the Data Management Officer for escalations.
            </p>
        </div>
    </div>

</div>
