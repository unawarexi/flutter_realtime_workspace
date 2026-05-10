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
  TAGLINE: 'Computer Based Test Platform',
  LOGO_URL: 'https://res.cloudinary.com/dkt3rfpgz/image/upload/v1767626977/teamspot2_hrn11f.png',
  PRIMARY_COLOR: '#ea580c',
  SECONDARY_COLOR: '#1e293b',
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
        <div style="width: 100%; font-size: 9px; padding: 0 15mm; display: flex; justify-content: space-between; color: #9ca3af;">
          <span>TEAMSPOT CBT Platform</span>
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
// EXAM HISTORY PDF
// ====================================================================================

/**
 * Generate an Exam History PDF with question-by-question analysis
 */
export const generateExamHistoryPDF = async (options) => {
  const { submission, exam, course, student, lecturer, branding = {} } = options;

  // Build question analysis
  const questions = exam.questions.map((q, idx) => {
    const studentAnswer = submission.answers.find((a) => a.questionId === q._id?.toString())?.answer || 'No Answer';
    const isCorrect = studentAnswer === q.correctAnswer;

    return {
      number: idx + 1,
      text: q.question,
      studentAnswer,
      correctAnswer: q.correctAnswer,
      isCorrect,
      marks: isCorrect ? q.marks : 0,
      maxMarks: q.marks
    };
  });

  // Calculate stats
  const correctCount = questions.filter((q) => q.isCorrect).length;
  const wrongCount = questions.length - correctCount;

  // Build summary
  const summary = [
    {
      label: 'Course',
      value: `${course?.courseCode} - ${course?.courseTitle}`
    },
    { label: 'Lecturer', value: lecturer?.fullname || 'N/A' },
    { label: 'Student', value: student?.fullname || 'N/A' },
    { label: 'Matric No', value: student?.matricNumber || 'N/A' },
    {
      label: 'Score',
      value: `${submission.score}/${submission.totalMarks}`,
      class: submission.passed ? 'success' : 'danger'
    },
    {
      label: 'Status',
      value: submission.passed ? 'PASSED' : 'FAILED',
      class: submission.passed ? 'success' : 'danger'
    }
  ];

  // Build stats
  const stats = [
    { label: 'Total Questions', value: exam.questions.length },
    { label: 'Correct', value: correctCount, class: 'success' },
    { label: 'Wrong', value: wrongCount, class: 'danger' },
    {
      label: 'Percentage',
      value: `${submission.percentage}%`,
      class: 'primary'
    }
  ];

  return generatePDFFromTemplate({
    templateName: 'pdf-base',
    data: {
      DOCUMENT_TITLE: `Exam History Report`,
      DOCUMENT_SUBTITLE: `${course?.courseCode} | ${new Date(submission.submittedAt).toLocaleDateString()}`,
      SUMMARY: summary,
      STATS: stats,
      QUESTIONS: questions,
      SHOW_SIGNATURE: false
    },
    branding
  });
};

// ====================================================================================
// SEMESTER RESULTS PDF
// ====================================================================================

/**
 * Generate a Semester Results PDF with all courses and grades
 */
export const generateSemesterResultsPDF = async (options) => {
  const { student, submissions, branding = {} } = options;

  // Build table data
  const tableData = submissions.map((s) => ({
    courseCode: s.examId?.courseId?.courseCode || 'N/A',
    courseTitle: s.examId?.courseId?.courseTitle || 'N/A',
    score: s.score,
    total: s.totalMarks,
    percentage: `${s.percentage}%`,
    grade: s.grade,
    status: s.passed ? 'pass' : 'fail',
    date: new Date(s.submittedAt).toLocaleDateString()
  }));

  const tableColumns = [
    { header: 'Course Code', key: 'courseCode' },
    { header: 'Course Title', key: 'courseTitle' },
    { header: 'Score', key: 'score' },
    { header: 'Total', key: 'total' },
    { header: 'Percentage', key: 'percentage' },
    { header: 'Grade', key: 'grade' },
    { header: 'Status', key: 'status' },
    { header: 'Date', key: 'date' }
  ];

  // Calculate summary stats
  const totalExams = submissions.length;
  const passedExams = submissions.filter((s) => s.passed).length;
  const failedExams = totalExams - passedExams;
  const averagePercentage = totalExams > 0 ? (submissions.reduce((sum, s) => sum + s.percentage, 0) / totalExams).toFixed(1) : 0;

  const summary = [
    { label: 'Student Name', value: student?.fullname || 'N/A' },
    { label: 'Matric No', value: student?.matricNumber || 'N/A' },
    { label: 'Total Exams', value: totalExams },
    { label: 'Passed', value: passedExams, class: 'success' },
    {
      label: 'Failed',
      value: failedExams,
      class: failedExams > 0 ? 'danger' : 'success'
    },
    { label: 'Average', value: `${averagePercentage}%`, class: 'primary' }
  ];

  // Overall status info box
  const overallStatus =
    passedExams === totalExams
      ? {
          type: 'success',
          title: 'Excellent Performance!',
          content: 'You have passed all your exams this semester.'
        }
      : passedExams > totalExams / 2
        ? {
            type: 'warning',
            title: 'Good Progress',
            content: `You passed ${passedExams} out of ${totalExams} exams. Keep working on the areas that need improvement.`
          }
        : {
            type: 'danger',
            title: 'Needs Improvement',
            content: `You passed ${passedExams} out of ${totalExams} exams. Please consult your academic advisor.`
          };

  return generatePDFFromTemplate({
    templateName: 'pdf-base',
    data: {
      DOCUMENT_TITLE: 'Semester Results Summary',
      DOCUMENT_SUBTITLE: `${student?.fullname} | ${student?.matricNumber}`,
      SUMMARY: summary,
      TABLE_TITLE: 'Examination Results',
      TABLE_COLUMNS: tableColumns,
      TABLE_DATA: tableData,
      INFO_BOX: overallStatus,
      SHOW_SIGNATURE: true,
      EXAMINER_NAME: 'Course Examiner',
      HOD_NAME: 'Head of Department'
    },
    branding
  });
};

// ====================================================================================
// TRANSCRIPT PDF
// ====================================================================================

/**
 * Generate an Official Transcript PDF
 */
export const generateTranscriptPDF = async (options) => {
  const { student, submissions, department, faculty, branding = {} } = options;

  const tableData = submissions.map((s) => ({
    semester: '2024/2025',
    courseCode: s.examId?.courseId?.courseCode || 'N/A',
    courseTitle: s.examId?.courseId?.courseTitle || 'N/A',
    grade: s.grade,
    status: s.passed ? 'pass' : 'fail'
  }));

  const tableColumns = [
    { header: 'Semester', key: 'semester' },
    { header: 'Course Code', key: 'courseCode' },
    { header: 'Course Title', key: 'courseTitle' },
    { header: 'Grade', key: 'grade' },
    { header: 'Status', key: 'status' }
  ];

  const summary = [
    { label: 'Student Name', value: student?.fullname || 'N/A' },
    { label: 'Matric No', value: student?.matricNumber || 'N/A' },
    { label: 'Department', value: department?.departmentName || 'N/A' },
    { label: 'Faculty', value: faculty || 'N/A' },
    { label: 'Level', value: student?.level || 'N/A' },
    { label: 'Total Courses', value: submissions.length }
  ];

  return generatePDFFromTemplate({
    templateName: 'pdf-base',
    data: {
      DOCUMENT_TITLE: 'Official Academic Transcript',
      DOCUMENT_SUBTITLE: `${student?.fullname} | ${student?.matricNumber}`,
      WATERMARK: 'OFFICIAL',
      SUMMARY: summary,
      TABLE_TITLE: 'Academic Record',
      TABLE_COLUMNS: tableColumns,
      TABLE_DATA: tableData,
      SHOW_SIGNATURE: true,
      EXAMINER_NAME: 'Examinations Officer',
      HOD_NAME: 'Dean of Faculty'
    },
    branding
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
  generateExamHistoryPDF,
  generateSemesterResultsPDF,
  generateTranscriptPDF,
  generateTablePDF
};
