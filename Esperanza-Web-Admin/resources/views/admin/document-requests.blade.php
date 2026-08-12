@php
    $requests = [
        ['ref' => 'DR-2026-2231', 'citizen' => 'Perla Dionisio', 'type' => 'Barangay Residency', 'office' => 'Barangay Hall (Brgy. Labangtaytay)', 'barangay' => 'Labangtaytay', 'submitted' => 'Jul 12, 2026', 'status' => 'Pending Review'],
        ['ref' => 'DR-2026-2228', 'citizen' => 'Romeo Villaflor', 'type' => 'Barangay Business Clearance', 'office' => 'Barangay Hall (Brgy. Labangtaytay)', 'barangay' => 'Labangtaytay', 'submitted' => 'Jul 11, 2026', 'status' => 'Ready for Release'],
        ['ref' => 'DR-2026-2225', 'citizen' => 'Cristina Manalo', 'type' => 'Barangay Indigency', 'office' => 'Barangay Hall (Brgy. Labangtaytay)', 'barangay' => 'Labangtaytay', 'submitted' => 'Jul 10, 2026', 'status' => 'Under Verification'],
        ['ref' => 'DR-2026-2219', 'citizen' => 'Kevin Ray Dizon', 'type' => 'First Time Jobseeker Certificate (RA 11261)', 'office' => 'Barangay Hall (Brgy. Labangtaytay)', 'barangay' => 'Labangtaytay', 'submitted' => 'Jul 9, 2026', 'status' => 'Completed'],
        ['ref' => 'DR-2026-2217', 'citizen' => 'Bienvenido Rosales', 'type' => 'Barangay Certification (Registration of Death)', 'office' => 'Barangay Hall (Brgy. Labangtaytay)', 'barangay' => 'Labangtaytay', 'submitted' => 'Jul 9, 2026', 'status' => 'Waiting Requirements'],
        ['ref' => 'DR-2026-2214', 'citizen' => 'Rosemarie Tan', 'type' => 'Business Permit (New)', 'office' => 'BPLO', 'barangay' => 'Baras', 'submitted' => 'Jul 10, 2026', 'status' => 'Pending Review'],
        ['ref' => 'DR-2026-2210', 'citizen' => 'Maria Fe Bacaltos', 'type' => 'Cedula', 'office' => "Treasurer's Office", 'barangay' => 'Poblacion', 'submitted' => 'Jul 8, 2026', 'status' => 'Under Verification'],
        ['ref' => 'DR-2026-2201', 'citizen' => 'Elmer Bantillo', 'type' => 'Certificate of Indigency', 'office' => 'MSWDO', 'barangay' => 'Santiago', 'submitted' => 'Jul 7, 2026', 'status' => 'Waiting Requirements'],
        ['ref' => 'DR-2026-2187', 'citizen' => 'Maria Fe Bacaltos', 'type' => 'Barangay Clearance', 'office' => 'Barangay Hall', 'barangay' => 'Poblacion', 'submitted' => 'Jul 3, 2026', 'status' => 'Ready for Release'],
        ['ref' => 'DR-2026-2154', 'citizen' => 'Corazon Villareal', 'type' => 'Certificate of Residency', 'office' => 'Civil Registrar', 'barangay' => 'Iligan', 'submitted' => 'Jun 29, 2026', 'status' => 'Approved'],
        ['ref' => 'DR-2026-2098', 'citizen' => 'Teresita Salazar', 'type' => 'Senior Citizen ID', 'office' => 'OSCA', 'barangay' => 'Agoho', 'submitted' => 'Jun 22, 2026', 'status' => 'Processing'],
        ['ref' => 'DR-2026-1998', 'citizen' => 'Josefina Marbella', 'type' => 'Certificate of Residency', 'office' => 'Civil Registrar', 'barangay' => 'Baras', 'submitted' => 'Jun 14, 2026', 'status' => 'Completed'],
        ['ref' => 'DR-2026-1872', 'citizen' => 'Alvin Dagohoy', 'type' => 'Certificate of Indigency', 'office' => 'MSWDO', 'barangay' => 'Domorog', 'submitted' => 'May 30, 2026', 'status' => 'Completed'],
        ['ref' => 'DR-2026-1655', 'citizen' => 'Rosemarie Tan', 'type' => 'Business Permit Renewal', 'office' => 'BPLO', 'barangay' => 'Baras', 'submitted' => 'May 12, 2026', 'status' => 'Rejected'],
        ['ref' => 'DR-2026-1490', 'citizen' => 'Michael Bacus', 'type' => 'Real Property Tax Clearance', 'office' => "Treasurer's Office", 'barangay' => 'Iligan', 'submitted' => 'Apr 20, 2026', 'status' => 'Completed'],
        // One sample request per remaining barangay so every Barangay Secretary
        // account (BS-004 through BS-020) has something to review — otherwise
        // most of the 20 barangay-scoped roles would land on an empty table.
        ['ref' => 'DR-2026-2240', 'citizen' => 'Joel Aranas', 'type' => 'Barangay Residency', 'office' => 'Barangay Hall (Brgy. Almero)', 'barangay' => 'Almero', 'submitted' => 'Jul 6, 2026', 'status' => 'Pending Review'],
        ['ref' => 'DR-2026-2241', 'citizen' => 'Lorna Dimaano', 'type' => 'Barangay Indigency', 'office' => 'Barangay Hall (Brgy. Guadalupe)', 'barangay' => 'Guadalupe', 'submitted' => 'Jul 5, 2026', 'status' => 'Under Verification'],
        ['ref' => 'DR-2026-2242', 'citizen' => 'Divina Galvez', 'type' => 'Barangay Business Clearance', 'office' => 'Barangay Hall (Brgy. Labrador)', 'barangay' => 'Labrador', 'submitted' => 'Jul 4, 2026', 'status' => 'Ready for Release'],
        ['ref' => 'DR-2026-2243', 'citizen' => 'Ferdinand Hilario', 'type' => 'First Time Jobseeker Certificate (RA 11261)', 'office' => 'Barangay Hall (Brgy. Libertad)', 'barangay' => 'Libertad', 'submitted' => 'Jun 25, 2026', 'status' => 'Completed'],
        ['ref' => 'DR-2026-2244', 'citizen' => 'Analiza Ibarra', 'type' => 'Barangay Certification (Registration of Death)', 'office' => 'Barangay Hall (Brgy. Magsaysay)', 'barangay' => 'Magsaysay', 'submitted' => 'Jul 2, 2026', 'status' => 'Waiting Requirements'],
        ['ref' => 'DR-2026-2245', 'citizen' => 'Romulo Jacinto', 'type' => 'Barangay Residency', 'office' => 'Barangay Hall (Brgy. Masbaranon)', 'barangay' => 'Masbaranon', 'submitted' => 'Jul 8, 2026', 'status' => 'Pending Review'],
        ['ref' => 'DR-2026-2246', 'citizen' => 'Danilo Lazaro', 'type' => 'Barangay Indigency', 'office' => 'Barangay Hall (Brgy. Potingbato)', 'barangay' => 'Potingbato', 'submitted' => 'Jun 18, 2026', 'status' => 'Completed'],
        ['ref' => 'DR-2026-2247', 'citizen' => 'Precious Manalo', 'type' => 'Barangay Business Clearance', 'office' => 'Barangay Hall (Brgy. Rizal)', 'barangay' => 'Rizal', 'submitted' => 'Jul 9, 2026', 'status' => 'Under Verification'],
        ['ref' => 'DR-2026-2248', 'citizen' => 'Ernesto Nierva', 'type' => 'Barangay Certification (Late Registration)', 'office' => 'Barangay Hall (Brgy. San Roque)', 'barangay' => 'San Roque', 'submitted' => 'Jul 6, 2026', 'status' => 'Ready for Release'],
        ['ref' => 'DR-2026-2249', 'citizen' => 'Ramil Pascua', 'type' => 'Barangay Residency', 'office' => 'Barangay Hall (Brgy. Sorosimbajan)', 'barangay' => 'Sorosimbajan', 'submitted' => 'Jul 11, 2026', 'status' => 'Pending Review'],
        ['ref' => 'DR-2026-2250', 'citizen' => 'Liezel Quimson', 'type' => 'Barangay Indigency', 'office' => 'Barangay Hall (Brgy. Tawad)', 'barangay' => 'Tawad', 'submitted' => 'Jun 30, 2026', 'status' => 'Completed'],
        ['ref' => 'DR-2026-2251', 'citizen' => 'Dante Robles', 'type' => 'First Time Jobseeker Certificate (RA 11261)', 'office' => 'Barangay Hall (Brgy. Tunga)', 'barangay' => 'Tunga', 'submitted' => 'Jul 7, 2026', 'status' => 'Waiting Requirements'],
        ['ref' => 'DR-2026-2252', 'citizen' => 'Cherry Ann Sarmiento', 'type' => 'Barangay Business Clearance', 'office' => 'Barangay Hall (Brgy. Villa)', 'barangay' => 'Villa', 'submitted' => 'Jul 10, 2026', 'status' => 'Ready for Release'],
    ];

    $tabs = ['all' => 'All', 'action' => 'Needs Action', 'release' => 'Ready for Release', 'done' => 'Completed'];
    $actionStatuses = ['Pending Review', 'Under Verification', 'Waiting Requirements', 'Processing'];
    $doneStatuses = ['Completed', 'Released'];

    $submittedDocs = [
        ['name' => 'PhilSys National ID.jpg', 'citizen' => 'Maria Fe Bacaltos', 'type' => 'Valid ID', 'ref' => 'DR-2026-2210', 'uploaded' => 'Jul 8, 2026', 'status' => 'Under Verification'],
        ['name' => 'DTI Registration.pdf', 'citizen' => 'Rosemarie Tan', 'type' => 'DTI/SEC Registration', 'ref' => 'DR-2026-2214', 'uploaded' => 'Jul 10, 2026', 'status' => 'Pending Review'],
        ['name' => 'Barangay Certification.pdf', 'citizen' => 'Elmer Bantillo', 'type' => 'Barangay Certificate of Indigency', 'ref' => 'DR-2026-2201', 'uploaded' => 'Jul 7, 2026', 'status' => 'Waiting Requirements'],
        ['name' => 'Fire Safety Inspection Cert.pdf', 'citizen' => 'Rosemarie Tan', 'type' => 'Fire Safety Inspection Certificate', 'ref' => 'DR-2026-1655', 'uploaded' => 'May 10, 2026', 'status' => 'Approved'],
        ['name' => 'PSA Birth Certificate.pdf', 'citizen' => 'Teresita Salazar', 'type' => 'Proof of Age', 'ref' => 'DR-2026-2098', 'uploaded' => 'Jun 22, 2026', 'status' => 'Approved'],
        ['name' => '2x2 ID Photo.jpg', 'citizen' => 'Josefina Marbella', 'type' => 'Photo', 'ref' => 'DR-2026-1998', 'uploaded' => 'Jun 14, 2026', 'status' => 'Completed'],
    ];
@endphp

<x-layouts.admin title="Dokyu" subtitle="Track and process citizen document requests." active="document-requests">
    <div
        x-data="{
            tab: 'all',
            search: '',
            open: false,
            selected: null,
            processing: false,
            requests: @js($requests),
            actionStatuses: @js($actionStatuses),
            doneStatuses: @js($doneStatuses),
            statusStyles: {
                'Draft': ['bg-slate-100 text-slate-600 ring-slate-200', 'bg-slate-400'],
                'Submitted': ['bg-blue-50 text-blue-700 ring-blue-200', 'bg-blue-500'],
                'Pending Review': ['bg-amber-50 text-amber-700 ring-amber-200', 'bg-amber-500'],
                'Under Verification': ['bg-indigo-50 text-indigo-700 ring-indigo-200', 'bg-indigo-500'],
                'Processing': ['bg-brand-50 text-brand-700 ring-brand-200', 'bg-brand-500'],
                'Waiting Requirements': ['bg-orange-50 text-orange-700 ring-orange-200', 'bg-orange-500'],
                'Approved': ['bg-emerald-50 text-emerald-700 ring-emerald-200', 'bg-emerald-500'],
                'Rejected': ['bg-rose-50 text-rose-700 ring-rose-200', 'bg-rose-500'],
                'Ready for Release': ['bg-teal-50 text-teal-700 ring-teal-200', 'bg-teal-500'],
                'Released': ['bg-cyan-50 text-cyan-700 ring-cyan-200', 'bg-cyan-500'],
                'Completed': ['bg-green-50 text-green-700 ring-green-200', 'bg-green-500'],
            },
            matchesTab(r) {
                if (this.tab === 'all') return true;
                if (this.tab === 'action') return this.actionStatuses.includes(r.status);
                if (this.tab === 'release') return r.status === 'Ready for Release';
                if (this.tab === 'done') return this.doneStatuses.includes(r.status);
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
                const map = { 'Submitted': 0, 'Pending Review': 0, 'Under Verification': 1, 'Waiting Requirements': 1, 'Processing': 1, 'Approved': 2, 'Ready for Release': 3, 'Released': 4, 'Completed': 4, 'Rejected': 0 };
                return map[status] ?? 0;
            },
            reject() {
                if (this.processing) return;
                this.processing = true;
                setTimeout(() => {
                    this.selected.status = 'Rejected';
                    this.processing = false;
                    this.open = false;
                    this.$dispatch('toast', { message: 'Request ' + this.selected.ref + ' rejected.', variant: 'error' });
                }, 700);
            },
            approve() {
                if (this.processing) return;
                this.processing = true;
                setTimeout(() => {
                    const order = ['Submitted', 'Under Verification', 'Approved', 'Ready for Release', 'Released'];
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

        <div x-show="!$store.session.can('dokyu')" x-cloak>
            <x-admin.access-restricted module="Dokyu (Document Requests)" icon="file-text" />
        </div>

        <div x-show="$store.session.can('dokyu')" x-cloak>

        <div class="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-4">
            <x-ui.stat-card @click="tab = 'all'" class="cursor-pointer" label="Total Requests" value="1,284" icon="file-text" color="brand" trend="+8.4%" sublabel="This month" :delay="0" />
            <x-ui.stat-card @click="tab = 'action'" class="cursor-pointer" label="Needs Action" value="63" icon="inbox" color="orange" sublabel="Review or verification" :delay="40" />
            <x-ui.stat-card @click="tab = 'release'" class="cursor-pointer" label="Ready for Release" value="41" icon="package-check" color="green" :delay="80" />
            <x-ui.stat-card :href="route('admin.analytics')" label="Avg. Processing Time" value="2.4 days" icon="timer" color="purple" trendDirection="down" trend="-0.6 days" sublabel="Within RA 11032 limits" :delay="120" />
        </div>

        <div class="bg-white border border-slate-200 rounded-2xl shadow-card p-3 mb-4 space-y-3">
            <div class="flex flex-wrap items-center gap-2">
                <div class="relative flex-1 min-w-[200px]">
                    <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none"></i>
                    <input type="text" x-model="search" placeholder="Search reference or citizen..." class="w-full pl-9 pr-3 py-2 text-xs rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200">
                </div>
                <div x-data="{ open: false }" class="contents">
                    <x-ui.button @click="open = true" variant="secondary" icon="folder-open" size="sm" class="shrink-0">Citizen Documents Storage</x-ui.button>
                    <x-ui.modal title="Citizen Documents Storage" maxWidth="lg">
                        <p class="text-sm text-slate-500 mb-4">Supporting documents submitted by citizens for their Dokyu requests, awaiting or completed verification.</p>
                        <div class="space-y-2">
                            @foreach($submittedDocs as $doc)
                                <div class="flex items-center gap-3 rounded-xl border border-slate-100 p-3">
                                    <span class="w-9 h-9 rounded-lg bg-slate-100 text-slate-500 flex items-center justify-center shrink-0">
                                        <i data-lucide="file-text" class="w-4 h-4"></i>
                                    </span>
                                    <div class="min-w-0 flex-1">
                                        <p class="text-sm font-medium text-slate-700 truncate">{{ $doc['name'] }}</p>
                                        <p class="text-xs text-slate-400">{{ $doc['citizen'] }} · {{ $doc['type'] }} · <span class="font-mono">{{ $doc['ref'] }}</span></p>
                                    </div>
                                    <x-ui.badge :status="$doc['status']" class="shrink-0" />
                                </div>
                            @endforeach
                        </div>

                        <x-slot:footer>
                            <x-ui.button size="sm" @click="open = false">Close</x-ui.button>
                        </x-slot:footer>
                    </x-ui.modal>
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
                <p class="text-[11px] text-slate-400 shrink-0" x-text="filteredRequests.length + ' of ' + requests.length + ' requests'"></p>
            </div>
        </div>

        <x-ui.table>
            <thead>
                <tr class="border-b border-slate-100 bg-slate-50/60">
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400">Reference</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400">Citizen</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden md:table-cell">Document Type</th>
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
                            <button @click="open = true; selected = r" class="text-xs font-medium text-brand-600 hover:underline whitespace-nowrap">Process</button>
                        </td>
                    </tr>
                </template>
            </tbody>
        </x-ui.table>

        <div class="flex flex-col items-center text-center py-10 bg-white border border-slate-100 rounded-2xl mt-3" x-show="filteredRequests.length === 0">
            <span class="w-11 h-11 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mb-3"><i data-lucide="search-x" class="w-5 h-5"></i></span>
            <p class="text-sm font-medium text-slate-600">No requests match these filters.</p>
        </div>

        <x-ui.modal title="Process Document Request" maxWidth="lg">
            <template x-if="selected">
                <div>
                    <p class="text-xs text-slate-400 mb-4 font-mono" x-text="selected.ref"></p>

                    <div class="flex items-center mb-6 px-1">
                        @foreach(['Submitted', 'Under Verification', 'Approved', 'Ready for Release', 'Released'] as $i => $step)
                            <div class="flex-1 flex items-center">
                                <div class="flex flex-col items-center gap-2 text-center">
                                    <span
                                        class="w-9 h-9 rounded-full flex items-center justify-center text-xs font-semibold transition-all duration-300"
                                        :class="stepIndex(selected.status) > {{ $i }} ? 'bg-emerald-500 text-white shadow-sm' : (stepIndex(selected.status) === {{ $i }} ? 'bg-brand-600 text-white shadow-card ring-4 ring-brand-100' : 'bg-slate-100 text-slate-400')"
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
                                <span class="w-8 h-8 rounded-lg bg-white text-brand-600 border border-slate-200 flex items-center justify-center shrink-0"><i data-lucide="user-round" class="w-4 h-4"></i></span>
                                <div class="min-w-0">
                                    <p class="text-[10px] text-slate-400 uppercase tracking-wide">Citizen</p>
                                    <p class="text-sm font-medium text-navy-900 truncate" x-text="selected.citizen"></p>
                                </div>
                            </div>
                            <div class="flex items-center gap-2.5 px-4 py-3">
                                <span class="w-8 h-8 rounded-lg bg-white text-brand-600 border border-slate-200 flex items-center justify-center shrink-0"><i data-lucide="file-text" class="w-4 h-4"></i></span>
                                <div class="min-w-0">
                                    <p class="text-[10px] text-slate-400 uppercase tracking-wide">Document</p>
                                    <p class="text-sm font-medium text-navy-900 truncate" x-text="selected.type"></p>
                                </div>
                            </div>
                            <div class="flex items-center gap-2.5 px-4 py-3">
                                <span class="w-8 h-8 rounded-lg bg-white text-brand-600 border border-slate-200 flex items-center justify-center shrink-0"><i data-lucide="landmark" class="w-4 h-4"></i></span>
                                <div class="min-w-0">
                                    <p class="text-[10px] text-slate-400 uppercase tracking-wide">Processing Office</p>
                                    <p class="text-sm font-medium text-navy-900 truncate" x-text="selected.office"></p>
                                </div>
                            </div>
                            <div class="flex items-center gap-2.5 px-4 py-3">
                                <span class="w-8 h-8 rounded-lg bg-white text-brand-600 border border-slate-200 flex items-center justify-center shrink-0"><i data-lucide="map-pin" class="w-4 h-4"></i></span>
                                <div class="min-w-0">
                                    <p class="text-[10px] text-slate-400 uppercase tracking-wide">Barangay</p>
                                    <p class="text-sm font-medium text-navy-900 truncate" x-text="'Brgy. ' + selected.barangay"></p>
                                </div>
                            </div>
                            <div class="flex items-center gap-2.5 px-4 py-3 sm:col-span-2">
                                <span class="w-8 h-8 rounded-lg bg-white text-brand-600 border border-slate-200 flex items-center justify-center shrink-0"><i data-lucide="calendar" class="w-4 h-4"></i></span>
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
