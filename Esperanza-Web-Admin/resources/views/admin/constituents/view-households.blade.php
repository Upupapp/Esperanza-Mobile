{{-- view-households.blade.php --}}
{{-- Households table view — rendered inside constituents.blade.php Alpine x-data scope --}}

<div class="space-y-4">

    {{-- Header row: count + add button --}}
    <div class="flex items-center justify-between">
        <p class="text-sm text-slate-500">
            Showing <span class="font-semibold text-navy-900" x-text="filteredHouseholds.length"></span>
            <span x-text="filteredHouseholds.length === 1 ? 'household' : 'households'"></span>
        </p>
        <button
            @click="showAddHousehold = true; addHouseholdStep = 1; $nextTick(()=>window.renderIcons?.())"
            class="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium rounded-lg shadow-sm transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
            <i data-lucide="plus" class="w-4 h-4"></i>
            Add Household
        </button>
    </div>

    {{-- Table --}}
    <x-ui.table>
        <thead>
            <tr class="bg-slate-50 border-b border-slate-200">
                <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Household</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Barangay / Sitio</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Head</th>
                <th class="px-4 py-3 text-center text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Families</th>
                <th class="px-4 py-3 text-center text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Members</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Dwelling</th>
                <th class="px-4 py-3 text-center text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Amenities</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap w-32">Completion</th>
                <th class="px-4 py-3 text-center text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Actions</th>
            </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">

            {{-- Empty state row --}}
            <template x-if="filteredHouseholds.length === 0">
                <tr>
                    <td colspan="9" class="py-16 px-4 text-center">
                        <x-ui.empty-state
                            icon="house"
                            title="No households found"
                            subtitle="Try adjusting your search or filters, or register a new household."
                        />
                    </td>
                </tr>
            </template>

            {{-- Household rows --}}
            <template x-for="h in filteredHouseholds" :key="h.id">
                <tr
                    class="hover:bg-blue-50/40 cursor-pointer transition-colors group"
                    @click="openHousehold(h)"
                >
                    {{-- Household label + ID + flood risk badge --}}
                    <td class="px-4 py-3">
                        <div class="flex items-start gap-3">
                            <div class="flex-shrink-0 w-9 h-9 rounded-lg bg-indigo-100 flex items-center justify-center ring-2 ring-white shadow-sm">
                                <i data-lucide="house" class="w-4 h-4 text-indigo-600"></i>
                            </div>
                            <div class="min-w-0">
                                <p class="text-sm font-semibold text-navy-900 truncate" x-text="h.label"></p>
                                <p class="text-xs text-slate-400 font-mono" x-text="'#' + h.id"></p>
                                {{-- Flood risk chip --}}
                                <span
                                    class="inline-flex items-center mt-0.5 gap-1 px-1.5 py-0.5 rounded text-xs font-medium"
                                    :class="{
                                        'bg-emerald-100 text-emerald-700': h.flood_risk === 'Low',
                                        'bg-amber-100 text-amber-700': h.flood_risk === 'Medium',
                                        'bg-rose-100 text-rose-700': h.flood_risk === 'High'
                                    }"
                                >
                                    <i data-lucide="waves-horizontal" class="w-3 h-3"></i>
                                    <span x-text="(h.flood_risk || 'Unknown') + ' Flood Risk'"></span>
                                </span>
                            </div>
                        </div>
                    </td>

                    {{-- Barangay / Sitio --}}
                    <td class="px-4 py-3">
                        <p class="text-sm text-navy-900 font-medium" x-text="h.barangay"></p>
                        <p class="text-xs text-slate-400" x-text="h.sitio ? ('Sitio ' + h.sitio) : '—'"></p>
                    </td>

                    {{-- Head --}}
                    <td class="px-4 py-3">
                        <div class="flex items-center gap-2">
                            <template x-if="h.head_name">
                                <div class="w-8 h-8 text-xs rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold ring-2 ring-white shadow-sm shrink-0" x-text="(h.head_name || '').split(/\s+/).filter(Boolean).map(w => w[0]).slice(0,2).join('').toUpperCase()"></div>
                            </template>
                            <span class="text-sm text-navy-900" x-text="h.head_name || '—'"></span>
                        </div>
                    </td>

                    {{-- Family count --}}
                    <td class="px-4 py-3 text-center">
                        <span class="inline-flex items-center justify-center w-7 h-7 rounded-full bg-indigo-100 text-indigo-700 text-xs font-semibold" x-text="h.family_count"></span>
                    </td>

                    {{-- Member count --}}
                    <td class="px-4 py-3 text-center">
                        <span class="inline-flex items-center justify-center w-7 h-7 rounded-full bg-slate-100 text-slate-700 text-xs font-semibold" x-text="h.member_count"></span>
                    </td>

                    {{-- Dwelling type --}}
                    <td class="px-4 py-3">
                        <p class="text-sm text-navy-900 leading-tight" x-text="h.dwelling_type || '—'"></p>
                        <p class="text-xs text-slate-400 mt-0.5" x-text="h.housing_tenure || ''"></p>
                    </td>

                    {{-- Amenities: electricity / water / toilet icons --}}
                    <td class="px-4 py-3">
                        <div class="flex items-center justify-center gap-2">
                            {{-- Electricity --}}
                            <span
                                class="relative group/tip"
                                :title="h.electricity ? 'Has Electricity' : 'No Electricity'"
                            >
                                <i
                                    data-lucide="zap"
                                    class="w-4 h-4 transition-colors"
                                    :class="h.electricity ? 'text-amber-500' : 'text-slate-300'"
                                ></i>
                            </span>
                            {{-- Water --}}
                            <span
                                class="relative"
                                :title="h.water ? 'Has Water Source' : 'No Water Source'"
                            >
                                <i
                                    data-lucide="droplets"
                                    class="w-4 h-4 transition-colors"
                                    :class="h.water ? 'text-blue-500' : 'text-slate-300'"
                                ></i>
                            </span>
                            {{-- Toilet --}}
                            <span
                                class="relative"
                                :title="h.toilet ? 'Has Toilet Facility' : 'No Toilet Facility'"
                            >
                                <i
                                    data-lucide="toilet"
                                    class="w-4 h-4 transition-colors"
                                    :class="h.toilet ? 'text-emerald-500' : 'text-slate-300'"
                                ></i>
                            </span>
                        </div>
                    </td>

                    {{-- Profile completion --}}
                    <td class="px-4 py-3">
                        <div class="flex items-center gap-2">
                            <div class="flex-1 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                                <div
                                    class="h-full rounded-full transition-all"
                                    :class="completionColor(h.profile_pct)"
                                    :style="'width:' + (h.profile_pct||0) + '%'"
                                ></div>
                            </div>
                            <span class="text-xs font-medium w-8 text-right" :class="completionTextColor(h.profile_pct)" x-text="(h.profile_pct||0) + '%'"></span>
                        </div>
                    </td>

                    {{-- Actions --}}
                    <td class="px-4 py-3" @click.stop>
                        <div class="flex items-center justify-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button
                                @click="openHousehold(h)"
                                title="View household detail"
                                class="p-1.5 rounded-md text-slate-400 hover:text-blue-600 hover:bg-blue-50 transition-colors"
                            >
                                <i data-lucide="eye" class="w-4 h-4"></i>
                            </button>
                            <button
                                @click="$dispatch('toast', {message: 'Edit household feature coming soon.', type: 'info'})"
                                title="Edit household"
                                class="p-1.5 rounded-md text-slate-400 hover:text-amber-600 hover:bg-amber-50 transition-colors"
                            >
                                <i data-lucide="pencil" class="w-4 h-4"></i>
                            </button>
                        </div>
                    </td>
                </tr>
            </template>

        </tbody>
    </x-ui.table>

    {{-- Footer pagination hint --}}
    <template x-if="filteredHouseholds.length > 0">
        <p class="text-xs text-slate-400 text-right pt-1">
            <span x-text="filteredHouseholds.length"></span> record<span x-text="filteredHouseholds.length===1?'':'s'"></span> shown
        </p>
    </template>

</div>
