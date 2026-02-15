# Object Pascal Notebook
## VSCode Notebook by Object Pascal.

Questa estensione permette di avere a disposizione notebook in Object Pascal.

Il motore di esecuzione degli script usa l'ottima libreria [**DWScript**](https://github.com/EricGrange/DWScript); la libreria, oltre ad implementare la maggior parte della sintassi di Delphi, introduce molte migliorie al linguaggio, come l'implementazione di un *garbage collector* per la gestione del ciclo di vita degli oggetti.
Per conoscere nel dettaglio tutte le funzionalità che la libreria mette a disposizione, oltre a fare riferimento alla relativa documentazione in linea, è consigliabile studiare i casi di test presenti a questo [indirizzo](https://github.com/EricGrange/DWScript/tree/master/Test).

**Avviso**: Se vuoi collaborare per rendere disponibile questa estensione anche per altri sistemi operativi oltre a Windows, per favore leggi [qui](#aiuto-cercasi).

## Esempio di notebook

Per attivare l'estesione, basterà creare o aprire un file con estensione **opnb**.
VSCode mostrerà l'usuale interfaccia grafica di un notebook.
Dopo di che, sarà sufficiente popolare il notebook con le nostre celle di codice e di descrizioni markdown:

![Figura 1](media\nb-example-1.png)

## Il processo OPNBHost

Ogni notebook aperto in VSCode demanda l'esecuzione delle sue celle ad una applicazione apposita di nome **OPNBHost**. Questa applicazione è lanciata in esecuzione automaticamente dall'estensione ogni volta che è necessario ed ha il compito di eseguire e restituire i risultati di ogni cella eseguita. **OPNBHost** implementa un server HTTP tramite il quale la comunicazione tra l'estensione e la stessa applicazione è resa possibile.
La porta HTTP di ascolto, per default è la 9000, ma l'utente può modificarla a piacimento tramite l'apposita opzione dell'estensione.

### Problemi con antivirus

OPNBHost è un server HTTP e la sua attività di aprire una porta HTTP lo potrebbe far considerare sospetto agli occhi di un antivirus. Normalmente l'antivirus mostra un messaggio per chiedergli se il file sia da considerarsi attendibile o meno e, in questi casi, basterà rispondere affermativamente per evitare problemi futuri. Se ciò non accadesse, basterà aggiungere OPNBHost alla lista dei file di esclusione dell'antivirus utilizzato.

### Avaria di OPNBHost

Se l'esecuzione di un notebook ha dei problemi al di fuori di quelli normalmente previsti, allora il problema risiederà, molto probabilmente, ad una qualche avaria dell'host. Per risolvere la problematica, basterà terminare forzatamente il processo OPNBHost; esso verrà rilanciato in esecuzione automaticamente dall'estensione alla prossima esecuzione di una cella.

## L'istruzione speciale "Restart"

Una volta che un notebook viene eseguito, il relativo contesto di esecuzione è mantenuto da OPNBHost. Quindi, man mano che vengono dichiarati tipi, strutture, varibili e quant'altro, tutto ciò viene mantenuto persitente dall'host e messo a disposizione per l'esecuzione successiva di altre celle.

Se ad un certo punto si ha la necessità di eliminare tutto il contesto di esecuzione di un notebook, perché desideriamo rieseguirlo dall'inizio come se fosse la prima volta, basterà ricorrere all'istruzione speciale **Restart**:

![Figura 2](media\nb-restart-1.png)

L'istruzione **Restart** deve essere l'unica istruzione presente all'interno di una cella.

## Formattazione dell'output delle celle

Il seguente [notebook](Examples\Notebooks\Output%20examples.opnb) di esempio mostra come generare degli output formattati per le nostre celle per soddifare le nostre esigenze di visualizzazione più complesse di quelle di mostrare un semplice messaggio. 

## Import libraries

E' possibile importare all'interno di un notebook tutte le librerie che sono necessarie all'esecuzione del nostro notebook. Queste librerie possono essere scritte da noi stessi per le nostre finalità oppure utilizzare quelle che altri vorranno mettere a disposizione per noi.
Per importare una libreria è possibile utilizzare l'istruzione speciale **Import**, che possiede il prototipo seguente:

```Delphi
Import('Namespace', 'Percorso della libreria');
```

Il primo parametro, *Namespace*, pur attualmente non utilizzato, deve essere comunque specificato e dev'essere univoco rispetto alle altre istruzioni *import* presenti.
Il secondo parametro deve essere invece il percorso della cartella in cui si trovano i file della libreria da referenziare.

Il seguente [notebook](Examples\Notebooks\SimpleMath.opnb) di esempio mostra come importare una libreria definita in DWScript.

### Algoritmo del processo di importazione

Quando l'istruzione **Import** viene eseguita essa implementerà i passi seguenti:

1. Partendo dal percorso della cartella specificata, vengono censiti tutti i file con estensione *pas, dll, so e dylib* (le estensioni delle librerie dinamiche saranno in funzione del sistema operativo presente). La ricerca si estende anche in profondità, iterando ricorsivamente tutte le sottocartelle incontrate.
2. Terminato il censimento, per ogni file:
    - Se il file ha estensione *pas* allora questo viene considerato come una libreria *Unit* e messa a disposizione di tutte le celle del notebook. Le celle non avranno bisogno di specificare l'istruzione *Uses* per usare queste librerie, in quanto queste dichiarazioni sono da considerarsi implicite.
    - Se il file è una libreria dinamica, allora OPNB caricherà tale libreria all'interno del processo, se tale libreria è effettivamente una libreria conforme a OPNB. Vedremo più avanti come scrivere una libreria conforme. Lo scopo di queste librerie dinamiche è quello di mettere a disposizione del nostro notebook applicazioni, framework e risorse native esterne.

## Scrittura di una libreria conforme

In questo capitolo spiegheremo come scrivere una libreria dinamica che OPNB possa caricare e mettere a disposizione dei nostri notebook.

Come spiegheremo più avanti, il programma OPNB è scritto in Delphi, utilizzando il framework FMX per generare eseguibili per più sistemi operativi (quelli previsti da FMX). 
Anche le librerie dinamiche, attualmente, dovranno essere scritte in Delphi FMX.

Detto questo, in futuro e se ve ne fosse veramente la necessità, si potrebbe prevedere la possibilità di utilizzare un qualsiasi altro linguaggio, come ad esempio il C o C++. Per far questo, si dovranno progettare strutture dati che permettano lo scambio di dati senza conflitti di memoria e relativi *memory leaks* e che funzionino in sistemi operativi diversi.

### Architettura generale

Normalmente, per un utilizzo più pulito e più agevole, il codice presente nelle celle non andranno a dialogare direttamente con una libreria dinamica; questo perché, anche se questo è effettivamente possibile, il codice sarebbe oltremodo complesso e complicato, oltre al fatto che la cella dovrebbe conoscere il protocollo di comunicazione tra OPNB e la libreria importata e questo, per librerie non scritte da noi, non è detto che sia possibile.

Pertanto, l'architettura consigliata che l'autore di una libreria dovrà seguire, è quella di prevedere una (o più) *Unit* che faccia da interfaccia tra il notebook e la libreria dinamica:

![Architettura](media\lib-arch-1.png)

La unit di interfaccia metterà a disposizione dei notebook tutte le funzionalità disponibili, secondo quanto documentato dagli autori della libreria; tutti i dettagli di implementazione e di comunicazione tra la unit di interfaccia e la libreria dinamica saranno interni alla stessa libreria e non saranno visibili dall'esterno.

Useremo la libreria di esempio [**MemoryMatrices**](https://github.com/ElCondor1969/ObjectPascalNotebook/tree/698d45c62704f6ef934f2bcc9859df598428ce2c/Examples/MemoryMatrices) come modello per le spiegazioni che seguiranno.

### Scrittura della libreria dinamica

Una libreria dinamica dovrà esporre le seguenti due procedure:

```pascal
procedure LibInit(const ALibInterface: PLibInterface); cdecl;
begin
  with ALibInterface^ do
    begin
      LibGUID:='{2970D979-84FB-4B42-B730-F596BEC20E2F}';
      InvokeLibProc:=InvokeLibProcImpl;
    end;
  // Follow the initialization code
end;

procedure LibFree(const ALibInterface: PLibInterface); cdecl;
begin
  // Follow the resources release code
end;

exports
  LibInit,
  LibFree;
```

Senza la presenza delle procedure **LibInit** e **LibFree** il processo OPNB non caricherà mai la nostra libreria.

Il progetto dovrà utilizzare la unit **uLibInterface** che dichiarirà tutti i tipi e i record necessari:

```pascal
type
  TInvokeLibProc = function(Context, Instance: NativeInt; const ProcName: PChar; var Args:array of variant): Variant; cdecl;

  PLibInterface = ^TLibInterface;
  TLibInterface = record
    Version: Integer;
    Context: NativeInt;
    Namespace: PChar;
    ExecutionPath: PChar;
    LibHandle: TDynLibHandle;
    LibGUID: PChar;
    InvokeLibProc: TInvokeLibProc;
  end;
```

La procedura **LibInit** riceve un puntatore al record **TLibInterface**; ci sono due campi di questo record che vanno obbligatoriamente valorizzati per farli acquisire dal processo OPNB, e sono:

1. **LibGUID**
2. **InvokeLibProc**

Il campo **LibGUID** deve essere valorizzato con il GUID che permetterà di individuare la nostra libreria all'interno del processo. Ogni libreria conforme OPNB dovrà possedere il proprio GUID univoco. Tale informazione, come vedremo, è fondamentale per permettere la cerniera tra la libreria dinamica e le unit di interfaccia della libreria.

Il campo **InvokeLibProc** deve essere valorizzato con un puntatore a quella che sarà la procedura di comunicazione tra il processo OPNB e la libreria dinamica e che dovrà essere di tipo **TInvokeLibProc** visto sopra.
Quando il processo OPNB richiederà delle funzionalità, lo farà invocando opportunamente questa procedura.

### La libreria **MemoryMatrices**

Illustrato le regole e la struttura di base per la nostra libreria, continuiamo la nostra spiegazione servendoci della libreria di esempio **MemoryMatrices**.

Questa libreria vuole consentire le operazioni di base tra vettori e matrici, ma eseguite non al livello di script ma a livello di codice della macchina. Infatti sia il codice delle celle che quello delle *unit* viene eseguito tramite la sua interpretazione a run-time, laddove il codice di una libreria dinamica viene eseguito nativamente e quindi in maniera sensibilmente più veloce.

La libreria mette a disposizione le funzionalità seguenti:
1. Allocazione in memoria di vettori e matrici di dimensioni qualsiasi.
2. Lettura e scrittura di un vettore o matrice allocati.
3. Operazioni di:
    - Moltiplicazione
    - Trasposizione
    - Somma
    - Sottrazione
    - Hadamard
    - Moltiplicazione scalare

#### Il progetto di libreria dinamica MemoryMatrices 

Questo progetto Delphi FMX implementa la nostra libreria dinamica di esempio. Affinché sia una libreria conforme, essa
definirà le due procedure **LibInit** e **LibFree** in questo modo:

```pascal
procedure LibInit(const ALibInterface: PLibInterface); cdecl;
begin
  with ALibInterface^ do
    begin
      LibGUID:='{2970D979-84FB-4B42-B730-F596BEC20E2F}';
      InvokeLibProc:=InvokeLibProcImpl;
    end;
  MatrixDict:=TDictionary<integer, TMatrixEntry>.Create;
end;

procedure LibFree(const ALibInterface: PLibInterface); cdecl;
begin
  FreeMatrixDict;
end;
```

Non è lo scopo di questo capitolo spiegare come la libreria gestisce il ciclo di vita delle matrici ed implementa le operazioni elencate sopra; quello che ci interessa è vedere come rendere possibile la comunicazione tra il processo OPNB e la libreria. Infatti, la libreria implementa la procedura **InvokeLibProcImpl**, quella il cui puntatore è stato passato alla variabile **InvokeLibProc**, nel seguente modo:

```pascal
function InvokeLibProcImpl(Context, Instance: NativeInt; const ProcName: PChar; var Args:array of variant): Variant; cdecl;
begin
  if (SameText(ProcName,'InstantiateMatrix')) then
    Result:=InstantiateMatrix(Args[0], Args[1], Args[2], Args[3])
  else if (SameText(ProcName,'FreeMatrix')) then
    FreeMatrix(Args[0])
  else if (SameText(ProcName,'ReadMatrixInfo')) then
    ReadMatrixInfo(Args[0], Args[1], Args[2])
  else if (SameText(ProcName,'ReadMatrix')) then
    Result:=ReadMatrix(Args[0], Args[1], Args[2])
  else if (SameText(ProcName,'WriteMatrix')) then
    WriteMatrix(Args[0],Args[1])
  else if (SameText(ProcName,'RandomizeMatrix')) then
    RandomizeMatrix(Args[0],Args[1])
  else if (SameText(ProcName,'MulMatrices')) then
    Result:=MulMatrices(Args[0],Args[1])
  else if (SameText(ProcName,'TransposeMatrix')) then
    Result:=TransposeMatrix(Args[0])
  else if (SameText(ProcName,'AddMatrices')) then
    Result:=AddMatrices(Args[0],Args[1])
  else if (SameText(ProcName,'SubMatrices')) then
    Result:=SubMatrices(Args[0],Args[1])
  else if (SameText(ProcName,'HadamardMatrices')) then
    Result:=HadamardMatrices(Args[0],Args[1])
  else if (SameText(ProcName,'ScaleMatrix')) then
    Result:=ScaleMatrix(Args[0],Args[1])
  else
    RaiseException('Proc "%s" unknown',[ProcName]);
end;
```

Come osserviamo sopra, chi ha invocato la libreria dall'esterno specifica:
- Il riferimento all'eventuale oggetto/risorsa tramite il parametro **Instance**.
- Il nome della procedura/metodo tramite il parametro **ProcName**.
- La lista delle varibiabili di ingresso e/o di uscita da utilizzare nell'invocazione, tramite il parametro **Args**.

Il codice non fa altro che vedere quale procedura è stata invocata e chiamare la relativa procedura/funzione di implementazione. Ovviamente, per ogni procedura invocata, il numero dei parametri e dei relativi significati cambia e questo dev'essere a conoscenza del chiamante.

#### La unit di interfaccia **uMemoryMatrices**

Questa [unit](Examples\MemoryMatrices\Lib\uMemoryMatrices.pas) rappresenta il codice di interfaccia tra i notebook utilizzatori e la libreria dinamica. Come spiegavamo sopra, questa *unit* offrirà ai notebook le funzionalità messe a disposizione dalla libreria, nel modo più comodo possibile, nascondendo al contempo tutta l'implementazione di dialogo con la libreria dinamica.
La definizione pubblica della *unit* è la seguente:

```pascal
function InstantiateMatrix(const NumRows, NumCols: integer; Initialize:boolean=false; Value: float=0): integer;
procedure FreeMatrix(const MatrixHandle: integer);
procedure ReadMatrixInfo(const MatrixHandle: integer; var NumRows, NumCols: integer);
function ReadMatrix(const MatrixHandle: integer): TArrayVariantArray;
procedure WriteMatrix(const MatrixHandle: integer; Data: TArrayVariantArray);
procedure RandomizeMatrix(const MatrixHandle: integer; Bias: float=0.5);
function MulMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
function TransposeMatrix(const MatrixHandle: integer): integer;
function AddMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
function SubMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
function HadamardMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
function ScaleMatrix(const MatrixHandle: integer; S: float): integer;
```

Come osserviamo, la *unit* definisce tutte le procedure e funzioni utilizzabili dalle celle. Un esempio di utilizzo della libreria può essere trovato in questo [notebook](Examples\Notebooks\Memory%20Matrices%20example%201.opnb).

Per chiudere il cerchio ci manca di capire come la *unit* comunica con la sua corrispondente libreria dinamica. Per farlo, prendiamo come esempio illustrativo l'implementazione della procedura **ReadMatrixInfo**:

```pascal
implementation

const
  LibGUID='{2970D979-84FB-4B42-B730-F596BEC20E2F}';

procedure ReadMatrixInfo(const MatrixHandle: integer; var NumRows, NumCols: integer);
var
  Args: TVariantArray;
begin
  Args.Push(MatrixHandle);
  Args.Push(0);
  Args.Push(0);
  __LibInterface_InvokeLibProc(LibGUID, 0, 'ReadMatrixInfo', Args);
  NumRows:=Args[1];
  NumCols:=Args[2];
end;
```

Come possiamo osservare, il dialogo con una libreria dinamica avviene tramite l'utiizzo della funzione **__LibInterface_InvokeLibProc**; i parametri da passare a questa procedura sono:
- Il GUID univoco della procedura alla quale si vuole inviare il comando.
- L'istanza dell'oggetto a cui la procedura da invocare appartiene; si può passare 0 se si invoca una procedura/funzione e non un metodo.
- La lista dei parametri di ingresso e/o di uscita.

La **__LibInterface_InvokeLibProc** restituisce anche il valore di ritorno nel caso la il nome invocato sia quello di una funzione.

## Esecuzione di un notebook su macchine remote

Come abbiamo visto, le celle dei nostri notebook vengono eseguite dal processo OPNB che viene lanciato in esecuzione sulla nostra macchina locale.

Ci potrebbero però essere dei casi nei quali l'esecuzione di un notebook sia meglio che avvenga non nella nostra macchina, ma in un'altra più performante, o con delle risorse necessarie che la nostra macchina locale non possiede. Per far capire meglio una possibile esigenza, si pensi ad un notebook che utilizzi delle librerie di reti neurali, le quali necessitino di una GPU avanzata. In uno scenario come questo, noi vorremmo modificare localmente il nostro notebook, ma demandare la sua esecuzione nella macchina remota che possiede le capacità hardware necessarie.

Questo è possibile utilizzando, all'inizio del nostro notebook, l'istruzione **SetRemoteOPNBHost**:

![SetRemoteOPNBHost](media\nb-remote-host-1.png)

L'istruzione deve essere l'unica istruzione della cella e, dopo la sua esecuzione, tutte le esecuzioni delle celle del notebook saranno reindirizzate verso l'host specificato.
Ovviamente, nella macchina remota deve trovarsi già in esecuzione una istanza del processo OPNB, altrimenti le richieste di esecuzione cadrebbero nel vuoto.

### Considerazioni sulla sicurezza

Ovviamente, per motivi di sicurezza, l'host OPNB della macchina remota dovrebbe essere lanciato in esecuzione in modo che abiliti il protocollo HTTPS; per far ciò, l'applicazione dovrebbe essere lanciato in esecuzione specificando i parametri seguenti:

- **UseSSL**: Flag booleano che abilita il protocollo HTTPS.
- **CertFile**: Nome del file del certificato.
- **CertKey**: Nome del file delle chiavi del certificato.
- **CertPassword**: Password del certificato.

Ad esempio:

```dos
OPNBHost -port "9001" -UseSSL true -CertFile "MyCert.cert.pem" -CertKey "MyCert.key.pem" -CertPassword "APassword"
```

Ad ogni modo, abilitare il protocollo HTTPS non basta, da solo, a garantire la sicurezza, perché attualmente il processo OPNB non implementa nessun controllo sugli accessi e chiunque, che conoscesse l'URL di ascolto del processo, potrebbe inviare le proprie richieste di esecuzione.
Questo aspetto deve essere tenuto bene in mente nel caso si volesse attivare un processo OPNB destinato ad accogliere richieste remote.

## Compilazione di OPNB

Come abbiamo già detto, L'applicazione OPNB è stato scritta in Delphi FMX e deve essere compilato tramite questo linguaggio.
Inoltre, come visto sopra, viene utilizzato [**DWScript**](https://github.com/EricGrange/DWScript) come linguaggio per i nostri notebook. Pertanto, per compilare l'estensione, abbiamo bisogno dei relativi sorgenti.

Il repository contiene all'interno della cartella *vendor\DWScript*, un submodule GIT che punta al repository di DWScript. Basterà quindi eseguire il checkout di questo submodule per avere tutti i sorgenti a disposizione per la compilazione del programma.

## Aiuto cercasi!

Delphi FMX permette di generare eseguibili anche per altri sistemi operativi, come Linux e macOS. Purtroppo non sono in grado generare eseguibili per questi sistemi operativi e proprio per questo chiedo a chiunque abbia il piacere di collaborare, e sia in grado di compilare anche per questi sistemi operativi, di farsi avanti e dare la possibilità a questa estensione di essere utilizzata anche al di fuori di Windows.

Grazie!
