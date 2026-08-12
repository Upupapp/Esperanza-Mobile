{{-- Relief & Logistics Tab --}}
<div class="space-y-6">

    {{-- Header --}}
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
            <h2 class="text-xl font-bold text-navy-900">Relief & Logistics</h2>
            <p class="text-sm text-slate-500 mt-0.5">Inventory management, relief requests, distributions, and donation tracking.</p>
        </div>
        <button
            onclick="window.toast?.('Relief logistics report exported.', 'success')"
            class="inline-flex items-center gap-2 px-4 py-2 bg-white border border-slate-200 rounded-xl text-sm font-medium text-slate-700 hover:bg-slate-50 transition-colors shadow-sm self-start sm:self-auto">
            <i data-lucide="download" class="w-4 h-4"></i>
            Export
        </button>
    </div>

    {{-- Subtab Navigation --}}
    <div class="flex flex-wrap gap-2">
        @foreach([['inventory','Inventory'],['requests','Requests'],['releases','Releases'],['distribution','Distribution'],['donations','Donations']] as [$key,$label])
        <button
            @click="reliefSubtab = '{{ $key }}'"
            :class="reliefSubtab === '{{ $key }}'
                ? 'bg-brand-blue text-white shadow-sm'
                : 'bg-white border border-slate-200 text-slate-600 hover:bg-slate-50'"
            class="px-4 py-2 rounded-full text-sm font-medium transition-all">
            {{ $label }}
        </button>
        @endforeach
    </div>

    {{-- ================================================================ --}}
    {{-- SUBTAB: Inventory --}}
    {{-- ================================================================ --}}
    <div x-show="reliefSubtab === 'inventory'" x-cloak class="space-y-4">

        {{-- Summary Pills --}}
        <div class="flex flex-wrap gap-3">
            <div class="flex items-center gap-2 px-4 py-2 bg-white rounded-xl border border-slate-100 shadow-card text-sm">
                <i data-lucide="package" class="w-4 h-4 text-slate-400"></i>
                <span class="text-slate-500">Total Item Types:</span>
                <span class="font-bold text-slate-800">15</span>
            </div>
            <div class="flex items-center gap-2 px-4 py-2 bg-amber-50 rounded-xl border border-amber-100 shadow-card text-sm">
                <i data-lucide="triangle-alert" class="w-4 h-4 text-amber-500"></i>
                <span class="text-amber-700">Low Stock Items:</span>
                <span class="font-bold text-amber-800">4</span>
            </div>
            <div class="flex items-center gap-2 px-4 py-2 bg-rose-50 rounded-xl border border-rose-100 shadow-card text-sm">
                <i data-lucide="calendar-x" class="w-4 h-4 text-rose-500"></i>
                <span class="text-rose-700">Expiring Soon (≤30 days):</span>
                <span class="font-bold text-rose-800">1</span>
            </div>
            <div class="flex items-center gap-2 px-4 py-2 bg-white rounded-xl border border-slate-100 shadow-card text-sm">
                <i data-lucide="lock" class="w-4 h-4 text-slate-400"></i>
                <span class="text-slate-500">Total Reserved:</span>
                @php $totalReserved = collect($inventory)->sum('reserved'); @endphp
                <span class="font-bold text-slate-800">{{ number_format($totalReserved) }}</span>
            </div>
        </div>

        {{-- Filter Bar --}}
        <div class="flex flex-wrap gap-3 items-center">
            <div class="relative flex-1 min-w-[200px]">
                <i data-lucide="search" class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"></i>
                <input
                    type="text"
                    x-model="inventorySearch"
                    placeholder="Search by name or code…"
                    class="w-full pl-9 pr-4 py-2 rounded-xl border border-slate-200 text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand-blue/30 focus:border-brand-blue bg-white">
            </div>
            <select
                x-model="inventoryCategoryFilter"
                class="px-3 py-2 rounded-xl border border-slate-200 text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
                <option value="">All Categories</option>
                <option value="Food">Food</option>
                <option value="Water">Water</option>
                <option value="Non-Food">Non-Food</option>
                <option value="Medicine">Medicine</option>
                <option value="Baby Supplies">Baby Supplies</option>
                <option value="PPE">PPE</option>
                <option value="Fuel">Fuel</option>
                <option value="Medical">Medical</option>
            </select>
            <button
                @click="showStockInModal = true; selectedInventoryItem = null"
                class="inline-flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-xl text-sm font-medium hover:bg-emerald-700 transition-colors shadow-sm">
                <i data-lucide="circle-plus" class="w-4 h-4"></i>
                Stock In
            </button>
            <button
                @click="showStockOutModal = true; selectedInventoryItem = null"
                class="inline-flex items-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-xl text-sm font-medium hover:bg-orange-600 transition-colors shadow-sm">
                <i data-lucide="circle-minus" class="w-4 h-4"></i>
                Stock Out
            </button>
        </div>

        {{-- Inventory Table --}}
        <div class="bg-white rounded-2xl shadow-card border border-slate-100 overflow-hidden">
            <div class="overflow-x-auto">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="bg-slate-50 border-b border-slate-100">
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Code</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Item Name</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Category</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Unit</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Available</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Reserved</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Reorder Lvl</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Storage</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Expiry</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Condition</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Source</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-50">
                        @foreach($inventory as $item)
                        @php
                            $isLowStock = $item['available'] <= $item['reorder'];
                            $isExpiringSoon = isset($item['expiry']) && $item['code'] === 'INV-013';
                        @endphp
                        <tr
                            x-show="(inventorySearch === '' || '{{ strtolower($item['name']) }}'.includes(inventorySearch.toLowerCase()) || '{{ strtolower($item['code']) }}'.includes(inventorySearch.toLowerCase())) && (inventoryCategoryFilter === '' || '{{ $item['category'] }}' === inventoryCategoryFilter)"
                            class="{{ $isLowStock ? 'bg-amber-50' : 'bg-white hover:bg-slate-50' }} transition-colors">
                            <td class="px-4 py-3">
                                <span class="font-mono text-xs text-slate-500 bg-slate-100 px-2 py-0.5 rounded">{{ $item['code'] }}</span>
                            </td>
                            <td class="px-4 py-3">
                                <span class="font-medium text-slate-800">{{ $item['name'] }}</span>
                            </td>
                            <td class="px-4 py-3">
                                <span class="text-slate-600">{{ $item['category'] }}</span>
                            </td>
                            <td class="px-4 py-3 text-slate-600">{{ $item['unit'] }}</td>
                            <td class="px-4 py-3">
                                <span class="{{ $isLowStock ? 'text-rose-600 font-bold' : 'text-slate-700 font-medium' }}">
                                    {{ number_format($item['available']) }} {{ $item['unit'] }}
                                </span>
                                @if($isLowStock)
                                    <span class="ml-1.5 px-1.5 py-0.5 bg-amber-100 text-amber-700 rounded text-xs font-medium">Low Stock</span>
                                @endif
                            </td>
                            <td class="px-4 py-3 text-slate-600">{{ number_format($item['reserved']) }} {{ $item['unit'] }}</td>
                            <td class="px-4 py-3 text-slate-600">{{ number_format($item['reorder']) }}</td>
                            <td class="px-4 py-3 text-slate-600 text-xs">{{ $item['location'] ?? '—' }}</td>
                            <td class="px-4 py-3">
                                @if(isset($item['expiry']) && $item['expiry'])
                                    <span class="{{ $isExpiringSoon ? 'text-rose-600 font-semibold' : 'text-slate-600' }} text-xs">
                                        {{ $item['expiry'] }}
                                    </span>
                                    @if($isExpiringSoon)
                                        <span class="ml-1 px-1.5 py-0.5 bg-rose-100 text-rose-700 rounded text-xs font-medium whitespace-nowrap">Expiring Soon</span>
                                    @endif
                                @else
                                    <span class="text-slate-400 text-xs">N/A</span>
                                @endif
                            </td>
                            <td class="px-4 py-3">
                                @php
                                    $condColor = match($item['condition'] ?? 'Good') {
                                        'Good' => 'bg-emerald-100 text-emerald-700',
                                        'Fair' => 'bg-amber-100 text-amber-700',
                                        'Poor' => 'bg-rose-100 text-rose-700',
                                        default => 'bg-slate-100 text-slate-600',
                                    };
                                @endphp
                                <span class="px-2 py-0.5 rounded-full text-xs font-medium {{ $condColor }}">{{ $item['condition'] ?? 'Good' }}</span>
                            </td>
                            <td class="px-4 py-3 text-xs text-slate-500">{{ $item['source'] ?? '—' }}</td>
                            <td class="px-4 py-3">
                                <div class="flex items-center gap-1">
                                    <button
                                        @click="selectedInventoryItem = {{ json_encode($item) }}; showStockInModal = true"
                                        class="p-1.5 text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors" title="Stock In">
                                        <i data-lucide="circle-plus" class="w-3.5 h-3.5"></i>
                                    </button>
                                    <button
                                        @click="selectedInventoryItem = {{ json_encode($item) }}; showStockOutModal = true"
                                        class="p-1.5 text-orange-500 hover:bg-orange-50 rounded-lg transition-colors" title="Stock Out">
                                        <i data-lucide="circle-minus" class="w-3.5 h-3.5"></i>
                                    </button>
                                    <button
                                        @click="$dispatch('toast', { message: 'Movement history for {{ $item['name'] }}.', variant: 'info' })"
                                        class="p-1.5 text-slate-500 hover:bg-slate-100 rounded-lg transition-colors" title="View History">
                                        <i data-lucide="history" class="w-3.5 h-3.5"></i>
                                    </button>
                                    <button
                                        @click="$dispatch('toast', { message: 'Items reserved from {{ $item['name'] }}.', variant: 'success' })"
                                        class="p-1.5 text-brand-blue hover:bg-blue-50 rounded-lg transition-colors" title="Reserve">
                                        <i data-lucide="lock" class="w-3.5 h-3.5"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    {{-- ================================================================ --}}
    {{-- SUBTAB: Requests --}}
    {{-- ================================================================ --}}
    <div x-show="reliefSubtab === 'requests'" x-cloak class="space-y-4">
        <div class="flex items-center justify-between">
            <h3 class="text-base font-semibold text-navy-900">Relief Requests</h3>
            <button
                @click="showRequestModal = true"
                class="inline-flex items-center gap-2 px-4 py-2 bg-brand-blue text-white rounded-xl text-sm font-medium hover:bg-brand-blue/90 transition-colors shadow-sm">
                <i data-lucide="plus" class="w-4 h-4"></i>
                Create Request
            </button>
        </div>

        {{-- Request Cards Grid --}}
        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">

            {{-- REQ-001 --}}
            <div class="bg-white rounded-2xl shadow-card border border-slate-100 p-5 flex flex-col gap-3">
                <div class="flex items-start justify-between gap-2">
                    <div>
                        <span class="font-mono text-xs text-slate-400">REQ-001</span>
                        <h4 class="font-semibold text-slate-800 text-sm mt-0.5">Masbaranon Elementary School</h4>
                    </div>
                    <div class="flex flex-col items-end gap-1">
                        <span class="px-2 py-0.5 bg-violet-100 text-violet-700 rounded-full text-xs font-medium">For Approval</span>
                        <span class="px-2 py-0.5 bg-rose-100 text-rose-700 rounded-full text-xs font-medium">Urgent</span>
                    </div>
                </div>
                <ul class="text-xs text-slate-600 space-y-1">
                    <li class="flex items-center gap-1.5"><i data-lucide="package" class="w-3 h-3 text-slate-400"></i>30 Family Food Packs</li>
                    <li class="flex items-center gap-1.5"><i data-lucide="droplet" class="w-3 h-3 text-slate-400"></i>60 Bottled Water (1.5L)</li>
                </ul>
                <div class="flex items-center gap-1.5 text-xs text-slate-500">
                    <i data-lucide="users" class="w-3.5 h-3.5 text-slate-400"></i>
                    120 beneficiaries
                </div>
                <div class="flex items-center justify-between pt-2 border-t border-slate-50 mt-auto">
                    <div class="text-xs text-slate-400">Relief Officer Reyes · Jul 15, 2026</div>
                    <button
                        @click="$dispatch('toast', { message: 'REQ-001 approved and queued for preparation.', variant: 'success' })"
                        class="px-3 py-1.5 bg-violet-600 text-white rounded-lg text-xs font-medium hover:bg-violet-700 transition-colors">
                        Approve
                    </button>
                </div>
            </div>

            {{-- REQ-002 --}}
            <div class="bg-white rounded-2xl shadow-card border border-slate-100 p-5 flex flex-col gap-3">
                <div class="flex items-start justify-between gap-2">
                    <div>
                        <span class="font-mono text-xs text-slate-400">REQ-002</span>
                        <h4 class="font-semibold text-slate-800 text-sm mt-0.5">Baras Barangay Hall</h4>
                    </div>
                    <div class="flex flex-col items-end gap-1">
                        <span class="px-2 py-0.5 bg-emerald-100 text-emerald-700 rounded-full text-xs font-medium">Approved</span>
                        <span class="px-2 py-0.5 bg-slate-100 text-slate-600 rounded-full text-xs font-medium">Normal</span>
                    </div>
                </div>
                <ul class="text-xs text-slate-600 space-y-1">
                    <li class="flex items-center gap-1.5"><i data-lucide="package" class="w-3 h-3 text-slate-400"></i>20 Hygiene Kits</li>
                    <li class="flex items-center gap-1.5"><i data-lucide="bed" class="w-3 h-3 text-slate-400"></i>10 Sleeping Mats</li>
                </ul>
                <div class="flex items-center gap-1.5 text-xs text-slate-500">
                    <i data-lucide="users" class="w-3.5 h-3.5 text-slate-400"></i>
                    45 beneficiaries
                </div>
                <div class="flex items-center justify-between pt-2 border-t border-slate-50 mt-auto">
                    <div class="text-xs text-slate-400">Relief Officer Cruz · Jul 15, 2026</div>
                    <button
                        @click="$dispatch('toast', { message: 'REQ-002 marked as preparing.', variant: 'success' })"
                        class="px-3 py-1.5 bg-emerald-600 text-white rounded-lg text-xs font-medium hover:bg-emerald-700 transition-colors">
                        Prepare Release
                    </button>
                </div>
            </div>

            {{-- REQ-003 --}}
            <div class="bg-white rounded-2xl shadow-card border border-slate-100 p-5 flex flex-col gap-3">
                <div class="flex items-start justify-between gap-2">
                    <div>
                        <span class="font-mono text-xs text-slate-400">REQ-003</span>
                        <h4 class="font-semibold text-slate-800 text-sm mt-0.5">Domorog MPH</h4>
                    </div>
                    <div class="flex flex-col items-end gap-1">
                        <span class="px-2 py-0.5 bg-amber-100 text-amber-700 rounded-full text-xs font-medium">Preparing</span>
                        <span class="px-2 py-0.5 bg-slate-100 text-slate-600 rounded-full text-xs font-medium">Normal</span>
                    </div>
                </div>
                <ul class="text-xs text-slate-600 space-y-1">
                    <li class="flex items-center gap-1.5"><i data-lucide="package" class="w-3 h-3 text-slate-400"></i>15 Family Food Packs</li>
                    <li class="flex items-center gap-1.5"><i data-lucide="droplet" class="w-3 h-3 text-slate-400"></i>30 Bottled Water (1.5L)</li>
                </ul>
                <div class="flex items-center gap-1.5 text-xs text-slate-500">
                    <i data-lucide="users" class="w-3.5 h-3.5 text-slate-400"></i>
                    38 beneficiaries
                </div>
                <div class="flex items-center justify-between pt-2 border-t border-slate-50 mt-auto">
                    <div class="text-xs text-slate-400">Relief Officer Bato · Jul 15, 2026</div>
                    <button
                        @click="$dispatch('toast', { message: 'REQ-003 marked as in transit.', variant: 'success' })"
                        class="px-3 py-1.5 bg-orange-500 text-white rounded-lg text-xs font-medium hover:bg-orange-600 transition-colors">
                        Mark In Transit
                    </button>
                </div>
            </div>

            {{-- REQ-004 --}}
            <div class="bg-white rounded-2xl shadow-card border border-slate-100 p-5 flex flex-col gap-3">
                <div class="flex items-start justify-between gap-2">
                    <div>
                        <span class="font-mono text-xs text-slate-400">REQ-004</span>
                        <h4 class="font-semibold text-slate-800 text-sm mt-0.5">Magsaysay Barangay Hall</h4>
                    </div>
                    <div class="flex flex-col items-end gap-1">
                        <span class="px-2 py-0.5 bg-teal-100 text-teal-700 rounded-full text-xs font-medium">Delivered</span>
                        <span class="px-2 py-0.5 bg-rose-100 text-rose-700 rounded-full text-xs font-medium">High</span>
                    </div>
                </div>
                <ul class="text-xs text-slate-600 space-y-1">
                    <li class="flex items-center gap-1.5"><i data-lucide="baby" class="w-3 h-3 text-slate-400"></i>10 Baby Diapers packs</li>
                    <li class="flex items-center gap-1.5"><i data-lucide="heart-pulse" class="w-3 h-3 text-slate-400"></i>5 ORS sachets</li>
                </ul>
                <div class="flex items-center gap-1.5 text-xs text-slate-500">
                    <i data-lucide="users" class="w-3.5 h-3.5 text-slate-400"></i>
                    18 beneficiaries
                </div>
                <div class="flex items-center justify-between pt-2 border-t border-slate-50 mt-auto">
                    <div class="text-xs text-slate-400">Relief Officer Villanueva · Jul 14, 2026</div>
                    <button
                        @click="$dispatch('toast', { message: 'REQ-004 marked as received.', variant: 'success' })"
                        class="px-3 py-1.5 bg-teal-600 text-white rounded-lg text-xs font-medium hover:bg-teal-700 transition-colors">
                        Mark Received
                    </button>
                </div>
            </div>

            {{-- REQ-005 --}}
            <div class="bg-white rounded-2xl shadow-card border border-slate-100 p-5 flex flex-col gap-3">
                <div class="flex items-start justify-between gap-2">
                    <div>
                        <span class="font-mono text-xs text-slate-400">REQ-005</span>
                        <h4 class="font-semibold text-slate-800 text-sm mt-0.5">Municipal Gymnasium</h4>
                    </div>
                    <div class="flex flex-col items-end gap-1">
                        <span class="px-2 py-0.5 bg-purple-100 text-purple-700 rounded-full text-xs font-medium">Distributing</span>
                        <span class="px-2 py-0.5 bg-rose-100 text-rose-700 rounded-full text-xs font-medium">Urgent</span>
                    </div>
                </div>
                <ul class="text-xs text-slate-600 space-y-1">
                    <li class="flex items-center gap-1.5"><i data-lucide="package" class="w-3 h-3 text-slate-400"></i>100 Family Food Packs</li>
                    <li class="flex items-center gap-1.5"><i data-lucide="droplet" class="w-3 h-3 text-slate-400"></i>200 Bottled Water (1.5L)</li>
                    <li class="flex items-center gap-1.5"><i data-lucide="sparkles" class="w-3 h-3 text-slate-400"></i>50 Hygiene Kits</li>
                </ul>
                <div class="flex items-center gap-1.5 text-xs text-slate-500">
                    <i data-lucide="users" class="w-3.5 h-3.5 text-slate-400"></i>
                    312 beneficiaries
                </div>
                <div class="flex items-center justify-between pt-2 border-t border-slate-50 mt-auto">
                    <div class="text-xs text-slate-400">Relief Officer Santos · Jul 15, 2026</div>
                    <span class="px-3 py-1.5 bg-purple-50 text-purple-600 rounded-lg text-xs font-medium border border-purple-100">Active Distribution</span>
                </div>
            </div>

            {{-- REQ-006 --}}
            <div class="bg-white rounded-2xl shadow-card border border-slate-100 p-5 flex flex-col gap-3">
                <div class="flex items-start justify-between gap-2">
                    <div>
                        <span class="font-mono text-xs text-slate-400">REQ-006</span>
                        <h4 class="font-semibold text-slate-800 text-sm mt-0.5">Santiago (Incoming Request)</h4>
                    </div>
                    <div class="flex flex-col items-end gap-1">
                        <span class="px-2 py-0.5 bg-indigo-100 text-indigo-700 rounded-full text-xs font-medium">For Validation</span>
                        <span class="px-2 py-0.5 bg-rose-100 text-rose-700 rounded-full text-xs font-medium">High</span>
                    </div>
                </div>
                <ul class="text-xs text-slate-600 space-y-1">
                    <li class="flex items-center gap-1.5"><i data-lucide="package" class="w-3 h-3 text-slate-400"></i>25 Family Food Packs</li>
                </ul>
                <div class="flex items-center gap-1.5 text-xs text-slate-500">
                    <i data-lucide="users" class="w-3.5 h-3.5 text-slate-400"></i>
                    60 beneficiaries
                </div>
                <div class="flex items-center justify-between pt-2 border-t border-slate-50 mt-auto">
                    <div class="text-xs text-slate-400">Brgy. Captain Dizon · Jul 15, 2026</div>
                    <button
                        @click="$dispatch('toast', { message: 'REQ-006 validated and queued for approval.', variant: 'success' })"
                        class="px-3 py-1.5 bg-indigo-600 text-white rounded-lg text-xs font-medium hover:bg-indigo-700 transition-colors">
                        Validate
                    </button>
                </div>
            </div>

        </div>
    </div>

    {{-- ================================================================ --}}
    {{-- SUBTAB: Releases --}}
    {{-- ================================================================ --}}
    <div x-show="reliefSubtab === 'releases'" x-cloak class="space-y-4">
        <div class="flex items-center justify-between">
            <h3 class="text-base font-semibold text-navy-900">Relief Releases</h3>
            <button
                @click="$dispatch('toast', { message: 'Releases report exported.', variant: 'success' })"
                class="inline-flex items-center gap-2 px-3 py-2 bg-white border border-slate-200 rounded-xl text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors">
                <i data-lucide="download" class="w-4 h-4"></i>
                Export
            </button>
        </div>
        <div class="bg-white rounded-2xl shadow-card border border-slate-100 overflow-hidden">
            <div class="overflow-x-auto">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="bg-slate-50 border-b border-slate-100">
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Release ID</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Date</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Destination</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Items Released</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Qty</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Beneficiaries</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Released By</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Status</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-50">
                        @foreach([
                            ['REL-001', 'Jul 15, 2026', 'Magsaysay Barangay Hall', 'Family Food Packs, Bottled Water', '28 packs / 56 bottles', '28 families', 'Relief Officer Ramos', 'Delivered', 'teal'],
                            ['REL-002', 'Jul 15, 2026', 'Baras Barangay Hall', 'Hygiene Kits, Sleeping Mats', '22 kits / 22 mats', '22 families', 'Relief Officer Ramos', 'Received', 'emerald'],
                            ['REL-003', 'Jul 15, 2026', 'Municipal Gymnasium', 'Family Food Packs, Hygiene Kits, Water', '84 packs / 84 kits', '84 families', 'Relief Officer Santos', 'Distributing', 'purple'],
                            ['REL-004', 'Jul 15, 2026', 'Domorog MPH', 'Family Food Packs', '19 packs', '19 families', 'Relief Officer Ramos', 'In Transit', 'orange'],
                        ] as [$id, $date, $dest, $items, $qty, $bene, $by, $status, $color])
                        <tr class="hover:bg-slate-50 transition-colors">
                            <td class="px-4 py-3"><span class="font-mono text-xs text-slate-500 bg-slate-100 px-2 py-0.5 rounded">{{ $id }}</span></td>
                            <td class="px-4 py-3 text-slate-600 text-xs whitespace-nowrap">{{ $date }}</td>
                            <td class="px-4 py-3 font-medium text-slate-800">{{ $dest }}</td>
                            <td class="px-4 py-3 text-slate-600 text-xs">{{ $items }}</td>
                            <td class="px-4 py-3 text-slate-600 text-xs whitespace-nowrap">{{ $qty }}</td>
                            <td class="px-4 py-3 text-slate-600 text-xs">{{ $bene }}</td>
                            <td class="px-4 py-3 text-xs text-slate-500">{{ $by }}</td>
                            <td class="px-4 py-3">
                                @php
                                    $statusClass = match($color) {
                                        'teal' => 'bg-teal-100 text-teal-700',
                                        'emerald' => 'bg-emerald-100 text-emerald-700',
                                        'purple' => 'bg-purple-100 text-purple-700',
                                        'orange' => 'bg-orange-100 text-orange-700',
                                        default => 'bg-slate-100 text-slate-600',
                                    };
                                @endphp
                                <span class="px-2 py-0.5 rounded-full text-xs font-medium {{ $statusClass }}">{{ $status }}</span>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    {{-- ================================================================ --}}
    {{-- SUBTAB: Distribution --}}
    {{-- ================================================================ --}}
    <div x-show="reliefSubtab === 'distribution'" x-cloak
         x-data="{ showDistModal: false, distHouseholdSearch: '', distPackageType: '', isDuplicate: false, supervisorConfirmed: false }"
         class="space-y-4">

        <div class="flex items-center justify-between">
            <h3 class="text-base font-semibold text-navy-900">Beneficiary Distribution</h3>
            <button
                @click="showDistModal = true; distHouseholdSearch = ''; distPackageType = ''; isDuplicate = false; supervisorConfirmed = false"
                class="inline-flex items-center gap-2 px-4 py-2 bg-brand-blue text-white rounded-xl text-sm font-medium hover:bg-brand-blue/90 transition-colors shadow-sm">
                <i data-lucide="plus" class="w-4 h-4"></i>
                Record Distribution
            </button>
        </div>

        {{-- Duplicate Warning Banner --}}
        <div class="bg-amber-50 border border-amber-200 rounded-xl p-3 flex items-center gap-2 text-amber-700 text-sm">
            <i data-lucide="triangle-alert" class="w-4 h-4 flex-shrink-0"></i>
            Duplicate assistance warnings are active for the current operational period (SWM-2026-07).
        </div>

        {{-- Distribution Table --}}
        <div class="bg-white rounded-2xl shadow-card border border-slate-100 overflow-hidden">
            <div class="overflow-x-auto">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="bg-slate-50 border-b border-slate-100">
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Dist. ID</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Barangay</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Center</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Household Head</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Size</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Package</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Date</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Officer</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Verification</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Status</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-50">
                        @foreach([
                            ['DIST-001','Masbaranon','EC-002','Rodrigo Panganiban',5,'Family Food Pack','Jul 15','Juan Dela Cruz','QR Scan','Completed'],
                            ['DIST-002','Masbaranon','EC-002','Nenita Cruz',4,'Family Food Pack','Jul 15','Juan Dela Cruz','Manual','Completed'],
                            ['DIST-003','Baras','EC-003','Rosario Dela Cruz',3,'Family Food Pack','Jul 15','Maria Santos','ID Scan','Completed'],
                            ['DIST-004','Domorog','EC-004','Eduardo Santos',6,'Family Food Pack','Jul 15','Pedro Garcia','Manual','Completed'],
                            ['DIST-005','Magsaysay','EC-005','Margarita Flores',4,'Family Food Pack','Jul 14','Linda Razon','QR Scan','Completed'],
                            ['DIST-006','Poblacion','EC-006','Antonio Mendez',8,'Family Food Pack + Hygiene Kit','Jul 15','Rodrigo Castillo','QR Scan','Completed'],
                            ['DIST-007','Poblacion','EC-006','Felisa Bautista',5,'Family Food Pack + Hygiene Kit','Jul 15','Rodrigo Castillo','ID Scan','Completed'],
                            ['DIST-008','Iligan','EC-007','Hernando Alcala',3,'Family Food Pack','Jul 15','Priscilla Buena','Manual','Completed'],
                            ['DIST-009','Masbaranon','EC-002','Consuelo Ramos',6,'Family Food Pack','Jul 15','Juan Dela Cruz','QR Scan','Completed'],
                            ['DIST-010','Baras','EC-003','Gerardo Umali',4,'Family Food Pack','Jul 15','Maria Santos','Manual','Completed'],
                        ] as [$id,$brgy,$center,$head,$size,$pkg,$date,$officer,$verify,$status])
                        <tr class="hover:bg-slate-50 transition-colors">
                            <td class="px-4 py-3"><span class="font-mono text-xs text-slate-500 bg-slate-100 px-2 py-0.5 rounded">{{ $id }}</span></td>
                            <td class="px-4 py-3 text-slate-700 text-xs">{{ $brgy }}</td>
                            <td class="px-4 py-3 text-slate-600 text-xs">{{ $center }}</td>
                            <td class="px-4 py-3 font-medium text-slate-800">{{ $head }}</td>
                            <td class="px-4 py-3 text-center text-slate-600">{{ $size }}</td>
                            <td class="px-4 py-3 text-slate-600 text-xs">{{ $pkg }}</td>
                            <td class="px-4 py-3 text-slate-600 text-xs whitespace-nowrap">{{ $date }}</td>
                            <td class="px-4 py-3 text-xs text-slate-500">{{ $officer }}</td>
                            <td class="px-4 py-3">
                                @php
                                    $vColor = match($verify) {
                                        'QR Scan' => 'bg-blue-100 text-blue-700',
                                        'ID Scan' => 'bg-indigo-100 text-indigo-700',
                                        'Manual' => 'bg-slate-100 text-slate-600',
                                        default => 'bg-slate-100 text-slate-600',
                                    };
                                @endphp
                                <span class="px-2 py-0.5 rounded-full text-xs font-medium {{ $vColor }}">{{ $verify }}</span>
                            </td>
                            <td class="px-4 py-3">
                                <span class="px-2 py-0.5 bg-emerald-100 text-emerald-700 rounded-full text-xs font-medium">{{ $status }}</span>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>

        {{-- Record Distribution Modal --}}
        <div
            x-show="showDistModal"
            x-cloak
            class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
            @click.self="showDistModal = false">
            <div class="bg-white rounded-2xl shadow-float w-full max-w-2xl max-h-[90vh] overflow-y-auto p-6">
                <div class="flex items-center justify-between mb-5">
                    <h3 class="text-base font-bold text-navy-900">Record Distribution</h3>
                    <button @click="showDistModal = false" class="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                        <i data-lucide="x" class="w-4 h-4 text-slate-500"></i>
                    </button>
                </div>
                <div class="space-y-4">
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Household Head Search</label>
                        <input
                            type="text"
                            x-model="distHouseholdSearch"
                            @input="isDuplicate = distHouseholdSearch.toLowerCase().includes('rodrigo panganiban') && distPackageType === 'Family Food Pack'; supervisorConfirmed = false"
                            placeholder="Type household head name…"
                            class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 focus:border-brand-blue">
                        <p class="text-xs text-slate-400 mt-1">Type to search from registered evacuee households (DIST-001 – DIST-010).</p>
                    </div>

                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Package Type</label>
                            <select
                                x-model="distPackageType"
                                @change="isDuplicate = distHouseholdSearch.toLowerCase().includes('rodrigo panganiban') && distPackageType === 'Family Food Pack'; supervisorConfirmed = false"
                                class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
                                <option value="">Select package…</option>
                                <option>Family Food Pack</option>
                                <option>Hygiene Kit</option>
                                <option>Family Food Pack + Hygiene Kit</option>
                                <option>Water Pack</option>
                                <option>Sleeping Kit</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Verification Method</label>
                            <select class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
                                <option>QR Scan</option>
                                <option>ID Scan</option>
                                <option>Manual</option>
                            </select>
                        </div>
                    </div>

                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Distribution Center</label>
                            <select class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
                                @foreach($centers as $center)
                                <option value="{{ $center['id'] }}">{{ $center['name'] }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Distributing Officer</label>
                            <input type="text" placeholder="Officer name" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                    </div>

                    {{-- Duplicate Warning --}}
                    <div x-show="isDuplicate" x-cloak class="bg-rose-50 border border-rose-200 rounded-xl p-3 text-rose-700 text-sm">
                        <strong>⚠ Duplicate Alert:</strong> This household already received 1 Family Food Pack on Jul 15, 2026. Override requires supervisor authorization.
                        <label class="flex items-center gap-2 mt-2 cursor-pointer">
                            <input type="checkbox" x-model="supervisorConfirmed" class="rounded text-rose-600">
                            <span class="text-xs">I am a supervisor and authorize this distribution.</span>
                        </label>
                    </div>
                </div>

                <div class="flex items-center justify-end gap-3 mt-6 pt-4 border-t border-slate-100">
                    <button @click="showDistModal = false" class="px-4 py-2 rounded-xl border border-slate-200 text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors">Cancel</button>
                    <button
                        :disabled="isDuplicate && !supervisorConfirmed"
                        :class="(isDuplicate && !supervisorConfirmed) ? 'opacity-40 cursor-not-allowed bg-brand-blue text-white' : 'bg-brand-blue text-white hover:bg-brand-blue/90'"
                        @click="if(!(isDuplicate && !supervisorConfirmed)){ $dispatch('toast', { message: 'Distribution DIST-011 recorded for ' + (distHouseholdSearch || 'household') + '.', variant: 'success' }); showDistModal = false }"
                        class="px-5 py-2 rounded-xl text-sm font-semibold transition-colors shadow-sm">
                        <i data-lucide="check" class="w-4 h-4 inline-block mr-1"></i>
                        Distribute
                    </button>
                </div>
            </div>
        </div>
    </div>

    {{-- ================================================================ --}}
    {{-- SUBTAB: Donations --}}
    {{-- ================================================================ --}}
    <div x-show="reliefSubtab === 'donations'" x-cloak
         x-data="{ showDonationModal: false }"
         class="space-y-4">

        <div class="flex items-center justify-between">
            <h3 class="text-base font-semibold text-navy-900">Donation Records</h3>
            <button
                @click="showDonationModal = true"
                class="inline-flex items-center gap-2 px-4 py-2 bg-brand-blue text-white rounded-xl text-sm font-medium hover:bg-brand-blue/90 transition-colors shadow-sm">
                <i data-lucide="plus" class="w-4 h-4"></i>
                Record Donation
            </button>
        </div>

        <div class="bg-white rounded-2xl shadow-card border border-slate-100 overflow-hidden">
            <div class="overflow-x-auto">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="bg-slate-50 border-b border-slate-100">
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">ID</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Donor</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Date</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Items</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Qty</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Est. Value</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Received By</th>
                            <th class="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Status</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-50">
                        @foreach([
                            ['DON-001','SM Foundation Masbate','Jul 14, 2026','Canned goods, Bottled water','500 cans / 200 bottles','₱45,000','Relief Officer Santos','Allocated','emerald'],
                            ['DON-002','Philippine Red Cross — Masbate Chapter','Jul 15, 2026','First Aid Kits, ORS','20 kits / 100 sachets','₱28,000','MDRRMO Head Salinas','Allocated','emerald'],
                            ['DON-003','Reyes Family (Private)','Jul 15, 2026','Cash for food packs','—','₱10,000','Treasurer Mendoza','Acknowledged','blue'],
                            ['DON-004','Bayanihan Group Manila','Jul 15, 2026','Sleeping mats, Blankets','50 mats / 50 blankets','₱22,000','Relief Officer Ramos','Partially Allocated','amber'],
                            ['DON-005','LGU Masbate City','Jul 15, 2026','Rice (50kg sacks), Canned goods','20 sacks / 300 cans','₱38,000','MDRRMO Head Salinas','Allocated','emerald'],
                        ] as [$id,$donor,$date,$items,$qty,$value,$by,$status,$color])
                        <tr class="hover:bg-slate-50 transition-colors">
                            <td class="px-4 py-3"><span class="font-mono text-xs text-slate-500 bg-slate-100 px-2 py-0.5 rounded">{{ $id }}</span></td>
                            <td class="px-4 py-3 font-medium text-slate-800 text-xs">{{ $donor }}</td>
                            <td class="px-4 py-3 text-slate-600 text-xs whitespace-nowrap">{{ $date }}</td>
                            <td class="px-4 py-3 text-slate-600 text-xs">{{ $items }}</td>
                            <td class="px-4 py-3 text-slate-600 text-xs">{{ $qty }}</td>
                            <td class="px-4 py-3 font-semibold text-slate-800 text-xs">{{ $value }}</td>
                            <td class="px-4 py-3 text-xs text-slate-500">{{ $by }}</td>
                            <td class="px-4 py-3">
                                @php
                                    $donClass = match($color) {
                                        'emerald' => 'bg-emerald-100 text-emerald-700',
                                        'blue'    => 'bg-blue-100 text-blue-700',
                                        'amber'   => 'bg-amber-100 text-amber-700',
                                        default   => 'bg-slate-100 text-slate-600',
                                    };
                                @endphp
                                <span class="px-2 py-0.5 rounded-full text-xs font-medium {{ $donClass }}">{{ $status }}</span>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>

        {{-- Record Donation Modal --}}
        <div
            x-show="showDonationModal"
            x-cloak
            class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
            @click.self="showDonationModal = false">
            <div class="bg-white rounded-2xl shadow-float w-full max-w-2xl max-h-[90vh] overflow-y-auto p-6">
                <div class="flex items-center justify-between mb-5">
                    <h3 class="text-base font-bold text-navy-900">Record Donation</h3>
                    <button @click="showDonationModal = false" class="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                        <i data-lucide="x" class="w-4 h-4 text-slate-500"></i>
                    </button>
                </div>
                <div class="space-y-4">
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Donor Name / Organization</label>
                            <input type="text" placeholder="e.g. SM Foundation" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Date Received</label>
                            <input type="date" value="{{ date('Y-m-d') }}" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Items / Description</label>
                            <input type="text" placeholder="e.g. Canned goods, Bottled water" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Quantity</label>
                            <input type="text" placeholder="e.g. 500 cans / 200 bottles" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Estimated Value (₱)</label>
                            <input type="number" min="0" placeholder="0.00" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-600 mb-1.5">Received By</label>
                            <input type="text" placeholder="Officer name" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        </div>
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Notes / Remarks</label>
                        <textarea rows="2" placeholder="Additional notes…" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 resize-none"></textarea>
                    </div>
                </div>
                <div class="flex items-center justify-end gap-3 mt-6 pt-4 border-t border-slate-100">
                    <button @click="showDonationModal = false" class="px-4 py-2 rounded-xl border border-slate-200 text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors">Cancel</button>
                    <button
                        @click="$dispatch('toast', { message: 'Donation DON-006 recorded successfully.', variant: 'success' }); showDonationModal = false"
                        class="px-5 py-2 bg-brand-blue text-white rounded-xl text-sm font-semibold hover:bg-brand-blue/90 transition-colors shadow-sm">
                        Save Donation
                    </button>
                </div>
            </div>
        </div>
    </div>

    {{-- ================================================================ --}}
    {{-- MODAL: Stock In --}}
    {{-- ================================================================ --}}
    <div
        x-show="showStockInModal"
        x-cloak
        x-data="{ stockInQty: 0, stockInItem: '', stockInBatch: '', stockInSource: '', stockInBy: '', stockInDate: '{{ date('Y-m-d') }}', stockInCondition: 'Good', stockInNotes: '' }"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
        @click.self="showStockInModal = false">
        <div class="bg-white rounded-2xl shadow-float w-full max-w-2xl max-h-[90vh] overflow-y-auto p-6">
            <div class="flex items-center justify-between mb-5">
                <div>
                    <h3 class="text-base font-bold text-navy-900">Stock In</h3>
                    <p class="text-xs text-slate-500 mt-0.5">Record incoming inventory items</p>
                </div>
                <button @click="showStockInModal = false" class="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                    <i data-lucide="x" class="w-4 h-4 text-slate-500"></i>
                </button>
            </div>
            <div class="space-y-4">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div class="sm:col-span-2">
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Item Name</label>
                        <select x-model="stockInItem" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
                            <option value="">Select item…</option>
                            @foreach($inventory as $item)
                            <option value="{{ $item['name'] }}" @if(isset($selectedInventoryItem) && $selectedInventoryItem && $item['code'] === ($selectedInventoryItem['code'] ?? '')) selected @endif>
                                {{ $item['code'] }} — {{ $item['name'] }}
                            </option>
                            @endforeach
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Quantity</label>
                        <input type="number" min="1" x-model="stockInQty" placeholder="0" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Batch / Lot Number</label>
                        <input type="text" x-model="stockInBatch" placeholder="e.g. LOT-2026-0715" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Source / Donor</label>
                        <input type="text" x-model="stockInSource" placeholder="e.g. DSWD Masbate" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Received By</label>
                        <input type="text" x-model="stockInBy" placeholder="Officer name" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Date Received</label>
                        <input type="date" x-model="stockInDate" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Condition</label>
                        <select x-model="stockInCondition" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
                            <option>Good</option>
                            <option>Fair</option>
                            <option>Poor</option>
                        </select>
                    </div>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Notes</label>
                    <textarea x-model="stockInNotes" rows="2" placeholder="Additional notes…" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 resize-none"></textarea>
                </div>
            </div>
            <div class="flex items-center justify-end gap-3 mt-6 pt-4 border-t border-slate-100">
                <button @click="showStockInModal = false" class="px-4 py-2 rounded-xl border border-slate-200 text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors">Cancel</button>
                <button
                    @click="$dispatch('toast', { message: 'Stock added: +' + stockInQty + ' ' + stockInItem + '. Inventory updated.', variant: 'success' }); showStockInModal = false"
                    class="px-5 py-2 bg-emerald-600 text-white rounded-xl text-sm font-semibold hover:bg-emerald-700 transition-colors shadow-sm">
                    <i data-lucide="circle-plus" class="w-4 h-4 inline-block mr-1"></i>
                    Confirm Stock In
                </button>
            </div>
        </div>
    </div>

    {{-- ================================================================ --}}
    {{-- MODAL: Stock Out --}}
    {{-- ================================================================ --}}
    <div
        x-show="showStockOutModal"
        x-cloak
        x-data="{ stockOutQty: 0, stockOutItem: '', stockOutPurpose: '', stockOutDest: '', stockOutBy: '', stockOutRemarks: '' }"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
        @click.self="showStockOutModal = false">
        <div class="bg-white rounded-2xl shadow-float w-full max-w-2xl max-h-[90vh] overflow-y-auto p-6">
            <div class="flex items-center justify-between mb-5">
                <div>
                    <h3 class="text-base font-bold text-navy-900">Stock Out</h3>
                    <p class="text-xs text-slate-500 mt-0.5">Release inventory from storage</p>
                </div>
                <button @click="showStockOutModal = false" class="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                    <i data-lucide="x" class="w-4 h-4 text-slate-500"></i>
                </button>
            </div>
            <div class="space-y-4">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div class="sm:col-span-2">
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Item</label>
                        <select x-model="stockOutItem" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
                            <option value="">Select item…</option>
                            @foreach($inventory as $item)
                            <option value="{{ $item['name'] }}" @if(isset($selectedInventoryItem) && $selectedInventoryItem && $item['code'] === ($selectedInventoryItem['code'] ?? '')) selected @endif>
                                {{ $item['code'] }} — {{ $item['name'] }} (Available: {{ number_format($item['available']) }})
                            </option>
                            @endforeach
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Quantity to Release</label>
                        <input type="number" min="1" x-model="stockOutQty" placeholder="0" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                        <div x-show="stockOutQty > 999 && stockOutItem === ''" class="mt-1.5 flex items-center gap-1.5 text-xs text-amber-600">
                            <i data-lucide="triangle-alert" class="w-3.5 h-3.5"></i>
                            Requested quantity exceeds available stock.
                        </div>
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Purpose</label>
                        <select x-model="stockOutPurpose" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
                            <option value="">Select purpose…</option>
                            <option>Relief Distribution</option>
                            <option>Evacuation Center Supply</option>
                            <option>Medical Use</option>
                            <option>Transfer</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Destination / Beneficiary</label>
                        <input type="text" x-model="stockOutDest" placeholder="e.g. Masbaranon EC" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Authorized By</label>
                        <input type="text" x-model="stockOutBy" placeholder="Authorizing officer" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                    </div>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Remarks</label>
                    <textarea x-model="stockOutRemarks" rows="2" placeholder="Additional remarks…" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 resize-none"></textarea>
                </div>
            </div>
            <div class="flex items-center justify-end gap-3 mt-6 pt-4 border-t border-slate-100">
                <button @click="showStockOutModal = false" class="px-4 py-2 rounded-xl border border-slate-200 text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors">Cancel</button>
                <button
                    @click="$dispatch('toast', { message: 'Stock released: -' + stockOutQty + ' ' + (stockOutItem || 'item') + '.', variant: 'success' }); showStockOutModal = false"
                    class="px-5 py-2 bg-orange-500 text-white rounded-xl text-sm font-semibold hover:bg-orange-600 transition-colors shadow-sm">
                    <i data-lucide="circle-minus" class="w-4 h-4 inline-block mr-1"></i>
                    Confirm Stock Out
                </button>
            </div>
        </div>
    </div>

    {{-- ================================================================ --}}
    {{-- MODAL: Create Request --}}
    {{-- ================================================================ --}}
    <div
        x-show="showRequestModal"
        x-cloak
        x-data="{ reqItemCount: 1, reqBeneficiaries: 0, reqPriority: 'Normal', reqReason: '', reqBy: '' }"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm"
        @click.self="showRequestModal = false">
        <div class="bg-white rounded-2xl shadow-float w-full max-w-2xl max-h-[90vh] overflow-y-auto p-6">
            <div class="flex items-center justify-between mb-5">
                <div>
                    <h3 class="text-base font-bold text-navy-900">Create Relief Request</h3>
                    <p class="text-xs text-slate-500 mt-0.5">Submit a new relief request for review and approval</p>
                </div>
                <button @click="showRequestModal = false" class="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                    <i data-lucide="x" class="w-4 h-4 text-slate-500"></i>
                </button>
            </div>
            <div class="space-y-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Requesting Entity</label>
                    <select class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
                        <option value="">Select center or barangay…</option>
                        <optgroup label="Evacuation Centers">
                            @foreach($centers as $center)
                            <option value="center-{{ $center['id'] }}">{{ $center['name'] }} ({{ $center['barangay'] }})</option>
                            @endforeach
                        </optgroup>
                        <optgroup label="Barangays">
                            @foreach($barangays as $brgy)
                            <option value="brgy-{{ Str::slug($brgy) }}">{{ $brgy }} Barangay Hall</option>
                            @endforeach
                        </optgroup>
                    </select>
                </div>

                {{-- Item Rows --}}
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Requested Items</label>
                    <div class="space-y-2">
                        <template x-for="i in reqItemCount" :key="i">
                            <div class="flex gap-2 items-center">
                                <select class="flex-1 px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
                                    <option value="">Select item…</option>
                                    @foreach($inventory as $item)
                                    <option value="{{ $item['code'] }}">{{ $item['name'] }}</option>
                                    @endforeach
                                </select>
                                <input type="number" min="1" placeholder="Qty" class="w-24 px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                            </div>
                        </template>
                    </div>
                    <button
                        x-show="reqItemCount < 5"
                        @click="reqItemCount++"
                        class="mt-2 text-xs text-brand-blue hover:underline flex items-center gap-1">
                        <i data-lucide="plus" class="w-3 h-3"></i>
                        Add Another Item
                    </button>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Beneficiary Count</label>
                        <input type="number" min="0" x-model="reqBeneficiaries" placeholder="0" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-600 mb-1.5">Priority</label>
                        <select x-model="reqPriority" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 bg-white">
                            <option>Normal</option>
                            <option>High</option>
                            <option>Urgent</option>
                        </select>
                    </div>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Reason / Justification</label>
                    <textarea x-model="reqReason" rows="2" placeholder="Describe the need…" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30 resize-none"></textarea>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Requested By</label>
                    <input type="text" x-model="reqBy" placeholder="Name and designation" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-brand-blue/30">
                </div>
            </div>
            <div class="flex items-center justify-end gap-3 mt-6 pt-4 border-t border-slate-100">
                <button @click="showRequestModal = false" class="px-4 py-2 rounded-xl border border-slate-200 text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors">Cancel</button>
                <button
                    @click="$dispatch('toast', { message: 'Relief request REQ-007 submitted for approval.', variant: 'success' }); showRequestModal = false"
                    class="px-5 py-2 bg-brand-blue text-white rounded-xl text-sm font-semibold hover:bg-brand-blue/90 transition-colors shadow-sm">
                    Submit Request
                </button>
            </div>
        </div>
    </div>

</div>

@once
<script>
document.addEventListener('DOMContentLoaded', function () {
    window.renderIcons?.();
});
</script>
@endonce
