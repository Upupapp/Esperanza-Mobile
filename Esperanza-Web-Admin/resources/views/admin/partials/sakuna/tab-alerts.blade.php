{{--
    resources/views/admin/partials/sakuna/tab-alerts.blade.php
    Alert Composition and Publishing Interface — SAKUNA Disaster Management Module
    @include'd from admin/sakuna.blade.php — Alpine state inherited from parent x-data.
    DO NOT add x-data at the root level of this file.
--}}

@php
    $levelBorder = [
        'Information' => 'border-sky-400',
        'Advisory'    => 'border-teal-400',
        'Watch'       => 'border-amber-400',
        'Warning'     => 'border-orange-400',
        'Critical'    => 'border-rose-500',
    ];

    $alertTypes = [
        'Flood Warning',
        'Storm Surge Advisory',
        'Landslide Watch',
        'Typhoon Advisory',
        'Earthquake Warning',
        'Volcanic Activity Advisory',
        'Tsunami Warning',
        'Mandatory Evacuation Order',
        'Pre-Emptive Evacuation Advisory',
        'Fire Emergency Alert',
        'Public Health Advisory',
        'Road and Infrastructure Closure',
        'Missing Person Alert',
        'Agricultural Damage Advisory',
        'Power Interruption Notice',
        'Water Service Interruption Notice',
        'Search and Rescue Operation Notice',
        'All-Clear / Situation Normal',
    ];

    $alertLevels   = ['Information', 'Advisory', 'Watch', 'Warning', 'Critical'];
    $alertStatuses = ['Draft', 'For Review', 'Approved', 'Scheduled', 'Published', 'Expired', 'Cancelled', 'Archived'];

    $targetGroups = [
        'All Residents',
        'Evacuation Center Occupants',
        'Vulnerable Households',
        'Farmers',
        'Senior Citizens',
        'PWD Households',
        'MDRRMO Personnel',
    ];
@endphp

{{-- ══════════════════════════════════════════════════════════════════════════ --}}
{{-- A. ACTIVE CRITICAL ALERT BANNER                                            --}}
{{-- ══════════════════════════════════════════════════════════════════════════ --}}
<div class="bg-rose-50 border border-rose-200 rounded-2xl p-4 flex items-start gap-3 mb-4">
    <div class="w-10 h-10 rounded-xl bg-rose-100 flex items-center justify-center flex-shrink-0">
        <i data-lucide="siren" class="w-5 h-5 text-rose-600"></i>
    </div>
    <div class="flex-1 min-w-0">
        <div class="flex items-center gap-2 flex-wrap mb-0.5">
            <span class="text-xs font-semibold uppercase tracking-wider text-rose-600">Active Critical Alert</span>
            <span class="px-2 py-0.5 bg-rose-100 text-rose-700 border border-rose-200 rounded-full text-xs font-medium">Mandatory Evacuation</span>
        </div>
        <p class="text-sm font-semibold text-slate-800">Sapilitang Bakwit — Masbaranon Purok 3 at 4</p>
        <p class="text-xs text-slate-500 mt-0.5">Published Jul 15, 2026 05:30 AM by MDRRMO Head Salinas &middot; Target: Municipality-Wide &middot; 4 Channels</p>
    </div>
    <div class="flex gap-2 flex-shrink-0">
        <button
            @click="$dispatch('toast', { message: 'Alert details loaded.', variant: 'info' })"
            class="text-xs font-medium text-rose-700 bg-rose-100 hover:bg-rose-200 rounded-lg px-3 py-1.5 transition-colors">
            View Details
        </button>
        <button
            @click="$dispatch('toast', { message: 'Cancellation requires supervisor confirmation.', variant: 'warning' })"
            class="text-xs font-medium text-slate-600 bg-white border border-rose-200 hover:bg-rose-50 rounded-lg px-3 py-1.5 transition-colors">
            Cancel Alert
        </button>
    </div>
</div>

{{-- ══════════════════════════════════════════════════════════════════════════ --}}
{{-- B. HEADER ROW                                                              --}}
{{-- ══════════════════════════════════════════════════════════════════════════ --}}
<div class="flex items-start justify-between gap-4 mb-4 flex-wrap">
    <div>
        <h2 class="text-lg font-bold text-slate-800">Alerts &amp; Advisories</h2>
        <p class="text-sm text-slate-500 mt-0.5">Compose, review, publish, and manage alerts and public advisories.</p>
    </div>
    <div class="flex items-center gap-2 flex-shrink-0">
        <button
            @click="$dispatch('toast', { message: 'Alert list exported to CSV.', variant: 'success' })"
            class="flex items-center gap-1.5 px-3 py-2 text-sm font-medium text-slate-600 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors shadow-sm">
            <i data-lucide="download" class="w-4 h-4"></i>
            <span class="hidden sm:inline">Export</span>
        </button>
        <button
            @click="showCreateAlert = true; alertComposerStep = 1; $nextTick(() => window.renderIcons?.())"
            class="flex items-center gap-1.5 px-4 py-2 text-sm font-semibold text-white bg-brand-600 hover:bg-brand-700 rounded-xl transition-colors shadow-sm">
            <i data-lucide="plus" class="w-4 h-4"></i>
            Create Alert
        </button>
    </div>
</div>

{{-- ══════════════════════════════════════════════════════════════════════════ --}}
{{-- C. STATS PILLS                                                             --}}
{{-- ══════════════════════════════════════════════════════════════════════════ --}}
<div class="flex items-center gap-2 flex-wrap mb-4">
    <div class="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-50 border border-emerald-100 rounded-full">
        <span class="w-2 h-2 rounded-full bg-emerald-500 flex-shrink-0"></span>
        <span class="text-xs font-semibold text-emerald-700">Published</span>
        <span class="text-xs font-bold text-emerald-800">5</span>
    </div>
    <div class="flex items-center gap-1.5 px-3 py-1.5 bg-slate-100 border border-slate-200 rounded-full">
        <span class="w-2 h-2 rounded-full bg-slate-400 flex-shrink-0"></span>
        <span class="text-xs font-semibold text-slate-600">Draft</span>
        <span class="text-xs font-bold text-slate-800">2</span>
    </div>
    <div class="flex items-center gap-1.5 px-3 py-1.5 bg-blue-50 border border-blue-100 rounded-full">
        <span class="w-2 h-2 rounded-full bg-blue-400 flex-shrink-0"></span>
        <span class="text-xs font-semibold text-blue-700">Scheduled</span>
        <span class="text-xs font-bold text-blue-800">0</span>
    </div>
    <div class="flex items-center gap-1.5 px-3 py-1.5 bg-rose-50 border border-rose-200 rounded-full">
        <span class="w-2 h-2 rounded-full bg-rose-500 animate-pulse flex-shrink-0"></span>
        <span class="text-xs font-semibold text-rose-700">Critical Active</span>
        <span class="text-xs font-bold text-rose-800">1</span>
    </div>
    <div class="flex items-center gap-1.5 px-3 py-1.5 bg-slate-100 border border-slate-200 rounded-full">
        <span class="text-xs font-semibold text-slate-600">Total This Operation</span>
        <span class="text-xs font-bold text-slate-800">7</span>
    </div>
</div>

{{-- ══════════════════════════════════════════════════════════════════════════ --}}
{{-- D. FILTER BAR                                                              --}}
{{-- ══════════════════════════════════════════════════════════════════════════ --}}
<div class="flex flex-wrap gap-2 mb-5">
    {{-- Search --}}
    <div class="relative flex-1 min-w-48">
        <i data-lucide="search" class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none"></i>
        <input
            type="text"
            x-model="alertSearch"
            placeholder="Search by title or ID…"
            class="w-full pl-9 pr-3 py-2 text-sm border border-slate-200 rounded-xl bg-white text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors"
        />
    </div>

    {{-- Alert Type --}}
    <select
        x-model="alertTypeFilter"
        class="px-3 py-2 text-sm border border-slate-200 rounded-xl bg-white text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors">
        <option value="">All Types</option>
        @foreach($alertTypes as $type)
            <option value="{{ $type }}">{{ $type }}</option>
        @endforeach
    </select>

    {{-- Level --}}
    <select
        x-model="alertLevelFilter"
        class="px-3 py-2 text-sm border border-slate-200 rounded-xl bg-white text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors">
        <option value="">All Levels</option>
        @foreach($alertLevels as $level)
            <option value="{{ $level }}">{{ $level }}</option>
        @endforeach
    </select>

    {{-- Status --}}
    <select
        x-model="alertStatusFilter"
        class="px-3 py-2 text-sm border border-slate-200 rounded-xl bg-white text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors">
        <option value="">All Statuses</option>
        @foreach($alertStatuses as $st)
            <option value="{{ $st }}">{{ $st }}</option>
        @endforeach
    </select>

    {{-- Clear --}}
    <button
        @click="alertSearch = ''; alertTypeFilter = ''; alertLevelFilter = ''; alertStatusFilter = ''"
        class="px-3 py-2 text-sm font-medium text-slate-600 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors flex items-center gap-1.5">
        <i data-lucide="x" class="w-3.5 h-3.5"></i>
        Clear
    </button>
</div>

{{-- ══════════════════════════════════════════════════════════════════════════ --}}
{{-- E. ALERT LIST                                                              --}}
{{-- ══════════════════════════════════════════════════════════════════════════ --}}
<div>
    @foreach($alerts as $alert)
        <div
            class="bg-white rounded-2xl shadow-card border border-slate-100 border-l-4 {{ $levelBorder[$alert['level']] ?? 'border-slate-300' }} p-4 mb-3 transition-shadow hover:shadow-md"
            x-show="
                (alertSearch === '' || '{{ strtolower($alert['title']) }}'.includes(alertSearch.toLowerCase()) || '{{ strtolower($alert['id']) }}'.includes(alertSearch.toLowerCase())) &&
                (alertTypeFilter === '' || '{{ $alert['type'] }}' === alertTypeFilter) &&
                (alertLevelFilter === '' || '{{ $alert['level'] }}' === alertLevelFilter) &&
                (alertStatusFilter === '' || '{{ $alert['status'] }}' === alertStatusFilter)
            "
            x-transition:enter="transition ease-out duration-200"
            x-transition:enter-start="opacity-0 translate-y-1"
            x-transition:enter-end="opacity-100 translate-y-0"
        >
            <div class="flex items-start justify-between gap-3">
                <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2 flex-wrap mb-1">
                        <span class="text-xs font-mono text-slate-400">{{ $alert['id'] }}</span>
                        <span :class="alertLevelBadge('{{ $alert['level'] }}')">{{ $alert['level'] }}</span>
                        <span :class="statusBadge('{{ $alert['status'] }}')">{{ $alert['status'] }}</span>
                        <span class="text-xs text-slate-500 bg-slate-100 px-2 py-0.5 rounded-full">{{ $alert['type'] }}</span>
                    </div>
                    <p class="text-sm font-semibold text-slate-800 mb-1 truncate">{{ $alert['title'] }}</p>
                    <div class="flex items-center gap-3 flex-wrap">
                        <span class="text-xs text-slate-500 flex items-center gap-1">
                            <i data-lucide="target" class="w-3 h-3"></i>
                            {{ $alert['target'] }}
                        </span>
                        @foreach($alert['channels'] as $ch)
                            <span class="text-xs bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full">{{ $ch }}</span>
                        @endforeach
                    </div>
                    <p class="text-xs text-slate-400 mt-1.5">
                        {{ $alert['status'] === 'Published' ? 'Published ' . $alert['published'] : 'Not yet published' }}
                        &middot; By {{ $alert['created_by'] }}
                    </p>
                </div>
                <div class="flex gap-2 flex-shrink-0 flex-col items-end">
                    <button
                        @click="$dispatch('toast', { message: 'Alert details opened.', variant: 'info' })"
                        class="text-xs text-brand-600 hover:text-brand-700 font-medium">
                        View
                    </button>
                    @if($alert['status'] === 'Draft')
                        <button
                            @click="$dispatch('toast', { message: '{{ addslashes($alert['id']) }} submitted for review.', variant: 'success' })"
                            class="text-xs text-slate-600 hover:text-slate-800">
                            Submit for Review
                        </button>
                    @elseif($alert['status'] === 'For Review')
                        <button
                            @click="$dispatch('toast', { message: '{{ addslashes($alert['id']) }} approved.', variant: 'success' })"
                            class="text-xs text-emerald-600 hover:text-emerald-800 font-medium">
                            Approve
                        </button>
                    @elseif($alert['status'] === 'Approved')
                        <button
                            @click="$dispatch('toast', { message: '{{ addslashes($alert['id']) }} published to all channels.', variant: 'success' })"
                            class="text-xs text-brand-600 font-medium">
                            Publish Now
                        </button>
                    @elseif($alert['status'] === 'Published')
                        <button
                            @click="$dispatch('toast', { message: '{{ addslashes($alert['id']) }} archived.', variant: 'info' })"
                            class="text-xs text-slate-500">
                            Archive
                        </button>
                    @endif
                </div>
            </div>
        </div>
    @endforeach

    {{-- Empty state --}}
    <div
        class="text-center py-10 text-slate-400"
        x-show="alertSearch !== '' || alertTypeFilter !== '' || alertLevelFilter !== '' || alertStatusFilter !== ''"
        style="display:none"
    >
        <i data-lucide="bell-off" class="w-10 h-10 mx-auto mb-3 text-slate-300"></i>
        <p class="text-sm">No alerts match your filters.</p>
        <button
            @click="alertSearch = ''; alertTypeFilter = ''; alertLevelFilter = ''; alertStatusFilter = ''"
            class="mt-2 text-sm text-brand-600 hover:underline">
            Clear filters
        </button>
    </div>
</div>

{{-- ══════════════════════════════════════════════════════════════════════════ --}}
{{-- F. CREATE ALERT MODAL                                                      --}}
{{-- ══════════════════════════════════════════════════════════════════════════ --}}
<div
    x-show="showCreateAlert"
    x-cloak
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
    @click.self="showCreateAlert = false; alertComposerStep = 1"
    x-transition:enter="transition ease-out duration-200"
    x-transition:enter-start="opacity-0"
    x-transition:enter-end="opacity-100"
    x-transition:leave="transition ease-in duration-150"
    x-transition:leave-start="opacity-100"
    x-transition:leave-end="opacity-0"
>
    <div
        class="bg-white rounded-2xl shadow-float w-full max-w-3xl max-h-[90vh] overflow-y-auto p-6"
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0 scale-95"
        x-transition:enter-end="opacity-100 scale-100"
    >
        {{-- Modal header --}}
        <div class="flex items-center justify-between mb-6">
            <div>
                <h3 class="text-base font-bold text-slate-800">Compose Alert</h3>
                <p class="text-xs text-slate-500 mt-0.5">Create and publish a new public alert or advisory.</p>
            </div>
            <button
                @click="showCreateAlert = false; alertComposerStep = 1"
                class="w-8 h-8 rounded-lg flex items-center justify-center text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors">
                <i data-lucide="x" class="w-4 h-4"></i>
            </button>
        </div>

        {{-- Step indicator --}}
        <div class="flex items-center mb-6 overflow-x-auto pb-1">
            <template x-for="(step, i) in [{label:'Compose'},{label:'Target'},{label:'Preview'},{label:'Publish'}]" :key="i">
                <div class="flex items-center flex-shrink-0">
                    <div
                        class="flex items-center gap-2"
                        :class="alertComposerStep > i+1 ? 'text-emerald-600' : alertComposerStep === i+1 ? 'text-brand-600' : 'text-slate-400'">
                        <div
                            class="w-7 h-7 rounded-full border-2 flex items-center justify-center text-xs font-bold transition-all"
                            :class="alertComposerStep > i+1 ? 'bg-emerald-500 border-emerald-500 text-white' : alertComposerStep === i+1 ? 'border-brand-500 text-brand-600 bg-brand-50' : 'border-slate-200 text-slate-400'"
                            x-text="alertComposerStep > i+1 ? '✓' : i+1">
                        </div>
                        <span class="text-xs font-medium hidden sm:block" x-text="step.label"></span>
                    </div>
                    <div
                        x-show="i < 3"
                        class="w-8 h-px mx-2 transition-colors"
                        :class="alertComposerStep > i+1 ? 'bg-emerald-400' : 'bg-slate-200'">
                    </div>
                </div>
            </template>
        </div>

        {{-- ── STEP 1: Compose ─────────────────────────────────────────── --}}
        <div x-show="alertComposerStep === 1" x-transition:enter="transition ease-out duration-150" x-transition:enter-start="opacity-0 translate-x-2" x-transition:enter-end="opacity-100 translate-x-0">
            <div class="space-y-4">
                {{-- Title --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-700 mb-1.5">Alert Title <span class="text-rose-500">*</span></label>
                    <input
                        type="text"
                        placeholder="e.g. Flood Warning — Masbaranon"
                        class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-white text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors"
                    />
                </div>

                {{-- Type + Level side by side --}}
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1.5">Alert Type <span class="text-rose-500">*</span></label>
                        <select class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-white text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors">
                            <option value="">Select type…</option>
                            @foreach($alertTypes as $type)
                                <option value="{{ $type }}">{{ $type }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1.5">Alert Level <span class="text-rose-500">*</span></label>
                        <select class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-white text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors">
                            <option value="">Select level…</option>
                            @foreach($alertLevels as $level)
                                <option value="{{ $level }}">{{ $level }}</option>
                            @endforeach
                        </select>
                    </div>
                </div>

                {{-- Message in Filipino --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-700 mb-1.5">
                        Message in Filipino <span class="text-rose-500">*</span>
                    </label>
                    <textarea
                        rows="4"
                        placeholder="Ilagay ang mensahe ng abiso sa Filipino…"
                        class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-white text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors resize-y">
                    </textarea>
                    <p class="text-xs text-slate-400 mt-1">Use clear, simple language. Residents must understand the action required.</p>
                </div>

                {{-- English version (collapsible) --}}
                <details class="border border-slate-100 rounded-xl overflow-hidden">
                    <summary class="px-4 py-3 text-xs font-semibold text-slate-600 cursor-pointer hover:bg-slate-50 transition-colors list-none flex items-center gap-2">
                        <i data-lucide="circle-plus" class="w-3.5 h-3.5 text-slate-400"></i>
                        Add English version (optional)
                    </summary>
                    <div class="px-4 pb-4 pt-2 border-t border-slate-100">
                        <textarea
                            rows="3"
                            placeholder="Enter English translation of the alert message…"
                            class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-white text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors resize-y">
                        </textarea>
                    </div>
                </details>

                {{-- Recommended Actions --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-700 mb-1.5">Recommended Actions</label>
                    <textarea
                        rows="2"
                        placeholder="e.g. Lumikas agad patungo sa pinakamalapit na evacuation center. Dalhin ang mga gamit na kailangan."
                        class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-white text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors resize-y">
                    </textarea>
                </div>

                {{-- Issuing Office + Approving Officer --}}
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1.5">Issuing Office</label>
                        <input
                            type="text"
                            placeholder="e.g. MDRRMO Esperanza"
                            class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-white text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors"
                        />
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1.5">Approving Officer</label>
                        <input
                            type="text"
                            placeholder="e.g. MDRRMO Head R. Salinas"
                            class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-white text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors"
                        />
                    </div>
                </div>

                {{-- Attachment --}}
                <button
                    @click="$dispatch('toast', { message: 'File upload available in production.', variant: 'info' })"
                    class="flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-slate-600 border border-slate-200 border-dashed rounded-xl hover:bg-slate-50 transition-colors w-full justify-center">
                    <i data-lucide="paperclip" class="w-4 h-4 text-slate-400"></i>
                    Attach supporting document or image (optional)
                </button>
            </div>
        </div>

        {{-- ── STEP 2: Target & Channels ───────────────────────────────── --}}
        <div x-show="alertComposerStep === 2" x-transition:enter="transition ease-out duration-150" x-transition:enter-start="opacity-0 translate-x-2" x-transition:enter-end="opacity-100 translate-x-0"
            x-data="{ targetScope: 'municipality', selectedBarangays: [], selectedGroups: [], selectedChannels: [] }">
            <div class="space-y-5">
                {{-- Target Scope --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-700 mb-2.5">Target Scope <span class="text-rose-500">*</span></label>
                    <div class="flex flex-wrap gap-3">
                        <label class="flex items-center gap-2 cursor-pointer">
                            <input type="radio" x-model="targetScope" value="municipality" class="w-4 h-4 text-brand-600 border-slate-300 focus:ring-brand-500" />
                            <span class="text-sm font-medium text-slate-700">Municipality-Wide</span>
                            <span class="text-xs text-slate-400 bg-slate-100 px-2 py-0.5 rounded-full">All 20 barangays</span>
                        </label>
                        <label class="flex items-center gap-2 cursor-pointer">
                            <input type="radio" x-model="targetScope" value="barangays" class="w-4 h-4 text-brand-600 border-slate-300 focus:ring-brand-500" />
                            <span class="text-sm font-medium text-slate-700">Selected Barangays</span>
                        </label>
                        <label class="flex items-center gap-2 cursor-pointer">
                            <input type="radio" x-model="targetScope" value="groups" class="w-4 h-4 text-brand-600 border-slate-300 focus:ring-brand-500" />
                            <span class="text-sm font-medium text-slate-700">Specific Groups</span>
                        </label>
                    </div>
                </div>

                {{-- Barangay checkbox grid --}}
                <div x-show="targetScope === 'barangays'">
                    <label class="block text-xs font-semibold text-slate-700 mb-2">Select Barangays</label>
                    <div class="grid grid-cols-2 sm:grid-cols-4 gap-2 border border-slate-100 rounded-xl p-3 bg-slate-50 max-h-52 overflow-y-auto">
                        @foreach($barangays as $brgy)
                            <label class="flex items-center gap-2 cursor-pointer text-xs text-slate-700 hover:text-slate-900 py-0.5">
                                <input type="checkbox" value="{{ $brgy }}" x-model="selectedBarangays" class="w-3.5 h-3.5 text-brand-600 border-slate-300 rounded focus:ring-brand-500" />
                                {{ $brgy }}
                            </label>
                        @endforeach
                    </div>
                    <p class="text-xs text-slate-400 mt-1.5" x-text="selectedBarangays.length + ' barangay(s) selected'"></p>
                </div>

                {{-- Target Groups --}}
                <div x-show="targetScope === 'groups'">
                    <label class="block text-xs font-semibold text-slate-700 mb-2">Target Groups</label>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                        @foreach($targetGroups as $group)
                            <label class="flex items-center gap-2.5 cursor-pointer p-2.5 border border-slate-100 rounded-xl hover:bg-slate-50 transition-colors text-sm text-slate-700">
                                <input type="checkbox" value="{{ $group }}" x-model="selectedGroups" class="w-4 h-4 text-brand-600 border-slate-300 rounded focus:ring-brand-500" />
                                {{ $group }}
                            </label>
                        @endforeach
                    </div>
                </div>

                {{-- Delivery Channels --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-700 mb-2.5">Delivery Channels</label>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                        @php
                            $channels = [
                                ['id' => 'push',    'label' => 'Mobile Push Notification',        'icon' => 'bell',             'desc' => 'All registered app users in target area'],
                                ['id' => 'sms',     'label' => 'SMS',                             'icon' => 'message-square',   'desc' => 'Via LGU SMS gateway'],
                                ['id' => 'portal',  'label' => 'Portal Banner',                   'icon' => 'layout-dashboard', 'desc' => 'Pinned banner on citizen portal'],
                                ['id' => 'brgy',    'label' => 'Barangay Personnel Notification', 'icon' => 'users',            'desc' => 'Notifies all barangay captains & BDRRMOs'],
                                ['id' => 'social',  'label' => 'Social Media Copy',               'icon' => 'share-2',          'desc' => 'Generates shareable text for Facebook/FB Page'],
                                ['id' => 'siren',   'label' => 'Public Display / Siren Instruction', 'icon' => 'radio-tower',  'desc' => 'Instruction sent to public display operators'],
                            ];
                        @endphp
                        @foreach($channels as $ch)
                            <label class="flex items-start gap-3 cursor-pointer p-3 border border-slate-100 rounded-xl hover:bg-slate-50 transition-colors">
                                <input type="checkbox" value="{{ $ch['id'] }}" x-model="selectedChannels" class="w-4 h-4 text-brand-600 border-slate-300 rounded focus:ring-brand-500 mt-0.5 flex-shrink-0" />
                                <div>
                                    <div class="flex items-center gap-1.5">
                                        <i data-lucide="{{ $ch['icon'] }}" class="w-3.5 h-3.5 text-brand-500"></i>
                                        <span class="text-sm font-medium text-slate-700">{{ $ch['label'] }}</span>
                                    </div>
                                    <p class="text-xs text-slate-400 mt-0.5">{{ $ch['desc'] }}</p>
                                </div>
                            </label>
                        @endforeach
                    </div>
                    <p class="text-xs text-slate-400 mt-2" x-text="selectedChannels.length + ' channel(s) selected'"></p>
                </div>

                {{-- Effective + Expiration --}}
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1.5">Effective Date &amp; Time</label>
                        <input
                            type="datetime-local"
                            class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors"
                        />
                        <p class="text-xs text-slate-400 mt-1">Leave blank to publish immediately.</p>
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-700 mb-1.5">Expiration Date &amp; Time</label>
                        <input
                            type="datetime-local"
                            class="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-xl bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors"
                        />
                        <p class="text-xs text-slate-400 mt-1">Leave blank for indefinite.</p>
                    </div>
                </div>
            </div>
        </div>

        {{-- ── STEP 3: Preview ─────────────────────────────────────────── --}}
        <div x-show="alertComposerStep === 3" x-transition:enter="transition ease-out duration-150" x-transition:enter-start="opacity-0 translate-x-2" x-transition:enter-end="opacity-100 translate-x-0">
            <p class="text-xs text-slate-500 mb-4">Review how this alert will appear to recipients across delivery channels.</p>
            <div class="flex flex-col sm:flex-row gap-6 items-start justify-center">
                {{-- Mobile push preview --}}
                <div class="flex flex-col items-center">
                    <div class="w-64 bg-gray-900 rounded-3xl p-4 shadow-xl">
                        <div class="bg-gray-800 rounded-2xl p-3">
                            <div class="flex items-center gap-2 mb-2">
                                <div class="w-6 h-6 rounded bg-rose-500 flex items-center justify-center flex-shrink-0">
                                    <i data-lucide="shield-alert" class="w-3.5 h-3.5 text-white"></i>
                                </div>
                                <span class="text-xs text-gray-300 font-medium">Esperanza MDRRMO</span>
                                <span class="text-xs text-gray-500 ml-auto">now</span>
                            </div>
                            <p class="text-xs font-semibold text-white mb-1">Flood Warning Alert</p>
                            <p class="text-xs text-gray-400 leading-relaxed">Patuloy na tumataas ang tubig sa Masbaranon. Lumikas na agad sa pinakamalapit na evacuation center.</p>
                        </div>
                        <div class="flex justify-center gap-4 mt-3">
                            <button class="text-xs text-brand-400 font-medium">View Alert</button>
                            <button class="text-xs text-gray-400">Dismiss</button>
                        </div>
                    </div>
                    <p class="text-xs text-slate-400 text-center mt-2">Mobile Push Notification</p>
                </div>

                {{-- Portal banner + SMS previews --}}
                <div class="flex-1 w-full space-y-4">
                    {{-- Portal banner preview --}}
                    <div>
                        <div class="bg-rose-600 rounded-xl p-4 flex items-center gap-3">
                            <i data-lucide="triangle-alert" class="w-5 h-5 text-white flex-shrink-0"></i>
                            <div class="flex-1 min-w-0">
                                <p class="text-xs font-semibold text-rose-100 uppercase tracking-wide">Warning</p>
                                <p class="text-sm font-bold text-white">Flood Warning Alert</p>
                                <p class="text-xs text-rose-200">Masbaranon, Baras — Issued Jul 15, 2026 by MDRRMO Esperanza</p>
                            </div>
                            <button class="ml-auto text-rose-200 hover:text-white flex-shrink-0">
                                <i data-lucide="x" class="w-4 h-4"></i>
                            </button>
                        </div>
                        <p class="text-xs text-slate-400 text-center mt-2">Portal Banner Preview</p>
                    </div>

                    {{-- SMS preview --}}
                    <div>
                        <div class="bg-gray-900 rounded-xl p-4">
                            <div class="flex items-center gap-2 mb-2">
                                <div class="w-5 h-5 rounded bg-emerald-600 flex items-center justify-center flex-shrink-0">
                                    <i data-lucide="message-square" class="w-3 h-3 text-white"></i>
                                </div>
                                <span class="text-xs text-gray-400">SMS · LGU-ESPERANZA · Municipality-Wide</span>
                            </div>
                            <p class="text-xs text-gray-200 leading-relaxed">[MDRRMO ESPERANZA] BABALA: Tumataas ang tubig sa Masbaranon. Sapilitang bakwit ang mga residente ng Purok 3 at 4. Lumikas na agad sa evacuation center. Para sa tulong: 0917-xxx-xxxx</p>
                        </div>
                        <p class="text-xs text-slate-400 text-center mt-2">SMS Preview</p>
                    </div>
                </div>
            </div>

            <div class="mt-5 bg-sky-50 border border-sky-200 rounded-xl p-3 flex items-start gap-2">
                <i data-lucide="info" class="w-4 h-4 text-sky-600 flex-shrink-0 mt-0.5"></i>
                <p class="text-xs text-sky-700">Actual message content will reflect what was entered in Step 1. Previews above use sample text for illustration.</p>
            </div>
        </div>

        {{-- ── STEP 4: Publish ─────────────────────────────────────────── --}}
        <div x-show="alertComposerStep === 4" x-transition:enter="transition ease-out duration-150" x-transition:enter-start="opacity-0 translate-x-2" x-transition:enter-end="opacity-100 translate-x-0">
            <div class="space-y-4">
                {{-- Summary box --}}
                <div class="bg-slate-50 border border-slate-100 rounded-xl p-4">
                    <p class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">Alert Summary</p>
                    <div class="space-y-2">
                        <div class="flex items-start gap-3">
                            <span class="text-xs text-slate-500 w-24 flex-shrink-0">Title</span>
                            <span class="text-sm font-semibold text-slate-800">Flood Warning Alert — Masbaranon</span>
                        </div>
                        <div class="flex items-start gap-3">
                            <span class="text-xs text-slate-500 w-24 flex-shrink-0">Type &amp; Level</span>
                            <div class="flex items-center gap-2 flex-wrap">
                                <span class="text-xs bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full">Flood Warning</span>
                                <span class="text-xs px-2.5 py-0.5 rounded-full bg-orange-100 text-orange-700 font-medium">Warning</span>
                            </div>
                        </div>
                        <div class="flex items-start gap-3">
                            <span class="text-xs text-slate-500 w-24 flex-shrink-0">Target</span>
                            <span class="text-sm text-slate-700">Municipality-Wide</span>
                        </div>
                        <div class="flex items-start gap-3">
                            <span class="text-xs text-slate-500 w-24 flex-shrink-0">Channels</span>
                            <div class="flex flex-wrap gap-1.5">
                                <span class="text-xs bg-brand-50 text-brand-700 px-2 py-0.5 rounded-full">Mobile Push</span>
                                <span class="text-xs bg-brand-50 text-brand-700 px-2 py-0.5 rounded-full">SMS</span>
                                <span class="text-xs bg-brand-50 text-brand-700 px-2 py-0.5 rounded-full">Portal Banner</span>
                                <span class="text-xs bg-brand-50 text-brand-700 px-2 py-0.5 rounded-full">Barangay Personnel</span>
                            </div>
                        </div>
                        <div class="flex items-start gap-3">
                            <span class="text-xs text-slate-500 w-24 flex-shrink-0">Scheduled</span>
                            <span class="text-sm text-slate-700">Immediately upon publish</span>
                        </div>
                        <div class="flex items-start gap-3">
                            <span class="text-xs text-slate-500 w-24 flex-shrink-0">Issuing Office</span>
                            <span class="text-sm text-slate-700">MDRRMO Esperanza</span>
                        </div>
                        <div class="flex items-start gap-3">
                            <span class="text-xs text-slate-500 w-24 flex-shrink-0">Approving Officer</span>
                            <span class="text-sm text-slate-700">MDRRMO Head R. Salinas</span>
                        </div>
                    </div>
                </div>

                {{-- Critical warning --}}
                <div class="bg-amber-50 border border-amber-200 rounded-xl p-4 text-amber-700 text-sm flex items-start gap-2">
                    <i data-lucide="triangle-alert" class="w-4 h-4 flex-shrink-0 mt-0.5"></i>
                    <div>
                        <p class="font-semibold mb-1">Critical Municipality-Wide Alert</p>
                        <p class="text-xs leading-relaxed">This alert will be sent to all residents in the Municipality of Esperanza across 4 channels. This action cannot be undone without cancelling the alert.</p>
                    </div>
                </div>

                {{-- Action buttons --}}
                <div class="flex flex-col sm:flex-row gap-2 pt-2">
                    <button
                        @click="$dispatch('toast', { message: 'Alert saved as draft.', variant: 'info' }); showCreateAlert = false; alertComposerStep = 1"
                        class="flex-1 px-4 py-2.5 text-sm font-medium text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-xl transition-colors">
                        Save as Draft
                    </button>
                    <button
                        @click="$dispatch('toast', { message: 'Alert submitted for review by Information Officer.', variant: 'success' }); showCreateAlert = false; alertComposerStep = 1"
                        class="flex-1 px-4 py-2.5 text-sm font-medium text-brand-700 bg-brand-50 border border-brand-200 hover:bg-brand-100 rounded-xl transition-colors">
                        Submit for Review
                    </button>
                    <button
                        @click="$dispatch('toast', { message: 'Alert published to 4 channels. All target recipients are being notified.', variant: 'success' }); showCreateAlert = false; alertComposerStep = 1; $nextTick(() => window.renderIcons?.())"
                        class="flex-1 px-4 py-2.5 text-sm font-semibold text-white bg-brand-600 hover:bg-brand-700 rounded-xl transition-colors shadow-sm">
                        Publish Now
                    </button>
                </div>
            </div>
        </div>

        {{-- Step navigation footer --}}
        <div class="flex items-center justify-between mt-6 pt-4 border-t border-slate-100">
            <button
                @click="if (alertComposerStep > 1) { alertComposerStep--; $nextTick(() => window.renderIcons?.()); }"
                :disabled="alertComposerStep === 1"
                :class="alertComposerStep === 1 ? 'opacity-30 cursor-not-allowed' : 'hover:bg-slate-100'"
                class="flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-slate-600 rounded-xl transition-colors">
                <i data-lucide="chevron-left" class="w-4 h-4"></i>
                Back
            </button>
            <span class="text-xs text-slate-400" x-text="'Step ' + alertComposerStep + ' of 4'"></span>
            <button
                x-show="alertComposerStep < 4"
                @click="alertComposerStep++; $nextTick(() => window.renderIcons?.())"
                class="flex items-center gap-1.5 px-4 py-2 text-sm font-semibold text-white bg-brand-600 hover:bg-brand-700 rounded-xl transition-colors shadow-sm">
                Next
                <i data-lucide="chevron-right" class="w-4 h-4"></i>
            </button>
            <div x-show="alertComposerStep === 4" class="w-20"></div>
        </div>
    </div>
</div>
