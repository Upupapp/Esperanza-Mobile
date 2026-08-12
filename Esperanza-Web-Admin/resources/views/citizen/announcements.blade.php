@php
    $initials = fn (string $name) => collect(preg_split('/\s+/', trim($name)))
        ->filter()->map(fn ($p) => mb_substr($p, 0, 1))->take(2)->implode('');
    $truncate = fn (string $s, int $len = 62) => mb_strlen($s) > $len ? mb_substr($s, 0, $len) . '…' : $s;

    // Shared with citizen/dashboard.blade.php's Balita preview — see config/esperanza_balita.php.
    $posts = config('esperanza_balita.posts');
    $categories = config('esperanza_balita.categories');
    $mediaLibrary = config('esperanza_balita.mediaLibrary');

    foreach ($posts as $i => $post) {
        $posts[$i]['id'] = $i;
        $posts[$i]['initials'] = $post['official'] ? 'LGU' : $initials($post['author']);
        $posts[$i]['liked'] = false;
        $posts[$i]['showComments'] = false;
        // Unify into a single media array — seed posts point at real bundled
        // images ('real' => true), composer-added posts get placeholder tiles.
        $posts[$i]['media'] = $post['image']
            ? [['name' => $post['image'], 'category' => $post['video'] ? 'VID' : 'IMG', 'real' => true]]
            : [];
        unset($posts[$i]['image'], $posts[$i]['video']);

        // Every comment can hold its own replies, shown nested right under it.
        foreach ($post['comments'] as $ci => $comment) {
            $posts[$i]['comments'][$ci]['initials'] = $comment['author'] === 'Esperanza LGU' ? 'LGU' : $initials($comment['author']);
            $posts[$i]['comments'][$ci]['replies'] = [];
        }
    }

    $recentPosts = collect($posts)->take(4);
    $trendingPosts = collect($posts)->sortByDesc('likes')->take(3)->values();

    $upcomingEvents = [
        ['month' => 'Aug', 'day' => '14', 'title' => 'Fiesta ng Esperanza — Opening Program', 'venue' => 'Municipal Plaza'],
        ['month' => 'Jul', 'day' => '18', 'title' => 'Barangay Poblacion Medical Mission', 'venue' => 'Poblacion Covered Court'],
        ['month' => 'Jul', 'day' => '25', 'title' => 'Livelihood Skills Training', 'venue' => 'Municipal Hall'],
    ];
@endphp

<x-layouts.citizen title="Balita" subtitle="Latest news from the municipality — and your neighbors." active="announcements">
    <div
        x-data="{
            cat: 'All',
            matchesCat(post) {
                if (this.cat === 'MyBarangay') return post.barangay === this.$store.citizenSession.account?.barangay;
                return this.cat === 'All' || (this.cat === 'Official' && post.official) || (this.cat === 'Community' && !post.official) || this.cat === post.category;
            },
            get filteredPostCount() { return this.posts.filter(p => this.matchesCat(p)).length; },
            posts: @js($posts),
            mediaLibrary: @js($mediaLibrary),
            open: false,
            sharePost: null,
            commentDraft: {},
            commentMedia: {},
            commentMediaPicker: null,
            replyingTo: {},
            replyText: {},
            myName() {
                const a = this.$store.citizenSession.account;
                return a ? a.fullName : 'Resident';
            },
            myInitials() { return this.$store.citizenSession.initials(); },
            toggleLike(post) {
                post.liked = !post.liked;
                post.likes += post.liked ? 1 : -1;
            },
            addComment(post) {
                const text = (this.commentDraft[post.id] || '').trim();
                const media = this.commentMedia[post.id] || null;
                if (!text && !media) return;
                post.comments.push({ author: this.myName(), initials: this.myInitials(), body: text, time: 'Ngayon lang', media, likes: 0, liked: false, replies: [] });
                this.commentDraft[post.id] = '';
                this.commentMedia[post.id] = null;
                this.commentMediaPicker = null;
                this.$nextTick(() => window.renderIcons?.());
            },
            toggleCommentLike(c) {
                c.liked = !c.liked;
                c.likes += c.liked ? 1 : -1;
            },
            startReply(post, ci, author) {
                this.replyingTo[post.id] = (this.replyingTo[post.id] === ci) ? null : ci;
                this.replyText[post.id] = '@' + author + ' ';
            },
            submitReply(post, ci) {
                const text = (this.replyText[post.id] || '').trim();
                if (!text) return;
                post.comments[ci].replies.push({ author: this.myName(), initials: this.myInitials(), body: text, time: 'Ngayon lang', likes: 0, liked: false });
                this.replyText[post.id] = '';
                this.replyingTo[post.id] = null;
                this.$nextTick(() => window.renderIcons?.());
            },
            openShare(post) { this.sharePost = post; this.open = true; },
            doShare() {
                if (this.sharePost) this.sharePost.shares++;
                this.open = false;
                this.$dispatch('toast', { message: 'Naibahagi sa iyong Balita feed!', variant: 'success' });
            },
            deletePost(post) {
                const idx = this.posts.findIndex(p => p.id === post.id);
                if (idx !== -1) this.posts.splice(idx, 1);
                this.$dispatch('toast', { message: 'Naalis ang post mo.', variant: 'success' });
            },
            hidePost(post) {
                const idx = this.posts.findIndex(p => p.id === post.id);
                if (idx !== -1) this.posts.splice(idx, 1);
                this.$dispatch('toast', { message: 'Itinago ang post na ito sa iyong feed.', variant: 'info' });
            },
            mutePost(post) {
                const author = post.author;
                for (let i = this.posts.length - 1; i >= 0; i--) {
                    if (this.posts[i].author === author) this.posts.splice(i, 1);
                }
                this.$dispatch('toast', { message: 'Na-mute mo si ' + author + '.', variant: 'info' });
            },
            postsToday(author) {
                return this.posts.filter(p => p.author === author && /hrs? ago|min ago|Ngayon lang/i.test(p.time)).length;
            },
        }"
        x-init="$nextTick(() => window.renderIcons?.())"
        class="animate-fade-up max-w-6xl mx-auto"
    >
        <x-ui.page-intro id="balita-feed" icon="users-round" title="Ngayon, pwede ka nang mag-post!" titleEn="You can now post to Balita!">
            <x-ui.t
                fil="Ibahagi ang balita, larawan, o video sa iyong komunidad. I-like, i-comment, o i-share ang mga post ng kapwa residente at ng munisipyo."
                en="Share news, photos, or videos with your community. Like, comment, or share posts from fellow residents and the municipality."
            />
        </x-ui.page-intro>

        <div class="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_300px] gap-5 items-start">
            <!-- Main column -->
            <div class="min-w-0">
                <!-- Composer trigger + modal: own scoped 'open', independent of the Share modal below -->
                <div x-data="{
                    open: false,
                    composerText: '',
                    composerMedia: [],
                    showMediaPicker: false,
                    pickerCategory: null,
                    audience: 'Lahat',
                    reset() { this.open = false; this.composerText = ''; this.composerMedia = []; this.showMediaPicker = false; this.pickerCategory = null; },
                    submit() {
                        if (!this.composerText.trim()) return;
                        const me = this.$store.citizenSession.account;
                        this.posts.unshift({
                            id: Date.now(), official: false, author: me ? me.fullName : 'Resident', barangay: me ? me.barangay : 'Poblacion', category: null,
                            time: 'Ngayon lang', body: this.composerText,
                            media: this.composerMedia.map(m => ({ name: m.name, category: m.category, real: false })),
                            likes: 0, shares: 0, comments: [],
                            initials: this.$store.citizenSession.initials(), liked: false, showComments: false,
                        });
                        this.reset();
                        this.$nextTick(() => window.renderIcons?.());
                        this.$dispatch('toast', { message: 'Na-post na! — this is a frontend preview, no data is saved.', variant: 'success' });
                    },
                }" class="contents">
                    <x-ui.card padded="false" class="mb-3 overflow-hidden hover:shadow-card-hover transition-shadow duration-300">
                        <div class="relative bg-gradient-to-br from-brand-50 via-white to-purple-50/60 px-4 pt-4 pb-3.5">
                            <div class="relative flex items-center gap-3">
                                <div class="relative shrink-0">
                                    <div class="w-10 h-10 text-sm rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold ring-2 ring-white shadow-sm shrink-0" x-text="$store.citizenSession.initials()"></div>
                                    <span class="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full bg-emerald-500 ring-2 ring-white"></span>
                                </div>
                                <button
                                    @click="open = true"
                                    class="flex-1 text-left group"
                                >
                                    <span class="block px-4 py-2.5 rounded-2xl bg-white border border-slate-200/80 text-slate-400 text-sm shadow-sm group-hover:border-brand-300 group-hover:shadow-card group-hover:-translate-y-0.5 transition-all duration-200">
                                        <span x-text="($store.lang.current === 'en' ? 'What\'s on your mind, ' : 'Ano ang balita mo, ') + ($store.citizenSession.account?.firstName ?? 'Resident') + '?'"></span>
                                    </span>
                                </button>
                            </div>
                        </div>
                        <div class="grid grid-cols-3 divide-x divide-slate-100 border-t border-slate-100">
                            <button @click="open = true; pickerCategory = 'IMG'; showMediaPicker = true" class="flex items-center justify-center gap-2 py-2.5 text-xs font-medium text-slate-500 hover:bg-emerald-50/70 hover:text-emerald-700 transition-colors">
                                <span class="w-6 h-6 rounded-full bg-emerald-50 text-emerald-500 flex items-center justify-center"><i data-lucide="image" class="w-3.5 h-3.5"></i></span>
                                <x-ui.t fil="Larawan" en="Photo" />
                            </button>
                            <button @click="open = true; pickerCategory = 'VID'; showMediaPicker = true" class="flex items-center justify-center gap-2 py-2.5 text-xs font-medium text-slate-500 hover:bg-rose-50/70 hover:text-rose-700 transition-colors">
                                <span class="w-6 h-6 rounded-full bg-rose-50 text-rose-500 flex items-center justify-center"><i data-lucide="video" class="w-3.5 h-3.5"></i></span>
                                <x-ui.t fil="Video" en="Video" />
                            </button>
                            <button @click="open = true; pickerCategory = 'GIF'; showMediaPicker = true" class="flex items-center justify-center gap-2 py-2.5 text-xs font-medium text-slate-500 hover:bg-purple-50/70 hover:text-purple-700 transition-colors">
                                <span class="w-6 h-6 rounded-full bg-purple-50 text-purple-500 flex items-center justify-center"><i data-lucide="sticker" class="w-3.5 h-3.5"></i></span>
                                <x-ui.t fil="GIF" en="GIF" />
                            </button>
                        </div>
                    </x-ui.card>

                    <x-ui.modal title="Gumawa ng Post" titleEn="Create Post" maxWidth="md">
                        <!-- Identity + audience -->
                        <div class="flex items-center gap-2.5 mb-3">
                            <div class="w-10 h-10 text-sm rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold ring-2 ring-white shadow-sm shrink-0" x-text="$store.citizenSession.initials()"></div>
                            <div class="min-w-0">
                                <p class="text-sm font-semibold text-navy-900" x-text="$store.citizenSession.account?.fullName || 'Resident'"></p>
                                <button
                                    type="button"
                                    @click="audience = audience === 'Lahat' ? 'Brgy. Poblacion' : 'Lahat'"
                                    class="inline-flex items-center gap-1 text-[11px] font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-md px-1.5 py-0.5 mt-0.5 transition-colors"
                                >
                                    <i data-lucide="globe" class="w-3 h-3"></i>
                                    <span x-text="audience"></span>
                                    <i data-lucide="chevron-down" class="w-3 h-3"></i>
                                </button>
                            </div>
                        </div>

                        <!-- Open, borderless textarea — feels like writing, not filling a form -->
                        <textarea
                            x-model="composerText"
                            rows="4"
                            x-bind:placeholder="$store.lang.current === 'en' ? 'Share something with your community...' : 'Ibahagi ang balita mo sa komunidad...'"
                            class="w-full border-0 bg-transparent text-[15px] leading-relaxed text-slate-800 placeholder:text-slate-400 focus:ring-0 outline-none resize-none px-0"
                        ></textarea>

                        <!-- Attached media: large FB-style preview tiles, still ours (soft gradients, rounded-2xl) -->
                        <div class="grid grid-cols-2 gap-2.5 mb-1" x-show="composerMedia.length > 0">
                            <template x-for="(m, mi) in composerMedia" :key="mi">
                                <div
                                    class="relative aspect-square rounded-2xl overflow-hidden border border-slate-200 flex flex-col items-center justify-center gap-1.5"
                                    :class="m.category === 'VID' ? 'bg-gradient-to-br from-rose-100 via-rose-50 to-white' : (m.category === 'GIF' ? 'bg-gradient-to-br from-purple-100 via-purple-50 to-white' : 'bg-gradient-to-br from-brand-100 via-brand-50 to-white')"
                                >
                                    <span class="w-12 h-12 rounded-full bg-white flex items-center justify-center shadow-card">
                                        <i data-lucide="image" class="w-6 h-6 text-brand-500" x-show="m.category === 'IMG'"></i>
                                        <i data-lucide="video" class="w-6 h-6 text-rose-500" x-show="m.category === 'VID'"></i>
                                        <i data-lucide="sticker" class="w-6 h-6 text-purple-500" x-show="m.category === 'GIF'"></i>
                                    </span>
                                    <span class="text-[11px] font-medium text-slate-600 px-3 truncate max-w-full" x-text="m.name"></span>
                                    <button
                                        type="button" @click="composerMedia.splice(mi, 1)"
                                        class="absolute top-2 right-2 w-7 h-7 rounded-full bg-navy-950/60 text-white flex items-center justify-center hover:bg-navy-950/80 transition-colors"
                                    ><i data-lucide="x" class="w-4 h-4"></i></button>
                                </div>
                            </template>
                            <button
                                type="button" @click="pickerCategory = null; showMediaPicker = !showMediaPicker"
                                class="aspect-square rounded-2xl border-2 border-dashed border-slate-200 flex flex-col items-center justify-center gap-1.5 text-slate-400 hover:border-brand-300 hover:bg-brand-50/40 hover:text-brand-500 transition-colors"
                            >
                                <span class="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center"><i data-lucide="plus" class="w-5 h-5"></i></span>
                                <span class="text-xs font-medium"><x-ui.t fil="Idagdag pa" en="Add more" /></span>
                            </button>
                        </div>

                        <!-- Add to your post -->
                        <div class="flex items-center justify-between rounded-xl border border-slate-200 px-3.5 py-2 mt-1">
                            <p class="text-xs font-medium text-slate-500"><x-ui.t fil="Idagdag sa post" en="Add to your post" /></p>
                            <div class="flex items-center gap-0.5">
                                <button type="button" @click="pickerCategory = 'IMG'; showMediaPicker = !(showMediaPicker && pickerCategory === 'IMG')" class="w-8 h-8 rounded-full hover:bg-emerald-50 flex items-center justify-center text-emerald-500 transition-colors"><i data-lucide="image" class="w-[18px] h-[18px]"></i></button>
                                <button type="button" @click="pickerCategory = 'VID'; showMediaPicker = !(showMediaPicker && pickerCategory === 'VID')" class="w-8 h-8 rounded-full hover:bg-rose-50 flex items-center justify-center text-rose-500 transition-colors"><i data-lucide="video" class="w-[18px] h-[18px]"></i></button>
                                <button type="button" @click="pickerCategory = 'GIF'; showMediaPicker = !(showMediaPicker && pickerCategory === 'GIF')" class="w-8 h-8 rounded-full hover:bg-purple-50 flex items-center justify-center text-purple-500 transition-colors"><i data-lucide="sticker" class="w-[18px] h-[18px]"></i></button>
                            </div>
                        </div>

                        <!-- Picker, filtered to whichever toolbar icon was clicked -->
                        <div x-show="showMediaPicker" x-cloak x-transition class="mt-2">
                            <x-ui.file-picker
                                files="mediaLibrary.filter(f => !pickerCategory || f.category === pickerCategory)"
                                onSelect="composerMedia.push(file); showMediaPicker = false; $nextTick(() => window.renderIcons?.())"
                                uploadAction="composerMedia.push({ name: pickerCategory === 'VID' ? 'New video.mp4' : 'New upload.jpg', category: pickerCategory || 'IMG' }); showMediaPicker = false; $nextTick(() => window.renderIcons?.()); $dispatch('toast', { message: 'File upload is a frontend preview — no data is saved.', variant: 'info' })"
                            />
                        </div>

                        <x-slot:footer>
                            <x-ui.button class="w-full" size="sm" icon="send" ::disabled="!composerText.trim()" @click="submit()"><x-ui.t fil="I-post" en="Post" /></x-ui.button>
                        </x-slot:footer>
                    </x-ui.modal>
                </div>

                <!-- Share modal (uses the page-level 'open') -->
                <x-ui.modal title="Ibahagi ang Post" titleEn="Share Post" maxWidth="sm">
                    <div class="space-y-2">
                        <button @click="doShare()" class="w-full flex items-center gap-3 rounded-xl border border-slate-200 p-2.5 hover:border-brand-300 hover:bg-brand-50/40 transition-colors text-left">
                            <span class="w-8 h-8 rounded-lg bg-brand-50 text-brand-600 flex items-center justify-center shrink-0"><i data-lucide="share-2" class="w-4 h-4"></i></span>
                            <span class="text-sm font-medium text-slate-700"><x-ui.t fil="Ibahagi sa Balita Feed" en="Share to Balita Feed" /></span>
                        </button>
                        <button @click="doShare()" class="w-full flex items-center gap-3 rounded-xl border border-slate-200 p-2.5 hover:border-brand-300 hover:bg-brand-50/40 transition-colors text-left">
                            <span class="w-8 h-8 rounded-lg bg-slate-100 text-slate-500 flex items-center justify-center shrink-0"><i data-lucide="link" class="w-4 h-4"></i></span>
                            <span class="text-sm font-medium text-slate-700"><x-ui.t fil="Kopyahin ang Link" en="Copy Link" /></span>
                        </button>
                    </div>
                    <x-slot:footer>
                        <x-ui.button variant="secondary" size="sm" @click="open = false"><x-ui.t fil="Isara" en="Close" /></x-ui.button>
                    </x-slot:footer>
                </x-ui.modal>

                <!-- Category filter -->
                <div class="bg-white border border-slate-200 rounded-2xl shadow-card p-3 mb-3 flex flex-wrap items-center justify-between gap-2">
                <div class="flex items-center gap-1.5 bg-slate-100/70 rounded-xl p-1 w-fit overflow-x-auto">
                    @foreach($categories as $c)
                        <button
                            @click="cat = '{{ $c }}'"
                            class="px-3 py-1.5 text-[11px] font-medium rounded-lg transition-colors whitespace-nowrap"
                            :class="cat === '{{ $c }}' ? 'bg-white text-navy-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'"
                        >@if($c === 'All')<x-ui.t fil="Lahat" en="All" />@elseif($c === 'Official')<x-ui.t fil="Opisyal" en="Official" />@elseif($c === 'Community')<x-ui.t fil="Komunidad" en="Community" />@else{{ $c }}@endif</button>
                    @endforeach
                    <button
                        x-show="$store.barangay.mine" x-cloak
                        @click="cat = 'MyBarangay'"
                        class="px-3 py-1.5 text-[11px] font-medium rounded-lg transition-colors whitespace-nowrap flex items-center gap-1"
                        :class="cat === 'MyBarangay' ? 'bg-white text-navy-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'"
                    ><i data-lucide="map-pinned" class="w-3 h-3"></i><x-ui.t fil="Aking Barangay" en="My Barangay" /></button>
                </div>
                <p class="text-[11px] text-slate-400 shrink-0" x-text="filteredPostCount + ' ' + ($store.lang.current === 'en' ? 'of ' + posts.length + ' posts' : 'sa ' + posts.length + ' post')"></p>
                </div>

                <!-- Feed -->
                <div class="space-y-3">
                    <template x-for="post in posts" :key="post.id">
                        <div
                            x-show="matchesCat(post)"
                            class="bg-white rounded-2xl border border-slate-100 shadow-card"
                        >
                            <!-- Header -->
                            <div class="flex items-center gap-2.5 p-3.5 pb-2.5">
                                <div class="relative shrink-0" x-data="{ showCard: false }" @mouseenter="showCard = true" @mouseleave="showCard = false">
                                    <img :src="'{{ asset('images/esperanza/esperanza-seal.png') }}'" x-show="post.official" class="w-9 h-9 rounded-full object-cover ring-2 ring-white shadow-sm cursor-pointer">
                                    <div x-show="!post.official" class="w-9 h-9 rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold ring-2 ring-white shadow-sm text-xs cursor-pointer">
                                        <span x-text="post.initials"></span>
                                    </div>

                                    <!-- Hover profile card -->
                                    <div
                                        x-show="showCard"
                                        x-transition:enter="transition ease-out duration-150"
                                        x-transition:enter-start="opacity-0 scale-95 -translate-y-1"
                                        x-transition:enter-end="opacity-100 scale-100 translate-y-0"
                                        x-cloak
                                        class="absolute left-0 top-full mt-2 z-20 w-64 bg-white rounded-2xl shadow-float border border-slate-100 p-4"
                                    >
                                        <div class="flex items-center gap-3 mb-3">
                                            <img :src="'{{ asset('images/esperanza/esperanza-seal.png') }}'" x-show="post.official" class="w-12 h-12 rounded-full object-cover ring-2 ring-white shadow-sm shrink-0">
                                            <div x-show="!post.official" class="w-12 h-12 rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold ring-2 ring-white shadow-sm shrink-0 text-sm">
                                                <span x-text="post.initials"></span>
                                            </div>
                                            <div class="min-w-0">
                                                <p class="text-sm font-semibold text-navy-900 flex items-center gap-1 truncate">
                                                    <span x-text="post.author"></span>
                                                    <i data-lucide="badge-check" class="w-3.5 h-3.5 text-brand-500 shrink-0" x-show="post.official"></i>
                                                </p>
                                                <p class="text-xs text-slate-400 truncate" x-text="post.official ? 'Opisyal na Account ng LGU' : ('Residente — Brgy. ' + post.barangay)"></p>
                                            </div>
                                        </div>
                                        <div class="rounded-xl bg-slate-50 border border-slate-100 px-3 py-2.5 flex items-center gap-2.5">
                                            <span class="w-7 h-7 rounded-lg bg-brand-50 text-brand-600 flex items-center justify-center shrink-0"><i data-lucide="calendar-check" class="w-3.5 h-3.5"></i></span>
                                            <p class="text-xs text-slate-600 leading-snug">
                                                <template x-if="postsToday(post.author) > 0">
                                                    <span><span class="font-semibold text-navy-900" x-text="postsToday(post.author)"></span> <x-ui.t fil="post ngayong araw" en="post(s) today" /></span>
                                                </template>
                                                <template x-if="postsToday(post.author) === 0">
                                                    <x-ui.t fil="Walang bagong post ngayong araw" en="No new posts today" />
                                                </template>
                                            </p>
                                        </div>
                                    </div>
                                </div>
                                <div class="min-w-0 flex-1">
                                    <p class="text-sm font-semibold text-navy-900 flex items-center gap-1.5 truncate">
                                        <span x-text="post.author"></span>
                                        <i data-lucide="badge-check" class="w-3.5 h-3.5 text-brand-500 shrink-0" x-show="post.official"></i>
                                    </p>
                                    <p class="text-[11px] text-slate-400" x-text="(post.barangay ? 'Brgy. ' + post.barangay + ' · ' : '') + post.time"></p>
                                </div>

                                <!-- Post options -->
                                <div class="relative shrink-0" x-data="{ menuOpen: false }" @click.outside="menuOpen = false">
                                    <button
                                        type="button" @click="menuOpen = !menuOpen"
                                        class="w-8 h-8 rounded-full flex items-center justify-center text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition-colors"
                                    ><i data-lucide="ellipsis-vertical" class="w-4 h-4"></i></button>
                                    <div
                                        x-show="menuOpen"
                                        x-transition:enter="transition ease-out duration-150"
                                        x-transition:enter-start="opacity-0 scale-95 -translate-y-1"
                                        x-transition:enter-end="opacity-100 scale-100 translate-y-0"
                                        x-cloak
                                        class="absolute right-0 top-full mt-1 z-20 w-48 bg-white rounded-2xl shadow-float border border-slate-100 py-1.5"
                                    >
                                        <button
                                            type="button" x-show="post.author === ($store.citizenSession.account?.fullName || '')"
                                            @click="deletePost(post); menuOpen = false"
                                            class="w-full flex items-center gap-2.5 px-3.5 py-2 text-left text-sm text-rose-600 hover:bg-rose-50 transition-colors"
                                        ><i data-lucide="trash-2" class="w-4 h-4"></i><x-ui.t fil="Burahin" en="Delete" /></button>
                                        <button
                                            type="button"
                                            @click="hidePost(post); menuOpen = false"
                                            class="w-full flex items-center gap-2.5 px-3.5 py-2 text-left text-sm text-slate-600 hover:bg-slate-50 transition-colors"
                                        ><i data-lucide="eye-off" class="w-4 h-4 text-slate-400"></i><x-ui.t fil="Itago" en="Hide" /></button>
                                        <button
                                            type="button" x-show="post.author !== ($store.citizenSession.account?.fullName || '')"
                                            @click="mutePost(post); menuOpen = false"
                                            class="w-full flex items-center gap-2.5 px-3.5 py-2 text-left text-sm text-slate-600 hover:bg-slate-50 transition-colors"
                                        ><i data-lucide="bell-off" class="w-4 h-4 text-slate-400"></i><span x-text="($store.lang.current === 'en' ? 'Mute ' : 'I-mute si ') + post.author"></span></button>
                                    </div>
                                </div>
                            </div>

                            <!-- Body -->
                            <p class="px-3.5 pb-2.5 text-[13px] text-slate-700 leading-relaxed whitespace-pre-line" x-text="post.body"></p>

                            <!-- Media: Facebook-style layouts depending on how many are attached -->
                            <div class="bg-slate-100" x-show="post.media && post.media.length > 0">
                                <!-- 1 item -->
                                <template x-if="post.media?.length === 1">
                                    <div class="relative">
                                        <template x-if="post.media[0].real">
                                            <img :src="'{{ asset('images/esperanza/') }}/' + post.media[0].name" alt="" class="w-full max-h-72 object-cover">
                                        </template>
                                        <template x-if="!post.media[0].real">
                                            <div
                                                class="w-full h-56 flex flex-col items-center justify-center gap-2"
                                                :class="post.media[0].category === 'VID' ? 'bg-gradient-to-br from-rose-100 via-rose-50 to-white' : (post.media[0].category === 'GIF' ? 'bg-gradient-to-br from-purple-100 via-purple-50 to-white' : 'bg-gradient-to-br from-brand-100 via-brand-50 to-white')"
                                            >
                                                <span class="w-14 h-14 rounded-full bg-white flex items-center justify-center shadow-card">
                                                    <i data-lucide="image" class="w-7 h-7 text-brand-500" x-show="post.media[0].category === 'IMG'"></i>
                                                    <i data-lucide="video" class="w-7 h-7 text-rose-500" x-show="post.media[0].category === 'VID'"></i>
                                                    <i data-lucide="sticker" class="w-7 h-7 text-purple-500" x-show="post.media[0].category === 'GIF'"></i>
                                                </span>
                                                <span class="text-xs font-medium text-slate-500" x-text="post.media[0].name"></span>
                                            </div>
                                        </template>
                                        <span x-show="post.media[0].category === 'VID'" class="absolute inset-0 flex items-center justify-center bg-navy-950/20 pointer-events-none">
                                            <span class="w-12 h-12 rounded-full bg-white/90 flex items-center justify-center shadow-float"><i data-lucide="play" class="w-5 h-5 text-navy-900 ml-0.5"></i></span>
                                        </span>
                                    </div>
                                </template>

                                <!-- 2 items: side by side -->
                                <template x-if="post.media?.length === 2">
                                    <div class="grid grid-cols-2 gap-0.5">
                                        <template x-for="(m, mi) in post.media" :key="mi">
                                            <div class="relative aspect-square overflow-hidden">
                                                <template x-if="m.real"><img :src="'{{ asset('images/esperanza/') }}/' + m.name" alt="" class="w-full h-full object-cover"></template>
                                                <template x-if="!m.real">
                                                    <div class="w-full h-full flex items-center justify-center" :class="m.category === 'VID' ? 'bg-gradient-to-br from-rose-100 to-rose-50' : (m.category === 'GIF' ? 'bg-gradient-to-br from-purple-100 to-purple-50' : 'bg-gradient-to-br from-brand-100 to-brand-50')">
                                                        <i data-lucide="image" class="w-7 h-7 text-brand-500" x-show="m.category === 'IMG'"></i>
                                                        <i data-lucide="video" class="w-7 h-7 text-rose-500" x-show="m.category === 'VID'"></i>
                                                        <i data-lucide="sticker" class="w-7 h-7 text-purple-500" x-show="m.category === 'GIF'"></i>
                                                    </div>
                                                </template>
                                                <span x-show="m.category === 'VID'" class="absolute inset-0 flex items-center justify-center bg-navy-950/20 pointer-events-none">
                                                    <span class="w-9 h-9 rounded-full bg-white/90 flex items-center justify-center shadow-float"><i data-lucide="play" class="w-4 h-4 text-navy-900 ml-0.5"></i></span>
                                                </span>
                                            </div>
                                        </template>
                                    </div>
                                </template>

                                <!-- 3 items: one large + two stacked -->
                                <template x-if="post.media?.length === 3">
                                    <div class="grid grid-cols-2 grid-rows-2 gap-0.5">
                                        <div class="relative row-span-2 overflow-hidden" style="min-height: 220px;">
                                            <template x-if="post.media[0].real"><img :src="'{{ asset('images/esperanza/') }}/' + post.media[0].name" alt="" class="w-full h-full object-cover absolute inset-0"></template>
                                            <template x-if="!post.media[0].real">
                                                <div class="w-full h-full absolute inset-0 flex items-center justify-center" :class="post.media[0].category === 'VID' ? 'bg-gradient-to-br from-rose-100 to-rose-50' : (post.media[0].category === 'GIF' ? 'bg-gradient-to-br from-purple-100 to-purple-50' : 'bg-gradient-to-br from-brand-100 to-brand-50')">
                                                    <i data-lucide="image" class="w-8 h-8 text-brand-500" x-show="post.media[0].category === 'IMG'"></i>
                                                    <i data-lucide="video" class="w-8 h-8 text-rose-500" x-show="post.media[0].category === 'VID'"></i>
                                                    <i data-lucide="sticker" class="w-8 h-8 text-purple-500" x-show="post.media[0].category === 'GIF'"></i>
                                                </div>
                                            </template>
                                        </div>
                                        <template x-for="mi in [1, 2]" :key="mi">
                                            <div class="relative aspect-square overflow-hidden">
                                                <template x-if="post.media[mi].real"><img :src="'{{ asset('images/esperanza/') }}/' + post.media[mi].name" alt="" class="w-full h-full object-cover"></template>
                                                <template x-if="!post.media[mi].real">
                                                    <div class="w-full h-full flex items-center justify-center" :class="post.media[mi].category === 'VID' ? 'bg-gradient-to-br from-rose-100 to-rose-50' : (post.media[mi].category === 'GIF' ? 'bg-gradient-to-br from-purple-100 to-purple-50' : 'bg-gradient-to-br from-brand-100 to-brand-50')">
                                                        <i data-lucide="image" class="w-6 h-6 text-brand-500" x-show="post.media[mi].category === 'IMG'"></i>
                                                        <i data-lucide="video" class="w-6 h-6 text-rose-500" x-show="post.media[mi].category === 'VID'"></i>
                                                        <i data-lucide="sticker" class="w-6 h-6 text-purple-500" x-show="post.media[mi].category === 'GIF'"></i>
                                                    </div>
                                                </template>
                                            </div>
                                        </template>
                                    </div>
                                </template>

                                <!-- 4+ items: 2x2 grid with a +N overlay -->
                                <template x-if="post.media?.length >= 4">
                                    <div class="grid grid-cols-2 gap-0.5">
                                        <template x-for="(m, mi) in post.media.slice(0, 4)" :key="mi">
                                            <div class="relative aspect-square overflow-hidden">
                                                <template x-if="m.real"><img :src="'{{ asset('images/esperanza/') }}/' + m.name" alt="" class="w-full h-full object-cover"></template>
                                                <template x-if="!m.real">
                                                    <div class="w-full h-full flex items-center justify-center" :class="m.category === 'VID' ? 'bg-gradient-to-br from-rose-100 to-rose-50' : (m.category === 'GIF' ? 'bg-gradient-to-br from-purple-100 to-purple-50' : 'bg-gradient-to-br from-brand-100 to-brand-50')">
                                                        <i data-lucide="image" class="w-7 h-7 text-brand-500" x-show="m.category === 'IMG'"></i>
                                                        <i data-lucide="video" class="w-7 h-7 text-rose-500" x-show="m.category === 'VID'"></i>
                                                        <i data-lucide="sticker" class="w-7 h-7 text-purple-500" x-show="m.category === 'GIF'"></i>
                                                    </div>
                                                </template>
                                                <div x-show="mi === 3 && post.media.length > 4" class="absolute inset-0 bg-navy-950/55 flex items-center justify-center">
                                                    <span class="text-white text-xl font-semibold" x-text="'+' + (post.media.length - 4)"></span>
                                                </div>
                                            </div>
                                        </template>
                                    </div>
                                </template>
                            </div>

                            <!-- Stats -->
                            <div class="flex items-center justify-between px-3.5 pt-2.5 text-[11px] text-slate-400" x-show="post.likes > 0 || post.comments.length > 0">
                                <span class="flex items-center gap-1" x-show="post.likes > 0">
                                    <span class="w-3.5 h-3.5 rounded-full bg-rose-500 flex items-center justify-center"><i data-lucide="heart" class="w-2 h-2 text-white" style="fill: white;"></i></span>
                                    <span x-text="post.likes"></span>
                                </span>
                                <button @click="post.showComments = !post.showComments" class="hover:underline" x-show="post.comments.length > 0">
                                    <span x-text="post.comments.length"></span> <x-ui.t fil="komento" en="comments" />
                                </button>
                            </div>

                            <!-- Actions -->
                            <div class="grid grid-cols-3 gap-1 px-2.5 py-1.5 mt-1.5 border-t border-slate-100">
                                <button
                                    @click="toggleLike(post)"
                                    class="flex items-center justify-center gap-1.5 text-xs font-medium py-1.5 rounded-lg hover:bg-slate-50 transition-colors"
                                    :class="post.liked ? 'text-rose-600' : 'text-slate-500'"
                                >
                                    <i data-lucide="heart" class="w-4 h-4 transition-transform" :class="post.liked && 'scale-125'" :style="post.liked ? 'fill: currentColor' : ''"></i>
                                    <x-ui.t fil="Gusto" en="Like" />
                                </button>
                                <button @click="post.showComments = !post.showComments" class="flex items-center justify-center gap-1.5 text-xs font-medium py-1.5 rounded-lg hover:bg-slate-50 transition-colors text-slate-500">
                                    <i data-lucide="message-circle" class="w-4 h-4"></i><x-ui.t fil="Komento" en="Comment" />
                                </button>
                                <button @click="openShare(post)" class="flex items-center justify-center gap-1.5 text-xs font-medium py-1.5 rounded-lg hover:bg-slate-50 transition-colors text-slate-500">
                                    <i data-lucide="share-2" class="w-4 h-4"></i><x-ui.t fil="Ibahagi" en="Share" />
                                </button>
                            </div>

                            <!-- Comments -->
                            <div x-show="post.showComments" x-cloak x-transition class="bg-slate-50/70 border-t border-slate-100 px-3.5 py-3 space-y-3">
                                <template x-for="(c, ci) in post.comments" :key="ci">
                                    <div class="flex items-start gap-2.5">
                                        <div class="w-7 h-7 rounded-full bg-gradient-to-br from-slate-400 to-slate-600 text-white flex items-center justify-center font-semibold shrink-0 text-[10px] mt-0.5">
                                            <span x-text="c.initials"></span>
                                        </div>
                                        <div class="min-w-0 flex-1">
                                            <div class="bg-white hover:shadow-card rounded-2xl px-3.5 py-2 inline-block max-w-full border border-slate-100 transition-shadow duration-200">
                                                <p class="text-[11px] font-semibold text-navy-900" x-text="c.author"></p>
                                                <p class="text-xs text-slate-600 mt-0.5 leading-snug" x-show="c.body" x-text="c.body"></p>
                                                <div
                                                    class="w-20 h-20 rounded-lg mt-1.5 flex items-center justify-center"
                                                    x-show="c.media"
                                                    :class="c.media?.category === 'VID' ? 'bg-rose-100' : (c.media?.category === 'GIF' ? 'bg-purple-100' : 'bg-brand-100')"
                                                >
                                                    <i data-lucide="image" class="w-6 h-6 text-brand-500" x-show="c.media?.category === 'IMG'"></i>
                                                    <i data-lucide="video" class="w-6 h-6 text-rose-500" x-show="c.media?.category === 'VID'"></i>
                                                    <i data-lucide="sticker" class="w-6 h-6 text-purple-500" x-show="c.media?.category === 'GIF'"></i>
                                                </div>
                                            </div>
                                            <div class="flex items-center gap-3 mt-1 ml-1">
                                                <button
                                                    type="button" @click="toggleCommentLike(c)"
                                                    class="text-[10.5px] font-semibold transition-colors"
                                                    :class="c.liked ? 'text-brand-600' : 'text-slate-400 hover:text-slate-600'"
                                                ><x-ui.t fil="Gusto" en="Like" /></button>
                                                <button
                                                    type="button" @click="startReply(post, ci, c.author)"
                                                    class="text-[10.5px] font-semibold transition-colors"
                                                    :class="replyingTo[post.id] === ci ? 'text-brand-600' : 'text-slate-400 hover:text-slate-600'"
                                                ><x-ui.t fil="Sagot" en="Reply" /></button>
                                                <span class="text-[10.5px] text-slate-300" x-text="c.time"></span>
                                                <span class="text-[10.5px] text-slate-400 flex items-center gap-1" x-show="c.likes > 0">
                                                    <i data-lucide="thumbs-up" class="w-2.5 h-2.5 text-brand-500" style="fill: currentColor"></i><span x-text="c.likes"></span>
                                                </span>
                                            </div>

                                            <!-- Nested replies to this comment -->
                                            <template x-for="(r, ri) in c.replies" :key="ri">
                                                <div class="flex items-start gap-2 mt-2">
                                                    <div class="w-6 h-6 rounded-full bg-gradient-to-br from-slate-400 to-slate-600 text-white flex items-center justify-center font-semibold shrink-0 text-[9px]">
                                                        <span x-text="r.initials"></span>
                                                    </div>
                                                    <div class="min-w-0 flex-1">
                                                        <div class="bg-white hover:shadow-card rounded-2xl px-3 py-1.5 inline-block max-w-full border border-slate-100 transition-shadow duration-200">
                                                            <p class="text-[10.5px] font-semibold text-navy-900" x-text="r.author"></p>
                                                            <p class="text-[11px] text-slate-600 mt-0.5 leading-snug" x-text="r.body"></p>
                                                        </div>
                                                        <div class="flex items-center gap-3 mt-1 ml-1">
                                                            <button
                                                                type="button" @click="toggleCommentLike(r)"
                                                                class="text-[10px] font-semibold transition-colors"
                                                                :class="r.liked ? 'text-brand-600' : 'text-slate-400 hover:text-slate-600'"
                                                            ><x-ui.t fil="Gusto" en="Like" /></button>
                                                            <span class="text-[10px] text-slate-300" x-text="r.time"></span>
                                                            <span class="text-[10px] text-slate-400 flex items-center gap-1" x-show="r.likes > 0">
                                                                <i data-lucide="thumbs-up" class="w-2.5 h-2.5 text-brand-500" style="fill: currentColor"></i><span x-text="r.likes"></span>
                                                            </span>
                                                        </div>
                                                    </div>
                                                </div>
                                            </template>

                                            <!-- Reply box: appears right under this comment (and its replies), Facebook-style -->
                                            <div x-show="replyingTo[post.id] === ci" x-cloak x-transition class="flex items-center gap-2 mt-2">
                                                <div class="w-6 h-6 rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold shrink-0 text-[9px]">MB</div>
                                                <div class="flex-1 relative">
                                                    <input
                                                        type="text"
                                                        x-model="replyText[post.id]"
                                                        @keydown.enter="submitReply(post, ci)"
                                                        x-bind:placeholder="$store.lang.current === 'en' ? 'Write a reply...' : 'Sumagot...'"
                                                        class="w-full rounded-full border border-slate-200 bg-white py-1.5 pl-3.5 pr-8 text-[11px] text-slate-800 placeholder:text-slate-400 shadow-sm focus:border-brand-400 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200"
                                                    >
                                                    <button type="button" @click="submitReply(post, ci)" class="absolute right-2 top-1/2 -translate-y-1/2 text-brand-500 hover:text-brand-700">
                                                        <i data-lucide="send" class="w-3 h-3"></i>
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </template>

                                <!-- Attached media preview, before sending -->
                                <div class="flex items-center gap-2 ml-9" x-show="commentMedia[post.id]" x-cloak>
                                    <div
                                        class="relative w-11 h-11 rounded-lg overflow-hidden border border-slate-200 flex items-center justify-center shrink-0 bg-white"
                                        :class="commentMedia[post.id]?.category === 'VID' ? 'bg-rose-50' : (commentMedia[post.id]?.category === 'GIF' ? 'bg-purple-50' : 'bg-brand-50')"
                                    >
                                        <i data-lucide="image" class="w-4 h-4 text-brand-500" x-show="commentMedia[post.id]?.category === 'IMG'"></i>
                                        <i data-lucide="video" class="w-4 h-4 text-rose-500" x-show="commentMedia[post.id]?.category === 'VID'"></i>
                                        <i data-lucide="sticker" class="w-4 h-4 text-purple-500" x-show="commentMedia[post.id]?.category === 'GIF'"></i>
                                        <button type="button" @click="commentMedia[post.id] = null" class="absolute top-0 right-0 w-3.5 h-3.5 rounded-full bg-navy-950/60 text-white flex items-center justify-center">
                                            <i data-lucide="x" class="w-2 h-2"></i>
                                        </button>
                                    </div>
                                </div>

                                <!-- Mini attach popover -->
                                <div x-show="commentMediaPicker === post.id" x-cloak x-transition class="ml-9">
                                    <x-ui.file-picker
                                        files="mediaLibrary"
                                        onSelect="commentMedia[post.id] = file; commentMediaPicker = null; $nextTick(() => window.renderIcons?.())"
                                        :columns="2"
                                        :search="false"
                                    />
                                </div>

                                <div class="flex items-center gap-2.5">
                                    <div class="w-7 h-7 text-[10px] rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold ring-2 ring-white shadow-sm shrink-0" x-text="$store.citizenSession.initials()"></div>
                                    <div class="flex-1 relative">
                                        <input
                                            type="text"
                                            x-model="commentDraft[post.id]"
                                            @keydown.enter="addComment(post)"
                                            x-bind:placeholder="$store.lang.current === 'en' ? 'Write a comment...' : 'Sumulat ng komento...'"
                                            class="w-full rounded-full border border-slate-200 bg-white py-2 pl-4 pr-[4.5rem] text-xs text-slate-800 placeholder:text-slate-400 shadow-sm focus:border-brand-400 focus:ring-4 focus:ring-brand-100 outline-none transition-all duration-200"
                                        >
                                        <div class="absolute right-1.5 top-1/2 -translate-y-1/2 flex items-center gap-0.5">
                                            <button
                                                type="button"
                                                @click="commentMediaPicker = (commentMediaPicker === post.id ? null : post.id)"
                                                class="w-6 h-6 rounded-full flex items-center justify-center transition-colors"
                                                :class="commentMediaPicker === post.id ? 'bg-brand-50 text-brand-600' : 'text-slate-400 hover:bg-slate-100 hover:text-brand-600'"
                                            ><i data-lucide="image-plus" class="w-3.5 h-3.5"></i></button>
                                            <button
                                                type="button" @click="addComment(post)"
                                                class="w-6 h-6 rounded-full flex items-center justify-center text-brand-500 hover:bg-brand-50 hover:text-brand-700 transition-colors"
                                            ><i data-lucide="send" class="w-3.5 h-3.5"></i></button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </template>
                    <div class="flex flex-col items-center text-center py-12 bg-white rounded-2xl border border-slate-100" x-show="filteredPostCount === 0">
                        <span class="w-11 h-11 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center mb-3"><i data-lucide="megaphone-off" class="w-5 h-5"></i></span>
                        <p class="text-sm font-medium text-slate-600"><x-ui.t fil="Wala pang balita sa kategoryang ito." en="No Balita posts in this category yet." /></p>
                    </div>
                </div>
            </div>

            <!-- Sidebar: sticks in place and scrolls independently of the feed -->
            <div class="hidden lg:block sticky top-4 max-h-[calc(100vh-6rem)] overflow-y-auto scrollbar-thin space-y-4 pr-1">
                <x-ui.card padded="false" class="p-3.5">
                    <p class="text-xs font-semibold text-navy-900 uppercase tracking-wide mb-2.5 flex items-center gap-1.5">
                        <i data-lucide="clock" class="w-3.5 h-3.5 text-slate-400"></i><x-ui.t fil="Kamakailang Post" en="Recent Posts" />
                    </p>
                    <div class="space-y-2.5">
                        @foreach($recentPosts as $rp)
                            <div class="flex items-start gap-2">
                                @if($rp['official'])
                                    <img src="{{ asset('images/esperanza/esperanza-seal.png') }}" alt="" class="w-7 h-7 rounded-full object-cover shrink-0">
                                @else
                                    <div class="w-7 h-7 rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold shrink-0 text-[9px]">{{ $rp['initials'] }}</div>
                                @endif
                                <div class="min-w-0">
                                    <p class="text-xs font-medium text-navy-900 truncate">{{ $rp['author'] }}</p>
                                    <p class="text-[11px] text-slate-400 leading-snug">{{ $truncate($rp['body']) }}</p>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </x-ui.card>

                <x-ui.card padded="false" class="p-3.5">
                    <p class="text-xs font-semibold text-navy-900 uppercase tracking-wide mb-2.5 flex items-center gap-1.5">
                        <i data-lucide="flame" class="w-3.5 h-3.5 text-orange-500"></i><x-ui.t fil="Trending sa Balita" en="Trending in Balita" />
                    </p>
                    <div class="space-y-2.5">
                        @foreach($trendingPosts as $tp)
                            <div class="flex items-start gap-2">
                                @if($tp['official'])
                                    <img src="{{ asset('images/esperanza/esperanza-seal.png') }}" alt="" class="w-7 h-7 rounded-full object-cover shrink-0">
                                @else
                                    <div class="w-7 h-7 rounded-full bg-gradient-to-br from-brand-500 to-navy-800 text-white flex items-center justify-center font-semibold shrink-0 text-[9px]">{{ $tp['initials'] }}</div>
                                @endif
                                <div class="min-w-0 flex-1">
                                    <p class="text-xs font-medium text-navy-900 truncate">{{ $tp['author'] }}</p>
                                    <p class="text-[11px] text-slate-400 leading-snug">{{ $truncate($tp['body'], 50) }}</p>
                                    <p class="text-[10px] text-rose-500 font-medium mt-0.5 flex items-center gap-1"><i data-lucide="heart" class="w-2.5 h-2.5" style="fill: currentColor"></i>{{ $tp['likes'] }} likes</p>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </x-ui.card>

                <x-ui.card padded="false" class="p-3.5">
                    <p class="text-xs font-semibold text-navy-900 uppercase tracking-wide mb-2.5 flex items-center gap-1.5">
                        <i data-lucide="calendar-days" class="w-3.5 h-3.5 text-slate-400"></i><x-ui.t fil="Paparating na Kaganapan" en="Upcoming Events" />
                    </p>
                    <div class="space-y-2.5">
                        @foreach($upcomingEvents as $ev)
                            <div class="flex items-center gap-2.5">
                                <div class="w-9 h-9 rounded-lg bg-brand-50 text-brand-600 flex flex-col items-center justify-center shrink-0 leading-none">
                                    <span class="text-xs font-bold">{{ $ev['day'] }}</span>
                                    <span class="text-[8px] font-semibold uppercase">{{ $ev['month'] }}</span>
                                </div>
                                <div class="min-w-0">
                                    <p class="text-xs font-medium text-navy-900 truncate">{{ $ev['title'] }}</p>
                                    <p class="text-[11px] text-slate-400 truncate">{{ $ev['venue'] }}</p>
                                </div>
                            </div>
                        @endforeach
                    </div>
                    <a href="{{ route('citizen.events') }}" class="block text-center text-[11px] font-medium text-brand-600 hover:underline mt-2.5 pt-2.5 border-t border-slate-100">
                        <x-ui.t fil="Tingnan Lahat" en="View All" />
                    </a>
                </x-ui.card>
            </div>
        </div>
    </div>
</x-layouts.citizen>
