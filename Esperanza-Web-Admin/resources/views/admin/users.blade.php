@php
    // Single source of truth for the RBAC model lives in config/esperanza_rbac.php
    // (also embedded as JSON on the login screen and every admin page for the
    // "log in as this role" session simulation — see resources/js/app.js).
    $permTypes = config('esperanza_rbac.permission_types');
    $permissionModules = config('esperanza_rbac.permission_modules');
    $roles = config('esperanza_rbac.roles');
    $accounts = config('esperanza_rbac.accounts');

    $roleNames = array_column($roles, 'name', 'key');

    $departments = ['Office of the Mayor', 'MSWDO', "Treasurer's Office", 'Civil Registrar', 'Municipal Health Office', 'ICT Office', 'BPLO', 'OSCA', 'MDRRMO'];

    // Access scope: a Municipal account can act across the whole LGU; a
    // Barangay account is restricted to the data of one specific barangay.
    $barangays = config('esperanza.barangays');

    $users = array_map(fn ($a) => [
        'name' => $a['name'], 'id' => $a['id'], 'role' => $a['role'], 'dept' => $a['dept'],
        'status' => $a['status'], 'scope' => $a['scope'],
    ], $accounts);

    $tab = $tab ?? 'personnel';
@endphp

<x-layouts.admin title="User Management" subtitle="Manage LGU personnel accounts, roles, and access." active="users">
    <div x-data="{ tab: '{{ $tab }}' }" class="animate-fade-up">

        <div x-show="!$store.session.can('user_management')" x-cloak>
            <x-admin.access-restricted module="User Management" icon="user-cog" />
        </div>

        <div x-show="$store.session.can('user_management')" x-cloak>

        <div class="flex items-center gap-1.5 bg-white border border-slate-200 rounded-xl p-1 shadow-card w-fit mb-4">
            <button @click="tab = 'personnel'" class="px-3.5 py-1.5 text-xs font-medium rounded-lg transition-colors flex items-center gap-1.5" :class="tab === 'personnel' ? 'bg-brand-600 text-white' : 'text-slate-500 hover:bg-slate-50'"><i data-lucide="user-cog" class="w-3.5 h-3.5"></i>Personnel</button>
            <button @click="tab = 'roles'" class="px-3.5 py-1.5 text-xs font-medium rounded-lg transition-colors flex items-center gap-1.5" :class="tab === 'roles' ? 'bg-brand-600 text-white' : 'text-slate-500 hover:bg-slate-50'"><i data-lucide="shield-check" class="w-3.5 h-3.5"></i>Roles</button>
            <button @click="tab = 'permissions'" class="px-3.5 py-1.5 text-xs font-medium rounded-lg transition-colors flex items-center gap-1.5" :class="tab === 'permissions' ? 'bg-brand-600 text-white' : 'text-slate-500 hover:bg-slate-50'"><i data-lucide="key-round" class="w-3.5 h-3.5"></i>Permissions</button>
        </div>

        {{-- ============================= PERSONNEL ============================= --}}
        <div
            x-data="{
                open: false,
                search: '',
                users: @js($users),
                statusStyles: {
                    'Approved': ['bg-emerald-50 text-emerald-700 ring-emerald-200', 'bg-emerald-500'],
                    'Pending Review': ['bg-amber-50 text-amber-700 ring-amber-200', 'bg-amber-500'],
                    'Rejected': ['bg-rose-50 text-rose-700 ring-rose-200', 'bg-rose-500'],
                    'Archived': ['bg-slate-100 text-slate-400 ring-slate-200', 'bg-slate-300'],
                },
                get filteredUsers() {
                    const q = this.search.trim().toLowerCase();
                    return this.users.filter(u => q === '' || u.name.toLowerCase().includes(q) || u.id.toLowerCase().includes(q) || u.role.toLowerCase().includes(q));
                },
            }"
            x-show="tab === 'personnel'"
        >
            <div class="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-4">
                <x-ui.stat-card label="Total Personnel" value="46" icon="users" color="brand" :delay="0" />
                <x-ui.stat-card label="Active Accounts" value="42" icon="user-round-check" color="green" :delay="40" />
                <x-ui.stat-card label="Pending Approval" value="3" icon="user-round-search" color="orange" :delay="80" />
                <x-ui.stat-card label="Deactivated" value="1" icon="user-x" color="red" :delay="120" />
            </div>

            <div class="bg-white border border-slate-200 rounded-2xl shadow-card p-3 mb-4 flex flex-wrap items-center gap-2">
                <div class="relative flex-1 min-w-[200px]">
                    <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none"></i>
                    <input type="text" x-model="search" placeholder="Search personnel..." class="w-full pl-9 pr-3 py-2 text-xs rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200">
                </div>
                <p class="text-[11px] text-slate-400 shrink-0" x-text="filteredUsers.length + ' of ' + users.length + ' personnel'"></p>
                <div class="w-px h-6 bg-slate-200 hidden sm:block"></div>
                <x-ui.button @click="open = true" icon="user-plus" size="sm" class="shrink-0">Add Personnel</x-ui.button>
            </div>

            <x-ui.table>
                <thead>
                    <tr class="border-b border-slate-100 bg-slate-50/60">
                        <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400">Personnel</th>
                        <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden sm:table-cell">Employee ID</th>
                        <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden md:table-cell">Role</th>
                        <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden lg:table-cell">Department</th>
                        <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden md:table-cell">Access Scope</th>
                        <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400">Status</th>
                        <th class="px-4 py-2.5"></th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-50">
                    <template x-for="u in filteredUsers" :key="u.id">
                        <tr class="hover:bg-slate-50/70 transition-colors">
                            <td class="px-4 py-2.5 flex items-center gap-3">
                                <span class="w-8 h-8 rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold shrink-0 text-xs" x-text="u.name.split(' ').map(w => w[0]).slice(0,2).join('').toUpperCase()"></span>
                                <span class="text-slate-700 font-medium whitespace-nowrap" x-text="u.name"></span>
                            </td>
                            <td class="px-4 py-3 text-slate-500 hidden sm:table-cell font-mono text-xs" x-text="u.id"></td>
                            <td class="px-4 py-3 text-slate-500 hidden md:table-cell" x-text="u.role"></td>
                            <td class="px-4 py-3 text-slate-500 hidden lg:table-cell" x-text="u.dept"></td>
                            <td class="px-4 py-3 hidden md:table-cell">
                                <span
                                    class="inline-flex items-center gap-1.5 text-[11px] font-medium rounded-full px-2.5 py-1 whitespace-nowrap border"
                                    :class="u.scope === 'Municipal' ? 'text-brand-700 bg-brand-50 border-brand-100' : 'text-purple-700 bg-purple-50 border-purple-100'"
                                >
                                    <i :data-lucide="u.scope === 'Municipal' ? 'landmark' : 'map-pin'" class="w-3 h-3"></i>
                                    <span x-text="u.scope === 'Municipal' ? 'Municipality-wide' : 'Brgy. ' + u.scope"></span>
                                </span>
                            </td>
                            <td class="px-4 py-3">
                                <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ring-1 ring-inset whitespace-nowrap" :class="(statusStyles[u.status] || statusStyles['Approved'])[0]">
                                    <span class="w-1.5 h-1.5 rounded-full" :class="(statusStyles[u.status] || statusStyles['Approved'])[1]"></span>
                                    <span x-text="u.status"></span>
                                </span>
                            </td>
                            <td class="px-4 py-3 text-right">
                                <button class="text-slate-400 hover:text-brand-600 transition-colors"><i data-lucide="ellipsis-vertical" class="w-4 h-4"></i></button>
                            </td>
                        </tr>
                    </template>
                </tbody>
            </x-ui.table>

            <div class="flex flex-col items-center text-center py-10 bg-white border border-slate-100 rounded-2xl mt-3" x-show="filteredUsers.length === 0">
                <span class="w-11 h-11 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mb-3"><i data-lucide="search-x" class="w-5 h-5"></i></span>
                <p class="text-sm font-medium text-slate-600">No personnel match this search.</p>
            </div>

            {{-- ---------------- Add Personnel wizard ---------------- --}}
            <div
                x-data="{
                    step: 1,
                    roles: @js(array_map(fn ($r) => ['key' => $r['key'], 'name' => $r['name'], 'icon' => $r['icon'], 'color' => $r['color'], 'desc' => $r['desc'], 'editable' => $r['editable'], 'permissions' => $r['permissions']], array_values(array_filter($roles, fn ($r) => $r['key'] !== 'citizen')))),
                    modules: @js($permissionModules),
                    barangays: @js($barangays),
                    form: { firstName: '', lastName: '', email: '', dept: '{{ $departments[0] }}', roleKey: 'department_staff', scope: 'municipal', barangay: '{{ $barangays[0] }}' },
                    get selectedRole() { return this.roles.find(r => r.key === this.form.roleKey); },
                    grantedCount(role) { return Object.values(role.permissions).reduce((n, arr) => n + arr.length, 0); },
                    accessedModules(role) {
                        return this.modules.filter(m => m.submodules.some(s => (role.permissions[s.key] || []).length > 0));
                    },
                    next() { if (this.step < 4) this.step++; },
                    back() { if (this.step > 1) this.step--; },
                    reset() { this.step = 1; this.form = { firstName: '', lastName: '', email: '', dept: '{{ $departments[0] }}', roleKey: 'department_staff', scope: 'municipal', barangay: '{{ $barangays[0] }}' }; },
                }"
                x-init="$watch('open', v => { if (!v) reset(); })"
            >
                <x-ui.modal title="Add Personnel Account" maxWidth="3xl">
                    <div class="space-y-4">
                        <!-- Stepper -->
                        <div class="flex items-center gap-2 mb-1">
                            <template x-for="(label, i) in ['Account Info', 'Assign Role', 'Access Scope', 'Review Access']" :key="i">
                                <div class="flex items-center gap-2 flex-1">
                                    <div class="flex items-center gap-2 flex-1">
                                        <span
                                            class="w-6 h-6 rounded-full flex items-center justify-center text-[10.5px] font-semibold shrink-0 transition-colors duration-200"
                                            :class="step > i + 1 ? 'bg-emerald-500 text-white' : (step === i + 1 ? 'bg-brand-600 text-white' : 'bg-slate-100 text-slate-400')"
                                        >
                                            <i data-lucide="check" class="w-3 h-3" x-show="step > i + 1"></i>
                                            <span x-show="step <= i + 1" x-text="i + 1"></span>
                                        </span>
                                        <span class="text-[11px] font-medium hidden sm:inline" :class="step === i + 1 ? 'text-navy-900' : 'text-slate-400'" x-text="label"></span>
                                    </div>
                                    <div class="h-px flex-1 bg-slate-100" x-show="i < 3"></div>
                                </div>
                            </template>
                        </div>

                        <!-- Step 1: Account Info -->
                        <div x-show="step === 1" x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 translate-x-2" x-transition:enter-end="opacity-100 translate-x-0" class="space-y-4">
                            <div class="grid grid-cols-2 gap-4">
                                <x-ui.input name="first_name" label="First Name" placeholder="Angeline" x-model="form.firstName" />
                                <x-ui.input name="last_name" label="Last Name" placeholder="Mercado" x-model="form.lastName" />
                            </div>
                            <x-ui.input name="email" type="email" label="Work Email" icon="mail" placeholder="angeline.mercado@esperanza.gov.ph" x-model="form.email" />
                            <div>
                                <label class="block text-sm font-medium text-slate-700 mb-1.5">Department</label>
                                <select x-model="form.dept" class="w-full rounded-xl border border-slate-200 bg-slate-50/60 py-2.5 px-4 text-sm text-slate-700 focus:bg-white focus:border-brand-400 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200">
                                    @foreach($departments as $dept)
                                        <option value="{{ $dept }}">{{ $dept }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>

                        <!-- Step 2: Assign Role -->
                        <div x-show="step === 2" x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 translate-x-2" x-transition:enter-end="opacity-100 translate-x-0">
                            <p class="text-xs text-slate-500 mb-3">Select the role that best matches this personnel's responsibilities. Permissions are inherited from the role and can be reviewed in the next step.</p>
                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5 max-h-80 overflow-y-auto scrollbar-thin pr-1 -mr-1">
                                <template x-for="role in roles" :key="role.key">
                                    <button
                                        type="button" @click="form.roleKey = role.key"
                                        class="text-left rounded-xl border p-3 transition-all duration-150"
                                        :class="form.roleKey === role.key ? 'border-brand-400 bg-brand-50/60 ring-2 ring-brand-100' : 'border-slate-200 hover:border-slate-300'"
                                    >
                                        <div class="flex items-center gap-2.5 mb-1.5">
                                            <span class="w-8 h-8 rounded-lg flex items-center justify-center shrink-0" :class="role.color">
                                                <i :data-lucide="role.icon" class="w-4 h-4"></i>
                                            </span>
                                            <p class="text-xs font-semibold text-navy-900" x-text="role.name"></p>
                                        </div>
                                        <p class="text-[11px] text-slate-500 leading-snug line-clamp-2" x-text="role.desc"></p>
                                    </button>
                                </template>
                            </div>
                        </div>

                        <!-- Step 3: Access Scope -->
                        <div x-show="step === 3" x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 translate-x-2" x-transition:enter-end="opacity-100 translate-x-0" class="space-y-3.5">
                            <p class="text-xs text-slate-500 mb-1">Define the geographic boundary of this account's access — a Municipal account can act across the whole LGU, while a Barangay account only sees that barangay's data.</p>
                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                                <button
                                    type="button" @click="form.scope = 'municipal'"
                                    class="text-left rounded-xl border p-3.5 transition-all duration-150"
                                    :class="form.scope === 'municipal' ? 'border-brand-400 bg-brand-50/60 ring-2 ring-brand-100' : 'border-slate-200 hover:border-slate-300'"
                                >
                                    <span class="w-9 h-9 rounded-lg bg-brand-50 text-brand-600 flex items-center justify-center mb-2"><i data-lucide="landmark" class="w-4.5 h-4.5"></i></span>
                                    <p class="text-xs font-semibold text-navy-900">Municipal</p>
                                    <p class="text-[11px] text-slate-500 mt-0.5 leading-snug">Municipality-wide access across all 20 barangays.</p>
                                </button>
                                <button
                                    type="button" @click="form.scope = 'barangay'"
                                    class="text-left rounded-xl border p-3.5 transition-all duration-150"
                                    :class="form.scope === 'barangay' ? 'border-brand-400 bg-brand-50/60 ring-2 ring-brand-100' : 'border-slate-200 hover:border-slate-300'"
                                >
                                    <span class="w-9 h-9 rounded-lg bg-purple-50 text-purple-600 flex items-center justify-center mb-2"><i data-lucide="map-pin" class="w-4.5 h-4.5"></i></span>
                                    <p class="text-xs font-semibold text-navy-900">Barangay</p>
                                    <p class="text-[11px] text-slate-500 mt-0.5 leading-snug">Restricted to the data of one specific barangay.</p>
                                </button>
                            </div>

                            <div x-show="form.scope === 'barangay'" x-cloak x-transition:enter="transition ease-out duration-150" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100">
                                <label class="block text-sm font-medium text-slate-700 mb-1.5">Barangay</label>
                                <select x-model="form.barangay" class="w-full rounded-xl border border-slate-200 bg-slate-50/60 py-2.5 px-4 text-sm text-slate-700 focus:bg-white focus:border-brand-400 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200">
                                    <template x-for="b in barangays" :key="b">
                                        <option :value="b" x-text="'Brgy. ' + b"></option>
                                    </template>
                                </select>
                                <p class="text-[11px] text-slate-400 mt-1.5">This account will only be able to view and manage data belonging to Brgy. <span x-text="form.barangay" class="font-medium text-slate-600"></span>.</p>
                            </div>
                        </div>

                        <!-- Step 4: Review Access -->
                        <div x-show="step === 4" x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 translate-x-2" x-transition:enter-end="opacity-100 translate-x-0" class="space-y-3.5">
                            <div class="flex items-center gap-3 rounded-xl border border-slate-100 bg-slate-50/60 p-3.5">
                                <x-ui.avatar name="New Personnel" size="sm" />
                                <div class="min-w-0 flex-1">
                                    <p class="text-sm font-medium text-slate-700" x-text="(form.firstName || 'First') + ' ' + (form.lastName || 'Last')"></p>
                                    <p class="text-xs text-slate-400" x-text="form.dept + ' · ' + (selectedRole ? selectedRole.name : '')"></p>
                                </div>
                                <span class="text-xs font-semibold text-brand-600 shrink-0" x-text="selectedRole ? grantedCount(selectedRole) + ' permissions' : ''"></span>
                            </div>

                            <div class="flex items-center gap-2.5 rounded-xl border px-3.5 py-2.5" :class="form.scope === 'municipal' ? 'border-brand-100 bg-brand-50/60' : 'border-purple-100 bg-purple-50/60'">
                                <i :data-lucide="form.scope === 'municipal' ? 'landmark' : 'map-pin'" class="w-4 h-4 shrink-0" :class="form.scope === 'municipal' ? 'text-brand-600' : 'text-purple-600'"></i>
                                <p class="text-xs font-medium" :class="form.scope === 'municipal' ? 'text-brand-700' : 'text-purple-700'">
                                    <span x-show="form.scope === 'municipal'">Municipality-wide access — can view and manage data across all 20 barangays.</span>
                                    <span x-show="form.scope === 'barangay'">Barangay-restricted access — will only see data belonging to Brgy. <span x-text="form.barangay"></span>.</span>
                                </p>
                            </div>

                            <div>
                                <p class="text-[11px] font-semibold uppercase tracking-wider text-slate-400 mb-2">Accessible Modules</p>
                                <div class="flex flex-wrap gap-1.5 mb-3.5">
                                    <template x-for="mod in (selectedRole ? accessedModules(selectedRole) : [])" :key="mod.key">
                                        <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-brand-50 text-brand-700 text-[11px] font-medium">
                                            <i :data-lucide="mod.icon" class="w-3 h-3"></i>
                                            <span x-text="mod.name"></span>
                                        </span>
                                    </template>
                                </div>
                            </div>

                            <template x-if="selectedRole">
                                <x-admin.permission-tree modules="modules" bind="selectedRole.permissions" locked="true" :compact="true" />
                            </template>
                        </div>

                        <div class="flex items-start gap-2.5 rounded-xl bg-slate-50 border border-slate-100 px-3.5 py-2.5">
                            <i data-lucide="info" class="w-4 h-4 text-slate-400 shrink-0 mt-0.5"></i>
                            <p class="text-xs text-slate-500">A temporary password will be sent to the personnel's work email upon account creation.</p>
                        </div>
                    </div>

                    <x-slot:footer>
                        <x-ui.button variant="secondary" size="sm" x-show="step === 1" @click="open = false">Cancel</x-ui.button>
                        <x-ui.button variant="secondary" size="sm" x-show="step > 1" @click="back()" icon="arrow-left">Back</x-ui.button>
                        <x-ui.button size="sm" x-show="step < 4" @click="next()" icon="arrow-right">Continue</x-ui.button>
                        <x-ui.button size="sm" x-show="step === 4" icon="user-plus" @click="open = false; $dispatch('toast', { message: 'Personnel account created — invite sent.', variant: 'success' })">Create Account</x-ui.button>
                    </x-slot:footer>
                </x-ui.modal>
            </div>
        </div>

        {{-- ============================= ROLES ============================= --}}
        <div x-data="{ roles: @js($roles), modules: @js($permissionModules), grantedCount(role) { return Object.values(role.permissions).reduce((n, arr) => n + arr.length, 0); }, moduleCount(role) { return this.modules.filter(m => m.submodules.some(s => (role.permissions[s.key] || []).length > 0)).length; } }" x-show="tab === 'roles'" x-cloak>
            <div class="flex items-center justify-between gap-3 mb-4">
                <p class="text-sm text-slate-500">{{ count($roles) }} roles · 46 personnel accounts</p>
                <x-ui.button icon="plus" size="sm" @click="$dispatch('toast', { message: 'Custom role builder — connect to backend to persist new roles.', variant: 'default' })">New Role</x-ui.button>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                <template x-for="role in roles" :key="role.key">
                    <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4 hover:shadow-lg hover:-translate-y-0.5 transition-all duration-200">
                        <div class="flex items-start justify-between">
                            <div class="flex items-center gap-3">
                                <span class="w-11 h-11 rounded-xl flex items-center justify-center shrink-0" :class="role.color">
                                    <i :data-lucide="role.icon" class="w-5 h-5"></i>
                                </span>
                                <div>
                                    <p class="text-sm font-semibold text-navy-900 flex items-center gap-1.5" x-text="role.name"></p>
                                    <p class="text-xs text-slate-400" x-text="(role.users > 999 ? role.users.toLocaleString() : role.users) + ' personnel'"></p>
                                </div>
                            </div>
                            <span x-show="!role.editable" class="text-slate-300" title="System role — not editable"><i data-lucide="lock" class="w-3.5 h-3.5"></i></span>
                        </div>
                        <p class="text-xs text-slate-500 mt-3.5 leading-relaxed line-clamp-3" x-text="role.desc"></p>
                        <div class="mt-3.5 pt-3.5 border-t border-slate-100 flex items-center justify-between">
                            <span class="text-[11px] text-slate-400"><span class="font-semibold text-slate-600" x-text="moduleCount(role)"></span> modules · <span class="font-semibold text-slate-600" x-text="grantedCount(role)"></span> permissions</span>
                            <button
                                @click="tab = 'permissions'; window.dispatchEvent(new CustomEvent('select-role', { detail: role.key }))"
                                class="text-xs font-medium text-brand-600 hover:underline flex items-center gap-1"
                            >View <i data-lucide="arrow-right" class="w-3 h-3"></i></button>
                        </div>
                    </div>
                </template>
            </div>
        </div>

        {{-- ============================= PERMISSIONS ============================= --}}
        <div
            x-data="{
                roles: @js($roles),
                modules: @js($permissionModules),
                selectedRoleKey: 'municipal_admin',
                workingPerms: {},
                dirty: false,
                get selectedRole() { return this.roles.find(r => r.key === this.selectedRoleKey); },
                selectRole(key) { this.selectedRoleKey = key; this.loadWorking(); },
                loadWorking() { this.workingPerms = JSON.parse(JSON.stringify(this.selectedRole.permissions)); this.dirty = false; },
                totalGranted() { return Object.values(this.workingPerms).reduce((n, arr) => n + arr.length, 0); },
                totalAvailable() { return this.modules.reduce((n, m) => n + m.submodules.reduce((n2, s) => n2 + s.perms.length, 0), 0); },
                moduleGranted(mod) { return mod.submodules.reduce((n, s) => n + (this.workingPerms[s.key]?.length || 0), 0); },
                moduleTotal(mod) { return mod.submodules.reduce((n, s) => n + s.perms.length, 0); },
                accessedModules() { return this.modules.filter(m => this.moduleGranted(m) > 0); },
                savePerms() {
                    this.selectedRole.permissions = JSON.parse(JSON.stringify(this.workingPerms));
                    this.dirty = false;
                    $dispatch('toast', { message: 'Permissions updated for ' + this.selectedRole.name + '.', variant: 'success' });
                },
            }"
            x-init="loadWorking(); $watch('workingPerms', () => dirty = true); window.addEventListener('select-role', e => selectRole(e.detail))"
            x-show="tab === 'permissions'" x-cloak
            class="grid grid-cols-1 lg:grid-cols-12 gap-4 items-start"
        >
            <!-- Sticky role sidebar -->
            <div class="lg:col-span-3 lg:sticky lg:top-4 space-y-1.5">
                <p class="text-[11px] font-semibold uppercase tracking-wider text-slate-400 px-1 mb-2">System Roles</p>
                <template x-for="role in roles" :key="role.key">
                    <button
                        type="button" @click="selectRole(role.key)"
                        class="w-full flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-left transition-colors duration-150"
                        :class="selectedRoleKey === role.key ? 'bg-brand-50 ring-1 ring-brand-200' : 'hover:bg-slate-50'"
                    >
                        <span class="w-8 h-8 rounded-lg flex items-center justify-center shrink-0" :class="role.color">
                            <i :data-lucide="role.icon" class="w-4 h-4"></i>
                        </span>
                        <div class="min-w-0 flex-1">
                            <p class="text-xs font-semibold truncate" :class="selectedRoleKey === role.key ? 'text-brand-700' : 'text-navy-900'" x-text="role.name"></p>
                            <p class="text-[10.5px] text-slate-400" x-text="(role.users > 999 ? role.users.toLocaleString() : role.users) + ' personnel'"></p>
                        </div>
                        <i data-lucide="lock" class="w-3 h-3 text-slate-300 shrink-0" x-show="!role.editable"></i>
                    </button>
                </template>
            </div>

            <!-- Role description + permission tree -->
            <div class="lg:col-span-6 space-y-4">
                <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4">
                    <div class="flex items-start justify-between gap-3 mb-1">
                        <div class="flex items-center gap-3">
                            <span class="w-11 h-11 rounded-xl flex items-center justify-center shrink-0" :class="selectedRole.color">
                                <i :data-lucide="selectedRole.icon" class="w-5 h-5"></i>
                            </span>
                            <div>
                                <p class="text-sm font-semibold text-navy-900 flex items-center gap-2">
                                    <span x-text="selectedRole.name"></span>
                                    <span x-show="!selectedRole.editable" class="inline-flex items-center gap-1 text-[10px] font-medium text-slate-500 bg-slate-100 rounded-full px-2 py-0.5"><i data-lucide="lock" class="w-2.5 h-2.5"></i>System</span>
                                </p>
                                <p class="text-xs text-slate-400" x-text="(selectedRole.users > 999 ? selectedRole.users.toLocaleString() : selectedRole.users) + ' personnel assigned'"></p>
                            </div>
                        </div>
                        <x-ui.button size="sm" icon="save" x-show="selectedRole.editable" x-bind:disabled="!dirty" @click="savePerms()">Save Changes</x-ui.button>
                    </div>
                    <p class="text-xs text-slate-500 mt-3 leading-relaxed" x-text="selectedRole.desc"></p>
                </div>

                <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4">
                    <div class="flex items-center justify-between mb-3">
                        <p class="text-xs font-semibold text-navy-900">Module Permissions</p>
                        <p class="text-[11px] text-slate-400" x-show="!selectedRole.editable">Read-only — system role</p>
                    </div>
                    <x-admin.permission-tree modules="modules" bind="workingPerms" locked="!selectedRole.editable" />
                </div>
            </div>

            <!-- Sticky permission summary -->
            <div class="lg:col-span-3 lg:sticky lg:top-4 space-y-4">
                <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4">
                    <p class="text-[11px] font-semibold uppercase tracking-wider text-slate-400 mb-3">Permission Summary</p>
                    <div class="flex items-end gap-1.5 mb-1">
                        <span class="text-2xl font-semibold text-navy-900" x-text="totalGranted()"></span>
                        <span class="text-xs text-slate-400 mb-1">/ <span x-text="totalAvailable()"></span> granted</span>
                    </div>
                    <div class="h-1.5 rounded-full bg-slate-100 overflow-hidden mb-4">
                        <div class="h-full bg-brand-500 rounded-full transition-all duration-300" :style="`width: ${totalAvailable() ? (totalGranted() / totalAvailable() * 100) : 0}%`"></div>
                    </div>

                    <div class="space-y-2.5">
                        <template x-for="mod in modules" :key="mod.key">
                            <div>
                                <div class="flex items-center justify-between text-[11px] mb-1">
                                    <span class="text-slate-600 flex items-center gap-1.5 truncate"><i :data-lucide="mod.icon" class="w-3 h-3 text-slate-400 shrink-0"></i><span class="truncate" x-text="mod.name"></span></span>
                                    <span class="text-slate-400 shrink-0 ml-2" x-text="moduleGranted(mod) + '/' + moduleTotal(mod)"></span>
                                </div>
                                <div class="h-1 rounded-full bg-slate-100 overflow-hidden">
                                    <div class="h-full bg-brand-400 rounded-full transition-all duration-300" :style="`width: ${moduleTotal(mod) ? (moduleGranted(mod) / moduleTotal(mod) * 100) : 0}%`"></div>
                                </div>
                            </div>
                        </template>
                    </div>
                </div>

                <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4">
                    <p class="text-[11px] font-semibold uppercase tracking-wider text-slate-400 mb-3">Accessible Modules</p>
                    <div class="flex flex-wrap gap-1.5" x-show="accessedModules().length > 0">
                        <template x-for="mod in accessedModules()" :key="mod.key">
                            <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-brand-50 text-brand-700 text-[10.5px] font-medium">
                                <i :data-lucide="mod.icon" class="w-3 h-3"></i>
                                <span x-text="mod.name"></span>
                            </span>
                        </template>
                    </div>
                    <p class="text-[11px] text-slate-400" x-show="accessedModules().length === 0">No module access granted.</p>
                </div>
            </div>
        </div>

        </div>
    </div>
</x-layouts.admin>
