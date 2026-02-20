async function loadJson(path) {
  const res = await fetch(path, { cache: 'no-store' });
  if (!res.ok) throw new Error(`failed to fetch ${path}`);
  return res.json();
}

function drawTrend(svg, points) {
  const w = 600;
  const h = 180;
  const pad = 20;
  svg.innerHTML = '';

  const bg = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
  bg.setAttribute('x', '0');
  bg.setAttribute('y', '0');
  bg.setAttribute('width', String(w));
  bg.setAttribute('height', String(h));
  bg.setAttribute('fill', '#ffffff');
  svg.appendChild(bg);

  if (!points.length) return;

  const maxY = 100;
  const minY = 0;
  const stepX = points.length > 1 ? (w - pad * 2) / (points.length - 1) : 0;
  const coords = points.map((p, i) => {
    const x = pad + i * stepX;
    const y = h - pad - ((p.compliance_score - minY) / (maxY - minY)) * (h - pad * 2);
    return { x, y };
  });

  const poly = document.createElementNS('http://www.w3.org/2000/svg', 'polyline');
  poly.setAttribute('fill', 'none');
  poly.setAttribute('stroke', '#0f766e');
  poly.setAttribute('stroke-width', '3');
  poly.setAttribute('points', coords.map(c => `${c.x},${c.y}`).join(' '));
  svg.appendChild(poly);

  coords.forEach((c) => {
    const dot = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
    dot.setAttribute('cx', String(c.x));
    dot.setAttribute('cy', String(c.y));
    dot.setAttribute('r', '3');
    dot.setAttribute('fill', '#0f766e');
    svg.appendChild(dot);
  });
}

async function loadReport() {
  const meta = document.getElementById('meta');
  const scoreValue = document.getElementById('scoreValue');
  const checksBody = document.getElementById('checksBody');
  const trendMeta = document.getElementById('trendMeta');
  const trendChart = document.getElementById('trendChart');

  try {
    const report = await loadJson('report.json');
    let history;
    try {
      history = await loadJson('history.json');
    } catch {
      history = { points: [] };
    }

    meta.textContent = `Repo: ${report.repo} | Generated (UTC): ${report.generated_at_utc}`;
    scoreValue.textContent = `${report.compliance_score}%`;

    checksBody.innerHTML = '';
    for (const check of report.checks) {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${check.name}</td>
        <td class="status-${check.status}">${check.status}</td>
        <td><code>${check.source}</code></td>
      `;
      checksBody.appendChild(tr);
    }

    const points = Array.isArray(history.points) ? history.points : [];
    drawTrend(trendChart, points);
    trendMeta.textContent = `Data points: ${points.length}`;
  } catch (err) {
    meta.textContent = 'Failed to load dashboard data';
    console.error(err);
  }
}

loadReport();
