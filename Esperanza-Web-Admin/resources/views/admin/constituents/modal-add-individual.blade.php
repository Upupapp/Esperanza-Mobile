{{-- ============================================================
     FILE: modal-add-individual.blade.php
     Partial: Multi-step Add Resident form modal
     Alpine scope: parent x-data (showAddIndividual, addIndividualStep, etc.)
     ============================================================ --}}

<div
    x-data="{
        get open() { return showAddIndividual; },
        set open(v) { showAddIndividual = v; },

        form: {
            first_name: '', middle_name: '', last_name: '', suffix: '',
            sex: '', dob: '', civil_status: '', contact: '', email: '',
            barangay: '', sitio: '', address: '', household_id: '',
            family_id: '', relation: '',
            occupation: '', education: '', income_range: '',
            tags: [], verification: 'Unverified',
        },

        resetForm() {
            this.form = {
                first_name:'', middle_name:'', last_name:'', suffix:'',
                sex:'', dob:'', civil_status:'', contact:'', email:'',
                barangay:'', sitio:'', address:'', household_id:'',
                family_id:'', relation:'',
                occupation:'', education:'', income_range:'',
                tags:[], verification:'Unverified',
            };
            addIndividualStep = 1;
        },

        submitForm() {
            this.open = false;
            this.resetForm();
            $dispatch('toast', { message: 'Resident record created successfully.', variant: 'success' });
            window.renderIcons?.();
        },

        toggleTag(tag) {
            if (this.form.tags.includes(tag)) {
                this.form.tags = this.form.tags.filter(t => t !== tag);
            } else {
                this.form.tags = [...this.form.tags, tag];
            }
        },

        hasTag(tag) {
            return this.form.tags.includes(tag);
        },
    }"
    @modal-closed.window="if (!showAddIndividual) resetForm()"
>
    <x-ui.modal maxWidth="2xl">

        {{-- ════════════════════════════════════════════════════════
             HEADER + STEP PROGRESS
        ════════════════════════════════════════════════════════ --}}
        <div class="bg-white px-6 pt-6 pb-0 rounded-t-2xl border-b border-slate-200">

            <div class="flex items-start justify-between mb-5">
                <div>
                    <h2 class="text-lg font-bold text-navy-900">Add New Resident</h2>
                    <p class="text-sm text-slate-500 mt-0.5">Encode a new individual record into the barangay registry</p>
                </div>
                <button
                    @click="open = false; resetForm()"
                    class="w-8 h-8 rounded-full flex items-center justify-center text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors flex-shrink-0"
                    title="Close"
                >
                    <i data-lucide="x" class="w-4 h-4"></i>
                </button>
            </div>

            {{-- Step progress indicator --}}
            <nav class="flex items-center gap-0" aria-label="Form steps">

                {{-- Step 1 --}}
                <div class="flex-1 flex flex-col items-center">
                    <div class="flex items-center w-full">
                        <div class="flex-1 h-0.5" :class="addIndividualStep > 1 ? 'bg-brand-500' : 'bg-transparent'"></div>
                        <div
                            class="w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold border-2 transition-all flex-shrink-0"
                            :class="addIndividualStep === 1
                                ? 'border-brand-500 bg-brand-500 text-white'
                                : addIndividualStep > 1
                                ? 'border-brand-500 bg-brand-500 text-white'
                                : 'border-slate-200 bg-white text-slate-400'"
                        >
                            <template x-if="addIndividualStep > 1">
                                <i data-lucide="check" class="w-4 h-4"></i>
                            </template>
                            <template x-if="addIndividualStep <= 1">
                                <span>1</span>
                            </template>
                        </div>
                        <div class="flex-1 h-0.5" :class="addIndividualStep > 1 ? 'bg-brand-500' : 'bg-slate-200'"></div>
                    </div>
                    <span class="text-xs mt-1.5 font-medium" :class="addIndividualStep === 1 ? 'text-brand-600' : addIndividualStep > 1 ? 'text-brand-500' : 'text-slate-400'">
                        Personal
                    </span>
                </div>

                {{-- Step 2 --}}
                <div class="flex-1 flex flex-col items-center">
                    <div class="flex items-center w-full">
                        <div class="flex-1 h-0.5" :class="addIndividualStep > 2 ? 'bg-brand-500' : 'bg-slate-200'"></div>
                        <div
                            class="w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold border-2 transition-all flex-shrink-0"
                            :class="addIndividualStep === 2
                                ? 'border-brand-500 bg-brand-500 text-white'
                                : addIndividualStep > 2
                                ? 'border-brand-500 bg-brand-500 text-white'
                                : 'border-slate-200 bg-white text-slate-400'"
                        >
                            <template x-if="addIndividualStep > 2">
                                <i data-lucide="check" class="w-4 h-4"></i>
                            </template>
                            <template x-if="addIndividualStep <= 2">
                                <span>2</span>
                            </template>
                        </div>
                        <div class="flex-1 h-0.5" :class="addIndividualStep > 2 ? 'bg-brand-500' : 'bg-slate-200'"></div>
                    </div>
                    <span class="text-xs mt-1.5 font-medium" :class="addIndividualStep === 2 ? 'text-brand-600' : addIndividualStep > 2 ? 'text-brand-500' : 'text-slate-400'">
                        Address
                    </span>
                </div>

                {{-- Step 3 --}}
                <div class="flex-1 flex flex-col items-center">
                    <div class="flex items-center w-full">
                        <div class="flex-1 h-0.5" :class="addIndividualStep > 2 ? 'bg-brand-500' : 'bg-slate-200'"></div>
                        <div
                            class="w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold border-2 transition-all flex-shrink-0"
                            :class="addIndividualStep === 3
                                ? 'border-brand-500 bg-brand-500 text-white'
                                : 'border-slate-200 bg-white text-slate-400'"
                        >
                            <span>3</span>
                        </div>
                        <div class="flex-1 h-0.5 bg-transparent"></div>
                    </div>
                    <span class="text-xs mt-1.5 font-medium" :class="addIndividualStep === 3 ? 'text-brand-600' : 'text-slate-400'">
                        Profile
                    </span>
                </div>

            </nav>

            {{-- Progress bar under steps --}}
            <div class="mt-4 h-1 bg-slate-100 rounded-full overflow-hidden -mx-6">
                <div
                    class="h-full bg-gradient-to-r from-brand-500 to-brand-600 rounded-full transition-all duration-500"
                    :style="'width:' + (((addIndividualStep - 1) / 2) * 100) + '%'"
                ></div>
            </div>
        </div>

        {{-- ════════════════════════════════════════════════════════
             FORM BODY
        ════════════════════════════════════════════════════════ --}}
        <div class="px-6 py-6 overflow-y-auto max-h-[55vh] bg-slate-50/30">

            {{-- ── STEP 1: Personal Information ── --}}
            <div x-show="addIndividualStep === 1" class="space-y-5">

                <div class="flex items-center gap-2 mb-4">
                    <div class="w-8 h-8 rounded-lg bg-brand-100 flex items-center justify-center">
                        <i data-lucide="user" class="w-4 h-4 text-brand-600"></i>
                    </div>
                    <div>
                        <h3 class="text-sm font-semibold text-navy-900">Personal Information</h3>
                        <p class="text-xs text-slate-500">Basic identity and contact details</p>
                    </div>
                </div>

                {{-- Name row --}}
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div class="sm:col-span-1">
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                            First Name <span class="text-red-500">*</span>
                        </label>
                        <input
                            type="text"
                            x-model="form.first_name"
                            placeholder="e.g. Maria"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                            required
                        />
                    </div>
                    <div class="sm:col-span-1">
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Middle Name</label>
                        <input
                            type="text"
                            x-model="form.middle_name"
                            placeholder="e.g. Santos"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                        />
                    </div>
                    <div class="sm:col-span-1">
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                            Last Name <span class="text-red-500">*</span>
                        </label>
                        <input
                            type="text"
                            x-model="form.last_name"
                            placeholder="e.g. Reyes"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                            required
                        />
                    </div>
                </div>

                {{-- Suffix --}}
                <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Suffix</label>
                        <select
                            x-model="form.suffix"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                        >
                            <option value="">None</option>
                            <option value="Jr.">Jr.</option>
                            <option value="Sr.">Sr.</option>
                            <option value="II">II</option>
                            <option value="III">III</option>
                            <option value="IV">IV</option>
                        </select>
                    </div>

                    {{-- Sex --}}
                    <div class="sm:col-span-3">
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                            Sex <span class="text-red-500">*</span>
                        </label>
                        <div class="flex gap-3">
                            <label class="flex-1 flex items-center gap-2.5 cursor-pointer group">
                                <div
                                    class="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg border-2 transition-all text-sm font-medium"
                                    :class="form.sex === 'M'
                                        ? 'border-blue-400 bg-blue-50 text-blue-700'
                                        : 'border-slate-200 bg-white text-slate-500 hover:border-blue-200 hover:bg-blue-50/50'"
                                >
                                    <input type="radio" name="sex" value="M" x-model="form.sex" class="sr-only" />
                                    <i data-lucide="mars" class="w-4 h-4"></i>
                                    Male
                                </div>
                            </label>
                            <label class="flex-1 flex items-center gap-2.5 cursor-pointer group">
                                <div
                                    class="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg border-2 transition-all text-sm font-medium"
                                    :class="form.sex === 'F'
                                        ? 'border-pink-400 bg-pink-50 text-pink-700'
                                        : 'border-slate-200 bg-white text-slate-500 hover:border-pink-200 hover:bg-pink-50/50'"
                                >
                                    <input type="radio" name="sex" value="F" x-model="form.sex" class="sr-only" />
                                    <i data-lucide="venus" class="w-4 h-4"></i>
                                    Female
                                </div>
                            </label>
                        </div>
                    </div>
                </div>

                {{-- DOB & Civil Status --}}
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                            Date of Birth <span class="text-red-500">*</span>
                        </label>
                        <input
                            type="date"
                            x-model="form.dob"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                            required
                        />
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                            Civil Status <span class="text-red-500">*</span>
                        </label>
                        <select
                            x-model="form.civil_status"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                            required
                        >
                            <option value="" disabled selected>Select status</option>
                            <option value="Single">Single</option>
                            <option value="Married">Married</option>
                            <option value="Widowed">Widowed</option>
                            <option value="Separated">Separated</option>
                            <option value="Annulled">Annulled</option>
                            <option value="Live-in">Live-in</option>
                        </select>
                    </div>
                </div>

                {{-- Contact & Email --}}
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                            Contact Number <span class="text-red-500">*</span>
                        </label>
                        <div class="relative">
                            <span class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-sm font-medium">+63</span>
                            <input
                                type="tel"
                                x-model="form.contact"
                                placeholder="9XXXXXXXXX"
                                maxlength="10"
                                class="w-full pl-12 pr-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                                required
                            />
                        </div>
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                            Email Address
                            <span class="text-slate-400 font-normal ml-1">(optional)</span>
                        </label>
                        <input
                            type="email"
                            x-model="form.email"
                            placeholder="email@example.com"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                        />
                    </div>
                </div>

            </div>{{-- /Step 1 --}}


            {{-- ── STEP 2: Address & Household ── --}}
            <div x-show="addIndividualStep === 2" class="space-y-5">

                <div class="flex items-center gap-2 mb-4">
                    <div class="w-8 h-8 rounded-lg bg-indigo-100 flex items-center justify-center">
                        <i data-lucide="map-pin" class="w-4 h-4 text-indigo-600"></i>
                    </div>
                    <div>
                        <h3 class="text-sm font-semibold text-navy-900">Address & Household</h3>
                        <p class="text-xs text-slate-500">Location and household linkage</p>
                    </div>
                </div>

                {{-- Barangay & Sitio --}}
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                            Barangay <span class="text-red-500">*</span>
                        </label>
                        <select
                            x-model="form.barangay"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                            required
                        >
                            <option value="" disabled selected>Select barangay</option>
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
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Sitio / Purok</label>
                        <input
                            type="text"
                            x-model="form.sitio"
                            placeholder="e.g. Sitio Malago"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                        />
                    </div>
                </div>

                {{-- Full Address --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                        Full Address <span class="text-red-500">*</span>
                    </label>
                    <textarea
                        x-model="form.address"
                        placeholder="House No. / Block, Street, Purok, Barangay, Municipality, Province"
                        rows="3"
                        class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition resize-none"
                        required
                    ></textarea>
                </div>

                {{-- Household & Family IDs --}}
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                            Household ID
                            <span class="text-slate-400 font-normal ml-1">(optional — link to existing)</span>
                        </label>
                        <div class="relative">
                            <i data-lucide="search" class="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"></i>
                            <input
                                type="text"
                                x-model="form.household_id"
                                placeholder="e.g. HH-2024-001"
                                class="w-full pl-9 pr-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                            />
                        </div>
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                            Family ID
                            <span class="text-slate-400 font-normal ml-1">(optional)</span>
                        </label>
                        <input
                            type="text"
                            x-model="form.family_id"
                            placeholder="e.g. FAM-2024-001"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                        />
                    </div>
                </div>

                {{-- Relation in Household --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                        Relation in Household <span class="text-red-500">*</span>
                    </label>
                    <div class="grid grid-cols-2 sm:grid-cols-3 gap-2">
                        <template x-for="rel in ['Head', 'Spouse', 'Son', 'Daughter', 'Grandchild', 'Other']" :key="rel">
                            <label class="cursor-pointer">
                                <input type="radio" name="relation" :value="rel" x-model="form.relation" class="sr-only" />
                                <div
                                    class="flex items-center justify-center px-3 py-2.5 rounded-lg border-2 text-sm font-medium transition-all"
                                    :class="form.relation === rel
                                        ? 'border-brand-500 bg-brand-50 text-brand-700'
                                        : 'border-slate-200 bg-white text-slate-500 hover:border-brand-200 hover:bg-brand-50/30'"
                                    x-text="rel"
                                ></div>
                            </label>
                        </template>
                    </div>
                </div>

            </div>{{-- /Step 2 --}}


            {{-- ── STEP 3: Profile & Tags ── --}}
            <div x-show="addIndividualStep === 3" class="space-y-5">

                <div class="flex items-center gap-2 mb-4">
                    <div class="w-8 h-8 rounded-lg bg-emerald-100 flex items-center justify-center">
                        <i data-lucide="tag" class="w-4 h-4 text-emerald-600"></i>
                    </div>
                    <div>
                        <h3 class="text-sm font-semibold text-navy-900">Profile & Sector Tags</h3>
                        <p class="text-xs text-slate-500">Socioeconomic profile and program eligibility</p>
                    </div>
                </div>

                {{-- Occupation, Education, Income --}}
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Occupation</label>
                        <input
                            type="text"
                            x-model="form.occupation"
                            placeholder="e.g. Farmer, Teacher"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 placeholder-slate-400 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                        />
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Highest Education</label>
                        <select
                            x-model="form.education"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                        >
                            <option value="" disabled selected>Select level</option>
                            <option value="No Formal Education">No Formal Education</option>
                            <option value="Elementary Level">Elementary Level</option>
                            <option value="Elementary Graduate">Elementary Graduate</option>
                            <option value="High School Level">High School Level</option>
                            <option value="High School Graduate">High School Graduate</option>
                            <option value="Senior High School Level">Senior High School Level</option>
                            <option value="Senior High School Graduate">Senior High School Graduate</option>
                            <option value="Vocational / Tech-Voc">Vocational / Tech-Voc</option>
                            <option value="College Level">College Level</option>
                            <option value="College Graduate">College Graduate</option>
                            <option value="Post-Graduate">Post-Graduate</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Monthly Income Range</label>
                        <select
                            x-model="form.income_range"
                            class="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm text-navy-900 bg-white focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent transition"
                        >
                            <option value="" disabled selected>Select range</option>
                            <option value="No Income">No Income</option>
                            <option value="Below ₱5,000">Below ₱5,000</option>
                            <option value="₱5,000–₱9,999">₱5,000 – ₱9,999</option>
                            <option value="₱10,000–₱14,999">₱10,000 – ₱14,999</option>
                            <option value="₱15,000–₱24,999">₱15,000 – ₱24,999</option>
                            <option value="₱25,000–₱49,999">₱25,000 – ₱49,999</option>
                            <option value="₱50,000 and above">₱50,000 and above</option>
                        </select>
                    </div>
                </div>

                {{-- Vulnerable Sector Tags --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-2">
                        Vulnerable Sector Classification
                        <span class="text-slate-400 font-normal ml-1">(check all that apply)</span>
                    </label>
                    <div class="grid grid-cols-2 sm:grid-cols-3 gap-2">
                        <template x-for="sector in [
                            { key: 'senior', label: 'Senior Citizen', icon: 'user-round', color: 'amber' },
                            { key: 'osca', label: 'OSCA Registered', icon: 'award', color: 'amber' },
                            { key: 'pwd', label: 'PWD', icon: 'accessibility', color: 'blue' },
                            { key: 'youth', label: 'Youth (15–30)', icon: 'zap', color: 'green' },
                            { key: 'child', label: 'Child (0–14)', icon: 'baby', color: 'violet' },
                            { key: 'osy', label: 'Out-of-School Youth', icon: 'graduation-cap', color: 'orange' },
                            { key: '4ps', label: '4Ps Beneficiary', icon: 'wallet', color: 'cyan' },
                            { key: 'solo_parent', label: 'Solo Parent', icon: 'heart', color: 'rose' },
                            { key: 'farmer', label: 'Farmer / Fisher', icon: 'leaf', color: 'lime' },
                            { key: 'high_risk', label: 'High-Risk', icon: 'alert-triangle', color: 'red' },
                        ]" :key="sector.key">
                            <label
                                @click="toggleTag(sector.key)"
                                class="flex items-center gap-2.5 px-3 py-2.5 rounded-lg border-2 cursor-pointer transition-all"
                                :class="hasTag(sector.key)
                                    ? {
                                        'border-amber-400 bg-amber-50': sector.color === 'amber',
                                        'border-blue-400 bg-blue-50': sector.color === 'blue',
                                        'border-green-400 bg-green-50': sector.color === 'green',
                                        'border-violet-400 bg-violet-50': sector.color === 'violet',
                                        'border-orange-400 bg-orange-50': sector.color === 'orange',
                                        'border-cyan-400 bg-cyan-50': sector.color === 'cyan',
                                        'border-rose-400 bg-rose-50': sector.color === 'rose',
                                        'border-lime-400 bg-lime-50': sector.color === 'lime',
                                        'border-red-400 bg-red-50': sector.color === 'red',
                                      }
                                    : 'border-slate-200 bg-white hover:border-slate-300'"
                            >
                                <div
                                    class="w-4 h-4 rounded border-2 flex items-center justify-center flex-shrink-0 transition-all"
                                    :class="hasTag(sector.key)
                                        ? {
                                            'border-amber-500 bg-amber-500': sector.color === 'amber',
                                            'border-blue-500 bg-blue-500': sector.color === 'blue',
                                            'border-green-500 bg-green-500': sector.color === 'green',
                                            'border-violet-500 bg-violet-500': sector.color === 'violet',
                                            'border-orange-500 bg-orange-500': sector.color === 'orange',
                                            'border-cyan-500 bg-cyan-500': sector.color === 'cyan',
                                            'border-rose-500 bg-rose-500': sector.color === 'rose',
                                            'border-lime-600 bg-lime-600': sector.color === 'lime',
                                            'border-red-500 bg-red-500': sector.color === 'red',
                                          }
                                        : 'border-slate-300 bg-white'"
                                >
                                    <template x-if="hasTag(sector.key)">
                                        <i data-lucide="check" class="w-2.5 h-2.5 text-white"></i>
                                    </template>
                                </div>
                                <span class="text-xs font-medium text-slate-700" x-text="sector.label"></span>
                            </label>
                        </template>
                    </div>
                </div>

                {{-- Initial Verification Status --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-2">
                        Initial Verification Status <span class="text-red-500">*</span>
                    </label>
                    <div class="flex gap-3">
                        <label class="flex-1 cursor-pointer">
                            <input type="radio" name="verification" value="For Validation" x-model="form.verification" class="sr-only" />
                            <div
                                class="flex items-center gap-2.5 px-4 py-3 rounded-lg border-2 transition-all"
                                :class="form.verification === 'For Validation'
                                    ? 'border-amber-400 bg-amber-50'
                                    : 'border-slate-200 bg-white hover:border-amber-200'"
                            >
                                <div
                                    class="w-4 h-4 rounded-full border-2 flex items-center justify-center flex-shrink-0"
                                    :class="form.verification === 'For Validation' ? 'border-amber-500' : 'border-slate-300'"
                                >
                                    <div
                                        class="w-2 h-2 rounded-full bg-amber-500 transition-opacity"
                                        :class="form.verification === 'For Validation' ? 'opacity-100' : 'opacity-0'"
                                    ></div>
                                </div>
                                <div>
                                    <p class="text-sm font-semibold text-slate-700">For Validation</p>
                                    <p class="text-xs text-slate-400">Documents pending review</p>
                                </div>
                            </div>
                        </label>
                        <label class="flex-1 cursor-pointer">
                            <input type="radio" name="verification" value="Unverified" x-model="form.verification" class="sr-only" />
                            <div
                                class="flex items-center gap-2.5 px-4 py-3 rounded-lg border-2 transition-all"
                                :class="form.verification === 'Unverified'
                                    ? 'border-slate-400 bg-slate-50'
                                    : 'border-slate-200 bg-white hover:border-slate-300'"
                            >
                                <div
                                    class="w-4 h-4 rounded-full border-2 flex items-center justify-center flex-shrink-0"
                                    :class="form.verification === 'Unverified' ? 'border-slate-500' : 'border-slate-300'"
                                >
                                    <div
                                        class="w-2 h-2 rounded-full bg-slate-500 transition-opacity"
                                        :class="form.verification === 'Unverified' ? 'opacity-100' : 'opacity-0'"
                                    ></div>
                                </div>
                                <div>
                                    <p class="text-sm font-semibold text-slate-700">Unverified</p>
                                    <p class="text-xs text-slate-400">No documents on file</p>
                                </div>
                            </div>
                        </label>
                    </div>
                </div>

                {{-- Summary preview box --}}
                <div class="bg-brand-50 border border-brand-100 rounded-xl p-4">
                    <h4 class="text-xs font-semibold text-brand-700 uppercase tracking-wider mb-2.5 flex items-center gap-1.5">
                        <i data-lucide="eye" class="w-3.5 h-3.5"></i>
                        Record Preview
                    </h4>
                    <div class="grid grid-cols-2 sm:grid-cols-3 gap-2 text-xs">
                        <div>
                            <span class="text-brand-500">Name:</span>
                            <span class="font-semibold text-navy-900 ml-1">
                                <span x-text="[form.first_name, form.middle_name, form.last_name, form.suffix].filter(Boolean).join(' ') || '—'"></span>
                            </span>
                        </div>
                        <div>
                            <span class="text-brand-500">Barangay:</span>
                            <span class="font-semibold text-navy-900 ml-1" x-text="form.barangay || '—'"></span>
                        </div>
                        <div>
                            <span class="text-brand-500">Tags:</span>
                            <span class="font-semibold text-navy-900 ml-1" x-text="form.tags.length > 0 ? form.tags.join(', ') : 'None'"></span>
                        </div>
                    </div>
                </div>

            </div>{{-- /Step 3 --}}

        </div>{{-- /form body --}}


        {{-- ════════════════════════════════════════════════════════
             FOOTER NAVIGATION
        ════════════════════════════════════════════════════════ --}}
        <div class="px-6 py-4 border-t border-slate-200 bg-white rounded-b-2xl flex items-center justify-between gap-3">

            {{-- Back --}}
            <button
                x-show="addIndividualStep > 1"
                @click="addIndividualStep--"
                class="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg border border-slate-200 text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors"
            >
                <i data-lucide="chevron-left" class="w-4 h-4"></i>
                Back
            </button>

            {{-- Cancel (shown only on step 1) --}}
            <button
                x-show="addIndividualStep === 1"
                @click="open = false; resetForm()"
                class="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg border border-slate-200 text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors"
            >
                Cancel
            </button>

            <div class="flex items-center gap-1.5 ml-auto">
                {{-- Step indicator --}}
                <span class="text-xs text-slate-400 mr-2">
                    Step <span x-text="addIndividualStep"></span> of 3
                </span>

                {{-- Next (steps 1–2) --}}
                <button
                    x-show="addIndividualStep < 3"
                    @click="addIndividualStep++"
                    class="inline-flex items-center gap-1.5 px-5 py-2 rounded-lg bg-brand-600 text-white text-sm font-semibold hover:bg-brand-700 transition-colors shadow-sm"
                >
                    Next
                    <i data-lucide="chevron-right" class="w-4 h-4"></i>
                </button>

                {{-- Save Resident (step 3) --}}
                <button
                    x-show="addIndividualStep === 3"
                    @click="submitForm()"
                    class="inline-flex items-center gap-1.5 px-5 py-2 rounded-lg bg-brand-600 text-white text-sm font-semibold hover:bg-brand-700 transition-colors shadow-sm"
                >
                    <i data-lucide="save" class="w-4 h-4"></i>
                    Save Resident
                </button>
            </div>

        </div>

    </x-ui.modal>
</div>
