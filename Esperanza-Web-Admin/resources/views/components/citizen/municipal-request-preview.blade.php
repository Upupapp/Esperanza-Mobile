{{-- Municipal document request-slip preview — this represents the CITIZEN'S
     REQUEST, not the final certificate itself (only the Civil Registrar /
     issuing office can produce that, after verifying it against the actual
     civil registry). Section layout recreates the real PSA/LCRO Municipal
     Form's boxed grid (Child/Mother/Father cells for Form 102, Husband/Wife
     cells for Form 97, bulleted blanks for the Pet Registration Form) with
     the citizen's typed answers sitting directly inside each box/blank —
     the same way the value would sit inside the box if the paper form were
     filled out by hand — instead of an external "label: value" summary.
     `docKey` / `bind` / `title` / `office` / etc. are Alpine expression
     strings since the selected document changes at runtime. --}}
@props(['docKey', 'bind', 'title', 'office', 'formNo' => null, 'officiant' => null, 'officiantTitle' => null, 'technician' => null, 'technicianTitle' => null, 'verifier' => null, 'verifierTitle' => null])

<div class="rounded-2xl border-2 border-slate-200 bg-white p-6 shadow-inner-sm relative overflow-hidden" style="font-family: Georgia, 'Times New Roman', serif;">
    <div class="absolute inset-0 bg-[radial-gradient(circle_at_center,theme(colors.slate.100),transparent_70%)] opacity-40 pointer-events-none"></div>

    <!-- Letterhead -->
    <div class="relative flex items-center gap-3 mb-4">
        <div class="relative w-14 h-14 shrink-0">
            <div class="absolute inset-0 rounded-full bg-slate-50 border-2 border-gold-400 flex items-center justify-center text-slate-300">
                <i data-lucide="shield" class="w-6 h-6"></i>
            </div>
            <img src="{{ asset('images/esperanza/esperanza-seal.png') }}" alt="Municipality of Esperanza Seal" onerror="this.style.display='none'" class="relative w-14 h-14 rounded-full object-cover border-2 border-gold-400">
        </div>
        <div class="min-w-0 flex-1">
            <p class="text-[11px] text-slate-500">Republic of the Philippines · Province of Masbate</p>
            <p class="text-xs font-semibold text-slate-700 uppercase tracking-wide">Municipality of Esperanza</p>
            <p class="text-sm font-bold text-navy-900" x-text="{{ $office }}"></p>
        </div>
        <div class="text-right shrink-0">
            <span class="inline-flex items-center gap-1.5 text-[10px] font-semibold text-brand-700 bg-brand-50 border border-brand-100 rounded-full px-2.5 py-1">
                <i data-lucide="file-text" class="w-3 h-3"></i> Request Slip
            </span>
            <p class="text-[10px] text-slate-400 mt-1" x-show="{{ $formNo }}" x-text="{{ $formNo }}"></p>
        </div>
    </div>

    <div class="relative text-center mb-5">
        <h3 class="text-base font-bold text-navy-900 uppercase tracking-wide underline decoration-2 underline-offset-4" x-text="{{ $title }}"></h3>
    </div>

    <div class="relative text-[13px] text-slate-800 space-y-4">
        <!-- Certificate of Marriage: Husband / Wife boxed grid, matching Municipal Form No. 97 -->
        <template x-if="{{ $docKey }} === 'mcro_marriage'">
            <div class="space-y-3">
                <p class="text-xs"><span class="text-slate-500">Requester:</span> <span class="font-medium" x-text="{{ $bind }}.requester_name || '—'"></span> <span class="text-slate-400">(<span x-text="{{ $bind }}.relationship || '—'"></span>)</span></p>
                <div class="border border-slate-300 rounded-sm overflow-hidden">
                    <div class="grid grid-cols-2 divide-x divide-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Husband</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.husband_name || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Wife</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.wife_name || ' '"></p>
                        </div>
                    </div>
                    <div class="grid grid-cols-2 divide-x divide-slate-300 border-t border-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Date of Marriage</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.date_of_marriage || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Place of Marriage</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.place_of_marriage || ' '"></p>
                        </div>
                    </div>
                    <div class="px-3 py-2 border-t border-slate-300">
                        <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Registration Status</p>
                        <p class="font-medium" x-text="{{ $bind }}.is_delayed || ' '"></p>
                    </div>
                </div>
            </div>
        </template>

        <!-- Application for Marriage License: Groom / Bride boxed grid, matching Municipal Form No. 90 -->
        <template x-if="{{ $docKey }} === 'mcro_marriage_license'">
            <div class="space-y-3">
                <div class="border border-slate-300 rounded-sm overflow-hidden">
                    <div class="grid grid-cols-2 divide-x divide-slate-300">
                        <p class="text-[8px] font-bold uppercase tracking-wider text-white bg-navy-800 px-3 py-1">Groom</p>
                        <p class="text-[8px] font-bold uppercase tracking-wider text-white bg-navy-800 px-3 py-1 border-l border-navy-700">Bride</p>
                    </div>
                    <div class="grid grid-cols-2 divide-x divide-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Full Name</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.groom_name || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Full Name</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.bride_name || ' '"></p>
                        </div>
                    </div>
                    <div class="grid grid-cols-2 divide-x divide-slate-300 border-t border-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Date of Birth</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.groom_dob || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Date of Birth</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.bride_dob || ' '"></p>
                        </div>
                    </div>
                    <div class="grid grid-cols-2 divide-x divide-slate-300 border-t border-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Citizenship</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.groom_citizenship || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Citizenship</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.bride_citizenship || ' '"></p>
                        </div>
                    </div>
                    <div class="grid grid-cols-2 divide-x divide-slate-300 border-t border-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Residence</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.groom_residence || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Residence</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.bride_residence || ' '"></p>
                        </div>
                    </div>
                    <div class="grid grid-cols-2 divide-x divide-slate-300 border-t border-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Civil Status</p>
                            <p class="font-medium" x-text="{{ $bind }}.groom_civil_status || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Civil Status</p>
                            <p class="font-medium" x-text="{{ $bind }}.bride_civil_status || ' '"></p>
                        </div>
                    </div>
                </div>
                <p class="text-xs px-1"><span class="text-slate-500">Consent/Advice Given By:</span> <span class="font-medium" x-text="{{ $bind }}.consent_person || '—'"></span></p>
            </div>
        </template>

        <!-- Certificate of Live Birth: Child / Mother / Father boxed grid, matching Municipal Form No. 102 -->
        <template x-if="{{ $docKey }} === 'mcro_live_birth'">
            <div class="space-y-3">
                <div class="border border-slate-300 rounded-sm overflow-hidden">
                    <p class="text-[8px] font-bold uppercase tracking-wider text-white bg-navy-800 px-3 py-1">Child</p>
                    <div class="px-3 py-2 border-b border-slate-300">
                        <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Name</p>
                        <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.child_name || ' '"></p>
                    </div>
                    <div class="grid grid-cols-3 divide-x divide-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Sex</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.sex || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Date of Birth</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.date_of_birth || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Place of Birth</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.place_of_birth || ' '"></p>
                        </div>
                    </div>
                </div>
                <div class="border border-slate-300 rounded-sm overflow-hidden">
                    <p class="text-[8px] font-bold uppercase tracking-wider text-white bg-navy-800 px-3 py-1">Mother</p>
                    <div class="grid grid-cols-2 divide-x divide-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Maiden Name</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.mother_maiden_name || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Citizenship</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.mother_citizenship || ' '"></p>
                        </div>
                    </div>
                </div>
                <div class="border border-slate-300 rounded-sm overflow-hidden">
                    <p class="text-[8px] font-bold uppercase tracking-wider text-white bg-navy-800 px-3 py-1">Father</p>
                    <div class="grid grid-cols-2 divide-x divide-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Full Name</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.father_name || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Citizenship</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.father_citizenship || ' '"></p>
                        </div>
                    </div>
                </div>
                <div class="grid grid-cols-2 gap-x-4 text-xs px-1">
                    <p><span class="text-slate-500">Requester:</span> <span class="font-medium" x-text="{{ $bind }}.requester_relationship || '—'"></span></p>
                    <p><span class="text-slate-500">Status:</span> <span class="font-medium" x-text="{{ $bind }}.is_delayed || '—'"></span></p>
                </div>

                <!-- Muslim Attachment (Municipal Form No. 102, attachment) — only shown once any of its fields are filled -->
                <div
                    class="border border-slate-300 rounded-sm overflow-hidden"
                    x-show="{{ $bind }}.ethnicity_father || {{ $bind }}.ethnicity_mother || {{ $bind }}.dob_hijrah"
                    x-cloak
                >
                    <p class="text-[8px] font-bold uppercase tracking-wider text-white bg-navy-800 px-3 py-1">Muslim Attachment</p>
                    <div class="grid grid-cols-2 divide-x divide-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Ethnicity of Father</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.ethnicity_father || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Ethnicity of Mother</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.ethnicity_mother || ' '"></p>
                        </div>
                    </div>
                    <div class="px-3 py-2 border-t border-slate-300">
                        <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Date of Birth — Hijrah Calendar</p>
                        <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.dob_hijrah || ' '"></p>
                    </div>
                </div>
            </div>
        </template>

        <!-- Certificate of Death: Deceased boxed grid, matching Municipal Form No. 103 -->
        <template x-if="{{ $docKey }} === 'mcro_death'">
            <div class="space-y-3">
                <div class="border border-slate-300 rounded-sm overflow-hidden">
                    <p class="text-[8px] font-bold uppercase tracking-wider text-white bg-navy-800 px-3 py-1">Deceased</p>
                    <div class="px-3 py-2 border-b border-slate-300">
                        <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Name</p>
                        <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.deceased_name || ' '"></p>
                    </div>
                    <div class="grid grid-cols-3 divide-x divide-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Sex</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.sex || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Date of Death</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.date_of_death || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Place of Death</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.place_of_death || ' '"></p>
                        </div>
                    </div>
                    <div class="grid grid-cols-2 divide-x divide-slate-300 border-t border-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Date of Birth</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.date_of_birth || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Civil Status</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.civil_status || ' '"></p>
                        </div>
                    </div>
                    <div class="grid grid-cols-2 divide-x divide-slate-300 border-t border-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Citizenship</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.citizenship || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Residence</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.residence || ' '"></p>
                        </div>
                    </div>
                    <div class="grid grid-cols-2 divide-x divide-slate-300 border-t border-slate-300">
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Name of Father</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.father_name || ' '"></p>
                        </div>
                        <div class="px-3 py-2">
                            <p class="text-[8px] font-semibold uppercase tracking-wider text-slate-400">Mother's Maiden Name</p>
                            <p class="font-medium border-b border-slate-300 pb-1 min-h-[1.4rem]" x-text="{{ $bind }}.mother_maiden_name || ' '"></p>
                        </div>
                    </div>
                </div>
                <div class="grid grid-cols-2 gap-x-4 text-xs px-1">
                    <p><span class="text-slate-500">Requester:</span> <span class="font-medium" x-text="{{ $bind }}.requester_relationship || '—'"></span></p>
                    <p><span class="text-slate-500">Status:</span> <span class="font-medium" x-text="{{ $bind }}.is_delayed || '—'"></span></p>
                </div>
            </div>
        </template>

        <!-- Delayed Registration: sworn-affidavit format, matching the real "Affidavit for Delayed Registration" -->
        <template x-if="{{ $docKey }} === 'mcro_delayed_registration'">
            <div class="space-y-3">
                <p class="text-xs text-slate-500">Republic of the Philippines · Municipality of Esperanza</p>
                <p class="leading-relaxed">
                    That I am the applicant for the delayed registration of
                    <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.registration_type || '_______'"></span> of
                    <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.subject_name || '_______________________'"></span>,
                    to whom I am the <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.applicant_relationship || '_______'"></span>.
                </p>
                <p class="leading-relaxed">That the reason for the delay in registering this event was
                    <span class="font-semibold underline decoration-dotted underline-offset-2" x-text="{{ $bind }}.reason_for_delay || '_______________________'"></span>.
                </p>
                <p class="leading-relaxed">That I am executing this affidavit to attest to the truthfulness of the foregoing statements for all legal intents and purposes.</p>
            </div>
        </template>

        <!-- Pet Registration: bulleted label + blank, matching the real Pet Registration Form layout -->
        <template x-if="{{ $docKey }} === 'municipal_pet_registration'">
            <div class="space-y-4 text-xs">
                <div>
                    <p class="text-[10px] font-bold uppercase tracking-wider text-navy-900 mb-1.5">Owner Information</p>
                    <ul class="space-y-1.5">
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Full Name:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.owner_name || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Address:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.address || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Phone Number:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.phone || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Email Address:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.email || ' '"></span></li>
                    </ul>
                </div>
                <div>
                    <p class="text-[10px] font-bold uppercase tracking-wider text-navy-900 mb-1.5">Pet Information</p>
                    <ul class="space-y-1.5">
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Pet's Name:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.pet_name || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Species:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.species || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Breed:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.breed || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Color/Markings:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.color_markings || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Gender:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.gender || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Date of Birth / Age:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.pet_dob || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Microchip Number:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.microchip_number || ' '"></span></li>
                    </ul>
                </div>
                <div>
                    <p class="text-[10px] font-bold uppercase tracking-wider text-navy-900 mb-1.5">Vaccination &amp; Care</p>
                    <ul class="space-y-1.5">
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Last Rabies Vaccination:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.last_rabies_vaccination || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Other Vaccinations:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.other_vaccinations || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Spayed / Neutered:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.spay_neuter || ' '"></span></li>
                    </ul>
                </div>
                <div>
                    <p class="text-[10px] font-bold uppercase tracking-wider text-navy-900 mb-1.5">Emergency Contact</p>
                    <ul class="space-y-1.5">
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Name:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.emergency_contact_name || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Phone Number:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.emergency_contact_phone || ' '"></span></li>
                    </ul>
                </div>
            </div>
        </template>

        <!-- PWD ID (PRPWD Application): sectioned label + blank, matching the DOH PRPWD v3.0 form -->
        <template x-if="{{ $docKey }} === 'msw_pwd_id'">
            <div class="space-y-4 text-xs">
                <div>
                    <p class="text-[10px] font-bold uppercase tracking-wider text-navy-900 mb-1.5">Personal Information</p>
                    <ul class="space-y-1.5">
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Full Name:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.full_name || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Date of Birth:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.date_of_birth || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Sex:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.sex || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Civil Status:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.civil_status || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Religion:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.religion || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Blood Type:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.blood_type || ' '"></span></li>
                    </ul>
                </div>
                <div>
                    <p class="text-[10px] font-bold uppercase tracking-wider text-navy-900 mb-1.5">Disability Information</p>
                    <ul class="space-y-1.5">
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Type of Disability:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="({{ $bind }}.type_of_disability || []).join(', ') || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Cause of Disability:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="({{ $bind }}.cause_of_disability || []).join(', ') || ' '"></span></li>
                    </ul>
                </div>
                <div>
                    <p class="text-[10px] font-bold uppercase tracking-wider text-navy-900 mb-1.5">Residence &amp; Employment</p>
                    <ul class="space-y-1.5">
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Address:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.residence_address || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Educational Attainment:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.educational_attainment || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Employment Status:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.employment_status || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Occupation:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.occupation || ' '"></span></li>
                    </ul>
                </div>
                <div>
                    <p class="text-[10px] font-bold uppercase tracking-wider text-navy-900 mb-1.5">ID Reference Numbers</p>
                    <ul class="space-y-1.5">
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">SSS No.:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.sss_no || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">GSIS No.:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.gsis_no || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Pag-IBIG No.:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.pagibig_no || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">PhilHealth No.:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.philhealth_no || ' '"></span></li>
                    </ul>
                </div>
                <div>
                    <p class="text-[10px] font-bold uppercase tracking-wider text-navy-900 mb-1.5">Family Background</p>
                    <ul class="space-y-1.5">
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Father's Name:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.father_name || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Mother's Name:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.mother_name || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Guardian's Name:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.guardian_name || ' '"></span></li>
                    </ul>
                </div>
            </div>
        </template>

        <!-- Senior Citizen ID (OSCA Membership): bulleted label + blank, matching the real OSCA Application for Membership -->
        <template x-if="{{ $docKey }} === 'osca_senior_citizen'">
            <div class="space-y-4 text-xs">
                <div>
                    <ul class="space-y-1.5">
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Name:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.full_name || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Birthdate:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.birthdate || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Birthplace:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.birthplace || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Address (Brgy./Sitio):</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.address_purok || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Sex:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.sex || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Age:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.age || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Marital Status:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.marital_status || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Educational Attainment:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.educational_attainment || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Present Occupation:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.present_occupation || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Annual Income:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.annual_income || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Pension:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.pension || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">PhilSys ID No.:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.philsys_id || ' '"></span></li>
                    </ul>
                </div>
                <div>
                    <p class="text-[10px] font-bold uppercase tracking-wider text-navy-900 mb-1.5">Last Government Service</p>
                    <ul class="space-y-1.5">
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Office:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.last_govt_office || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Year:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.last_govt_year || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Address:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.last_govt_address || ' '"></span></li>
                        <li class="flex items-baseline gap-2"><span class="text-slate-500 shrink-0">Position/Designation:</span><span class="flex-1 font-medium border-b border-dotted border-slate-400" x-text="{{ $bind }}.last_govt_position || ' '"></span></li>
                    </ul>
                </div>
            </div>
        </template>
    </div>

    <!-- Signatures — real named signatories from the actual municipal forms -->
    <div class="relative mt-6 pt-4 border-t border-dashed border-slate-200" x-show="{{ $officiant }} || {{ $technician }}">
        <div class="grid grid-cols-2 gap-4">
            <template x-if="{{ $officiant }}">
                <div class="text-center">
                    <div class="w-full border-b border-slate-400 mb-1 h-6"></div>
                    <p class="text-xs font-bold text-navy-900 uppercase" x-text="{{ $officiant }}"></p>
                    <p class="text-[10px] text-slate-500" x-text="{{ $officiantTitle }}"></p>
                </div>
            </template>
            <template x-if="{{ $technician }}">
                <div class="text-center">
                    <p class="text-xs font-bold text-navy-900 uppercase" x-text="{{ $technician }}"></p>
                    <p class="text-[10px] text-slate-500" x-text="{{ $technicianTitle }}"></p>
                </div>
            </template>
            <template x-if="{{ $verifier }}">
                <div class="text-center">
                    <p class="text-xs font-bold text-navy-900 uppercase" x-text="{{ $verifier }}"></p>
                    <p class="text-[10px] text-slate-500" x-text="{{ $verifierTitle }}"></p>
                </div>
            </template>
        </div>
    </div>

    <div class="relative flex items-start gap-2.5 rounded-xl bg-slate-50 border border-slate-100 px-3.5 py-2.5 mt-5">
        <i data-lucide="info" class="w-4 h-4 text-slate-400 shrink-0 mt-0.5"></i>
        <p class="text-[11px] text-slate-500">This is a summary of your request, not the final certificate. The <span x-text="{{ $office }}"></span> will prepare and release the official document upon verification against the civil registry.</p>
    </div>
</div>
