@props(['text'])

<span x-data="{ show: false }" class="relative inline-flex items-center" @mouseenter="show = true" @mouseleave="show = false" @click="show = !show">
    {{ $slot }}
    <span
        x-show="show"
        x-transition.opacity.duration.150ms
        x-cloak
        class="absolute z-50 bottom-full left-1/2 -translate-x-1/2 mb-2 w-max max-w-[220px] px-2.5 py-1.5 rounded-lg bg-navy-900 text-white text-[11px] leading-snug shadow-float text-center"
    >{{ $text }}</span>
</span>
