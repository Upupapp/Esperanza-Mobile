{{-- modal-dq-detail.blade.php — Data Quality Issue Detail Modal --}}
{{-- Rendered inside constituents.blade.php Alpine x-data scope --}}
{{-- Open state bound to: showDQDetail --}}

<div x-data="{ get open() { return showDQDetail }, set open(v) { showDQDetail = v } }">
    <x-ui.modal maxWidth="xl">

        {{-- ── MODAL HEADER ────────────────────────────────────────────────── --}}
        <div class="flex items-start justify-between gap-4 p-6 pb-4 border-b border-slate-100">
            <div class="flex-1 min-w-0">

                {{-- Title row --}}
                <div class="flex flex-wrap items-center gap-2 mb-1.5">
                    <h2 class="text-base font-bold text-navy-900 tracking-tight">
                        Issue
                        <span x-text="selectedDQIssue ? '#' + selectedDQIssue.id : ''"></span>
                    </h2>

                    {{-- Type chip --}}
                    <span
                        class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-medium ring-1"
                        :class="{
                            'text-rose-700 bg-rose-50 ring-rose-200':       selectedDQIssue?.type === 'Duplicate Suspected',
                            'text-orange-700 bg-orange-50 ring-orange-200': selectedDQIssue?.type === 'Orphaned Record',
                            'text-amber-700 bg-amber-50 ring-amber-200':    selectedDQIssue?.type === 'Incomplete Profile',
                            'text-indigo-700 bg-indigo-50 ring-indigo-200': selectedDQIssue?.type === 'Missing Documents',
                            'text-slate-600 bg-slate-50 ring-slate-200':    selectedDQIssue?.type === 'Stale Record',
                            'text-purple-700 bg-purple-50 ring-purple-200': selectedDQIssue?.type === 'Address Mismatch',
                        }"
                        x-text="selectedDQIssue?.type"
                    ></span>

                    {{-- Severity badge --}}
                    <span
                        class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold ring-1"
                        :class="selectedDQIssue ? severityBadge(selectedDQIssue.severity) : ''"
                        x-text="selectedDQIssue?.severity"
                    ></span>
                </div>

                {{-- Meta row --}}
                <div class="flex flex-wrap items-center gap-3 text-xs text-slate-500">
                    <span class="flex items-center gap-1">
                        <i data-lucide="map-pin" class="w-3 h-3"></i>
                        <span x-text="selectedDQIssue?.barangay"></span>
                    </span>
                    <span class="text-slate-300">·</span>
                    <span class="flex items-center gap-1">
                        <i data-lucide="user" class="w-3 h-3"></i>
                        Assigned to <span class="font-medium text-slate-700 ml-1" x-text="selectedDQIssue?.assigned_to || 'Unassigned'"></span>
                    </span>
                    <span class="text-slate-300">·</span>
                    <span class="flex items-center gap-1">
                        <i data-lucide="calendar" class="w-3 h-3"></i>
                        Created <span class="font-medium text-slate-700 ml-1" x-text="selectedDQIssue?.created"></span>
                    </span>
                </div>
            </div>

            {{-- Close X --}}
            <button
                @click="showDQDetail = false"
                class="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition shrink-0"
                aria-label="Close modal"
            >
                <i data-lucide="x" class="w-5 h-5"></i>
            </button>
        </div>

        {{-- ── MODAL BODY ──────────────────────────────────────────────────── --}}
        <div class="p-6 space-y-5 overflow-y-auto max-h-[60vh]">

            {{-- ── SECTION 1: Record Context ──────────────────────────────── --}}
            <section>
                <h3 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3 flex items-center gap-2">
                    <i data-lucide="file-user" class="w-3.5 h-3.5"></i>
                    Record Context
                </h3>

                {{-- Highlighted record box --}}
                <div class="rounded-xl bg-navy-900/[0.03] border border-navy-900/10 p-4 space-y-3">
                    <div class="flex flex-wrap items-center gap-3">
                        <div class="flex items-center gap-2">
                            <span class="text-[11px] text-slate-500 font-medium">Record ID</span>
                            <code
                                class="px-2 py-0.5 rounded bg-slate-100 text-[11px] font-mono font-semibold text-navy-900"
                                x-text="selectedDQIssue?.record_id"
                            ></code>
                        </div>
                        <span class="text-slate-300">·</span>
                        <div class="flex items-center gap-2">
                            <span class="text-[11px] text-slate-500 font-medium">Record Name</span>
                            <span
                                class="text-sm font-semibold text-navy-900"
                                x-text="selectedDQIssue?.record_name"
                            ></span>
                        </div>
                    </div>

                    {{-- Description --}}
                    <div class="pt-3 border-t border-slate-200/60">
                        <p class="text-[11px] font-semibold text-slate-500 uppercase tracking-wider mb-1.5">Description</p>
                        <p
                            class="text-sm text-slate-700 leading-relaxed"
                            x-text="selectedDQIssue?.description || 'No description provided.'"
                        ></p>
                    </div>
                </div>
            </section>

            {{-- ── SECTION 2: Issue Details ────────────────────────────────── --}}
            <section>
                <h3 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3 flex items-center gap-2">
                    <i data-lucide="clipboard-list" class="w-3.5 h-3.5"></i>
                    Issue Details
                </h3>

                <div class="grid grid-cols-2 md:grid-cols-3 gap-px bg-slate-100 rounded-xl overflow-hidden border border-slate-100">

                    {{-- Type --}}
                    <div class="bg-white px-4 py-3">
                        <dt class="text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Type</dt>
                        <dd
                            class="text-xs font-semibold text-navy-900"
                            x-text="selectedDQIssue?.type"
                        ></dd>
                    </div>

                    {{-- Severity --}}
                    <div class="bg-white px-4 py-3">
                        <dt class="text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Severity</dt>
                        <dd>
                            <span
                                class="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-semibold ring-1"
                                :class="selectedDQIssue ? severityBadge(selectedDQIssue.severity) : ''"
                                x-text="selectedDQIssue?.severity"
                            ></span>
                        </dd>
                    </div>

                    {{-- Barangay --}}
                    <div class="bg-white px-4 py-3">
                        <dt class="text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Barangay</dt>
                        <dd
                            class="text-xs font-medium text-slate-700"
                            x-text="selectedDQIssue?.barangay"
                        ></dd>
                    </div>

                    {{-- Assigned To --}}
                    <div class="bg-white px-4 py-3">
                        <dt class="text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Assigned To</dt>
                        <dd class="flex items-center gap-1.5">
                            <span
                                class="w-5 h-5 rounded-full bg-brand-100 text-brand-700 text-[9px] font-bold flex items-center justify-center uppercase shrink-0"
                                x-text="selectedDQIssue?.assigned_to ? selectedDQIssue.assigned_to.charAt(0) : '?'"
                            ></span>
                            <span
                                class="text-xs font-medium text-slate-700"
                                x-text="selectedDQIssue?.assigned_to || 'Unassigned'"
                            ></span>
                        </dd>
                    </div>

                    {{-- Created --}}
                    <div class="bg-white px-4 py-3">
                        <dt class="text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Created</dt>
                        <dd
                            class="text-xs text-slate-700"
                            x-text="selectedDQIssue?.created"
                        ></dd>
                    </div>

                    {{-- Current Status --}}
                    <div class="bg-white px-4 py-3">
                        <dt class="text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Status</dt>
                        <dd>
                            <span
                                class="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium ring-1"
                                :class="{
                                    'text-rose-700 bg-rose-50 ring-rose-200':           selectedDQIssue?.status === 'Open',
                                    'text-amber-700 bg-amber-50 ring-amber-200':        selectedDQIssue?.status === 'In Review',
                                    'text-emerald-700 bg-emerald-50 ring-emerald-200':  selectedDQIssue?.status === 'Resolved',
                                    'text-slate-500 bg-slate-50 ring-slate-200':        selectedDQIssue?.status === 'Dismissed',
                                }"
                                x-text="selectedDQIssue?.status"
                            ></span>
                        </dd>
                    </div>

                </div>
            </section>

            {{-- ── SECTION 3: Merge Candidate (only if present) ────────────── --}}
            <section x-show="selectedDQIssue?.merge_candidate" x-cloak>
                <h3 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3 flex items-center gap-2">
                    <i data-lucide="git-merge" class="w-3.5 h-3.5 text-rose-500"></i>
                    Possible Duplicate Found
                </h3>

                <div class="rounded-xl border border-rose-200 bg-rose-50/50 p-4 space-y-4">

                    {{-- Candidate card --}}
                    <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
                        <div>
                            <p class="text-[11px] text-rose-600 font-semibold uppercase tracking-wider mb-1">
                                Suspected Duplicate Record
                            </p>
                            <p class="text-sm font-bold text-navy-900" x-text="selectedDQIssue?.merge_candidate?.name"></p>
                            <p class="text-xs text-slate-500 font-mono mt-0.5" x-text="selectedDQIssue?.merge_candidate?.record_id"></p>
                        </div>

                        {{-- Confidence indicator --}}
                        <div class="shrink-0 text-right">
                            <p class="text-[11px] text-slate-500 font-semibold uppercase tracking-wider mb-1">Match Confidence</p>
                            <div class="flex items-center gap-2">
                                <div class="w-24 h-2 bg-slate-200 rounded-full overflow-hidden">
                                    <div
                                        class="h-full rounded-full transition-all duration-500"
                                        :class="(selectedDQIssue?.merge_candidate?.confidence || 0) >= 85 ? 'bg-rose-500' : (selectedDQIssue?.merge_candidate?.confidence || 0) >= 60 ? 'bg-amber-400' : 'bg-slate-400'"
                                        :style="'width:' + (selectedDQIssue?.merge_candidate?.confidence || 0) + '%'"
                                    ></div>
                                </div>
                                <span
                                    class="text-sm font-bold tabular-nums"
                                    :class="(selectedDQIssue?.merge_candidate?.confidence || 0) >= 85 ? 'text-rose-700' : 'text-amber-600'"
                                    x-text="(selectedDQIssue?.merge_candidate?.confidence || 0) + '%'"
                                ></span>
                            </div>
                        </div>
                    </div>

                    {{-- Open merge review CTA --}}
                    <div class="pt-3 border-t border-rose-200 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
                        <p class="text-xs text-rose-700">
                            <i data-lucide="triangle-alert" class="w-3.5 h-3.5 inline -mt-0.5 mr-1"></i>
                            Both records require side-by-side review before merging. This action cannot be undone.
                        </p>
                        <button
                            @click="showMerge = true; showDQDetail = false; $nextTick(() => window.renderIcons?.())"
                            class="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-semibold rounded-lg bg-rose-600 text-white hover:bg-rose-700 transition shadow-sm shrink-0"
                        >
                            <i data-lucide="git-merge" class="w-3.5 h-3.5"></i>
                            Open Merge Review
                        </button>
                    </div>

                </div>
            </section>

        </div>

        {{-- ── MODAL FOOTER ────────────────────────────────────────────────── --}}
        <div class="flex flex-col-reverse sm:flex-row items-center justify-between gap-3 px-6 py-4 border-t border-slate-100 bg-slate-50/60 rounded-b-2xl">

            {{-- Left: Close --}}
            <button
                @click="showDQDetail = false"
                class="w-full sm:w-auto inline-flex items-center justify-center gap-1.5 px-4 py-2 text-xs font-medium rounded-lg border border-slate-200 text-slate-600 bg-white hover:bg-slate-50 transition"
            >
                <i data-lucide="x" class="w-3.5 h-3.5"></i> Close
            </button>

            {{-- Right: Action buttons --}}
            <div class="flex flex-wrap items-center justify-end gap-2 w-full sm:w-auto">

                {{-- Reassign --}}
                <button
                    @click="$dispatch('toast',{message:'Reassignment feature coming soon.',variant:'info'})"
                    class="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-medium rounded-lg border border-slate-200 text-slate-600 bg-white hover:bg-slate-50 transition"
                >
                    <i data-lucide="user-pen" class="w-3.5 h-3.5"></i> Reassign
                </button>

                {{-- Dismiss --}}
                <button
                    @click="showDQDetail = false; $dispatch('toast',{message:'Issue dismissed. It will no longer appear in the Open queue.',variant:'warning'})"
                    class="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-medium rounded-lg border border-amber-200 text-amber-700 bg-amber-50 hover:bg-amber-100 transition"
                >
                    <i data-lucide="ban" class="w-3.5 h-3.5"></i> Dismiss
                </button>

                {{-- Mark Resolved --}}
                <button
                    @click="showDQDetail = false; $dispatch('toast',{message:'Issue marked as resolved. Great work!',variant:'success'})"
                    class="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-semibold rounded-lg bg-emerald-600 text-white hover:bg-emerald-700 transition shadow-sm"
                >
                    <i data-lucide="circle-check" class="w-3.5 h-3.5"></i> Mark Resolved
                </button>

            </div>
        </div>

    </x-ui.modal>
</div>
