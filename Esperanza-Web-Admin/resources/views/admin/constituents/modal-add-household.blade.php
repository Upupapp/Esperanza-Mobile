{{-- modal-add-household.blade.php --}}
{{-- Add Household modal — 3 steps --}}

<div x-data="{
    get open() { return showAddHousehold },
    set open(v) { showAddHousehold = v },
    form: {
        barangay: '',
        sitio: '',
        address: '',
        head_name: '',
        dwelling_type: '',
        housing_tenure: '',
        flood_risk: '',
        hazard_zone: '',
        electricity: false,
        water: false,
        toilet: false,
        programs: [],
        notes: ''
    },
    programOptions: [
        '4Ps (Pantawid Pamilyang Pilipino Program)',
        'OSCA (Senior Citizen Assistance)',
        'PWD Assistance Program',
        'Solo Parent Welfare Program',
        'DSWD Financial Assistance',
        'Other Government Assistance'
    ],
    barangayOptions: [
        'Bagong Silang','Batuan','Bayabas','Buenaflor','Buenavista','Calpi','Centro Poblacion',
        'Cogon','Dao','Esperanza','Gatbo','Jupi','Lanipga','Libtong','Lourdes','Mabuhay',
        'Mapale','Matagabong','Milagrosa','Poblacion Norte','Poblacion Sur','Salvacion','Tinago'
    ],
    hazardZoneOptions: [
        'Zone 1 (Safe)',
        'Zone 2 (Moderate Risk)',
        'Zone 3 (High Risk)'
    ],
    get canProceed() {
        if (addHouseholdStep === 1) {
            return this.form.barangay !== '' && this.form.address.trim() !== '' && this.form.head_name.trim() !== ''
        }
        if (addHouseholdStep === 2) {
            return this.form.dwelling_type !== '' && this.form.housing_tenure !== '' && this.form.flood_risk !== ''
        }
        return true
    },
    saveHousehold() {
        this.$dispatch('toast', { message: 'Household record saved successfully.', type: 'success' })
        showAddHousehold = false
        addHouseholdStep = 1
        this.form = {
            barangay: '', sitio: '', address: '', head_name: '',
            dwelling_type: '', housing_tenure: '', flood_risk: '', hazard_zone: '',
            electricity: false, water: false, toilet: false,
            programs: [], notes: ''
        }
    }
}">
<x-ui.modal maxWidth="xl">

    <div class="flex flex-col h-full max-h-[90vh]">

        {{-- ── Modal Header ── --}}
        <div class="flex-shrink-0 px-6 pt-6 pb-4 border-b border-slate-200">
            <div class="flex items-start justify-between gap-3">
                <div>
                    <h2 class="text-lg font-bold text-navy-900">Register New Household</h2>
                    <p class="text-sm text-slate-500 mt-0.5">Municipality of Esperanza, Masbate</p>
                </div>
                <button @click="showAddHousehold = false; addHouseholdStep = 1" class="p-2 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors">
                    <i data-lucide="x" class="w-5 h-5"></i>
                </button>
            </div>

            {{-- Step indicator — 3 steps --}}
            <div class="flex items-center gap-0 mt-5">
                <template x-for="(step, idx) in [
                    {n:1, label:'Location'},
                    {n:2, label:'Dwelling'},
                    {n:3, label:'Amenities & Programs'}
                ]" :key="step.n">
                    <div class="flex items-center" :class="idx < 2 ? 'flex-1' : ''">
                        <div class="flex items-center gap-1.5 sm:gap-2">
                            <div
                                class="w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0 transition-all"
                                :class="addHouseholdStep > step.n
                                    ? 'bg-emerald-500 text-white'
                                    : addHouseholdStep === step.n
                                        ? 'bg-indigo-600 text-white shadow-md shadow-indigo-200'
                                        : 'bg-slate-100 text-slate-400'"
                            >
                                <template x-if="addHouseholdStep > step.n">
                                    <i data-lucide="check" class="w-3.5 h-3.5"></i>
                                </template>
                                <template x-if="addHouseholdStep <= step.n">
                                    <span x-text="step.n"></span>
                                </template>
                            </div>
                            <span
                                class="text-xs font-medium hidden sm:block transition-colors"
                                :class="addHouseholdStep === step.n ? 'text-indigo-600' : addHouseholdStep > step.n ? 'text-emerald-600' : 'text-slate-400'"
                                x-text="step.label"
                            ></span>
                        </div>
                        <template x-if="idx < 2">
                            <div class="flex-1 h-px mx-2 sm:mx-3" :class="addHouseholdStep > step.n ? 'bg-emerald-300' : 'bg-slate-200'"></div>
                        </template>
                    </div>
                </template>
            </div>
        </div>

        {{-- ── Form Body (scrollable) ── --}}
        <div class="flex-1 overflow-y-auto px-6 py-5">

            {{-- ── STEP 1: Location & Identity ── --}}
            <div x-show="addHouseholdStep === 1" x-cloak class="space-y-5">
                <p class="text-xs text-slate-500 bg-indigo-50 border border-indigo-100 rounded-lg px-3 py-2 flex items-start gap-2">
                    <i data-lucide="info" class="w-3.5 h-3.5 text-indigo-500 mt-0.5 flex-shrink-0"></i>
                    Enter the location and primary occupant information. Fields marked <span class="text-rose-500 font-bold mx-0.5">*</span> are required.
                </p>

                {{-- Barangay + Sitio --}}
                <div class="grid grid-cols-2 gap-3">
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                            Barangay <span class="text-rose-500">*</span>
                        </label>
                        <select
                            x-model="form.barangay"
                            class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-lg bg-white text-navy-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition"
                        >
                            <option value="">Select barangay…</option>
                            <template x-for="b in barangayOptions" :key="b">
                                <option :value="b" x-text="b"></option>
                            </template>
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Sitio / Purok</label>
                        <input
                            type="text"
                            x-model="form.sitio"
                            placeholder="e.g. Sitio Bonbon"
                            class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-lg bg-white text-navy-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition"
                        />
                    </div>
                </div>

                {{-- Street address --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                        Street Address <span class="text-rose-500">*</span>
                    </label>
                    <input
                        type="text"
                        x-model="form.address"
                        placeholder="e.g. Purok 3, Brgy. Esperanza"
                        class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-lg bg-white text-navy-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition"
                    />
                </div>

                {{-- Household head --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                        Household Head Name <span class="text-rose-500">*</span>
                    </label>
                    <input
                        type="text"
                        x-model="form.head_name"
                        placeholder="Full name of household head"
                        class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-lg bg-white text-navy-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition"
                    />
                    <p class="text-xs text-slate-400 mt-1.5">This person will be listed as the primary occupant of this household.</p>
                </div>
            </div>

            {{-- ── STEP 2: Dwelling & Risk ── --}}
            <div x-show="addHouseholdStep === 2" x-cloak class="space-y-5">
                <p class="text-xs text-slate-500 bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 flex items-start gap-2">
                    <i data-lucide="building-2" class="w-3.5 h-3.5 text-slate-400 mt-0.5 flex-shrink-0"></i>
                    Describe the dwelling type, ownership, and disaster risk classification.
                </p>

                {{-- Dwelling type radios --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-2">
                        Dwelling Type <span class="text-rose-500">*</span>
                    </label>
                    <div class="grid grid-cols-2 gap-2">
                        <template x-for="dt in [
                            {val:'Single Detached', icon:'home', desc:'Standalone structure'},
                            {val:'Single Attached', icon:'building', desc:'Shares one wall'},
                            {val:'Apartment', icon:'building-2', desc:'Multi-family building'},
                            {val:'Informal Settler', icon:'tent', desc:'Informal settlement'}
                        ]" :key="dt.val">
                            <label
                                class="relative flex items-center gap-3 p-3 rounded-lg border-2 cursor-pointer transition-all"
                                :class="form.dwelling_type === dt.val
                                    ? 'border-indigo-500 bg-indigo-50'
                                    : 'border-slate-200 bg-white hover:border-slate-300'"
                            >
                                <input type="radio" x-model="form.dwelling_type" :value="dt.val" class="sr-only" />
                                <i :data-lucide="dt.icon" class="w-4 h-4 flex-shrink-0" :class="form.dwelling_type === dt.val ? 'text-indigo-600' : 'text-slate-400'"></i>
                                <div class="min-w-0">
                                    <p class="text-xs font-semibold" :class="form.dwelling_type === dt.val ? 'text-indigo-700' : 'text-slate-700'" x-text="dt.val"></p>
                                    <p class="text-xs text-slate-400" x-text="dt.desc"></p>
                                </div>
                                <template x-if="form.dwelling_type === dt.val">
                                    <div class="absolute top-2 right-2 w-4 h-4 bg-indigo-600 rounded-full flex items-center justify-center">
                                        <i data-lucide="check" class="w-2.5 h-2.5 text-white"></i>
                                    </div>
                                </template>
                            </label>
                        </template>
                    </div>
                </div>

                {{-- Housing tenure radios --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-2">
                        Housing Tenure <span class="text-rose-500">*</span>
                    </label>
                    <div class="grid grid-cols-3 gap-2">
                        <template x-for="ht in [
                            {val:'Owner', icon:'key', desc:'Owns the property'},
                            {val:'Renter', icon:'banknote', desc:'Paying rent'},
                            {val:'Shared', icon:'handshake', desc:'Shared occupancy'}
                        ]" :key="ht.val">
                            <label
                                class="relative flex flex-col items-center gap-1.5 p-3 rounded-lg border-2 cursor-pointer transition-all text-center"
                                :class="form.housing_tenure === ht.val
                                    ? 'border-indigo-500 bg-indigo-50'
                                    : 'border-slate-200 bg-white hover:border-slate-300'"
                            >
                                <input type="radio" x-model="form.housing_tenure" :value="ht.val" class="sr-only" />
                                <i :data-lucide="ht.icon" class="w-5 h-5" :class="form.housing_tenure === ht.val ? 'text-indigo-600' : 'text-slate-400'"></i>
                                <span class="text-xs font-semibold" :class="form.housing_tenure === ht.val ? 'text-indigo-700' : 'text-slate-600'" x-text="ht.val"></span>
                                <template x-if="form.housing_tenure === ht.val">
                                    <div class="absolute top-1.5 right-1.5 w-3.5 h-3.5 bg-indigo-600 rounded-full flex items-center justify-center">
                                        <i data-lucide="check" class="w-2.5 h-2.5 text-white"></i>
                                    </div>
                                </template>
                            </label>
                        </template>
                    </div>
                </div>

                {{-- Flood risk radios --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-2">
                        Flood Risk Level <span class="text-rose-500">*</span>
                    </label>
                    <div class="grid grid-cols-3 gap-2">
                        <template x-for="fr in [
                            {val:'Low', cls:'border-emerald-300 bg-emerald-50', activeCls:'border-emerald-500 bg-emerald-50', iconCls:'text-emerald-600', textCls:'text-emerald-700', dotCls:'bg-emerald-500'},
                            {val:'Medium', cls:'border-amber-300 bg-amber-50', activeCls:'border-amber-500 bg-amber-50', iconCls:'text-amber-600', textCls:'text-amber-700', dotCls:'bg-amber-500'},
                            {val:'High', cls:'border-rose-300 bg-rose-50', activeCls:'border-rose-500 bg-rose-50', iconCls:'text-rose-600', textCls:'text-rose-700', dotCls:'bg-rose-500'}
                        ]" :key="fr.val">
                            <label
                                class="relative flex flex-col items-center gap-1.5 p-3 rounded-lg border-2 cursor-pointer transition-all text-center"
                                :class="form.flood_risk === fr.val ? fr.activeCls : 'border-slate-200 bg-white hover:border-slate-300'"
                            >
                                <input type="radio" x-model="form.flood_risk" :value="fr.val" class="sr-only" />
                                <i data-lucide="waves-horizontal" class="w-5 h-5" :class="form.flood_risk === fr.val ? fr.iconCls : 'text-slate-400'"></i>
                                <span class="text-xs font-semibold" :class="form.flood_risk === fr.val ? fr.textCls : 'text-slate-600'" x-text="fr.val"></span>
                                <template x-if="form.flood_risk === fr.val">
                                    <div class="absolute top-1.5 right-1.5 w-3.5 h-3.5 rounded-full flex items-center justify-center" :class="fr.dotCls">
                                        <i data-lucide="check" class="w-2.5 h-2.5 text-white"></i>
                                    </div>
                                </template>
                            </label>
                        </template>
                    </div>
                </div>

                {{-- Hazard zone dropdown --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Hazard Zone Classification</label>
                    <select
                        x-model="form.hazard_zone"
                        class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-lg bg-white text-navy-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition"
                    >
                        <option value="">Select hazard zone…</option>
                        <template x-for="hz in hazardZoneOptions" :key="hz">
                            <option :value="hz" x-text="hz"></option>
                        </template>
                    </select>
                </div>
            </div>

            {{-- ── STEP 3: Amenities & Programs ── --}}
            <div x-show="addHouseholdStep === 3" x-cloak class="space-y-5">
                <p class="text-xs text-slate-500 bg-slate-50 border border-slate-200 rounded-lg px-3 py-2 flex items-start gap-2">
                    <i data-lucide="plug-zap" class="w-3.5 h-3.5 text-slate-400 mt-0.5 flex-shrink-0"></i>
                    Indicate available basic amenities, government program enrollments, and any notes.
                </p>

                {{-- Amenities checkboxes --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-2">Basic Amenities</label>
                    <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
                        {{-- Electricity --}}
                        <label
                            class="flex flex-col items-center gap-2 p-4 rounded-xl border-2 cursor-pointer transition-all text-center"
                            :class="form.electricity ? 'border-amber-400 bg-amber-50' : 'border-slate-200 bg-white hover:border-slate-300'"
                        >
                            <input type="checkbox" x-model="form.electricity" class="sr-only" />
                            <div class="w-10 h-10 rounded-xl flex items-center justify-center" :class="form.electricity ? 'bg-amber-100' : 'bg-slate-100'">
                                <i data-lucide="zap" class="w-5 h-5" :class="form.electricity ? 'text-amber-500' : 'text-slate-400'"></i>
                            </div>
                            <span class="text-xs font-semibold" :class="form.electricity ? 'text-amber-700' : 'text-slate-600'">Has Electricity</span>
                            <div class="w-5 h-5 rounded border-2 flex items-center justify-center transition-colors"
                                :class="form.electricity ? 'bg-amber-500 border-amber-500' : 'border-slate-300'">
                                <i x-show="form.electricity" data-lucide="check" class="w-3 h-3 text-white"></i>
                            </div>
                        </label>

                        {{-- Water --}}
                        <label
                            class="flex flex-col items-center gap-2 p-4 rounded-xl border-2 cursor-pointer transition-all text-center"
                            :class="form.water ? 'border-blue-400 bg-blue-50' : 'border-slate-200 bg-white hover:border-slate-300'"
                        >
                            <input type="checkbox" x-model="form.water" class="sr-only" />
                            <div class="w-10 h-10 rounded-xl flex items-center justify-center" :class="form.water ? 'bg-blue-100' : 'bg-slate-100'">
                                <i data-lucide="droplets" class="w-5 h-5" :class="form.water ? 'text-blue-500' : 'text-slate-400'"></i>
                            </div>
                            <span class="text-xs font-semibold" :class="form.water ? 'text-blue-700' : 'text-slate-600'">Has Water Source</span>
                            <div class="w-5 h-5 rounded border-2 flex items-center justify-center transition-colors"
                                :class="form.water ? 'bg-blue-500 border-blue-500' : 'border-slate-300'">
                                <i x-show="form.water" data-lucide="check" class="w-3 h-3 text-white"></i>
                            </div>
                        </label>

                        {{-- Toilet --}}
                        <label
                            class="flex flex-col items-center gap-2 p-4 rounded-xl border-2 cursor-pointer transition-all text-center"
                            :class="form.toilet ? 'border-emerald-400 bg-emerald-50' : 'border-slate-200 bg-white hover:border-slate-300'"
                        >
                            <input type="checkbox" x-model="form.toilet" class="sr-only" />
                            <div class="w-10 h-10 rounded-xl flex items-center justify-center" :class="form.toilet ? 'bg-emerald-100' : 'bg-slate-100'">
                                <i data-lucide="toilet" class="w-5 h-5" :class="form.toilet ? 'text-emerald-500' : 'text-slate-400'"></i>
                            </div>
                            <span class="text-xs font-semibold" :class="form.toilet ? 'text-emerald-700' : 'text-slate-600'">Has Toilet Facility</span>
                            <div class="w-5 h-5 rounded border-2 flex items-center justify-center transition-colors"
                                :class="form.toilet ? 'bg-emerald-500 border-emerald-500' : 'border-slate-300'">
                                <i x-show="form.toilet" data-lucide="check" class="w-3 h-3 text-white"></i>
                            </div>
                        </label>
                    </div>
                </div>

                {{-- Programs --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-2">Programs to Enroll</label>
                    <div class="space-y-2">
                        <template x-for="prog in programOptions" :key="prog">
                            <label
                                class="flex items-center gap-3 p-3 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 cursor-pointer transition-colors"
                                :class="form.programs.includes(prog) ? 'border-emerald-300 bg-emerald-50/50' : ''"
                            >
                                <input type="checkbox" :value="prog" x-model="form.programs"
                                    class="w-4 h-4 rounded text-emerald-600 border-slate-300 focus:ring-emerald-500" />
                                <span class="text-sm text-navy-900" x-text="prog"></span>
                            </label>
                        </template>
                    </div>
                </div>

                {{-- Notes --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Notes / Remarks</label>
                    <textarea
                        x-model="form.notes"
                        rows="3"
                        placeholder="Any additional observations or notes about this household…"
                        class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-lg bg-white text-navy-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition resize-none"
                    ></textarea>
                </div>

                {{-- Summary preview --}}
                <div class="rounded-lg border border-slate-200 bg-slate-50 p-4">
                    <h4 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2.5">Household Summary</h4>
                    <dl class="grid grid-cols-2 gap-x-4 gap-y-1.5 text-xs">
                        <div><dt class="text-slate-400">Barangay</dt><dd class="font-semibold text-navy-900 truncate" x-text="form.barangay || '—'"></dd></div>
                        <div><dt class="text-slate-400">Head</dt><dd class="font-semibold text-navy-900 truncate" x-text="form.head_name || '—'"></dd></div>
                        <div><dt class="text-slate-400">Dwelling</dt><dd class="font-semibold text-navy-900" x-text="form.dwelling_type || '—'"></dd></div>
                        <div><dt class="text-slate-400">Flood Risk</dt><dd class="font-semibold text-navy-900" x-text="form.flood_risk || '—'"></dd></div>
                        <div><dt class="text-slate-400">Amenities</dt>
                            <dd class="font-semibold text-navy-900">
                                <span x-text="[form.electricity ? 'Elec' : null, form.water ? 'Water' : null, form.toilet ? 'Toilet' : null].filter(Boolean).join(', ') || 'None'"></span>
                            </dd>
                        </div>
                        <div><dt class="text-slate-400">Programs</dt><dd class="font-semibold text-navy-900" x-text="form.programs.length > 0 ? form.programs.length + ' selected' : 'None'"></dd></div>
                    </dl>
                </div>
            </div>

        </div>

        {{-- ── Modal Footer ── --}}
        <div class="flex-shrink-0 px-6 py-4 border-t border-slate-200 bg-slate-50/50 flex items-center justify-between gap-3 rounded-b-2xl">
            {{-- Back / Cancel --}}
            <button
                @click="addHouseholdStep > 1 ? addHouseholdStep-- : (showAddHousehold = false)"
                class="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-slate-600 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors shadow-sm"
            >
                <i data-lucide="arrow-left" class="w-4 h-4"></i>
                <span x-text="addHouseholdStep > 1 ? 'Back' : 'Cancel'"></span>
            </button>

            {{-- Step counter --}}
            <span class="text-xs text-slate-400 font-medium hidden sm:block">
                Step <span x-text="addHouseholdStep"></span> of 3
            </span>

            {{-- Next (steps 1–2) --}}
            <button
                x-show="addHouseholdStep < 3"
                @click="canProceed && addHouseholdStep++"
                :disabled="!canProceed"
                class="inline-flex items-center gap-2 px-5 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-slate-200 disabled:text-slate-400 disabled:cursor-not-allowed text-white text-sm font-medium rounded-lg shadow-sm transition-colors"
            >
                Next
                <i data-lucide="arrow-right" class="w-4 h-4"></i>
            </button>

            {{-- Save (step 3) --}}
            <button
                x-show="addHouseholdStep === 3"
                @click="saveHousehold()"
                class="inline-flex items-center gap-2 px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white text-sm font-medium rounded-lg shadow-sm transition-colors focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:ring-offset-2"
            >
                <i data-lucide="save" class="w-4 h-4"></i>
                Save Household
            </button>
        </div>

    </div>

</x-ui.modal>
</div>
