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
    'Recorded by': 'Naitala ng',
    'Filed by you': 'In-file mo',
    'For': 'Para sa',
    'Fee paid': 'Bayad',
    'Free': 'Libre',
    "Office's number": 'Numero ng office',
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
    # Register + Tulong screens (flows review, 20 Nov 2026): the English that was not yet through tr().
    'Verification closed before it finished. You can start again now, or later from your profile.':
        'Nagsara ang verification bago natapos. Puwede kang magsimula ulit ngayon, o mamaya sa profile mo.',
    'Esperanza needs your camera for the ID scan and face check. Allow camera access in Settings, then try again.':
        'Kailangan ng Esperanza ang camera mo para sa ID scan at face check. I-allow ang camera sa Settings, tapos subukan ulit.',
    'That email is not valid. Check how it is written (for example: name@gmail.com).':
        'Hindi valid ang email. Tingnan kung tama ang pagkakasulat (halimbawa: name@gmail.com).',
    'Esperanza needs to let you choose a photo or scan of your valid ID. The LGU uses it to verify your account.':
        'Kailangan ng Esperanza na makapili ka ng photo o scan ng valid ID mo. Ginagamit ito ng LGU para i-verify ang account mo.',
    'Esperanza needs your camera to take a selfie. The LGU compares it with your valid ID to verify your account.':
        'Kailangan ng Esperanza ang camera mo para mag-selfie. Ikinukumpara ito ng LGU sa valid ID mo para i-verify ang account mo.',
    'First name': 'Pangalan',
    'Last name': 'Apelyido',
    'The code was sent to': 'Ipinadala ang code sa',
    'Check your spam folder too.': 'Tingnan din ang spam folder.',
    'ID uploaded': 'Na-upload na ang ID',
    'JPG, PNG, or PDF': 'JPG, PNG, o PDF',
    'Your Verification Status': 'Status ng verification mo',
    'Enter the 6-digit code sent to': 'Ilagay ang 6-digit code na ipinadala sa',
    'to confirm your account.': 'para kumpirmahin ang iyong account.',
    'Your account was created, but signing in did not work:':
        'Nagawa na ang account mo, pero hindi gumana ang pag-sign in:',
    'Checking your identity…': 'Chine-check ang identity mo…',
    'Your selfie is used only to verify your account: the LGU staff who review it compare it with your valid ID. It is not your profile photo and is never shown publicly.':
        'Ginagamit lang ang selfie mo para i-verify ang account mo: ikinukumpara ito ng LGU staff sa valid ID mo. Hindi ito ang profile photo mo at hindi ito ipinapakita sa iba.',
    'Have your valid ID ready. You will scan it with your camera, then do a quick face check - about 2 minutes. The check is done by Didit, our identity verification provider. You can also do this later from your profile.':
        'Ihanda ang valid ID mo. I-scan mo ito gamit ang camera, tapos mabilis na face check - mga 2 minuto. Ang Didit, ang identity verification provider namin, ang gagawa ng check. Puwede mo rin itong gawin mamaya sa profile mo.',
    'By creating an Esperanza account, you agree to provide accurate information for barangay/municipal record-keeping. Your data is used only for LGU service delivery (document requests, assistance programs, resident records) and is not shared with third parties. Esperanza LGU staff may contact you to verify submitted information. False or misleading information may result in your verification being rejected.':
        'Sa paggawa ng Esperanza account, pumapayag kang magbigay ng tamang impormasyon para sa records ng barangay at munisipyo. Ginagamit lang ang data mo para sa mga serbisyo ng LGU (document requests, assistance programs, resident records) at hindi ito ibinibigay sa iba. Puwede kang kontakin ng staff ng Esperanza LGU para i-check ang info na ibinigay mo. Kapag mali o nakakalito ang info, puwedeng ma-reject ang verification mo.',
    'Some of your details need a closer look from Esperanza LGU staff. No action needed from you right now.':
        'Kailangan pang tingnang mabuti ng staff ng Esperanza LGU ang ilang detalye mo. Wala ka pang kailangang gawin ngayon.',
    'Your account has been verified. You now have full access to Esperanza mobile services.':
        'Verified na ang account mo. Magagamit mo na lahat ng services ng Esperanza app.',
    'Your submission needs corrections before it can be verified. Please review and resubmit your information.':
        'May kailangang itama sa ipinasa mo bago ito ma-verify. Pakitingnan at ipasa ulit ang info mo.',
    'Complete your registration to begin the verification process.':
        'Tapusin ang registration mo para masimulan ang verification.',
    'Continue Registration': 'Ituloy ang Registration',
    'Submit and follow up assistance program requests.':
        'Mag-submit at i-follow up ang mga request para sa assistance programs.',
    'Done': 'Tapos na',
    'Share results': 'I-share ang results',
    'Clear All': 'I-clear lahat',
    'result': 'resulta',
    'No requests match your current filters.': 'Walang request na tugma sa filters mo.',
    'No active requests': 'Walang active na request',
    'No completed requests yet': 'Wala pang tapos na request',
    'Tap "New Request" to get started.': 'I-tap ang "Bagong hiling" para magsimula.',
    'Clear Filters': 'I-clear ang filters',
    'You can file a': 'Makakapag-file ka ng kahilingan sa',
    'request once the LGU has checked your valid ID and verified your account. You will be notified when that is done.':
        'kapag nasuri na ng LGU ang iyong valid ID at na-verify ang iyong account. Aabisuhan ka kapag tapos na ito.',
    'No requests yet': 'Wala pang request',
    'No Dokyu requests yet': 'Wala pang Dokyu request',
    'No Tulong requests yet': 'Wala pang Tulong request',
    'Your submitted Dokyu and Tulong requests will appear here.':
        'Dito lalabas ang mga Dokyu at Tulong request na in-file mo.',
    'Track This Request': 'I-track ang request na ito',
    'Back to Home': 'Bumalik sa Home',
    'Choose a type of': 'Pumili ng uri ng',
    'Where is this service administered?': 'Saan pinoproseso ang service na ito?',
    'Choose Barangay or Municipality-level services to narrow the list.':
        'Pumili ng Barangay o Municipal na services para umikli ang listahan.',
    'Which office handles this?': 'Aling office ang humahawak nito?',
    'Choose a department to see its specific services.': 'Pumili ng department para makita ang mga service nito.',
    'Search services': 'Maghanap ng service',
    'No service matches': 'Walang service na tugma sa',
    'Applicant Info': 'Info ng applicant',
    'Please complete': 'Pakisagutan ang',
    'numbers only.': 'numbers lang.',
    'enter the amount; the fee is computed from it.': 'ilagay ang halaga; dito kukuwentahin ang fee.',
    "We've prefilled this from your Resident Profile. Changes here only apply to this request — to update your saved profile, use Edit Profile.":
        'Kinuha namin ito sa Resident Profile mo. Sa request na ito lang ang mga babaguhin mo rito — para i-update ang naka-save mong profile, gamitin ang Edit Profile.',
    'Select': 'Pumili ng',
    'Choose one': 'Pumili ng isa',
    'Others (please specify)': 'Iba pa (pakisulat)',
    'None added yet.': 'Wala pang naidagdag.',
    'Add': 'Idagdag',
    'Remove': 'Alisin',
    'Process': 'Proseso',
    'e.g. Employment requirement, medical assistance for hospital bill...':
        'hal. requirement sa trabaho, medical assistance para sa hospital bill...',
    'Submit Request': 'I-submit ang request',
    'Additional notes (optional)': 'Dagdag na notes (optional)',
    'Additional notes': 'Dagdag na notes',
    'Make sure everything looks correct before submitting.': 'Siguraduhing tama lahat bago i-submit.',
    'Not attached yet — add it later from your request':
        'Hindi pa naka-attach — puwede mo itong idagdag mamaya sa request mo',
    'Not attached': 'Hindi naka-attach',
    'Opens the document full screen to zoom': 'Bubuksan ang document nang full screen para ma-zoom',
    'Tap to view full screen and pinch to zoom.': 'I-tap para makita nang full screen, at i-pinch para mag-zoom.',
    'Select your Date of Birth above first': 'Piliin muna ang Date of Birth mo sa itaas',
    'It may still have been filed: check your requests before you submit again.':
        'Baka na-file na ito: tingnan muna ang mga request mo bago mag-submit ulit.',
    'Your request was filed, but': 'Na-file na ang request mo, pero',
    'could not be uploaded. Add it from your request.': 'ay hindi na-upload. Idagdag ito mula sa request mo.',
    'That photo is larger than 5 MB. Please take or choose a smaller one.':
        'Lampas 5 MB ang photo. Kumuha o pumili ng mas maliit.',
    'Take Photo': 'Mag-picture',
    'Choose Image': 'Pumili ng image',
    'Choose File / PDF': 'Pumili ng file / PDF',
    'From My Papeles': 'Mula sa My Papeles',
    'Upload': 'I-upload',
    'Existing document found': 'May naka-save ka nang document',
    'Upload New Document': 'Mag-upload ng bagong document',
    'Use Existing Document': 'Gamitin ang naka-save na document',
    'Uploaded': 'Na-upload',
    'Handled by our staff during processing — no document to upload here.':
        'Ang staff na ang bahala dito habang pinoproseso — walang kailangang i-upload dito.',
    'Could not read the selected file. Please pick it again.': 'Hindi mabasa ang file na pinili mo. Pumili ulit.',
    'Document replaced.': 'Napalitan na ang document.',
    'Document attached.': 'Na-attach na ang document.',
    'Application resubmitted.': 'Na-resubmit na ang application.',
    'Withdraw this request?': 'Bawiin ang request na ito?',
    'The office stops working on': 'Ititigil ng office ang pag-process ng',
    'and it cannot be reopened. To ask again, file a new request.':
        'at hindi na ito mabubuksan ulit. Para humiling ulit, mag-file ng bago.',
    'Withdraw': 'Bawiin',
    'withdrawn.': 'binawi na.',
    'cannot be applied for in the app right now. Ask the office about it.':
        'ay hindi pa puwedeng i-apply sa app ngayon. Magtanong sa office.',
    'Admin remarks': 'Remarks ng office',
    'The reason is shown under Status below.': 'Nasa ilalim ng Status sa ibaba ang dahilan.',
    'No reason was given.': 'Walang ibinigay na dahilan.',
    'Submit a new': 'Mag-submit ng bagong',
    'The office could not confirm this report, or it repeats another one. If you still need help, report it again or call an emergency hotline.':
        'Hindi ma-confirm ng office ang report na ito, o kapareho ito ng ibang report. Kung kailangan mo pa rin ng tulong, mag-report ulit o tumawag sa emergency hotline.',
    'The request requires additional verification.': 'Kailangan pa ng dagdag na verification ang request.',
    'Withdraw Request': 'Bawiin ang request',
    'Request Timeline': 'Timeline ng request',
    'Status Timeline': 'Timeline ng status',
    'No history recorded yet.': 'Wala pang history.',
    'Application Rejected': 'Na-reject ang application',
    'What you can do:': 'Ang puwede mong gawin:',
    'Apply Again': 'Mag-apply ulit',
    'All flagged documents have been replaced — you may now resubmit.':
        'Napalitan na lahat ng na-flag na document — puwede mo na itong i-resubmit.',
    'documents need your attention.': 'na document ang kailangang ayusin.',
    '1 document requires correction.': '1 document ang kailangang itama.',
    '1 required document still needs to be attached.': '1 required document pa ang kailangang i-attach.',
    'replaced. The office checks it after you resubmit.':
        'napalitan na. Iche-check ito ng office kapag na-resubmit mo na.',
    'Replace the flagged documents above first, then resubmit.':
        'Palitan muna ang mga na-flag na document sa itaas, tapos i-resubmit.',
    'Replace the flagged document above first, then resubmit.':
        'Palitan muna ang na-flag na document sa itaas, tapos i-resubmit.',
    'Attach the required documents above first, then resubmit.':
        'I-attach muna ang mga required document sa itaas, tapos i-resubmit.',
    'Attach the required document above first, then resubmit.':
        'I-attach muna ang required document sa itaas, tapos i-resubmit.',
    'This request cannot be resubmitted right now. Pull down to refresh.':
        'Hindi pa ito ma-resubmit ngayon. I-pull down para mag-refresh.',
    '1 document was not accepted: replace it below so the office can review it again.':
        '1 document ang hindi tinanggap: palitan ito sa ibaba para ma-review ulit ng office.',
    'documents were not accepted: replace them below so the office can review them again.':
        'na document ang hindi tinanggap: palitan ang mga ito sa ibaba para ma-review ulit ng office.',
    'required documents still need to be attached.': 'na required document pa ang kailangang i-attach.',
    'Every required document is attached. You can change one until the office reviews it.':
        "Naka-attach na lahat ng required document. Puwede mo pang palitan hangga't hindi pa nare-review ng office.",
    'accepted by the office.': 'ang tinanggap ng office.',
    'Documents for this request': 'Mga document para sa request na ito',
    'Accepted by the office': 'Tinanggap ng office',
    'Not accepted by the office': 'Hindi tinanggap ng office',
    'The office asked for a replacement': 'Humingi ng kapalit ang office',
    'Replaced; the office checks it again': 'Napalitan na; iche-check ulit ng office',
    'With the office': 'Nasa office',
    'Not accepted by the office. Upload a replacement.': 'Hindi tinanggap ng office. Mag-upload ng kapalit.',
    'Approved — being prepared': 'Approved — inihahanda na',
    'Bring a valid ID to': 'Magdala ng valid ID sa',
    'to claim it.': 'para ma-claim ito.',
    'The office needs more for this case. Read the remarks above, or contact the MSWDO. This is still an active request, not a rejection.':
        'May kailangan pa ang office para sa case na ito. Basahin ang remarks sa itaas, o kontakin ang MSWDO. Active pa rin ang request na ito, hindi ito rejected.',
    'When you have done what the office asks, resubmit the request so they review it again.':
        'Kapag nagawa mo na ang hinihingi ng office, i-resubmit ang request para ma-review nila ulit.',
    'The request requires additional verification. This is still an active request, not a rejection — no action is needed from you at this time.':
        'Kailangan pa ng dagdag na verification ang request. Active pa rin ito, hindi rejected — wala ka pang kailangang gawin ngayon.',
    'Open photo': 'Buksan ang photo',
    'you sent with the report': 'na ipinadala mo kasama ng report',
    'Proof of release photo': 'Photo ng proof of release',
    'Could not open the file. Pull down to refresh, then try again.':
        'Hindi mabuksan ang file. I-pull down para mag-refresh, tapos subukan ulit.',
    'Dokyu Requests': 'Mga Dokyu request',
    'Tulong Requests': 'Mga Tulong request',
    'Active Requests': 'Mga active na request',
    'Account Details': 'Detalye ng account',
    'Start a Dokyu or Tulong request and track it here.': 'Mag-request ng Dokyu o Tulong at i-track ito dito.',
    'Latest Updates': 'Mga bagong update',
    'How can we help you today?': 'Paano ka namin matutulungan ngayon?',
    'Welcome, Guest': 'Welcome, Guest',
    "You're browsing public content. Sign in or create an account for full access.":
        'Public na content lang ang nakikita mo. Mag-sign in o gumawa ng account para magamit lahat.',
    'Create Account': 'Gumawa ng account',
    'Search services, permits, or documents': 'Maghanap ng serbisyo, permit, o dokumento',
    'A more accessible government for you.': 'Gobyernong mas abot-kamay mo.',
    'A more accessible government for you. Open the Government Directory.':
        'Gobyernong mas abot-kamay mo. Buksan ang Government Directory.',
    'Announcement': 'Anunsyo',
    'Complete your information so Esperanza LGU can maintain an accurate resident and household record.':
        'Kumpletuhin ang info mo para tama ang record mo at ng household mo sa Esperanza LGU.',
    'Some information needs to be updated.': 'May ilang info na kailangang i-update.',
    'Sections': 'Mga section',
    'Your basic, contact, and address details.': 'Ang basic info, contact, at address mo.',
    'Family Information': 'Impormasyon ng Pamilya',
    'Tell us about your family members living with you.': 'Ilagay ang mga kapamilyang kasama mo sa bahay.',
    'Household Information': 'Impormasyon ng Household',
    'Your residence, utilities, and who you live with.':
        'Ang bahay mo, utilities, at kung sino ang kasama mo sa bahay.',
    'Review & Submit': 'I-review at I-submit',
    'Sent to your barangay office. See what you sent.': 'Naipadala na sa barangay office mo. Tingnan ang ipinadala mo.',
    'Everything looks good — review and submit for verification.':
        'Mukhang ayos na lahat — i-review at i-submit para ma-verify.',
    'Fill in Personal Information to submit; Family and Household are optional.':
        'Punan ang Personal na Impormasyon para ma-submit; optional ang Pamilya at Household.',
    'Complete': 'Kumpleto',
    'Update Information': 'I-update ang impormasyon',
    'Submitted for validation': 'Naipadala na para ma-check',
    'Your barangay office is reviewing your information. This screen updates when they verify it.':
        'Chine-check ng barangay office mo ang info mo. Mag-a-update ang screen na ito kapag na-verify na nila.',
    'Complete your resident and household information.': 'Kumpletuhin ang info mo at ng household mo.',
    'Complete Resident Profile': 'Kumpletuhin ang Resident Profile',
    'Continue Resident Profile': 'Ituloy ang Resident Profile',
    'Your submitted information is currently being reviewed.': 'Chine-check pa ang info na ipinadala mo.',
    'Your resident profile has been verified by Esperanza LGU.':
        'Na-verify na ng Esperanza LGU ang resident profile mo.',
    'Continue your Resident Profile.': 'Ituloy ang Resident Profile mo.',
    'Esperanza LGU is reviewing your submission.': 'Chine-check ng Esperanza LGU ang ipinadala mo.',
    'Your resident profile has been verified.': 'Na-verify na ang resident profile mo.',
    'Submitted on': 'Na-submit noong',
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
