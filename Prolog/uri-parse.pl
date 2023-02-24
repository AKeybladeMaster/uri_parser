%%%% -*- Mode: Prolog -*-
%%%% uri-parse.pl

%%% Darion Mance 869239

uri_parse(URIString, uri(S, U, H, PoNum, Pa, Q, F)) :-
    string_lower(URIString, URILowerString),
    atom_chars(URILowerString, URIList),
    scheme_part(URIList, Scheme, SchemeRest),
    translate(Scheme, S),
    authority_part(S, SchemeRest, Userinfo, Host, Port, AuthorityRest),
    path_part(AuthorityRest, Path, PathRest),
    query_part(PathRest, Query, QueryRest),
    fragment_part(QueryRest, Fragment),
    translate(Userinfo, U),
    translate(Host, H),
    translate(Port, Po),
    n_conversion(Po, PoNum),
    translate(Path, Pa),
    translate(Query, Q),
    translate(Fragment, F),
    !.

uri_parse(URIString, uri(S, U, H, PoNum, Pa, Q, F)) :-
    string_lower(URIString, URILowerString),
    atom_chars(URILowerString, URIList),
    scheme_part(URIList, Scheme, SRest),
    translate(Scheme, S),
    s_syntax(S, SRest, Userinfo, Host, Port, Path, Query, Fragment),
    translate(Userinfo, U),
    translate(Host, H),
    translate(Port, Po),
    n_conversion(Po, PoNum),
    translate(Path, Pa),
    translate(Query, Q),
    translate(Fragment, F),
    !.


translate([], []) :- !.
translate(List, Atom) :-
    string_to_atom(List, Atom),
    !.


n_conversion([], []) :- !.
n_conversion(Atom, Number) :-
    atom_number(Atom, Number),
    !.   

%---------%---------%---------%---------%---------%
%% display dell'uri

uri_display(uri(Scheme, Userinfo, Host, Port, Path, Query, Frag)) :-
    format(
        'Scheme: ~w~n\c
         Userinfo: ~w~n\c
         Host: ~w~n\c
         Port: ~w~n\c
         Path: ~w~n\c
         Query: ~w~n\c
         Frag: ~w~n\c',
        [Scheme, Userinfo, Host, Port, Path, Query, Frag]).

uri_display(uri(Scheme, Userinfo, Host, Port, Path, Query, Frag), Stream) :-
    format(Stream,
	   'Scheme: ~w~n\c
            Userinfo: ~w~n\c
            Host: ~w~n\c
            Port: ~w~n\c
            Path: ~w~n\c
            Query: ~w~n\c
            Frag: ~w~n\c',
           [Scheme, Userinfo, Host, Port, Path, Query, Frag]).


%---------%---------%---------%---------%---------%
%% analisi dello scheme

% controlli validita' scheme
scheme_part([X | _], _, _) :-
    invalid_char(X),
    !,
    fail.

scheme_part([X, ':'], [X], []) :- !.

% scheme incontra ':' = finito -> passa il resto
scheme_part([X, ':'| Rest], [X], Rest) :- !.

% scorrimento ricorsivo e salvataggio risultato in 2o parametro (Scheme)
scheme_part([X | Xs], [X | Ys], Rest) :-
    scheme_part(Xs, Ys, Rest),
    !.


%---------%---------%---------%---------%---------%
%% analisi dell'authority

% controlli validita' pre-authority
authority_part(_, [_, '/', '/' | _], _, _, _, _) :-
    !,
    fail.

% special scheme + (//)* = errore -> fail
authority_part(X, _, _, _, _, _) :-
    member(X, [mailto, news, tel, fax, zos]),
    !,
    fail.

% casi di controllo per trovare userinfo, host e port (se presenti)
authority_part(_, ['/', '/' | Rest], Userinfo, Host, Port, AuthRest) :-
    userinfo_part(Rest, Userinfo, UserRest),
    host_part(UserRest, Host, HostRest),
    port_part(HostRest, Port, AuthRest),
    !.

authority_part(_, ['/', '/' | Rest], UInfo, Host, ['8', '0'], AuthRest) :-
    userinfo_part(Rest, UInfo, UserRest),
    host_part(UserRest, Host, AuthRest),
    !.

authority_part(_, ['/', '/' | Rest], [], Host, Port, AuthRest) :-
    host_part(Rest, Host, HostRest),
    port_part(HostRest, Port, AuthRest),
    !.

authority_part(_, ['/', '/' | Rest], [], Host, ['8', '0'], AuthRest) :-
    host_part(Rest, Host, AuthRest),
    !.

% caso con / = passaggio al secondo caso di URI -> passa il resto
authority_part(_, ['/' | Rest], [], [], ['8', '0'], ['/' | Rest]) :- !.

authority_part(_, [X | _], _, _, _, _) :- 
    invalid_host_zos_char(X),
    !,
    fail.

% mi hai trovato!
authority_part(lp, [], User, Host, ['4', '2'], []) :-
    translate("prof", User),
    translate("antoniotti", Host),
    !.

authority_part(_, [X | _], _, _, _, _) :- 
    char_type(X, alnum),
    !,
    fail.

authority_part(_, SchemeRest, [], [], ['8', '0'], SchemeRest) :- !.

%---------%---------%---------%---------%---------%
%% sub-analisi dell'userinfo

userinfo_part([X], _, _) :- 
    invalid_char(X),
    !,
    fail.

% userinfo di mailto -> non incontra '@'
userinfo_part([X], [X], []) :- !.

userinfo_part([X | _], _, _) :-
    invalid_char(X),
    !,
    fail.

% usato negli special scheme
userinfo_part([_, End], _, _) :-
    invalid_char(End),
    !,
    fail.

userinfo_part([X, '@' | Rest], [X], Rest) :- !.

userinfo_part([X | Xs], [X | Ys], Rest) :-
    userinfo_part(Xs, Ys, Rest),
    !.

%---------%---------%---------%---------%---------%
%%% CASI IN TEL/FAX PER VEDERE SE USERINFO %%%
%%%               E'UN NUMERO              %%%
%---------%---------%---------%---------%---------%

% check_user_digits([]) :- !.

% check_user_digits(['+', _, '+', _ | _]) :-
%     !,
%     fail.

% check_user_digits([_, '+', _ | _]) :-
%     !,
%     fail.

% check_user_digits(['+', X | Xs]) :- 
%     digit(X),
%     check_user_digits(Xs),
%     !.

% check_user_digits([X | Xs]) :- 
%     digit(X),
%     check_user_digits(Xs),
%     !.


%---------%---------%---------%---------%---------%
%% analisi dell'host

% verifica se host e' IP = NNN.NNN.NNN.NNN
host_part(Uri, Host, HostRest) :-
    is_ip(Uri, Host, HostRest, 0),
    !.

host_part([X], _, _) :-
    invalid_char(X),
    !,
    fail.

% host = ultima parte dell'URI -> non incontra ':' | '/' | '?' | '#'
host_part([X], [X], []) :- !.

host_part([X | _], _, _) :-
    invalid_host_zos_char(X),
    !,
    fail.

% incontra un char invalido alla fine dell'URI -> fallisce
host_part([_, End], _, _) :-
    member(End, ['.', ' ', '?', '#', '@', ':']),
    !,
    fail.

% host incontra path | query | fragment -> caso base -> passa il resto
host_part([X, Enc | Rest], [X], [Enc | Rest]) :-
    member(Enc, [':', '/']),
    !.

% caso ricorsivo <id host> . <id host>*
host_part([X, '.' | Xs], [X, '.' | Ys], Rest) :-
    host_part(Xs, Ys, Rest),
    !.

% caso ricorsivo normale
host_part([X | Xs], [X | Ys], Rest) :-
    host_part(Xs, Ys, Rest),
    !.

%---------%---------%---------%---------%---------%
%%% CLAUSOLE PER VERIFICA PRESENZA IP %%%
%---------%---------%---------%---------%---------%

is_ip([X, Y, Z | Xs], [X, Y, Z], Xs , 3) :-
    digit(X),
    digit(Y),
    digit(Z),
    string_to_atom([X, Y, Z], IPAtom),
    atom_number(IPAtom, IPNum),
    IPNum =< 255,
    IPNum >= 0,
    !.

is_ip([X, Y, Z, '.' | Xs], [X, Y, Z, '.' | Ys], Rest, Count) :-
    NewCount is Count + 1,
    digit(X),
    digit(Y),
    digit(Z),
    string_to_atom([X, Y, Z], IPAtom),
    atom_number(IPAtom, IPNum),
    IPNum =< 255,
    IPNum >= 0,
    is_ip(Xs, Ys, Rest, NewCount),
    !.


%---------%---------%---------%---------%---------%
%% analisi del port

port_part([], ['8', '0'], []) :- !.

% caso in cui port = ultima parte dell'URI
port_part([X], [X], []) :-
    digit(X),
    !.

port_part([':', _, ':', _ | _], _, _) :-
    !,
    fail.

port_part([_, ':', _ | _], _, _) :-
    !,
    fail.

% port inesistente in URI -> passa il resto
port_part(['/' | Rest], ['8', '0'], ['/' | Rest]) :- !.

% port incontra path | query | fragment -> passa il resto
port_part([X, '/' | Rest], [X], ['/' | Rest]) :-
    !,
    digit(X).

% verifica che port cominci con ':'
port_part([':', X | Xs], [X | Ys], Rest) :-
    digit(X),
    port_part(Xs, Ys, Rest),
    !.

% caso ricorsivo normale
port_part([X | Xs], [X | Ys], Rest) :-
    digit(X),
    port_part(Xs, Ys, Rest),
    !.


%---------%---------%---------%---------%---------%
%% analisi della path

path_part([], [], []) :- !.

path_part(['/'], [], []) :- !.

path_part(['/', '/' | _], _, _) :-
    !,
    fail.

path_part(['/', Enc | Rest], [], [Enc | Rest]) :-
    member(Enc, ['?', '#']),
    !.

path_part([Enc | Rest], [], [Enc | Rest]) :-
    member(Enc, ['?', '#']),
    !.

% verifica che path cominci con '/'
path_part(['/' | Xs], Ys, Rest) :-
    path_part(Xs, Ys, Rest),
    !.

path_part(['/', BadEnd], _, _) :-
    member(BadEnd, ['/', '.', ' ', '?', '#', '@', ':']),
    !,
    fail.

path_part([X | _], _, _) :-
    invalid_char(X),
    !,
    fail.

% fail se path finisce con char invalido etc.
path_part([_, End], _, _) :-
    member(End, ['/', '.', ' ', '?', '#', '@', ':']),
    !,
    fail.

path_part([_, BadEnd, End], _, _) :-
    member(BadEnd, [' ', '/']),
    invalid_char(End),
    !,
    fail.

path_part([_, BadEnd, Enc | _], _, _) :-
    invalid_char(BadEnd),
    member(Enc, ['?', '#', '/']),
    !,
    fail.

path_part(['/', Enc | Rest], [], [Enc | Rest]) :-
    member(Enc, ['?', '#']),
    !.

% caso in cui path incontra query | fragment
path_part([X, Enc | Rest], [X], [Enc | Rest]) :-
    member(Enc, ['?', '#']),
    !.

% caso con lo spazio, lo formatta in %20
path_part([X, ' ' | Xs], [X, '%', '2', '0' | Ys], Rest) :-
    path_part(Xs, Ys, Rest),
    !.

% caso ricorsivo <id path> / <id path>*
path_part([X, '/' | Xs], [X, '/' | Ys], Rest) :-
    path_part(Xs, Ys, Rest),
    !.

% caso ricorsivo normale
path_part([X | Xs], [X | Ys], Rest) :-
    path_part(Xs, Ys, Rest),
    !.


%---------%---------%---------%---------%---------%
%% analisi della query

query_part([], [], []) :- !.

query_part(['#' | Rest], [], ['#' | Rest]) :- !.

query_part(['?', InvalidEnd | _], _, _) :-
    member(InvalidEnd, ['#', ' ']),
    !,
    fail.

query_part(['?'], _, _) :-
    !,
    fail.

query_part([_, ' '], _, _) :-
    !,
    fail.

% per la zos scheme
query_part(['(' | _], _, _) :-
    !,
    fail.

% non incide sul controllo dell'uri
% query_part([X | _], _, _) :-
%     invalid_query_char(X),
%     !,
%     fail.

% caso in cui la query incontra il fragment
query_part([X, '#' | Rest], [X], ['#' | Rest]) :- !.

% verifica che query cominci con '?'
query_part(['?' | Xs], Ys, Rest) :-
    query_part(Xs, Ys, Rest),
    !.

% caso con lo spazio, lo formatta in %20
query_part([X, ' ' | Xs], [X, '%', '2', '0' | Ys], Rest) :-
    query_part(Xs, Ys, Rest),
    !.

% usato per mantenere i ? digitati
query_part([X, '?' | Xs], [X, '?' | Ys], Rest) :-
    query_part(Xs, Ys, Rest),
    !.

% caso ricorsivo con scorrimento di char per char
query_part([X | Xs], [X | Ys], Rest) :-
    query_part(Xs, Ys, Rest),
    !.


%---------%---------%---------%---------%---------%
%% analisi del fragment

fragment_part([], []) :- !.

fragment_part(['#'], _) :-
    !,
    fail.

fragment_part([_, ' '], _) :-
    !,
    fail.

% verifica che fragment cominci con '#'
fragment_part(['#' | Xs], Ys) :-
    fragment_part(Xs, Ys),
    !.

% caso con lo spazio, lo formatta in %20
fragment_part([X, ' ' | Xs], [X, '%', '2', '0' | Ys]) :-
    fragment_part(Xs, Ys),
    !.

% fragment = ultimo elemento di URI -> si scorre fino alla fine
fragment_part([X | Xs], [X | Ys]) :-
    fragment_part(Xs, Ys),
    !.


%---------%---------%---------%---------%---------%
%% analisi dello special scheme syntax

s_syntax(mailto, [], [], [], ['8', '0'], [], [], []) :- !.

s_syntax(mailto, SchemeRest, Userinfo, Host, ['8', '0'], [], [], []) :-
    userinfo_part(SchemeRest, Userinfo, UserRest),
    host_part(UserRest, Host, []),
    !.

s_syntax(mailto, SchemeRest, Userinfo, [], ['8', '0'], [], [], []) :-
    userinfo_part(SchemeRest, Userinfo, []),
    !.

s_syntax(mailto, _, [], [], [], [], [], []) :- 
    !,
    fail.

s_syntax(news, [], [], [], ['8', '0'], [], [], []) :- !.

s_syntax(news, SchemeRest, [], Host, ['8', '0'], [], [], []) :-
    host_part(SchemeRest, Host, []),
    !.

s_syntax(SAtom, [], [], [], ['8', '0'], [], [], []) :-
    member(SAtom, [tel, fax]),
    !.

s_syntax(SAtom, SchemeRest, Userinfo, [], ['8', '0'], [], [], []) :-
    member(SAtom, [tel, fax]),
    !,
    userinfo_part(SchemeRest, Userinfo, []).
% check_user_digits(Userinfo).

s_syntax(SAtom, _, [], [], [], [], [], []) :-
    member(SAtom, [tel, fax]),
    !,
    fail.

s_syntax(zos, SchemeRest, Userinfo, Host, Port, [], _, _) :-
    authority_part(zos2, SchemeRest, Userinfo, Host, Port, AuthorityRest),
    special_path(AuthorityRest, [], _),
    !,
    fail.

s_syntax(zos, SchemeRest, Userinfo, Host, Port, SPath, Query, Frag) :-
    authority_part(zos2, SchemeRest, Userinfo, Host, Port, AuthorityRest),
    special_path(AuthorityRest, Path, PathRest),
    path_length(Path, PathLength),
    PathLength =< 44,
    sub_path(PathRest, SubPath, SubPathRest),
    path_length(SubPath, SubPathLength),
    SubPathLength =< 10, % =< 10 vengono contate anche le parentesi
    append(Path, SubPath, SPath),
    query_part(SubPathRest, Query, QueryRest),
    fragment_part(QueryRest, Frag),
    !.

s_syntax(zos, SchemeRest, Userinfo, Host, Port, Path, Query, Frag) :-
    authority_part(zos2, SchemeRest, Userinfo, Host, Port, AuthorityRest),
    special_path(AuthorityRest, Path, PathRest),
    path_length(Path, PathLength),
    PathLength =< 44,
    query_part(PathRest, Query, QueryRest),
    fragment_part(QueryRest, Frag),
    !.


%---------%---------%---------%---------%---------%
%% special path + sub path per scheme zos

special_path([], [], []) :- !.

% path non esiste, comincia con '?' | '#' -> passa Enc + resto
special_path([Enc | Rest], [], [Enc | Rest]) :-
    member(Enc, ['?', '#']),
    !.

special_path(['/', BadBegin | _], _, _) :-
    member(BadBegin, ['.', '/', ' ', '?', '#', '@', '(']),
    !,
    fail.

special_path(['/', X | _], _, _) :-
    digit(X),
    !,
    fail.

% caso ricorsivo <id path> / <id path>* fallisce
special_path([_, '/' | _], _, _) :-
    !,
    fail.

% verifica che special path cominci con '/'
special_path(['/' | Xs], Ys, Rest) :-
    special_path(Xs, Ys, Rest),
    !.

special_path([X | _], _, _) :-
    invalid_host_zos_char(X),
    !,
    fail.

% fail se special finisce con '.', '/', ' ', '?', '#' etc.
special_path([_, End], _, _) :-
    member(End, ['.', '/', ' ', '?', '#', '@', ' ', ':']),
    !,
    fail.

special_path([_, BadEnd, End], _, _) :-
    member(BadEnd, [' ', '.']),
    invalid_host_zos_char(End),
    !,
    fail.

% caso in cui path incontra query | fragment
special_path([X, Enc | Rest], [X], [Enc | Rest]) :-
    member(Enc, ['?', '#', '(']),
    !.

% caso ricorsivo <id path> . <id path>*
special_path([X, '.' | Xs], [X, '.' | Ys], Rest) :-
    char_type(X, alnum),
    special_path(Xs, Ys, Rest),
    !.

% caso ricorsivo con '..'
special_path([X, '.', '.' | Xs], [X, '.', '.' | Ys], Rest) :-
    char_type(X, alnum),
    special_path(Xs, Ys, Rest),
    !.

% caso ricorsivo normale
special_path([X | Xs], [X | Ys], Rest) :-
    char_type(X, alnum),
    special_path(Xs, Ys, Rest),
    !.


sub_path([], [], []) :- !.

sub_path(['(', ')'], _, _) :-
    !,
    fail.

sub_path(['(', ' ', ')'], _, _) :-
    !,
    fail.

% caso in cui sub_path = ultima parte dell'URI
sub_path([X, ')'], [X , ')'], []) :- !.

sub_path([X | _], _, _) :-
    invalid_host_zos_char(X),
    !,
    fail.

sub_path(['(', X | _], _, _) :-
    digit(X),
    !,
    fail.

sub_path([_], _, _) :-
    !,
    fail.

sub_path([X, ')', Enc | Rest], [X, ')'], [Enc | Rest]) :-
    member(Enc, ['?', '#']),
    !.

% caso in cui sub-path incontra query | fragment senza ')'
sub_path([_, BadEnc | _], _, _) :-
    member(BadEnc, ['?', '#']),
    !,
    fail.

sub_path([_, ')', _ | _], _, _) :-
    !,
    fail.

sub_path(['(' | Xs], ['(' | Ys], Rest) :-
    sub_path(Xs, Ys, Rest),
    !.

sub_path([X | Xs], [X | Ys], Rest) :-
    sub_path(Xs, Ys, Rest),
    !.


path_length([], 0).
path_length([_|Xs], L) :-
    path_length(Xs, N),
    L is N + 1,
    !.


%---------%---------%---------%---------%---------%
%% Fatti usati per la grammatica

digit('0').
digit('1').
digit('2').
digit('3').
digit('4').
digit('5').
digit('6').
digit('7').
digit('8').
digit('9').


invalid_char('/').
invalid_char('?').
invalid_char('#').
invalid_char('@').
invalid_char(':').
invalid_char(' ').


% non sembra ci sia bisogno di usarlo
% invalid_query_char('#').


invalid_host_zos_char('.').
invalid_host_zos_char(X) :-
    invalid_char(X).


%%%% -*- end of file -- uri-parse.pl -*-
