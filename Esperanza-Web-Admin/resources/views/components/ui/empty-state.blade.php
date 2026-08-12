@props(['icon' => 'inbox', 'title' => 'Nothing here yet', 'description' => null])

<div {{ $attributes->merge(['class' => 'flex flex-col items-center justify-center text-center py-14 px-6 animate-fade-in']) }}>
    <div class="w-16 h-16 rounded-2xl bg-slate-100 flex items-center justify-center mb-4">
        <i data-lucide="{{ $icon }}" class="w-7 h-7 text-slate-400"></i>
    </div>
    <h3 class="text-sm font-semibold text-slate-700">{{ $title }}</h3>
    @if($description)
        <p class="text-sm text-slate-400 mt-1 max-w-sm">{{ $description }}</p>
    @endif
    @isset($slot)
        <div class="mt-5">{{ $slot }}</div>
    @endisset
</div>
