{{-- ============================================================
     FILE: modal-lifecycle.blade.php
     Partial: Lifecycle action confirmation modal
     Alpine scope: parent x-data (showLifecycle, lifecycleAction, selectedIndividual, etc.)
     ============================================================ --}}

<div
    x-data="{
        get open() { return showLifecycle; },
        set open(v) { showLifecycle = v; },

        form: {
            target_barangay: '',
            transfer_reason: '',
            effective_date: '',
            certifying_officer: '',
            date_of_passing: '',
            cause_of_death: '',
            informant_name: '',
            death_cert_ref: '',
            archive_reason: '',
        },

        resetLifecycleForm() {
            this.form = {
                target_barangay: '', transfer_reason: '', effective_date: '',
                certifying_officer: '', date_of_passing: '', cause_of_death: '',
                informant_name: '', death_cert_ref: '', archive_reason: '',
            };
        },

        confirmLifecycle() {
            this.open = false;
            this.resetLifecycleForm();
            $dispatch('toast', {
                message: 'Lifecycle action recorded: ' + lifecycleAction,
                variant: 'success'
            });
            window.renderIcons?.();
        },

        get actionConfig() {
            const cfg = {
                Transfer: {
                    color: 'indigo',
                    icon: 'arrow-right-from-line',
                    title: 'Transfer Resident',
                    desc: 'Move this resident to another barangay within Esperanza. A transfer record will be created and the record will be updated accordingly.',
                    confirmLabel: 'Confirm Transfer',
                },
                Deceased: {
                    color: 'slate',
                    icon: 'flower',
                    title: 'Mark as Deceased',
                    desc: 'Record the passing of this resident. The profile will be retained for historical reference and program reconciliation.',
                    confirmLabel: 'Record Passing',
                },
                Archive: {
                    color: 'amber',
                    icon: 'archive',
                    title: 'Archive Record',
                    desc: 'Archiving removes this record from active views but preserves all data for audit and compliance purposes. This action can be reversed.',
                    confirmLabel: 'Archive Record',
                },
                Restore: {
                    color: 'emerald',
                    icon: 'refresh-cw',
                    title: 'Restore Record',
                    desc: 'Restore this archived resident record to Active status. They will appear in all active views and program eligibility checks.',
                    confirmLabel: 'Restore to Active',
                },
            };
            return cfg[lifecycleAction] || cfg['Archive'];
        },
    }"
>
    <x-ui.modal maxWidth="sm">

        {{-- ════════════════════════════════════════════════════════
             DYNAMIC HEADER — color and icon change per action
        ════════════════════════════════════════════════════════ --}}
        <div
            class="px-6 pt-6 pb-5 rounded-t-2xl border-b border-slate-100 relative overflow-hidden"
            :class="{
                'bg-indigo-50': lifecycleAction === 'Transfer',
                'bg-slate-50': lifecycleAction === 'Deceased',
                'bg-amber-50': lifecycleAction === 'Archive',
                'bg-emerald-50': lifecycleAction === 'Restore',
                'bg-slate-50': !lifecycleAction,
            }"
        >
            {{-- Decorative blob --}}
            <div
                class="absolute -top-6 -right-6 w-24 h-24 rounded-full opacity-20 pointer-events-none"
                :class="{
                    'bg-indigo-400': lifecycleAction === 'Transfer',
                    'bg-slate-400': lifecycleAction === 'Deceased',
                    'bg-amber-400': lifecycleAction === 'Archive',
                    'bg-emerald-400': lifecycleAction === 'Restore',
                }"
            ></div>

            {{-- Close --}}
            <button
                @click="open = false; resetLifecycleForm()"
                class="absolute top-4 right-4 w-7 h-7 rounded-full flex items-center justify-center text-slate-400 hover:text-slate-600 hover:bg-white/60 transition-colors z-10"
                title="Close"
            >
                <i data-lucide="x" class="w-4 h-4"></i>
            </button>

            <div class="flex items-start gap-4 pr-6">
                {{-- Icon --}}
                <div
                    class="w-12 h-12 rounded-2xl flex items-center justify-center flex-shrink-0 shadow-sm"
                    :class="{
                        'bg-indigo-100 text-indigo-600': lifecycleAction === 'Transfer',
                        'bg-slate-200 text-slate-600': lifecycleAction === 'Deceased',
                        'bg-amber-100 text-amber-600': lifecycleAction === 'Archive',
                        'bg-emerald-100 text-emerald-600': lifecycleAction === 'Restore',
                    }"
                >
                    {{-- Transfer --}}
                    <template x-if="lifecycleAction === 'Transfer'">
                        <i data-lucide="arrow-right-from-line" class="w-6 h-6"></i>
                    </template>
                    {{-- Deceased --}}
                    <template x-if="lifecycleAction === 'Deceased'">
                        <i data-lucide="flower" class="w-6 h-6"></i>
                    </template>
                    {{-- Archive --}}
                    <template x-if="lifecycleAction === 'Archive'">
                        <i data-lucide="archive" class="w-6 h-6"></i>
                    </template>
                    {{-- Restore --}}
                    <template x-if="lifecycleAction === 'Restore'">
                        <i data-lucide="refresh-cw" class="w-6 h-6"></i>
                    </template>
                    {{-- Fallback --}}
                    <template x-if="!['Transfer','Deceased','Archive','Restore'].includes(lifecycleAction)">
                        <i data-lucide="settings-2" class="w-6 h-6"></i>
                    </template>
                </div>

                <div class="min-w-0 pt-0.5">
                    <h2
                        class="text-base font-bold"
                        :class="{
                            'text-indigo-900': lifecycleAction === 'Transfer',
                            'text-slate-700': lifecycleAction === 'Deceased',
                            'text-amber-900': lifecycleAction === 'Archive',
                            'text-emerald-900': lifecycleAction === 'Restore',
                        }"
                        x-text="actionConfig.title"
                    ></h2>
                    <p class="text-xs mt-1 leading-relaxed text-slate-500" x-text="actionConfig.desc"></p>
                </div>
            </div>
        </div>

        {{-- ════════════════════════════════════════════════════════
             MODAL BODY
        ════════════════════════════════════════════════════════ --}}
        <div class="px-6 py-5 space-y-5 overflow-y-auto max-h-[60vh]">

            {{-- ── Resident context box ── --}}
            <div class="bg-slate-50 border border-slate-200 rounded-xl p-4 flex items-center gap-3">
                <div class="w-10 h-10 rounded-full bg-navy-100 flex items-center justify-center text-navy-700 font-bold text-sm uppercase flex-shrink-0">
                    <span x-text="(selectedIndividual?.name || 'R').split(' ').map(w=>w[0]).slice(0,2).join('')"></span>
                </div>
                <div class="min-w-0 flex-1">
                    <p class="text-sm font-bold text-navy-900 truncate" x-text="selectedIndividual?.name || '—'"></p>
                    <p class="text-xs text-slate-500 mt-0.5">
                        ID: <span class="font-mono font-medium text-slate-700" x-text="selectedIndividual?.id || '—'"></span>
                        <span class="mx-1.5 text-slate-300">·</span>
                        Brgy. <span x-text="selectedIndividual?.barangay || '—'"></span>
                    </p>
                </div>
                <span
                    class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold flex-shrink-0"
                    :class="statusBadge(selectedIndividual?.status)"
                    x-text="selectedIndividual?.status"
                ></span>
            </div>


            {{-- ── TRANSFER FORM ── --}}
            <div x-show="lifecycleAction === 'Transfer'" class="space-y-4">

                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                        Target Barangay <span class="text-red-500">*</span>
                    </label>
                    <select
                        x-model="form.target_barangay"
                        class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent transition"
                        required
                    >
                        <option value="" disabled selected>Select destination barangay</option>
                        <option value="Poblacion">Poblacion</option>
                        <option value="Masbaranon">Masbaranon</option>
                        <option value="Baras">Baras</option>
                        <option value="Iligan">Iligan</option>
                        <option value="Santiago">Santiago</option>
                        <option value="Magsaysay">Magsaysay</option>
                        <option value="Domorog">Domorog</option>
                        <option value="San Roque">San Roque</option>
                        <option value="Rizal">Rizal</option>
                        <option value="Libertad">Libertad</option>
                        <option value="Guadalupe">Guadalupe</option>
                        <option value="Potingbato">Potingbato</option>
                        <option value="Villa">Villa</option>
                        <option value="Agoho">Agoho</option>
                        <option value="Sorosimbajan">Sorosimbajan</option>
                        <option value="Labrador">Labrador</option>
                        <option value="Almero">Almero</option>
                        <option value="Tunga">Tunga</option>
                        <option value="Labangtaytay">Labangtaytay</option>
                        <option value="Tawad">Tawad</option>
                    </select>
                    <p class="text-xs text-slate-400 mt-1">
                        Select the barangay where this resident will be formally transferred.
                    </p>
                </div>

                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                        Reason for Transfer <span class="text-red-500">*</span>
                    </label>
                    <textarea
                        x-model="form.transfer_reason"
                        placeholder="Briefly state the reason for this transfer (e.g., marriage, employment relocation, family consolidation…)"
                        rows="3"
                        class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent transition resize-none"
                        required
                    ></textarea>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                            Effective Date <span class="text-red-500">*</span>
                        </label>
                        <input
                            type="date"
                            x-model="form.effective_date"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent transition"
                            required
                        />
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                            Certifying Officer <span class="text-red-500">*</span>
                        </label>
                        <input
                            type="text"
                            x-model="form.certifying_officer"
                            placeholder="Full name of the barangay officer"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent transition"
                            required
                        />
                    </div>
                </div>

                {{-- Warning note --}}
                <div class="bg-indigo-50 border border-indigo-100 rounded-lg px-4 py-3 flex items-start gap-2.5 text-xs text-indigo-700">
                    <i data-lucide="info" class="w-4 h-4 flex-shrink-0 mt-0.5 text-indigo-400"></i>
                    <span>
                        This transfer will flag the record for barangay scope reassignment.
                        Program linkages (4Ps, OSCA, PWD) must be updated at the receiving barangay.
                    </span>
                </div>

            </div>{{-- /Transfer --}}


            {{-- ── DECEASED FORM ── --}}
            <div x-show="lifecycleAction === 'Deceased'" class="space-y-4">

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                            Date of Passing <span class="text-red-500">*</span>
                        </label>
                        <input
                            type="date"
                            x-model="form.date_of_passing"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 bg-white focus:outline-none focus:ring-2 focus:ring-slate-400 focus:border-transparent transition"
                            required
                        />
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Cause of Death</label>
                        <input
                            type="text"
                            x-model="form.cause_of_death"
                            placeholder="e.g. Natural causes, illness"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-slate-400 focus:border-transparent transition"
                        />
                    </div>
                </div>

                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                        Informant Name <span class="text-red-500">*</span>
                    </label>
                    <input
                        type="text"
                        x-model="form.informant_name"
                        placeholder="Name of the person reporting the death"
                        class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-slate-400 focus:border-transparent transition"
                        required
                    />
                </div>

                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">PSA Death Certificate Reference No.</label>
                    <input
                        type="text"
                        x-model="form.death_cert_ref"
                        placeholder="e.g. 2024-DC-000123"
                        class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-slate-400 focus:border-transparent transition"
                    />
                    <p class="text-xs text-slate-400 mt-1">Leave blank if PSA certificate is not yet available.</p>
                </div>

                {{-- Note --}}
                <div class="bg-slate-100 border border-slate-200 rounded-lg px-4 py-3 flex items-start gap-2.5 text-xs text-slate-600">
                    <i data-lucide="info" class="w-4 h-4 flex-shrink-0 mt-0.5 text-slate-400"></i>
                    <span>
                        The record will be set to <strong>Deceased</strong> status and removed from active views.
                        All program enrollments will be flagged for review by the MSWDO office.
                    </span>
                </div>

            </div>{{-- /Deceased --}}


            {{-- ── ARCHIVE FORM ── --}}
            <div x-show="lifecycleAction === 'Archive'" class="space-y-4">

                <div class="bg-amber-50 border border-amber-200 rounded-xl p-4 flex items-start gap-3">
                    <i data-lucide="archive" class="w-5 h-5 text-amber-500 flex-shrink-0 mt-0.5"></i>
                    <div class="text-sm text-amber-800">
                        <p class="font-semibold mb-1">Confirm Archive</p>
                        <p class="text-xs leading-relaxed">
                            This resident record will be hidden from all active dashboards, reports, and program eligibility lists.
                            The data is <strong>not deleted</strong> and can be restored by an authorized administrator at any time.
                        </p>
                    </div>
                </div>

                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                        Reason for Archiving <span class="text-red-500">*</span>
                    </label>
                    <textarea
                        x-model="form.archive_reason"
                        placeholder="Provide a reason (e.g., resident migrated permanently, duplicate record, data entry error…)"
                        rows="4"
                        class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-transparent transition resize-none"
                        required
                    ></textarea>
                    <p class="text-xs text-slate-400 mt-1">This reason will be recorded in the audit log and is required by LGU data governance policy.</p>
                </div>

                {{-- Acknowledgment checkbox --}}
                <label class="flex items-start gap-3 cursor-pointer">
                    <input type="checkbox" class="mt-0.5 w-4 h-4 rounded border-slate-300 text-amber-500 focus:ring-amber-400" />
                    <span class="text-xs text-slate-600">
                        I confirm that this archive action is authorized and that all required program linkages have been reviewed prior to archiving.
                    </span>
                </label>

            </div>{{-- /Archive --}}


            {{-- ── RESTORE FORM ── --}}
            <div x-show="lifecycleAction === 'Restore'" class="space-y-4">

                <div class="bg-emerald-50 border border-emerald-200 rounded-xl p-4 flex items-start gap-3">
                    <i data-lucide="refresh-cw" class="w-5 h-5 text-emerald-500 flex-shrink-0 mt-0.5"></i>
                    <div class="text-sm text-emerald-800">
                        <p class="font-semibold mb-1">Confirm Restore</p>
                        <p class="text-xs leading-relaxed">
                            This action will restore the resident record to <strong>Active</strong> status.
                            The record will reappear in all active views, program eligibility checks, and barangay reports.
                            Please verify that no duplicate record exists before proceeding.
                        </p>
                    </div>
                </div>

                {{-- Summary of record being restored --}}
                <div class="rounded-xl border border-slate-200 bg-white p-4 space-y-2">
                    <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">Record Being Restored</h4>
                    <div class="grid grid-cols-2 gap-y-2 gap-x-4 text-xs">
                        <div>
                            <span class="text-slate-400">Name:</span>
                            <span class="font-semibold text-navy-900 ml-1" x-text="selectedIndividual?.name || '—'"></span>
                        </div>
                        <div>
                            <span class="text-slate-400">ID:</span>
                            <span class="font-mono font-semibold text-navy-900 ml-1" x-text="selectedIndividual?.id || '—'"></span>
                        </div>
                        <div>
                            <span class="text-slate-400">Barangay:</span>
                            <span class="font-semibold text-navy-900 ml-1" x-text="'Brgy. ' + (selectedIndividual?.barangay || '—')"></span>
                        </div>
                        <div>
                            <span class="text-slate-400">New Status:</span>
                            <span class="font-semibold text-emerald-600 ml-1">Active</span>
                        </div>
                    </div>
                </div>

                {{-- Acknowledgment --}}
                <label class="flex items-start gap-3 cursor-pointer">
                    <input type="checkbox" class="mt-0.5 w-4 h-4 rounded border-slate-300 text-emerald-500 focus:ring-emerald-400" />
                    <span class="text-xs text-slate-600">
                        I have verified this is not a duplicate record and that restoring it is appropriate under current LGU data policy.
                    </span>
                </label>

            </div>{{-- /Restore --}}

        </div>{{-- /body --}}


        {{-- ════════════════════════════════════════════════════════
             FOOTER ACTIONS
        ════════════════════════════════════════════════════════ --}}
        <div class="px-6 py-4 border-t border-slate-200 bg-white rounded-b-2xl flex items-center justify-between gap-3">

            <button
                @click="open = false; resetLifecycleForm()"
                class="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg border border-slate-200 text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors"
            >
                Cancel
            </button>

            {{-- Confirm button — color shifts per action --}}
            <button
                @click="confirmLifecycle()"
                class="inline-flex items-center gap-1.5 px-5 py-2 rounded-lg text-white text-sm font-semibold transition-colors shadow-sm"
                :class="{
                    'bg-indigo-600 hover:bg-indigo-700': lifecycleAction === 'Transfer',
                    'bg-slate-700 hover:bg-slate-800': lifecycleAction === 'Deceased',
                    'bg-amber-500 hover:bg-amber-600': lifecycleAction === 'Archive',
                    'bg-emerald-600 hover:bg-emerald-700': lifecycleAction === 'Restore',
                }"
            >
                {{-- Icon per action --}}
                <template x-if="lifecycleAction === 'Transfer'">
                    <i data-lucide="arrow-right-from-line" class="w-4 h-4"></i>
                </template>
                <template x-if="lifecycleAction === 'Deceased'">
                    <i data-lucide="flower" class="w-4 h-4"></i>
                </template>
                <template x-if="lifecycleAction === 'Archive'">
                    <i data-lucide="archive" class="w-4 h-4"></i>
                </template>
                <template x-if="lifecycleAction === 'Restore'">
                    <i data-lucide="refresh-cw" class="w-4 h-4"></i>
                </template>

                <span x-text="actionConfig.confirmLabel"></span>
            </button>

        </div>

    </x-ui.modal>
</div>
