{{-- modal-merge.blade.php — Duplicate Merge Review Modal --}}
{{-- Rendered inside constituents.blade.php Alpine x-data scope --}}
{{-- Open state bound to: showMerge --}}

<div x-data="{
    get open() { return showMerge },
    set open(v) { showMerge = v },

    /* Which record to keep per field: 'A' or 'B' */
    fieldChoices: {
        name:                'A',
        barangay:            'A',
        date_of_birth:       'A',
        contact:             'A',
        household:           'A',
        verification_status: 'A',
    },

    /* Reset choices when modal opens */
    resetChoices() {
        this.fieldChoices = {
            name:                'A',
            barangay:            'A',
            date_of_birth:       'A',
            contact:             'A',
            household:           'A',
            verification_status: 'A',
        };
    },

    merging: false,
    confirmMerge() {
        if (this.merging) return;
        this.merging = true;
        setTimeout(() => {
            this.merging = false;
            this.open = false;
            this.$dispatch('toast', { message: 'Records merged successfully. Secondary record has been archived.', variant: 'success' });
        }, 900);
    },
}">
    <x-ui.modal maxWidth="2xl">

        {{-- ── MODAL HEADER ────────────────────────────────────────────────── --}}
        <div class="flex items-start justify-between gap-4 p-6 pb-4 border-b border-slate-100">
            <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 mb-1">
                    <span class="flex items-center justify-center w-7 h-7 rounded-lg bg-rose-100">
                        <i data-lucide="git-merge" class="w-4 h-4 text-rose-600"></i>
                    </span>
                    <h2 class="text-base font-bold text-navy-900 tracking-tight">
                        Duplicate Review &mdash; Merge Preview
                    </h2>
                    <span class="ml-1 inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider text-rose-700 bg-rose-100 ring-1 ring-rose-200">
                        Irreversible
                    </span>
                </div>
                <p class="text-xs text-slate-500 mt-0.5 max-w-2xl">
                    Review both records side-by-side and choose which fields to keep before merging.
                    The secondary record will be permanently archived after the merge is confirmed.
                </p>
            </div>

            {{-- Close X --}}
            <button
                @click="showMerge = false"
                class="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition shrink-0"
                aria-label="Cancel merge and close"
            >
                <i data-lucide="x" class="w-5 h-5"></i>
            </button>
        </div>

        {{-- ── MODAL BODY ──────────────────────────────────────────────────── --}}
        <div class="p-6 space-y-6 overflow-y-auto max-h-[65vh]"
             x-init="$watch('showMerge', v => { if (v) resetChoices() })"
        >

            {{-- ── RECORD HEADERS (side-by-side) ──────────────────────────── --}}
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">

                {{-- Record A (Primary) --}}
                <div class="rounded-xl border-2 border-brand-300 bg-brand-50/40 p-4">
                    <div class="flex items-center gap-2 mb-3">
                        <span class="flex items-center justify-center w-6 h-6 rounded-full bg-brand-600 text-white text-xs font-bold shrink-0">A</span>
                        <span class="text-xs font-bold text-brand-700 uppercase tracking-wider">Record A — Primary</span>
                        <span class="ml-auto inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-semibold bg-brand-100 text-brand-700 ring-1 ring-brand-200">Keep</span>
                    </div>
                    <p class="text-sm font-bold text-navy-900" x-text="selectedDQIssue?.record_name || '—'"></p>
                    <p class="text-xs font-mono text-slate-500 mt-0.5" x-text="selectedDQIssue?.record_id || '—'"></p>
                    <div class="mt-3 pt-3 border-t border-brand-200">
                        <div class="flex items-center gap-1.5 text-[11px] text-brand-600">
                            <i data-lucide="shield-check" class="w-3 h-3"></i>
                            This record will be retained as the canonical entry.
                        </div>
                    </div>
                </div>

                {{-- Record B (Suspected Duplicate) --}}
                <div class="rounded-xl border-2 border-rose-200 bg-rose-50/30 p-4">
                    <div class="flex items-center gap-2 mb-3">
                        <span class="flex items-center justify-center w-6 h-6 rounded-full bg-rose-500 text-white text-xs font-bold shrink-0">B</span>
                        <span class="text-xs font-bold text-rose-700 uppercase tracking-wider">Record B — Suspected Duplicate</span>
                        <span class="ml-auto inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-semibold bg-rose-100 text-rose-700 ring-1 ring-rose-200">Archive</span>
                    </div>
                    <p class="text-sm font-bold text-navy-900" x-text="selectedDQIssue?.merge_candidate?.name || '—'"></p>
                    <p class="text-xs font-mono text-slate-500 mt-0.5" x-text="selectedDQIssue?.merge_candidate?.record_id || '—'"></p>

                    {{-- Confidence bar --}}
                    <div class="mt-3 pt-3 border-t border-rose-200 space-y-1.5">
                        <div class="flex items-center justify-between text-[11px]">
                            <span class="text-rose-600 font-semibold flex items-center gap-1">
                                <i data-lucide="percent" class="w-3 h-3"></i> Match Confidence
                            </span>
                            <span
                                class="font-bold tabular-nums text-rose-700"
                                x-text="(selectedDQIssue?.merge_candidate?.confidence || 0) + '%'"
                            ></span>
                        </div>
                        <div class="w-full h-2 bg-rose-100 rounded-full overflow-hidden">
                            <div
                                class="h-full rounded-full transition-all duration-700"
                                :class="(selectedDQIssue?.merge_candidate?.confidence || 0) >= 85 ? 'bg-rose-500' : 'bg-amber-400'"
                                :style="'width:' + (selectedDQIssue?.merge_candidate?.confidence || 0) + '%'"
                            ></div>
                        </div>
                    </div>
                </div>
            </div>

            {{-- ── FIELD COMPARISON TABLE ───────────────────────────────────── --}}
            <div>
                <h3 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3 flex items-center gap-2">
                    <i data-lucide="columns-2" class="w-3.5 h-3.5"></i>
                    Field-by-Field Comparison — Select Which Value to Keep
                </h3>

                <div class="rounded-xl overflow-hidden border border-slate-200">
                    <table class="min-w-full text-sm">
                        <thead class="bg-slate-50 border-b border-slate-200">
                            <tr>
                                <th class="px-4 py-2.5 text-left text-[11px] font-semibold text-slate-500 uppercase tracking-wider w-36">Field</th>
                                <th class="px-4 py-2.5 text-left text-[11px] font-semibold text-brand-600 uppercase tracking-wider">
                                    <span class="flex items-center gap-1.5">
                                        <span class="w-4 h-4 rounded-full bg-brand-600 text-white text-[9px] font-bold flex items-center justify-center">A</span>
                                        Record A (Primary)
                                    </span>
                                </th>
                                <th class="px-4 py-2.5 text-left text-[11px] font-semibold text-rose-600 uppercase tracking-wider">
                                    <span class="flex items-center gap-1.5">
                                        <span class="w-4 h-4 rounded-full bg-rose-500 text-white text-[9px] font-bold flex items-center justify-center">B</span>
                                        Record B (Duplicate)
                                    </span>
                                </th>
                                <th class="px-4 py-2.5 text-center text-[11px] font-semibold text-slate-500 uppercase tracking-wider w-28">Keep</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100 bg-white">

                            {{-- Row macro: name --}}
                            <tr class="even:bg-slate-50/50 hover:bg-brand-50/30 transition-colors group">
                                <td class="px-4 py-3 text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Full Name</td>
                                <td class="px-4 py-3">
                                    <span
                                        class="text-sm font-medium transition-colors"
                                        :class="fieldChoices.name === 'A' ? 'text-navy-900' : 'text-slate-400 line-through'"
                                        x-text="selectedDQIssue?.record_name || '—'"
                                    ></span>
                                </td>
                                <td class="px-4 py-3">
                                    <span
                                        class="text-sm font-medium transition-colors"
                                        :class="fieldChoices.name === 'B' ? 'text-navy-900' : 'text-slate-400 line-through'"
                                        x-text="selectedDQIssue?.merge_candidate?.name || '—'"
                                    ></span>
                                </td>
                                <td class="px-4 py-3">
                                    <div class="flex items-center justify-center gap-3">
                                        <label class="flex items-center gap-1 cursor-pointer" title="Keep Record A value">
                                            <input type="radio" name="merge_name" value="A" x-model="fieldChoices.name" class="w-3.5 h-3.5 accent-brand-600">
                                            <span class="text-[11px] font-semibold text-brand-700">A</span>
                                        </label>
                                        <label class="flex items-center gap-1 cursor-pointer" title="Keep Record B value">
                                            <input type="radio" name="merge_name" value="B" x-model="fieldChoices.name" class="w-3.5 h-3.5 accent-rose-500">
                                            <span class="text-[11px] font-semibold text-rose-600">B</span>
                                        </label>
                                    </div>
                                </td>
                            </tr>

                            {{-- Row: barangay --}}
                            <tr class="even:bg-slate-50/50 hover:bg-brand-50/30 transition-colors group">
                                <td class="px-4 py-3 text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Barangay</td>
                                <td class="px-4 py-3">
                                    <span
                                        class="text-sm font-medium transition-colors"
                                        :class="fieldChoices.barangay === 'A' ? 'text-navy-900' : 'text-slate-400 line-through'"
                                        x-text="selectedDQIssue?.barangay || '—'"
                                    ></span>
                                </td>
                                <td class="px-4 py-3">
                                    <span class="text-sm font-medium text-slate-400" x-text="selectedDQIssue?.barangay || '—'"></span>
                                    <span class="ml-1 text-[10px] text-slate-400">(same)</span>
                                </td>
                                <td class="px-4 py-3">
                                    <div class="flex items-center justify-center gap-3">
                                        <label class="flex items-center gap-1 cursor-pointer">
                                            <input type="radio" name="merge_barangay" value="A" x-model="fieldChoices.barangay" class="w-3.5 h-3.5 accent-brand-600">
                                            <span class="text-[11px] font-semibold text-brand-700">A</span>
                                        </label>
                                        <label class="flex items-center gap-1 cursor-pointer">
                                            <input type="radio" name="merge_barangay" value="B" x-model="fieldChoices.barangay" class="w-3.5 h-3.5 accent-rose-500">
                                            <span class="text-[11px] font-semibold text-rose-600">B</span>
                                        </label>
                                    </div>
                                </td>
                            </tr>

                            {{-- Row: date of birth --}}
                            <tr class="even:bg-slate-50/50 hover:bg-brand-50/30 transition-colors group">
                                <td class="px-4 py-3 text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Date of Birth</td>
                                <td class="px-4 py-3">
                                    <span
                                        class="text-sm font-medium transition-colors"
                                        :class="fieldChoices.date_of_birth === 'A' ? 'text-navy-900' : 'text-slate-400 line-through'"
                                    >Jan 12, 1985</span>
                                </td>
                                <td class="px-4 py-3">
                                    <span
                                        class="text-sm font-medium transition-colors"
                                        :class="fieldChoices.date_of_birth === 'B' ? 'text-navy-900' : 'text-slate-400 line-through'"
                                    >
                                        Jan 12, 1985
                                        <span class="ml-1 text-[10px] text-slate-400">(same)</span>
                                    </span>
                                </td>
                                <td class="px-4 py-3">
                                    <div class="flex items-center justify-center gap-3">
                                        <label class="flex items-center gap-1 cursor-pointer">
                                            <input type="radio" name="merge_dob" value="A" x-model="fieldChoices.date_of_birth" class="w-3.5 h-3.5 accent-brand-600">
                                            <span class="text-[11px] font-semibold text-brand-700">A</span>
                                        </label>
                                        <label class="flex items-center gap-1 cursor-pointer">
                                            <input type="radio" name="merge_dob" value="B" x-model="fieldChoices.date_of_birth" class="w-3.5 h-3.5 accent-rose-500">
                                            <span class="text-[11px] font-semibold text-rose-600">B</span>
                                        </label>
                                    </div>
                                </td>
                            </tr>

                            {{-- Row: contact --}}
                            <tr class="even:bg-slate-50/50 hover:bg-brand-50/30 transition-colors group">
                                <td class="px-4 py-3 text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Contact No.</td>
                                <td class="px-4 py-3">
                                    <span
                                        class="text-sm font-medium font-mono transition-colors"
                                        :class="fieldChoices.contact === 'A' ? 'text-navy-900' : 'text-slate-400 line-through'"
                                    >0912-345-6789</span>
                                </td>
                                <td class="px-4 py-3">
                                    <span
                                        class="text-sm font-medium font-mono transition-colors"
                                        :class="fieldChoices.contact === 'B' ? 'text-navy-900' : 'text-slate-400 line-through'"
                                    >0998-765-4321</span>
                                    <span class="ml-1 inline-flex items-center px-1 rounded text-[9px] font-semibold bg-amber-100 text-amber-700 ring-1 ring-amber-200">DIFF</span>
                                </td>
                                <td class="px-4 py-3">
                                    <div class="flex items-center justify-center gap-3">
                                        <label class="flex items-center gap-1 cursor-pointer">
                                            <input type="radio" name="merge_contact" value="A" x-model="fieldChoices.contact" class="w-3.5 h-3.5 accent-brand-600">
                                            <span class="text-[11px] font-semibold text-brand-700">A</span>
                                        </label>
                                        <label class="flex items-center gap-1 cursor-pointer">
                                            <input type="radio" name="merge_contact" value="B" x-model="fieldChoices.contact" class="w-3.5 h-3.5 accent-rose-500">
                                            <span class="text-[11px] font-semibold text-rose-600">B</span>
                                        </label>
                                    </div>
                                </td>
                            </tr>

                            {{-- Row: household --}}
                            <tr class="even:bg-slate-50/50 hover:bg-brand-50/30 transition-colors group">
                                <td class="px-4 py-3 text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Household</td>
                                <td class="px-4 py-3">
                                    <span
                                        class="text-sm font-medium transition-colors"
                                        :class="fieldChoices.household === 'A' ? 'text-navy-900' : 'text-slate-400 line-through'"
                                    >HH-2024-00814</span>
                                </td>
                                <td class="px-4 py-3">
                                    <span
                                        class="text-sm font-medium transition-colors"
                                        :class="fieldChoices.household === 'B' ? 'text-navy-900' : 'text-slate-400 line-through'"
                                    >
                                        HH-2024-00814
                                        <span class="ml-1 text-[10px] text-slate-400">(same)</span>
                                    </span>
                                </td>
                                <td class="px-4 py-3">
                                    <div class="flex items-center justify-center gap-3">
                                        <label class="flex items-center gap-1 cursor-pointer">
                                            <input type="radio" name="merge_household" value="A" x-model="fieldChoices.household" class="w-3.5 h-3.5 accent-brand-600">
                                            <span class="text-[11px] font-semibold text-brand-700">A</span>
                                        </label>
                                        <label class="flex items-center gap-1 cursor-pointer">
                                            <input type="radio" name="merge_household" value="B" x-model="fieldChoices.household" class="w-3.5 h-3.5 accent-rose-500">
                                            <span class="text-[11px] font-semibold text-rose-600">B</span>
                                        </label>
                                    </div>
                                </td>
                            </tr>

                            {{-- Row: verification status --}}
                            <tr class="even:bg-slate-50/50 hover:bg-brand-50/30 transition-colors group">
                                <td class="px-4 py-3 text-[11px] font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Verification</td>
                                <td class="px-4 py-3">
                                    <span
                                        class="transition-opacity"
                                        :class="fieldChoices.verification_status === 'A' ? 'opacity-100' : 'opacity-30'"
                                    >
                                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200">
                                            Verified
                                        </span>
                                    </span>
                                </td>
                                <td class="px-4 py-3">
                                    <span
                                        class="transition-opacity"
                                        :class="fieldChoices.verification_status === 'B' ? 'opacity-100' : 'opacity-30'"
                                    >
                                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium bg-amber-50 text-amber-700 ring-1 ring-amber-200">
                                            Pending
                                        </span>
                                    </span>
                                    <span class="ml-1 inline-flex items-center px-1 rounded text-[9px] font-semibold bg-amber-100 text-amber-700 ring-1 ring-amber-200">DIFF</span>
                                </td>
                                <td class="px-4 py-3">
                                    <div class="flex items-center justify-center gap-3">
                                        <label class="flex items-center gap-1 cursor-pointer">
                                            <input type="radio" name="merge_verification" value="A" x-model="fieldChoices.verification_status" class="w-3.5 h-3.5 accent-brand-600">
                                            <span class="text-[11px] font-semibold text-brand-700">A</span>
                                        </label>
                                        <label class="flex items-center gap-1 cursor-pointer">
                                            <input type="radio" name="merge_verification" value="B" x-model="fieldChoices.verification_status" class="w-3.5 h-3.5 accent-rose-500">
                                            <span class="text-[11px] font-semibold text-rose-600">B</span>
                                        </label>
                                    </div>
                                </td>
                            </tr>

                        </tbody>
                    </table>
                </div>

                {{-- Table legend --}}
                <div class="flex flex-wrap items-center gap-4 mt-2.5 text-[11px] text-slate-500">
                    <span class="flex items-center gap-1">
                        <span class="inline-flex items-center px-1 rounded text-[9px] font-semibold bg-amber-100 text-amber-700 ring-1 ring-amber-200">DIFF</span>
                        Fields that differ between records
                    </span>
                    <span class="flex items-center gap-1">
                        <i data-lucide="info" class="w-3 h-3"></i>
                        Strikethrough indicates the value that will be discarded
                    </span>
                </div>
            </div>

            {{-- ── WARNING BANNER ───────────────────────────────────────────── --}}
            <div class="flex items-start gap-3 p-4 rounded-xl bg-amber-50 border border-amber-200">
                <i data-lucide="triangle-alert" class="w-4 h-4 mt-0.5 shrink-0 text-amber-600"></i>
                <div class="min-w-0">
                    <p class="text-xs font-bold text-amber-800">This action is irreversible.</p>
                    <p class="text-xs text-amber-700 mt-0.5 leading-relaxed">
                        The secondary record (Record B) will be permanently archived after the merge is confirmed.
                        All linked transactions, service records, and program enrollments from Record B will be
                        transferred to Record A. This operation is logged and cannot be undone without contacting
                        the System Administrator.
                    </p>
                </div>
            </div>

        </div>

        {{-- ── MODAL FOOTER ────────────────────────────────────────────────── --}}
        <div class="flex flex-col-reverse sm:flex-row items-center justify-between gap-3 px-6 py-4 border-t border-slate-100 bg-slate-50/60 rounded-b-2xl">

            {{-- Left: Cancel --}}
            <button
                @click="showMerge = false" x-bind:disabled="merging"
                class="w-full sm:w-auto inline-flex items-center justify-center gap-1.5 px-4 py-2 text-xs font-medium rounded-lg border border-slate-200 text-slate-600 bg-white hover:bg-slate-50 transition disabled:opacity-50 disabled:pointer-events-none"
            >
                <i data-lucide="x" class="w-3.5 h-3.5"></i> Cancel
            </button>

            {{-- Right: Merge confirmation --}}
            <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-2 w-full sm:w-auto">
                <p class="text-[11px] text-slate-500 text-center sm:text-right hidden sm:block">
                    Merging <span class="font-semibold text-navy-900" x-text="selectedDQIssue?.record_name || 'record'"></span>
                    &rarr; canonical entry
                </p>
                <button
                    @click="confirmMerge()" x-bind:disabled="merging"
                    class="inline-flex items-center justify-center gap-1.5 px-5 py-2 text-xs font-bold rounded-lg bg-rose-600 text-white hover:bg-rose-700 active:bg-rose-800 transition shadow-md shadow-rose-200 shrink-0 disabled:opacity-70 disabled:pointer-events-none"
                >
                    <i data-lucide="loader-circle" class="w-3.5 h-3.5 animate-spin" x-show="merging" x-cloak></i>
                    <i data-lucide="git-merge" class="w-3.5 h-3.5" x-show="!merging"></i>
                    <span x-text="merging ? 'Merging…' : 'Proceed with Merge'"></span>
                </button>
            </div>

        </div>

    </x-ui.modal>
</div>
