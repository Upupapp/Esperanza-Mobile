<x-layouts.guest title="LGU Personnel Login" image="rectangle_cityhall.jpg" fullscreen>
    <div
        x-data="{
            accounts: @js(config('esperanza_rbac.accounts')),
            barangayNames: @js(config('esperanza.barangays')),
            scope: '',
            scopeSearch: '',
            employeeId: '',
            password: '',
            loading: false,
            error: '',
            showSamples: false,
            get filteredScopes() {
                const q = this.scopeSearch.trim().toLowerCase();
                return this.barangayNames.filter(b => !q || b.toLowerCase().includes(q));
            },
            get filteredAccounts() {
                return this.accounts.filter(a => !this.scope || a.scope === this.scope);
            },
            chooseScope(s) {
                this.scope = s;
                this.error = '';
                this.$nextTick(() => this.$refs.employeeId?.focus());
            },
            fill(account) {
                this.scope = account.scope;
                this.employeeId = account.id;
                this.password = 'demo1234';
                this.error = '';
            },
            submit() {
                if (this.loading) return;
                if (!this.scope) {
                    this.error = 'Please select your access scope.';
                    return;
                }
                const match = this.accounts.find(a => a.id.toLowerCase() === this.employeeId.trim().toLowerCase() && a.scope === this.scope);
                if (!match) {
                    this.error = 'Employee ID not recognized for the selected scope. Try one of the sample accounts below.';
                    this.showSamples = true;
                    return;
                }
                this.error = '';
                this.loading = true;
                setTimeout(() => {
                    this.loading = false;
                    this.$store.session.login(match);
                    window.location.href = '{{ route('admin.dashboard') }}';
                }, 900);
            },
        }"
    >
        <a href="{{ route('home') }}" class="inline-flex items-center gap-1.5 text-sm text-slate-400 hover:text-slate-600 mb-4 transition-colors">
            <i data-lucide="arrow-left" class="w-4 h-4"></i> Back
        </a>

        <div class="flex items-center justify-between animate-fade-up">
            <div class="w-10 h-10 rounded-xl bg-navy-900 text-white flex items-center justify-center shadow-card">
                <i data-lucide="shield-check" class="w-5 h-5"></i>
            </div>
            <span class="inline-flex items-center gap-1.5 text-[11px] font-medium text-navy-700 bg-slate-100 border border-slate-200 rounded-full px-2.5 py-1">
                <i data-lucide="lock" class="w-3 h-3"></i> Restricted Access
            </span>
        </div>

        <h1 class="text-xl font-semibold text-navy-900 mt-3 animate-fade-up" style="animation-delay: 40ms">LGU Personnel Login</h1>
        <p class="text-slate-500 text-sm mt-1 animate-fade-up" style="animation-delay: 60ms" x-text="scope ? 'Signing in to ' + (scope === 'Municipal' ? 'Municipal-wide access.' : 'Brgy. ' + scope + '.') : 'First, select your assigned access scope.'"></p>

        <!-- Step 1: choose access scope -->
        <div x-show="!scope" x-transition:leave="transition ease-in duration-150" x-transition:leave-start="opacity-100" x-transition:leave-end="opacity-0" class="mt-5 animate-fade-up" style="animation-delay: 90ms">
            <button
                type="button" @click="chooseScope('Municipal')"
                class="w-full flex items-center gap-2.5 text-left rounded-xl border border-slate-200 bg-white hover:border-navy-300 hover:bg-navy-50/40 hover:-translate-y-0.5 px-3.5 py-3 text-sm shadow-sm hover:shadow-card transition-all duration-150 mb-2.5"
            >
                <span class="w-8 h-8 rounded-lg bg-navy-50 text-navy-700 flex items-center justify-center shrink-0"><i data-lucide="landmark" class="w-4 h-4"></i></span>
                <span>
                    <span class="block text-xs font-semibold text-navy-900">Municipal-wide</span>
                    <span class="block text-[10.5px] text-slate-400">Municipal Hall departments &amp; offices</span>
                </span>
            </button>

            <div class="relative mb-2.5">
                <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none"></i>
                <input type="text" x-model="scopeSearch" placeholder="Search your barangay..." class="w-full pl-9 pr-3 py-2.5 text-sm rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-navy-300 focus:ring-4 focus:ring-navy-100 outline-none transition-all duration-200">
            </div>
            <div class="grid grid-cols-2 gap-1.5 max-h-56 overflow-y-auto scrollbar-thin pr-0.5">
                <template x-for="b in filteredScopes" :key="b">
                    <button
                        type="button" @click="chooseScope(b)"
                        class="flex items-center gap-1.5 text-left rounded-xl border border-slate-200 bg-white hover:border-navy-300 hover:bg-navy-50/40 hover:-translate-y-0.5 px-3 py-2.5 text-xs font-medium text-slate-600 hover:text-navy-800 shadow-sm hover:shadow-card transition-all duration-150"
                    >
                        <i data-lucide="map-pin" class="w-3.5 h-3.5 text-slate-400 shrink-0"></i><span class="truncate" x-text="b"></span>
                    </button>
                </template>
                <div class="col-span-2 flex flex-col items-center text-center py-6" x-show="filteredScopes.length === 0">
                    <span class="w-9 h-9 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mb-2"><i data-lucide="search-x" class="w-4 h-4"></i></span>
                    <p class="text-[11px] text-slate-400">No barangay matches "<span x-text="scopeSearch"></span>".</p>
                </div>
            </div>
        </div>

        <!-- Step 2: credentials, scoped to the chosen access scope -->
        <div x-show="scope" x-cloak x-transition:enter="transition ease-out duration-250" x-transition:enter-start="opacity-0 translate-y-1" x-transition:enter-end="opacity-100 translate-y-0" class="mt-5">
            <button
                type="button" @click="scope = ''; scopeSearch = ''"
                class="w-full flex items-center justify-between gap-2 rounded-xl border border-navy-200 bg-navy-50/60 px-3.5 py-2.5 text-left hover:bg-navy-50 transition-colors mb-3.5 animate-fade-up"
            >
                <span class="flex items-center gap-2 text-sm font-medium text-navy-800 min-w-0">
                    <i :data-lucide="scope === 'Municipal' ? 'landmark' : 'map-pin'" class="w-4 h-4 shrink-0"></i>
                    <span class="truncate" x-text="scope === 'Municipal' ? 'Municipal-wide' : 'Brgy. ' + scope"></span>
                </span>
                <span class="text-[11px] font-medium text-navy-600 flex items-center gap-0.5 shrink-0">Change <i data-lucide="chevron-right" class="w-3 h-3"></i></span>
            </button>

            <form class="space-y-3.5" @submit.prevent="submit">
                <div class="animate-fade-up" style="animation-delay: 40ms">
                    <x-ui.input name="employee_id" type="text" label="Employee ID" icon="badge-check" placeholder="SA-001" class="font-mono uppercase" x-model="employeeId" x-ref="employeeId" required />
                </div>

                <div class="animate-fade-up" style="animation-delay: 80ms" x-data="passwordField">
                    <label for="password" class="block text-sm font-medium text-slate-700 mb-1.5">Password</label>
                    <div class="relative">
                        <i data-lucide="lock" class="absolute left-3.5 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-slate-400 pointer-events-none"></i>
                        <input
                            :type="visible ? 'text' : 'password'"
                            name="password" id="password" placeholder="••••••••" required
                            x-model="password"
                            class="w-full rounded-xl border border-slate-200 bg-slate-50/60 py-2.5 pl-10 pr-11 text-sm text-slate-800 placeholder:text-slate-400 focus:bg-white focus:border-navy-400 focus:ring-4 focus:ring-navy-100 outline-none transition-all duration-200"
                        >
                        <button type="button" @click="toggle" class="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors">
                            <i data-lucide="eye" class="w-[18px] h-[18px]" x-show="!visible"></i>
                            <i data-lucide="eye-off" class="w-[18px] h-[18px]" x-show="visible" x-cloak></i>
                        </button>
                    </div>
                </div>

                <div x-show="error" x-cloak x-transition:enter="transition ease-out duration-150" x-transition:enter-start="opacity-0 -translate-y-1" x-transition:enter-end="opacity-100 translate-y-0" class="flex items-center gap-2.5 rounded-xl bg-rose-50 border border-rose-100 px-3.5 py-2.5">
                    <i data-lucide="circle-alert" class="w-4 h-4 text-rose-500 shrink-0"></i>
                    <p class="text-xs text-rose-600" x-text="error"></p>
                </div>

                <button
                    type="submit"
                    class="btn-shine w-full inline-flex items-center justify-center gap-2 rounded-xl bg-gradient-to-b from-navy-800 to-navy-900 text-white py-3 text-sm font-medium shadow-card hover:shadow-card-hover transition-all duration-200 active:scale-[0.98] disabled:opacity-70 animate-fade-up"
                    style="animation-delay: 120ms"
                    :disabled="loading"
                >
                    <svg x-show="loading" x-cloak class="w-4 h-4 animate-spin" viewBox="0 0 24 24" fill="none">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
                    </svg>
                    <span x-text="loading ? 'Verifying credentials…' : 'Sign In'"></span>
                    <i data-lucide="arrow-right" class="w-4 h-4" x-show="!loading"></i>
                </button>
            </form>
        </div>

        <div class="mt-4 rounded-xl border border-slate-100 bg-slate-50/60 overflow-hidden animate-fade-up" style="animation-delay: 260ms">
            <button type="button" @click="showSamples = !showSamples" class="w-full flex items-center justify-between gap-2 px-3.5 py-2.5 text-left">
                <span class="flex items-center gap-2 text-xs font-medium text-slate-600"><i data-lucide="flask-conical" class="w-3.5 h-3.5 text-slate-400"></i>Try a sample account (preview only)</span>
                <i data-lucide="chevron-down" class="w-3.5 h-3.5 text-slate-400 transition-transform duration-200" :class="showSamples && 'rotate-180'"></i>
            </button>
            <div x-show="showSamples" x-cloak x-transition:enter="transition ease-out duration-150" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100">
                <p class="px-3.5 pb-2 text-[10.5px] text-slate-400" x-show="!scope">Picking an account below will select its access scope for you.</p>
                <div class="px-3.5 pb-3.5 grid grid-cols-2 gap-1.5 max-h-52 overflow-y-auto scrollbar-thin">
                    <template x-for="account in filteredAccounts" :key="account.id">
                        <button
                            type="button" @click="fill(account)"
                            class="text-left rounded-lg border px-2.5 py-2 transition-all duration-150"
                            :class="employeeId.toLowerCase() === account.id.toLowerCase() ? 'border-navy-400 bg-white ring-2 ring-navy-100' : 'border-slate-200 bg-white hover:border-slate-300'"
                        >
                            <span class="block text-[11px] font-mono font-semibold text-navy-800" x-text="account.id"></span>
                            <span class="block text-[10.5px] text-slate-400 truncate" x-text="account.role"></span>
                            <span class="inline-flex items-center gap-1 text-[9.5px] font-medium rounded-full px-1.5 py-0.5 mt-1" :class="account.scope === 'Municipal' ? 'bg-brand-50 text-brand-600' : 'bg-purple-50 text-purple-600'">
                                <i :data-lucide="account.scope === 'Municipal' ? 'landmark' : 'map-pin'" class="w-2.5 h-2.5"></i>
                                <span x-text="account.scope === 'Municipal' ? 'Municipal' : 'Brgy. ' + account.scope"></span>
                            </span>
                        </button>
                    </template>
                    <p x-show="filteredAccounts.length === 0" class="col-span-2 text-center text-[11px] text-slate-400 py-4">No sample accounts for this scope yet.</p>
                </div>
            </div>
        </div>

        <p class="text-center text-xs text-slate-400 mt-4">
            Personnel accounts cannot self-register — contact the ICT Office for access.
        </p>
    </div>
</x-layouts.guest>
