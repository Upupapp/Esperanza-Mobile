{{-- Shown when the signed-in account's role has no permissions on this
     module. Pair with a sibling content block gated by
     x-show="$store.session.can('moduleKey')" so exactly one of the two shows. --}}
@props(['module' => 'this module', 'icon' => 'lock'])

<div class="flex flex-col items-center justify-center text-center py-20 px-6 bg-white rounded-2xl border border-slate-100 shadow-card animate-fade-up">
    <span class="w-14 h-14 rounded-2xl bg-rose-50 text-rose-500 flex items-center justify-center mb-4">
        <i data-lucide="{{ $icon }}" class="w-6 h-6"></i>
    </span>
    <h3 class="text-base font-semibold text-navy-900">Access Restricted</h3>
    <p class="text-sm text-slate-500 mt-1.5 max-w-sm">
        Your account role does not include permissions for <span class="font-medium text-slate-700">{{ $module }}</span>.
        Contact your Municipal Administrator if you believe this is incorrect.
    </p>
    <div class="flex items-center gap-2.5 mt-5 rounded-xl bg-slate-50 border border-slate-100 px-3.5 py-2.5 text-xs text-slate-500">
        <i data-lucide="user" class="w-3.5 h-3.5 text-slate-400 shrink-0"></i>
        Signed in as <span class="font-medium text-slate-700" x-text="$store.session.account?.name + ' (' + $store.session.account?.role + ')'"></span>
    </div>
</div>
