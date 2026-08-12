@props(['id', 'icon' => 'sparkles', 'title', 'titleEn' => null, 'color' => 'brand'])

@php
    $colorMap = [
        'brand' => ['border-brand-100', 'bg-brand-50/60', 'text-brand-600'],
        'purple' => ['border-purple-100', 'bg-purple-50/60', 'text-purple-600'],
        'gold' => ['border-gold-200', 'bg-gold-50/60', 'text-gold-700'],
    ];
    [$border, $bg, $iconColor] = $colorMap[$color] ?? $colorMap['brand'];
@endphp

<div
    x-data="{
        show: false,
        init() { this.show = !localStorage.getItem('esperanza_intro_{{ $id }}'); },
        dismiss() { this.show = false; localStorage.setItem('esperanza_intro_{{ $id }}', '1'); },
    }"
    x-show="show"
    x-cloak
    x-transition
    class="relative flex items-start gap-3 rounded-2xl border {{ $border }} {{ $bg }} px-4 py-3.5 mb-4"
>
    <span class="w-8 h-8 rounded-xl bg-white {{ $iconColor }} flex items-center justify-center shrink-0 shadow-card">
        <i data-lucide="{{ $icon }}" class="w-4 h-4"></i>
    </span>
    <div class="min-w-0 flex-1">
        <p class="text-sm font-medium text-navy-900" x-text="$store.lang.current === 'en' ? @js($titleEn ?? $title) : @js($title)">{{ $title }}</p>
        <p class="text-xs text-slate-500 mt-0.5 leading-relaxed">{{ $slot }}</p>
    </div>
    <button @click="dismiss()" class="text-slate-400 hover:text-slate-600 shrink-0 transition-colors" aria-label="Dismiss">
        <i data-lucide="x" class="w-4 h-4"></i>
    </button>
</div>
