import * as vscode from 'vscode';
import { Buffer } from 'buffer';

export class PascalNotebookSerializer implements vscode.NotebookSerializer {

  async deserializeNotebook(content: Uint8Array): Promise<vscode.NotebookData> {
    const txt = Buffer.from(content).toString('utf8').trim() || '{"cells": []}';
    const obj = JSON.parse(txt);
    return new vscode.NotebookData(
      obj.cells.map((c: any) =>
        new vscode.NotebookCellData(
          c.kind === "markdown" ? vscode.NotebookCellKind.Markup : vscode.NotebookCellKind.Code,
          c.value,
          c.language || "ObjectPascal"
        )
      )
    );
  }

  async serializeNotebook(data: vscode.NotebookData): Promise<Uint8Array> {
    const obj = {
      cells: data.cells.map(c => ({
        kind: c.kind === vscode.NotebookCellKind.Code ? "code" : "markdown",
        value: c.value,
        language: c.languageId
      }))
    };
    return Buffer.from(JSON.stringify(obj, null, 2), 'utf8');
  }
}
