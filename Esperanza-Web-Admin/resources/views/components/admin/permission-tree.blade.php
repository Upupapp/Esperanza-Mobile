{{-- Reusable Module → Submodule → Permission accordion.
     `modules` / `bind` / `locked` are Alpine expression strings (not PHP values) — `bind`
     names an object already declared in the calling page's x-data, keyed by
     submodule key => array of granted permission strings. This component
     mutates that object directly, so the caller always has the live result.
     `locked` is any Alpine boolean expression (e.g. "!selectedRole.editable"),
     evaluated live so the same tree can flip read-only per selected role. --}}
@props(['modules', 'bind', 'compact' => false, 'locked' => 'false'])

@php
    $permTypeLabels = [
        'view' => 'View', 'create' => 'Create', 'edit' => 'Edit', 'delete' => 'Delete',
        'review' => 'Review', 'approve' => 'Approve', 'reject' => 'Reject', 'release' => 'Release',
        'export' => 'Export', 'print' => 'Print', 'archive' => 'Archive',
    ];
@endphp

<div
    x-data="{
        permQuery: '',
        openModules: [],
        permTypeLabels: @js($permTypeLabels),
        toggleModule(key) {
            const i = this.openModules.indexOf(key);
            if (i === -1) { this.openModules.push(key); } else { this.openModules.splice(i, 1); }
        },
        isOpen(key) { return this.openModules.includes(key); },
        hasPerm(subKey, perm) { return ({{ $bind }}[subKey] || []).includes(perm); },
        subCount(subKey) { return ({{ $bind }}[subKey] || []).length; },
        togglePerm(subKey, perm) {
            if ({{ $locked }}) return;
            if (!{{ $bind }}[subKey]) { {{ $bind }}[subKey] = []; }
            const i = {{ $bind }}[subKey].indexOf(perm);
            if (i === -1) { {{ $bind }}[subKey].push(perm); } else { {{ $bind }}[subKey].splice(i, 1); }
        },
        toggleAllSub(sub) {
            if ({{ $locked }}) return;
            {{ $bind }}[sub.key] = (this.subCount(sub.key) === sub.perms.length) ? [] : [...sub.perms];
        },
        moduleChecked(mod) { return mod.submodules.reduce((n, s) => n + this.subCount(s.key), 0); },
        moduleTotal(mod) { return mod.submodules.reduce((n, s) => n + s.perms.length, 0); },
        toggleAllModule(mod) {
            if ({{ $locked }}) return;
            const full = this.moduleChecked(mod) === this.moduleTotal(mod);
            mod.submodules.forEach(s => { {{ $bind }}[s.key] = full ? [] : [...s.perms]; });
        },
        matchesQuery(mod) {
            if (!this.permQuery) return true;
            const q = this.permQuery.toLowerCase();
            return mod.name.toLowerCase().includes(q) || mod.submodules.some(s => s.name.toLowerCase().includes(q));
        },
    }"
    x-init="openModules = [{{ $modules }}[0]?.key].filter(Boolean)"
    class="space-y-2.5"
>
    <div class="relative">
        <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none"></i>
        <input
            type="text" x-model="permQuery"
            placeholder="Search modules or permissions..."
            class="w-full pl-9 pr-3 py-2 text-xs rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200"
        >
    </div>

    <div class="{{ $compact ? 'max-h-80 overflow-y-auto scrollbar-thin pr-1 -mr-1' : '' }} space-y-2.5">
        <template x-for="mod in {{ $modules }}" :key="mod.key">
            <div x-show="matchesQuery(mod)" class="rounded-2xl border border-slate-200 overflow-hidden">
                <button
                    type="button" @click="toggleModule(mod.key)"
                    class="w-full flex items-center gap-3 px-3.5 py-2.5 bg-slate-50/70 hover:bg-slate-100/70 transition-colors text-left"
                >
                    <i data-lucide="chevron-right" class="w-3.5 h-3.5 text-slate-400 transition-transform duration-200 shrink-0" :class="isOpen(mod.key) && 'rotate-90'"></i>
                    <span class="w-7 h-7 rounded-lg bg-white shadow-sm flex items-center justify-center shrink-0 text-brand-600">
                        <i :data-lucide="mod.icon" class="w-3.5 h-3.5"></i>
                    </span>
                    <div class="min-w-0 flex-1">
                        <p class="text-xs font-semibold text-navy-900 truncate" x-text="mod.name"></p>
                        <p class="text-[10.5px] text-slate-400"><span x-text="moduleChecked(mod)"></span>/<span x-text="moduleTotal(mod)"></span> permissions</p>
                    </div>
                    <span
                        x-show="!({{ $locked }})"
                        @click.stop="toggleAllModule(mod)"
                        class="text-[10.5px] font-medium text-brand-600 hover:underline shrink-0 px-1.5"
                        x-text="moduleChecked(mod) === moduleTotal(mod) ? 'Clear all' : 'Select all'"
                    ></span>
                </button>

                <div
                    x-show="isOpen(mod.key)"
                    x-transition:enter="transition ease-out duration-150"
                    x-transition:enter-start="opacity-0"
                    x-transition:enter-end="opacity-100"
                    x-cloak
                    class="divide-y divide-slate-100 border-t border-slate-100"
                >
                    <template x-for="sub in mod.submodules" :key="sub.key">
                        <div class="px-3.5 py-2.5">
                            <div class="flex items-center justify-between gap-3 mb-1.5">
                                <label class="flex items-center gap-2" :class="({{ $locked }}) ? '' : 'cursor-pointer'">
                                    <input
                                        type="checkbox"
                                        :checked="subCount(sub.key) === sub.perms.length"
                                        :disabled="{{ $locked }}"
                                        @change="toggleAllSub(sub)"
                                        class="rounded border-slate-300 text-brand-600 focus:ring-brand-200 disabled:opacity-60"
                                    >
                                    <span class="text-[11.5px] font-medium text-slate-700" x-text="sub.name"></span>
                                </label>
                                <span class="text-[10px] text-slate-400 shrink-0" x-text="subCount(sub.key) + '/' + sub.perms.length"></span>
                            </div>
                            <div class="flex flex-wrap gap-1.5 pl-6">
                                <template x-for="perm in sub.perms" :key="perm">
                                    <button
                                        type="button"
                                        @click="togglePerm(sub.key, perm)"
                                        :disabled="{{ $locked }}"
                                        class="px-2.5 py-1 rounded-lg text-[10px] font-medium border transition-colors"
                                        :class="[
                                            hasPerm(sub.key, perm) ? 'bg-brand-600 border-brand-600 text-white' : 'bg-white border-slate-200 text-slate-500',
                                            ({{ $locked }}) ? 'cursor-not-allowed opacity-70' : 'hover:border-slate-300'
                                        ]"
                                        x-text="permTypeLabels[perm] || perm"
                                    ></button>
                                </template>
                            </div>
                        </div>
                    </template>
                </div>
            </div>
        </template>
    </div>
</div>
