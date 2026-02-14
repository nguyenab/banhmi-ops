#!/usr/bin/env node
/**
 * Banh Mi Ops - Debrief Report Renderer
 *
 * Reads operation debrief JSON data and renders it into an HTML report
 * using the Handlebars template.
 *
 * Usage:
 *   node render-report.js <debrief.json> [output.html]
 *   cat debrief.json | node render-report.js --stdin [output.html]
 *
 * Author: Abraham Nguyen (github.com/nguyenab)
 * License: MIT
 */

const fs = require("fs");
const path = require("path");
const Handlebars = require("handlebars");

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------
const SCRIPT_DIR = __dirname;
const TEMPLATE_DIR = path.resolve(SCRIPT_DIR, "..", "templates");
const DEFAULT_TEMPLATE = path.join(TEMPLATE_DIR, "operation-debrief.html");

// ---------------------------------------------------------------------------
// Handlebars Helpers
// ---------------------------------------------------------------------------
Handlebars.registerHelper("formatNumber", function (num) {
  if (typeof num !== "number") return num;
  return num.toLocaleString();
});

Handlebars.registerHelper("formatDate", function (dateStr) {
  if (!dateStr) return "N/A";
  try {
    const d = new Date(dateStr);
    return d.toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return dateStr;
  }
});

Handlebars.registerHelper("statusClass", function (status) {
  if (!status) return "unknown";
  const s = String(status).toLowerCase();
  if (s === "complete" || s === "success" || s === "passed") return "success";
  if (s === "failed" || s === "error") return "error";
  if (s === "in-progress" || s === "running") return "running";
  if (s === "skipped") return "skipped";
  return "unknown";
});

Handlebars.registerHelper("statusIcon", function (status) {
  if (!status) return "?";
  const s = String(status).toLowerCase();
  if (s === "complete" || s === "success" || s === "passed") return "OK";
  if (s === "failed" || s === "error") return "FAIL";
  if (s === "in-progress" || s === "running") return "...";
  if (s === "skipped") return "SKIP";
  return "?";
});

Handlebars.registerHelper("percentage", function (value, total) {
  if (!total || total === 0) return "0%";
  return Math.round((value / total) * 100) + "%";
});

Handlebars.registerHelper("ifEquals", function (a, b, options) {
  return a === b ? options.fn(this) : options.inverse(this);
});

Handlebars.registerHelper("json", function (context) {
  return JSON.stringify(context, null, 2);
});

// ---------------------------------------------------------------------------
// Core Functions
// ---------------------------------------------------------------------------

/**
 * Load and compile the Handlebars template.
 */
function loadTemplate(templatePath) {
  if (!fs.existsSync(templatePath)) {
    console.error(`Template not found: ${templatePath}`);
    console.error(`Expected at: ${DEFAULT_TEMPLATE}`);
    process.exit(1);
  }
  const source = fs.readFileSync(templatePath, "utf-8");
  return Handlebars.compile(source);
}

/**
 * Read and parse the debrief JSON data.
 */
function loadDebrief(inputPath) {
  let raw;
  if (inputPath === "--stdin") {
    raw = fs.readFileSync(0, "utf-8"); // stdin
  } else {
    if (!fs.existsSync(inputPath)) {
      console.error(`Debrief file not found: ${inputPath}`);
      process.exit(1);
    }
    raw = fs.readFileSync(inputPath, "utf-8");
  }

  try {
    return JSON.parse(raw);
  } catch (err) {
    console.error(`Failed to parse JSON: ${err.message}`);
    process.exit(1);
  }
}

/**
 * Enrich debrief data with computed fields.
 */
function enrichData(data) {
  // Ensure required fields have defaults
  data.operation = data.operation || {};
  data.operation.title = data.operation.title || "Untitled Operation";
  data.operation.status = data.operation.status || "unknown";
  data.operation.timestamp = data.operation.timestamp || new Date().toISOString();
  data.tasks = data.tasks || [];
  data.cost = data.cost || {};
  data.timeline = data.timeline || [];
  data.reviewers = data.reviewers || {};
  data.summary = data.summary || "";
  data.assessment = data.assessment || "";

  // Compute task stats
  const taskStats = {
    total: data.tasks.length,
    complete: 0,
    failed: 0,
    skipped: 0,
    inProgress: 0,
  };

  for (const task of data.tasks) {
    const s = String(task.status || "").toLowerCase();
    if (s === "complete" || s === "success" || s === "passed")
      taskStats.complete++;
    else if (s === "failed" || s === "error") taskStats.failed++;
    else if (s === "skipped") taskStats.skipped++;
    else taskStats.inProgress++;
  }

  data.taskStats = taskStats;

  // Compute total tokens
  if (data.cost.models) {
    let totalInput = 0;
    let totalOutput = 0;
    for (const model of data.cost.models) {
      totalInput += model.inputTokens || 0;
      totalOutput += model.outputTokens || 0;
    }
    data.cost.totalInputTokens = totalInput;
    data.cost.totalOutputTokens = totalOutput;
    data.cost.totalTokens = totalInput + totalOutput;
  }

  // Render timestamp
  data.renderedAt = new Date().toISOString();
  data.banhmiVersion = "1.0.0";

  return data;
}

/**
 * Render the report.
 */
function render(data, templatePath, outputPath) {
  const template = loadTemplate(templatePath);
  const enriched = enrichData(data);
  const html = template(enriched);

  if (outputPath) {
    const outDir = path.dirname(outputPath);
    if (!fs.existsSync(outDir)) {
      fs.mkdirSync(outDir, { recursive: true });
    }
    fs.writeFileSync(outputPath, html, "utf-8");
    console.log(`Report written to: ${outputPath}`);
  } else {
    process.stdout.write(html);
  }
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------
function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes("--help") || args.includes("-h")) {
    console.log(`
Banh Mi Ops - Debrief Report Renderer

Usage:
  node render-report.js <debrief.json> [output.html]
  cat debrief.json | node render-report.js --stdin [output.html]

Options:
  --template <path>   Use a custom Handlebars template
  --stdin             Read debrief JSON from stdin
  --help              Show this help

Examples:
  node render-report.js operation-debrief.json report.html
  node render-report.js operation-debrief.json  # outputs to stdout
  cat data.json | node render-report.js --stdin report.html
`);
    process.exit(0);
  }

  let inputPath = null;
  let outputPath = null;
  let templatePath = DEFAULT_TEMPLATE;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--template" && args[i + 1]) {
      templatePath = args[++i];
    } else if (args[i] === "--stdin") {
      inputPath = "--stdin";
    } else if (!inputPath) {
      inputPath = args[i];
    } else if (!outputPath) {
      outputPath = args[i];
    }
  }

  if (!inputPath) {
    console.error("No input file specified. Use --help for usage.");
    process.exit(1);
  }

  const data = loadDebrief(inputPath);
  render(data, templatePath, outputPath);
}

main();
