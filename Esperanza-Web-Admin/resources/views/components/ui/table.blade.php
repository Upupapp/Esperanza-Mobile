@props(['padded' => false])

<div {{ $attributes->merge(['class' => 'bg-white rounded-2xl border border-slate-100 shadow-card overflow-hidden']) }}>
    <div class="overflow-x-auto scrollbar-thin">
        <table class="w-full text-sm {{ $padded ? 'p-5' : '' }}">
            {{ $slot }}
        </table>
    </div>
</div>
