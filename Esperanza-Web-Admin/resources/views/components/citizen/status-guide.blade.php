@php
    $statuses = [
        ['name' => 'Submitted', 'desc' => 'We received your request. It is now in the queue.'],
        ['name' => 'Pending Review', 'desc' => 'Staff are checking your details and requirements.'],
        ['name' => 'Under Verification', 'desc' => "We're verifying your documents or eligibility."],
        ['name' => 'Waiting Requirements', 'desc' => 'Something is still needed from you — check the details.'],
        ['name' => 'Processing', 'desc' => 'Your request is approved and being prepared.'],
        ['name' => 'Approved', 'desc' => 'Your request has been approved.'],
        ['name' => 'Ready for Release', 'desc' => 'It is ready — you may claim it at the office.'],
        ['name' => 'Released', 'desc' => 'It has been handed over to you.'],
        ['name' => 'Completed', 'desc' => 'This request is fully done.'],
        ['name' => 'Rejected', 'desc' => 'This request was not approved. Check the reason and resubmit if needed.'],
    ];
@endphp

<div x-data="{ open: false }" class="contents">
    <button
        type="button"
        @click="open = true"
        class="inline-flex items-center gap-1 text-xs font-medium text-slate-400 hover:text-brand-600 transition-colors"
    ><i data-lucide="circle-question-mark" class="w-3.5 h-3.5"></i>What do these statuses mean?</button>

    <x-ui.modal title="Status Guide" maxWidth="sm">
        <p class="text-sm text-slate-500 mb-4">Here's what each status means for your request.</p>
        <div class="space-y-3">
            @foreach($statuses as $s)
                <div class="flex items-start gap-3">
                    <x-ui.badge :status="$s['name']" class="shrink-0 mt-0.5" />
                    <p class="text-xs text-slate-500 leading-snug pt-1">{{ $s['desc'] }}</p>
                </div>
            @endforeach
        </div>
        <x-slot:footer>
            <x-ui.button size="sm" @click="open = false">Got it</x-ui.button>
        </x-slot:footer>
    </x-ui.modal>
</div>
