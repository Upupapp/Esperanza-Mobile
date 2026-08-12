@props(['fil', 'en'])

<span x-text="$store.lang.current === 'en' ? @js($en) : @js($fil)">{{ $fil }}</span>
