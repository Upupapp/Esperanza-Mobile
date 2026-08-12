@php
    $requests = [
        ['ref' => 'DR-2026-2210', 'type' => 'Cedula (Community Tax Certificate)', 'submitted' => 'Jul 8, 2026', 'status' => 'Under Verification'],
        ['ref' => 'DR-2026-2187', 'type' => 'Barangay Clearance', 'submitted' => 'Jul 3, 2026', 'status' => 'Ready for Release'],
        ['ref' => 'AR-2026-0142', 'type' => 'Medical Assistance', 'submitted' => 'Jun 28, 2026', 'status' => 'Approved'],
        ['ref' => 'DR-2026-1998', 'type' => 'Certificate of Residency', 'submitted' => 'Jun 14, 2026', 'status' => 'Completed'],
    ];

    // Same source data as the full Balita feed (config/esperanza_balita.php) —
    // this is a compact, functioning preview, not a separate static snapshot.
    $initials = fn (string $name) => collect(preg_split('/\s+/', trim($name)))
        ->filter()
        ->map(fn ($p) => mb_substr($p, 0, 1))
        ->take(2)
        ->implode('');

    $balitaPreview = collect(config('esperanza_balita.posts'))
        ->take(4)
        ->values()
        ->map(function ($post, $i) use ($initials) {
            return [
                'id' => $i,
                'official' => $post['official'],
                'author' => $post['author'],
                'initials' => $post['official'] ? 'LGU' : $initials($post['author']),
                'barangay' => $post['barangay'],
                'body' => $post['body'],
                'time' => $post['time'],
                'likes' => $post['likes'],
                'liked' => false,
                'commentCount' => count($post['comments']),
            ];
        })
        ->all();

    $events = [
        ['title' => 'Fiesta ng Esperanza — Opening Program', 'date' => 'Aug 14, 2026', 'time' => '6:00 PM', 'venue' => 'Municipal Plaza'],
        ['title' => 'Barangay Poblacion Medical Mission', 'date' => 'Jul 18, 2026', 'time' => '8:00 AM', 'venue' => 'Poblacion Covered Court'],
        ['title' => 'Livelihood Skills Training', 'date' => 'Jul 25, 2026', 'time' => '1:00 PM', 'venue' => 'Municipal Hall Conference Room'],
    ];

    // Sampling: treated as true so the birthday greeting can be previewed on login.
    $isBirthdayToday = true;
@endphp

<x-layouts.citizen
    title="Dashboard"
    subtitle="Welcome back to your Esperanza Citizen Portal."
    active="dashboard"
>

    <div
        x-data='{
            ready: false,
            balitaPreview: @json($balitaPreview),

            toggleBalitaLike(post) {
                post.liked = !post.liked;
                post.likes += post.liked ? 1 : -1;
            },
        }'
        x-init="setTimeout(() => ready = true, 400)"
    >

        <!-- Skeleton state -->
        <div x-show="!ready" x-transition.opacity.duration.300ms>
            <x-ui.skeleton class="h-28 w-full rounded-2xl mb-4" />

            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
                @for ($i = 0; $i < 4; $i++)
                    <div class="bg-white rounded-2xl border border-slate-100 shadow-card p-4 space-y-3">
                        <x-ui.skeleton class="w-10 h-10 rounded-xl" />
                        <x-ui.skeleton class="h-6 w-16" />
                        <x-ui.skeleton class="h-3 w-24" />
                    </div>
                @endfor
            </div>
        </div>

        <!-- Real content -->
        <div
            x-show="ready"
            x-cloak
            x-transition:enter="transition ease-out duration-500"
            x-transition:enter-start="opacity-0 translate-y-2"
            x-transition:enter-end="opacity-100 translate-y-0"
        >

            <!-- Welcome hero -->
            <div class="relative rounded-2xl overflow-hidden mb-4 bg-gradient-to-br from-navy-900 via-navy-800 to-brand-700 shadow-card">
                <div class="absolute inset-0 opacity-20 bg-[radial-gradient(circle_at_top_right,theme(colors.white),transparent_55%)] pointer-events-none"></div>

                <div class="relative px-5 py-6 sm:px-7 sm:py-7 flex flex-col lg:flex-row lg:items-center gap-5">

                    <div class="flex items-center gap-4 flex-1 min-w-0">
                        <div class="relative shrink-0">
                            <div
                                class="w-14 h-14 text-lg rounded-full bg-white/15 backdrop-blur border-2 border-white/40 text-white flex items-center justify-center font-semibold shadow-lg"
                                x-text="$store.citizenSession.initials()"
                            ></div>

                            <span class="absolute -bottom-1 -right-1 w-5 h-5 rounded-full bg-emerald-500 border-2 border-navy-900 flex items-center justify-center">
                                <i data-lucide="check" class="w-2.5 h-2.5 text-white"></i>
                            </span>
                        </div>

                        <div class="min-w-0">
                            <p class="text-[11px] font-medium text-white/50 uppercase tracking-wide">
                                {{ now()->format('l, F j') }}
                            </p>

                            <h2
                                class="text-xl font-semibold text-white truncate"
                                x-text="($store.lang.current === 'en' ? 'Good day, ' : 'Magandang araw, ') + ($store.citizenSession.account?.firstName ?? 'Guest') + ' 👋'"
                            ></h2>

                            <p class="text-sm text-white/60 mt-0.5">
                                Brgy.
                                <span x-text="$store.citizenSession.account?.barangay ?? '—'"></span>
                                ·
                                <x-ui.t fil="narito ang buod ng iyong account." en="here's your account overview." />
                            </p>
                        </div>
                    </div>

                    <div class="flex items-center gap-2 shrink-0">
                        <x-ui.button
                            :href="route('citizen.assistance-requests')"
                            variant="ghost"
                            size="sm"
                            icon="hand-heart"
                            class="!text-white !bg-white/10 hover:!bg-white/20 !border !border-white/20"
                        >
                            Tulong
                        </x-ui.button>

                        <x-ui.button
                            :href="route('citizen.document-requests')"
                            variant="secondary"
                            size="sm"
                            icon="file-plus"
                            class="!border-0"
                        >
                            <x-ui.t fil="Bagong Kahilingan sa Dokyu" en="New Dokyu Request" />
                        </x-ui.button>
                    </div>

                </div>

                <!-- My Barangay — integrated into the hero, same footer-strip
                     pattern as the Profile page's completeness bar -->
                <div
                    x-show="$store.barangay.mine"
                    x-cloak
                    class="relative flex items-center gap-3 px-5 sm:px-7 py-3 border-t border-white/10"
                >
                    <div class="relative w-8 h-8 shrink-0">
                        <div class="absolute inset-0 rounded-full bg-white/10 flex items-center justify-center text-white/40">
                            <i data-lucide="landmark" class="w-3.5 h-3.5"></i>
                        </div>

                        <img
                            :src="$store.barangay.mine?.seal ? '{{ rtrim(asset(''), '/') }}/' + $store.barangay.mine.seal : ''"
                            x-show="$store.barangay.mine?.seal"
                            onerror="this.style.display='none'"
                            alt=""
                            class="relative w-8 h-8 rounded-full object-cover ring-1 ring-white/30"
                        >
                    </div>

                    <p class="min-w-0 flex-1 text-xs text-white/60 truncate">
                        <x-ui.t fil="Barangay" en="Barangay" />
                        <span class="font-semibold text-white" x-text="$store.barangay.mine?.label"></span>
                        <span class="text-white/25 mx-1">·</span>
                        <x-ui.t fil="Punong Barangay:" en="Punong Barangay:" />
                        <span class="text-white/90 font-medium" x-text="$store.barangay.mine?.officials?.punong_barangay"></span>
                    </p>

                    <a
                        :href="'tel:' + ($store.barangay.mine?.contact || '').replace(/[^0-9+]/g, '')"
                        x-show="$store.barangay.mine?.contact"
                        :title="$store.barangay.mine?.contact"
                        class="w-7 h-7 rounded-lg bg-white/10 hover:bg-white/20 flex items-center justify-center text-white/70 hover:text-white transition-colors shrink-0"
                    >
                        <i data-lucide="phone" class="w-3 h-3"></i>
                    </a>

                    <a
                        href="{{ route('citizen.directory') }}"
                        class="shrink-0 inline-flex items-center gap-0.5 text-[11px] font-medium text-white/70 hover:text-white transition-colors"
                    >
                        <x-ui.t fil="Tingnan" en="View" />
                        <i data-lucide="chevron-right" class="w-3 h-3"></i>
                    </a>
                </div>
            </div>

            @php
                $introFil = 'Ang <strong>Dokyu</strong> ay para sa paghingi ng mga dokumento ng munisipyo (clearance, ID, permit). Ang <strong>Tulong</strong> ay para sa pag-apply sa mga programang ayuda. Parehong simple ang hakbang: pumili, punan ang detalye, magbayad kung kailangan, pagkatapos i-review at i-submit — masusubaybayan mo anumang oras mula sa dashboard na ito.';

                $introEn = "<strong>Dokyu</strong> is for requesting municipal documents (clearances, IDs, permits). <strong>Tulong</strong> is for applying to assistance and ayuda programs. Both use the same simple steps: choose, fill in details, pay if needed, then review and submit — you can track progress anytime from this dashboard.";
            @endphp

            <x-ui.page-intro
                id="dashboard"
                icon="compass"
                title="Bago ka lang? Narito ang mabilisang gabay."
                titleEn="New here? Here's a quick orientation."
            >
                <span x-html="$store.lang.current === 'en' ? @js($introEn) : @js($introFil)">
                    {!! $introFil !!}
                </span>
            </x-ui.page-intro>

            <!-- KPI row -->
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5 mb-4">

                <x-ui.stat-card
                    :href="route('citizen.document-requests')"
                    label="Dokyu"
                    value="4"
                    icon="file-text"
                    color="brand"
                    sublabel="1 handa nang kunin"
                    sublabelEn="1 ready for release"
                    :delay="0"
                />

                <x-ui.stat-card
                    :href="route('citizen.assistance-requests')"
                    label="Tulong"
                    value="1"
                    icon="hand-heart"
                    color="purple"
                    sublabel="Aprubado ngayong buwan"
                    sublabelEn="Approved this month"
                    :delay="40"
                />

                <x-ui.stat-card
                    :href="route('citizen.notifications')"
                    label="Hindi Nabasang Abiso"
                    labelEn="Unread Notifications"
                    value="4"
                    icon="bell"
                    color="orange"
                    sublabel="2 nangangailangan ng aksyon"
                    sublabelEn="2 need your attention"
                    :delay="80"
                />

                <x-ui.stat-card
                    :href="route('citizen.profile')"
                    label="Pagkakumpleto ng Profile"
                    labelEn="Profile Completeness"
                    value="82%"
                    icon="user-round-check"
                    color="green"
                    trend="+10%"
                    sublabel="Magdagdag ng valid ID para matapos"
                    sublabelEn="Add a valid ID to finish"
                    :delay="120"
                />

            </div>

            <!-- Middle row: my requests + announcements -->
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-4">

                <x-ui.card padded="false" class="lg:col-span-2">

                    <div class="flex items-center justify-between px-4 pt-3.5 pb-2">
                        <h3 class="text-sm font-semibold text-navy-900">
                            <x-ui.t fil="Mga Kamakailang Kahilingan" en="My Recent Requests" />
                        </h3>

                        <a
                            href="{{ route('citizen.document-requests') }}"
                            class="text-xs font-medium text-brand-600 hover:underline"
                        >
                            <x-ui.t fil="Tingnan Lahat" en="View All" />
                        </a>
                    </div>

                    <div class="divide-y divide-slate-50">

                        @foreach($requests as $req)

                            <a
                                href="{{ route('citizen.document-requests') }}"
                                class="flex items-center justify-between gap-4 px-4 py-2.5 hover:bg-slate-50/70 transition-colors"
                            >

                                <div class="min-w-0">
                                    <p class="text-sm font-medium text-slate-700 truncate">
                                        {{ $req['type'] }}
                                    </p>

                                    <p class="text-xs text-slate-400 mt-0.5 font-mono">
                                        {{ $req['ref'] }}
                                        ·
                                        <x-ui.t fil="Isinumite" en="Submitted" />
                                        {{ $req['submitted'] }}
                                    </p>
                                </div>

                                <x-ui.badge
                                    :status="$req['status']"
                                    class="shrink-0"
                                />

                            </a>

                        @endforeach

                    </div>

                </x-ui.card>

                <x-ui.card padded="false">

                    <div class="flex items-center justify-between px-4 pt-3.5 pb-2">
                        <h3 class="text-sm font-semibold text-navy-900">
                            Balita
                        </h3>

                        <a
                            href="{{ route('citizen.announcements') }}"
                            class="text-xs font-medium text-brand-600 hover:underline"
                        >
                            <x-ui.t fil="Tingnan Lahat" en="View All" />
                        </a>
                    </div>

                    <div class="divide-y divide-slate-50">

                        <template x-for="post in balitaPreview" :key="post.id">

                            <div class="px-4 py-2.5 hover:bg-slate-50/70 transition-colors">

                                <a
                                    :href="'{{ route('citizen.announcements') }}'"
                                    class="flex items-start gap-2.5"
                                >

                                    <img
                                        :src="'{{ asset('images/esperanza/esperanza-seal.png') }}'"
                                        x-show="post.official"
                                        class="w-8 h-8 rounded-full object-cover ring-2 ring-white shadow-sm shrink-0"
                                    >

                                    <div
                                        x-show="!post.official"
                                        class="w-8 h-8 rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold shrink-0 text-[10px]"
                                        x-text="post.initials"
                                    ></div>

                                    <div class="min-w-0 flex-1">

                                        <p class="text-xs font-semibold text-navy-900 flex items-center gap-1 truncate">

                                            <span x-text="post.author"></span>

                                            <i
                                                data-lucide="badge-check"
                                                class="w-3 h-3 text-brand-500 shrink-0"
                                                x-show="post.official"
                                            ></i>

                                        </p>

                                        <p
                                            class="text-xs text-slate-500 mt-0.5 line-clamp-2 leading-snug"
                                            x-text="post.body"
                                        ></p>

                                        <p
                                            class="text-[10.5px] text-slate-400 mt-1"
                                            x-text="post.time"
                                        ></p>

                                    </div>

                                </a>

                                <div class="flex items-center gap-3 mt-1.5 ml-[42px]">

                                    <button
                                        type="button"
                                        @click="toggleBalitaLike(post)"
                                        class="flex items-center gap-1 text-[10.5px] font-medium transition-colors"
                                        :class="post.liked ? 'text-rose-600' : 'text-slate-400 hover:text-slate-600'"
                                    >
                                        <i
                                            data-lucide="heart"
                                            class="w-3 h-3 transition-transform"
                                            :class="post.liked && 'scale-125'"
                                            :style="post.liked ? 'fill: currentColor' : ''"
                                        ></i>

                                        <span x-text="post.likes"></span>
                                    </button>

                                    <a
                                        :href="'{{ route('citizen.announcements') }}'"
                                        class="flex items-center gap-1 text-[10.5px] font-medium text-slate-400 hover:text-slate-600 transition-colors"
                                        x-show="post.commentCount > 0"
                                    >
                                        <i data-lucide="message-circle" class="w-3 h-3"></i>
                                        <span x-text="post.commentCount"></span>
                                    </a>

                                </div>

                            </div>

                        </template>

                    </div>

                </x-ui.card>

            </div>

            <!-- Upcoming events -->
            <x-ui.card padded="false">

                <div class="flex items-center justify-between px-4 pt-3.5 pb-2">
                    <h3 class="text-sm font-semibold text-navy-900">
                        <x-ui.t fil="Mga Paparating na Kaganapan" en="Upcoming Events" />
                    </h3>

                    <a
                        href="{{ route('citizen.events') }}"
                        class="text-xs font-medium text-brand-600 hover:underline"
                    >
                        <x-ui.t fil="Tingnan Lahat" en="View All" />
                    </a>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-3 gap-3.5 px-4 pb-4">

                    @foreach($events as $event)

                        <a
                            href="{{ route('citizen.events') }}"
                            class="block rounded-xl border border-slate-100 p-3.5 hover:border-brand-200 hover:shadow-card hover:-translate-y-0.5 transition-all duration-300"
                        >

                            <div class="flex items-center gap-2 text-xs font-medium text-brand-600 mb-1.5">
                                <i data-lucide="calendar-days" class="w-3.5 h-3.5"></i>
                                {{ $event['date'] }} · {{ $event['time'] }}
                            </div>

                            <p class="text-sm font-medium text-slate-700 leading-snug">
                                {{ $event['title'] }}
                            </p>

                            <p class="text-xs text-slate-400 mt-1 flex items-center gap-1.5">
                                <i data-lucide="map-pin" class="w-3.5 h-3.5"></i>
                                {{ $event['venue'] }}
                            </p>

                        </a>

                    @endforeach

                </div>

            </x-ui.card>

        </div>
    </div>

    @if($isBirthdayToday)

        <div
            x-data
            x-init="setTimeout(() => {
                if (!sessionStorage.getItem('esperanza_birthday_seen')) {
                    $dispatch('show-birthday-popup');
                    sessionStorage.setItem('esperanza_birthday_seen', '1');
                }
            }, 1400)"
        ></div>

    @endif

</x-layouts.citizen>