https://powcoder.com
代写代考加微信 powcoder
Assignment Project Exam Help
Add WeChat powcoder
-module(routers_framework).

-export([start/1]).

-include("include/routers.hrl").

-spec start(topology()) -> [pid()].
start(Topology) ->
    Routers = case Topology of
                  {line, N} when is_integer(N), N > 0 ->
                      line(N);
                  {ring, N} when is_integer(N), N > 0 ->
                      torus(1, N);
                  {star, N} when is_integer(N), N > 0 ->
                      star(N);
                  {fully_connected, N} when is_integer(N), N > 0 ->
                      fully_connected(N);
                  {hypercube, Dim} when is_integer(Dim), Dim >= 0 ->
                      % This should really be torus(N, 2), but that has bugs rn
                      %torus(Dim, 2);
                      hypercube(Dim);
                  {tree, Depth, Children} when is_integer(Depth),
                                               is_integer(Children),
                                               Depth >= 0, Children > 0 ->
                      tree(Depth, Children);
                  {torus, Dim, N} when is_integer(Dim), is_integer(N),
                                       Dim >= 0, N > 0 ->
                      case N of
                          2 ->
                              hypercube(Dim);
                          _ ->
                              torus(Dim, N)
                      end;
                  {butterfly, Dim} when is_integer(Dim), Dim >= 0 ->
                      butterfly(Dim);
                  {butterfly_wrap, Dim} when is_integer(Dim), Dim >= 0 ->
                      butterfly_wrap(Dim)
              end,
    % DIRTY HACK for maximal concurrency
    Tag = {'$gen_request_id', make_ref()},
    [Router ! {'$gen_call',
               {self(), Tag},
               {neighbours, Neighbours}} || {Router, Neighbours} <- Routers],
    [receive {Tag, ok} -> Router end || {Router, _} <- Routers].

%% internal functions

line(1) ->
    singleton();
line(N) ->
    {ok, Pid} = router:start_link(),
    line(N - 1, [{Pid, []}]).

line(0, Routers) ->
    Routers;
line(N, [{Pid, Neighbours} | Rest]) ->
    {ok, Pid1} = router:start_link(),
    line(N - 1, [{Pid1, [Pid]}, {Pid, [Pid1 | Neighbours]} | Rest]).

%ring(1) ->
%    singleton();
%ring(N) ->
%    ring(N - 2, line(2)).
%
%ring(0, Routers) ->
%    Routers;
%ring(N, [{Pid2, [Neighbour2 | _]}, {Pid1, [Neighbour1 | _]} | Rest]) ->
%    {ok, Pid3} = router:start_link(),
%    ring(N - 1, [{Pid3, [Pid1, Pid2]},
%                 {Pid2, [Neighbour2, Pid3]},
%                 {Pid1, [Neighbour1, Pid3]} | Rest]).

star(N) ->
    {ok, Pid1} = router:start_link(),
    Rest = [Pid || {ok, Pid} <- [router:start_link() || _ <- lists:seq(2, N)]],
    [{Pid1, Rest} | [{Pid, [Pid1]} || Pid <- Rest]].

fully_connected(N) ->
    Routers = [Pid || {ok, Pid} <- [router:start_link() || _ <- lists:seq(1, N)]],
    [{Pid, Routers -- [Pid]} || Pid <- Routers].

tree(Depth, N_Children) ->
    tree(Depth, N_Children, []).

tree(0, _N_Children, Parents) ->
    {ok, Pid} = router:start_link(),
    [{Pid, Parents}];
tree(Depth, N_Children, Parents) ->
    {ok, Pid} = router:start_link(),
    Children = [tree(Depth - 1, N_Children, [Pid]) || _ <- lists:seq(1, N_Children)],
    [{Pid, Parents ++ [Pid_Child || [{Pid_Child, _} | _] <- Children]} | lists:append(Children)].

%mesh(0, _N) ->
%    singleton();
%mesh(Dim, N) ->
%    Rows = [mesh(Dim - 1, N) || _ <- lists:seq(1, N)],
%    [Head | Tail] = Rows,
%    lists:append(lists:zipwith3(fun(Pids, Neighbours1, Neighbours2) ->
%                                    lists:zipwith3(fun({Pid, Neighbours}, {Neighbour1, _}, {Neighbour2, _}) ->
%                                                       {Pid, [Neighbour1, Neighbour2 | Neighbours]}
%                                                   end, Pids, Neighbours1, Neighbours2)
%                                end, Rows, [[] | lists:droplast(Rows)], Tail ++ [[]])).

% Yes, this produces bugged tori with duplicate connections for N = 2.
% Use hypercube(Dim) if you want a size 2 torus. Or fix it, if you can.
torus(0, _N) ->
    singleton();
torus(Dim, N) ->
    Rows = [torus(Dim - 1, N) || _ <- lists:seq(1, N)],
    [Head | Tail] = Rows,
    lists:append(lists:zipwith3(fun(Pids, Neighbours1, Neighbours2) ->
                                    lists:zipwith3(fun({Pid, Neighbours}, {Neighbour1, _}, {Neighbour2, _}) ->
                                                       {Pid, [Neighbour1, Neighbour2 | Neighbours]}
                                                   end, Pids, Neighbours1, Neighbours2)
                                end, Rows, [lists:last(Rows) | lists:droplast(Rows)], Tail ++ [Head])).

hypercube(0) ->
    {ok, Pid} = router:start_link(),
    [{Pid, []}];
hypercube(N) ->
    F = fun({Pid1, Neigh1}, {Pid2, Neigh2}) ->
            [{Pid1, [Pid2 | Neigh1]}, {Pid2, [Pid1 | Neigh2]}]
        end,
    lists:append(lists:zipwith(F, hypercube(N - 1), hypercube(N - 1))).

butterfly(N) ->
    lists:append(butterfly(N, false)).

butterfly_wrap(N) ->
    lists:append(butterfly(N, true)).

butterfly(0, _) ->
    {ok, Pid} = router:start_link(),
    [[{Pid, []}]];
butterfly(N, Wrapped) ->
    [Y1 | Tail1] = butterfly(N - 1, false),
    [Y2 | Tail2] = butterfly(N - 1, false),
    {X1, X2} = case Wrapped of
                   true ->
                       {lists:last([Y1 | Tail1]), lists:last([Y2 | Tail2])};
                   false ->
                       L = lists:seq(1, 1 bsl (N - 1)),
                       F = fun(_) ->
                               {ok, Pid} = router:start_link(),
                               {Pid, []}
                           end,
                       {lists:map(F, L), lists:map(F, L)}
               end,
    J = fun({Pid1, Neigh1}, {Pid2, _Neigh2}) ->
            case Pid2 of
                Pid1 ->
                    {Pid1, Neigh1};
                _ ->
                    {Pid1, [Pid2 | Neigh1]}
            end
        end,
    Joins = fun({A, B, C}) ->
                lists:zipwith(J, case Wrapped of
                                     true when N =< 2 ->
                                         A;
                                     _ ->
                                         lists:zipwith(J, A, B)
                                 end, C)
            end,
    [NewX1, NewX2, NewY1, NewY2] = [Joins(P) || P <- [{X1, Y1, Y2},
                                                      {X2, Y2, Y1},
                                                      {Y1, X1, X2},
                                                      {Y2, X2, X1}]],
    case Wrapped of
        true ->
            lists:zipwith(fun lists:append/2,
                          lists:droplast([NewX1, NewY1 | Tail1]),
                          lists:droplast([NewX2, NewY2 | Tail2]));
        false ->
            lists:zipwith(fun lists:append/2,
                          [NewX1, NewY1 | Tail1],
                          [NewX2, NewY2 | Tail2])
    end.

singleton() ->
    {ok, Pid} = router:start_link(),
    [{Pid, []}].
