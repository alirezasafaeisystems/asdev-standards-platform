async function loadReport() {
  const meta = document.getElementById('meta');
  const scoreValue = document.getElementById('scoreValue');
  const checksBody = document.getElementById('checksBody');

  try {
    const res = await fetch('report.json', { cache: 'no-store' });
    if (!res.ok) throw new Error('report fetch failed');
    const report = await res.json();

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
  } catch (err) {
    meta.textContent = 'Failed to load report.json';
    console.error(err);
  }
}

loadReport();
