;;; -*- Mode: Common Lisp -*-
;;; README.txt


;---------;---------;---------;---------;---------;
;; Informazioni generali

Nome progetto: uri-parse.lisp

Obiettivo: Parser semplificato di URI

Progetto a cura di: Beasty

Linguaggio: Common Lisp (LispWorks 7.1)

!!!  In caso di versioni diverse dalla 7.1 non !!!
!!!    si assicura il corretto funzionamento   !!!
!!!               del programma.               !!!


;---------;---------;---------;---------;---------;
;; Caratteristiche principali

- Parsifica una stringa URI nella forma opportuna in Lisp
- Ottiene un determinato campo/valore data una lista di parametri in input
- Scrive il formato parsato dell'URI su uno Stream (e ipotetico file)


;---------;---------;---------;---------;---------;
;; Istruzioni d'uso

1) Richiama uri-parse(URIString) per ottenere l'uri parsata
   nella forma opportuna in Lisp (defstruct).
   - opzionalmente, salva in un parametro tramite 'defparameter URIParsed'
   (es. defparameter URIParsed (uri-parse "http://disco.unimib.it"))

2) Richiama una delle varie funzioni per ottenere un campo/valore dell'uri
   parsata in output:
   - uri-scheme
   - uri-userinfo
   - uri-host
   - uri-port
     etc.
   (es. uri-scheme URIParsed (dall'esempio precedente) -> "http")

3) Richiama uri-display URIParsed per ottenere una stampa formattata
   dell'uri parsata in output (avendo come parametro opzionale lo
   Stream, impostato di default a *standard-output*, altrimenti detto T).


;---------;---------;---------;---------;---------;
;; Modifiche al progetto

Ci sono state varie domande che mi sono posto riguardo alla parsificazione
di certi campi/elementi dell'URI; sono arrivato a determinate conclusioni:

- Scheme, Userinfo, Host non possono contenere spazi dato che non esistono
  (implementazione reale) uri tali

- Path, Query e Fragment permettono l'uso degli spazi, che vengono poi
  codificati in '%20', date le opportune condizioni per convertirle
  (es. finire path con spazio da errore).

- il controllo del carattere invalido in query non sembra incida sulla
  parsificazione in quanto al primo # trovato si passa al fragment, dove
  tutti i caratteri sono accettati (non vale il caso '?#'); serve comunque
  almeno un carattere dopo '?' per la query.

- la path per zos e' obbligatoria, a prescindere dal tipo di schema che 
  l'uri ha.

- data l'incertezza nell'interpretazione delle tipiche uri con scheme zos,
  ho deciso di affidarmi completamente alla grammatica definita nel PDF e
  deciso di permettere l'uso di due '.' vicini nella path dello scheme zos

- in presenza di invalidita' all'interno della stringa fornita per la
  parsificazione dell'uri viene lanciato un errore tramite la funzione
  'error', che interrompe l'esecuzione della parsificazione e determina
  cosa e' andato storto.

- (POST-UPDATE DEL PDF - 29/12/2021) l'uso di 80 per il port e' ormai
  di default sempre qualora non specificato (scheme speciali inclusi).


;---------;---------;---------;---------;---------;
;; Riflessioni finali

L'intero progetto è stato svolto affinchè il testo non superasse le 80
colonne (e anche questo file rispetta tali norme).

L'uso della defstruct ha facilitato la strutturizzazione dell'uri parsata.


;---------;---------;---------;---------;---------;


;;; -*- end of file -- uri-parse.lisp -*-