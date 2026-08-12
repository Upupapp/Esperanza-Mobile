<x-layouts.guest title="Welcome" image="esperanza-aerial.jpg" fullscreen>
    <div class="lg:hidden flex items-center gap-3 mb-8">
        <img src="{{ asset('images/esperanza/esperanza-seal.png') }}" class="w-11 h-11 rounded-full ring-2 ring-slate-200 object-cover" alt="Seal">
        <div>
            <p class="font-semibold text-navy-900 leading-tight">Municipality of Esperanza</p>
            <p class="text-xs text-slate-400">Province of Masbate</p>
        </div>
    </div>

    <h1 class="text-2xl font-semibold text-navy-900"><x-ui.t fil="Maligayang Pagdating sa Esperanza Web Platform" en="Welcome to the Esperanza Web Platform" /></h1>
    <p class="text-slate-500 text-sm mt-1.5"><x-ui.t fil="Piliin kung paano ka mag-sign in." en="Choose how you'd like to sign in." /></p>

    <div class="mt-7 space-y-4">
        <a href="{{ route('citizen.login') }}" class="group relative flex items-center gap-4 p-5 rounded-2xl border border-slate-200 bg-white hover:border-brand-300 hover:shadow-card-hover transition-all duration-300 overflow-hidden animate-fade-up">
            <div class="absolute inset-0 bg-gradient-to-r from-brand-50/0 via-brand-50/0 to-brand-50/60 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
            <div class="relative w-12 h-12 rounded-xl bg-brand-50 text-brand-600 flex items-center justify-center shrink-0 transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-3">
                <i data-lucide="user" class="w-6 h-6"></i>
            </div>
            <div class="relative flex-1 min-w-0">
                <p class="font-semibold text-navy-900"><x-ui.t fil="Portal ng Mamamayan" en="Citizen Portal" /></p>
                <p class="text-sm text-slate-400"><x-ui.t fil="Humiling ng dokumento, subaybayan ang aplikasyon, at manatiling updated." en="Request documents, track applications, and stay updated." /></p>
            </div>
            <i data-lucide="chevron-right" class="relative w-5 h-5 text-slate-300 transition-all duration-200 group-hover:text-brand-500 group-hover:translate-x-1"></i>
        </a>

        <a href="{{ route('admin.login') }}" class="group relative flex items-center gap-4 p-5 rounded-2xl border border-slate-200 bg-white hover:border-navy-300 hover:shadow-card-hover transition-all duration-300 overflow-hidden animate-fade-up" style="animation-delay: 80ms">
            <div class="absolute inset-0 bg-gradient-to-r from-navy-50/0 via-navy-50/0 to-slate-100/60 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
            <div class="relative w-12 h-12 rounded-xl bg-navy-900/5 text-navy-800 flex items-center justify-center shrink-0 transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-3">
                <i data-lucide="shield-check" class="w-6 h-6"></i>
            </div>
            <div class="relative flex-1 min-w-0">
                <p class="font-semibold text-navy-900">LGU Personnel</p>
                <p class="text-sm text-slate-400">Manage requests, residents, and municipal operations.</p>
            </div>
            <i data-lucide="chevron-right" class="relative w-5 h-5 text-slate-300 transition-all duration-200 group-hover:text-navy-600 group-hover:translate-x-1"></i>
        </a>
    </div>

    <p class="text-center text-sm text-slate-400 mt-7">
        <x-ui.t fil="Bago sa Esperanza LGU?" en="New to Esperanza LGU?" /> <a href="{{ route('citizen.register') }}" class="text-brand-600 font-medium hover:underline"><x-ui.t fil="Gumawa ng account ng mamamayan" en="Create a citizen account" /></a>
    </p>
</x-layouts.guest>
