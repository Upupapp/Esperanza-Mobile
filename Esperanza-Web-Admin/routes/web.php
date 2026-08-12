<?php

use Illuminate\Support\Facades\Route;

// Entry point — the single authentication screen where the user chooses
// between the Citizen Portal and the LGU Personnel (Administrative) Portal.
Route::view('/', 'auth.select-portal')->name('home');

// Citizen auth
Route::view('/citizen/login', 'auth.citizen-login')->name('citizen.login');
Route::view('/citizen/register', 'auth.citizen-register')->name('citizen.register');

// LGU Personnel auth
Route::view('/admin/login', 'auth.admin-login')->name('admin.login');

// Shared logout stub — frontend-only, returns to the portal chooser.
Route::view('/logout', 'auth.select-portal')->name('logout');

// Citizen Portal
Route::view('/citizen/dashboard', 'citizen.dashboard')->name('citizen.dashboard');
Route::view('/citizen/profile', 'citizen.profile')->name('citizen.profile');
Route::view('/citizen/document-requests', 'citizen.document-requests')->name('citizen.document-requests');
Route::view('/citizen/assistance-requests', 'citizen.assistance-requests')->name('citizen.assistance-requests');
Route::view('/citizen/notifications', 'citizen.notifications')->name('citizen.notifications');
Route::view('/citizen/directory', 'citizen.directory')->name('citizen.directory');
Route::view('/citizen/announcements', 'citizen.announcements')->name('citizen.announcements');
Route::view('/citizen/events', 'citizen.events')->name('citizen.events');
Route::view('/citizen/settings', 'citizen.settings')->name('citizen.settings');

// Help & Support — FAQs, Tutorials, and Support merged into one page with tabs.
// The three route names are kept so existing links deep-link into the right tab.
Route::view('/citizen/help', 'citizen.help', ['tab' => 'faqs'])->name('citizen.faqs');
Route::view('/citizen/help/tutorials', 'citizen.help', ['tab' => 'tutorials'])->name('citizen.tutorials');
Route::view('/citizen/help/support', 'citizen.help', ['tab' => 'support'])->name('citizen.support');

// Administrative Portal
Route::view('/admin/dashboard', 'admin.dashboard')->name('admin.dashboard');
Route::view('/admin/document-requests', 'admin.document-requests')->name('admin.document-requests');
Route::view('/admin/assistance-requests', 'admin.assistance-requests')->name('admin.assistance-requests');
Route::view('/admin/payments', 'admin.payments')->name('admin.payments');

// Constituents — Registry, Profiling Coverage, and Data Quality as tabs.
Route::view('/admin/constituents', 'admin.constituents', ['tab' => 'registry'])->name('admin.constituents');
Route::view('/admin/constituents/families', 'admin.constituents', ['tab' => 'registry', 'view' => 'families'])->name('admin.constituents.families');
Route::view('/admin/constituents/households', 'admin.constituents', ['tab' => 'registry', 'view' => 'households'])->name('admin.constituents.households');
Route::view('/admin/constituents/profiling', 'admin.constituents', ['tab' => 'profiling'])->name('admin.resident-profiling');
Route::view('/admin/constituents/data-quality', 'admin.constituents', ['tab' => 'data-quality'])->name('admin.constituents.data-quality');

// Communications — Balita (announcements) and Directory merged into one page with tabs.
Route::view('/admin/communications', 'admin.communications', ['tab' => 'balita'])->name('admin.communications');
Route::view('/admin/communications/offices', 'admin.communications', ['tab' => 'offices'])->name('admin.directory');
Route::view('/admin/announcements', 'admin.communications', ['tab' => 'balita'])->name('admin.announcements');

// Reports & Analytics — merged into one page with tabs.
Route::view('/admin/reports', 'admin.reports', ['tab' => 'reports'])->name('admin.reports');
Route::view('/admin/reports/analytics', 'admin.reports', ['tab' => 'analytics'])->name('admin.analytics');

// User Management — Personnel and Roles merged into one page with tabs.
Route::view('/admin/users', 'admin.users', ['tab' => 'personnel'])->name('admin.users');
Route::view('/admin/users/roles', 'admin.users', ['tab' => 'roles'])->name('admin.roles');
Route::view('/admin/users/permissions', 'admin.users', ['tab' => 'permissions'])->name('admin.permissions');

// Internal Forms — staff self-service forms (HR, GSO, Agriculture, MSWD), separate from citizen-facing Dokyu/Tulong.
Route::view('/admin/internal-forms', 'admin.internal-forms', ['office' => 'hr'])->name('admin.internal-forms');

// Settings — General, Notifications, Security, Branding, Integrations, Audit Logs as tabs.
Route::view('/admin/settings', 'admin.settings', ['tab' => 'general'])->name('admin.settings');
Route::view('/admin/settings/branding', 'admin.settings', ['tab' => 'branding'])->name('admin.branding');
Route::view('/admin/settings/audit-logs', 'admin.settings', ['tab' => 'audit-logs'])->name('admin.audit-logs');

// Sakuna — Disaster Risk Reduction, Emergency Operations, Evacuation, Relief, and Recovery Management.
// All sub-routes resolve to the same view with a tab parameter.
Route::view('/admin/sakuna', 'admin.sakuna', ['tab' => 'command-center'])->name('admin.sakuna');
Route::view('/admin/sakuna/vulnerability', 'admin.sakuna', ['tab' => 'vulnerability'])->name('admin.sakuna.vulnerability');
Route::view('/admin/sakuna/incidents', 'admin.sakuna', ['tab' => 'incidents'])->name('admin.sakuna.incidents');
Route::view('/admin/sakuna/evacuation-centers', 'admin.sakuna', ['tab' => 'evacuation-centers'])->name('admin.sakuna.evacuation-centers');
Route::view('/admin/sakuna/evacuees', 'admin.sakuna', ['tab' => 'evacuees'])->name('admin.sakuna.evacuees');
Route::view('/admin/sakuna/resources', 'admin.sakuna', ['tab' => 'resources'])->name('admin.sakuna.resources');
Route::view('/admin/sakuna/relief', 'admin.sakuna', ['tab' => 'relief'])->name('admin.sakuna.relief');
Route::view('/admin/sakuna/damage-assessment', 'admin.sakuna', ['tab' => 'damage-assessment'])->name('admin.sakuna.damage-assessment');
Route::view('/admin/sakuna/alerts', 'admin.sakuna', ['tab' => 'alerts'])->name('admin.sakuna.alerts');
Route::view('/admin/sakuna/reports', 'admin.sakuna', ['tab' => 'reports'])->name('admin.sakuna.reports');
