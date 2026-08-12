@php
    use Carbon\Carbon;

    $events = [
        ['title' => 'Fiesta ng Esperanza — Opening Program', 'date' => 'Aug 14, 2026', 'time' => '6:00 PM', 'venue' => 'Municipal Plaza', 'category' => 'Festival', 'barangay' => null],
        ['title' => 'Barangay Poblacion Medical Mission', 'date' => 'Jul 18, 2026', 'time' => '8:00 AM', 'venue' => 'Poblacion Covered Court', 'category' => 'Health', 'barangay' => 'Poblacion'],
        ['title' => 'Livelihood Skills Training — Batch 2', 'date' => 'Jul 25, 2026', 'time' => '1:00 PM', 'venue' => 'Municipal Hall Conference Room', 'category' => 'Livelihood', 'barangay' => null],
        ['title' => 'Brigada Eskwela 2026', 'date' => 'Aug 3, 2026', 'time' => '7:00 AM', 'venue' => 'Esperanza Central Elementary School', 'category' => 'Education', 'barangay' => 'Poblacion'],
        ['title' => 'Quarterly Barangay Assembly — Poblacion', 'date' => 'Aug 9, 2026', 'time' => '2:00 PM', 'venue' => 'Poblacion Barangay Hall', 'category' => 'Governance', 'barangay' => 'Poblacion'],
    ];

    $categoryColor = [
        'Festival' => 'bg-gold-500',
        'Health' => 'bg-emerald-500',
        'Livelihood' => 'bg-purple-500',
        'Education' => 'bg-blue-500',
        'Governance' => 'bg-brand-500',
    ];

    // Normalize each event with a Y-m-d key + display bits the calendar/list both need.
    $events = collect($events)->map(function ($e) use ($categoryColor) {
        $d = Carbon::parse($e['date']);
        $e['key'] = $d->format('Y-m-d');
        $e['day'] = $d->format('j');
        $e['monthShort'] = strtoupper($d->format('M'));
        $e['dotColor'] = $categoryColor[$e['category']] ?? 'bg-slate-400';
        return $e;
    })->values()->all();

    // Pre-build a full 12-month calendar grid (frontend-only mock, so there's
    // no live "today" to anchor to — Jan-Dec of the events' own year) so
    // citizens can browse the whole year, not just the months that happen to
    // have an event on them.
    $calendarYear = (int) Carbon::parse($events[0]['key'])->format('Y');
    $months = collect(range(1, 12))->map(function ($m) use ($calendarYear) {
        $first = Carbon::create($calendarYear, $m, 1);
        $cells = [];
        for ($i = 0; $i < $first->dayOfWeek; $i++) $cells[] = null;
        for ($d = 1; $d <= $first->daysInMonth; $d++) {
            $cells[] = ['day' => $d, 'key' => $first->copy()->day($d)->format('Y-m-d')];
        }
        while (count($cells) % 7 !== 0) $cells[] = null;
        return [
            'label' => $first->format('F Y'),
            'weeks' => array_chunk($cells, 7),
        ];
    })->values()->all();

    // Land on the month of the earliest event instead of always January.
    $defaultMonthIndex = ((int) Carbon::parse(collect($events)->min('key'))->format('n')) - 1;
@endphp

<x-layouts.citizen title="Events" subtitle="Upcoming municipal and barangay events." active="events">
    <div
        x-data="{
            reminders: {},
            events: @js($events),
            months: @js($months),
            categories: @js(collect($categoryColor)->map(fn ($color, $name) => ['name' => $name, 'color' => $color])->values()),
            monthIndex: {{ $defaultMonthIndex }},
            selectedDate: null,
            myBarangayOnly: false,
            get month() { return this.months[this.monthIndex]; },
            eventsOn(dateKey) { return this.events.filter(e => e.key === dateKey); },
            get selectedEvents() {
                const base = this.selectedDate ? this.eventsOn(this.selectedDate) : this.events;
                if (!this.myBarangayOnly) return base;
                return base.filter(e => e.barangay === this.$store.citizenSession.account?.barangay);
            },
            selectDay(cell) {
                if (!cell) return;
                this.selectedDate = this.selectedDate === cell.key ? null : cell.key;
            },
            prevMonth() { if (this.monthIndex > 0) { this.monthIndex--; this.selectedDate = null; } },
            nextMonth() { if (this.monthIndex < this.months.length - 1) { this.monthIndex++; this.selectedDate = null; } },
        }"
        class="animate-fade-up grid grid-cols-1 lg:grid-cols-[380px_minmax(0,1fr)] gap-5 items-start"
    >
        <!-- Calendar -->
        <div class="bg-white rounded-2xl border border-slate-200 shadow-card p-4">
            <!-- Legend: fixed at the very top so it never shifts position -->
            <div class="flex flex-wrap gap-x-3.5 gap-y-1.5 mb-3 pb-3 border-b border-slate-100">
                <template x-for="c in categories" :key="c.name">
                    <span class="flex items-center gap-1.5 text-[11px] text-slate-500">
                        <span class="w-2 h-2 rounded-full shrink-0" :class="c.color"></span>
                        <span x-text="c.name"></span>
                    </span>
                </template>
            </div>

            <div class="flex items-center justify-between mb-3">
                <p class="text-sm font-semibold text-navy-900" x-text="month?.label"></p>
                <div class="flex items-center gap-1">
                    <button type="button" @click="prevMonth()" :disabled="monthIndex === 0" class="w-7 h-7 rounded-lg flex items-center justify-center text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition-colors disabled:opacity-30 disabled:pointer-events-none">
                        <i data-lucide="chevron-left" class="w-4 h-4"></i>
                    </button>
                    <button type="button" @click="nextMonth()" :disabled="monthIndex === months.length - 1" class="w-7 h-7 rounded-lg flex items-center justify-center text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition-colors disabled:opacity-30 disabled:pointer-events-none">
                        <i data-lucide="chevron-right" class="w-4 h-4"></i>
                    </button>
                </div>
            </div>

            <div class="grid grid-cols-7 mb-1.5">
                <template x-for="d in ['S','M','T','W','T','F','S']" :key="d">
                    <p class="text-center text-[10px] font-semibold uppercase text-slate-400" x-text="d"></p>
                </template>
            </div>

            <template x-for="(week, wi) in month?.weeks || []" :key="wi">
                <div class="grid grid-cols-7 gap-1 mb-1">
                    <template x-for="(cell, ci) in week" :key="ci">
                        <button
                            type="button"
                            @click="selectDay(cell)"
                            :disabled="!cell"
                            class="aspect-square rounded-lg flex flex-col items-center justify-center gap-0.5 text-xs transition-all duration-150 relative"
                            :class="!cell ? 'pointer-events-none' : (selectedDate === cell.key ? 'bg-brand-600 text-white font-semibold shadow-sm' : (eventsOn(cell.key).length ? 'text-navy-900 font-medium hover:bg-brand-50' : 'text-slate-500 hover:bg-slate-50'))"
                        >
                            <span x-show="cell" x-text="cell?.day"></span>
                            <span class="flex items-center gap-0.5" x-show="cell && eventsOn(cell.key).length">
                                <template x-for="(e, ei) in (cell ? eventsOn(cell.key) : []).slice(0, 3)" :key="ei">
                                    <span class="w-1 h-1 rounded-full" :class="selectedDate === cell?.key ? 'bg-white' : e.dotColor"></span>
                                </template>
                            </span>
                        </button>
                    </template>
                </div>
            </template>

            <div class="flex items-center justify-between mt-3 pt-3 border-t border-slate-100" x-show="selectedDate">
                <p class="text-[11px] text-slate-400" x-text="$store.lang.current === 'en' ? 'Showing events for the selected date' : 'Ipinapakita ang mga kaganapan sa napiling petsa'"></p>
                <button type="button" @click="selectedDate = null" class="text-[11px] font-medium text-brand-600 hover:underline"><x-ui.t fil="I-clear" en="Clear" /></button>
            </div>
        </div>

        <!-- Event list -->
        <div class="space-y-3.5 min-w-0">
            <div class="flex items-center justify-between" x-show="$store.barangay.mine">
                <p class="text-xs text-slate-400" x-text="selectedEvents.length + ' ' + ($store.lang.current === 'en' ? 'events' : 'kaganapan')"></p>
                <button
                    type="button" @click="myBarangayOnly = !myBarangayOnly"
                    class="inline-flex items-center gap-1.5 text-[11px] font-medium rounded-lg px-2.5 py-1.5 transition-colors"
                    :class="myBarangayOnly ? 'bg-brand-600 text-white' : 'bg-slate-100 text-slate-500 hover:bg-slate-200'"
                ><i data-lucide="map-pinned" class="w-3 h-3"></i><x-ui.t fil="Aking Barangay Lang" en="My Barangay Only" /></button>
            </div>

            <template x-for="(event, i) in selectedEvents" :key="event.key + event.title">
                <x-ui.card>
                    <div class="flex items-center gap-4">
                        <div class="w-14 h-14 rounded-xl bg-brand-50 text-brand-700 flex flex-col items-center justify-center shrink-0">
                            <span class="text-lg font-bold leading-none" x-text="event.day"></span>
                            <span class="text-[10px] font-semibold uppercase tracking-wide" x-text="event.monthShort"></span>
                        </div>
                        <div class="min-w-0 flex-1">
                            <div class="flex items-center gap-2 flex-wrap">
                                <p class="text-sm font-semibold text-navy-900" x-text="event.title"></p>
                                <span class="text-[11px] font-medium text-brand-700 bg-brand-50 border border-brand-100 rounded-full px-2 py-0.5" x-text="event.category"></span>
                                <span
                                    class="text-[11px] font-medium text-emerald-700 bg-emerald-50 border border-emerald-100 rounded-full px-2 py-0.5 inline-flex items-center gap-1"
                                    x-show="event.barangay && event.barangay === $store.citizenSession.account?.barangay"
                                ><i data-lucide="map-pinned" class="w-3 h-3"></i><x-ui.t fil="Sa Aking Barangay" en="In My Barangay" /></span>
                            </div>
                            <p class="text-xs text-slate-400 mt-1 flex flex-wrap items-center gap-x-4 gap-y-1">
                                <span class="flex items-center gap-1.5"><i data-lucide="clock" class="w-3.5 h-3.5"></i><span x-text="event.time"></span></span>
                                <span class="flex items-center gap-1.5"><i data-lucide="map-pin" class="w-3.5 h-3.5"></i><span x-text="event.venue"></span></span>
                            </p>
                        </div>
                        <button
                            type="button"
                            class="shrink-0 hidden sm:inline-flex items-center justify-center gap-2 rounded-xl px-3.5 py-2 text-xs font-medium transition-all duration-200 active:scale-[0.97]"
                            :class="reminders[event.key + event.title] ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-white text-slate-700 border border-slate-200 shadow-card hover:bg-slate-50 hover:border-slate-300'"
                            @click="
                                reminders[event.key + event.title] = !reminders[event.key + event.title];
                                $dispatch('toast', { message: reminders[event.key + event.title] ? ($store.lang.current === 'en' ? 'We will remind you before this event starts.' : 'Paalalahanan ka namin bago magsimula ang kaganapang ito.') : ($store.lang.current === 'en' ? 'Reminder cancelled.' : 'Nakansela ang paalala.'), variant: reminders[event.key + event.title] ? 'success' : 'info' });
                            "
                        >
                            <i data-lucide="bell-check" class="w-3.5 h-3.5" x-show="reminders[event.key + event.title]"></i>
                            <i data-lucide="bell" class="w-3.5 h-3.5" x-show="!reminders[event.key + event.title]"></i>
                            <span x-text="reminders[event.key + event.title] ? ($store.lang.current === 'en' ? 'Reminder Set' : 'Naka-set na') : ($store.lang.current === 'en' ? 'Remind Me' : 'Paalalahanan Ako')"></span>
                        </button>
                    </div>
                </x-ui.card>
            </template>

            <div class="flex flex-col items-center text-center py-12 bg-white rounded-2xl border border-slate-100" x-show="selectedEvents.length === 0">
                <span class="w-11 h-11 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mb-3"><i data-lucide="calendar-x" class="w-5 h-5"></i></span>
                <p class="text-sm font-medium text-slate-600"><x-ui.t fil="Walang kaganapan sa petsang ito." en="No events on this date." /></p>
            </div>
        </div>
    </div>
</x-layouts.citizen>
