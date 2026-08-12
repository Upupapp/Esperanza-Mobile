<?php

// Shared source of truth for Balita (community feed) posts, used by both
// citizen/announcements.blade.php (full feed) and citizen/dashboard.blade.php
// (compact preview) so the two stay in sync instead of drifting apart.

return [

    'categories' => ['All', 'Official', 'Community', 'Health', 'Public Service', 'Advisory', 'Livelihood'],

    'mediaLibrary' => [
        ['name' => 'Fiesta Rehearsal Photo.jpg', 'category' => 'IMG'],
        ['name' => 'Barangay Cleanup.jpg', 'category' => 'IMG'],
        ['name' => 'Medical Mission Clip.mp4', 'category' => 'VID'],
        ['name' => 'Salamat Po.gif', 'category' => 'GIF'],
        ['name' => 'Clapping Hands.gif', 'category' => 'GIF'],
    ],

    'posts' => [
        [
            'official' => true, 'author' => 'Esperanza LGU', 'barangay' => null, 'category' => 'Community',
            'time' => 'Posted yesterday', 'body' => 'Sumali sa buong-munisipyong pagdiriwang ngayong Agosto! Street dancing, trade fair, at gabi-gabing cultural program sa Municipal Plaza. Maligayang pagdating sa lahat! 🎉',
            'image' => 'esperanza_festival.jpg', 'video' => false,
            'likes' => 214, 'shares' => 58,
            'comments' => [
                ['author' => 'Rosemarie Tan', 'body' => 'Sana araw-araw may ganito, sobrang saya po ng fiesta natin! 🥳', 'time' => '20 hrs ago', 'likes' => 6, 'liked' => false],
                ['author' => 'Elmer Bantillo', 'body' => 'Anong oras po ang street dancing sa opening day?', 'time' => '18 hrs ago', 'likes' => 2, 'liked' => false],
            ],
        ],
        [
            'official' => false, 'author' => 'Elmer Bantillo', 'barangay' => 'Santiago', 'category' => null,
            'time' => '3 hrs ago', 'body' => 'Successful po ang blood donation drive natin ngayong araw dito sa Brgy. Santiago! Umabot ng 40+ na donors. Maraming salamat sa lahat ng dumalo at sa Red Cross Masbate! 🩸🙏',
            'image' => 'esperanza_community1.jpg', 'video' => false,
            'likes' => 47, 'shares' => 6,
            'comments' => [
                ['author' => 'Maria Fe Bacaltos', 'body' => 'Ang galing naman nito! Sana makasali ako sa susunod.', 'time' => '2 hrs ago', 'likes' => 3, 'liked' => false],
            ],
        ],
        [
            'official' => true, 'author' => 'Esperanza LGU', 'barangay' => null, 'category' => 'Health',
            'time' => 'Posted 3 days ago', 'body' => "Libreng check-up, dental extraction, at pamimigay ng gamot sa covered court. Magdala po ng valid ID at PhilHealth card kung meron. Sa lahat, halina't makinabang!",
            'image' => 'esperanza_people.jpg', 'video' => false,
            'likes' => 156, 'shares' => 31,
            'comments' => [
                ['author' => 'Teresita Salazar', 'body' => 'Pwede po ba isama ang lola ko na senior citizen?', 'time' => '2 days ago', 'likes' => 1, 'liked' => false],
            ],
        ],
        [
            'official' => false, 'author' => 'Michael Bacus', 'barangay' => 'Iligan', 'category' => null,
            'time' => '1 day ago', 'body' => 'May nakakita po ba nito? Nawala malapit sa covered court kagabi. Itim na may puting paa, mahiyain pero friendly naman. Tulungan niyo po ako i-share. 🐕💔',
            'image' => 'esperanza_event3.jpg', 'video' => false,
            'likes' => 29, 'shares' => 22,
            'comments' => [],
        ],
        [
            'official' => false, 'author' => 'Josefina Marbella', 'barangay' => 'Baras', 'category' => null,
            'time' => '1 day ago', 'body' => 'Gusto ko lang po magpasalamat sa MSWDO at OSCA sa mabilis na pag-asikaso ng aking social pension application. Simple lang pero malaking tulong na po sa amin. Maraming salamat po talaga! 🙏',
            'image' => null, 'video' => false,
            'likes' => 83, 'shares' => 4,
            'comments' => [
                ['author' => 'Corazon Villareal', 'body' => 'Salamat din po sa patuloy na tiwala sa aming serbisyo, Nanay Josefina! 💙', 'time' => '20 hrs ago', 'likes' => 9, 'liked' => false],
            ],
        ],
        [
            'official' => false, 'author' => 'Angelica Fajardo', 'barangay' => 'Rizal', 'category' => null,
            'time' => '2 days ago', 'body' => 'Coverage ng aming fiesta rehearsal kagabi! Ang saya-saya, sana dumagsa kayo sa opening program. 💃🎊',
            'image' => 'esperanza_event2.jpg', 'video' => true,
            'likes' => 61, 'shares' => 9,
            'comments' => [],
        ],
        [
            'official' => true, 'author' => 'Esperanza LGU', 'barangay' => null, 'category' => 'Public Service',
            'time' => 'Posted 5 days ago', 'body' => 'Maaari na pong bayaran online ang processing fees ng inyong document requests gamit ang GCash — hindi na kailangang pumila pa sa Municipal Hall.',
            'image' => 'esperanza-community.jpg', 'video' => false,
            'likes' => 98, 'shares' => 27,
            'comments' => [],
        ],
        [
            'official' => false, 'author' => 'Teresita Salazar', 'barangay' => 'Agoho', 'category' => null,
            'time' => '4 days ago', 'body' => 'Tanong lang po, kailan po ulit ang susunod na free medical mission? Gusto ko sanang isama ang lola ko na senior citizen. Salamat po sa sasagot!',
            'image' => null, 'video' => false,
            'likes' => 12, 'shares' => 1,
            'comments' => [
                ['author' => 'Esperanza LGU', 'body' => 'Magandang araw po! Target po namin ang susunod na medical mission sa Brgy. Masbaranon this August. Aabisuhan po namin dito sa Balita.', 'time' => '3 days ago', 'likes' => 5, 'liked' => false],
            ],
        ],
        [
            'official' => true, 'author' => 'Esperanza LGU', 'barangay' => null, 'category' => 'Advisory',
            'time' => 'Posted 1 week ago', 'body' => 'Naglabas ng low pressure area advisory ang PAGASA. Pinapaalalahanan ang mga residente sa mga coastal barangay na sundan ang mga update mula sa MDRRMO.',
            'image' => 'esperanza-boats.jpg', 'video' => false,
            'likes' => 74, 'shares' => 35,
            'comments' => [],
        ],
    ],

];
