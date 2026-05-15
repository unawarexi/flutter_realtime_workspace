import puppeteer from 'puppeteer';
import handlebars from 'handlebars';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ====================================================================================
// HANDLEBARS HELPERS
// ====================================================================================

// Register comparison helper
handlebars.registerHelper('eq', function (a, b) {
  return a === b;
});

// Register lookup helper (already built-in but ensuring it works)
handlebars.registerHelper('lookup', function (obj, key) {
  return obj && obj[key] !== undefined ? obj[key] : '';
});

// Register substr helper — used by member avatar initials
handlebars.registerHelper('substr', function (str, start, len) {
  return (str || '').toString().substr(start, len).toUpperCase();
});

// ====================================================================================
// TEMPLATE CACHE
// ====================================================================================

const templateCache = new Map();

const loadTemplate = (templateName) => {
  if (templateCache.has(templateName)) {
    return templateCache.get(templateName);
  }

  const templatePath = path.join(__dirname, '..', 'template', `${templateName}.html`);
  const templateContent = fs.readFileSync(templatePath, 'utf-8');
  const compiledTemplate = handlebars.compile(templateContent);

  templateCache.set(templateName, compiledTemplate);
  return compiledTemplate;
};

// ====================================================================================
// DEFAULT BRANDING
// ====================================================================================

const DEFAULT_BRANDING = {
  INSTITUTION_NAME: 'TeamSpot',
  TAGLINE: 'Enterprise Workspace Platform',
  LOGO_URL: 'https://res.cloudinary.com/dkt3rfpgz/image/upload/v1767626977/teamspot2_hrn11f.png',
  PRIMARY_COLOR: '#1e40af',
  SECONDARY_COLOR: '#1e3a8a',
  ACCENT_COLOR: '#10b981',
  DANGER_COLOR: '#ef4444'
};

// ====================================================================================
// PDF GENERATOR
// ====================================================================================

/**
 * Generate a PDF from an HTML template using Puppeteer
 * @param {Object} options - Generation options
 * @param {string} options.templateName - Name of the template (without .html extension)
 * @param {Object} options.data - Data to inject into the template
 * @param {Object} options.branding - Custom branding overrides
 * @param {Object} options.pdfOptions - Puppeteer PDF options
 * @returns {Promise<Buffer>} - PDF buffer
 */
export const generatePDFFromTemplate = async (options) => {
  const { templateName = 'pdf-base', data = {}, branding = {}, pdfOptions = {} } = options;

  // Merge branding with defaults
  const mergedBranding = { ...DEFAULT_BRANDING, ...branding };

  // Generate reference ID and date
  const referenceId = `TEAMSPOT-${Date.now().toString(36).toUpperCase()}`;
  const generatedDate = new Date().toLocaleDateString('en-GB', {
    day: '2-digit',
    month: 'long',
    year: 'numeric'
  });

  // Prepare template data
  const templateData = {
    ...data,
    ...mergedBranding,
    REFERENCE_ID: data.REFERENCE_ID || referenceId,
    GENERATED_DATE: data.GENERATED_DATE || generatedDate,
    PAGE_NUMBER: '{{page}}',
    TOTAL_PAGES: '{{pages}}'
  };

  // Load and compile template
  const template = loadTemplate(templateName);
  const html = template(templateData);

  // Launch Puppeteer
  let browser;
  try {
    browser = await puppeteer.launch({
      headless: 'new',
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-gpu']
    });

    const page = await browser.newPage();

    // Set content with wait until network idle
    await page.setContent(html, {
      waitUntil: ['load', 'networkidle0']
    });

    // Default PDF options
    const defaultPdfOptions = {
      format: 'A4',
      printBackground: true,
      margin: {
        top: '15mm',
        right: '15mm',
        bottom: '20mm',
        left: '15mm'
      },
      displayHeaderFooter: true,
      headerTemplate: `<div></div>`,
      footerTemplate: `
        <div style="width: 100%; font-size: 9px; padding: 0 15mm; display: flex; justify-content: space-between; color: #94a3b8; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;">
          <span style="color: #1e40af; font-weight: 600;">TeamSpot</span>
          <span>Enterprise Workspace Platform</span>
          <span>Page <span class="pageNumber"></span> of <span class="totalPages"></span></span>
        </div>
      `
    };

    // Generate PDF
    const pdfBuffer = await page.pdf({
      ...defaultPdfOptions,
      ...pdfOptions
    });

    return pdfBuffer;
  } finally {
    if (browser) {
      await browser.close();
    }
  }
};

// ====================================================================================
// PROJECT REPORT PDF
// ====================================================================================

/**
 * Generate a Project Report — task breakdown, member stats, progress overview.
 * @param {{ project, tasks, members, branding }} options
 */
export const generateProjectReport = async (options) => {
  const { project, tasks = [], members = [], branding = {} } = options;

  const byStatus = tasks.reduce((acc, t) => { acc[t.status] = (acc[t.status] || 0) + 1; return acc; }, {});
  const overdueTasks = tasks.filter(t => t.dueDate && !t.completedAt && new Date(t.dueDate) < new Date()).length;
  const totalLogged = tasks.reduce((sum, t) => sum + (t.loggedHours || 0), 0);
  const totalEstimated = tasks.reduce((sum, t) => sum + (t.estimatedHours || 0), 0);
  const completionRate = tasks.length ? Math.round(((byStatus.done || 0) / tasks.length) * 100) : 0;

  const stats = [
    { label: 'Total Tasks', value: tasks.length },
    { label: 'Completed', value: byStatus.done || 0, class: 'success' },
    { label: 'In Progress', value: byStatus.in_progress || 0, class: 'primary' },
    { label: 'Blocked / Overdue', value: (byStatus.blocked || 0) + overdueTasks, class: overdueTasks > 0 ? 'danger' : 'warning' },
  ];

  const summary = [
    { label: 'Project', value: project.name },
    { label: 'Template', value: project.template || 'Kanban' },
    { label: 'Status', value: project.status, class: project.status === 'active' ? 'success' : 'warning' },
    { label: 'Priority', value: project.priority },
    { label: 'Completion', value: `${completionRate}%`, class: completionRate >= 80 ? 'success' : completionRate >= 40 ? 'primary' : 'warning' },
    { label: 'Time Logged', value: `${totalLogged}h / ${totalEstimated}h est.` },
  ];

  const tableData = tasks.slice(0, 150).map(t => ({
    key: t.key || '—',
    title: t.title?.length > 50 ? t.title.slice(0, 47) + '...' : t.title,
    assignee: t.assignedTo?.fullName || 'Unassigned',
    status: t.status,
    priority: t.priority,
    due: t.dueDate ? new Date(t.dueDate).toLocaleDateString('en-GB') : '—',
    hours: `${t.loggedHours || 0}h`,
  }));

  const tableColumns = [
    { header: 'Key', key: 'key' },
    { header: 'Title', key: 'title' },
    { header: 'Assignee', key: 'assignee' },
    { header: 'Status', key: 'status' },
    { header: 'Priority', key: 'priority' },
    { header: 'Due Date', key: 'due' },
    { header: 'Logged', key: 'hours' },
  ];

  const memberTableData = members.slice(0, 50).map(m => ({
    name: m.userId?.fullName || m.email || '—',
    role: m.role,
    status: m.status,
    tasks: tasks.filter(t => t.assignedTo?.toString() === m.userId?._id?.toString()).length,
    joined: m.joinedAt ? new Date(m.joinedAt).toLocaleDateString('en-GB') : '—',
  }));

  return generatePDFFromTemplate({
    templateName: 'pdf-base',
    data: {
      DOCUMENT_TITLE: `Project Report — ${project.name}`,
      DOCUMENT_SUBTITLE: `${project.template || 'Kanban'} · ${project.status?.toUpperCase()}`,
      SUMMARY: summary,
      SUMMARY_TITLE: 'Project Overview',
      STATS: stats,
      TABLE_TITLE: 'Task Breakdown',
      TABLE_COLUMNS: tableColumns,
      TABLE_DATA: tableData,
      MEMBERS: memberTableData.length ? memberTableData : undefined,
      DOC_STATUS: project.status,
    },
    branding,
  });
};

// ====================================================================================
// AUDIT LOG REPORT PDF
// ====================================================================================

/**
 * Generate a compliance Audit Log Report.
 * @param {{ logs, filters, generatedBy, branding }} options
 */
export const generateAuditReport = async (options) => {
  const { logs = [], filters = {}, generatedBy, branding = {} } = options;

  const successCount = logs.filter(l => l.status === 'success').length;
  const failureCount = logs.length - successCount;
  const byCategory = logs.reduce((acc, l) => { acc[l.category] = (acc[l.category] || 0) + 1; return acc; }, {});
  const topCategory = Object.entries(byCategory).sort((a, b) => b[1] - a[1])[0]?.[0] || '—';

  const stats = [
    { label: 'Total Events', value: logs.length },
    { label: 'Successful', value: successCount, class: 'success' },
    { label: 'Failed', value: failureCount, class: failureCount > 0 ? 'danger' : 'success' },
    { label: 'Top Category', value: topCategory, class: 'primary' },
  ];

  const summary = [
    { label: 'From', value: filters.from ? new Date(filters.from).toLocaleDateString('en-GB') : 'All time' },
    { label: 'To', value: filters.to ? new Date(filters.to).toLocaleDateString('en-GB') : 'Now' },
    { label: 'Category Filter', value: filters.category || 'All' },
    { label: 'Total Records', value: logs.length },
    { label: 'Success Rate', value: logs.length ? `${Math.round((successCount / logs.length) * 100)}%` : '—', class: 'success' },
    { label: 'Generated By', value: generatedBy || 'System' },
  ];

  const tableData = logs.slice(0, 500).map(l => ({
    actor: l.actor?.email || l.actor?.userId || '—',
    action: l.action,
    category: l.category,
    target: l.target?.name || l.target?.id || '—',
    status: l.status,
    ip: l.actor?.ip || '—',
    timestamp: new Date(l.createdAt).toLocaleString('en-GB'),
  }));

  const tableColumns = [
    { header: 'Actor', key: 'actor' },
    { header: 'Action', key: 'action' },
    { header: 'Category', key: 'category' },
    { header: 'Target', key: 'target' },
    { header: 'Status', key: 'status' },
    { header: 'IP Address', key: 'ip' },
    { header: 'Timestamp', key: 'timestamp' },
  ];

  return generatePDFFromTemplate({
    templateName: 'pdf-base',
    data: {
      DOCUMENT_TITLE: 'Audit Log Report',
      DOCUMENT_SUBTITLE: 'Compliance & Security Event Log',
      WATERMARK: 'CONFIDENTIAL',
      SUMMARY: summary,
      SUMMARY_TITLE: 'Report Parameters',
      STATS: stats,
      TABLE_TITLE: 'Audit Events',
      TABLE_COLUMNS: tableColumns,
      TABLE_DATA: tableData,
      GENERATED_BY: generatedBy,
      DOC_STATUS: 'Confidential',
    },
    branding,
  });
};

// ====================================================================================
// BILLING INVOICE PDF
// ====================================================================================

/**
 * Generate a Billing Invoice PDF.
 * @param {{ invoice, subscription, organization, branding }} options
 */
export const generateBillingInvoice = async (options) => {
  const { invoice, subscription, organization, branding = {} } = options;

  const tableData = (invoice.lineItems || []).map(item => ({
    description: item.description,
    qty: item.quantity ?? 1,
    unitPrice: `${invoice.currency || 'USD'} ${(item.unitPrice || 0).toFixed(2)}`,
    total: `${invoice.currency || 'USD'} ${(item.total || 0).toFixed(2)}`,
  }));

  const tableColumns = [
    { header: 'Description', key: 'description' },
    { header: 'Qty', key: 'qty' },
    { header: 'Unit Price', key: 'unitPrice' },
    { header: 'Amount', key: 'total' },
  ];

  const summary = [
    { label: 'Invoice #', value: invoice.invoiceNumber },
    { label: 'Organisation', value: organization?.name || '—' },
    { label: 'Plan', value: (subscription?.plan || 'free').toUpperCase() },
    { label: 'Billing Cycle', value: subscription?.billingCycle || 'monthly' },
    { label: 'Seats Used', value: subscription?.seats ? `${subscription.seats.used} / ${subscription.seats.purchased}` : '—' },
    { label: 'Amount', value: `${invoice.currency || 'USD'} ${(invoice.amount || 0).toFixed(2)}`, class: 'primary' },
  ];

  const statusMap = {
    paid: { type: 'success', title: 'Payment Received', content: `Confirmed on ${invoice.paidAt ? new Date(invoice.paidAt).toLocaleDateString('en-GB') : '—'}.` },
    failed: { type: 'danger', title: 'Payment Failed', content: 'Invoice could not be processed. Please update your payment method in Billing settings.' },
    refunded: { type: 'warning', title: 'Refunded', content: 'This invoice has been refunded.' },
    pending: { type: 'info', title: 'Payment Pending', content: `Due: ${invoice.dueDate ? new Date(invoice.dueDate).toLocaleDateString('en-GB') : 'Upon receipt'}.` },
  };

  return generatePDFFromTemplate({
    templateName: 'pdf-base',
    data: {
      DOCUMENT_TITLE: `Invoice ${invoice.invoiceNumber}`,
      DOCUMENT_SUBTITLE: `${organization?.name || 'TeamSpot'} · ${new Date(invoice.createdAt || Date.now()).toLocaleDateString('en-GB')}`,
      REFERENCE_ID: invoice.invoiceNumber,
      SUMMARY: summary,
      SUMMARY_TITLE: 'Invoice Details',
      TABLE_TITLE: 'Line Items',
      TABLE_COLUMNS: tableColumns,
      TABLE_DATA: tableData,
      INFO_BOX: statusMap[invoice.status] || statusMap.pending,
      DOC_STATUS: invoice.status,
      SHOW_SIGNATURE: false,
    },
    branding: { ...branding, INSTITUTION_NAME: organization?.name || 'TeamSpot' },
  });
};

// ====================================================================================
// TEAM REPORT PDF
// ====================================================================================

/**
 * Generate a Team Member Report with role/status/activity breakdown.
 * @param {{ team, members, recentActivity, branding }} options
 */
export const generateTeamReport = async (options) => {
  const { team, members = [], recentActivity = [], branding = {} } = options;

  const byRole = members.reduce((acc, m) => { acc[m.role] = (acc[m.role] || 0) + 1; return acc; }, {});
  const activeCount = members.filter(m => m.status === 'active').length;
  const invitedCount = members.filter(m => m.status === 'invited').length;

  const stats = [
    { label: 'Total Members', value: members.length },
    { label: 'Active', value: activeCount, class: 'success' },
    { label: 'Pending Invites', value: invitedCount, class: invitedCount > 0 ? 'warning' : 'success' },
    { label: 'Admins', value: (byRole.owner || 0) + (byRole.admin || 0), class: 'primary' },
  ];

  const summary = [
    { label: 'Team', value: team.name },
    { label: 'Total Members', value: members.length },
    { label: 'Active', value: activeCount, class: 'success' },
    { label: 'Suspended', value: members.filter(m => m.status === 'suspended').length, class: 'danger' },
    { label: 'Admins / Managers', value: (byRole.admin || 0) + (byRole.manager || 0), class: 'primary' },
    { label: 'Report Date', value: new Date().toLocaleDateString('en-GB') },
  ];

  const tableData = members.map(m => ({
    name: m.userId?.fullName || '—',
    email: m.userId?.email || m.email || '—',
    role: m.role,
    status: m.status,
    joined: m.joinedAt ? new Date(m.joinedAt).toLocaleDateString('en-GB') : '—',
    lastActive: m.lastActive ? new Date(m.lastActive).toLocaleDateString('en-GB') : '—',
  }));

  const tableColumns = [
    { header: 'Name', key: 'name' },
    { header: 'Email', key: 'email' },
    { header: 'Role', key: 'role' },
    { header: 'Status', key: 'status' },
    { header: 'Joined', key: 'joined' },
    { header: 'Last Active', key: 'lastActive' },
  ];

  const activityData = recentActivity.slice(0, 20).map(a => ({
    actor: a.actor?.fullName || '—',
    event: a.description || a.type,
    timestamp: new Date(a.timestamp).toLocaleString('en-GB'),
  }));

  return generatePDFFromTemplate({
    templateName: 'pdf-base',
    data: {
      DOCUMENT_TITLE: `Team Report — ${team.name}`,
      DOCUMENT_SUBTITLE: 'Member Directory & Activity Summary',
      SUMMARY: summary,
      SUMMARY_TITLE: 'Team Overview',
      STATS: stats,
      TABLE_TITLE: 'Member Directory',
      TABLE_COLUMNS: tableColumns,
      TABLE_DATA: tableData,
      ACTIVITY_ITEMS: activityData.length ? activityData : undefined,
      DOC_STATUS: 'Official',
    },
    branding,
  });
};

// ====================================================================================
// MEETING MINUTES PDF
// ====================================================================================

/**
 * Generate Meeting Minutes with attendee list and action items.
 * @param {{ meeting, attendees, actionItems, branding }} options
 */
export const generateMeetingMinutes = async (options) => {
  const { meeting, attendees = [], actionItems = [], branding = {} } = options;

  const accepted = attendees.filter(a => a.status === 'accepted').length;
  const declined = attendees.filter(a => a.status === 'declined').length;
  const pending  = attendees.filter(a => a.status === 'pending').length;

  const stats = [
    { label: 'Invited', value: attendees.length },
    { label: 'Accepted', value: accepted, class: 'success' },
    { label: 'Declined', value: declined, class: declined > 0 ? 'danger' : 'success' },
    { label: 'Pending', value: pending, class: pending > 0 ? 'warning' : 'success' },
  ];

  const summary = [
    { label: 'Meeting', value: meeting.meetingTitle },
    { label: 'Date', value: new Date(meeting.meetingDate).toLocaleDateString('en-GB') },
    { label: 'Time', value: `${meeting.meetingTime?.start || '—'} – ${meeting.meetingTime?.end || '—'}` },
    { label: 'Duration', value: `${meeting.duration} min` },
    { label: 'Organiser', value: meeting.organizer?.name || '—' },
    { label: 'Location / Link', value: meeting.meetingLink ? 'Virtual (link attached)' : meeting.location || 'TBD' },
  ];

  const tableData = attendees.map(a => ({
    name: a.name || a.email || '—',
    email: a.email || '—',
    rsvp: a.status || 'pending',
    respondedAt: a.respondedAt ? new Date(a.respondedAt).toLocaleDateString('en-GB') : '—',
  }));

  const tableColumns = [
    { header: 'Name', key: 'name' },
    { header: 'Email', key: 'email' },
    { header: 'RSVP', key: 'rsvp' },
    { header: 'Responded', key: 'respondedAt' },
  ];

  const actionTableData = actionItems.map((item, i) => ({
    no: i + 1,
    action: item.action || item.description || '—',
    owner: item.owner || item.assignedTo || '—',
    due: item.dueDate ? new Date(item.dueDate).toLocaleDateString('en-GB') : '—',
    status: item.status || 'open',
  }));

  const infoBox = meeting.agenda
    ? { type: 'info', title: 'Meeting Agenda', content: meeting.agenda }
    : null;

  return generatePDFFromTemplate({
    templateName: 'pdf-base',
    data: {
      DOCUMENT_TITLE: meeting.meetingTitle,
      DOCUMENT_SUBTITLE: `Meeting Minutes · ${new Date(meeting.meetingDate).toLocaleDateString('en-GB')}`,
      REFERENCE_ID: meeting._id?.toString(),
      SUMMARY: summary,
      SUMMARY_TITLE: 'Meeting Details',
      STATS: stats,
      TABLE_TITLE: 'Attendees',
      TABLE_COLUMNS: tableColumns,
      TABLE_DATA: tableData,
      INFO_BOX: infoBox,
      ACTION_ITEMS: actionTableData.length ? actionTableData : undefined,
      DOC_STATUS: 'Minutes',
      SHOW_SIGNATURE: true,
      SIGNER1_NAME: meeting.organizer?.name || 'Organiser',
      SIGNER1_TITLE: 'Meeting Organiser',
      SIGNER2_NAME: '—',
      SIGNER2_TITLE: 'Verified Attendee',
    },
    branding,
  });
};

// ====================================================================================
// TICKET REPORT PDF
// ====================================================================================

/**
 * Generate a Support Ticket Report with SLA and status breakdown.
 * @param {{ tickets, filters, branding }} options
 */
export const generateTicketReport = async (options) => {
  const { tickets = [], filters = {}, branding = {} } = options;

  const byStatus = tickets.reduce((acc, t) => { acc[t.status] = (acc[t.status] || 0) + 1; return acc; }, {});
  const byPriority = tickets.reduce((acc, t) => { acc[t.priority] = (acc[t.priority] || 0) + 1; return acc; }, {});
  const slaBreached = tickets.filter(t => t.sla?.breached).length;

  const stats = [
    { label: 'Total Tickets', value: tickets.length },
    { label: 'Open / In Progress', value: (byStatus.open || 0) + (byStatus.in_progress || 0), class: 'primary' },
    { label: 'Resolved / Closed', value: (byStatus.resolved || 0) + (byStatus.closed || 0), class: 'success' },
    { label: 'SLA Breached', value: slaBreached, class: slaBreached > 0 ? 'danger' : 'success' },
  ];

  const summary = [
    { label: 'Period', value: filters.from ? `${new Date(filters.from).toLocaleDateString('en-GB')} – ${new Date(filters.to || Date.now()).toLocaleDateString('en-GB')}` : 'All time' },
    { label: 'Open', value: byStatus.open || 0, class: 'primary' },
    { label: 'In Progress', value: byStatus.in_progress || 0, class: 'warning' },
    { label: 'Resolved', value: byStatus.resolved || 0, class: 'success' },
    { label: 'Critical Priority', value: byPriority.critical || 0, class: byPriority.critical > 0 ? 'danger' : 'success' },
    { label: 'SLA Breached', value: slaBreached, class: slaBreached > 0 ? 'danger' : 'success' },
  ];

  const tableData = tickets.slice(0, 200).map(t => ({
    number: t.ticketNumber || '—',
    title: t.title?.length > 45 ? t.title.slice(0, 42) + '...' : t.title,
    type: t.type,
    priority: t.priority,
    status: t.status,
    assignee: t.assignee?.fullName || 'Unassigned',
    sla: t.sla?.breached ? 'Breached' : 'OK',
    created: new Date(t.createdAt).toLocaleDateString('en-GB'),
  }));

  const tableColumns = [
    { header: '#', key: 'number' },
    { header: 'Title', key: 'title' },
    { header: 'Type', key: 'type' },
    { header: 'Priority', key: 'priority' },
    { header: 'Status', key: 'status' },
    { header: 'Assignee', key: 'assignee' },
    { header: 'SLA', key: 'sla' },
    { header: 'Created', key: 'created' },
  ];

  return generatePDFFromTemplate({
    templateName: 'pdf-base',
    data: {
      DOCUMENT_TITLE: 'Support Ticket Report',
      DOCUMENT_SUBTITLE: 'Helpdesk & Issue Tracking Summary',
      SUMMARY: summary,
      SUMMARY_TITLE: 'Ticket Summary',
      STATS: stats,
      TABLE_TITLE: 'Ticket List',
      TABLE_COLUMNS: tableColumns,
      TABLE_DATA: tableData,
      DOC_STATUS: 'Report',
    },
    branding,
  });
};

// ====================================================================================
// ANALYTICS DASHBOARD REPORT PDF
// ====================================================================================

/**
 * Generate a generic Analytics / Dashboard Report.
 * @param {{ title, subtitle, metrics, tableData, tableColumns, summary, infoBox, branding }} options
 */
export const generateAnalyticsReport = async (options) => {
  const {
    title = 'Analytics Report',
    subtitle = 'Workspace Analytics & Metrics',
    metrics = {},
    tableData = [],
    tableColumns = [],
    summary = [],
    infoBox = null,
    branding = {},
  } = options;

  const stats = [
    { label: 'Projects', value: metrics.projects ?? 0 },
    { label: 'Tasks', value: metrics.tasks ?? 0, class: 'primary' },
    { label: 'Members', value: metrics.users ?? 0 },
    { label: 'Meetings', value: metrics.meetings ?? 0, class: 'success' },
  ];

  return generatePDFFromTemplate({
    templateName: 'pdf-base',
    data: {
      DOCUMENT_TITLE: title,
      DOCUMENT_SUBTITLE: subtitle,
      SUMMARY: summary.length ? summary : undefined,
      SUMMARY_TITLE: 'Key Metrics',
      STATS: stats,
      TABLE_TITLE: 'Data Breakdown',
      TABLE_COLUMNS: tableColumns.length ? tableColumns : undefined,
      TABLE_DATA: tableData.length ? tableData : undefined,
      INFO_BOX: infoBox,
      DOC_STATUS: 'Analytics',
    },
    branding,
  });
};

// ====================================================================================
// WORKSPACE SUMMARY PDF
// ====================================================================================

/**
 * Generate a Workspace Summary Report — projects, members, channels at a glance.
 * @param {{ workspace, projects, members, channels, metrics, branding }} options
 */
export const generateWorkspaceSummary = async (options) => {
  const { workspace, projects = [], members = [], channels = [], metrics = {}, branding = {} } = options;

  const activeProjects = projects.filter(p => p.status === 'active').length;
  const byPlan = workspace.settings?.visibility || 'private';

  const stats = [
    { label: 'Projects', value: projects.length },
    { label: 'Active Projects', value: activeProjects, class: 'success' },
    { label: 'Members', value: members.length, class: 'primary' },
    { label: 'Channels', value: channels.length },
  ];

  const summary = [
    { label: 'Workspace', value: workspace.name },
    { label: 'Visibility', value: byPlan },
    { label: 'Active Projects', value: activeProjects, class: 'success' },
    { label: 'Total Members', value: members.length },
    { label: 'Tasks Completed', value: metrics.tasksCompleted || 0, class: 'success' },
    { label: 'Report Date', value: new Date().toLocaleDateString('en-GB') },
  ];

  const tableData = projects.slice(0, 50).map(p => ({
    name: p.name,
    template: p.template || 'Kanban',
    status: p.status,
    priority: p.priority,
    tasks: p.taskCount ?? '—',
    created: new Date(p.createdAt).toLocaleDateString('en-GB'),
  }));

  const tableColumns = [
    { header: 'Project Name', key: 'name' },
    { header: 'Template', key: 'template' },
    { header: 'Status', key: 'status' },
    { header: 'Priority', key: 'priority' },
    { header: 'Tasks', key: 'tasks' },
    { header: 'Created', key: 'created' },
  ];

  return generatePDFFromTemplate({
    templateName: 'pdf-base',
    data: {
      DOCUMENT_TITLE: `Workspace Report — ${workspace.name}`,
      DOCUMENT_SUBTITLE: 'Projects · Members · Channels Overview',
      SUMMARY: summary,
      SUMMARY_TITLE: 'Workspace Overview',
      STATS: stats,
      TABLE_TITLE: 'Project List',
      TABLE_COLUMNS: tableColumns,
      TABLE_DATA: tableData,
      DOC_STATUS: 'Summary',
    },
    branding,
  });
};

// ====================================================================================
// GENERIC TABLE PDF
// ====================================================================================

/**
 * Generate a generic table-based PDF report
 */
export const generateTablePDF = async (options) => {
  const { title, subtitle, data, columns, summary = null, infoBox = null, branding = {}, showSignature = false } = options;

  return generatePDFFromTemplate({
    templateName: 'pdf-base',
    data: {
      DOCUMENT_TITLE: title,
      DOCUMENT_SUBTITLE: subtitle,
      SUMMARY: summary,
      TABLE_TITLE: title,
      TABLE_COLUMNS: columns,
      TABLE_DATA: data,
      INFO_BOX: infoBox,
      SHOW_SIGNATURE: showSignature
    },
    branding
  });
};

export default {
  generatePDFFromTemplate,
  generateTablePDF,
  generateProjectReport,
  generateAuditReport,
  generateBillingInvoice,
  generateTeamReport,
  generateMeetingMinutes,
  generateTicketReport,
  generateAnalyticsReport,
  generateWorkspaceSummary,
};
