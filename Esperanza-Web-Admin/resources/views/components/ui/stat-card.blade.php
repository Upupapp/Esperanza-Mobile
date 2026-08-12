@props([
    'label',
    'labelEn' => null,
    'value' => null,
    'icon',
    'color' => 'brand',
    'sublabel' => null,
    'sublabelEn' => null,
    'trend' => null,
    'trendDirection' => 'up',
    'delay' => 0,
    'valueBind' => null,
    'href' => null,
])

@php
    $colorMap = [
        'brand' => 'bg-brand-50 text-brand-600',
        'green' => 'bg-emerald-50 text-emerald-600',
        'purple' => 'bg-purple-50 text-purple-600',
        'orange' => 'bg-orange-50 text-orange-600',
        'red' => 'bg-rose-50 text-rose-600',
        'gold' => 'bg-gold-50 text-gold-700',
    ];
    $iconClasses = $colorMap[$color] ?? $colorMap['brand'];
    $tag = $href ? 'a' : 'div';
@endphp

<{{ $tag }}
    @if($href) href="{{ $href }}" @endif
    {{ $attributes->merge(['class' => 'group bg-white rounded-2xl border border-slate-100 shadow-card hover:shadow-card-hover transition-all duration-300 p-3.5 animate-fade-up block' . ($href ? ' cursor-pointer hover:-translate-y-0.5' : '')]) }}
    style="animation-delay: {{ $delay }}ms"
>
    <div class="flex items-start justify-between">
        <div class="w-9 h-9 rounded-xl {{ $iconClasses }} flex items-center justify-center transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-3">
            <i data-lucide="{{ $icon }}" class="w-4 h-4"></i>
        </div>
        @if($trend)
            <span class="inline-flex items-center gap-1 text-xs font-medium {{ $trendDirection === 'up' ? 'text-emerald-600' : 'text-rose-600' }}">
                <i data-lucide="{{ $trendDirection === 'up' ? 'trending-up' : 'trending-down' }}" class="w-3.5 h-3.5"></i>
                {{ $trend }}
            </span>
        @elseif($href)
            <i data-lucide="arrow-up-right" class="w-3.5 h-3.5 text-slate-300 transition-all duration-300 group-hover:text-brand-500 group-hover:translate-x-0.5 group-hover:-translate-y-0.5"></i>
        @endif
    </div>
    <p class="mt-2.5 text-xl font-semibold text-navy-900 tabular-nums tracking-tight" @if($valueBind) x-text="{{ $valueBind }}" @endif>{{ $value }}</p>
    <p class="text-xs font-medium text-slate-400 uppercase tracking-wide mt-1" x-text="$store.lang.current === 'en' ? @js($labelEn ?? $label) : @js($label)">{{ $label }}</p>
    @if($sublabel)
        <p class="text-[11px] text-slate-500 mt-0.5" x-text="$store.lang.current === 'en' ? @js($sublabelEn ?? $sublabel) : @js($sublabel)">{{ $sublabel }}</p>
    @endif
</{{ $tag }}>
