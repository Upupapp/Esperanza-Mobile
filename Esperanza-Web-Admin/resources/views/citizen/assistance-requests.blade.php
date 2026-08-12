@php
    $requests = [
        ['ref' => 'AR-2026-0142', 'type' => 'Medical Assistance (AICS)', 'office' => 'MSWDO', 'purpose' => 'Hospital bill support — Masbate Provincial Hospital', 'submitted' => 'Jun 28, 2026', 'status' => 'Approved'],
        ['ref' => 'AR-2026-0098', 'type' => 'Educational Assistance', 'office' => 'MSWDO', 'purpose' => 'Tuition support for 2 dependents, SY 2026-2027', 'submitted' => 'May 20, 2026', 'status' => 'Released'],
        ['ref' => 'AR-2026-0061', 'type' => 'Financial Assistance (AICS)', 'office' => 'MSWDO', 'purpose' => 'Livelihood capital support', 'submitted' => 'Apr 2, 2026', 'status' => 'Completed'],
        ['ref' => 'AR-2026-0037', 'type' => 'Social Pension (Indigent Senior Citizen)', 'office' => 'OSCA', 'purpose' => 'Quarterly social pension enrollment', 'submitted' => 'Feb 10, 2026', 'status' => 'Completed'],
    ];

    $assistanceTypes = [
        [
            'name' => 'Medical Assistance (AICS)', 'office' => 'MSWDO', 'amount' => '₱1,000 – ₱150,000 per case', 'fee' => 'Free', 'days' => '3-5 working days', 'icon' => 'stethoscope',
            'desc' => 'Hospital bills, medicines, and treatment support under DSWD\'s Assistance to Individuals in Crisis Situation.',
            'requirements' => ['One (1) valid government-issued ID', "Medical Abstract or Doctor's prescription", 'Hospital bill or Statement of Account', 'Barangay Certificate of Indigency'],
            'process' => ['Submit Request', 'MSWDO Assessment', 'Approval', 'Cash / Guarantee Letter Release'],
        ],
        [
            'name' => 'Burial Assistance (AICS)', 'office' => 'MSWDO', 'amount' => 'Up to ₱5,000', 'fee' => 'Free', 'days' => '2-3 working days', 'icon' => 'flower',
            'desc' => 'Financial aid for funeral and burial expenses. Must be filed within 15 days from date of death.',
            'requirements' => ['Death Certificate', 'Valid ID of claimant', 'Proof of relationship to the deceased', 'Funeral contract or bill', 'Barangay Certificate of Indigency'],
            'process' => ['Submit Request', 'Verify Death Certificate', 'Approval', 'Release'],
        ],
        [
            'name' => 'Educational Assistance', 'office' => "MSWDO / Mayor's Office", 'amount' => 'Tuition + allowance per semester', 'fee' => 'Free', 'days' => '10-15 working days', 'icon' => 'graduation-cap',
            'desc' => 'Municipal scholarship and school supplies support for indigent students in good academic standing.',
            'requirements' => ['Certificate of Enrollment', 'Report Card / Form 138 (GWA 80 and above)', 'Certificate of Indigency (family income below ₱120,000/year)', 'Barangay Residency Certificate'],
            'process' => ['Submit Requirements', 'Scholarship Committee Review', 'Approval', 'Disbursement'],
        ],
        [
            'name' => 'Financial Assistance (AICS)', 'office' => 'MSWDO', 'amount' => 'Based on social worker assessment', 'fee' => 'Free', 'days' => '3-5 working days', 'icon' => 'wallet',
            'desc' => 'Cash assistance for individuals and families in crisis situations.',
            'requirements' => ['One (1) valid government-issued ID', 'Barangay Certificate of Indigency', 'Brief interview / social case study with MSWDO'],
            'process' => ['Submit Request', 'Social Case Study', 'Approval', 'Release'],
        ],
        [
            // DSWD Family Assistance Card in Emergencies and Disasters (FACED)
            'name' => 'Food / Relief Assistance', 'office' => 'MSWDO / MDRRMO', 'amount' => 'Relief goods package', 'fee' => 'Free', 'days' => '1-2 working days', 'icon' => 'package',
            'desc' => 'Food packs and relief goods for families affected by calamities or emergencies.',
            'requirements' => ['Barangay Certification', 'One (1) valid government-issued ID'],
            'process' => ['Submit Request', 'Barangay Verification', 'Approval', 'Distribution'],
            'certTitle' => 'Family Assistance Card in Emergencies and Disasters (FACED)',
            'certSubtitle' => 'Head of Family details, per DSWD FACED card',
            'fields' => [
                ['key' => 'evacuation_center', 'label' => 'Evacuation Center / Site (if applicable)', 'type' => 'text'],
                ['key' => 'civil_status', 'label' => 'Civil Status', 'type' => 'select', 'options' => ['Single', 'Married', 'Widowed', 'Separated']],
                ['key' => 'mother_maiden_name', 'label' => "Mother's Maiden Name", 'type' => 'text'],
                ['key' => 'monthly_income', 'label' => 'Monthly Family Net Income', 'type' => 'text'],
                ['key' => 'type_of_vulnerability', 'label' => 'Type of Vulnerability', 'type' => 'checkbox-group', 'allowOther' => true, 'options' => ['4Ps Beneficiary', 'Indigenous Person', 'Person with Disability', 'Senior Citizen', 'Solo Parent']],
                ['key' => 'house_ownership', 'label' => 'House Ownership', 'type' => 'select', 'options' => ['Owner', 'Renter', 'Sharer', 'Informal Settler']],
                ['key' => 'shelter_damage', 'label' => 'Shelter Damage Classification', 'type' => 'select', 'options' => ['None', 'Partially Damaged', 'Totally Damaged']],
                ['key' => 'family_members', 'label' => 'Family Members', 'type' => 'table', 'rowIcon' => 'user-round', 'rowLabel' => 'Family Member', 'columns' => [
                    ['key' => 'name', 'label' => 'Name'],
                    ['key' => 'relation', 'label' => 'Relation to Head', 'options' => ['Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'Brother', 'Sister', 'Grandchild', 'Other Relative']],
                    ['key' => 'dob', 'label' => 'Date of Birth', 'type' => 'date'],
                    ['key' => 'age', 'label' => 'Age', 'type' => 'number'],
                    ['key' => 'sex', 'label' => 'Sex', 'options' => ['Male', 'Female']],
                    ['key' => 'education', 'label' => 'Educational Attainment', 'options' => ['None', 'Elementary', 'High School', 'Vocational', 'College', 'Post Graduate']],
                    ['key' => 'occupation', 'label' => 'Occupation'],
                    ['key' => 'vulnerability', 'label' => 'Vulnerability', 'options' => ['None', '4Ps Beneficiary', 'Indigenous Person', 'Person with Disability', 'Senior Citizen', 'Solo Parent']],
                ]],
            ],
        ],
        [
            'name' => 'Social Pension (Indigent Senior Citizen)', 'office' => 'OSCA', 'amount' => '₱1,000/month (₱3,000 per quarter)', 'fee' => '₱100.00', 'days' => '5-7 working days', 'icon' => 'users',
            'desc' => 'Monthly stipend for indigent senior citizens 60 and above with no pension or regular income.',
            'requirements' => ['Senior Citizen ID', 'Affidavit of no pension, income, or family support (notarized)', 'Barangay Certification'],
            'process' => ['Submit Requirements', 'OSCA / DSWD Verification', 'Enrollment', 'Quarterly Release'],
        ],
        [
            // DSWD Application Form for Solo Parent, Annex B (2023), per RA 11861
            'name' => 'Solo Parent Cash Assistance', 'office' => 'MSWDO', 'amount' => 'Cash grant + goods, per assessment', 'fee' => 'Free', 'days' => '3-5 working days', 'icon' => 'heart-handshake',
            'desc' => 'Support for solo parents under the Expanded Solo Parents Welfare Act (RA 11861).',
            'requirements' => ['Solo Parent ID', 'PSA Birth Certificate(s) of children', 'Barangay Certification'],
            'process' => ['Submit Requirements', 'MSWDO Assessment', 'Approval', 'Release'],
            'certTitle' => 'Application Form for Solo Parent',
            'certSubtitle' => 'Annex B (2023) — Local Social Welfare and Development Office',
            'fields' => [
                ['key' => 'age', 'label' => 'Age', 'type' => 'number'],
                ['key' => 'civil_status', 'label' => 'Civil Status', 'type' => 'select', 'options' => ['Single', 'Married', 'Widowed', 'Separated', 'Annulled']],
                ['key' => 'educational_attainment', 'label' => 'Educational Attainment', 'type' => 'text'],
                ['key' => 'occupation', 'label' => 'Occupation', 'type' => 'text'],
                ['key' => 'employment_status', 'label' => 'Employment Status', 'type' => 'select', 'options' => ['Employed', 'Self-employed', 'Not employed']],
                ['key' => 'monthly_income', 'label' => 'Monthly Income', 'type' => 'text'],
                ['key' => 'is_pantawid_beneficiary', 'label' => 'Pantawid (4Ps) Beneficiary?', 'type' => 'select', 'options' => ['Yes', 'No']],
                ['key' => 'solo_parent_circumstance', 'label' => 'Circumstance of Being a Solo Parent', 'type' => 'text'],
                ['key' => 'solo_parent_needs', 'label' => 'Needs / Problems as a Solo Parent', 'type' => 'text'],
                ['key' => 'emergency_contact_name', 'label' => 'In Case of Emergency — Name', 'type' => 'text'],
                ['key' => 'emergency_contact_relationship', 'label' => 'In Case of Emergency — Relationship', 'type' => 'text'],
                ['key' => 'family_composition', 'label' => 'Family Composition', 'type' => 'table', 'rowIcon' => 'user-round', 'rowLabel' => 'Family Member', 'columns' => [
                    ['key' => 'name', 'label' => 'Name'],
                    ['key' => 'relationship', 'label' => 'Relationship', 'options' => ['Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'Brother', 'Sister', 'Grandchild', 'Other Relative']],
                    ['key' => 'age', 'label' => 'Age', 'type' => 'number'],
                    ['key' => 'birthday', 'label' => 'Birthday', 'type' => 'date'],
                    ['key' => 'civil_status', 'label' => 'Civil Status', 'options' => ['Single', 'Married', 'Widowed', 'Separated', 'Annulled']],
                    ['key' => 'educational_attainment', 'label' => 'Educational Attainment', 'options' => ['None', 'Elementary', 'High School', 'Vocational', 'College', 'Post Graduate']],
                    ['key' => 'occupation', 'label' => 'Occupation'],
                    ['key' => 'monthly_income', 'label' => 'Monthly Income'],
                ]],
            ],
        ],
    ];

    // Attach expected-processing-time onto each seeded request by matching its
    // type against $assistanceTypes, same mechanism as the Dokyu tracker.
    $daysByAssistType = collect($assistanceTypes)->pluck('days', 'name');
    foreach ($requests as &$r) {
        $r['days'] = $daysByAssistType[$r['type']] ?? '3-5 working days';
    }
    unset($r);

    // Where to follow up / claim assistance, keyed by office name.
    $pickupDirectory = [
        'MSWDO' => ['contact' => '(056) 333-1044', 'address' => 'Municipal Hall, Poblacion, Esperanza, Masbate'],
        'OSCA' => ['contact' => '(056) 333-1088', 'address' => 'Municipal Hall, Poblacion, Esperanza, Masbate'],
        "Mayor's Office" => ['contact' => '(056) 333-1021', 'address' => 'Municipal Hall, Poblacion, Esperanza, Masbate'],
        'MDRRMO' => ['contact' => '(056) 333-1090', 'address' => 'Municipal Hall, Poblacion, Esperanza, Masbate'],
    ];

    $submittedDocs = [
        ['name' => 'PhilSys National ID.jpg', 'category' => 'IMG'],
        ['name' => 'Barangay Certificate of Indigency.pdf', 'category' => 'PDF'],
        ['name' => 'Medical Abstract.pdf', 'category' => 'PDF'],
        ['name' => 'Hospital Bill.pdf', 'category' => 'PDF'],
        ['name' => 'Senior Citizen ID.jpg', 'category' => 'IMG'],
    ];
@endphp

<x-layouts.citizen title="Tulong" subtitle="Submit and follow up assistance program requests." active="assistance-requests">
    <div
        x-data="{
            open: false,
            tab: 'all',
            requests: @js($requests),
            doneStatuses: ['Completed', 'Released', 'Rejected'],
            get filteredRequests() {
                return this.requests.filter(r => {
                    if (this.tab === 'all') return true;
                    const isDone = this.doneStatuses.includes(r.status);
                    return this.tab === 'done' ? isDone : !isDone;
                });
            },
            pickupDirectory: @js($pickupDirectory),
            progressOpen: false,
            selectedRequest: null,
            openProgress(r) { this.selectedRequest = r; this.progressOpen = true; },
            stepOrder: ['Submitted', 'Assigned', 'Approved', 'Released'],
            stepIndex(status) {
                const map = { 'Submitted': 0, 'Pending Review': 0, 'Assigned': 1, 'Waiting Requirements': 1, 'Processing': 1, 'Approved': 2, 'Released': 3, 'Completed': 3, 'Rejected': 0 };
                return map[status] ?? 0;
            },
            get pickupInfo() {
                const r = this.selectedRequest;
                if (!r) return null;
                const primaryOffice = r.office.split('/')[0].trim();
                return this.pickupDirectory[primaryOffice] || { contact: 'Municipal Hall Trunkline (056) 333-1000', address: 'Municipal Hall, Poblacion, Esperanza, Masbate' };
            },
            get expectedRelease() {
                const r = this.selectedRequest;
                if (!r) return '';
                const match = r.days.match(/(\d+)(?!.*\d)/);
                const addDays = match ? parseInt(match[1]) : 5;
                const d = new Date(r.submitted);
                d.setDate(d.getDate() + addDays);
                return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
            },
        }"
        class="animate-fade-up"
    >

        <x-ui.page-intro id="tulong" icon="hand-heart" title="Paano gumagana ang Tulong" titleEn="How Tulong works" color="purple">
            <x-ui.t
                fil="Piliin ang programang tulong o ayuda na kailangan mo, sabihin sa amin ang iyong sitwasyon, ikabit ang mga requirement, pagkatapos i-submit. Halos lahat ng programa rito ay libreng i-apply — nagsisimula sa AR- ang reference number."
                en="Choose the assistance or ayuda program you need, tell us about your situation, attach your requirements, then submit. Almost every program here is free to apply for — reference numbers start with AR-."
            />
        </x-ui.page-intro>

        <div class="grid grid-cols-2 lg:grid-cols-5 gap-3 mb-4">
            <x-ui.stat-card label="Kabuuang Kahilingan" labelEn="Total Requests" value="4" icon="hand-heart" color="purple" :delay="0" />
            <x-ui.stat-card label="Aprubado" labelEn="Approved" value="1" icon="circle-check" color="green" :delay="40" />
            <x-ui.stat-card label="Na-release" labelEn="Released" value="1" icon="package-check" color="brand" :delay="80" />
            <x-ui.stat-card label="Kumpleto" labelEn="Completed" value="2" icon="badge-check" color="gold" :delay="120" />
            <x-ui.stat-card label="Natanggap na Ayuda" labelEn="Ayuda Received" value="₱42,500" icon="hand-coins" color="green" sublabel="Kabuuang natanggap na tulong" sublabelEn="Total aid received" :delay="160" />
        </div>

        <div class="flex items-center gap-3 mb-3">
            <h3 class="text-sm font-semibold text-navy-900"><x-ui.t fil="Aking mga Kahilingan" en="My Requests" /></h3>
            <x-citizen.status-guide />
        </div>

        <div class="bg-white border border-slate-200 rounded-2xl shadow-card px-3 py-2.5 mb-4">
            <div class="flex flex-wrap items-center justify-between gap-2">
                <div class="flex items-center gap-2.5 min-w-0">
                    <div class="flex items-center gap-1.5 bg-slate-100/70 rounded-xl p-1 w-fit overflow-x-auto shrink-0">
                        @foreach(['all' => ['Lahat', 'All'], 'active' => ['Isinasagawa', 'In Progress'], 'done' => ['Kumpleto', 'Completed']] as $key => [$labelFil, $labelEn])
                            <button
                                @click="tab = '{{ $key }}'"
                                class="px-3 py-1.5 text-[11px] font-medium rounded-lg transition-colors whitespace-nowrap"
                                :class="tab === '{{ $key }}' ? 'bg-white text-navy-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'"
                            ><x-ui.t :fil="$labelFil" :en="$labelEn" /></button>
                        @endforeach
                    </div>
                    <p class="text-[11px] text-slate-400 shrink-0" x-text="filteredRequests.length + ' ' + ($store.lang.current === 'en' ? 'of ' + requests.length + ' requests' : 'sa ' + requests.length + ' kahilingan')"></p>
                </div>

            <div
                x-data="{
                    open: false,
                    step: 1,
                    selectedType: null,
                    attachments: {},
                    showFilePicker: null,
                    submitted: false,
                    submitting: false,
                    paymentMethod: null,
                    alreadyPaid: false,
                    receipt: null,
                    showReceiptPicker: false,
                    types: @js($assistanceTypes),
                    files: @js($submittedDocs),
                    search: '',
                    formData: {},
                    get filteredTypes() { return this.types.map((t, i) => ({ ...t, i })).filter(t => t.name.toLowerCase().includes(this.search.toLowerCase())); },
                    selectType(i) {
                        this.selectedType = i;
                        this.attachments = {};
                        this.formData = {};
                        (this.types[i]?.fields || []).forEach(f => {
                            if (f.type === 'checkbox-group') { this.formData[f.key] = []; }
                            else if (f.type === 'table') { this.formData[f.key] = []; }
                            else { this.formData[f.key] = f.default || ''; }
                        });
                    },
                    toggleChecklist(fieldKey, option) {
                        const list = this.formData[fieldKey] || [];
                        const i = list.indexOf(option);
                        if (i === -1) { list.push(option); } else { list.splice(i, 1); }
                        this.formData[fieldKey] = list;
                    },
                    addTableRow(f) {
                        if (!this.formData[f.key]) this.formData[f.key] = [];
                        const row = {};
                        f.columns.forEach(c => { row[c.key] = ''; });
                        this.formData[f.key].push(row);
                    },
                    applicant: { firstName: '', lastName: '', address: '', mobile: '', email: '' },
                    seedApplicant() {
                        const a = this.$store.citizenSession.account;
                        this.applicant = a ? {
                            firstName: a.firstName, lastName: a.lastName, address: a.address, mobile: a.mobile, email: a.email,
                        } : { firstName: '', lastName: '', address: '', mobile: '', email: '' };
                    },
                    paymentMethods: [
                        { key: 'gcash', label: 'GCash', hint: 'Send to 0917-000-0000', hintFil: 'Ipadala sa 0917-000-0000', icon: 'smartphone' },
                        { key: 'paymaya', label: 'PayMaya', hint: 'Send to 0918-000-0000', hintFil: 'Ipadala sa 0918-000-0000', icon: 'wallet' },
                        { key: 'center', label: 'Payment in Center', labelFil: 'Bayad sa Opisina', hint: 'Pay at the MSWDO / OSCA office', hintFil: 'Magbayad sa opisina ng MSWDO / OSCA', icon: 'landmark' },
                    ],
                    stepLabels: {
                        fil: ['Pumili ng Tulong', 'Detalye ng Aplikasyon', 'Bayad', 'I-review at I-submit'],
                        en: ['Choose Assistance', 'Application Details', 'Payment', 'Review & Submit'],
                    },
                    stepIcons: ['hand-heart', 'user-round', 'credit-card', 'clipboard-check'],
                    reset() { this.step = 1; this.selectedType = null; this.attachments = {}; this.showFilePicker = null; this.submitted = false; this.paymentMethod = null; this.alreadyPaid = false; this.receipt = null; this.showReceiptPicker = false; this.search = ''; this.formData = {}; },
                    submitRequest() {
                        const type = this.types[this.selectedType];
                        this.requests.unshift({
                            ref: 'AR-2026-' + Math.floor(1000 + Math.random() * 9000),
                            type: type?.name || '—',
                            office: type?.office || '—',
                            purpose: type?.name || '—',
                            days: type?.days || '3-5 working days',
                            submitted: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
                            status: 'Submitted',
                        });
                    },
                }"
                x-init="seedApplicant(); $watch('$store.citizenSession.account', () => seedApplicant())"
                x-effect="!open && reset()"
                class="contents"
            >
                <div class="flex items-center gap-2 shrink-0">
                <x-ui.button @click="open = true" icon="hand-heart" size="sm" class="shrink-0"><x-ui.t fil="Bagong Kahilingan sa Tulong" en="New Tulong Request" /></x-ui.button>
                <x-ui.modal title="Bagong Kahilingan sa Tulong" titleEn="New Tulong Request" maxWidth="3xl">
                    <!-- Success state -->
                    <div x-show="submitted" x-cloak x-transition.opacity class="flex flex-col items-center justify-center text-center py-10">
                        <div class="relative flex items-center justify-center mb-4 w-16 h-16">
                            <span class="absolute inline-flex h-16 w-16 rounded-full bg-emerald-400/40 animate-ring-pulse"></span>
                            <span class="absolute inline-flex h-16 w-16 rounded-full bg-emerald-400/40 animate-ring-pulse" style="animation-delay: 0.35s;"></span>
                            <span class="relative w-14 h-14 rounded-full bg-emerald-500 text-white flex items-center justify-center animate-check-pop">
                                <i data-lucide="check" class="w-7 h-7"></i>
                            </span>
                        </div>
                        <p class="text-sm font-semibold text-navy-900">
                            <x-ui.t fil="Naisumite ang Kahilingan!" en="Request Submitted!" />
                            <span class="inline-block animate-check-pop" style="animation-delay: 0.3s;">🙂</span>
                        </p>
                        <p class="text-xs text-slate-400 mt-1 max-w-[220px]"><x-ui.t fil="Aabisuhan ka namin kapag na-review na ang iyong kahilingan sa Tulong." en="We'll notify you once your Tulong request is reviewed." /></p>
                    </div>

                    <div x-show="!submitted">
                    <!-- Step indicator -->
                    <div class="flex items-center mb-8 px-1">
                        <template x-for="(label, i) in ($store.lang.current === 'en' ? stepLabels.en : stepLabels.fil)" :key="i">
                            <div class="flex-1 flex items-center">
                                <div class="flex flex-col items-center gap-2 text-center">
                                    <span
                                        class="w-9 h-9 rounded-full flex items-center justify-center shrink-0 transition-all duration-300"
                                        :class="step > i + 1 ? 'bg-emerald-500 text-white shadow-sm' : (step === i + 1 ? 'bg-purple-600 text-white shadow-card ring-4 ring-purple-100' : 'bg-slate-100 text-slate-400')"
                                    >
                                        <i data-lucide="check" class="w-4 h-4" x-show="step > i + 1" x-cloak></i>
                                        <i :data-lucide="stepIcons[i]" class="w-4 h-4" x-show="step <= i + 1"></i>
                                    </span>
                                    <span class="text-[11px] max-w-[100px] leading-tight transition-colors duration-300" :class="step === i + 1 ? 'text-navy-900 font-semibold' : 'text-slate-400'" x-text="label"></span>
                                </div>
                                <div class="flex-1 h-1 rounded-full mx-1.5 -mt-6 transition-colors duration-300" :class="step > i + 1 ? 'bg-emerald-400' : 'bg-slate-100'" x-show="i < 3"></div>
                            </div>
                        </template>
                    </div>

                    <!-- Step 1: choose assistance type -->
                    <div x-show="step === 1">
                        <p class="text-sm text-slate-500 mb-3"><x-ui.t fil="Piliin ang uri ng tulong na kailangan mo." en="Choose the type of assistance you need." /></p>
                        <div class="relative mb-4">
                            <i data-lucide="search" class="w-3.5 h-3.5 text-slate-300 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"></i>
                            <input
                                type="text" x-model="search"
                                x-bind:placeholder="$store.lang.current === 'en' ? 'Search assistance programs...' : 'Maghanap ng programang tulong...'"
                                class="w-full rounded-xl border border-slate-200 bg-slate-50/60 py-2 pl-8 pr-3 text-xs text-slate-700 placeholder:text-slate-400 focus:bg-white focus:border-purple-400 focus:ring-4 focus:ring-purple-100 outline-none transition-all duration-200"
                            >
                        </div>
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                            <template x-for="type in filteredTypes" :key="type.i">
                                <label
                                    class="relative flex flex-col rounded-xl border p-3.5 cursor-pointer transition-all duration-200"
                                    :class="selectedType === type.i ? 'border-purple-400 bg-purple-50/60 ring-4 ring-purple-100 shadow-sm' : 'border-slate-200 hover:border-slate-300 hover:shadow-sm hover:-translate-y-0.5'"
                                >
                                    <input type="radio" name="assist_type" class="sr-only" :checked="selectedType === type.i" @change="selectType(type.i)">
                                    <div class="flex items-center justify-between mb-2.5">
                                        <span class="w-9 h-9 rounded-lg flex items-center justify-center shrink-0 transition-colors duration-200" :class="selectedType === type.i ? 'bg-purple-600 text-white' : 'bg-slate-100 text-slate-400'">
                                            <i :data-lucide="type.icon" class="w-4 h-4"></i>
                                        </span>
                                        <i data-lucide="circle-check" class="w-4 h-4 text-purple-500" x-show="selectedType === type.i" x-cloak></i>
                                    </div>
                                    <p class="text-sm font-medium text-slate-700 leading-snug" x-text="type.name"></p>
                                    <p class="text-xs text-slate-400 mt-1 truncate" x-text="type.office"></p>
                                    <span
                                        class="inline-block w-fit mt-2.5 text-[11px] font-semibold rounded-full px-2.5 py-1"
                                        :class="type.fee === 'Free' ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-navy-900'"
                                        x-text="type.amount"
                                    ></span>
                                </label>
                            </template>
                            <div class="sm:col-span-2 flex flex-col items-center text-center py-8" x-show="filteredTypes.length === 0">
                                <span class="w-10 h-10 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mb-2"><i data-lucide="search-x" class="w-4.5 h-4.5"></i></span>
                                <p class="text-xs text-slate-400"><x-ui.t fil="Walang programang tumutugma." en="No assistance programs match your search." /></p>
                            </div>
                        </div>
                    </div>

                    <!-- Step 2: application details + requirements -->
                    <div x-show="step === 2" x-cloak>
                        <div class="grid grid-cols-1 lg:grid-cols-5 gap-5 items-start mb-6">
                            <div class="lg:col-span-3">
                                <p class="text-sm font-semibold text-navy-900 mb-1"><x-ui.t fil="Impormasyon ng Aplikante" en="Applicant Information" /></p>
                                <p class="text-xs text-slate-400 mb-3"><x-ui.t fil="Naka-prefill mula sa iyong resident profile — i-edit kung kailangan." en="Pre-filled from your resident profile — edit if needed." /></p>
                                <div class="grid grid-cols-2 gap-3 mb-3">
                                    <x-ui.input name="assist_first_name" label="First Name" x-model="applicant.firstName" />
                                    <x-ui.input name="assist_last_name" label="Last Name" x-model="applicant.lastName" />
                                </div>
                                <div class="mb-3">
                                    <x-ui.input name="assist_address" label="Complete Address" icon="map-pin" x-model="applicant.address" />
                                </div>
                                <div class="grid grid-cols-2 gap-3">
                                    <x-ui.input name="assist_mobile" label="Mobile Number" icon="phone" x-model="applicant.mobile" />
                                    <x-ui.input name="assist_email" type="email" label="Email Address" icon="mail" x-model="applicant.email" />
                                </div>
                            </div>

                            <!-- Live request summary -->
                            <div class="lg:col-span-2">
                                <div class="lg:sticky lg:top-0 rounded-2xl border border-purple-100 bg-gradient-to-br from-purple-50/60 to-white p-4">
                                    <p class="text-xs font-semibold text-navy-900 uppercase tracking-wide mb-3 flex items-center gap-1.5"><i data-lucide="receipt-text" class="w-3.5 h-3.5 text-purple-500"></i><x-ui.t fil="Buod ng Kahilingan" en="Request Summary" /></p>
                                    <div class="flex items-center gap-2.5 mb-3">
                                        <span class="w-10 h-10 rounded-lg bg-purple-600 text-white flex items-center justify-center shrink-0"><i :data-lucide="types[selectedType]?.icon || 'hand-heart'" class="w-4.5 h-4.5"></i></span>
                                        <div class="min-w-0">
                                            <p class="text-sm font-medium text-navy-900 leading-snug" x-text="types[selectedType]?.name"></p>
                                            <p class="text-xs text-slate-400 truncate" x-text="types[selectedType]?.office"></p>
                                        </div>
                                    </div>
                                    <div class="space-y-1.5 text-xs border-t border-purple-100/70 pt-3">
                                        <div class="flex items-center justify-between"><span class="text-slate-400"><x-ui.t fil="Tinatayang Halaga" en="Estimated Amount" /></span><span class="font-semibold text-navy-900 text-right" x-text="types[selectedType]?.amount"></span></div>
                                        <div class="flex items-center justify-between"><span class="text-slate-400"><x-ui.t fil="Oras ng Pagproseso" en="Processing Time" /></span><span class="font-medium text-slate-600" x-text="types[selectedType]?.days"></span></div>
                                        <div class="flex items-center justify-between"><span class="text-slate-400"><x-ui.t fil="Requirements" en="Requirements" /></span><span class="font-medium text-slate-600" x-text="Object.keys(attachments).filter(k => attachments[k]).length + ' / ' + (types[selectedType]?.requirements || []).length + ' attached'"></span></div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Full-width: generic purpose OR structured fields (e.g. Solo Parent Application, FACED) — sits below the two-column grid so it isn't squeezed beside the sticky Request Summary -->
                        <!-- Generic purpose (assistance types without structured fields) -->
                        <div class="mb-6" x-show="!(types[selectedType]?.fields?.length)">
                            <label class="block text-sm font-medium text-slate-700 mb-1.5"><x-ui.t fil="Detalye ng Kahilingan" en="Details of Request" /></label>
                            <textarea rows="3" placeholder="Briefly describe your situation and needs" class="w-full rounded-xl border border-slate-200 bg-slate-50/60 py-2.5 px-4 text-sm text-slate-800 placeholder:text-slate-400 focus:bg-white focus:border-purple-400 focus:ring-4 focus:ring-purple-100 outline-none transition-all duration-200"></textarea>
                        </div>

                        <div class="mb-6" x-show="types[selectedType]?.fields?.length" x-cloak>
                            <p class="text-sm font-semibold text-navy-900 mb-1" x-text="types[selectedType]?.certTitle || ''"></p>
                            <p class="text-xs text-slate-400 mb-3" x-show="types[selectedType]?.certSubtitle" x-text="types[selectedType]?.certSubtitle"></p>
                            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                                <template x-for="f in (types[selectedType]?.fields || []).filter(f => f.type !== 'table')" :key="f.key">
                                    <div :class="f.type === 'checkbox-group' ? 'sm:col-span-2 lg:col-span-3' : ''">
                                        <template x-if="f.type === 'text' || f.type === 'number' || f.type === 'date'">
                                            <div>
                                                <label class="block text-xs font-medium text-slate-700 mb-1" x-text="f.label + (f.required ? ' *' : '')"></label>
                                                <input
                                                    :type="f.type" x-model="formData[f.key]"
                                                    class="w-full rounded-xl border border-slate-200 bg-slate-50/60 py-2.5 px-4 text-sm text-slate-800 focus:bg-white focus:border-purple-400 focus:ring-4 focus:ring-purple-100 outline-none transition-all duration-200"
                                                >
                                            </div>
                                        </template>
                                        <template x-if="f.type === 'select'">
                                            <div>
                                                <label class="block text-xs font-medium text-slate-700 mb-1" x-text="f.label + (f.required ? ' *' : '')"></label>
                                                <select x-model="formData[f.key]" class="w-full rounded-xl border border-slate-200 bg-slate-50/60 py-2.5 px-4 text-sm text-slate-700 focus:bg-white focus:border-purple-400 focus:ring-4 focus:ring-purple-100 outline-none transition-all duration-200">
                                                    <option value="">—</option>
                                                    <template x-for="opt in f.options" :key="opt"><option :value="opt" x-text="opt"></option></template>
                                                </select>
                                            </div>
                                        </template>
                                        <template x-if="f.type === 'checkbox-group'">
                                            <div>
                                                <label class="block text-xs font-medium text-slate-700 mb-2" x-text="f.label"></label>
                                                <div class="grid grid-cols-2 sm:grid-cols-3 gap-2">
                                                    <template x-for="opt in f.options" :key="opt">
                                                        <label class="flex items-center gap-2 rounded-lg border border-slate-200 px-2.5 py-2 text-xs text-slate-600 cursor-pointer hover:border-slate-300 transition-colors" :class="(formData[f.key] || []).includes(opt) && 'border-purple-300 bg-purple-50/60 text-purple-700'">
                                                            <input type="checkbox" class="rounded text-purple-600 focus:ring-purple-200" :checked="(formData[f.key] || []).includes(opt)" @change="toggleChecklist(f.key, opt)">
                                                            <span x-text="opt"></span>
                                                        </label>
                                                    </template>
                                                </div>
                                            </div>
                                        </template>
                                    </div>
                                </template>
                            </div>
                        </div>

                        <!-- Full-width table fields (e.g. Family Composition, FACED Family Members) -->
                        <template x-for="f in (types[selectedType]?.fields || []).filter(f => f.type === 'table')" :key="f.key">
                            <div class="mb-6">
                                <div class="flex items-center justify-between mb-2.5">
                                    <div>
                                        <p class="text-sm font-semibold text-navy-900" x-text="f.label"></p>
                                        <p class="text-xs text-slate-400 mt-0.5"><x-ui.t fil="Idagdag ang bawat miyembro ng sambahayan." en="Add each member of the household." /></p>
                                    </div>
                                    <span class="text-[11px] text-slate-400 shrink-0" x-text="(formData[f.key] || []).length + ' ' + ($store.lang.current === 'en' ? 'added' : 'nadagdag')"></span>
                                </div>
                                <div class="space-y-2.5">
                                    <template x-for="(row, ri) in (formData[f.key] || [])" :key="ri">
                                        <div class="rounded-xl border border-slate-200 bg-slate-50/40 p-3.5">
                                            <div class="flex items-center justify-between mb-3">
                                                <span class="inline-flex items-center gap-1.5 text-[11px] font-semibold text-purple-700 bg-purple-100/70 rounded-full pl-1.5 pr-2.5 py-1">
                                                    <i :data-lucide="f.rowIcon || 'list'" class="w-3 h-3"></i>
                                                    <span x-text="row[f.columns[0].key] || ((f.rowLabel || 'Entry') + ' ' + (ri + 1))"></span>
                                                </span>
                                                <button type="button" @click="formData[f.key].splice(ri, 1)" class="text-slate-300 hover:text-rose-500 transition-colors">
                                                    <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
                                                </button>
                                            </div>
                                            <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
                                                <template x-for="col in f.columns" :key="col.key">
                                                    <div>
                                                        <label class="block text-[10px] font-medium text-slate-400 uppercase tracking-wide mb-1" x-text="col.label"></label>
                                                        <template x-if="col.options">
                                                            <select x-model="row[col.key]" class="w-full rounded-lg border border-slate-200 bg-white py-1.5 px-2.5 text-xs text-slate-800 focus:border-purple-400 focus:ring-2 focus:ring-purple-100 outline-none transition-all duration-150">
                                                                <option value="">—</option>
                                                                <template x-for="opt in col.options" :key="opt"><option :value="opt" x-text="opt"></option></template>
                                                            </select>
                                                        </template>
                                                        <template x-if="!col.options">
                                                            <input :type="col.type === 'date' ? 'date' : (col.type === 'number' ? 'number' : 'text')" x-model="row[col.key]" class="w-full rounded-lg border border-slate-200 bg-white py-1.5 px-2.5 text-xs text-slate-800 focus:border-purple-400 focus:ring-2 focus:ring-purple-100 outline-none transition-all duration-150">
                                                        </template>
                                                    </div>
                                                </template>
                                            </div>
                                        </div>
                                    </template>

                                    <div class="flex flex-col items-center text-center py-6 rounded-xl border-2 border-dashed border-slate-200" x-show="(formData[f.key] || []).length === 0">
                                        <span class="w-9 h-9 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mb-2"><i :data-lucide="f.rowIcon || 'list'" class="w-4 h-4"></i></span>
                                        <p class="text-xs text-slate-400"><x-ui.t fil="Wala pang idinagdag na miyembro." en="No members added yet." /></p>
                                    </div>

                                    <button
                                        type="button" @click="addTableRow(f)"
                                        class="w-full flex items-center justify-center gap-1.5 rounded-xl border-2 border-dashed border-slate-200 hover:border-purple-300 hover:bg-purple-50/40 text-xs font-medium text-slate-500 hover:text-purple-600 py-2.5 transition-all duration-200"
                                    >
                                        <i data-lucide="plus" class="w-3.5 h-3.5"></i>
                                        <span x-text="($store.lang.current === 'en' ? 'Add ' : 'Magdagdag ng ') + (f.rowLabel || 'Entry')"></span>
                                    </button>
                                </div>
                            </div>
                        </template>

                        <div class="flex items-center justify-between mb-1">
                            <p class="text-sm font-semibold text-navy-900"><x-ui.t fil="Mga Requirement" en="Requirements" /></p>
                            <p class="text-[11px] font-medium text-slate-400" x-text="Object.keys(attachments).filter(k => attachments[k]).length + ' / ' + (types[selectedType]?.requirements || []).length"></p>
                        </div>
                        <div class="h-1 rounded-full bg-slate-100 overflow-hidden mb-3">
                            <div class="h-full bg-emerald-400 rounded-full transition-all duration-300" :style="'width:' + (((types[selectedType]?.requirements || []).length ? (Object.keys(attachments).filter(k => attachments[k]).length / (types[selectedType]?.requirements || []).length) : 0) * 100) + '%'"></div>
                        </div>
                        <p class="text-xs text-slate-400 mb-3"><x-ui.t fil="Ikabit mula sa mga file na na-upload mo na, o mag-upload ng bago." en="Attach from your already-uploaded files, or upload a new one." /></p>
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                            <template x-for="(req, i) in types[selectedType]?.requirements || []" :key="i">
                                <div class="rounded-xl border p-3 transition-colors duration-200" :class="attachments[i] ? 'border-emerald-200 bg-emerald-50/30' : 'border-slate-200'">
                                    <div class="flex items-center justify-between gap-3">
                                        <p class="text-xs text-slate-600 flex-1" x-text="req"></p>
                                        <button
                                            type="button" x-show="!attachments[i]"
                                            @click="showFilePicker = (showFilePicker === i ? null : i)"
                                            class="text-[11px] font-medium text-purple-600 hover:underline shrink-0 whitespace-nowrap"
                                        ><x-ui.t fil="Ikabit ang File" en="Attach File" /></button>
                                        <div class="flex items-center gap-1.5 shrink-0" x-show="attachments[i]">
                                            <span class="inline-flex items-center gap-1 text-[11px] text-emerald-600 font-medium whitespace-nowrap">
                                                <i data-lucide="circle-check" class="w-3.5 h-3.5"></i><span x-text="attachments[i]"></span>
                                            </span>
                                            <button type="button" @click="attachments[i] = null" class="text-slate-300 hover:text-rose-500"><i data-lucide="x" class="w-3.5 h-3.5"></i></button>
                                        </div>
                                    </div>
                                    <div x-show="showFilePicker === i" x-cloak x-transition class="mt-2.5 pt-2.5 border-t border-slate-100">
                                        <x-ui.file-picker
                                            files="files"
                                            onSelect="attachments[i] = file.name; showFilePicker = null"
                                            uploadAction="attachments[i] = 'New upload.jpg'; showFilePicker = null; $dispatch('toast', { message: 'File upload is a frontend preview — no data is saved.', variant: 'info' })"
                                            :columns="2"
                                            :search="false"
                                        />
                                    </div>
                                </div>
                            </template>
                        </div>
                    </div>

                    <!-- Step 3: payment -->
                    <div x-show="step === 3" x-cloak>
                        <template x-if="types[selectedType]?.fee === 'Free'">
                            <div class="flex flex-col items-center text-center py-8">
                                <span class="w-12 h-12 rounded-full bg-emerald-50 text-emerald-500 flex items-center justify-center mb-3">
                                    <i data-lucide="badge-check" class="w-6 h-6"></i>
                                </span>
                                <p class="text-sm font-semibold text-navy-900"><x-ui.t fil="Walang Kailangang Bayaran" en="No Payment Required" /></p>
                                <p class="text-xs text-slate-400 mt-1 max-w-[280px]" x-text="types[selectedType]?.name + ($store.lang.current === 'en' ? ' has no application fee under municipal ordinance.' : ' ay walang bayarin sa pag-apply ayon sa municipal ordinance.')"></p>
                            </div>
                        </template>

                        <template x-if="types[selectedType]?.fee !== 'Free'">
                            <div class="grid grid-cols-1 lg:grid-cols-5 gap-5 items-start">
                                <div class="lg:col-span-3 order-2 lg:order-1">
                                    <template x-if="!alreadyPaid">
                                        <div>
                                            <p class="text-sm font-semibold text-navy-900 mb-3"><x-ui.t fil="Piliin ang Paraan ng Pagbabayad" en="Choose Payment Method" /></p>
                                            <div class="space-y-2 mb-4">
                                                <template x-for="m in paymentMethods" :key="m.key">
                                                    <label
                                                        class="flex items-center gap-3 rounded-xl border p-3 cursor-pointer transition-all duration-200"
                                                        :class="paymentMethod === m.key ? 'border-purple-400 bg-purple-50/60 ring-4 ring-purple-100' : 'border-slate-200 hover:border-slate-300'"
                                                    >
                                                        <input type="radio" name="assist_payment_method" class="text-purple-600 focus:ring-purple-200" :checked="paymentMethod === m.key" @change="paymentMethod = m.key">
                                                        <span class="w-8 h-8 rounded-lg bg-slate-100 text-slate-500 flex items-center justify-center shrink-0">
                                                            <i :data-lucide="m.icon" class="w-4 h-4"></i>
                                                        </span>
                                                        <div class="min-w-0">
                                                            <p class="text-sm font-medium text-slate-700" x-text="$store.lang.current === 'en' ? m.label : (m.labelFil || m.label)"></p>
                                                            <p class="text-xs text-slate-400" x-text="$store.lang.current === 'en' ? m.hint : (m.hintFil || m.hint)"></p>
                                                        </div>
                                                    </label>
                                                </template>
                                            </div>
                                            <button type="button" @click="alreadyPaid = true" class="text-xs font-medium text-purple-600 hover:underline"><x-ui.t fil="Nakabayad na ako — ikakabit ang resibo" en="I've already paid — attach my receipt instead" /></button>
                                        </div>
                                    </template>

                                    <template x-if="alreadyPaid">
                                        <div>
                                            <div class="flex items-center justify-between mb-3">
                                                <p class="text-sm font-semibold text-navy-900"><x-ui.t fil="Ikabit ang Patunay ng Bayad" en="Attach Proof of Payment" /></p>
                                                <button type="button" @click="alreadyPaid = false; receipt = null" class="text-xs font-medium text-slate-400 hover:text-slate-600"><x-ui.t fil="Kanselahin" en="Cancel" /></button>
                                            </div>
                                            <div class="rounded-xl border border-slate-200 p-3">
                                                <div class="flex items-center justify-between gap-3">
                                                    <p class="text-xs text-slate-600 flex-1"><x-ui.t fil="Resibo o screenshot ng kumpirmasyon ng bayad" en="Receipt or payment confirmation screenshot" /></p>
                                                    <button
                                                        type="button" x-show="!receipt"
                                                        @click="showReceiptPicker = !showReceiptPicker"
                                                        class="text-[11px] font-medium text-purple-600 hover:underline shrink-0 whitespace-nowrap"
                                                    ><x-ui.t fil="Ikabit ang File" en="Attach File" /></button>
                                                    <div class="flex items-center gap-1.5 shrink-0" x-show="receipt">
                                                        <span class="inline-flex items-center gap-1 text-[11px] text-emerald-600 font-medium whitespace-nowrap">
                                                            <i data-lucide="circle-check" class="w-3.5 h-3.5"></i><span x-text="receipt"></span>
                                                        </span>
                                                        <button type="button" @click="receipt = null" class="text-slate-300 hover:text-rose-500"><i data-lucide="x" class="w-3.5 h-3.5"></i></button>
                                                    </div>
                                                </div>
                                                <div x-show="showReceiptPicker" x-cloak x-transition class="mt-2.5 pt-2.5 border-t border-slate-100">
                                                    <x-ui.file-picker
                                                        files="files"
                                                        onSelect="receipt = file.name; showReceiptPicker = false"
                                                        uploadAction="receipt = 'Receipt Scan.jpg'; showReceiptPicker = false; $dispatch('toast', { message: 'File upload is a frontend preview — no data is saved.', variant: 'info' })"
                                                        :columns="2"
                                                        :search="false"
                                                    />
                                                </div>
                                            </div>
                                        </div>
                                    </template>
                                </div>

                                <!-- Invoice -->
                                <div class="lg:col-span-2 order-1 lg:order-2">
                                    <div class="lg:sticky lg:top-0 rounded-xl border border-slate-200 overflow-hidden">
                                        <div class="flex items-center justify-between px-4 py-3 bg-slate-50 border-b border-slate-100">
                                            <p class="text-xs font-semibold text-navy-900 uppercase tracking-wide"><x-ui.t fil="Buod ng Invoice" en="Invoice Summary" /></p>
                                        </div>
                                        <div class="px-4 py-3.5 text-sm">
                                            <p class="text-[10px] font-mono text-slate-400 mb-2">Municipality of Esperanza</p>
                                            <div class="flex items-center justify-between py-1.5">
                                                <span class="text-slate-500"><x-ui.t fil="Sisingilin" en="Bill To" /></span>
                                                <span class="text-slate-700 font-medium" x-text="applicant.firstName + ' ' + applicant.lastName"></span>
                                            </div>
                                            <div class="flex items-center justify-between py-1.5">
                                                <span class="text-slate-500"><x-ui.t fil="Item" en="Item" /></span>
                                                <span class="text-slate-700 font-medium text-right" x-text="$store.lang.current === 'en' ? 'Documentary / Notarization Fee' : 'Bayarin sa Dokumento / Notaryo'"></span>
                                            </div>
                                            <div class="flex items-center justify-between py-1.5">
                                                <span class="text-slate-500"><x-ui.t fil="Kaugnay na Aplikasyon" en="Related Application" /></span>
                                                <span class="text-slate-700 font-medium text-right" x-text="types[selectedType]?.name"></span>
                                            </div>
                                            <div class="flex items-center justify-between py-1.5">
                                                <span class="text-slate-500"><x-ui.t fil="Kokolektang Opisina" en="Collecting Office" /></span>
                                                <span class="text-slate-700 font-medium" x-text="types[selectedType]?.office"></span>
                                            </div>
                                            <div class="border-t border-dashed border-slate-200 my-2"></div>
                                            <div class="flex items-center justify-between py-1">
                                                <span class="text-sm font-semibold text-navy-900 inline-flex items-center gap-1">
                                                    <x-ui.t fil="Kabuuang Babayaran" en="Total Due" />
                                                    <x-ui.tooltip text="This documentary fee is separate from your assistance amount — it won't be deducted from the aid you receive.">
                                                        <i data-lucide="info" class="w-3 h-3 text-slate-300 hover:text-slate-500 cursor-help"></i>
                                                    </x-ui.tooltip>
                                                </span>
                                                <span class="text-base font-bold text-purple-700" x-text="types[selectedType]?.fee"></span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </template>
                    </div>

                    <!-- Step 4: review & submit -->
                    <div x-show="step === 4" x-cloak>
                        <p class="text-sm font-semibold text-navy-900 mb-3"><x-ui.t fil="I-review ang Iyong Kahilingan" en="Review Your Request" /></p>
                        <div class="rounded-xl border border-slate-200 overflow-hidden mb-5">
                            <div class="grid grid-cols-1 sm:grid-cols-2 divide-y sm:divide-y-0 sm:divide-x divide-slate-100 bg-slate-50/60">
                                <div class="flex items-center gap-2.5 px-4 py-3">
                                    <span class="w-8 h-8 rounded-lg bg-white text-purple-600 border border-slate-200 flex items-center justify-center shrink-0"><i :data-lucide="types[selectedType]?.icon || 'hand-heart'" class="w-4 h-4"></i></span>
                                    <div class="min-w-0">
                                        <p class="text-[10px] text-slate-400 uppercase tracking-wide"><x-ui.t fil="Uri ng Tulong" en="Assistance Type" /></p>
                                        <p class="text-sm font-medium text-navy-900 truncate" x-text="types[selectedType]?.name || ''"></p>
                                    </div>
                                </div>
                                <div class="flex items-center gap-2.5 px-4 py-3">
                                    <span class="w-8 h-8 rounded-lg bg-white text-purple-600 border border-slate-200 flex items-center justify-center shrink-0"><i data-lucide="landmark" class="w-4 h-4"></i></span>
                                    <div class="min-w-0">
                                        <p class="text-[10px] text-slate-400 uppercase tracking-wide"><x-ui.t fil="Nangangasiwang Opisina" en="Handling Office" /></p>
                                        <p class="text-sm font-medium text-navy-900 truncate" x-text="types[selectedType]?.office || ''"></p>
                                    </div>
                                </div>
                                <div class="flex items-center gap-2.5 px-4 py-3">
                                    <span class="w-8 h-8 rounded-lg bg-white text-purple-600 border border-slate-200 flex items-center justify-center shrink-0"><i data-lucide="user-round" class="w-4 h-4"></i></span>
                                    <div class="min-w-0">
                                        <p class="text-[10px] text-slate-400 uppercase tracking-wide"><x-ui.t fil="Aplikante" en="Applicant" /></p>
                                        <p class="text-sm font-medium text-navy-900 truncate" x-text="applicant.firstName + ' ' + applicant.lastName"></p>
                                    </div>
                                </div>
                                <div class="flex items-center gap-2.5 px-4 py-3">
                                    <span class="w-8 h-8 rounded-lg bg-white text-purple-600 border border-slate-200 flex items-center justify-center shrink-0"><i data-lucide="wallet" class="w-4 h-4"></i></span>
                                    <div class="min-w-0">
                                        <p class="text-[10px] text-slate-400 uppercase tracking-wide"><x-ui.t fil="Bayarin sa Dokumento" en="Documentary Fee" /></p>
                                        <p class="text-sm font-medium text-navy-900 truncate">
                                            <template x-if="types[selectedType]?.fee === 'Free'"><span><x-ui.t fil="Hindi aplikable" en="Not applicable" /></span></template>
                                            <template x-if="types[selectedType]?.fee !== 'Free' && alreadyPaid"><span x-text="$store.lang.current === 'en' ? 'Paid — receipt attached' : 'Nabayaran na — nakakabit ang resibo'"></span></template>
                                            <template x-if="types[selectedType]?.fee !== 'Free' && !alreadyPaid"><span x-text="paymentMethod ? (paymentMethods.find(m => m.key === paymentMethod)?.label || '') : ($store.lang.current === 'en' ? 'Not selected' : 'Wala pang napili')"></span></template>
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Structured field details (Solo Parent, FACED, etc.) -->
                        <div class="mb-5" x-show="types[selectedType]?.fields?.length" x-cloak>
                            <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2"><x-ui.t fil="Detalye ng Aplikasyon" en="Application Details" /></p>
                            <div class="rounded-xl border border-slate-200 divide-y divide-slate-100">
                                <template x-for="f in (types[selectedType]?.fields || []).filter(f => f.type !== 'table')" :key="f.key">
                                    <div class="flex items-center justify-between gap-3 px-3.5 py-2 text-xs" x-show="formData[f.key] && (!Array.isArray(formData[f.key]) || formData[f.key].length)">
                                        <span class="text-slate-400 shrink-0" x-text="f.label"></span>
                                        <span class="font-medium text-slate-700 text-right truncate" x-text="Array.isArray(formData[f.key]) ? formData[f.key].join(', ') : formData[f.key]"></span>
                                    </div>
                                </template>
                            </div>

                            <template x-for="f in (types[selectedType]?.fields || []).filter(f => f.type === 'table')" :key="f.key">
                                <div class="mt-3" x-show="(formData[f.key] || []).length">
                                    <p class="text-[11px] font-semibold text-slate-500 uppercase tracking-wide mb-1.5 flex items-center gap-1.5">
                                        <i :data-lucide="f.rowIcon || 'list'" class="w-3 h-3 text-purple-400"></i>
                                        <span x-text="f.label"></span>
                                    </p>
                                    <div class="overflow-x-auto rounded-xl border border-slate-200">
                                        <table class="w-full text-xs">
                                            <thead>
                                                <tr class="bg-purple-50/60 border-b border-slate-200">
                                                    <template x-for="col in f.columns" :key="col.key">
                                                        <th class="px-2.5 py-2 text-left font-semibold text-purple-700 whitespace-nowrap" x-text="col.label"></th>
                                                    </template>
                                                </tr>
                                            </thead>
                                            <tbody class="divide-y divide-slate-100">
                                                <template x-for="(row, ri) in (formData[f.key] || [])" :key="ri">
                                                    <tr :class="ri % 2 === 1 && 'bg-slate-50/60'">
                                                        <template x-for="col in f.columns" :key="col.key">
                                                            <td class="px-2.5 py-2 text-slate-700 whitespace-nowrap" x-text="row[col.key] || '—'"></td>
                                                        </template>
                                                    </tr>
                                                </template>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </template>
                        </div>

                        <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2"><x-ui.t fil="Mga Nakakabit na Requirement" en="Attached Requirements" /></p>
                        <ul class="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-1.5 mb-5">
                            <template x-for="(req, i) in types[selectedType]?.requirements || []" :key="i">
                                <li class="flex items-center gap-2 text-xs">
                                    <i data-lucide="circle-check" class="w-3.5 h-3.5 shrink-0" :class="attachments[i] ? 'text-emerald-500' : 'text-slate-300'"></i>
                                    <span :class="attachments[i] ? 'text-slate-600' : 'text-slate-400'" class="truncate" x-text="req"></span>
                                </li>
                            </template>
                        </ul>

                        <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3"><x-ui.t fil="Ano ang Susunod" en="What Happens Next" /></p>
                        <div class="flex items-center rounded-xl border border-slate-100 bg-slate-50/60 px-4 py-4">
                            <template x-for="(step_label, i) in types[selectedType]?.process || []" :key="i">
                                <div class="flex-1 flex items-center">
                                    <div class="flex flex-col items-center gap-1.5 text-center">
                                        <span class="w-7 h-7 rounded-full bg-purple-600 text-white flex items-center justify-center text-xs font-semibold shrink-0 shadow-sm" x-text="i + 1"></span>
                                        <span class="text-[10px] text-slate-500 max-w-[80px] leading-tight" x-text="step_label"></span>
                                    </div>
                                    <div class="flex-1 h-0.5 bg-purple-200 -mt-5" x-show="i < (types[selectedType]?.process || []).length - 1"></div>
                                </div>
                            </template>
                        </div>
                    </div>
                    </div>

                    <x-slot:footer>
                        <x-ui.button variant="secondary" size="sm" x-show="!submitted" @click="step > 1 ? step-- : (open = false, reset())">
                            <span x-text="$store.lang.current === 'en' ? (step > 1 ? 'Back' : 'Cancel') : (step > 1 ? 'Bumalik' : 'Kanselahin')"></span>
                        </x-ui.button>
                        <x-ui.button
                            size="sm"
                            x-show="!submitted"
                            ::disabled="submitting || (step === 1 && selectedType === null) || (step === 3 && types[selectedType]?.fee !== 'Free' && !alreadyPaid && !paymentMethod) || (step === 3 && alreadyPaid && !receipt)"
                            @click="
                                if (step < 4) { step++ }
                                else {
                                    submitting = true;
                                    setTimeout(() => {
                                        submitting = false;
                                        submitted = true;
                                        submitRequest();
                                        setTimeout(() => { open = false; reset(); $dispatch('toast', { message: $store.lang.current === 'en' ? 'Assistance request submitted — this is a frontend preview, no data is saved.' : 'Naisumite ang kahilingan sa tulong — frontend preview lang ito, walang naiimbak na datos.', variant: 'success' }) }, 1400);
                                    }, 700);
                                }
                            "
                        >
                            <i data-lucide="loader-circle" class="w-3.5 h-3.5 animate-spin" x-show="submitting" x-cloak></i>
                            <span x-text="submitting ? ($store.lang.current === 'en' ? 'Submitting…' : 'Isinusumite…') : ($store.lang.current === 'en' ? (step < 4 ? 'Continue' : 'Submit Request') : (step < 4 ? 'Magpatuloy' : 'Isumite ang Kahilingan'))"></span>
                        </x-ui.button>
                    </x-slot:footer>
                </x-ui.modal>
                </div>
            </div>
            </div>
        </div>

        <x-ui.table>
            <thead>
                <tr class="border-b border-slate-100 bg-slate-50/60">
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400"><x-ui.t fil="Reference" en="Reference" /></th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400"><x-ui.t fil="Uri ng Tulong" en="Assistance Type" /></th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden lg:table-cell"><x-ui.t fil="Opisina" en="Office" /></th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden md:table-cell"><x-ui.t fil="Layunin" en="Purpose" /></th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden sm:table-cell"><x-ui.t fil="Isinumite" en="Submitted" /></th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400"><x-ui.t fil="Status" en="Status" /></th>
                    <th class="px-4 py-2.5"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-50">
                <template x-for="req in filteredRequests" :key="req.ref">
                    <tr class="hover:bg-slate-50/70 transition-colors cursor-pointer" @click="openProgress(req)">
                        <td class="px-4 py-3 font-mono text-xs text-slate-500" x-text="req.ref"></td>
                        <td class="px-4 py-3 text-slate-700 font-medium" x-text="req.type"></td>
                        <td class="px-4 py-3 text-slate-500 hidden lg:table-cell" x-text="req.office"></td>
                        <td class="px-4 py-3 text-slate-500 hidden md:table-cell" x-text="req.purpose"></td>
                        <td class="px-4 py-3 text-slate-500 hidden sm:table-cell" x-text="req.submitted"></td>
                        <td class="px-4 py-3">
                            <span
                                class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ring-1 ring-inset whitespace-nowrap"
                                :class="{
                                    'bg-blue-50 text-blue-700 ring-blue-200': req.status === 'Submitted',
                                    'bg-purple-50 text-purple-700 ring-purple-200': req.status === 'Assigned',
                                    'bg-emerald-50 text-emerald-700 ring-emerald-200': req.status === 'Approved',
                                    'bg-cyan-50 text-cyan-700 ring-cyan-200': req.status === 'Released',
                                    'bg-green-50 text-green-700 ring-green-200': req.status === 'Completed',
                                    'bg-rose-50 text-rose-700 ring-rose-200': req.status === 'Rejected',
                                }"
                            >
                                <span
                                    class="w-1.5 h-1.5 rounded-full"
                                    :class="{
                                        'bg-blue-500': req.status === 'Submitted',
                                        'bg-purple-500': req.status === 'Assigned',
                                        'bg-emerald-500': req.status === 'Approved',
                                        'bg-cyan-500': req.status === 'Released',
                                        'bg-green-500': req.status === 'Completed',
                                        'bg-rose-500': req.status === 'Rejected',
                                    }"
                                ></span>
                                <span x-text="req.status"></span>
                            </span>
                        </td>
                        <td class="px-4 py-3 text-right" @click.stop="openProgress(req)">
                            <span class="text-xs font-medium text-brand-600 hover:underline whitespace-nowrap"><x-ui.t fil="Subaybayan" en="Track" /></span>
                        </td>
                    </tr>
                </template>
            </tbody>
        </x-ui.table>

        <div class="flex flex-col items-center text-center py-10 bg-white border border-slate-100 rounded-2xl mt-3" x-show="filteredRequests.length === 0">
            <span class="w-11 h-11 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mb-3"><i data-lucide="search-x" class="w-5 h-5"></i></span>
            <p class="text-sm font-medium text-slate-600"><x-ui.t fil="Walang kahilingang tumutugma dito." en="No requests in this view." /></p>
        </div>

        <!-- Track Request -->
        <div x-data="{ get open() { return progressOpen }, set open(v) { progressOpen = v } }">
            <x-ui.modal title="Subaybayan ang Kahilingan" titleEn="Track Request" maxWidth="md">
                <template x-if="selectedRequest">
                    <div>
                        <p class="text-xs font-mono text-slate-400" x-text="selectedRequest.ref"></p>
                        <p class="text-sm font-semibold text-navy-900" x-text="selectedRequest.type"></p>
                        <p class="text-xs text-slate-400 mt-0.5" x-text="selectedRequest.purpose"></p>

                        <!-- Progress stepper -->
                        <div class="flex items-center mt-6 mb-2" x-show="selectedRequest.status !== 'Rejected'">
                            <template x-for="(label, i) in stepOrder" :key="i">
                                <div class="flex-1 flex items-center">
                                    <div class="flex flex-col items-center gap-1.5 text-center">
                                        <span
                                            class="w-6 h-6 rounded-full flex items-center justify-center text-[11px] font-semibold shrink-0 transition-colors duration-300"
                                            :class="stepIndex(selectedRequest.status) > i ? 'bg-emerald-500 text-white' : (stepIndex(selectedRequest.status) === i ? 'bg-purple-600 text-white' : 'bg-slate-100 text-slate-400')"
                                        >
                                            <i data-lucide="check" class="w-3 h-3" x-show="stepIndex(selectedRequest.status) > i" x-cloak></i>
                                            <span x-show="stepIndex(selectedRequest.status) <= i" x-text="i + 1"></span>
                                        </span>
                                        <span class="text-[9px] max-w-[60px] leading-tight" :class="stepIndex(selectedRequest.status) === i ? 'text-navy-900 font-medium' : 'text-slate-400'" x-text="label"></span>
                                    </div>
                                    <div class="flex-1 h-0.5 -mt-4 transition-colors duration-300" :class="stepIndex(selectedRequest.status) > i ? 'bg-emerald-400' : 'bg-slate-100'" x-show="i < stepOrder.length - 1"></div>
                                </div>
                            </template>
                        </div>

                        <div class="rounded-xl bg-rose-50 border border-rose-100 px-3.5 py-2.5 mt-5 flex items-center gap-2.5" x-show="selectedRequest.status === 'Rejected'">
                            <i data-lucide="circle-x" class="w-4 h-4 text-rose-500 shrink-0"></i>
                            <p class="text-xs text-rose-600"><x-ui.t fil="Tinanggihan ang kahilingang ito. Bisitahin ang opisina para sa detalye." en="This request was rejected. Visit the office below for details." /></p>
                        </div>

                        <div class="grid grid-cols-2 gap-3 mt-5">
                            <div class="rounded-xl bg-slate-50 border border-slate-100 p-3.5">
                                <p class="text-[10px] font-semibold uppercase tracking-wide text-slate-400 mb-1"><x-ui.t fil="Inaasahang Petsa ng Release" en="Expected Release" /></p>
                                <p class="text-sm font-semibold text-navy-900" x-text="expectedRelease"></p>
                            </div>
                            <div class="rounded-xl bg-slate-50 border border-slate-100 p-3.5">
                                <p class="text-[10px] font-semibold uppercase tracking-wide text-slate-400 mb-1"><x-ui.t fil="Isinumite" en="Submitted" /></p>
                                <p class="text-sm font-semibold text-navy-900" x-text="selectedRequest.submitted"></p>
                            </div>
                        </div>

                        <div class="rounded-xl border border-slate-200 p-3.5 mt-3">
                            <p class="text-[10px] font-semibold uppercase tracking-wide text-slate-400 mb-2"><x-ui.t fil="Saan Kukunin / Sino ang Tatawagan" en="Where to Claim / Who to Contact" /></p>
                            <p class="text-sm font-medium text-navy-900" x-text="selectedRequest.office"></p>
                            <p class="text-xs text-slate-500 mt-1.5 flex items-center gap-1.5" x-show="pickupInfo"><i data-lucide="map-pin" class="w-3.5 h-3.5 text-slate-300 shrink-0"></i><span x-text="pickupInfo?.address"></span></p>
                            <p class="text-xs text-slate-500 mt-1 flex items-center gap-1.5" x-show="pickupInfo"><i data-lucide="phone" class="w-3.5 h-3.5 text-slate-300 shrink-0"></i><span x-text="pickupInfo?.contact"></span></p>
                        </div>
                    </div>
                </template>

                <x-slot:footer>
                    <x-ui.button size="sm" @click="progressOpen = false"><x-ui.t fil="Isara" en="Close" /></x-ui.button>
                </x-slot:footer>
            </x-ui.modal>
        </div>
    </div>
</x-layouts.citizen>
