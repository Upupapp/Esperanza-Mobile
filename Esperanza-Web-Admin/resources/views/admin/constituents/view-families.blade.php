{{-- view-families.blade.php --}}
{{-- Families table view — rendered inside constituents.blade.php Alpine x-data scope --}}

<div class="space-y-4">

    {{-- Header row: count + add button --}}
    <div class="flex items-center justify-between">
        <p class="text-sm text-slate-500">
            Showing <span class="font-semibold text-navy-900" x-text="filteredFamilies.length"></span>
            <span x-text="filteredFamilies.length === 1 ? 'family' : 'families'"></span>
        </p>
        <button
            @click="showAddFamily = true; addFamilyStep = 1; $nextTick(()=>window.renderIcons?.())"
            class="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium rounded-lg shadow-sm transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
            <i data-lucide="plus" class="w-4 h-4"></i>
            Add Family
        </button>
    </div>

    {{-- Table --}}
    <x-ui.table>
        <thead>
            <tr class="bg-slate-50 border-b border-slate-200">
                <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Family</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Barangay</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Household</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Head of Family</th>
                <th class="px-4 py-3 text-center text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Members</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap w-36">Completion</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Verification</th>
                <th class="px-4 py-3 text-center text-xs font-semibold text-slate-500 uppercase tracking-wider whitespace-nowrap">Actions</th>
            </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">

            {{-- Empty state row --}}
            <template x-if="filteredFamilies.length === 0">
                <tr>
                    <td colspan="8" class="py-16 px-4 text-center">
                        <x-ui.empty-state
                            icon="users-round"
                            title="No families found"
                            subtitle="Try adjusting your search or filters, or add a new family record."
                        />
                    </td>
                </tr>
            </template>

            {{-- Family rows --}}
            <template x-for="f in filteredFamilies" :key="f.id">
                <tr
                    class="hover:bg-blue-50/40 cursor-pointer transition-colors group"
                    @click="openFamily(f)"
                >
                    {{-- Family label + ID + type chip --}}
                    <td class="px-4 py-3">
                        <div class="flex items-start gap-3">
                            <div class="flex-shrink-0 w-9 h-9 rounded-full bg-blue-100 flex items-center justify-center ring-2 ring-white shadow-sm">
                                <span class="text-blue-700 font-bold text-xs" x-text="f.surname?.substring(0,2).toUpperCase()"></span>
                            </div>
                            <div class="min-w-0">
                                <p class="text-sm font-semibold text-navy-900 truncate" x-text="f.label"></p>
                                <p class="text-xs text-slate-400 font-mono" x-text="'#' + f.id"></p>
                                {{-- Family type chip --}}
                                <span
                                    class="inline-flex items-center mt-0.5 px-1.5 py-0.5 rounded text-xs font-medium"
                                    :class="{
                                        'bg-slate-100 text-slate-600': f.family_type === 'Nuclear',
                                        'bg-purple-100 text-purple-700': f.family_type === 'Extended',
                                        'bg-amber-100 text-amber-700': f.family_type === 'Single Parent'
                                    }"
                                    x-text="f.family_type"
                                ></span>
                            </div>
                        </div>
                    </td>

                    {{-- Barangay --}}
                    <td class="px-4 py-3">
                        <p class="text-sm text-navy-900 font-medium" x-text="f.barangay"></p>
                        <p class="text-xs text-slate-400" x-text="f.sitio ? ('Sitio ' + f.sitio) : '—'"></p>
                    </td>

                    {{-- Household link --}}
                    <td class="px-4 py-3">
                        <template x-if="f.household_id">
                            <button
                                @click.stop="openHousehold(filteredHouseholds.find(h=>h.id===f.household_id) || {id:f.household_id,label:'HH-'+f.household_id})"
                                class="inline-flex items-center gap-1 text-xs text-blue-600 hover:text-blue-800 font-medium hover:underline"
                            >
                                <i data-lucide="house" class="w-3 h-3"></i>
                                <span x-text="'HH-' + f.household_id"></span>
                            </button>
                        </template>
                        <template x-if="!f.household_id">
                            <span class="text-xs text-slate-400 italic">Unlinked</span>
                        </template>
                    </td>

                    {{-- Head of Family --}}
                    <td class="px-4 py-3">
                        <div class="flex items-center gap-2">
                            <template x-if="f.head_name">
                                <div class="w-8 h-8 text-xs rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold ring-2 ring-white shadow-sm shrink-0" x-text="(f.head_name || '').split(/\s+/).filter(Boolean).map(w => w[0]).slice(0,2).join('').toUpperCase()"></div>
                            </template>
                            <span class="text-sm text-navy-900" x-text="f.head_name || '—'"></span>
                        </div>
                    </td>

                    {{-- Member count --}}
                    <td class="px-4 py-3 text-center">
                        <span class="inline-flex items-center justify-center w-7 h-7 rounded-full bg-slate-100 text-slate-700 text-xs font-semibold" x-text="f.member_count"></span>
                    </td>

                    {{-- Profile completion bar --}}
                    <td class="px-4 py-3">
                        <div class="flex items-center gap-2">
                            <div class="flex-1 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                                <div
                                    class="h-full rounded-full transition-all"
                                    :class="completionColor(f.profile_pct)"
                                    :style="'width:' + (f.profile_pct||0) + '%'"
                                ></div>
                            </div>
                            <span class="text-xs font-medium w-8 text-right" :class="completionTextColor(f.profile_pct)" x-text="(f.profile_pct||0) + '%'"></span>
                        </div>
                    </td>

                    {{-- Verification badge --}}
                    <td class="px-4 py-3">
                        <span
                            class="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium"
                            :class="verificationBadge(f.verification).class"
                            x-text="verificationBadge(f.verification).label"
                        ></span>
                    </td>

                    {{-- Actions --}}
                    <td class="px-4 py-3" @click.stop>
                        <div class="flex items-center justify-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button
                                @click="openFamily(f)"
                                title="View family detail"
                                class="p-1.5 rounded-md text-slate-400 hover:text-blue-600 hover:bg-blue-50 transition-colors"
                            >
                                <i data-lucide="eye" class="w-4 h-4"></i>
                            </button>
                            <button
                                @click="$dispatch('toast', {message: 'Add member feature coming soon.', type: 'info'})"
                                title="Add member to family"
                                class="p-1.5 rounded-md text-slate-400 hover:text-emerald-600 hover:bg-emerald-50 transition-colors"
                            >
                                <i data-lucide="user-plus" class="w-4 h-4"></i>
                            </button>
                        </div>
                    </td>
                </tr>
            </template>

        </tbody>
    </x-ui.table>

    {{-- Footer pagination hint --}}
    <template x-if="filteredFamilies.length > 0">
        <p class="text-xs text-slate-400 text-right pt-1">
            <span x-text="filteredFamilies.length"></span> record<span x-text="filteredFamilies.length===1?'':'s'"></span> shown
        </p>
    </template>

</div>
