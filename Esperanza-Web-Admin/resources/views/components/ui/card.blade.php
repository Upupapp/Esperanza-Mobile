@props(['padded' => true, 'hover' => false])

<div {{ $attributes->merge([
        'class' => 'bg-white rounded-2xl border border-slate-100 shadow-card '
            . ($hover ? 'transition-shadow duration-300 hover:shadow-card-hover ' : '')
            . ($padded ? 'p-4' : ''),
    ]) }}
>
    {{ $slot }}
</div>
