@php
    $payments = [
        ['ref' => 'DR-2026-2210', 'citizen' => 'Maria Fe Bacaltos', 'type' => 'Dokyu', 'item' => 'Cedula (Community Tax Certificate)', 'amount' => '₱32.00', 'method' => null, 'receipt' => null, 'status' => 'Waiting Requirements', 'date' => 'Jul 8, 2026'],
        ['ref' => 'DR-2026-2214', 'citizen' => 'Rosemarie Tan', 'type' => 'Dokyu', 'item' => 'Business Permit (New)', 'amount' => '₱1,250.00', 'method' => 'PayMaya', 'receipt' => 'PayMaya Receipt.png', 'status' => 'Pending Review', 'date' => 'Jul 10, 2026'],
        ['ref' => 'DR-2026-2187', 'citizen' => 'Maria Fe Bacaltos', 'type' => 'Dokyu', 'item' => 'Barangay Clearance', 'amount' => '₱50.00', 'method' => 'Payment in Center', 'receipt' => 'OR-88214.jpg', 'status' => 'Approved', 'date' => 'Jul 3, 2026'],
        ['ref' => 'DR-2026-2154', 'citizen' => 'Corazon Villareal', 'type' => 'Dokyu', 'item' => 'Certificate of Residency', 'amount' => '₱50.00', 'method' => 'GCash', 'receipt' => 'GCash Receipt.jpg', 'status' => 'Approved', 'date' => 'Jun 29, 2026'],
        ['ref' => 'DR-2026-1655', 'citizen' => 'Rosemarie Tan', 'type' => 'Dokyu', 'item' => 'Business Permit Renewal', 'amount' => '₱980.00', 'method' => 'GCash', 'receipt' => 'GCash Receipt (blurred).jpg', 'status' => 'Rejected', 'date' => 'May 12, 2026'],
        ['ref' => 'DR-2026-1490', 'citizen' => 'Michael Bacus', 'type' => 'Dokyu', 'item' => 'Real Property Tax Clearance', 'amount' => '₱100.00', 'method' => 'GCash', 'receipt' => 'GCash Receipt 2.jpg', 'status' => 'Approved', 'date' => 'Apr 20, 2026'],
        ['ref' => 'AR-2026-0037', 'citizen' => 'Josefina Marbella', 'type' => 'Tulong', 'item' => 'Social Pension — Documentary Fee', 'amount' => '₱100.00', 'method' => 'Payment in Center', 'receipt' => 'OR-77031.jpg', 'status' => 'Approved', 'date' => 'Feb 10, 2026'],
    ];

    $adminFiles = [
        ['name' => 'GCash Receipt Scan.jpg', 'category' => 'IMG'],
        ['name' => 'PayMaya Confirmation.png', 'category' => 'IMG'],
        ['name' => 'Official Receipt (OR) Scan.pdf', 'category' => 'PDF'],
    ];

    $tabs = ['all' => 'All', 'unpaid' => 'Awaiting Payment', 'review' => 'Pending Review', 'paid' => 'Paid'];

    $totalInvoiced = 2562.00;
    $totalCollected = 300.00;
    $paidCount = collect($payments)->where('status', 'Approved')->count();
    $reviewCount = collect($payments)->where('status', 'Pending Review')->count();
    $unpaidCount = collect($payments)->where('status', 'Waiting Requirements')->count();
@endphp

<x-layouts.admin title="Payments" subtitle="Track Dokyu and Tulong invoices, methods, and attached receipts." active="payments">
    <div
        x-data="{
            tab: 'all',
            search: '',
            open: false,
            selected: null,
            payments: @js($payments),
            adminFiles: @js($adminFiles),
            method: null,
            receipt: null,
            showReceiptPicker: false,
            processing: false,
            runAction(fn) {
                if (this.processing) return;
                this.processing = true;
                setTimeout(() => { fn(); this.processing = false; this.open = false; }, 700);
            },
            matches(p) {
                const tabOk = this.tab === 'all'
                    || (this.tab === 'unpaid' && p.status === 'Waiting Requirements')
                    || (this.tab === 'review' && p.status === 'Pending Review')
                    || (this.tab === 'paid' && p.status === 'Approved');
                const q = this.search.trim().toLowerCase();
                const searchOk = q === '' || p.ref.toLowerCase().includes(q) || p.citizen.toLowerCase().includes(q);
                return tabOk && searchOk;
            },
            get visibleCount() { return this.payments.filter(p => this.matches(p)).length; },
        }"
        class="animate-fade-up"
    >

        <div x-show="!$store.session.can('payments')" x-cloak>
            <x-admin.access-restricted module="Payments" icon="receipt" />
        </div>

        <div x-show="$store.session.can('payments')" x-cloak>

        <div class="grid grid-cols-2 lg:grid-cols-5 gap-3 mb-4">
            <x-ui.stat-card label="Total Invoiced" value="₱{{ number_format($totalInvoiced, 2) }}" icon="receipt" color="brand" sublabel="This month" :delay="0" />
            <x-ui.stat-card label="Total Collected" value="₱{{ number_format($totalCollected, 2) }}" icon="banknote" color="green" :delay="40" />
            <x-ui.stat-card label="Paid" value="{{ $paidCount }}" valueBind="payments.filter(p => p.status === 'Approved').length" icon="circle-check" color="green" :delay="80" />
            <x-ui.stat-card label="Pending Review" value="{{ $reviewCount }}" valueBind="payments.filter(p => p.status === 'Pending Review').length" icon="clock" color="orange" sublabel="Receipt awaiting verification" :delay="120" />
            <x-ui.stat-card label="Awaiting Payment" value="{{ $unpaidCount }}" valueBind="payments.filter(p => p.status === 'Waiting Requirements').length" icon="circle-dollar-sign" color="red" :delay="160" />
        </div>

        <div class="bg-white border border-slate-200 rounded-2xl shadow-card p-3 mb-4 space-y-3">
            <div class="flex flex-wrap items-center gap-2">
                <div class="relative flex-1 min-w-[200px]">
                    <i data-lucide="search" class="w-3.5 h-3.5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none"></i>
                    <input type="text" x-model="search" placeholder="Search reference or citizen..." class="w-full pl-9 pr-3 py-2 text-xs rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-brand-300 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200">
                </div>
            </div>
            <div class="flex flex-wrap items-center justify-between gap-2">
                <div class="flex items-center gap-1.5 bg-slate-100/70 rounded-xl p-1 w-fit overflow-x-auto">
                    @foreach($tabs as $key => $label)
                        <button
                            type="button" @click="tab = '{{ $key }}'"
                            class="px-3 py-1.5 text-[11px] font-medium rounded-lg transition-colors whitespace-nowrap"
                            :class="tab === '{{ $key }}' ? 'bg-white text-navy-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'"
                        >{{ $label }}</button>
                    @endforeach
                </div>
                <p class="text-[11px] text-slate-400 shrink-0" x-text="visibleCount + ' of ' + payments.length + ' payments'"></p>
            </div>
        </div>

        <x-ui.table>
            <thead>
                <tr class="border-b border-slate-100 bg-slate-50/60">
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400">Reference</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400">Citizen</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden md:table-cell">Item</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400">Amount</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden lg:table-cell">Method</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden lg:table-cell">Receipt</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400 hidden sm:table-cell">Date</th>
                    <th class="px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-400">Status</th>
                    <th class="px-4 py-2.5"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-50">
                @foreach($payments as $i => $p)
                    <tr
                        x-show="matches(payments[{{ $i }}])" x-cloak
                        class="hover:bg-slate-50/70 transition-colors"
                    >
                        <td class="px-4 py-3 font-mono text-xs text-slate-500">{{ $p['ref'] }}</td>
                        <td class="px-4 py-3 text-slate-700 font-medium whitespace-nowrap">{{ $p['citizen'] }}</td>
                        <td class="px-4 py-3 text-slate-500 hidden md:table-cell">{{ $p['item'] }}</td>
                        <td class="px-4 py-3 text-slate-700 font-semibold whitespace-nowrap">{{ $p['amount'] }}</td>
                        <td class="px-4 py-3 text-slate-500 hidden lg:table-cell" x-text="payments[{{ $i }}].method || '—'"></td>
                        <td class="px-4 py-3 hidden lg:table-cell">
                            <span class="inline-flex items-center gap-1 text-xs text-brand-600" x-show="payments[{{ $i }}].receipt">
                                <i data-lucide="paperclip" class="w-3.5 h-3.5"></i><span x-text="payments[{{ $i }}].receipt"></span>
                            </span>
                            <span class="text-xs text-slate-300" x-show="!payments[{{ $i }}].receipt">—</span>
                        </td>
                        <td class="px-4 py-3 text-slate-500 hidden sm:table-cell whitespace-nowrap">{{ $p['date'] }}</td>
                        <td class="px-4 py-3">
                            <x-ui.badge status="Waiting Requirements" x-show="payments[{{ $i }}].status === 'Waiting Requirements'" />
                            <x-ui.badge status="Pending Review" x-show="payments[{{ $i }}].status === 'Pending Review'" x-cloak />
                            <x-ui.badge status="Approved" x-show="payments[{{ $i }}].status === 'Approved'" x-cloak />
                            <x-ui.badge status="Rejected" x-show="payments[{{ $i }}].status === 'Rejected'" x-cloak />
                        </td>
                        <td class="px-4 py-3 text-right">
                            <button
                                @click="open = true; selected = {{ $i }}; method = payments[{{ $i }}].method; receipt = payments[{{ $i }}].receipt; showReceiptPicker = false"
                                class="text-xs font-medium text-brand-600 hover:underline whitespace-nowrap"
                            >Manage</button>
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </x-ui.table>

        <div class="flex flex-col items-center text-center py-10 bg-white border border-slate-100 rounded-2xl mt-3" x-show="visibleCount === 0">
            <span class="w-11 h-11 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mb-3"><i data-lucide="search-x" class="w-5 h-5"></i></span>
            <p class="text-sm font-medium text-slate-600">No payments match these filters.</p>
        </div>

        <x-ui.modal title="Payment Details" maxWidth="lg">
            <template x-if="selected !== null">
                <div>
                    <div class="flex items-center justify-between mb-4">
                        <span class="text-xs font-mono text-slate-400" x-text="payments[selected].ref"></span>
                        <span class="text-[11px] font-medium px-2 py-0.5 rounded-full" :class="payments[selected].type === 'Dokyu' ? 'bg-brand-50 text-brand-700' : 'bg-purple-50 text-purple-700'" x-text="payments[selected].type"></span>
                    </div>

                    <!-- Invoice -->
                    <div class="rounded-xl border border-slate-200 overflow-hidden mb-5">
                        <div class="flex items-center justify-between px-4 py-3 bg-slate-50 border-b border-slate-100">
                            <p class="text-xs font-semibold text-navy-900 uppercase tracking-wide">Invoice Summary</p>
                            <span class="text-[10px] font-mono text-slate-400">Municipality of Esperanza</span>
                        </div>
                        <div class="px-4 py-3.5 text-sm">
                            <div class="flex items-center justify-between py-1.5">
                                <span class="text-slate-500">Citizen</span>
                                <span class="text-slate-700 font-medium" x-text="payments[selected].citizen"></span>
                            </div>
                            <div class="flex items-center justify-between py-1.5">
                                <span class="text-slate-500">Item</span>
                                <span class="text-slate-700 font-medium text-right" x-text="payments[selected].item"></span>
                            </div>
                            <div class="flex items-center justify-between py-1.5">
                                <span class="text-slate-500">Date Invoiced</span>
                                <span class="text-slate-700 font-medium" x-text="payments[selected].date"></span>
                            </div>
                            <div class="border-t border-dashed border-slate-200 my-2"></div>
                            <div class="flex items-center justify-between py-1">
                                <span class="text-sm font-semibold text-navy-900">Total Due</span>
                                <span class="text-base font-bold text-brand-700" x-text="payments[selected].amount"></span>
                            </div>
                        </div>
                    </div>

                    <!-- Read-only receipt view for rows with a receipt already -->
                    <div class="rounded-xl border border-slate-200 p-3 mb-2 flex items-center justify-between gap-3" x-show="payments[selected].receipt">
                        <div class="flex items-center gap-2.5 min-w-0">
                            <span class="w-8 h-8 rounded-lg bg-brand-50 text-brand-600 flex items-center justify-center shrink-0"><i data-lucide="paperclip" class="w-4 h-4"></i></span>
                            <div class="min-w-0">
                                <p class="text-xs font-medium text-slate-700 truncate" x-text="payments[selected].receipt"></p>
                                <p class="text-[11px] text-slate-400" x-text="'Paid via ' + (payments[selected].method || 'unspecified method')"></p>
                            </div>
                        </div>
                        <button type="button" @click="$dispatch('toast', { message: 'Receipt preview is a frontend mock — no file is stored.', variant: 'info' })" class="text-xs font-medium text-brand-600 hover:underline shrink-0">View</button>
                    </div>

                    <!-- Admin: attach receipt on behalf of citizen (Waiting Requirements rows) -->
                    <div x-show="payments[selected].status === 'Waiting Requirements'" x-cloak>
                        <p class="text-sm font-semibold text-navy-900 mb-3 mt-4">Record Payment</p>
                        <p class="text-xs text-slate-400 mb-3">If the citizen paid over-the-counter or you've verified proof of payment, record it here.</p>
                        <div class="space-y-2 mb-4">
                            <template x-for="m in ['GCash', 'PayMaya', 'Payment in Center']" :key="m">
                                <label
                                    class="flex items-center gap-3 rounded-xl border p-3 cursor-pointer transition-all duration-200"
                                    :class="method === m ? 'border-brand-400 bg-brand-50/60 ring-4 ring-brand-100' : 'border-slate-200 hover:border-slate-300'"
                                >
                                    <input type="radio" name="admin_payment_method" class="text-brand-600 focus:ring-brand-200" :checked="method === m" @change="method = m">
                                    <span class="text-sm font-medium text-slate-700" x-text="m"></span>
                                </label>
                            </template>
                        </div>
                        <div class="rounded-xl border border-slate-200 p-3">
                            <div class="flex items-center justify-between gap-3">
                                <p class="text-xs text-slate-600 flex-1">Attach receipt / proof of payment</p>
                                <button type="button" x-show="!receipt" @click="showReceiptPicker = !showReceiptPicker" class="text-[11px] font-medium text-brand-600 hover:underline shrink-0 whitespace-nowrap">Attach File</button>
                                <div class="flex items-center gap-1.5 shrink-0" x-show="receipt">
                                    <span class="inline-flex items-center gap-1 text-[11px] text-emerald-600 font-medium whitespace-nowrap"><i data-lucide="circle-check" class="w-3.5 h-3.5"></i><span x-text="receipt"></span></span>
                                    <button type="button" @click="receipt = null" class="text-slate-300 hover:text-rose-500"><i data-lucide="x" class="w-3.5 h-3.5"></i></button>
                                </div>
                            </div>
                            <div x-show="showReceiptPicker" x-cloak x-transition class="mt-2.5 pt-2.5 border-t border-slate-100">
                                <x-ui.file-picker
                                    files="adminFiles"
                                    onSelect="receipt = file.name; showReceiptPicker = false"
                                    uploadAction="receipt = 'Scanned OR.jpg'; showReceiptPicker = false; $dispatch('toast', { message: 'File upload is a frontend preview — no data is saved.', variant: 'info' })"
                                    :columns="2"
                                    :search="false"
                                    :bilingual="false"
                                />
                            </div>
                        </div>
                    </div>
                </div>
            </template>

            <x-slot:footer>
                <template x-if="selected !== null && payments[selected].status === 'Waiting Requirements'">
                    <x-ui.button
                        size="sm"
                        ::disabled="!method || !receipt || processing"
                        @click="runAction(() => { payments[selected].method = method; payments[selected].receipt = receipt; payments[selected].status = 'Pending Review'; $dispatch('toast', { message: 'Payment recorded — sent for verification.', variant: 'success' }); })"
                    >
                        <span class="inline-flex items-center gap-1.5">
                            <i data-lucide="loader-circle" class="w-3.5 h-3.5 animate-spin" x-show="processing" x-cloak></i>
                            <i data-lucide="check" class="w-3.5 h-3.5" x-show="!processing"></i>
                            <span x-text="processing ? 'Saving…' : 'Save & Send for Verification'"></span>
                        </span>
                    </x-ui.button>
                </template>
                <template x-if="selected !== null && payments[selected].status === 'Pending Review'">
                    <div class="flex items-center gap-2.5">
                        <x-ui.button variant="danger" size="sm" x-bind:disabled="processing" @click="runAction(() => { payments[selected].status = 'Rejected'; $dispatch('toast', { message: 'Receipt rejected — citizen will be notified.', variant: 'error' }); })">
                            <span class="inline-flex items-center gap-1.5">
                                <i data-lucide="loader-circle" class="w-3.5 h-3.5 animate-spin" x-show="processing" x-cloak></i>
                                <span x-text="processing ? 'Rejecting…' : 'Reject Receipt'"></span>
                            </span>
                        </x-ui.button>
                        <x-ui.button size="sm" x-bind:disabled="processing" @click="runAction(() => { payments[selected].status = 'Approved'; $dispatch('toast', { message: 'Payment verified and marked as paid.', variant: 'success' }); })">
                            <span class="inline-flex items-center gap-1.5">
                                <i data-lucide="loader-circle" class="w-3.5 h-3.5 animate-spin" x-show="processing" x-cloak></i>
                                <i data-lucide="check" class="w-3.5 h-3.5" x-show="!processing"></i>
                                <span x-text="processing ? 'Verifying…' : 'Verify Payment'"></span>
                            </span>
                        </x-ui.button>
                    </div>
                </template>
                <template x-if="selected !== null && !['Waiting Requirements', 'Pending Review'].includes(payments[selected].status)">
                    <x-ui.button size="sm" @click="open = false">Close</x-ui.button>
                </template>
            </x-slot:footer>
        </x-ui.modal>

        </div>
    </div>
</x-layouts.admin>
