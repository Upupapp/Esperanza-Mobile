{{-- Standardized barangay certificate preview — letterhead (barangay seal +
     municipal seal) plus the legal template for whichever document is
     selected, with blanks live-bound to the citizen's typed form values.
     Every prop here is an Alpine expression string (not a PHP value) — the
     selected document AND its originating barangay both change at runtime
     as more barangays get onboarded, so nothing here can be server-rendered
     once. --}}
@props(['docKey', 'bind', 'title', 'subtitle', 'barangay', 'seal', 'punongBarangay', 'barangaySecretary'])

<div class="rounded-2xl border-2 border-slate-200 bg-white p-6 shadow-inner-sm relative overflow-hidden" style="font-family: Georgia, 'Times New Roman', serif;">
    <div class="absolute inset-0 bg-[radial-gradient(circle_at_center,theme(colors.slate.100),transparent_70%)] opacity-40 pointer-events-none"></div>

    <!-- Letterhead -->
    <div class="relative flex items-center justify-between gap-3 mb-4">
        <div class="relative w-16 h-16 shrink-0">
            <div class="absolute inset-0 rounded-full bg-slate-50 border-2 border-gold-400 flex items-center justify-center text-slate-300">
                <i data-lucide="landmark" class="w-6 h-6"></i>
            </div>
            <img
                :src="{{ $seal }} ? '{{ rtrim(asset(''), '/') }}/' + {{ $seal }} : ''"
                x-show="{{ $seal }}" onerror="this.style.display='none'" alt="Barangay Seal"
                class="relative w-16 h-16 rounded-full object-cover border-2 border-gold-400"
            >
        </div>
        <div class="text-center flex-1 min-w-0">
            <p class="text-[11px] text-slate-500">Republic of the Philippines</p>
            <p class="text-xs font-semibold text-slate-700">PROVINCE OF MASBATE</p>
            <p class="text-xs text-slate-600">Municipality of Esperanza</p>
            <p class="text-sm font-bold text-navy-900 uppercase tracking-wide">Barangay <span x-text="{{ $barangay }}"></span></p>
        </div>
        <div class="relative w-16 h-16 shrink-0">
            <div class="absolute inset-0 rounded-full bg-slate-50 border-2 border-gold-400 flex items-center justify-center text-slate-300">
                <i data-lucide="shield" class="w-6 h-6"></i>
            </div>
            <img src="{{ asset('images/esperanza/esperanza-seal.png') }}" alt="Municipality of Esperanza Seal" onerror="this.style.display='none'" class="relative w-16 h-16 rounded-full object-cover border-2 border-gold-400">
        </div>
    </div>

    <div class="relative text-center mb-5">
        <h3 class="text-lg font-bold text-navy-900 uppercase tracking-wide underline decoration-2 underline-offset-4" x-text="{{ $title }}"></h3>
        <p class="text-xs font-medium text-slate-500 mt-1" x-show="{{ $subtitle }}" x-text="{{ $subtitle }}"></p>
    </div>

    <div class="relative text-[13px] leading-relaxed text-slate-800 space-y-3">
        <p class="font-semibold">TO WHOM IT MAY CONCERN:</p>

        <!-- Registration of Death -->
        <template x-if="{{ $docKey }} === 'brgy_cert_death_registration'">
            <div class="space-y-2.5">
                <p>This is to certify that <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.subject_name || '_______________________'"></span>, is a bonafide resident of this barangay.</p>
                <p>This further certifies for the other information of this person to wit:</p>
                <div class="grid grid-cols-2 gap-x-4 gap-y-2 text-xs pl-2">
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Name of Father:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.father_name || ' '"></span></p>
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Name of Mother (Maiden):</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.mother_name || ' '"></span></p>
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Date of Death:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.date_of_death || ' '"></span></p>
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Place of Death:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.place_of_death || ' '"></span></p>
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Civil Status:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.civil_status || ' '"></span></p>
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Religion:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.religion || ' '"></span></p>
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Citizenship:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.citizenship || ' '"></span></p>
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Sex:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.sex || ' '"></span></p>
                </div>
                <p>Issued upon request of the interested party for the <span class="font-semibold">REGISTRATION of Death</span> and for whatever legal purposes this will serve him/her best.</p>
            </div>
        </template>

        <!-- Late Registration -->
        <template x-if="{{ $docKey }} === 'brgy_cert_late_registration'">
            <div class="space-y-2.5">
                <p>This is to certify that <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.subject_name || '_______________________'"></span>, is a bonafide resident of this barangay.</p>
                <p>This further certifies for the other information of this person to wit:</p>
                <div class="grid grid-cols-2 gap-x-4 gap-y-2 text-xs pl-2">
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Name of Father:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.father_name || ' '"></span></p>
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Name of Mother (Maiden):</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.mother_name || ' '"></span></p>
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Date of Birth:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.date_of_birth || ' '"></span></p>
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Place of Birth:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.place_of_birth || ' '"></span></p>
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Sex:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.sex || ' '"></span></p>
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Citizenship:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.citizenship || ' '"></span></p>
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Civil Status:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.civil_status || ' '"></span></p>
                    <p class="flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Occupation:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.occupation || ' '"></span></p>
                    <p class="col-span-2 flex items-baseline gap-1.5"><span class="text-slate-500 shrink-0">Name of Husband/Wife (if married):</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.spouse_name || ' '"></span></p>
                </div>
                <p>Issued upon request of the herein interested party for the <span class="font-semibold">LATE REGISTRATION of Birth</span> at the Municipal Registry Office of Esperanza, Masbate.</p>
                <div class="flex items-center gap-6 pt-2 text-[10px] text-slate-400">
                    <span class="border border-slate-300 rounded px-4 py-3">Right Thumbmark</span>
                    <span class="border border-slate-300 rounded px-4 py-3">Left Thumbmark</span>
                    <span class="border border-slate-300 rounded px-6 py-3">Picture</span>
                </div>
            </div>
        </template>

        <!-- Business Clearance -->
        <template x-if="{{ $docKey }} === 'brgy_business_clearance'">
            <div class="space-y-2.5">
                <p>
                    This is to certify that <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.applicant_name || '_______________________'"></span>,
                    <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.age || '___'"></span> years of age, having engaged in a business of
                    <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.business_type || '_______________'"></span>, for almost
                    <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.years_operating || '___'"></span> years located at Purok
                    <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.purok || '___'"></span>, Barangay <span x-text="{{ $barangay }}"></span>, Esperanza, Masbate
                    with the capital of ( <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.capital_figures || '_______'"></span> )
                    ( <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.capital_words || '_______________________'"></span> ).
                </p>
                <p>This is Non-Transferrable, and shall be null and void, upon failure of the aforementioned applicant to strictly comply with the conditions of this clearance.</p>
                <p>This clearance is being issued upon request of the interested party for identification and whatever legal purposes it may serve.</p>
            </div>
        </template>

        <!-- Residency -->
        <template x-if="{{ $docKey }} === 'brgy_residency'">
            <div class="space-y-2.5">
                <p>
                    This is to certify that <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.requester_name || '_______________________'"></span>,
                    <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.age || '___'"></span> of legal age, is a
                    <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="({{ $bind }}.residency_type || 'permanent').toLowerCase()"></span> bonafide resident of Purok
                    <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.purok || '___'"></span>, Barangay <span x-text="{{ $barangay }}"></span>, Esperanza, Masbate.
                </p>
                <p>He/She has no pending case/complaint against him/her as per record of this office. He/She has no derogatory record file in this office.</p>
                <p>This certification is being issued upon the request of aforementioned name for:</p>
                <p class="pl-2 text-xs font-semibold underline decoration-dotted underline-offset-2 inline-block" x-text="(({{ $bind }}.purpose || []).join(', ') || '_______________________')"></p>
            </div>
        </template>

        <!-- First Time Jobseeker -->
        <template x-if="{{ $docKey }} === 'brgy_first_time_jobseeker'">
            <div class="space-y-2.5">
                <p>
                    This is to certify that <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.requester_name || '_______________________'"></span>,
                    a bonafide resident of Purok <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.purok || '___'"></span>, Barangay <span x-text="{{ $barangay }}"></span>, Esperanza, Masbate,
                    <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.age || '___'"></span> years of age, is a qualified availee of
                    <span class="font-semibold">RA 11261</span> or the First Time Jobseekers Assistance Act of 2019.
                </p>
                <p>This certifies that the holder/bearer was informed of their rights, including the duties and responsibilities accorded by RA 11261, through the Oath of Understanding signed and executed in the presence of Barangay Officials.</p>
            </div>
        </template>

        <!-- Indigency -->
        <template x-if="{{ $docKey }} === 'brgy_indigency'">
            <div class="space-y-2.5">
                <p>
                    This is to certify that <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.requester_name || '_______________________'"></span>,
                    <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.age || '___'"></span> years of age, is a
                    <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="({{ $bind }}.residency_type || 'permanent').toLowerCase()"></span> resident of Purok
                    <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.purok || '___'"></span>, Barangay <span x-text="{{ $barangay }}"></span>, Esperanza, Masbate, for:
                </p>
                <p class="pl-2 text-xs font-semibold underline decoration-dotted underline-offset-2 inline-block" x-text="(({{ $bind }}.purpose || []).join(', ') || '_______________________')"></p>
                <p>The way of life of the family is a hand-to-mouth existence, meaning they belong to below poverty line. Further certified that he/she has no pending case/complaint, no derogatory record on file against him/her as per record of this office.</p>
            </div>
        </template>

        <p class="text-[11px] text-slate-400 pt-1" x-show="{{ $bind }}.__validity" x-text="{{ $bind }}.__validity"></p>
    </div>

    <!-- Signatures -->
    <div class="relative flex items-end justify-between mt-8 pt-4">
        <div class="text-center">
            <div class="w-40 border-b border-slate-400 mb-1"></div>
            <p class="text-[10px] text-slate-500">Signature over Printed Name of the Requester</p>
        </div>
        <div class="text-center">
            <p class="text-sm font-bold text-navy-900 uppercase" x-text="({{ $punongBarangay }}) || 'Hon. Punong Barangay'"></p>
            <p class="text-[10px] text-slate-500">Punong Barangay</p>
        </div>
    </div>
    <div class="relative mt-4 text-[11px] text-slate-500" x-show="{{ $barangaySecretary }}">
        Released by: <span class="font-semibold text-slate-700" x-text="{{ $barangaySecretary }}"></span> — Barangay Secretary
    </div>

    <p class="relative text-center text-[10px] italic text-slate-400 mt-5">Not Valid without Barangay Seal</p>
</div>
