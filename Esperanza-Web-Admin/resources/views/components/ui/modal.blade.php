@props(['title' => null, 'titleEn' => null, 'maxWidth' => 'md'])

@php
    // Roughly 1.5x the standard Tailwind max-w scale for each named tier.
    $widths = ['sm' => 'max-w-xl', 'md' => 'max-w-2xl', 'lg' => 'max-w-3xl', 'xl' => 'max-w-4xl', '2xl' => 'max-w-5xl', '3xl' => 'max-w-6xl'];
    $w = $widths[$maxWidth] ?? $widths['md'];
@endphp

<template x-teleport="body">
    <div
        x-show="open"
        x-cloak
        x-effect="
            document.body.classList.toggle('overflow-hidden', open);
            document.querySelector('main')?.classList.toggle('overflow-hidden', open);
        "
        style="position: fixed; inset: 0; z-index: 90;"
    >
        <div x-show="open" x-transition.opacity @click="open = false" style="position: absolute; inset: 0;" class="bg-navy-950/60 backdrop-blur-sm"></div>

        <div style="position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%);">
            <div
                x-show="open"
                x-transition:enter="transition ease-out duration-200"
                x-transition:enter-start="opacity-0 scale-95"
                x-transition:enter-end="opacity-100 scale-100"
                @click.outside="open = false"
                style="max-height: 88vh; width: calc(100vw - 2rem);"
                class="relative bg-white rounded-2xl shadow-float {{ $w }} flex flex-col overflow-hidden"
            >
                <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100 shrink-0">
                    <h3 class="text-sm font-semibold text-navy-900" x-text="$store.lang.current === 'en' ? @js($titleEn ?? $title) : @js($title)">{{ $title }}</h3>
                    <button @click="open = false" class="text-slate-400 hover:text-slate-600 transition-colors">
                        <i data-lucide="x" class="w-4 h-4"></i>
                    </button>
                </div>
                <div class="p-5 overflow-y-auto scrollbar-thin">
                    {{ $slot }}
                </div>
                @isset($footer)
                    <div class="flex items-center justify-end gap-2.5 px-5 py-4 border-t border-slate-100 bg-slate-50/60 shrink-0">
                        {{ $footer }}
                    </div>
                @endisset
            </div>
        </div>
    </div>
</template>
