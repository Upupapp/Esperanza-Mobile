@php
    $barangays = config('esperanza.barangays');
@endphp
<x-layouts.guest title="Create Account" image="esperanza_community1.jpg" fullscreen>
    <div
        x-data="{
            ...authForm('{{ route('citizen.dashboard') }}'),
            step: 1,
            totalSteps: 3,
            stepLabels: {
                en: ['Personal Info', 'Address', 'Contact & Security'],
                fil: ['Personal na Impormasyon', 'Address', 'Contact at Seguridad'],
            },
            next() { if (this.step < this.totalSteps) this.step++; },
            back() { if (this.step > 1) this.step--; },
        }"
    >
        <a href="{{ route('citizen.login') }}" class="inline-flex items-center gap-1.5 text-sm text-slate-400 hover:text-slate-600 mb-6 transition-colors">
            <i data-lucide="arrow-left" class="w-4 h-4"></i> <x-ui.t fil="Bumalik sa login" en="Back to login" />
        </a>

        <h1 class="text-2xl font-semibold text-navy-900"><x-ui.t fil="Gumawa ng Account ng Mamamayan" en="Create your Citizen Account" /></h1>
        <p class="text-slate-500 text-sm mt-1.5"><x-ui.t fil="Magrehistro para humiling ng dokumento at ma-access ang mga serbisyo ng munisipyo online." en="Register to request documents and access municipal services online." /></p>

        <!-- Step indicator -->
        <div class="flex items-center mt-6 mb-1">
            <template x-for="(label, i) in ($store.lang.current === 'en' ? stepLabels.en : stepLabels.fil)" :key="i">
                <div class="flex-1 flex items-center">
                    <div class="flex flex-col items-center gap-1.5 text-center">
                        <span
                            class="w-6 h-6 rounded-full flex items-center justify-center text-[11px] font-semibold shrink-0 transition-colors duration-300"
                            :class="step > i + 1 ? 'bg-emerald-500 text-white' : (step === i + 1 ? 'bg-brand-600 text-white' : 'bg-slate-100 text-slate-400')"
                        >
                            <i data-lucide="check" class="w-3 h-3" x-show="step > i + 1" x-cloak></i>
                            <span x-show="step <= i + 1" x-text="i + 1"></span>
                        </span>
                        <span class="text-[10px] max-w-[90px] leading-tight" :class="step === i + 1 ? 'text-navy-900 font-medium' : 'text-slate-400'" x-text="label"></span>
                    </div>
                    <div class="flex-1 h-0.5 -mt-4 transition-colors duration-300" :class="step > i + 1 ? 'bg-emerald-400' : 'bg-slate-100'" x-show="i < 2"></div>
                </div>
            </template>
        </div>

        <form class="mt-5 space-y-5" @submit.prevent="submit">
            <!-- Step 1: Personal Information -->
            <div x-show="step === 1" x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 translate-x-2" x-transition:enter-end="opacity-100 translate-x-0" class="space-y-4">
                <div class="grid grid-cols-2 gap-4">
                    <x-ui.input name="first_name" label="First Name" placeholder="Maria" required />
                    <x-ui.input name="last_name" label="Last Name" placeholder="Bacaltos" required />
                </div>
                <x-ui.input name="middle_name" label="Middle Name" placeholder="Cabaltera" />

                <div class="grid grid-cols-2 gap-4">
                    <x-ui.input name="birthdate" type="date" label="Date of Birth" required />
                    <div>
                        <label for="sex" class="block text-sm font-medium text-slate-700 mb-1.5"><x-ui.t fil="Kasarian" en="Sex" /></label>
                        <select id="sex" name="sex" required class="w-full rounded-xl border border-slate-200 bg-slate-50/60 py-2.5 px-4 text-sm text-slate-700 focus:bg-white focus:border-brand-400 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200 appearance-none">
                            <option value="">Select</option>
                            <option>Female</option>
                            <option>Male</option>
                        </select>
                    </div>
                </div>

                <div>
                    <label for="civil_status" class="block text-sm font-medium text-slate-700 mb-1.5"><x-ui.t fil="Katayuang Sibil" en="Civil Status" /></label>
                    <select id="civil_status" name="civil_status" required class="w-full rounded-xl border border-slate-200 bg-slate-50/60 py-2.5 px-4 text-sm text-slate-700 focus:bg-white focus:border-brand-400 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200 appearance-none">
                        <option value="">Select your civil status</option>
                        <option>Single</option>
                        <option>Married</option>
                        <option>Widowed</option>
                        <option>Separated</option>
                    </select>
                </div>

                <button
                    type="button" @click="next()"
                    class="btn-shine w-full inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-b from-brand-500 to-brand-600 text-white py-3 text-sm font-medium shadow-card hover:shadow-card-hover transition-all duration-200 active:scale-[0.98]"
                >
                    <x-ui.t fil="Susunod" en="Continue" /> <i data-lucide="arrow-right" class="w-4 h-4"></i>
                </button>
            </div>

            <!-- Step 2: Address -->
            <div x-show="step === 2" x-cloak x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 translate-x-2" x-transition:enter-end="opacity-100 translate-x-0" class="space-y-4">
                <div>
                    <label for="barangay" class="block text-sm font-medium text-slate-700 mb-1.5">Barangay</label>
                    <div class="relative">
                        <i data-lucide="map-pin" class="absolute left-3.5 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-slate-400 pointer-events-none"></i>
                        <select id="barangay" name="barangay" required class="w-full rounded-xl border border-slate-200 bg-slate-50/60 py-2.5 pl-10 pr-4 text-sm text-slate-700 focus:bg-white focus:border-brand-400 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200 appearance-none">
                            <option value="">Select your barangay</option>
                            @foreach($barangays as $brgy)
                                <option value="{{ $brgy }}">{{ $brgy }}</option>
                            @endforeach
                        </select>
                        <i data-lucide="chevron-down" class="absolute right-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none"></i>
                    </div>
                </div>

                <x-ui.input name="address" label="Complete Address" icon="house" placeholder="Purok 3, Sitio Mabuhay" required />

                <div class="flex items-center gap-2.5">
                    <button
                        type="button" @click="back()"
                        class="inline-flex items-center justify-center gap-2 rounded-xl border border-slate-200 text-slate-600 bg-white hover:bg-slate-50 py-3 px-5 text-sm font-medium transition-all duration-200 active:scale-[0.98]"
                    >
                        <i data-lucide="arrow-left" class="w-4 h-4"></i> <x-ui.t fil="Bumalik" en="Back" />
                    </button>
                    <button
                        type="button" @click="next()"
                        class="btn-shine flex-1 inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-b from-brand-500 to-brand-600 text-white py-3 text-sm font-medium shadow-card hover:shadow-card-hover transition-all duration-200 active:scale-[0.98]"
                    >
                        <x-ui.t fil="Susunod" en="Continue" /> <i data-lucide="arrow-right" class="w-4 h-4"></i>
                    </button>
                </div>
            </div>

            <!-- Step 3: Contact & Security -->
            <div x-show="step === 3" x-cloak x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 translate-x-2" x-transition:enter-end="opacity-100 translate-x-0" class="space-y-4">
                <x-ui.input name="email" type="email" label="Email Address" icon="mail" placeholder="maria.bacaltos@email.com" required />
                <x-ui.input name="mobile" type="text" label="Mobile Number" icon="phone" placeholder="09XX XXX XXXX" required />
                <x-ui.input name="password" type="password" label="Password" icon="lock" placeholder="Create a password" required />

                <label class="flex items-start gap-2.5 text-xs text-slate-500 pt-1">
                    <input type="checkbox" required class="mt-0.5 rounded border-slate-300 text-brand-600 focus:ring-brand-200">
                    <x-ui.t fil="Sumasang-ayon ako sa Terms of Service at patakaran sa Data Privacy ng Munisipyo ng Esperanza." en="I agree to the Terms of Service and Data Privacy policy of the Municipality of Esperanza." />
                </label>

                <div class="flex items-center gap-2.5">
                    <button
                        type="button" @click="back()" :disabled="loading"
                        class="inline-flex items-center justify-center gap-2 rounded-xl border border-slate-200 text-slate-600 bg-white hover:bg-slate-50 py-3.5 px-5 text-sm font-medium transition-all duration-200 active:scale-[0.98] disabled:opacity-50 disabled:pointer-events-none"
                    >
                        <i data-lucide="arrow-left" class="w-4 h-4"></i> <x-ui.t fil="Bumalik" en="Back" />
                    </button>
                    <button
                        type="submit"
                        class="btn-shine flex-1 inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-b from-brand-500 to-brand-600 text-white py-3.5 text-sm font-medium shadow-card hover:shadow-card-hover transition-all duration-200 active:scale-[0.98] disabled:opacity-70"
                        :disabled="loading"
                    >
                        <svg x-show="loading" x-cloak class="w-4 h-4 animate-spin" viewBox="0 0 24 24" fill="none">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
                        </svg>
                        <span x-text="$store.lang.current === 'en' ? (loading ? 'Creating your account…' : 'Create Account') : (loading ? 'Ginagawa ang account…' : 'Gumawa ng Account')"></span>
                    </button>
                </div>
            </div>
        </form>
    </div>
</x-layouts.guest>
