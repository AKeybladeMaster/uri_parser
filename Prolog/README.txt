%%% -*- Mode: Prolog -*-
%%% README.txt


%---------%---------%---------%---------%---------%
%%	Informazioni generali

Nome progetto: uri-parse.pl

Obiettivo: Parser semplificato di URI

Progetto a cura di: Beasty

Linguaggio: SWI-Prolog 8.4.0

!!! In caso di versioni diverse dalla 8.4.0 non !!!
!!!  si assicura il corretto funzionamento del  !!!
!!!                 programma.                  !!!


%---------%---------%---------%---------%---------%
%% Caratteristiche principali

- Parsifica una stringa URI nella forma opportuna in Prolog
- Ottiene un determinato campo/valore data una lista di parametri in input
- Scrive il formato parsato dell'URI su uno Stream (e ipotetico file)


%---------%---------%---------%---------%---------%
%% Istruzioni d'uso

1) Richiama uri_parse(URIString, URIParsed) per ottenere l'uri parsata
   nella forma opportuna in Prolog.

2) Richiama uri_parse(URIString, uri(_, _, _, _, _, _, _)) con uno o
   piu' campi '_' riempiti con nomi dei valori che si vogliono estrarre
   dall'uri parsata.

3) Richiama uri_display(ParsedURI) per ottenere una stampa formattata
   dell'uri parsata in output.

4) Richiama in alternativa uri_display(ParsedURI, Stream) per scrivere
   su stream una versione formattata dell'uri parsata in output. 


%---------%---------%---------%---------%---------%
%% Modifiche al progetto

Ci sono state varie domande che mi sono posto riguardo alla parsificazione
di certi campi/elementi dell'URI; sono arrivato a determinate conclusioni:

- L'implementazione del controllo di IP e' stata fatta per il formato
  di IP: NNN.NNN.NNN.NNN, di cui N un digit; qualsiasi formato diverso da
  questo (questo include il numero di N digit presenti nei sottogruppi
  dell'ip) risultera' in un fail della clausola ma si passera' comunque
  al controllo normale dell'host.

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

- (FACOLTATIVO PRE-UPDATE DEL PDF) per gli scheme tel/fax, ho consentito
  l'uso di soli digit e di un eventuale carattere '+' per il prefisso.
  É possibile "attivare" tale funzione togliendo i commenti in determinate
  parti (nome della clausola: 'check_user_digits' nella sezione di Userinfo).

- (POST-UPDATE DEL PDF - 29/12/2021) l'uso di 80 per il port e' ormai
  di default sempre qualora non specificato (scheme speciali inclusi).


%---------%---------%---------%---------%---------%
%% Riflessioni finali

Il progetto é stato divertente da implementare, nonostante sia stato
tentato dall'uso delle DCG per completarlo.

L'intero progetto è stato svolto affinchè il testo non superasse le 80
colonne (e anche questo file rispetta tali norme).

Invito infine a controllare la presenza di un piccolo easter egg
nel codice!


%---------%---------%---------%---------%---------%


%%% -*- end of file -- uri-parse.pl -*-