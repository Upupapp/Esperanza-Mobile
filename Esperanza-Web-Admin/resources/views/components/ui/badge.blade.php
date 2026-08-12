@props(['status' => 'Draft'])

@php
    // Universal status system — colors are fixed per status name across the whole platform.
    $styles = [
        'Draft' => ['bg-slate-100 text-slate-600 ring-slate-200', 'bg-slate-400'],
        'Submitted' => ['bg-blue-50 text-blue-700 ring-blue-200', 'bg-blue-500'],
        'Pending Review' => ['bg-amber-50 text-amber-700 ring-amber-200', 'bg-amber-500'],
        'Under Verification' => ['bg-indigo-50 text-indigo-700 ring-indigo-200', 'bg-indigo-500'],
        'Assigned' => ['bg-purple-50 text-purple-700 ring-purple-200', 'bg-purple-500'],
        'Processing' => ['bg-brand-50 text-brand-700 ring-brand-200', 'bg-brand-500'],
        'Waiting Requirements' => ['bg-orange-50 text-orange-700 ring-orange-200', 'bg-orange-500'],
        'Approved' => ['bg-emerald-50 text-emerald-700 ring-emerald-200', 'bg-emerald-500'],
        'Rejected' => ['bg-rose-50 text-rose-700 ring-rose-200', 'bg-rose-500'],
        'Ready for Release' => ['bg-teal-50 text-teal-700 ring-teal-200', 'bg-teal-500'],
        'Released' => ['bg-cyan-50 text-cyan-700 ring-cyan-200', 'bg-cyan-500'],
        'Completed' => ['bg-green-50 text-green-700 ring-green-200', 'bg-green-500'],
        'Cancelled' => ['bg-slate-100 text-slate-500 ring-slate-200', 'bg-slate-400'],
        'Archived' => ['bg-slate-100 text-slate-400 ring-slate-200', 'bg-slate-300'],
    ];

    [$classes, $dot] = $styles[$status] ?? $styles['Draft'];
@endphp

<span {{ $attributes->merge(['class' => "inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ring-1 ring-inset whitespace-nowrap $classes"]) }}>
    <span class="w-1.5 h-1.5 rounded-full {{ $dot }}"></span>
    {{ $status }}
</span>
