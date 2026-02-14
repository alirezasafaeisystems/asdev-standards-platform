const setText = (id, value) => {
  const el = document.getElementById(id);
  if (el) el.textContent = value;
};

const statusClass = (value) => {
  const v = String(value || "").toUpperCase();
  if (["PASS", "OK", "READY", "100"].some((k) => v.includes(k))) return "ok";
  if (["WARN", "BLOCKED", "DEGRADED", "N/A"].some((k) => v.includes(k))) return "warn";
  if (["FAIL", "FAILED", "ERROR"].some((k) => v.includes(k))) return "bad";
  return "warn";
};

const toRow = (label, value) => {
  const klass = statusClass(value);
  return `<div class="status-row"><span>${label}</span><span class="status-pill ${klass}">${value}</span></div>`;
};

const fetchJson = async (url) => {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error(`Failed ${url}`);
  return res.json();
};

const renderReadinessTable = (rows) => {
  const html = [
    "<table><thead><tr><th>Repo</th><th>Pipeline Exit</th><th>Readiness</th><th>Score</th></tr></thead><tbody>",
    ...rows.map(
      (r) =>
        `<tr><td>${r.repo}</td><td>${r.exit}</td><td class="${statusClass(r.readiness)}">${r.readiness}</td><td>${r.score}</td></tr>`
    ),
    "</tbody></table>",
  ].join("");
  document.getElementById("readiness-table").innerHTML = html;
};

const renderPriorityBars = (items) => {
  const sorted = [...items].sort((a, b) => b.todo - a.todo);
  const max = Math.max(...sorted.map((i) => i.todo), 1);
  document.getElementById("priority-bars").innerHTML = sorted
    .map(
      (i) =>
        `<div class="bar-row"><span>${i.priority}</span><div class="bar-track"><div class="bar-fill" style="width:${(i.todo / max) * 100}%"></div></div><span>${i.todo}</span></div>`
    )
    .join("");
};

const renderSources = (sources) => {
  document.getElementById("data-sources").innerHTML = sources.map((s) => `<li>${s}</li>`).join("");
};

async function refreshDashboard() {
  try {
    setText("last-refresh", "Refreshing...");
    const data = await fetchJson("./data.json");

    setText("kpi-readiness", data.kpis.readiness_avg ?? "n/a");
    setText("kpi-todo", String(data.kpis.roadmap_todo ?? "n/a"));
    setText("kpi-done", String(data.kpis.roadmap_done ?? "n/a"));
    setText("kpi-failed", String(data.kpis.autopilot_failed ?? "n/a"));

    document.getElementById("autopilot-summary").innerHTML = [
      toRow("Last Section", data.autopilot?.stamp ?? "n/a"),
      toRow("Phase", data.autopilot?.phase ?? "n/a"),
      toRow("Success", String(data.autopilot?.success ?? "0")),
      toRow("Failed", String(data.autopilot?.failed ?? "0")),
    ].join("");

    document.getElementById("p0-summary").innerHTML = (data.p0 || []).map((r) => toRow(r.check, r.status)).join("");
    document.getElementById("priority-steps").innerHTML = (data.priority_steps || []).map((r) => toRow(r.step, r.status)).join("");

    renderPriorityBars(data.queue?.by_priority || []);
    renderReadinessTable(data.readiness || []);
    renderSources(data.sources || []);

    setText("last-refresh", `Data ${data.generated_at || "n/a"}`);
  } catch (err) {
    setText("last-refresh", `Error: ${err.message}`);
  }
}

document.getElementById("refresh-btn").addEventListener("click", refreshDashboard);
refreshDashboard();
