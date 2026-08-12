@php
    $notifPrefs = [
        ['label' => 'New document requests', 'desc' => 'Notify when a citizen submits a new request.', 'checked' => true],
        ['label' => 'New assistance requests', 'desc' => 'Notify when a citizen applies for assistance.', 'checked' => true],
        ['label' => 'Overdue requests', 'desc' => 'Alert when requests exceed SLA processing time.', 'checked' => true],
        ['label' => 'Weekly summary report', 'desc' => 'Email digest of municipal service activity.', 'checked' => false],
    ];

    $palette = [
        ['name' => 'Brand Blue', 'hex' => '#2F62F5', 'class' => 'bg-brand-500'],
        ['name' => 'Navy', 'hex' => '#0B1730', 'class' => 'bg-navy-900'],
        ['name' => 'Gold', 'hex' => '#ECC02A', 'class' => 'bg-gold-400'],
        ['name' => 'Emerald', 'hex' => '#22C55E', 'class' => 'bg-emerald-500'],
    ];

    $logs = [
        ['user' => 'Juan Dela Cruz', 'action' => 'Approved document request DR-2026-2154', 'module' => 'Dokyu', 'time' => 'Jul 10, 2026 · 9:42 AM', 'ip' => '203.177.42.11'],
        ['user' => 'Corazon Villareal', 'action' => 'Published announcement "Free Medical & Dental Mission"', 'module' => 'Balita', 'time' => 'Jul 9, 2026 · 4:15 PM', 'ip' => '203.177.42.19'],
        ['user' => 'Paolo Reyes', 'action' => 'Created personnel account for Angeline Mercado', 'module' => 'User Management', 'time' => 'Jul 9, 2026 · 2:03 PM', 'ip' => '203.177.42.02'],
        ['user' => 'Bienvenido Salazar', 'action' => 'Released document request DR-2026-2187', 'module' => 'Dokyu', 'time' => 'Jul 8, 2026 · 11:27 AM', 'ip' => '203.177.42.33'],
        ['user' => 'Leilani Domingo', 'action' => 'Approved assistance request AR-2026-0142', 'module' => 'Tulong', 'time' => 'Jul 8, 2026 · 10:05 AM', 'ip' => '203.177.42.08'],
        ['user' => 'System', 'action' => 'Automated backup completed successfully', 'module' => 'System', 'time' => 'Jul 8, 2026 · 2:00 AM', 'ip' => 'internal'],
        ['user' => 'Juan Dela Cruz', 'action' => 'Updated municipality branding colors', 'module' => 'Branding', 'time' => 'Jul 7, 2026 · 3:41 PM', 'ip' => '203.177.42.11'],
        ['user' => 'Marivic Ong', 'action' => 'Rejected document request DR-2026-1655', 'module' => 'Dokyu', 'time' => 'Jul 6, 2026 · 1:18 PM', 'ip' => '203.177.42.27'],
    ];

    $tab = $tab ?? 'general';
@endphp

<x-layouts.admin title="Settings" subtitle="Platform preferences and configuration." active="settings">
    <div x-data="{ tab: '{{ $tab }}' }" class="animate-fade-up">

        <div x-show="!$store.session.can('settings')" x-cloak>
            <x-admin.access-restricted module="System Settings" icon="settings" />
        </div>

        <div x-show="$store.session.can('settings')" x-cloak class="grid grid-cols-1 lg:grid-cols-4 gap-4">

        <div class="lg:col-span-1">
            <x-ui.card padded="false" class="p-2">
                <nav class="space-y-0.5">
                    @foreach(['general' => ['building-2', 'General'], 'notifications' => ['bell', 'Notifications'], 'security' => ['shield', 'Security'], 'branding' => ['palette', 'Branding'], 'integrations' => ['plug', 'Integrations'], 'audit-logs' => ['scroll-text', 'Audit Logs']] as $key => [$icon, $label])
                        <button
                            @click="tab = '{{ $key }}'"
                            class="w-full flex items-center gap-2.5 px-3.5 py-2 rounded-xl text-sm font-medium transition-colors"
                            :class="tab === '{{ $key }}' ? 'bg-brand-50 text-brand-700' : 'text-slate-500 hover:bg-slate-50'"
                        >
                            <i data-lucide="{{ $icon }}" class="w-4 h-4"></i>{{ $label }}
                        </button>
                    @endforeach
                </nav>
            </x-ui.card>
        </div>

        <div class="lg:col-span-3">
            <div x-show="tab === 'general'">
                <x-ui.card>
                    <h3 class="text-sm font-semibold text-navy-900 mb-4">General Settings</h3>
                    <div class="space-y-4 max-w-lg">
                        <x-ui.input name="municipality" label="Municipality Name" value="Esperanza" />
                        <div class="grid grid-cols-2 gap-4">
                            <x-ui.input name="province" label="Province" value="Masbate" />
                            <x-ui.input name="region" label="Region" value="Region V (Bicol Region)" />
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-slate-700 mb-1.5">Default Language</label>
                            <select class="w-full rounded-xl border border-slate-200 bg-slate-50/60 py-2.5 px-4 text-sm text-slate-700 focus:bg-white focus:border-brand-400 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200">
                                <option>English</option>
                                <option>Filipino</option>
                            </select>
                        </div>
                        <x-ui.button icon="check" @click="$dispatch('toast', { message: 'Settings saved.', variant: 'success' })">Save Changes</x-ui.button>
                    </div>
                </x-ui.card>
            </div>

            <div x-show="tab === 'notifications'" x-cloak>
                <x-ui.card>
                    <h3 class="text-sm font-semibold text-navy-900 mb-1">Notification Settings</h3>
                    <p class="text-xs text-slate-400 mb-4">Choose which system events trigger notifications for administrators.</p>
                    <div class="divide-y divide-slate-50">
                        @foreach($notifPrefs as $pref)
                            <label class="flex items-center justify-between gap-4 py-2.5 cursor-pointer">
                                <div class="min-w-0">
                                    <p class="text-sm font-medium text-slate-700">{{ $pref['label'] }}</p>
                                    <p class="text-xs text-slate-400 mt-0.5">{{ $pref['desc'] }}</p>
                                </div>
                                <div class="relative shrink-0" x-data="{ on: {{ $pref['checked'] ? 'true' : 'false' }} }">
                                    <button
                                        @click="on = !on"
                                        type="button"
                                        class="w-10 h-6 rounded-full transition-colors duration-200 relative"
                                        :class="on ? 'bg-brand-600' : 'bg-slate-200'"
                                    >
                                        <span class="absolute top-0.5 left-0.5 w-5 h-5 rounded-full bg-white shadow transition-transform duration-200" :class="on && 'translate-x-4'"></span>
                                    </button>
                                </div>
                            </label>
                        @endforeach
                    </div>
                </x-ui.card>
            </div>

            <div x-show="tab === 'security'" x-cloak class="space-y-4">
                <x-ui.card class="flex items-center justify-between gap-4">
                    <div>
                        <p class="text-sm font-medium text-navy-900">Two-Factor Authentication</p>
                        <p class="text-xs text-slate-400 mt-0.5">Require 2FA for all personnel accounts.</p>
                    </div>
                    <x-ui.button variant="secondary" size="sm">Enforce for All</x-ui.button>
                </x-ui.card>
                <x-ui.card class="flex items-center justify-between gap-4">
                    <div>
                        <p class="text-sm font-medium text-navy-900">Session Timeout</p>
                        <p class="text-xs text-slate-400 mt-0.5">Automatically sign out inactive sessions.</p>
                    </div>
                    <select class="text-sm rounded-xl border border-slate-200 bg-white py-2 px-3 shadow-card focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200">
                        <option>15 minutes</option>
                        <option selected>30 minutes</option>
                        <option>1 hour</option>
                    </select>
                </x-ui.card>
            </div>

            <div x-show="tab === 'branding'" x-cloak class="space-y-4">
                <x-ui.card>
                    <h3 class="text-sm font-semibold text-navy-900 mb-4">Municipal Seal</h3>
                    <div class="flex items-center gap-5">
                        <img src="{{ asset('images/esperanza/esperanza-seal.png') }}" alt="Municipal Seal" class="w-20 h-20 rounded-full ring-4 ring-slate-100 object-cover">
                        <div>
                            <p class="text-sm text-slate-600">esperanza-seal.png</p>
                            <p class="text-xs text-slate-400 mt-0.5">512×512px · PNG · Used across both portals</p>
                            <x-ui.button variant="secondary" size="sm" icon="upload" class="mt-2.5">Replace Seal</x-ui.button>
                        </div>
                    </div>
                </x-ui.card>

                <x-ui.card>
                    <h3 class="text-sm font-semibold text-navy-900 mb-4">Brand Colors</h3>
                    <div class="grid grid-cols-2 sm:grid-cols-4 gap-3.5">
                        @foreach($palette as $color)
                            <div class="rounded-xl border border-slate-100 overflow-hidden">
                                <div class="h-16 {{ $color['class'] }}"></div>
                                <div class="p-2.5">
                                    <p class="text-xs font-medium text-slate-700">{{ $color['name'] }}</p>
                                    <p class="text-[11px] text-slate-400 font-mono">{{ $color['hex'] }}</p>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </x-ui.card>

                <x-ui.card class="flex items-center justify-between gap-4">
                    <div>
                        <p class="text-sm font-medium text-navy-900">Municipality Information</p>
                        <p class="text-xs text-slate-400 mt-0.5">{{ config('esperanza.municipality') }}, {{ config('esperanza.province') }} · {{ config('esperanza.region') }} · {{ count(config('esperanza.barangays')) }} barangays</p>
                    </div>
                    <x-ui.button variant="secondary" size="sm" icon="pencil">Edit Information</x-ui.button>
                </x-ui.card>
            </div>

            <div x-show="tab === 'integrations'" x-cloak>
                <x-ui.card>
                    <h3 class="text-sm font-semibold text-navy-900 mb-4">Connected Services</h3>
                    <div class="space-y-2.5">
                        @foreach([['name' => 'GCash Payment Gateway', 'icon' => 'credit-card', 'status' => 'Approved'], ['name' => 'SMS Gateway (Semaphore)', 'icon' => 'message-square', 'status' => 'Approved'], ['name' => 'PhilSys Verification API', 'icon' => 'badge-check', 'status' => 'Draft']] as $svc)
                            <div class="flex items-center justify-between gap-4 rounded-xl border border-slate-100 p-3">
                                <div class="flex items-center gap-3">
                                    <span class="w-8 h-8 rounded-lg bg-slate-100 text-slate-500 flex items-center justify-center shrink-0"><i data-lucide="{{ $svc['icon'] }}" class="w-4 h-4"></i></span>
                                    <p class="text-sm font-medium text-slate-700">{{ $svc['name'] }}</p>
                                </div>
                                <x-ui.badge :status="$svc['status']" />
                            </div>
                        @endforeach
                    </div>
                </x-ui.card>
            </div>

            <div x-show="tab === 'audit-logs'" x-cloak>
                <div class="flex flex-wrap items-center justify-between gap-3 mb-3">
                    <div class="relative">
                        <i data-lucide="search" class="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none"></i>
                        <input type="text" placeholder="Search actions or personnel..." class="w-64 pl-10 pr-4 py-2 text-sm rounded-xl bg-white border border-slate-200 focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200 shadow-card">
                    </div>
                    <select class="text-sm rounded-xl border border-slate-200 bg-white py-2 px-3.5 shadow-card focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200">
                        <option>All Modules</option>
                        <option>Dokyu</option>
                        <option>Tulong</option>
                        <option>Balita</option>
                        <option>User Management</option>
                        <option>System</option>
                    </select>
                </div>

                <x-ui.table>
                    <thead>
                        <tr class="border-b border-slate-100 bg-slate-50/60">
                            <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400">Personnel</th>
                            <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400">Action</th>
                            <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden md:table-cell">Module</th>
                            <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden sm:table-cell">Timestamp</th>
                            <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden lg:table-cell">IP Address</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-50">
                        @foreach($logs as $log)
                            <tr class="hover:bg-slate-50/70 transition-colors">
                                <td class="px-4 py-2.5 text-slate-700 font-medium whitespace-nowrap">{{ $log['user'] }}</td>
                                <td class="px-4 py-2.5 text-slate-600">{{ $log['action'] }}</td>
                                <td class="px-4 py-2.5 hidden md:table-cell"><span class="text-[11px] font-medium text-slate-500 bg-slate-100 px-2 py-0.5 rounded-md">{{ $log['module'] }}</span></td>
                                <td class="px-4 py-2.5 text-slate-500 hidden sm:table-cell whitespace-nowrap">{{ $log['time'] }}</td>
                                <td class="px-4 py-2.5 text-slate-400 hidden lg:table-cell font-mono text-xs">{{ $log['ip'] }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </x-ui.table>
            </div>
        </div>

        </div>
    </div>
</x-layouts.admin>
