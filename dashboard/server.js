const http = require('http');
const { execSync } = require('child_process');

const PORT = 7680;

function getSessions() {
    try {
        const output = execSync(
            `docker ps --format '{{.Names}}\\t{{.Ports}}\\t{{.Mounts}}' --filter 'name=safeclaw'`,
            { encoding: 'utf8' }
        );

        return output.trim().split('\n').filter(Boolean).map(line => {
            const [name, ports, mounts] = line.split('\t');
            const portMatch = ports.match(/:(\d+)->7681/);
            const port = portMatch ? portMatch[1] : null;

            let volume = '';
            try {
                const inspect = execSync(
                    `docker inspect ${name} --format '{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}}:{{.Destination}}{{end}}{{end}}'`,
                    { encoding: 'utf8' }
                ).trim();
                volume = inspect || '-';
            } catch (e) {
                volume = '-';
            }

            return { name, port, url: port ? `http://localhost:${port}` : null, volume };
        }).filter(s => s.port);
    } catch (e) {
        return [];
    }
}

function renderHTML(sessions) {
    const sessionRows = sessions.map(s => `
        <tr>
            <td>${s.name.replace('safeclaw-', '').replace('safeclaw', 'default')}</td>
            <td><a href="${s.url}" target="_blank">${s.url}</a></td>
            <td class="volume">${s.volume || '-'}</td>
        </tr>
    `).join('');

    const iframes = sessions.map(s => `
        <div class="frame">
            <div class="frame-bar">
                <span>${s.name.replace('safeclaw-', '').replace('safeclaw', 'default')}</span>
                <a href="${s.url}" target="_blank">open</a>
            </div>
            <iframe src="${s.url}"></iframe>
        </div>
    `).join('');

    return `<!DOCTYPE html>
<html>
<head>
    <title>SafeClaw</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
            background: #0d1117;
            color: #c9d1d9;
            padding: 24px;
        }
        h1 {
            font-size: 14px;
            font-weight: normal;
            color: #8b949e;
            margin-bottom: 16px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 24px;
        }
        th, td {
            padding: 8px 12px;
            text-align: left;
            border-bottom: 1px solid #30363d;
        }
        th {
            color: #8b949e;
            font-weight: normal;
            font-size: 12px;
        }
        td a {
            color: #58a6ff;
            text-decoration: none;
        }
        td a:hover { text-decoration: underline; }
        .volume {
            color: #8b949e;
            font-size: 12px;
        }
        .frames {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            gap: 16px;
        }
        .frame {
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 6px;
            overflow: hidden;
        }
        .frame-bar {
            padding: 8px 12px;
            border-bottom: 1px solid #30363d;
            display: flex;
            justify-content: space-between;
            font-size: 12px;
        }
        .frame-bar a {
            color: #58a6ff;
            text-decoration: none;
        }
        iframe {
            width: 100%;
            height: 400px;
            border: none;
            background: #000;
        }
        .empty {
            color: #8b949e;
            padding: 40px;
            text-align: center;
        }
    </style>
</head>
<body>
    <h1>safeclaw sessions</h1>
    ${sessions.length === 0 ? '<p class="empty">no sessions running<br><br>./scripts/run.sh -s name</p>' : `
    <table>
        <thead><tr><th>Session</th><th>URL</th><th>Volume</th></tr></thead>
        <tbody>${sessionRows}</tbody>
    </table>
    <div class="frames">${iframes}</div>
    `}
</body>
</html>`;
}

const server = http.createServer((req, res) => {
    if (req.url === '/api/sessions') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(getSessions()));
    } else {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(renderHTML(getSessions()));
    }
});

server.listen(PORT, '127.0.0.1', () => {
    console.log(`http://localhost:${PORT}`);
});
