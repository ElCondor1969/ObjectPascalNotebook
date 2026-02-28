import * as vscode from 'vscode';
import { PascalNotebookSerializer } from './pascalNotebookSerializer';
import * as process from 'process';
import * as cp from 'child_process';
import * as path from 'path';
import { randomBytes } from 'crypto';

export function activate(context: vscode.ExtensionContext) {

  const controller = vscode.notebooks.createNotebookController(
    'object-pascal-notebook',
    'objectPascalNotebook',
    'Object Pascal'
  );

  controller.supportedLanguages = ['objectpascal', 'pascal'];

  const serializer = vscode.workspace.registerNotebookSerializer(
    'objectPascalNotebook',
    new PascalNotebookSerializer()
  );

  // Register the new notebook command.
  const newNotebookCommand = vscode.commands.registerCommand('object-pascal-notebook.newNotebook', async () => {
    const data = new vscode.NotebookData([
      new vscode.NotebookCellData(vscode.NotebookCellKind.Code, '', 'objectpascal')
    ]);
    const doc = await vscode.workspace.openNotebookDocument('objectPascalNotebook', data);
    await vscode.window.showNotebookDocument(doc);
  });

  let oldServerPort = vscode.workspace.getConfiguration('objectPascalNotebook').get<number>('hostHTTPPort') ?? 9000;

  function getOPNBHostURL(notebook?:vscode.NotebookDocument) {
    if (!notebook || !notebook.metadata.urlOPNBHost) {
      return `http://localhost:${oldServerPort}`;
    }
    else {
      return notebook.metadata.urlOPNBHost;
    }
  }

  async function applyMetadata(notebook:vscode.NotebookDocument, metadata: any) {
    const edit = new vscode.WorkspaceEdit();
    edit.set(notebook.uri, [
      vscode.NotebookEdit.updateNotebookMetadata(metadata)
    ]);
    await vscode.workspace.applyEdit(edit);
  }

  const onChangeConfigurationSub = vscode.workspace.onDidChangeConfiguration(e => {
    if (e.affectsConfiguration('objectPascalNotebook.hostHTTPPort')) {
      let serverPort = vscode.workspace.getConfiguration('objectPascalNotebook').get<number>('hostHTTPPort') ?? 9000;
      if (oldServerPort != serverPort) {
        // Kill the local host for force the new port to next executions.
        fetch(`http://localhost:${oldServerPort}/out`, {
          method: 'POST'
        });

        oldServerPort = serverPort;
      }
    }
  });

  const onOpenNotebookDocumentSub = vscode.workspace.onDidOpenNotebookDocument(async (notebook) => {

    function generateRandomString(length: number): string {
      return randomBytes(Math.ceil(length / 2)).toString('hex').slice(0, length);
    }

    if (notebook.notebookType === 'objectPascalNotebook') {
      const updatedMetadata = {
        ...notebook.metadata,
        notebookId: generateRandomString(20),
        urlOPNBHost: ''
      };
      applyMetadata(notebook,updatedMetadata);
    }
  });

  const onCloseNotebookDocumentSub = vscode.workspace.onDidCloseNotebookDocument((notebook) => {
    if (notebook.notebookType === 'objectPascalNotebook') {
      fetch(`${getOPNBHostURL()}/cancel`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          notebookId: notebook.metadata.notebookId, 
          executionId: '' 
        })
      });
    }
  });

  // Active executions tracking (for cancels)
  const runningExecutions = new Map<string, { cancel: () => void }>();

  controller.executeHandler = async (cells, notebook, _controller) => {
    const notebookId = notebook.metadata.notebookId,
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
          
          const pingResp = await fetch(`${getOPNBHostURL(notebook)}/ping`, {
            method: 'GET',
            signal: controller.signal
          });
          
          clearTimeout(timeoutId);

          if (await pingResp.text() !== 'Pong') {
            throw new Error('Unknown HTTP Server.');
          }
        } 
        catch (err) {
          if ((err instanceof Error) && (['TypeError', 'AbortError'].indexOf(err.name) !== -1) &&
              (notebook.metadata.urlOPNBHost=='')) {
            // Start bundled HTTP server executable if not responding or not in execution
            try {
              const platformEXE: { [key: string]: string } = {
                'win32': 'OPNBHost.exe',
                'darwin': 'OPNBHost.app',
                'linux': 'OPNBHost'
              };
              const platform = process.platform;
              const arch = process.arch;
              const exeName = platformEXE[platform];
              let delphiFolder=''; 
              if (platform === 'win32') {
                delphiFolder = 'Win64';
              } 
              else if (platform === 'linux') {
                delphiFolder = 'Linux64';
              } 
              else if (platform === 'darwin') {
                delphiFolder = arch === 'arm64' ? 'OSXARM64' : 'OSX64';
              }
              const exe = path.join(context.extensionPath, 'dist', delphiFolder, exeName);
              const args = [`-port ${oldServerPort}`];

              const child = cp.spawn(exe, args, {
                detached: true,
                cwd: path.join(context.extensionPath, 'dist'),
                stdio: ['ignore', 'pipe', 'pipe']
              });

              console.log('Spawned OPNBHost.exe pid=', child.pid);
              child.stdout?.on('data', (d) => {
                console.log('[OPNBHost stdout] ' + d.toString());
              });
              child.stderr?.on('data', (d) => {
                console.error('[OPNBHost stderr] ' + d.toString());
              });
              child.on('error', (err) => {
                console.error('OPNBHost spawn error:', err);
              });
              child.on('exit', (code, sig) => {
                console.log(`OPNBHost exited. code=${code} sig=${sig}`);
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
        const startResp = await fetch(`${getOPNBHostURL(notebook)}/execute`, {
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
          const pollResp = await fetch(`${getOPNBHostURL(notebook)}/output`, {
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
            if (pollJson.outputData && pollJson.outputData.UrlRemoteOPNBHost) {
              const updatedMetadata = {
                ...notebook.metadata,
                urlOPNBHost: pollJson.outputData.UrlRemoteOPNBHost
              };
              applyMetadata(notebook, updatedMetadata);
            }
            break;
          }
        }

        if (cancelled) {
          await fetch(`${getOPNBHostURL(notebook)}/cancel`, {
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

  // Comand for abort executions.
  const cancelCmd = vscode.commands.registerCommand('objectPascalNotebook.cancelExecution', () => {
    for (const [_, r] of runningExecutions) {
      r.cancel();
    }
    vscode.window.showInformationMessage('Abort requested.');
  });

  context.subscriptions.push(
    controller,
    cancelCmd,
    serializer,
    onChangeConfigurationSub,
    onOpenNotebookDocumentSub,
    onCloseNotebookDocumentSub,
    newNotebookCommand
  );
}

export function deactivate() {
  let serverPort = vscode.workspace.getConfiguration('objectPascalNotebook').get<number>('hostHTTPPort') ?? 9000;

  // Kill the host.
  fetch(`http://localhost:${serverPort}/out`, {
    method: 'POST'
  });
}
