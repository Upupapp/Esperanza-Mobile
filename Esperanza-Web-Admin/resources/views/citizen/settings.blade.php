@php
    $notifPrefs = [
        ['label' => 'Document request updates', 'labelFil' => 'Update sa mga kahilingang dokumento', 'desc' => 'Get notified when a request status changes.', 'descFil' => 'Maaabisuhan ka kapag nagbago ang status ng iyong kahilingan.', 'checked' => true],
        ['label' => 'Assistance request updates', 'labelFil' => 'Update sa mga kahilingang tulong', 'desc' => 'Get notified about assistance program progress.', 'descFil' => 'Maaabisuhan ka tungkol sa progreso ng iyong tulong.', 'checked' => true],
        ['label' => 'Municipal announcements', 'labelFil' => 'Mga balita ng munisipyo', 'desc' => 'News and advisories from the municipality.', 'descFil' => 'Balita at abiso mula sa munisipyo.', 'checked' => true],
        ['label' => 'Event reminders', 'labelFil' => 'Paalala sa mga kaganapan', 'desc' => 'Reminders before events you\'re following.', 'descFil' => 'Paalala bago magsimula ang mga sinusundan mong kaganapan.', 'checked' => false],
        ['label' => 'SMS notifications', 'labelFil' => 'Abiso sa SMS', 'desc' => 'Receive critical updates via SMS as backup.', 'descFil' => 'Tumanggap ng mahahalagang update sa SMS bilang backup.', 'checked' => false],
    ];
@endphp

<x-layouts.citizen title="Settings" subtitle="Manage your account preferences." active="settings">
    <div
        x-data="{
            tab: 'notifications',
            savingPassword: false,
            enabling2fa: false,
            requestingData: false,
            updatePassword() {
                if (this.savingPassword) return;
                this.savingPassword = true;
                setTimeout(() => {
                    this.savingPassword = false;
                    this.$dispatch('toast', { message: 'Password updated — this is a frontend preview, no data is saved.', variant: 'success' });
                }, 800);
            },
            enable2fa() {
                if (this.enabling2fa) return;
                this.enabling2fa = true;
                setTimeout(() => {
                    this.enabling2fa = false;
                    this.$dispatch('toast', { message: 'Two-factor authentication setup is a frontend preview — no data is saved.', variant: 'info' });
                }, 800);
            },
            requestData() {
                if (this.requestingData) return;
                this.requestingData = true;
                setTimeout(() => {
                    this.requestingData = false;
                    this.$dispatch('toast', { message: 'Data export request received — this is a frontend preview, no file is generated.', variant: 'success' });
                }, 800);
            },
        }"
        class="animate-fade-up grid grid-cols-1 lg:grid-cols-4 gap-5"
    >

        <div class="lg:col-span-1">
            <x-ui.card padded="false" class="p-2">
                <nav class="space-y-0.5">
                    @foreach(['notifications' => ['bell', 'Mga Abiso', 'Notifications'], 'security' => ['shield', 'Seguridad', 'Security'], 'privacy' => ['lock', 'Pribasiya', 'Privacy'], 'preferences' => ['sliders-horizontal', 'Kagustuhan', 'Preferences']] as $key => [$icon, $labelFil, $labelEn])
                        <button
                            @click="tab = '{{ $key }}'"
                            class="w-full flex items-center gap-2.5 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-colors"
                            :class="tab === '{{ $key }}' ? 'bg-brand-50 text-brand-700' : 'text-slate-500 hover:bg-slate-50'"
                        >
                            <i data-lucide="{{ $icon }}" class="w-4 h-4"></i><x-ui.t :fil="$labelFil" :en="$labelEn" />
                        </button>
                    @endforeach
                </nav>
            </x-ui.card>
        </div>

        <div class="lg:col-span-3">
            <div x-show="tab === 'notifications'">
                <x-ui.card>
                    <h3 class="text-sm font-semibold text-navy-900 mb-1"><x-ui.t fil="Mga Kagustuhan sa Abiso" en="Notification Preferences" /></h3>
                    <p class="text-xs text-slate-400 mb-4"><x-ui.t fil="Piliin kung anong mga update ang gusto mong matanggap." en="Choose what updates you want to receive." /></p>
                    <div class="divide-y divide-slate-50" x-data="{}">
                        @foreach($notifPrefs as $pref)
                            <label class="flex items-center justify-between gap-4 py-3.5 cursor-pointer">
                                <div class="min-w-0">
                                    <p class="text-sm font-medium text-slate-700"><x-ui.t :fil="$pref['labelFil']" :en="$pref['label']" /></p>
                                    <p class="text-xs text-slate-400 mt-0.5"><x-ui.t :fil="$pref['descFil']" :en="$pref['desc']" /></p>
                                </div>
                                <div class="relative shrink-0" x-data="{ on: {{ $pref['checked'] ? 'true' : 'false' }} }">
                                    <button
                                        @click="on = !on"
                                        type="button"
                                        class="w-10 h-6 rounded-full transition-colors duration-200 relative"
                                        :class="on ? 'bg-brand-600' : 'bg-slate-200'"
                                    >
                                        <span class="absolute top-0.5 left-0.5 w-5 h-5 rounded-full bg-white shadow transition-transform duration-200" :class="on && 'translate-x-4'"></span>
                                    </button>
                                </div>
                            </label>
                        @endforeach
                    </div>
                </x-ui.card>
            </div>

            <div x-show="tab === 'security'" x-cloak class="space-y-5">
                <x-ui.card>
                    <h3 class="text-sm font-semibold text-navy-900 mb-4"><x-ui.t fil="Palitan ang Password" en="Change Password" /></h3>
                    <div class="space-y-4 max-w-md">
                        <x-ui.input name="current_password" type="password" label="Current Password" icon="lock" placeholder="••••••••" />
                        <x-ui.input name="new_password" type="password" label="New Password" icon="lock" placeholder="••••••••" />
                        <x-ui.input name="confirm_password" type="password" label="Confirm New Password" icon="lock" placeholder="••••••••" />
                        <x-ui.button x-bind:disabled="savingPassword" @click="updatePassword()">
                            <span class="inline-flex items-center gap-1.5">
                                <i data-lucide="loader-circle" class="w-3.5 h-3.5 animate-spin" x-show="savingPassword" x-cloak></i>
                                <i data-lucide="check" class="w-3.5 h-3.5" x-show="!savingPassword"></i>
                                <span x-text="savingPassword ? ($store.lang.current === 'en' ? 'Saving…' : 'Sine-save…') : ($store.lang.current === 'en' ? 'Update Password' : 'I-update ang Password')"></span>
                            </span>
                        </x-ui.button>
                    </div>
                </x-ui.card>
                <x-ui.card class="flex items-center justify-between gap-4">
                    <div>
                        <p class="text-sm font-medium text-navy-900"><x-ui.t fil="Two-Factor Authentication" en="Two-Factor Authentication" /></p>
                        <p class="text-xs text-slate-400 mt-0.5"><x-ui.t fil="Magdagdag ng karagdagang proteksyon sa iyong account." en="Add an extra layer of security to your account." /></p>
                    </div>
                    <x-ui.button variant="secondary" size="sm" x-bind:disabled="enabling2fa" @click="enable2fa()">
                        <span class="inline-flex items-center gap-1.5">
                            <i data-lucide="loader-circle" class="w-3.5 h-3.5 animate-spin" x-show="enabling2fa" x-cloak></i>
                            <span x-text="enabling2fa ? ($store.lang.current === 'en' ? 'Enabling…' : 'Ina-enable…') : ($store.lang.current === 'en' ? 'Enable 2FA' : 'I-enable ang 2FA')"></span>
                        </span>
                    </x-ui.button>
                </x-ui.card>
            </div>

            <div x-show="tab === 'privacy'" x-cloak>
                <x-ui.card>
                    <h3 class="text-sm font-semibold text-navy-900 mb-1"><x-ui.t fil="Pribasiya ng Datos" en="Data Privacy" /></h3>
                    <p class="text-xs text-slate-400 mb-4"><x-ui.t fil="Pamahalaan kung paano ginagamit ang iyong datos bilang residente sa buong platform, alinsunod sa Data Privacy Act of 2012." en="Manage how your resident data is used across the platform, in line with the Data Privacy Act of 2012." /></p>
                    <div class="flex items-start gap-3 rounded-xl bg-slate-50 border border-slate-100 p-4">
                        <i data-lucide="shield-check" class="w-5 h-5 text-emerald-600 shrink-0 mt-0.5"></i>
                        <p class="text-xs text-slate-500 leading-relaxed">
                            <x-ui.t
                                fil="Kinokolekta at pinoproseso ng Munisipyo ng Esperanza ang iyong personal na datos para lamang sa layunin ng paghahatid ng serbisyong publiko. Hindi ibinabahagi ang iyong datos sa ibang partido nang walang pahintulot."
                                en="The Municipality of Esperanza collects and processes your personal data solely for the purpose of delivering public services. Your data is not shared with third parties without consent."
                            />
                        </p>
                    </div>
                    <x-ui.button variant="secondary" size="sm" class="mt-4" x-bind:disabled="requestingData" @click="requestData()">
                        <span class="inline-flex items-center gap-1.5">
                            <i data-lucide="loader-circle" class="w-3.5 h-3.5 animate-spin" x-show="requestingData" x-cloak></i>
                            <i data-lucide="download" class="w-3.5 h-3.5" x-show="!requestingData"></i>
                            <span x-text="requestingData ? ($store.lang.current === 'en' ? 'Requesting…' : 'Hinihiling…') : ($store.lang.current === 'en' ? 'Request My Data' : 'Hilingin ang Aking Datos')"></span>
                        </span>
                    </x-ui.button>
                </x-ui.card>
            </div>

            <div x-show="tab === 'preferences'" x-cloak>
                <x-ui.card>
                    <h3 class="text-sm font-semibold text-navy-900 mb-4"><x-ui.t fil="Pangkalahatang Kagustuhan" en="General Preferences" /></h3>
                    <div class="space-y-4 max-w-md">
                        <div>
                            <label class="block text-sm font-medium text-slate-700 mb-1.5"><x-ui.t fil="Wika" en="Language" /></label>
                            <p class="text-xs text-slate-400 mb-2.5"><x-ui.t fil="Piliin ang wikang gagamitin sa Citizen Portal." en="Choose the language used across the Citizen Portal." /></p>
                            <div class="flex items-center gap-1.5 bg-slate-100/70 rounded-xl p-1 w-fit">
                                <button
                                    type="button"
                                    @click="$store.lang.set('fil'); $dispatch('toast', { message: 'Naka-Filipino na ang wika ng portal.', variant: 'success' })"
                                    class="px-4 py-2 text-sm font-medium rounded-lg transition-colors"
                                    :class="$store.lang.current === 'fil' ? 'bg-white text-navy-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'"
                                >Filipino</button>
                                <button
                                    type="button"
                                    @click="$store.lang.set('en'); $dispatch('toast', { message: 'Portal language set to English.', variant: 'success' })"
                                    class="px-4 py-2 text-sm font-medium rounded-lg transition-colors"
                                    :class="$store.lang.current === 'en' ? 'bg-white text-navy-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'"
                                >English</button>
                            </div>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-slate-700 mb-1.5"><x-ui.t fil="Time Zone" en="Time Zone" /></label>
                            <select class="w-full rounded-xl border border-slate-200 bg-slate-50/60 py-2.5 px-4 text-sm text-slate-700 focus:bg-white focus:border-brand-400 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200">
                                <option>(GMT+8:00) Manila</option>
                            </select>
                        </div>
                    </div>
                </x-ui.card>
            </div>
        </div>
    </div>
</x-layouts.citizen>
