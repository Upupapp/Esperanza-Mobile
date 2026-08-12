@props([
    'variant' => 'primary',
    'size' => 'md',
    'href' => null,
    'icon' => null,
    'iconPosition' => 'left',
    'type' => 'button',
])

@php
    $base = 'inline-flex items-center justify-center gap-2 font-medium rounded-xl transition-all duration-200 ease-out select-none focus:outline-none focus-visible:ring-4 active:scale-[0.97] disabled:opacity-50 disabled:pointer-events-none';

    $sizes = [
        'sm' => 'px-3.5 py-2 text-xs',
        'md' => 'px-4.5 py-2.5 text-sm',
        'lg' => 'px-6 py-3.5 text-sm',
    ];

    $variants = [
        'primary' => 'btn-shine bg-gradient-to-b from-brand-500 to-brand-600 text-white shadow-card hover:shadow-card-hover focus-visible:ring-brand-100',
        'secondary' => 'bg-white text-slate-700 border border-slate-200 shadow-card hover:bg-slate-50 hover:border-slate-300 focus-visible:ring-slate-100',
        'ghost' => 'bg-transparent text-slate-500 hover:bg-slate-100 hover:text-slate-700 focus-visible:ring-slate-100',
        'danger' => 'bg-rose-600 text-white shadow-card hover:bg-rose-700 focus-visible:ring-rose-100',
        'gold' => 'btn-shine bg-gradient-to-b from-gold-400 to-gold-500 text-navy-950 shadow-card hover:from-gold-300 hover:to-gold-400 focus-visible:ring-gold-100',
    ];

    $classes = $base . ' ' . ($sizes[$size] ?? $sizes['md']) . ' ' . ($variants[$variant] ?? $variants['primary']);
    $iconSize = $size === 'lg' ? 'w-[18px] h-[18px]' : 'w-4 h-4';
@endphp

@if($href)
    <a href="{{ $href }}" {{ $attributes->merge(['class' => $classes]) }}>
        @if($icon && $iconPosition === 'left')
            <i data-lucide="{{ $icon }}" class="{{ $iconSize }} shrink-0"></i>
        @endif
        <span>{{ $slot }}</span>
        @if($icon && $iconPosition === 'right')
            <i data-lucide="{{ $icon }}" class="{{ $iconSize }} shrink-0"></i>
        @endif
    </a>
@else
    <button type="{{ $type }}" {{ $attributes->merge(['class' => $classes]) }}>
        @if($icon && $iconPosition === 'left')
            <i data-lucide="{{ $icon }}" class="{{ $iconSize }} shrink-0"></i>
        @endif
        <span>{{ $slot }}</span>
        @if($icon && $iconPosition === 'right')
            <i data-lucide="{{ $icon }}" class="{{ $iconSize }} shrink-0"></i>
        @endif
    </button>
@endif
