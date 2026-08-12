@props(['title' => 'Dashboard', 'subtitle' => null, 'active' => 'dashboard'])
@php
    // Lightweight per-barangay directory (label, seal, officials, contact —
    // no document templates) available everywhere in the Citizen Portal via
    // $store.barangay, so any page can show the signed-in citizen's own
    // barangay branding without re-fetching the full Dokyu catalog.
    $barangayCatalog = [];
    foreach (config('esperanza_barangay_documents') as $b) {
        $barangayCatalog[$b['label']] = [
            'label' => $b['label'],
            'seal' => $b['seal'],
            'officials' => $b['officials'],
            'contact' => $b['contact'] ?? null,
        ];
    }
@endphp
<!DOCTYPE html>
<html lang="en" class="h-full">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title }} — Esperanza Citizen Portal</title>
    <link rel="icon" href="{{ asset('images/esperanza/esperanza-seal.png') }}">
    <script>
        window.__barangayCatalog = @json($barangayCatalog);
    </script>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="h-full font-sans antialiased">
    <div class="flex h-screen overflow-hidden bg-slate-50" x-data="{ collapsed: false, mobileOpen: false }">
        <x-citizen.sidebar :active="$active" />

        <div class="flex-1 flex flex-col min-w-0">
            <x-citizen.topbar :title="$title" :subtitle="$subtitle" :active="$active" />

            <main class="flex-1 overflow-y-auto scrollbar-thin p-4 lg:p-6">
                {{ $slot }}
            </main>
        </div>
    </div>

    <x-ui.toast-container />
    <x-citizen.birthday-popup />
    <x-citizen.fiesta-popup />
</body>
</html>
