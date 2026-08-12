@props(['href' => '#', 'icon', 'label', 'labelEn' => null, 'active' => false, 'badge' => null, 'dense' => false, 'moduleKey' => null])

<a
    href="{{ $href }}"
    class="group relative flex items-center rounded-xl font-medium transition-all duration-200
        {{ $dense ? 'gap-2.5 px-3 py-2 text-[13px]' : 'gap-3 px-3.5 py-2.5 text-sm' }}
        {{ $active ? 'bg-brand-600 text-white shadow-[0_4px_14px_-2px_rgba(47,98,245,0.45)]' : 'text-slate-300/90 hover:bg-white/[0.06] hover:text-white' }}"
    :class="collapsed && 'justify-center px-0'"
    :title="collapsed ? (($store.lang.current === 'en' ? @js($labelEn ?? $label) : @js($label))) : ''"
    @if($moduleKey) x-show="$store.session.can('{{ $moduleKey }}')" x-cloak @endif
>
    <i data-lucide="{{ $icon }}" class="{{ $dense ? 'w-4 h-4' : 'w-[18px] h-[18px]' }} shrink-0 {{ $active ? 'text-white' : 'text-slate-400 group-hover:text-white' }} transition-colors"></i>
    <span x-show="!collapsed" x-transition.opacity.duration.150ms class="truncate" x-text="$store.lang.current === 'en' ? @js($labelEn ?? $label) : @js($label)">{{ $label }}</span>
    @if($badge)
        <span x-show="!collapsed" class="ml-auto text-[10px] font-semibold px-1.5 py-0.5 rounded-full {{ $active ? 'bg-white/20 text-white' : 'bg-brand-500/20 text-brand-300' }}">{{ $badge }}</span>
    @endif
</a>
