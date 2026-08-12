@php
    $offices = [
        ['name' => 'Office of the Municipal Mayor', 'head' => 'Hon. Ricardo M. Espallardo', 'contact' => '(056) 333-1021', 'email' => 'mayor@esperanza.gov.ph', 'icon' => 'landmark', 'color' => 'from-navy-600 to-navy-900'],
        ['name' => 'Municipal Social Welfare & Development Office', 'head' => 'Ms. Corazon P. Villareal', 'contact' => '(056) 333-1044', 'email' => 'mswdo@esperanza.gov.ph', 'icon' => 'hand-heart', 'color' => 'from-purple-500 to-purple-700'],
        ['name' => 'Municipal Treasurer\'s Office', 'head' => 'Mr. Bienvenido T. Salazar', 'contact' => '(056) 333-1032', 'email' => 'treasury@esperanza.gov.ph', 'icon' => 'wallet', 'color' => 'from-gold-500 to-gold-700'],
        ['name' => 'Municipal Health Office', 'head' => 'Dr. Leilani F. Domingo', 'contact' => '(056) 333-1056', 'email' => 'health@esperanza.gov.ph', 'icon' => 'stethoscope', 'color' => 'from-emerald-500 to-emerald-700'],
        ['name' => 'Office of the Municipal Civil Registrar', 'head' => 'Narec N. Conag', 'contact' => '(056) 333-1067', 'email' => 'civilregistrar@esperanza.gov.ph', 'icon' => 'file-badge', 'color' => 'from-rose-500 to-rose-700'],
        ['name' => 'ICT Office', 'head' => 'Engr. Paolo J. Reyes', 'contact' => '(056) 333-1099', 'email' => 'ict@esperanza.gov.ph', 'icon' => 'monitor-cog', 'color' => 'from-brand-500 to-brand-700'],
    ];

    // Real per-barangay officials/seal/contact — same source of truth as the
    // Dokyu barangay letterhead (config/esperanza_barangay_documents.php), so
    // a captain's name here always matches what's shown everywhere else.
    $barangays = collect(config('esperanza_barangay_documents'))->map(fn ($b) => [
        'name' => $b['label'],
        'captain' => $b['officials']['punong_barangay'],
        'secretary' => $b['officials']['barangay_secretary'],
        'contact' => $b['contact'] ?? null,
        'seal' => $b['seal'],
    ])->sortBy('name')->values();
@endphp

<x-layouts.citizen title="Government Directory" subtitle="Contact details for municipal and barangay offices." active="directory">
    <div
        x-data="{
            tab: 'offices',
            search: '',
            offices: @js($offices),
            barangays: @js($barangays),
            get filteredOffices() {
                const q = this.search.trim().toLowerCase();
                return this.offices.filter(o => q === '' || o.name.toLowerCase().includes(q) || o.head.toLowerCase().includes(q));
            },
            get filteredBarangays() {
                const q = this.search.trim().toLowerCase();
                return this.barangays.filter(b => q === '' || b.name.toLowerCase().includes(q) || b.captain.toLowerCase().includes(q));
            },
        }"
        class="animate-fade-up"
    >

        <div class="bg-white border border-slate-200 rounded-2xl shadow-card p-3 mb-4 space-y-3">
            <div class="flex flex-wrap items-center gap-2">
                <div class="relative flex-1 min-w-[200px]">
                    <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none"></i>
                    <input type="text" x-model="search" x-bind:placeholder="$store.lang.current === 'en' ? 'Search offices or barangays...' : 'Maghanap ng opisina o barangay...'" class="w-full pl-9 pr-3 py-2 text-xs rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200">
                </div>
                <div class="flex items-center gap-1.5 bg-slate-100/70 rounded-xl p-1 w-fit overflow-x-auto shrink-0">
                    <button type="button" @click="tab = 'offices'" class="px-3 py-1.5 text-[11px] font-medium rounded-lg transition-colors flex items-center gap-1.5 whitespace-nowrap" :class="tab === 'offices' ? 'bg-white text-navy-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'">
                        <i data-lucide="building-2" class="w-3.5 h-3.5"></i><x-ui.t fil="Mga Opisina" en="Municipal Offices" />
                    </button>
                    <button type="button" @click="tab = 'barangays'" class="px-3 py-1.5 text-[11px] font-medium rounded-lg transition-colors flex items-center gap-1.5 whitespace-nowrap" :class="tab === 'barangays' ? 'bg-white text-navy-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'">
                        <i data-lucide="map-pin" class="w-3.5 h-3.5"></i><x-ui.t fil="Mga Barangay" en="Barangays" />
                    </button>
                </div>
            </div>
            <p class="text-[11px] text-slate-400" x-text="(tab === 'offices' ? filteredOffices.length + ' ' + ($store.lang.current === 'en' ? 'of ' + offices.length + ' offices' : 'sa ' + offices.length + ' opisina') : filteredBarangays.length + ' ' + ($store.lang.current === 'en' ? 'of ' + barangays.length + ' barangays' : 'sa ' + barangays.length + ' barangay'))"></p>
        </div>

        <!-- Municipal Offices -->
        <div x-show="tab === 'offices'">
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                <template x-for="office in filteredOffices" :key="office.name">
                    <div class="bg-white rounded-2xl border border-slate-100 shadow-card overflow-hidden hover:shadow-card-hover hover:-translate-y-0.5 transition-all duration-300 group">
                        <div class="h-20 bg-gradient-to-br flex items-center px-4 relative overflow-hidden" :class="office.color">
                            <i data-lucide="landmark" class="w-16 h-16 text-white/10 absolute -right-2 -bottom-3 rotate-12"></i>
                            <span class="w-11 h-11 rounded-xl bg-white/15 backdrop-blur flex items-center justify-center text-white shrink-0 relative">
                                <i :data-lucide="office.icon" class="w-5 h-5"></i>
                            </span>
                        </div>
                        <div class="p-4">
                            <p class="text-sm font-semibold text-navy-900 leading-snug" x-text="office.name"></p>
                            <p class="text-xs text-slate-400 mt-0.5" x-text="office.head"></p>
                            <div class="flex items-center gap-2 mt-3.5 pt-3.5 border-t border-slate-100">
                                <a :href="'tel:' + office.contact.replace(/[^0-9+]/g, '')" class="flex-1 inline-flex items-center justify-center gap-1.5 text-[11px] font-medium text-slate-600 bg-slate-50 hover:bg-slate-100 rounded-lg px-2.5 py-2 transition-colors">
                                    <i data-lucide="phone" class="w-3.5 h-3.5"></i><span x-text="office.contact"></span>
                                </a>
                                <a :href="'mailto:' + office.email" class="w-9 h-9 shrink-0 inline-flex items-center justify-center text-slate-500 bg-slate-50 hover:bg-brand-50 hover:text-brand-600 rounded-lg transition-colors" :title="office.email">
                                    <i data-lucide="mail" class="w-3.5 h-3.5"></i>
                                </a>
                            </div>
                        </div>
                    </div>
                </template>
            </div>
            <div class="flex flex-col items-center text-center py-12 bg-white border border-slate-100 rounded-2xl" x-show="filteredOffices.length === 0">
                <span class="w-11 h-11 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mb-3"><i data-lucide="search-x" class="w-5 h-5"></i></span>
                <p class="text-sm font-medium text-slate-600"><x-ui.t fil="Walang natagpuang opisina." en="No offices match your search." /></p>
            </div>
        </div>

        <!-- Barangays -->
        <div x-show="tab === 'barangays'" x-cloak>
            <!-- My Barangay -->
            <div x-show="$store.barangay.mine" x-cloak class="rounded-2xl bg-gradient-to-br from-brand-50 via-white to-purple-50/60 border border-brand-100 shadow-card p-4 sm:p-5 mb-4">
                <p class="text-[11px] font-semibold text-brand-600 uppercase tracking-wide mb-3 flex items-center gap-1.5"><i data-lucide="star" class="w-3.5 h-3.5"></i><x-ui.t fil="Aking Barangay" en="My Barangay" /></p>
                <div class="flex flex-col sm:flex-row sm:items-center gap-4">
                    <div class="flex items-center gap-3.5 flex-1 min-w-0">
                        <div class="relative w-14 h-14 shrink-0">
                            <div class="absolute inset-0 rounded-full bg-white border-2 border-gold-400 flex items-center justify-center text-slate-300"><i data-lucide="landmark" class="w-6 h-6"></i></div>
                            <img
                                :src="$store.barangay.mine?.seal ? '{{ rtrim(asset(''), '/') }}/' + $store.barangay.mine.seal : ''"
                                x-show="$store.barangay.mine?.seal" onerror="this.style.display='none'" alt=""
                                class="relative w-14 h-14 rounded-full object-cover border-2 border-gold-400"
                            >
                        </div>
                        <div class="min-w-0">
                            <h3 class="text-base font-semibold text-navy-900 truncate"><x-ui.t fil="Barangay" en="Barangay" /> <span x-text="$store.barangay.mine?.label"></span></h3>
                            <p class="text-xs text-slate-500 mt-0.5 truncate"><x-ui.t fil="Punong Barangay:" en="Punong Barangay:" /> <span class="font-medium text-slate-700" x-text="$store.barangay.mine?.officials?.punong_barangay"></span></p>
                            <p class="text-xs text-slate-500 mt-0.5 truncate"><x-ui.t fil="Kalihim:" en="Barangay Secretary:" /> <span class="font-medium text-slate-700" x-text="$store.barangay.mine?.officials?.barangay_secretary"></span></p>
                        </div>
                    </div>
                    <div class="flex items-center gap-2 shrink-0">
                        <a
                            :href="'tel:' + ($store.barangay.mine?.contact || '').replace(/[^0-9+]/g, '')"
                            x-show="$store.barangay.mine?.contact"
                            class="inline-flex items-center gap-1.5 text-xs font-medium text-slate-600 bg-white border border-slate-200 hover:bg-slate-50 rounded-xl px-3.5 py-2.5 transition-colors"
                        ><i data-lucide="phone" class="w-3.5 h-3.5"></i><span x-text="$store.barangay.mine?.contact"></span></a>
                        <x-ui.button :href="route('citizen.document-requests')" size="sm" icon="file-text"><x-ui.t fil="Humiling ng Dokyu" en="Request Documents" /></x-ui.button>
                    </div>
                </div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                <template x-for="b in filteredBarangays" :key="b.name">
                    <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4 hover:shadow-card-hover hover:-translate-y-0.5 transition-all duration-300 flex items-center gap-3.5">
                        <div class="relative w-12 h-12 shrink-0">
                            <div class="absolute inset-0 rounded-full bg-gradient-to-br from-brand-50 to-purple-50 border-2 border-brand-100 flex items-center justify-center text-brand-400">
                                <i data-lucide="map-pinned" class="w-5 h-5"></i>
                            </div>
                            <img
                                :src="b.seal ? '{{ rtrim(asset(''), '/') }}/' + b.seal : ''"
                                x-show="b.seal" onerror="this.style.display='none'" alt=""
                                class="relative w-12 h-12 rounded-full object-cover border-2 border-brand-100"
                            >
                        </div>
                        <div class="min-w-0 flex-1">
                            <p class="text-sm font-semibold text-navy-900 truncate" x-text="'Brgy. ' + b.name"></p>
                            <p class="text-xs text-slate-400 truncate" x-text="b.captain"></p>
                            <a :href="'tel:' + b.contact.replace(/[^0-9+]/g, '')" class="inline-flex items-center gap-1 text-[11px] font-medium text-brand-600 hover:underline mt-1">
                                <i data-lucide="phone" class="w-3 h-3"></i><span x-text="b.contact"></span>
                            </a>
                        </div>
                    </div>
                </template>
            </div>
            <div class="flex flex-col items-center text-center py-12 bg-white border border-slate-100 rounded-2xl" x-show="filteredBarangays.length === 0">
                <span class="w-11 h-11 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mb-3"><i data-lucide="search-x" class="w-5 h-5"></i></span>
                <p class="text-sm font-medium text-slate-600"><x-ui.t fil="Walang natagpuang barangay." en="No barangays match your search." /></p>
            </div>
        </div>
    </div>
</x-layouts.citizen>
