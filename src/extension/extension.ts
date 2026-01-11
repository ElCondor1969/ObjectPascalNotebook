import * as vscode from 'vscode';
import { PascalNotebookSerializer } from './pascalNotebookSerializer';
import * as cp from 'child_process';
import * as path from 'path';

export function activate(context: vscode.ExtensionContext) {
  console.log('Object Pascal Notebook extension activated.');

  const controller = vscode.notebooks.createNotebookController(
    'object-pascal-notebook',
    'objectPascalNotebook',
    'Object Pascal'
  );

  controller.supportedLanguages = ['ObjectPascal', 'Pascal'];

  const serializer = vscode.workspace.registerNotebookSerializer(
    'objectPascalNotebook',
    new PascalNotebookSerializer()
  );

  // Configurazione porta server
  const config = vscode.workspace.getConfiguration('objectPascalNotebook');
  let serverPort = config.get<number>('serverPort') ?? 9000;

  vscode.workspace.onDidChangeConfiguration(e => {
    if (e.affectsConfiguration('objectPascalNotebook.serverPort')) {
      serverPort = vscode.workspace.getConfiguration('objectPascalNotebook').get<number>('serverPort') ?? 9000;
    }
  });

  // Tracking esecuzioni attive (per cancellazione)
  const runningExecutions = new Map<string, { cancel: () => void }>();

  controller.executeHandler = async (cells, notebook, _controller) => {
    const notebookId = notebook.uri.toString(),
          notebookPath = notebook.uri.fsPath.replace(/[/\\][^/\\]+$/, "");

    for (const cell of cells) {
      const exec = controller.createNotebookCellExecution(cell);
      exec.start(Date.now());

      const code = cell.document.getText();
      if (!code.trim()) {
        exec.replaceOutput([ new vscode.NotebookCellOutput([ vscode.NotebookCellOutputItem.text('(empty cell)') ]) ]);
        exec.end(true);
        continue;
      }

      let cancelled = false;
      const cellId = `${notebookId}::${cell.index}`;

      runningExecutions.set(cellId, {
        cancel: () => { cancelled = true; }
      });

      try {
        // Ensure server is running with 2s timeout
        try {
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), 2000);
          
          const pingResp = await fetch(`http://localhost:${serverPort}/ping`, {
            method: 'GET',
            signal: controller.signal
          });
          
          clearTimeout(timeoutId);

          if (await pingResp.text() !== 'Pong') {
            throw new Error('Unknown HTTP Server.');
          }
        } 
        catch (err) {
          if ((err instanceof Error) && (['TypeError', 'AbortError'].indexOf(err.name) !== -1)) {
            // Start bundled HTTP server executable if not responding or not in execution
            try {
              const exe = path.join(context.extensionPath, 'dist', 'HTTPServer.exe');
              const args = [`--port=${serverPort}`];

              const child = cp.spawn(exe, args, {
                detached: true,
                cwd: path.join(context.extensionPath, 'dist'),
                stdio: ['ignore', 'pipe', 'pipe']
              });

              console.log('Spawned HTTPServer.exe pid=', child.pid);
              child.stdout?.on('data', (d) => {
                console.log('[HTTPServer stdout] ' + d.toString());
              });
              child.stderr?.on('data', (d) => {
                console.error('[HTTPServer stderr] ' + d.toString());
              });
              child.on('error', (err) => {
                console.error('HTTPServer spawn error:', err);
              });
              child.on('exit', (code, sig) => {
                console.log(`HTTPServer exited. code=${code} sig=${sig}`);
              });
              child.unref();

              // Wait for a short period to let the server start
              await new Promise(r => setTimeout(r, 2000));
            } 
            catch (spawnErr) {
              throw spawnErr;
            }
          } 
          else {
            throw err;
          }
        }
        
        // Start execution
        const startResp = await fetch(`http://localhost:${serverPort}/execute`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ notebookId, notebookPath, cell: cell.index, code })
        });

        if (!startResp.ok) {
          const errorMessage = await startResp.text();
          throw new Error(`Server :${errorMessage}`);
        }

        const startJson = await startResp.json();
        const executionId = startJson.executionId;

        if (!executionId) {
          throw new Error('Server: executionId missing.');
        }

        // Progressive output polling
        let lastOffset = 0;
        while (!cancelled) {
          await new Promise(r => setTimeout(r, 500));
          const pollResp = await fetch(`http://localhost:${serverPort}/output`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ notebookId, executionId, offset: lastOffset })
          });

          if (!pollResp.ok) {
            const errorMessage = await pollResp.text();
            throw new Error(`Server :${errorMessage}`);
          }

          const pollJson = await pollResp.json();

          if (pollJson.cancelled) {
            exec.replaceOutput([ new vscode.NotebookCellOutput([ vscode.NotebookCellOutputItem.text('(execution cancelled)') ]) ]);
            exec.end(false);
            break;
          }

          exec.replaceOutput([
            new vscode.NotebookCellOutput([
              vscode.NotebookCellOutputItem.text(pollJson.finished ? (pollJson.completeOutput || 'OK') : pollJson.chunk, 'text/html')
            ])
          ]);

          if (pollJson.finished) {
            exec.end(true);
            break;
          }
        }

        if (cancelled) {
          await fetch(`http://localhost:${serverPort}/cancel`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ notebookId, executionId })
          });
          exec.end(false);
        }

      } 
      catch (err) {
        exec.replaceOutput([ new vscode.NotebookCellOutput([ vscode.NotebookCellOutputItem.text('Error:' + String(err), 'text/html') ]) ]);
        exec.end(false);
      } 
      finally {
        runningExecutions.delete(cellId);
      }
    }
  };

  controller.interruptHandler = async (notebook) => {
    for (const [_, r] of runningExecutions) {
      r.cancel();
    }
    vscode.window.showInformationMessage('Abort requested.');
  };

  // Comando per annullare esecuzioni
  const cancelCmd = vscode.commands.registerCommand('objectPascalNotebook.cancelExecution', () => {
    for (const [_, r] of runningExecutions) {
      r.cancel();
    }
    vscode.window.showInformationMessage('Abort requested.');
  });

  context.subscriptions.push(controller, cancelCmd, serializer);
}

export function deactivate() {}
