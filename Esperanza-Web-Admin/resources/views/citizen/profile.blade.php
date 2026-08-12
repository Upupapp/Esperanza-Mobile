@php
    $household = [
        ['name' => 'Ramon Bacaltos', 'relation' => 'Spouse', 'age' => 41],
        ['name' => 'Josiah Bacaltos', 'relation' => 'Son', 'age' => 16],
        ['name' => 'Andrea Bacaltos', 'relation' => 'Daughter', 'age' => 12],
    ];

    $documents = [
        ['label' => 'Philippine National ID (PhilSys)', 'status' => 'Approved', 'icon' => 'badge-check'],
        ['label' => 'Proof of Residency — Barangay Certificate', 'status' => 'Approved', 'icon' => 'file-check'],
        ['label' => "Voter's ID", 'status' => 'Pending Review', 'icon' => 'file-clock'],
    ];

    $idTypes = ["Voter's ID", "Driver's License", 'Passport', 'PRC ID', 'Senior Citizen ID', 'PWD ID', 'Postal ID', 'Other Valid ID'];

    $availableFiles = [
        ['name' => "Voter's ID Scan.jpg", 'category' => 'IMG'],
        ["name" => "Driver's License Scan.jpg", 'category' => 'IMG'],
        ['name' => 'Passport Bio Page.pdf', 'category' => 'PDF'],
    ];
@endphp

<x-layouts.citizen title="My Profile" subtitle="Manage your resident information and account details." active="profile">
    <div
        x-data="{
            open: false,
            submitted: false,
            idType: '',
            idNumber: '',
            attachment: null,
            showFilePicker: false,
            verifiedIndex: null,
            files: @js($availableFiles),
            idTypes: @js($idTypes),
            reset() { this.open = false; this.submitted = false; this.idType = ''; this.idNumber = ''; this.attachment = null; this.showFilePicker = false; },

            showEditProfile: false,
            savingProfile: false,
            editForm: { firstName: '', lastName: '', mobile: '', occupation: '', address: '' },
            openEditProfile() {
                const a = this.$store.citizenSession.account || {};
                this.editForm = { firstName: a.firstName || '', lastName: a.lastName || '', mobile: a.mobile || '', occupation: a.occupation || '', address: a.address || '' };
                this.showEditProfile = true;
            },
            saveProfile() {
                if (this.savingProfile) return;
                this.savingProfile = true;
                setTimeout(() => {
                    const a = this.$store.citizenSession.account;
                    this.$store.citizenSession.login({
                        ...a,
                        firstName: this.editForm.firstName,
                        lastName: this.editForm.lastName,
                        fullName: this.editForm.firstName + ' ' + this.editForm.lastName,
                        mobile: this.editForm.mobile,
                        occupation: this.editForm.occupation,
                        address: this.editForm.address,
                    });
                    this.savingProfile = false;
                    this.showEditProfile = false;
                    this.$dispatch('toast', { message: 'Profile updated — this is a frontend preview, no data is saved.', variant: 'success' });
                }, 800);
            },
        }"
        class="animate-fade-up"
    >

        <!-- Profile hero -->
        <div class="relative rounded-2xl overflow-hidden mb-5 bg-gradient-to-br from-navy-900 via-navy-800 to-brand-700 shadow-card">
            <div class="absolute inset-0 opacity-20 bg-[radial-gradient(circle_at_top_right,theme(colors.white),transparent_55%)] pointer-events-none"></div>
            <div class="relative px-5 py-6 sm:px-7 sm:py-7 flex flex-col sm:flex-row sm:items-center gap-5">
                <div class="relative shrink-0">
                    <div class="w-20 h-20 text-2xl rounded-full bg-white/15 backdrop-blur border-2 border-white/40 text-white flex items-center justify-center font-semibold shadow-lg" x-text="$store.citizenSession.initials()"></div>
                    <span class="absolute -bottom-1 -right-1 w-7 h-7 rounded-full bg-emerald-500 border-2 border-navy-900 flex items-center justify-center">
                        <i data-lucide="badge-check" class="w-3.5 h-3.5 text-white"></i>
                    </span>
                </div>

                <div class="min-w-0 flex-1">
                    <div class="flex flex-wrap items-center gap-2">
                        <h2 class="text-xl font-semibold text-white" x-text="$store.citizenSession.account?.fullName || 'Resident'"></h2>
                        <span class="inline-flex items-center gap-1 text-[11px] font-medium text-emerald-100 bg-emerald-500/20 border border-emerald-400/30 rounded-full px-2 py-0.5">
                            <x-ui.t fil="Verified na Residente" en="Verified Resident" />
                        </span>
                    </div>
                    <p class="text-sm text-white/60 mt-1.5 flex flex-wrap items-center gap-x-3 gap-y-1">
                        <span class="flex items-center gap-1.5"><i data-lucide="hash" class="w-3.5 h-3.5"></i><span x-text="$store.citizenSession.account?.id"></span></span>
                        <span class="flex items-center gap-1.5"><i data-lucide="map-pin" class="w-3.5 h-3.5"></i><span x-text="'Brgy. ' + ($store.citizenSession.account?.barangay || '—')"></span></span>
                        <span class="flex items-center gap-1.5"><i data-lucide="calendar" class="w-3.5 h-3.5"></i><span x-text="($store.lang.current === 'en' ? 'Resident since ' : 'Residente mula ') + ($store.citizenSession.account?.residentSince || '—')"></span></span>
                    </p>
                </div>

                <div class="flex items-center gap-2 shrink-0">
                    <button
                        @click="open = true"
                        class="inline-flex items-center gap-1.5 text-xs font-medium text-white bg-white/10 hover:bg-white/20 border border-white/20 rounded-xl px-3.5 py-2.5 transition-colors"
                    ><i data-lucide="shield-plus" class="w-3.5 h-3.5"></i> <x-ui.t fil="Mag-verify ng ID" en="Verify ID" /></button>
                    <button
                        @click="openEditProfile()"
                        class="inline-flex items-center gap-1.5 text-xs font-medium text-navy-900 bg-white hover:bg-slate-100 rounded-xl px-3.5 py-2.5 transition-colors shadow-sm"
                    ><i data-lucide="pencil" class="w-3.5 h-3.5"></i> <x-ui.t fil="I-edit" en="Edit" /></button>
                </div>
            </div>

            <!-- Profile completeness -->
            <div class="relative px-5 pb-5 sm:px-7 sm:pb-6">
                <div class="flex items-center justify-between mb-1.5">
                    <p class="text-xs font-medium text-white/70"><x-ui.t fil="Kumpletuhin ang Profile" en="Profile Completeness" /></p>
                    <p class="text-xs font-semibold text-white" x-text="($store.citizenSession.account?.profileCompleteness || 0) + '%'"></p>
                </div>
                <div class="h-1.5 rounded-full bg-white/15 overflow-hidden">
                    <div class="h-full rounded-full bg-gradient-to-r from-gold-400 to-gold-300 transition-all duration-500" :style="'width:' + ($store.citizenSession.account?.profileCompleteness || 0) + '%'"></div>
                </div>
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-5">
            <!-- Personal information -->
            <div class="lg:col-span-2 space-y-5">
                <x-ui.card>
                    <h3 class="text-sm font-semibold text-navy-900 mb-4 flex items-center gap-2"><i data-lucide="user-round" class="w-4 h-4 text-slate-400"></i><x-ui.t fil="Personal na Impormasyon" en="Personal Information" /></h3>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div class="flex items-start gap-2.5 rounded-xl bg-slate-50/70 p-3">
                            <i data-lucide="signature" class="w-4 h-4 text-slate-300 shrink-0 mt-0.5"></i>
                            <div class="min-w-0">
                                <p class="text-[11px] text-slate-400"><x-ui.t fil="Buong Pangalan" en="Full Name" /></p>
                                <p class="text-sm text-slate-700 font-medium truncate" x-text="$store.citizenSession.account?.fullName || '—'"></p>
                            </div>
                        </div>
                        <div class="flex items-start gap-2.5 rounded-xl bg-slate-50/70 p-3">
                            <i data-lucide="cake" class="w-4 h-4 text-slate-300 shrink-0 mt-0.5"></i>
                            <div class="min-w-0">
                                <p class="text-[11px] text-slate-400"><x-ui.t fil="Petsa ng Kapanganakan" en="Date of Birth" /></p>
                                <p class="text-sm text-slate-700 font-medium truncate" x-text="$store.citizenSession.account?.birthdate || '—'"></p>
                            </div>
                        </div>
                        <div class="flex items-start gap-2.5 rounded-xl bg-slate-50/70 p-3">
                            <i data-lucide="venus-and-mars" class="w-4 h-4 text-slate-300 shrink-0 mt-0.5"></i>
                            <div class="min-w-0">
                                <p class="text-[11px] text-slate-400"><x-ui.t fil="Kasarian" en="Sex" /></p>
                                <p class="text-sm text-slate-700 font-medium truncate" x-text="$store.citizenSession.account?.sex || '—'"></p>
                            </div>
                        </div>
                        <div class="flex items-start gap-2.5 rounded-xl bg-slate-50/70 p-3">
                            <i data-lucide="heart" class="w-4 h-4 text-slate-300 shrink-0 mt-0.5"></i>
                            <div class="min-w-0">
                                <p class="text-[11px] text-slate-400"><x-ui.t fil="Katayuang Sibil" en="Civil Status" /></p>
                                <p class="text-sm text-slate-700 font-medium truncate" x-text="$store.citizenSession.account?.civilStatus || '—'"></p>
                            </div>
                        </div>
                        <div class="flex items-start gap-2.5 rounded-xl bg-slate-50/70 p-3">
                            <i data-lucide="flag" class="w-4 h-4 text-slate-300 shrink-0 mt-0.5"></i>
                            <div class="min-w-0">
                                <p class="text-[11px] text-slate-400"><x-ui.t fil="Nasyonalidad" en="Nationality" /></p>
                                <p class="text-sm text-slate-700 font-medium"><x-ui.t fil="Pilipino" en="Filipino" /></p>
                            </div>
                        </div>
                        <div class="flex items-start gap-2.5 rounded-xl bg-slate-50/70 p-3">
                            <i data-lucide="briefcase" class="w-4 h-4 text-slate-300 shrink-0 mt-0.5"></i>
                            <div class="min-w-0">
                                <p class="text-[11px] text-slate-400"><x-ui.t fil="Trabaho" en="Occupation" /></p>
                                <p class="text-sm text-slate-700 font-medium truncate" x-text="$store.citizenSession.account?.occupation || '—'"></p>
                            </div>
                        </div>
                    </div>
                </x-ui.card>

                <x-ui.card>
                    <h3 class="text-sm font-semibold text-navy-900 mb-4 flex items-center gap-2"><i data-lucide="contact" class="w-4 h-4 text-slate-400"></i><x-ui.t fil="Contact at Address" en="Contact & Address" /></h3>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div class="flex items-start gap-2.5 rounded-xl bg-slate-50/70 p-3">
                            <i data-lucide="mail" class="w-4 h-4 text-slate-300 shrink-0 mt-0.5"></i>
                            <div class="min-w-0">
                                <p class="text-[11px] text-slate-400"><x-ui.t fil="Email Address" en="Email Address" /></p>
                                <p class="text-sm text-slate-700 font-medium truncate" x-text="$store.citizenSession.account?.email || '—'"></p>
                            </div>
                        </div>
                        <div class="flex items-start gap-2.5 rounded-xl bg-slate-50/70 p-3">
                            <i data-lucide="phone" class="w-4 h-4 text-slate-300 shrink-0 mt-0.5"></i>
                            <div class="min-w-0">
                                <p class="text-[11px] text-slate-400"><x-ui.t fil="Numero ng Mobile" en="Mobile Number" /></p>
                                <p class="text-sm text-slate-700 font-medium truncate" x-text="$store.citizenSession.account?.mobile || '—'"></p>
                            </div>
                        </div>
                        <div class="flex items-start gap-2.5 rounded-xl bg-slate-50/70 p-3 sm:col-span-2">
                            <i data-lucide="map-pin" class="w-4 h-4 text-slate-300 shrink-0 mt-0.5"></i>
                            <div class="min-w-0">
                                <p class="text-[11px] text-slate-400"><x-ui.t fil="Kumpletong Address" en="Complete Address" /></p>
                                <p class="text-sm text-slate-700 font-medium" x-text="$store.citizenSession.account?.address || '—'"></p>
                            </div>
                        </div>
                    </div>
                </x-ui.card>
            </div>

            <div class="space-y-5">
                <!-- My Barangay -->
                <div x-show="$store.barangay.mine" x-cloak class="rounded-2xl bg-gradient-to-br from-brand-50 via-white to-purple-50/60 border border-brand-100 shadow-card p-4">
                    <p class="text-[11px] font-semibold text-brand-600 uppercase tracking-wide mb-3 flex items-center gap-1.5"><i data-lucide="landmark" class="w-3.5 h-3.5"></i><x-ui.t fil="Aking Barangay" en="My Barangay" /></p>
                    <div class="flex items-center gap-3 mb-3">
                        <div class="relative w-11 h-11 shrink-0">
                            <div class="absolute inset-0 rounded-full bg-white border-2 border-gold-400 flex items-center justify-center text-slate-300"><i data-lucide="landmark" class="w-5 h-5"></i></div>
                            <img
                                :src="$store.barangay.mine?.seal ? '{{ rtrim(asset(''), '/') }}/' + $store.barangay.mine.seal : ''"
                                x-show="$store.barangay.mine?.seal" onerror="this.style.display='none'" alt=""
                                class="relative w-11 h-11 rounded-full object-cover border-2 border-gold-400"
                            >
                        </div>
                        <h3 class="text-sm font-semibold text-navy-900 truncate"><x-ui.t fil="Barangay" en="Barangay" /> <span x-text="$store.barangay.mine?.label"></span></h3>
                    </div>
                    <div class="space-y-1.5 text-xs border-t border-brand-100/70 pt-3">
                        <div class="flex items-center justify-between gap-2"><span class="text-slate-400 shrink-0"><x-ui.t fil="Punong Barangay" en="Punong Barangay" /></span><span class="font-medium text-slate-700 text-right truncate" x-text="$store.barangay.mine?.officials?.punong_barangay"></span></div>
                        <div class="flex items-center justify-between gap-2"><span class="text-slate-400 shrink-0"><x-ui.t fil="Kalihim" en="Secretary" /></span><span class="font-medium text-slate-700 text-right truncate" x-text="$store.barangay.mine?.officials?.barangay_secretary"></span></div>
                        <div class="flex items-center justify-between gap-2" x-show="$store.barangay.mine?.contact"><span class="text-slate-400 shrink-0"><x-ui.t fil="Contact" en="Contact" /></span><a class="font-medium text-brand-600 hover:underline text-right truncate" :href="'tel:' + ($store.barangay.mine?.contact || '').replace(/[^0-9+]/g, '')" x-text="$store.barangay.mine?.contact"></a></div>
                    </div>
                </div>

                <!-- Household -->
                <x-ui.card padded="false">
                    <div class="px-4 pt-3.5 pb-2.5 flex items-center justify-between">
                        <h3 class="text-sm font-semibold text-navy-900 flex items-center gap-2"><i data-lucide="users-round" class="w-4 h-4 text-slate-400"></i><x-ui.t fil="Kasapi ng Sambahayan" en="Household Members" /></h3>
                        <span class="text-[11px] font-medium text-slate-400">{{ count($household) }}</span>
                    </div>
                    <div class="divide-y divide-slate-50">
                        @foreach($household as $member)
                            <div class="flex items-center gap-3 px-4 py-2.5 hover:bg-slate-50/60 transition-colors">
                                <div class="w-8 h-8 text-xs rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold shrink-0">{{ collect(explode(' ', $member['name']))->map(fn($w) => mb_substr($w, 0, 1))->take(2)->implode('') }}</div>
                                <div class="min-w-0 flex-1">
                                    <p class="text-sm font-medium text-slate-700 truncate">{{ $member['name'] }}</p>
                                    <p class="text-xs text-slate-400">{{ $member['age'] }} <x-ui.t fil="taong gulang" en="y/o" /></p>
                                </div>
                                <span class="text-[10px] font-medium text-slate-500 bg-slate-100 rounded-full px-2 py-0.5 shrink-0">{{ $member['relation'] }}</span>
                            </div>
                        @endforeach
                    </div>
                </x-ui.card>

                <!-- Documents on file -->
                <x-ui.card padded="false">
                    <div class="px-4 pt-3.5 pb-2.5">
                        <h3 class="text-sm font-semibold text-navy-900 flex items-center gap-2"><i data-lucide="folder-check" class="w-4 h-4 text-slate-400"></i><x-ui.t fil="Mga Dokumento sa File" en="Documents on File" /></h3>
                    </div>
                    <div class="divide-y divide-slate-50">
                        @foreach($documents as $doc)
                            <div class="flex items-center gap-3 px-4 py-2.5 hover:bg-slate-50/60 transition-colors">
                                <span class="w-8 h-8 rounded-lg bg-slate-100 text-slate-500 flex items-center justify-center shrink-0">
                                    <i data-lucide="{{ $doc['icon'] }}" class="w-4 h-4"></i>
                                </span>
                                <p class="text-sm text-slate-700 min-w-0 truncate flex-1">{{ $doc['label'] }}</p>
                                @if($doc['status'] === 'Approved')
                                    <x-ui.badge :status="$doc['status']" class="shrink-0" />
                                @else
                                    <x-ui.badge :status="$doc['status']" class="shrink-0" x-show="verifiedIndex !== {{ $loop->index }}" />
                                    <x-ui.badge status="Under Verification" class="shrink-0" x-show="verifiedIndex === {{ $loop->index }}" x-cloak />
                                @endif
                            </div>
                        @endforeach
                    </div>
                </x-ui.card>
            </div>
        </div>

        <x-ui.modal title="I-verify ang Valid ID" titleEn="Verify Valid ID" maxWidth="md">
            <!-- Success state -->
            <div x-show="submitted" x-cloak x-transition.opacity class="flex flex-col items-center justify-center text-center py-10">
                <div class="relative flex items-center justify-center mb-4 w-16 h-16">
                    <span class="absolute inline-flex h-16 w-16 rounded-full bg-emerald-400/40 animate-ring-pulse"></span>
                    <span class="absolute inline-flex h-16 w-16 rounded-full bg-emerald-400/40 animate-ring-pulse" style="animation-delay: 0.35s;"></span>
                    <span class="relative w-14 h-14 rounded-full bg-emerald-500 text-white flex items-center justify-center animate-check-pop">
                        <i data-lucide="check" class="w-7 h-7"></i>
                    </span>
                </div>
                <p class="text-sm font-semibold text-navy-900">
                    <x-ui.t fil="Naisumite para sa Beripikasyon!" en="Submitted for Verification!" />
                    <span class="inline-block animate-check-pop" style="animation-delay: 0.3s;">🙂</span>
                </p>
                <p class="text-xs text-slate-400 mt-1 max-w-[240px]"><x-ui.t fil="Susuriin ng aming staff ang iyong ID at ia-update ang iyong profile sa lalong madaling panahon." en="Our staff will review your ID and update your profile shortly." /></p>
            </div>

            <div x-show="!submitted">
                <p class="text-sm text-slate-500 mb-4"><x-ui.t fil="Magsumite ng valid ID para ma-verify ng aming staff ang iyong resident profile." en="Submit a valid ID so our staff can verify your resident profile." /></p>

                <div class="mb-3">
                    <label class="block text-sm font-medium text-slate-700 mb-1.5"><x-ui.t fil="Uri ng ID" en="ID Type" /></label>
                    <select x-model="idType" class="w-full rounded-xl border border-slate-200 bg-slate-50/60 py-2.5 px-4 text-sm text-slate-800 focus:bg-white focus:border-brand-400 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200">
                        <option value="" disabled x-text="$store.lang.current === 'en' ? 'Select ID type' : 'Pumili ng uri ng ID'"></option>
                        <template x-for="t in idTypes" :key="t">
                            <option :value="t" x-text="t"></option>
                        </template>
                    </select>
                </div>

                <div class="mb-5">
                    <x-ui.input name="valid_id_number" label="ID Number" placeholder="e.g. 1234-5678-9012" x-model="idNumber" />
                </div>

                <p class="text-sm font-semibold text-navy-900 mb-1"><x-ui.t fil="Ikabit ang Larawan ng ID" en="Attach ID Photo" /></p>
                <p class="text-xs text-slate-400 mb-3"><x-ui.t fil="Ikabit mula sa mga file na na-upload mo na, o mag-upload ng bago." en="Attach from your already-uploaded files, or upload a new one." /></p>
                <div class="rounded-xl border border-slate-200 p-3">
                    <div class="flex items-center justify-between gap-3">
                        <p class="text-xs text-slate-600 flex-1"><x-ui.t fil="Malinaw na larawan o scan ng harap ng iyong ID" en="Clear photo or scan of the front of your ID" /></p>
                        <button
                            type="button" x-show="!attachment"
                            @click="showFilePicker = !showFilePicker"
                            class="text-[11px] font-medium text-brand-600 hover:underline shrink-0 whitespace-nowrap"
                        ><x-ui.t fil="Ikabit ang File" en="Attach File" /></button>
                        <div class="flex items-center gap-1.5 shrink-0" x-show="attachment">
                            <span class="inline-flex items-center gap-1 text-[11px] text-emerald-600 font-medium whitespace-nowrap">
                                <i data-lucide="circle-check" class="w-3.5 h-3.5"></i><span x-text="attachment"></span>
                            </span>
                            <button type="button" @click="attachment = null" class="text-slate-300 hover:text-rose-500"><i data-lucide="x" class="w-3.5 h-3.5"></i></button>
                        </div>
                    </div>
                    <div x-show="showFilePicker" x-cloak x-transition class="mt-2.5 pt-2.5 border-t border-slate-100">
                        <x-ui.file-picker
                            files="files"
                            onSelect="attachment = file.name; showFilePicker = false"
                            uploadAction="attachment = 'New upload.jpg'; showFilePicker = false; $dispatch('toast', { message: 'File upload is a frontend preview — no data is saved.', variant: 'info' })"
                            :columns="2"
                            :search="false"
                        />
                    </div>
                </div>
            </div>

            <x-slot:footer>
                <x-ui.button variant="secondary" size="sm" x-show="!submitted" @click="reset()"><x-ui.t fil="Kanselahin" en="Cancel" /></x-ui.button>
                <x-ui.button
                    size="sm"
                    x-show="!submitted"
                    ::disabled="!idType || !attachment"
                    @click="
                        let idx = @js(collect($documents)->pluck('label')->all()).indexOf(idType);
                        verifiedIndex = idx;
                        submitted = true;
                        setTimeout(() => { reset(); $dispatch('toast', { message: $store.lang.current === 'en' ? 'Valid ID submitted for verification — this is a frontend preview, no data is saved.' : 'Naisumite ang valid ID para sa beripikasyon — frontend preview lang ito, walang naiimbak na datos.', variant: 'success' }) }, 1400);
                    "
                ><x-ui.t fil="Isumite para sa Beripikasyon" en="Submit for Verification" /></x-ui.button>
            </x-slot:footer>
        </x-ui.modal>

        <div x-data="{ get open() { return showEditProfile }, set open(v) { showEditProfile = v } }">
            <x-ui.modal title="I-edit ang Profile" titleEn="Edit Profile" maxWidth="md">
                <div class="space-y-4">
                    <div class="grid grid-cols-2 gap-3">
                        <x-ui.input name="edit_first_name" label="First Name" x-model="editForm.firstName" />
                        <x-ui.input name="edit_last_name" label="Last Name" x-model="editForm.lastName" />
                    </div>
                    <x-ui.input name="edit_mobile" label="Mobile Number" icon="phone" x-model="editForm.mobile" />
                    <x-ui.input name="edit_occupation" label="Occupation" icon="briefcase" x-model="editForm.occupation" />
                    <x-ui.input name="edit_address" label="Complete Address" icon="house" x-model="editForm.address" />
                    <p class="text-xs text-slate-400"><x-ui.t fil="Ang barangay at Resident ID ay hindi maaaring baguhin dito — makipag-ugnayan sa iyong Barangay Hall." en="Barangay and Resident ID can't be changed here — contact your Barangay Hall for those." /></p>
                </div>

                <x-slot:footer>
                    <x-ui.button variant="secondary" size="sm" x-bind:disabled="savingProfile" @click="showEditProfile = false"><x-ui.t fil="Kanselahin" en="Cancel" /></x-ui.button>
                    <x-ui.button size="sm" x-bind:disabled="savingProfile" @click="saveProfile()">
                        <span class="inline-flex items-center gap-1.5">
                            <i data-lucide="loader-circle" class="w-3.5 h-3.5 animate-spin" x-show="savingProfile" x-cloak></i>
                            <span x-text="savingProfile ? ($store.lang.current === 'en' ? 'Saving…' : 'Sine-save…') : ($store.lang.current === 'en' ? 'Save Changes' : 'I-save ang Pagbabago')"></span>
                        </span>
                    </x-ui.button>
                </x-slot:footer>
            </x-ui.modal>
        </div>
    </div>
</x-layouts.citizen>
