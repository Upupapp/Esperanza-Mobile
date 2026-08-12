@props(['title' => 'Welcome', 'image' => 'esperanza-aerial.jpg', 'fullscreen' => false])
<!DOCTYPE html>
<html lang="en" class="h-full">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title }} — Esperanza Web Platform</title>
    <link rel="icon" href="{{ asset('images/esperanza/esperanza-seal.png') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="h-full font-sans antialiased bg-slate-50 {{ $fullscreen ? 'overflow-hidden' : '' }}">
    <div class="{{ $fullscreen ? 'h-screen overflow-hidden' : 'min-h-screen' }} flex" x-data="{ time: '' }" x-init="setInterval(() => time = new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit' }), 1000)">
        <div class="hidden lg:flex lg:w-[46%] relative overflow-hidden shrink-0">
            <img
                src="{{ asset('images/esperanza/' . $image) }}"
                alt="Municipality of Esperanza"
                class="absolute inset-0 w-full h-full object-cover"
            >
            <div class="absolute inset-0 bg-gradient-to-br from-navy-950/96 via-navy-900/88 to-brand-900/75"></div>
            <div class="absolute inset-0 bg-grid-dots opacity-40"></div>

            <div class="absolute -top-24 -right-24 w-96 h-96 rounded-full bg-brand-500/25 blur-3xl animate-blob-float"></div>
            <div class="absolute bottom-0 -left-16 w-72 h-72 rounded-full bg-gold-400/15 blur-3xl animate-blob-float" style="animation-delay: -4s"></div>

            <div class="relative z-10 flex flex-col justify-between p-12 text-white w-full">
                <div class="flex items-center justify-between animate-fade-up">
                    <div class="flex items-center gap-3">
                        <img src="{{ asset('images/esperanza/esperanza-seal.png') }}" class="w-12 h-12 rounded-full ring-2 ring-white/25 object-cover" alt="Municipal Seal">
                        <div>
                            <p class="font-semibold leading-tight">Municipality of Esperanza</p>
                            <p class="text-xs text-white/60">Province of Masbate</p>
                        </div>
                    </div>
                    <div class="hidden xl:flex items-center gap-1.5 text-[11px] font-mono text-white/50 tabular-nums" x-text="time"></div>
                </div>

                <div class="animate-fade-up" style="animation-delay: 100ms">
                    <p class="font-display text-3xl leading-snug max-w-md">One platform for every resident, family, and frontliner of Esperanza.</p>
                    <p class="text-white/60 text-sm mt-4 max-w-sm">Request documents, follow up assistance programs, and stay informed on municipal announcements — all in one place.</p>
                </div>

                <div class="flex items-center gap-6 text-xs text-white/50 animate-fade-up" style="animation-delay: 200ms">
                    <span>20 Barangays</span>
                    <span class="w-1 h-1 rounded-full bg-white/30"></span>
                    <span>17,500+ Residents</span>
                    <span class="w-1 h-1 rounded-full bg-white/30"></span>
                    <span>LGU Digital Platform</span>
                </div>
            </div>
        </div>

        <div class="relative flex-1 flex items-center justify-center p-5 sm:p-8 {{ $fullscreen ? 'h-full overflow-hidden' : '' }}">
            <div class="absolute top-0 right-0 w-[28rem] h-[28rem] bg-brand-100/60 rounded-full blur-3xl -z-10 translate-x-1/3 -translate-y-1/3"></div>
            <div class="absolute bottom-0 left-0 w-72 h-72 bg-gold-100/50 rounded-full blur-3xl -z-10 -translate-x-1/3 translate-y-1/3"></div>

            <div class="w-full max-w-md animate-fade-up {{ $fullscreen ? 'max-h-full overflow-y-auto scrollbar-thin' : '' }}">
                {{ $slot }}
            </div>
        </div>
    </div>

    <x-ui.toast-container />
</body>
</html>
