"""Builds lib/l10n/filipino_text.dart: the website's own Filipino for every
English phrase the app passes through tr().

Owner decision (2026-10-23): the app's Filipino is the website's wording.
Where the website has no Filipino for a phrase there is no entry, and the
app shows the English. Nothing here translates; it only looks up.

Usage (from Esperanza-Mobile-App/):
    python tool/l10n/build_filipino.py <web-repo-dir>
or set ESPERANZA_WEB_DIR to the Esperanza-Web-Platform-frontend checkout.
Read the website from an up-to-date checkout of its main branch.
"""
import html
import os
import re
import sys

APP = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LIB = os.path.join(APP, 'lib')
OUT = os.path.join(LIB, 'l10n', 'filipino_text.dart')

SQ = r"'((?:[^'\\]|\\.)*)'"
DQ = r'"((?:[^"\\]|\\.)*)"'

# Status names are the ruled names, shown as they are on the website too
# (profile.blade.php, "LANGUAGE (TAB 09)"): never translated.
STATUS_NAMES = {
    'Draft', 'Submitted', 'Pending Review', 'Under Verification', 'Assigned', 'Processing',
    'Under Review', 'Resubmitted', 'Approved', 'Rejected', 'Mark to Release', 'Released',
    'Completed', 'Cancelled', 'Archived', 'Verified', 'Unverified', 'Waiting Requirements',
    'Pending', 'In Progress', 'Failed', 'Requires Review', 'Revoked', 'For Validation',
    'Needs Requirements', 'Initial Screening', 'Needs Correction', 'Pending Verification',
}

# The website's words for these are the start of a longer phrase (its
# "Tapos na" step, "Naging ..." before a term), not the phrase on its own.
NOT_ON_THEIR_OWN = {'Done', 'Also served'}

# Phrases only the app shows, so the website has no Filipino for them (owner, 19 Nov 2026: "not too OA or
# deep filipino" - everyday Filipino or Taglish, common English words kept). The website's own wording wins
# wherever it has one.
APP_ONLY = {
    'Up to': 'Hanggang',
    'From the office': 'Mula sa office',
    'Recorded for you before you had an account, or at the office counter. Tap one to see it.':
        'Naitala ng office para sa iyo bago ka nagka-account, o sa counter nila. I-tap para makita.',
    'The documents and assistance on your record: what the offices recorded for you, and what you filed.':
        'Ang mga dokumento at tulong sa record mo: ang naitala ng mga office para sa iyo, at ang mga in-file mo.',
    'A photo helps responders see what is happening. Do not stop to take one if you are in danger.':
        'Mas makakatulong sa responders kung may photo. Pero kung delikado ka, huwag nang mag-picture.',
    'Take a photo': 'Mag-picture',
    'Choose a photo': 'Pumili ng photo',
    "You can follow it on the Emergency tab, below Report an Incident. You'll be notified as the office acts on it.":
        'Makikita mo ito sa Sakuna tab, sa ilalim ng Mag-ulat ng Insidente. Aabisuhan ka kapag may update na mula sa office.',
    'Your request status is now "Submitted". You\'ll be notified as it moves through review, approval, and release.':
        'Ang request mo ay "Submitted" na. Aabisuhan ka habang dumadaan ito sa review, approval at release.',
    'Tell the office what happened (optional). They will check the release.':
        'Sabihin sa office kung ano ang nangyari (optional). Iche-check nila ito.',
    'Comments': 'Mga comment',
    'Could not load comments.': 'Hindi ma-load ang mga comment.',
    'Reminder on · Turn off': 'May reminder na · I-off',
    'Read': 'Nabasa na',
    'Action Required': 'Kailangan ng aksyon',
    'Warning': 'Babala',
    'Esperanza LGU reviews your residency once your identity is verified: with the ID check below, or by LGU staff using your valid ID.':
        'Ire-review ng Esperanza LGU ang residency mo kapag verified na ang identity mo: gamit ang ID check sa ibaba, o ng staff ng LGU gamit ang valid ID mo.',
}

# A Filipino phrase ending in a linker is the first half of a sentence the
# website finishes with a name or a number ("Tawagan ang" + office).
LINKERS = ('ng', 'ang', 'sa', 'kay', 'ni', 'mga', 'nang')


def unjs(s):
    return re.sub(r'\\(.)', r'\1', s)


def files(root, exts):
    for d, _, names in os.walk(root):
        for n in sorted(names):
            if n.endswith(exts):
                yield os.path.join(d, n)


def web_pairs(web):
    """English -> Filipino from the website's bilingual markup and scripts."""
    pairs = {}

    def add(en, fil):
        en, fil = html.unescape(en).strip(), html.unescape(fil).strip()
        if not en or not fil or en == fil:
            return
        if any(x in en + fil for x in ('{{', '${', '@', '<', '`', '\n')):
            return
        pairs.setdefault(en, fil)

    for path in files(os.path.join(web, 'resources'), ('.php', '.js')):
        s = open(path, encoding='utf-8').read()
        for m in re.finditer(r'<x-ui\.t\b([^>]*?)/?>', s, re.S):
            fil = re.search(r'\bfil=' + DQ, m.group(1))
            en = re.search(r'\ben=' + DQ, m.group(1))
            if fil and en:
                add(en.group(1), fil.group(1))
        for attr in ('title', 'label', 'sublabel'):
            for m in re.finditer(r'\b' + attr + '=' + DQ + r'[^>]*?\b' + attr + 'En=' + DQ, s, re.S):
                add(m.group(2), m.group(1))
        # t(en, fil) and errorText(err, en, fil): English first.
        # A file can also have its own t(key, label) column helper
        # (sakuna-report.js: t('name', 'Centre')): there the first argument is
        # a data key, not English, and it once gave the app's "Name" the
        # Filipino "Centre" (QA sweep 2026-11-18). Its key-first calls are
        # left out.
        column_helper = re.search(r'\bconst\s+t\s*=\s*\(\s*key\s*,\s*label\s*\)', s)
        for m in re.finditer(r'\bt\(\s*' + SQ + r'\s*,\s*' + SQ + r'\s*\)', s):
            if column_helper and re.fullmatch(r'[a-z][a-z0-9_]*', m.group(1)):
                continue
            add(unjs(m.group(1)), unjs(m.group(2)))
        for m in re.finditer(r'errorText\([^,()]+,\s*' + SQ + r'\s*,\s*' + SQ + r'\s*\)', s):
            add(unjs(m.group(1)), unjs(m.group(2)))
        for m in re.finditer(r"(?:\ben|===\s*'en')\s*\?\s*" + SQ + r'\s*:\s*' + SQ, s):
            add(unjs(m.group(1)), unjs(m.group(2)))
        # The resident's incident words: named lists of ['English', 'Filipino', ...]
        # (scope-citizen.js INCIDENT_STATUS, INCIDENT_STEPS, SEVERITIES).
        for block in re.finditer(r'const (?:INCIDENT_STATUS|INCIDENT_STEPS|SEVERITIES) = ([\[{].*?[\]}]);', s, re.S):
            for m in re.finditer(r'\[\s*' + SQ + r'\s*,\s*' + SQ, block.group(1)):
                add(unjs(m.group(1)), unjs(m.group(2)))
    return pairs


def norm(s):
    return re.sub(r'[\s.!:]+$', '', s.strip()).lower()


def fit(app, fil):
    """The website's Filipino, shaped like the app's English: its closing
    punctuation and its capitals (a heading in capitals stays in capitals)."""
    core = fil.rstrip(' .:!')
    tail = re.search(r'[.:!]*$', app).group(0)
    out = core + tail
    letters = re.sub(r'[^A-Za-z]', '', app)
    if letters and letters.isupper() and len(letters) > 1:
        return out.upper()
    fil_letters = re.sub(r'[^A-Za-z]', '', out)
    if fil_letters.isupper() and len(fil_letters) > 1:
        out = out[:1] + out[1:].lower()  # a heading in capitals on the website only
    if app[:1].isupper() and out[:1].islower():
        out = out[:1].upper() + out[1:]
    if app[:1].islower() and out[:1].isupper():
        out = out[:1].lower() + out[1:]
    return out


def is_fragment(fil):
    words = fil.rstrip(' .:!').split()
    return bool(words) and words[-1].lower() in LINKERS


def app_phrases():
    """Every literal the app passes to tr()."""
    found = set()
    for path in files(LIB, ('.dart',)):
        if path == OUT:
            continue
        # Single or double quotes: a phrase with an apostrophe is written
        # tr("Your family's ...") and was missed (2026-10-27).
        for m in re.finditer(r'\btr\(\s*(?:' + SQ + '|' + DQ + r')\s*\)', open(path, encoding='utf-8').read()):
            found.add(unjs(m.group(1) if m.group(1) is not None else m.group(2)))
    return found


def matches(phrases, pairs):
    by_norm = {}
    for en, fil in pairs.items():
        if not is_fragment(fil):
            by_norm.setdefault(norm(en), fil)
    out = {}
    for p in phrases:
        if p != p.strip() or p in STATUS_NAMES or p in NOT_ON_THEIR_OWN or len(re.findall(r'[A-Za-z]', p)) < 3:
            continue
        fil = by_norm.get(norm(p))
        if fil:
            out[p] = fit(p, fil)
    return out


def dart(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


def main():
    web = sys.argv[1] if len(sys.argv) > 1 else os.environ.get('ESPERANZA_WEB_DIR')
    if not web or not os.path.isdir(os.path.join(web, 'resources')):
        sys.exit('Give the website checkout: build_filipino.py <web-repo-dir> (or ESPERANZA_WEB_DIR).')
    phrases = app_phrases()
    table = matches(phrases, web_pairs(web))
    for en, fil in APP_ONLY.items():
        if en in phrases and en not in table:
            table[en] = fil
    lines = [
        '// GENERATED by tool/l10n/build_filipino.py from the website\'s own',
        '// Filipino. Do not edit by hand: change the wording on the website, or',
        '// the English in the app, and run the tool again.',
        '//',
        '// A phrase the website has no Filipino for has no entry: the app shows',
        '// the English (owner, 2026-10-23), unless the tool\'s APP_ONLY list gives it',
        '// everyday Filipino or Taglish (owner, 2026-11-19).',
        '',
        'const Map<String, String> filipinoText = {',
    ]
    for en in sorted(table, key=lambda k: (k.lower(), k)):
        lines.append('  ' + dart(en) + ': ' + dart(table[en]) + ',')
    lines.append('};')
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(lines) + '\n')
    print(f'{len(table)} phrases in Filipino, {len(app_phrases()) - len(table)} stay English')


if __name__ == '__main__':
    main()
