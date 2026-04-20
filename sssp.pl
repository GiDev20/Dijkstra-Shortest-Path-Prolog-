%% -*- mode: prolog; -*-



%%++%% Predicato di test completo
run_test :-
    G = test_network,
    format('~n--- Inizio Test Dijkstra ---~n'),
    delete_graph(G),
    new_graph(G),
    
    % Creazione Vertici
    maplist(new_vertex(G), [n1, n2, n3, n4, n5]),
    
    % Creazione Archi
    % Percorso 1: n1 -> n3 (costo 10)
    new_arc(G, n1, n3, 10),
    % Percorso 2: n1 -> n2 -> n3 (costo 2 + 3 = 5) - IL MIGLIORE
    new_arc(G, n1, n2, 2),
    new_arc(G, n2, n3, 3),
    % Proseguimento: n3 -> n4 (costo 1) -> totale per n4 = 6
    new_arc(G, n3, n4, 1),
    % n5 resta isolato
    
    % Esecuzione Algoritmo
    format('Eseguo Dijkstra da n1...~n'),
    dijkstra_sssp(G, n1),
    
    % Verifica Distanze
    distance(G, n3, D3),
    distance(G, n4, D4),
    distance(G, n5, D5),
    
    format('Distanza n1 -> n3: ~w (Atteso: 5)~n', [D3]),
    format('Distanza n1 -> n4: ~w (Atteso: 6)~n', [D4]),
    format('Distanza n1 -> n5: ~w (Atteso: inf)~n', [D5]),
    
    % Verifica Cammino
    format('~nRecupero cammino minimo n1 -> n4:~n'),
    (shortest_path(G, n1, n4, Path) -> 
        format('Cammino trovato: ~w~n', [Path]) ; 
        format('Errore: Cammino non trovato!~n')),
    
    format('~n--- Test Completato ---~n').

%-----------------------------------------------------------------------%
% DICHIARAZIONI DINAMICHE                                               %
%-----------------------------------------------------------------------%
% Per aggiornare la base dati durante l'esecuzione
:- dynamic graph/1.
:- dynamic vertex/2.
:- dynamic arc/4.

:- dynamic distance/3.
:- dynamic previous/3.
:- dynamic visited/2.

:- dynamic heap/2.
:- dynamic heap_entry/4.

%-----------------------------------------------------------------------%
% INTERFACCIA GRAFI                                                     %
%-----------------------------------------------------------------------%

new_graph(G) :-
    graph(G),
    !.

new_graph(G) :-
    assert(graph(G)),
    !.

delete_graph(G) :-
    retractall(graph(G)),
    retractall(vertex(G, _)),
    retractall(arc(G, _, _, _)),
    retractall(distance(G, _, _)),
    retractall(previous(G, _, _)),
    retractall(visited(G, _)),
    !.

new_vertex(G, V) :-
    graph(G),
    vertex(G, V),
    !.

new_vertex(G, V) :-
    graph(G),
    assert(vertex(G, V)),
    !.

vertices(G, Vs) :-
    graph(G),
    findall(V, vertex(G, V), Vs),
    !.

list_vertices(G) :-
    graph(G),
    listing(vertex(G, _)),
    !.

list_arcs(G) :-
    graph(G),
    listing(arc(G, _, _, _)),
    !.

list_graph(G) :-
    graph(G),
    list_vertices(G),
    list_arcs(G),
    !.

new_arc(G, U, V) :-
    new_arc(G, U, V, 1).

new_arc(G, U, V, Weight) :-
    graph(G),
    vertex(G, U),
    vertex(G, V),
    Weight >= 0,
    arc(G, U, V, Weight),
    !.

new_arc(G, U, V, Weight) :-
    graph(G),
    vertex(G, U),
    vertex(G, V),
    Weight >= 0,
    retractall(arc(G, U, V, _)),
    assert(arc(G, U, V, Weight)),
    !.

arcs(G, Es) :-
    graph(G),
    findall(arc(G, U, V, Weight), arc(G, U, V, Weight), Es),
    !.

neighbors(G, V, Ns) :-
    graph(G),
    vertex(G, V),
    findall(arc(G, V, N, Weight), arc(G, V, N, Weight), Ns),
    !.

%-----------------------------------------------------------------------%
% SSSP - DIJKSTRA                                                       %
%-----------------------------------------------------------------------%

change_distance(G, V, NewDist) :-
    graph(G),
    vertex(G, V),
    retractall(distance(G, V, _)),
    assert(distance(G, V, NewDist)),
    !.

change_previous(G, V, U) :-
    graph(G),
    vertex(G, V),
    vertex(G, U),
    retractall(previous(G, V, _)),
    assert(previous(G, V, U)),
    !.

%%++%%
reset_distance(G) :-
    retractall(distance(G, _, _)),
    !.

%%++%%
reset_previous(G) :-
    retractall(previous(G, _, _)),
    !.

%%++%%
reset_visited(G) :-
    retractall(visited(G, _)),
    !.

dijkstra_sssp(G, Source) :-
    graph(G),
    vertex(G, Source),
    reset_distance(G),
    reset_previous(G),
    reset_visited(G),
    new_heap(heap),
    initialize_graph(G, Source),
    main_loop(G),
    delete_heap(heap),
    !.

%%++%%
initialize_graph(G, Source) :-
    vertices(G, Vs),
    initialize_nodes(G, Vs, Source),
    !.

%%++%%
initialize_nodes(_, [], _) :-
    !.

initialize_nodes(G, [V | Vs], Source) :-
    V == Source,
    change_distance(G, V, 0),
    insert(heap, 0, V),
    initialize_nodes(G, Vs, Source),
    !.

initialize_nodes(G, [V | Vs], Source) :-
    V \== Source,
    change_distance(G, V, inf),
    insert(heap, inf, V),
    initialize_nodes(G, Vs, Source),
    !.

%%++%%
main_loop(G) :-
    empty(heap),
    !.

main_loop(G) :-
    not_empty(heap),
    extract(heap, DistZ, Z),
    DistZ \== inf,
    assert(visited(G, Z)),
    neighbors(G, Z, Arcs),
    relax_edges(G, Z, DistZ, Arcs),
    main_loop(G),
    !.

main_loop(_).

%%++%%
relax_edges(_, _, _, []) :-
    !.

relax_edges(G, Z, DistZ, [arc(G, Z, V, Weight) | Rest]) :-
    distance(G, V, DistV),
    NewDist is DistZ + Weight,
    NewDist < DistV,                 %Percorso migliore trovato
    change_distance(G, V, NewDist),
    change_previous(G, V, Z),
    modify_key(heap, NewDist, DistV, V),
    relax_edges(G, Z, DistZ, Rest),
    !.

relax_edges(G, Z, DistZ, [_ | Rest]) :-
    relax_edges(G, Z, DistZ, Rest).

shortest_path(G, Source, V, Path) :-
    graph(G),
    vertex(G, Source),
    vertex(G, V),
    build_path(G, Source, V, [V], Nodes),
    nodes_to_arcs(G, Nodes, Path),
    !.

%%++%%
build_path(_, Source, Source, Acc, Acc) :-
    !.

build_path(G, Source, V, Acc, Nodes) :-
    previous(G, V, U),
    build_path(G, Source, U, [U | Acc], Nodes).

%%++%%
nodes_to_arcs(_, [_], []) :-
    !.

nodes_to_arcs(G, [U, V | Rest], [arc(G, U, V, W) | Arcs]) :-
    arc(G, U, V, W),
    nodes_to_arcs(G, [V | Rest], Arcs).

%-----------------------------------------------------------------------%
% MIN-PRIORITY QUEUE (MIN-HEAP)                                         %
%-----------------------------------------------------------------------%

new_heap(H) :-
    heap(H, _),
    !.

new_heap(H) :-
    assert(heap(H, 0)),
    !.

delete_heap(H) :-
    retractall(heap(H, _)),
    retractall(heap_entry(H, _, _, _)),
    !.

list_heap(H) :-
    heap(H, _),
    listing(heap(H, _)),
    listing(heap_entry(H, _, _, _)),
    !.

heap_size(H, Size) :-
    heap(H, Size),
    !.

empty(H) :-
    heap(H, 0),
    !.

not_empty(H) :-
    heap(H, Size),
    Size > 0,
    !.

modify_key(H, NewKey, OldKey, Value) :-
    heap_entry(H, P, OldKey, Value),
    retract(heap_entry(H, P, OldKey, Value)),
    assert(heap_entry(H, P, NewKey, Value)),
    reorder_node(H, P, NewKey, OldKey),
    !.

%%++%%
reorder_node(H, P, NewKey, OldKey) :-
    NewKey < OldKey,
    swim(H, P),
    !.

reorder_node(H, P, NewKey, OldKey) :-
    NewKey > OldKey,
    sink(H, P),
    !.

reorder_node(_, _, _, _).

head(H, Key, Value) :-
    not_empty(H),
    heap_entry(H, 1, Key, Value),
    !.

insert(H, Key, Value) :-
    heap(H, Size),
    NewSize is Size + 1,
    retract(heap(H, Size)),
    assert(heap(H, NewSize)),
    assert(heap_entry(H, NewSize, Key, Value)),
    swim(H, NewSize),
    !.

%%++%%
swim(_, 1) :-
    !.

swim(H, P) :-
    P > 1,
    father(F, P),
    heap_entry(H, P, KP, _),
    heap_entry(H, F, KF, _),
    KP >= KF,
    !.

swim(H, P) :-          
    P > 1,
    father(F, P),
    heap_entry(H, P, KP, _),
    heap_entry(H, F, KF, _),
    KP < KF,
    swap(H, P, F),
    swim(H, F).

extract(H, Key, Value) :-
    heap(H, Size),
    Size > 0,
    heap_entry(H, 1, Key, Value),
    retract(heap_entry(H, 1, Key, Value)),
    NewSize is Size - 1,
    retract(heap(H, Size)),
    assert(heap(H, NewSize)),
    handle_rest(H, NewSize, Size),
    !.

%%++%%
handle_rest(_, 0, _) :-
    !.

handle_rest(H, NewSize, OldSize) :-
    NewSize > 0,
    heap_entry(H, OldSize, KeyLast, ValueLast),
    retract(heap_entry(H, OldSize, KeyLast, ValueLast)),
    assert(heap_entry(H, 1, KeyLast, ValueLast)),
    sink(H, 1).

%%++%%
sink(H, P) :-
    left_child(P, L),
    heap(H, Size),
    L =< Size,
    select_min_child(H, P, Size, MinChild),
    heap_entry(H, P, KeyP, _),
    heap_entry(H, MinChild, KeyMC, _),
    KeyP > KeyMC,
    swap(H, P, MinChild),
    sink(H, MinChild),
    !.

sink(_, _).

%%++%%
select_min_child(H, P, S, R) :-
    right_child(P, R),
    R =< S,
    heap_entry(H, R, KeyR, _),
    left_child(P, L),
    heap_entry(H, L, KeyL, _),
    KeyR < KeyL,
    !.

select_min_child(_, P, _, L) :-
    left_child(P, L).

%%++%%
swap(H, E1, E2) :-
    heap_entry(H, E1, K1, V1),
    heap_entry(H, E2, K2, V2),
    retract(heap_entry(H, E1, K1, V1)),
    retract(heap_entry(H, E2, K2, V2)),
    assert(heap_entry(H, E1, K2, V2)),
    assert(heap_entry(H, E2, K1, V1)).

%%++%%
left_child(P, L) :-
    L is 2 * P.

%%++%%
right_child(P, R) :-
    R is 2 * P + 1.

%%++%%
father(P, C) :-
    P is C // 2.
	
	
	
	
	
	
	
	
	
	
	
	
	
