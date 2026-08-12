import './bootstrap';
import Alpine from 'alpinejs';
import { createIcons, icons } from 'lucide';
import { Chart, ArcElement, DoughnutController, LineElement, LineController, PointElement, BarElement, BarController, LinearScale, CategoryScale, Filler, Tooltip, Legend } from 'chart.js';

Chart.register(ArcElement, DoughnutController, LineElement, LineController, PointElement, BarElement, BarController, LinearScale, CategoryScale, Filler, Tooltip, Legend);
Chart.defaults.font.family = 'Inter, ui-sans-serif, system-ui, sans-serif';
Chart.defaults.color = '#64748b';

window.Alpine = Alpine;
window.Chart = Chart;

document.addEventListener('alpine:init', () => {
    Alpine.store('lang', {
        current: localStorage.getItem('esperanza_lang') || 'fil',
        set(lang) {
            this.current = lang;
            localStorage.setItem('esperanza_lang', lang);
        },
    });

    // Frontend-only "logged in as this role" simulation for the Administrative
    // Portal (see config/esperanza_rbac.php). No real auth — the account object
    // just persists to localStorage so nav/pages can gate content by module
    // access and Municipal/Barangay scope. No session -> fail-open (unrestricted
    // preview), since this is a design demo, not a real security boundary.
    Alpine.store('session', {
        account: JSON.parse(localStorage.getItem('esperanza_session') || 'null'),
        login(account) {
            this.account = account;
            localStorage.setItem('esperanza_session', JSON.stringify(account));
        },
        logout() {
            this.account = null;
            localStorage.removeItem('esperanza_session');
        },
        can(moduleKey) {
            if (!this.account) return true;
            return (this.account.moduleKeys || []).includes(moduleKey);
        },
        canPerm(submoduleKey, permission) {
            if (!this.account) return true;
            const perms = (this.account.permissions || {})[submoduleKey];
            if (!perms) return false;
            return Array.isArray(perms) ? perms.includes(permission) : perms === '*';
        },
        inScope(barangay) {
            if (!this.account) return true;
            if (this.account.scope === 'Municipal') return true;
            return this.account.scope === barangay;
        },
        initials() {
            if (!this.account) return 'GP';
            return this.account.name
                .split(/\s+/)
                .filter(Boolean)
                .map((part) => part[0])
                .slice(0, 2)
                .join('')
                .toUpperCase();
        },
    });

    // Frontend-only "logged in as this resident" simulation for the Citizen
    // Portal (see config/esperanza_citizens.php). Mirrors $store.session above
    // but simpler — citizens don't have module permissions, just a barangay
    // identity that Dokyu (and later other pages) can read to show the right
    // barangay-specific content.
    Alpine.store('citizenSession', {
        account: JSON.parse(localStorage.getItem('esperanza_citizen_session') || 'null'),
        login(account) {
            this.account = account;
            localStorage.setItem('esperanza_citizen_session', JSON.stringify(account));
        },
        logout() {
            this.account = null;
            localStorage.removeItem('esperanza_citizen_session');
        },
        initials() {
            if (!this.account) return 'CI';
            return ((this.account.firstName?.[0] || '') + (this.account.lastName?.[0] || '')).toUpperCase();
        },
    });

    // Per-barangay directory (see components/layouts/citizen.blade.php, which
    // injects window.__barangayCatalog from config/esperanza_barangay_documents.php).
    // `.mine` lets any Citizen Portal page show the signed-in resident's own
    // barangay seal/officials/contact without re-declaring the catalog per view.
    Alpine.store('barangay', {
        catalog: window.__barangayCatalog || {},
        get mine() {
            const b = Alpine.store('citizenSession').account?.barangay;
            return b ? this.catalog[b] || null : null;
        },
    });

    Alpine.data('dropdown', () => ({
        open: false,
        toggle() {
            this.open = !this.open;
        },
        close() {
            this.open = false;
        },
    }));

    Alpine.data('sidebar', () => ({
        collapsed: false,
        mobileOpen: false,
        toggleCollapsed() {
            this.collapsed = !this.collapsed;
        },
    }));

    Alpine.data('donutChart', (config) => ({
        chart: null,
        init() {
            this.chart = new Chart(this.$refs.canvas, {
                type: 'doughnut',
                data: {
                    labels: config.labels,
                    datasets: [{
                        data: config.values,
                        backgroundColor: config.colors,
                        borderWidth: 0,
                        hoverOffset: 6,
                    }],
                },
                options: {
                    cutout: '72%',
                    plugins: { legend: { display: false }, tooltip: { padding: 10, cornerRadius: 8 } },
                    animation: { duration: 900, easing: 'easeOutQuart' },
                    maintainAspectRatio: false,
                },
            });
        },
    }));

    Alpine.data('lineChart', (config) => ({
        chart: null,
        init() {
            this.chart = new Chart(this.$refs.canvas, {
                type: 'line',
                data: {
                    labels: config.labels,
                    datasets: config.datasets.map((set) => ({
                        label: set.label,
                        data: set.data,
                        borderColor: set.color,
                        backgroundColor: set.fill ?? 'transparent',
                        tension: 0.4,
                        fill: !!set.fill,
                        pointRadius: 0,
                        pointHoverRadius: 5,
                        pointBackgroundColor: set.color,
                        borderWidth: 2.5,
                    })),
                },
                options: {
                    maintainAspectRatio: false,
                    animation: { duration: 900, easing: 'easeOutQuart' },
                    interaction: { mode: 'index', intersect: false },
                    plugins: { legend: { display: false }, tooltip: { padding: 10, cornerRadius: 8 } },
                    scales: {
                        x: { grid: { display: false }, border: { display: false } },
                        y: { grid: { color: '#f1f5f9' }, border: { display: false }, ticks: { callback: (v) => config.yPrefix ? config.yPrefix + v : v } },
                    },
                },
            });
        },
    }));

    Alpine.data('barChart', (config) => ({
        chart: null,
        init() {
            this.chart = new Chart(this.$refs.canvas, {
                type: 'bar',
                data: {
                    labels: config.labels,
                    datasets: (config.datasets || [{ label: config.label, data: config.values, backgroundColor: config.colors || config.color }]).map((ds) => ({
                        label: ds.label,
                        data: ds.data,
                        backgroundColor: ds.color || ds.backgroundColor,
                        borderRadius: 6,
                        borderSkipped: false,
                    })),
                },
                options: {
                    indexAxis: config.horizontal ? 'y' : 'x',
                    maintainAspectRatio: false,
                    animation: { duration: 900, easing: 'easeOutQuart' },
                    plugins: {
                        legend: { display: !!config.showLegend },
                        tooltip: { padding: 10, cornerRadius: 8 },
                    },
                    scales: {
                        x: { grid: { display: config.horizontal ? false : true, color: '#f1f5f9' }, border: { display: false } },
                        y: { grid: { display: config.horizontal ? true : false, color: '#f1f5f9' }, border: { display: false } },
                    },
                },
            });
        },
    }));

    Alpine.data('passwordField', () => ({
        visible: false,
        toggle() {
            this.visible = !this.visible;
            window.renderIcons?.();
        },
    }));

    Alpine.data('authForm', (redirectUrl = null) => ({
        loading: false,
        done: false,
        submit() {
            if (this.loading) return;
            this.loading = true;
            setTimeout(() => {
                this.loading = false;
                if (redirectUrl) {
                    window.location.href = redirectUrl;
                } else {
                    this.done = true;
                    this.$dispatch('toast', { message: 'This portal is a frontend preview — sign-in is mocked for now.', variant: 'info' });
                    setTimeout(() => (this.done = false), 2600);
                }
            }, 900);
        },
    }));

    Alpine.data('toast', () => ({
        items: [],
        push(message, variant = 'success') {
            const id = Date.now() + Math.random();
            this.items.push({ id, message, variant });
            this.$nextTick(() => window.renderIcons?.());
            setTimeout(() => this.dismiss(id), 4000);
        },
        dismiss(id) {
            this.items = this.items.filter((item) => item.id !== id);
        },
    }));
});

// Lucide swaps each <i data-lucide> for a brand new <svg> node. Any Alpine
// directive on that icon (x-show, :class) only binds if Alpine walks the
// DOM *after* the swap — so icons must render before Alpine.start().
function renderIcons() {
    createIcons({ icons });
}

window.renderIcons = renderIcons;

renderIcons();

// Modals use x-teleport to escape transformed ancestors (see modal.blade.php).
// Teleported content lives inside an inert <template> until Alpine relocates
// it during its initial walk, so icons inside modals aren't in the live DOM
// yet when renderIcons() runs above — catch them once Alpine finishes init.
document.addEventListener('alpine:initialized', () => renderIcons());

Alpine.start();
