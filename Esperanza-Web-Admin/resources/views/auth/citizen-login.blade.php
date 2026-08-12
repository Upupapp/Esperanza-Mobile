<x-layouts.guest title="Citizen Login" image="esperanza-community.jpg" fullscreen>
    <div
        x-data="{
            accounts: @js(config('esperanza_citizens.accounts')),
            barangayNames: @js(config('esperanza.barangays')),
            barangay: '',
            barangaySearch: '',
            identifier: '',
            password: '',
            loading: false,
            error: '',
            showSamples: false,
            get filteredBarangays() {
                const q = this.barangaySearch.trim().toLowerCase();
                return this.barangayNames.filter(b => !q || b.toLowerCase().includes(q));
            },
            get filteredAccounts() {
                return this.accounts.filter(a => !this.barangay || a.barangay === this.barangay);
            },
            chooseBarangay(b) {
                this.barangay = b;
                this.error = '';
                this.$nextTick(() => this.$refs.identifier?.focus());
            },
            fill(account) {
                this.barangay = account.barangay;
                this.identifier = account.id;
                this.password = 'demo1234';
                this.error = '';
            },
            submit() {
                if (this.loading) return;
                if (!this.barangay) {
                    this.error = 'Please select your barangay.';
                    return;
                }
                const q = this.identifier.trim().toLowerCase();
                const match = this.accounts.find(a => (a.id.toLowerCase() === q || a.email.toLowerCase() === q) && a.barangay === this.barangay);
                if (!match) {
                    this.error = 'Account not recognized for Brgy. ' + this.barangay + '. Check your barangay and ID, or try the sample account below.';
                    this.showSamples = true;
                    return;
                }
                this.error = '';
                this.loading = true;
                setTimeout(() => {
                    this.loading = false;
                    this.$store.citizenSession.login(match);
                    window.location.href = '{{ route('citizen.dashboard') }}';
                }, 900);
            },
        }"
    >
        <a href="{{ route('home') }}" class="inline-flex items-center gap-1.5 text-sm text-slate-400 hover:text-slate-600 mb-4 transition-colors">
            <i data-lucide="arrow-left" class="w-4 h-4"></i> <x-ui.t fil="Bumalik" en="Back" />
        </a>

        <div class="flex items-center justify-between animate-fade-up">
            <div class="w-10 h-10 rounded-xl bg-brand-50 text-brand-600 flex items-center justify-center">
                <i data-lucide="user" class="w-5 h-5"></i>
            </div>
            <span class="inline-flex items-center gap-1.5 text-[11px] font-medium text-brand-700 bg-brand-50 border border-brand-100 rounded-full px-2.5 py-1">
                <i data-lucide="shield-check" class="w-3 h-3"></i> <x-ui.t fil="Access ng Mamamayan" en="Citizen Access" />
            </span>
        </div>

        <h1 class="text-xl font-semibold text-navy-900 mt-3 animate-fade-up" style="animation-delay: 40ms"><x-ui.t fil="Maligayang Pagbabalik" en="Welcome back" /></h1>
        <p class="text-slate-500 text-sm mt-1 animate-fade-up" style="animation-delay: 60ms" x-text="barangay ? ($store.lang.current === 'en' ? 'Signing in to Brgy. ' + barangay + '.' : 'Nagsa-sign in sa Brgy. ' + barangay + '.') : ($store.lang.current === 'en' ? 'First, tell us which barangay you belong to.' : 'Una, sabihin sa amin kung anong barangay ka.')"></p>

        <!-- Step 1: choose barangay -->
        <div x-show="!barangay" x-transition:leave="transition ease-in duration-150" x-transition:leave-start="opacity-100" x-transition:leave-end="opacity-0" class="mt-5 animate-fade-up" style="animation-delay: 90ms">
            <div class="relative mb-2.5">
                <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none"></i>
                <input type="text" x-model="barangaySearch" placeholder="Search your barangay..." class="w-full pl-9 pr-3 py-2.5 text-sm rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200">
            </div>
            <div class="grid grid-cols-2 gap-1.5 max-h-64 overflow-y-auto scrollbar-thin pr-0.5">
                <template x-for="b in filteredBarangays" :key="b">
                    <button
                        type="button" @click="chooseBarangay(b)"
                        class="flex items-center gap-1.5 text-left rounded-xl border border-slate-200 bg-white hover:border-brand-300 hover:bg-brand-50/50 hover:-translate-y-0.5 px-3 py-2.5 text-xs font-medium text-slate-600 hover:text-brand-700 shadow-sm hover:shadow-card transition-all duration-150"
                    >
                        <i data-lucide="map-pin" class="w-3.5 h-3.5 text-slate-400 shrink-0"></i><span class="truncate" x-text="b"></span>
                    </button>
                </template>
                <div class="col-span-2 flex flex-col items-center text-center py-6" x-show="filteredBarangays.length === 0">
                    <span class="w-9 h-9 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mb-2"><i data-lucide="search-x" class="w-4 h-4"></i></span>
                    <p class="text-[11px] text-slate-400">No barangay matches "<span x-text="barangaySearch"></span>".</p>
                </div>
            </div>
        </div>

        <!-- Step 2: credentials, scoped to the chosen barangay -->
        <div x-show="barangay" x-cloak x-transition:enter="transition ease-out duration-250" x-transition:enter-start="opacity-0 translate-y-1" x-transition:enter-end="opacity-100 translate-y-0" class="mt-5">
            <button
                type="button" @click="barangay = ''; barangaySearch = ''"
                class="w-full flex items-center justify-between gap-2 rounded-xl border border-brand-200 bg-brand-50/60 px-3.5 py-2.5 text-left hover:bg-brand-50 transition-colors mb-3.5 animate-fade-up"
            >
                <span class="flex items-center gap-2 text-sm font-medium text-brand-700 min-w-0"><i data-lucide="map-pin" class="w-4 h-4 shrink-0"></i><span class="truncate">Brgy. <span x-text="barangay"></span></span></span>
                <span class="text-[11px] font-medium text-brand-600 flex items-center gap-0.5 shrink-0"><x-ui.t fil="Palitan" en="Change" /> <i data-lucide="chevron-right" class="w-3 h-3"></i></span>
            </button>

            <form class="space-y-3.5" @submit.prevent="submit">
                <div class="animate-fade-up" style="animation-delay: 40ms">
                    <x-ui.input name="email" type="text" label="Resident ID or Email" icon="mail" placeholder="ESP-RES-2024-1102" x-model="identifier" x-ref="identifier" required />
                </div>

                <div class="animate-fade-up" style="animation-delay: 80ms" x-data="passwordField">
                    <label for="password" class="block text-sm font-medium text-slate-700 mb-1.5"><x-ui.t fil="Password" en="Password" /></label>
                    <div class="relative">
                        <i data-lucide="lock" class="absolute left-3.5 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-slate-400 pointer-events-none"></i>
                        <input
                            :type="visible ? 'text' : 'password'"
                            name="password" id="password" placeholder="••••••••" required
                            x-model="password"
                            class="w-full rounded-xl border border-slate-200 bg-slate-50/60 py-2.5 pl-10 pr-11 text-sm text-slate-800 placeholder:text-slate-400 focus:bg-white focus:border-brand-400 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200"
                        >
                        <button type="button" @click="toggle" class="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors">
                            <i data-lucide="eye" class="w-[18px] h-[18px]" x-show="!visible"></i>
                            <i data-lucide="eye-off" class="w-[18px] h-[18px]" x-show="visible" x-cloak></i>
                        </button>
                    </div>
                    <div class="flex items-center justify-between mt-2">
                        <label class="flex items-center gap-2 text-sm text-slate-500">
                            <input type="checkbox" class="rounded border-slate-300 text-brand-600 focus:ring-brand-200">
                            <x-ui.t fil="Tandaan ako" en="Remember me" />
                        </label>
                        <a href="#" class="text-sm text-brand-600 hover:underline"><x-ui.t fil="Nakalimutan ang password?" en="Forgot password?" /></a>
                    </div>
                </div>

                <div x-show="error" x-cloak x-transition:enter="transition ease-out duration-150" x-transition:enter-start="opacity-0 -translate-y-1" x-transition:enter-end="opacity-100 translate-y-0" class="flex items-center gap-2.5 rounded-xl bg-rose-50 border border-rose-100 px-3.5 py-2.5">
                    <i data-lucide="circle-alert" class="w-4 h-4 text-rose-500 shrink-0"></i>
                    <p class="text-xs text-rose-600" x-text="error"></p>
                </div>

                <button
                    type="submit"
                    class="btn-shine w-full inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-b from-brand-500 to-brand-600 text-white py-3 text-sm font-medium shadow-card hover:shadow-card-hover transition-all duration-200 active:scale-[0.98] disabled:opacity-70 animate-fade-up"
                    style="animation-delay: 120ms"
                    :disabled="loading"
                >
                    <svg x-show="loading" x-cloak class="w-4 h-4 animate-spin" viewBox="0 0 24 24" fill="none">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
                    </svg>
                    <span x-text="$store.lang.current === 'en' ? (loading ? 'Signing in…' : 'Sign In') : (loading ? 'Nagsa-sign in…' : 'Mag-sign In')"></span>
                </button>
            </form>
        </div>

        <div class="mt-4 rounded-xl border border-slate-100 bg-slate-50/60 overflow-hidden animate-fade-up" style="animation-delay: 230ms">
            <button type="button" @click="showSamples = !showSamples" class="w-full flex items-center justify-between gap-2 px-3.5 py-2.5 text-left">
                <span class="flex items-center gap-2 text-xs font-medium text-slate-600"><i data-lucide="flask-conical" class="w-3.5 h-3.5 text-slate-400"></i><x-ui.t fil="Subukan ang sample na account" en="Try a sample account (preview only)" /></span>
                <i data-lucide="chevron-down" class="w-3.5 h-3.5 text-slate-400 transition-transform duration-200" :class="showSamples && 'rotate-180'"></i>
            </button>
            <div x-show="showSamples" x-cloak x-transition:enter="transition ease-out duration-150" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100">
                <p class="px-3.5 pb-2 text-[10.5px] text-slate-400" x-show="!barangay"><x-ui.t fil="Awtomatikong mapipili ang barangay ayon sa account na pipiliin mo." en="Picking an account below will select its barangay for you." /></p>
                <div class="px-3.5 pb-3.5 space-y-1.5 max-h-52 overflow-y-auto scrollbar-thin">
                    <template x-for="account in filteredAccounts" :key="account.id">
                        <button
                            type="button" @click="fill(account)"
                            class="w-full text-left rounded-lg border px-3 py-2 transition-all duration-150"
                            :class="identifier.toLowerCase() === account.id.toLowerCase() ? 'border-brand-400 bg-white ring-2 ring-brand-100' : 'border-slate-200 bg-white hover:border-slate-300'"
                        >
                            <span class="block text-xs font-semibold text-navy-800" x-text="account.fullName"></span>
                            <span class="block text-[10.5px] text-slate-400"><span x-text="account.id"></span> · Brgy. <span x-text="account.barangay"></span></span>
                        </button>
                    </template>
                    <p x-show="filteredAccounts.length === 0" class="text-center text-[11px] text-slate-400 py-4"><x-ui.t fil="Wala pang sample account para sa barangay na ito." en="No sample accounts for this barangay yet." /></p>
                </div>
            </div>
        </div>

        <p class="text-center text-sm text-slate-400 mt-4">
            <x-ui.t fil="Wala ka pang account?" en="Don't have an account?" /> <a href="{{ route('citizen.register') }}" class="text-brand-600 font-medium hover:underline"><x-ui.t fil="Magrehistro rito" en="Register here" /></a>
        </p>
    </div>
</x-layouts.guest>
