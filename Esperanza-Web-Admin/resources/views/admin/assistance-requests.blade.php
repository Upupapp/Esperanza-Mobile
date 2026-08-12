@php
    $requests = [
        ['ref' => 'AR-2026-0151', 'citizen' => 'Elmer Bantillo', 'type' => 'Medical Assistance (AICS)', 'office' => 'MSWDO', 'barangay' => 'Santiago', 'submitted' => 'Jul 9, 2026', 'status' => 'Pending Review'],
        ['ref' => 'AR-2026-0148', 'citizen' => 'Angelica Fajardo', 'type' => 'Burial Assistance (AICS)', 'office' => 'MSWDO', 'barangay' => 'Rizal', 'submitted' => 'Jul 6, 2026', 'status' => 'Assigned'],
        ['ref' => 'AR-2026-0142', 'citizen' => 'Maria Fe Bacaltos', 'type' => 'Medical Assistance (AICS)', 'office' => 'MSWDO', 'barangay' => 'Poblacion', 'submitted' => 'Jun 28, 2026', 'status' => 'Approved'],
        ['ref' => 'AR-2026-0098', 'citizen' => 'Rodrigo Palma', 'type' => 'Educational Assistance', 'office' => "Mayor's Office", 'barangay' => 'Domorog', 'submitted' => 'May 20, 2026', 'status' => 'Released'],
        ['ref' => 'AR-2026-0061', 'citizen' => 'Teresita Salazar', 'type' => 'Financial Assistance (AICS)', 'office' => 'MSWDO', 'barangay' => 'Agoho', 'submitted' => 'Apr 2, 2026', 'status' => 'Completed'],
        ['ref' => 'AR-2026-0044', 'citizen' => 'Michael Bacus', 'type' => 'Food / Relief Assistance', 'office' => 'MSWDO', 'barangay' => 'Iligan', 'submitted' => 'Mar 18, 2026', 'status' => 'Completed'],
        ['ref' => 'AR-2026-0037', 'citizen' => 'Josefina Marbella', 'type' => 'Social Pension (Indigent Senior)', 'office' => 'OSCA', 'barangay' => 'Baras', 'submitted' => 'Feb 10, 2026', 'status' => 'Completed'],
        ['ref' => 'AR-2026-0022', 'citizen' => 'Rosemarie Tan', 'type' => 'Solo Parent Cash Assistance', 'office' => 'MSWDO', 'barangay' => 'Baras', 'submitted' => 'Jan 28, 2026', 'status' => 'Waiting Requirements'],
    ];

    $tabs = ['all' => 'All', 'action' => 'Needs Action', 'release' => 'Approved / Released', 'done' => 'Completed'];
    $actionStatuses = ['Pending Review', 'Assigned', 'Waiting Requirements', 'Processing'];
    $releaseStatuses = ['Approved', 'Released'];
@endphp

<x-layouts.admin title="Tulong" subtitle="Review and manage citizen assistance requests." active="assistance-requests">
    <div
        x-data="{
            tab: 'all',
            search: '',
            open: false,
            selected: null,
            processing: false,
            requests: @js($requests),
            actionStatuses: @js($actionStatuses),
            releaseStatuses: @js($releaseStatuses),
            statusStyles: {
                'Draft': ['bg-slate-100 text-slate-600 ring-slate-200', 'bg-slate-400'],
                'Submitted': ['bg-blue-50 text-blue-700 ring-blue-200', 'bg-blue-500'],
                'Pending Review': ['bg-amber-50 text-amber-700 ring-amber-200', 'bg-amber-500'],
                'Assigned': ['bg-purple-50 text-purple-700 ring-purple-200', 'bg-purple-500'],
                'Processing': ['bg-brand-50 text-brand-700 ring-brand-200', 'bg-brand-500'],
                'Waiting Requirements': ['bg-orange-50 text-orange-700 ring-orange-200', 'bg-orange-500'],
                'Approved': ['bg-emerald-50 text-emerald-700 ring-emerald-200', 'bg-emerald-500'],
                'Rejected': ['bg-rose-50 text-rose-700 ring-rose-200', 'bg-rose-500'],
                'Released': ['bg-cyan-50 text-cyan-700 ring-cyan-200', 'bg-cyan-500'],
                'Completed': ['bg-green-50 text-green-700 ring-green-200', 'bg-green-500'],
            },
            matchesTab(r) {
                if (this.tab === 'all') return true;
                if (this.tab === 'action') return this.actionStatuses.includes(r.status);
                if (this.tab === 'release') return this.releaseStatuses.includes(r.status);
                if (this.tab === 'done') return r.status === 'Completed';
                return true;
            },
            get filteredRequests() {
                const q = this.search.trim().toLowerCase();
                return this.requests.filter(r =>
                    this.$store.session.inScope(r.barangay) &&
                    this.matchesTab(r) &&
                    (q === '' || r.ref.toLowerCase().includes(q) || r.citizen.toLowerCase().includes(q))
                );
            },
            stepIndex(status) {
                const map = { 'Submitted': 0, 'Pending Review': 0, 'Assigned': 1, 'Waiting Requirements': 1, 'Processing': 1, 'Approved': 2, 'Released': 3, 'Completed': 4, 'Rejected': 0 };
                return map[status] ?? 0;
            },
            reject() {
                if (this.processing) return;
                this.processing = true;
                setTimeout(() => {
                    this.selected.status = 'Rejected';
                    this.processing = false;
                    this.open = false;
                    this.$dispatch('toast', { message: 'Case ' + this.selected.ref + ' rejected.', variant: 'error' });
                }, 700);
            },
            approve() {
                if (this.processing) return;
                this.processing = true;
                setTimeout(() => {
                    const order = ['Submitted', 'Assigned', 'Approved', 'Released', 'Completed'];
                    const next = Math.min(this.stepIndex(this.selected.status) + 1, order.length - 1);
                    this.selected.status = order[next];
                    this.processing = false;
                    this.open = false;
                    this.$dispatch('toast', { message: this.selected.ref + ' moved to next stage: ' + this.selected.status + '.', variant: 'success' });
                }, 700);
            },
        }"
        class="animate-fade-up"
    >

        <div x-show="!$store.session.can('tulong')" x-cloak>
            <x-admin.access-restricted module="Tulong (Citizen Assistance)" icon="hand-heart" />
        </div>

        <div x-show="$store.session.can('tulong')" x-cloak>

        <div class="grid grid-cols-2 lg:grid-cols-5 gap-3 mb-4">
            <x-ui.stat-card @click="tab = 'all'" class="cursor-pointer" label="Active Cases" value="417" icon="hand-heart" color="purple" :delay="0" />
            <x-ui.stat-card @click="tab = 'action'" class="cursor-pointer" label="Needs Action" value="34" icon="inbox" color="orange" sublabel="Review or assignment" :delay="40" />
            <x-ui.stat-card @click="tab = 'release'" class="cursor-pointer" label="Approved / Released" value="112" icon="package-check" color="green" :delay="80" />
            <x-ui.stat-card :href="route('admin.analytics')" label="Budget Utilized (Q3)" value="₱1.8M" icon="wallet" color="brand" sublabel="of ₱2.5M allocated" :delay="120" />
            <x-ui.stat-card :href="route('admin.reports')" label="Ayuda Received" value="₱1.8M" icon="hand-coins" color="gold" sublabel="Disbursed to citizens" :delay="160" />
        </div>

        <div class="bg-white border border-slate-200 rounded-2xl shadow-card p-3 mb-4 space-y-3">
            <div class="flex flex-wrap items-center gap-2">
                <div class="relative flex-1 min-w-[200px]">
                    <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none"></i>
                    <input type="text" x-model="search" placeholder="Search reference or citizen..." class="w-full pl-9 pr-3 py-2 text-xs rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200">
                </div>
            </div>
            <div class="flex flex-wrap items-center justify-between gap-2">
                <div class="flex items-center gap-1.5 bg-slate-100/70 rounded-xl p-1 w-fit overflow-x-auto">
                    @foreach($tabs as $key => $label)
                        <button
                            type="button" @click="tab = '{{ $key }}'"
                            class="px-3 py-1.5 text-[11px] font-medium rounded-lg transition-colors whitespace-nowrap"
                            :class="tab === '{{ $key }}' ? 'bg-white text-navy-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'"
                        >{{ $label }}</button>
                    @endforeach
                </div>
                <p class="text-[11px] text-slate-400 shrink-0" x-text="filteredRequests.length + ' of ' + requests.length + ' cases'"></p>
            </div>
        </div>

        <x-ui.table>
            <thead>
                <tr class="border-b border-slate-100 bg-slate-50/60">
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400">Reference</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400">Citizen</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden md:table-cell">Assistance Type</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden lg:table-cell">Office</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden lg:table-cell">Barangay</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden sm:table-cell">Submitted</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400">Status</th>
                    <th class="px-4 py-2.5"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-50">
                <template x-for="r in filteredRequests" :key="r.ref">
                    <tr class="hover:bg-slate-50/70 transition-colors">
                        <td class="px-4 py-3 font-mono text-xs text-slate-500" x-text="r.ref"></td>
                        <td class="px-4 py-3 text-slate-700 font-medium whitespace-nowrap" x-text="r.citizen"></td>
                        <td class="px-4 py-3 text-slate-500 hidden md:table-cell" x-text="r.type"></td>
                        <td class="px-4 py-3 text-slate-500 hidden lg:table-cell"><span class="text-[11px] font-medium text-slate-500 bg-slate-100 px-2 py-0.5 rounded-md whitespace-nowrap" x-text="r.office"></span></td>
                        <td class="px-4 py-3 text-slate-500 hidden lg:table-cell"><span x-text="'Brgy. ' + r.barangay"></span></td>
                        <td class="px-4 py-3 text-slate-500 hidden sm:table-cell" x-text="r.submitted"></td>
                        <td class="px-4 py-3">
                            <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ring-1 ring-inset whitespace-nowrap" :class="(statusStyles[r.status] || statusStyles['Draft'])[0]">
                                <span class="w-1.5 h-1.5 rounded-full" :class="(statusStyles[r.status] || statusStyles['Draft'])[1]"></span>
                                <span x-text="r.status"></span>
                            </span>
                        </td>
                        <td class="px-4 py-3 text-right">
                            <button @click="open = true; selected = r" class="text-xs font-medium text-brand-600 hover:underline whitespace-nowrap">Review</button>
                        </td>
                    </tr>
                </template>
            </tbody>
        </x-ui.table>

        <div class="flex flex-col items-center text-center py-10 bg-white border border-slate-100 rounded-2xl mt-3" x-show="filteredRequests.length === 0">
            <span class="w-11 h-11 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mb-3"><i data-lucide="search-x" class="w-5 h-5"></i></span>
            <p class="text-sm font-medium text-slate-600">No cases match these filters.</p>
        </div>

        <x-ui.modal title="Review Tulong Case" maxWidth="lg">
            <template x-if="selected">
                <div>
                    <p class="text-xs text-slate-400 mb-4 font-mono" x-text="selected.ref"></p>

                    <div class="flex items-center mb-6 px-1">
                        @foreach(['Submitted', 'Assigned', 'Approved', 'Released', 'Completed'] as $i => $step)
                            <div class="flex-1 flex items-center">
                                <div class="flex flex-col items-center gap-2 text-center">
                                    <span
                                        class="w-9 h-9 rounded-full flex items-center justify-center text-xs font-semibold transition-all duration-300"
                                        :class="stepIndex(selected.status) > {{ $i }} ? 'bg-emerald-500 text-white shadow-sm' : (stepIndex(selected.status) === {{ $i }} ? 'bg-purple-600 text-white shadow-card ring-4 ring-purple-100' : 'bg-slate-100 text-slate-400')"
                                    >
                                        <i data-lucide="check" class="w-4 h-4" x-show="stepIndex(selected.status) > {{ $i }}" x-cloak></i>
                                        <span x-show="stepIndex(selected.status) <= {{ $i }}">{{ $i + 1 }}</span>
                                    </span>
                                    <span class="text-[11px] max-w-[80px] leading-tight transition-colors duration-300" :class="stepIndex(selected.status) === {{ $i }} ? 'text-navy-900 font-semibold' : 'text-slate-400'">{{ $step }}</span>
                                </div>
                                @if(!$loop->last)
                                    <div class="flex-1 h-1 rounded-full mx-1.5 -mt-6 transition-colors duration-300" :class="stepIndex(selected.status) > {{ $i }} ? 'bg-emerald-400' : 'bg-slate-100'"></div>
                                @endif
                            </div>
                        @endforeach
                    </div>

                    <div class="rounded-xl border border-slate-200 overflow-hidden">
                        <div class="grid grid-cols-1 sm:grid-cols-2 divide-y sm:divide-y-0 sm:divide-x divide-slate-100 bg-slate-50/60">
                            <div class="flex items-center gap-2.5 px-4 py-3">
                                <span class="w-8 h-8 rounded-lg bg-white text-purple-600 border border-slate-200 flex items-center justify-center shrink-0"><i data-lucide="user-round" class="w-4 h-4"></i></span>
                                <div class="min-w-0">
                                    <p class="text-[10px] text-slate-400 uppercase tracking-wide">Citizen</p>
                                    <p class="text-sm font-medium text-navy-900 truncate" x-text="selected.citizen"></p>
                                </div>
                            </div>
                            <div class="flex items-center gap-2.5 px-4 py-3">
                                <span class="w-8 h-8 rounded-lg bg-white text-purple-600 border border-slate-200 flex items-center justify-center shrink-0"><i data-lucide="hand-heart" class="w-4 h-4"></i></span>
                                <div class="min-w-0">
                                    <p class="text-[10px] text-slate-400 uppercase tracking-wide">Assistance Type</p>
                                    <p class="text-sm font-medium text-navy-900 truncate" x-text="selected.type"></p>
                                </div>
                            </div>
                            <div class="flex items-center gap-2.5 px-4 py-3">
                                <span class="w-8 h-8 rounded-lg bg-white text-purple-600 border border-slate-200 flex items-center justify-center shrink-0"><i data-lucide="landmark" class="w-4 h-4"></i></span>
                                <div class="min-w-0">
                                    <p class="text-[10px] text-slate-400 uppercase tracking-wide">Handling Office</p>
                                    <p class="text-sm font-medium text-navy-900 truncate" x-text="selected.office"></p>
                                </div>
                            </div>
                            <div class="flex items-center gap-2.5 px-4 py-3">
                                <span class="w-8 h-8 rounded-lg bg-white text-purple-600 border border-slate-200 flex items-center justify-center shrink-0"><i data-lucide="map-pin" class="w-4 h-4"></i></span>
                                <div class="min-w-0">
                                    <p class="text-[10px] text-slate-400 uppercase tracking-wide">Barangay</p>
                                    <p class="text-sm font-medium text-navy-900 truncate" x-text="'Brgy. ' + selected.barangay"></p>
                                </div>
                            </div>
                            <div class="flex items-center gap-2.5 px-4 py-3 sm:col-span-2">
                                <span class="w-8 h-8 rounded-lg bg-white text-purple-600 border border-slate-200 flex items-center justify-center shrink-0"><i data-lucide="calendar" class="w-4 h-4"></i></span>
                                <div class="min-w-0">
                                    <p class="text-[10px] text-slate-400 uppercase tracking-wide">Submitted</p>
                                    <p class="text-sm font-medium text-navy-900 truncate" x-text="selected.submitted"></p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </template>

            <x-slot:footer>
                <x-ui.button variant="danger" size="sm" x-bind:disabled="processing" @click="reject()">
                    <span class="inline-flex items-center gap-1.5">
                        <i data-lucide="loader-circle" class="w-3.5 h-3.5 animate-spin" x-show="processing" x-cloak></i>
                        <span x-text="processing ? 'Rejecting…' : 'Reject'"></span>
                    </span>
                </x-ui.button>
                <x-ui.button size="sm" x-bind:disabled="processing" @click="approve()">
                    <span class="inline-flex items-center gap-1.5">
                        <i data-lucide="loader-circle" class="w-3.5 h-3.5 animate-spin" x-show="processing" x-cloak></i>
                        <i data-lucide="check" class="w-3.5 h-3.5" x-show="!processing"></i>
                        <span x-text="processing ? 'Processing…' : 'Approve & Continue'"></span>
                    </span>
                </x-ui.button>
            </x-slot:footer>
        </x-ui.modal>

        </div>
    </div>
</x-layouts.admin>
