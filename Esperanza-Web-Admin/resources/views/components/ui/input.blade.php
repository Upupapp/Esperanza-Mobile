@props([
    'label' => null,
    'name',
    'type' => 'text',
    'icon' => null,
    'error' => null,
    'hint' => null,
])

<div class="w-full">
    @if($label)
        <label for="{{ $name }}" class="block text-sm font-medium text-slate-700 mb-1.5">{{ $label }}</label>
    @endif

    <div class="relative">
        @if($icon)
            <i data-lucide="{{ $icon }}" class="absolute left-3.5 top-1/2 -translate-y-1/2 w-[18px] h-[18px] text-slate-400"></i>
        @endif

        <input
            type="{{ $type }}"
            name="{{ $name }}"
            id="{{ $name }}"
            {{ $attributes->merge([
                'class' => 'w-full rounded-xl border bg-slate-50/60 py-2.5 text-sm text-slate-800 placeholder:text-slate-400 transition-all duration-200 focus:bg-white focus:outline-none focus:ring-4 '
                    . ($error
                        ? 'border-rose-300 focus:border-rose-400 focus:ring-rose-100'
                        : 'border-slate-200 focus:border-brand-400 focus:ring-brand-100')
                    . ' ' . ($icon ? 'pl-10 pr-4' : 'px-4'),
            ]) }}
        >
    </div>

    @if($hint && ! $error)
        <p class="mt-1.5 text-xs text-slate-400">{{ $hint }}</p>
    @endif

    @if($error)
        <p class="mt-1.5 text-xs text-rose-500 flex items-center gap-1">
            <i data-lucide="circle-alert" class="w-3.5 h-3.5"></i>{{ $error }}
        </p>
    @endif
</div>
