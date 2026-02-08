import * as vscode from 'vscode';
import { Buffer } from 'buffer';

export class PascalNotebookSerializer implements vscode.NotebookSerializer {

  async deserializeNotebook(content: Uint8Array): Promise<vscode.NotebookData> {
    const txt = Buffer.from(content).toString('utf8').trim() || '{"cells": []}';

    let obj: any;
    try {
      obj = JSON.parse(txt);
    } catch (error) {
      obj = { cells: [] };
    }

    const cells = obj.cells.map((c: any) => {
      const cell = new vscode.NotebookCellData(
        c.kind === "markdown" ? vscode.NotebookCellKind.Markup : vscode.NotebookCellKind.Code,
        c.value,
        c.language || "ObjectPascal"
      );

      if (c.outputs && Array.isArray(c.outputs)) {
        cell.outputs = c.outputs.map((out: any) => {
          return new vscode.NotebookCellOutput([
            vscode.NotebookCellOutputItem.text(out.value, 'text/html')
          ]);
        });
      }
      return cell;
    });

    return new vscode.NotebookData(cells);
  }

  async serializeNotebook(data: vscode.NotebookData): Promise<Uint8Array> {
    const obj = {
      cells: data.cells.map(c => {
        const cellJson: any = {
          kind: c.kind === vscode.NotebookCellKind.Code ? "code" : "markdown",
          value: c.value,
          language: c.languageId
        };

        if (c.outputs && c.outputs.length > 0) {
          cellJson.outputs = c.outputs.map(out => {
            const htmlItem = out.items.find(item => item.mime === 'text/html');
            return {
              value: htmlItem ? Buffer.from(htmlItem.data).toString('utf8') : ""
            };
          });
        }

        return cellJson;
      })
    };

    return Buffer.from(JSON.stringify(obj, null, 2), 'utf8');
  }
}
