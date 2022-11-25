https://powcoder.com
代写代考加微信 powcoder
Assignment Project Exam Help
Add WeChat powcoder
%% coding: utf-8
-module(test_routers).

-export([main/1]).

-record(options, {topology  = hypercube  :: 'line' | 'ring' | 'star'
                                          | 'fully_connected' | 'hypercube'
                                          | 'butterfly' | 'butterfly_wrap'
                                          | 'torus' | 'tree',
                  dimension = 3          :: non_neg_integer(),
                  size      = 20         :: pos_integer(),
                  depth     = 3          :: non_neg_integer(),
                  children  = 3          :: pos_integer(),
                  warmup    = 100        :: non_neg_integer(),
                  test_mode = one_to_all :: 'one_to_all' | 'all_to_one'}).


%% escript entry point

-spec main([string]) -> no_return().
main(Args) ->
    io:setopts([{encoding, unicode}]),
    Opts = parse_args(Args, #options{}),
    Topology = case Opts#options.topology of
                   line ->
                       {Opts#options.topology, Opts#options.size};
                   ring ->
                       {Opts#options.topology, Opts#options.size};
                   star ->
                       {Opts#options.topology, Opts#options.size};
                   fully_connected ->
                       {Opts#options.topology, Opts#options.size};
                   hypercube ->
                       {Opts#options.topology, Opts#options.dimension};
                   butterfly ->
                       {Opts#options.topology, Opts#options.dimension};
                   butterfly_wrap ->
                       {Opts#options.topology, Opts#options.dimension};
                   torus ->
                       {Opts#options.topology,
                        Opts#options.dimension,
                        Opts#options.size};
                   tree ->
                       {Opts#options.topology,
                        Opts#options.depth,
                        Opts#options.children}
               end,
    Routers = routers_framework:start(Topology),
    receive
    after Opts#options.warmup ->
        Router1 = lists:nth(rand:uniform(length(Routers)), Routers),
        F = fun(Router) ->
                {A, B} = case Opts#options.test_mode of
                             one_to_all ->
                                 {Router1, Router};
                             all_to_one ->
                                 {Router, Router1}
                         end,
                Tag = {'$gen_request_id', make_ref()},
                A ! {'$gen_call', {self(), Tag}, {test, B}},
                Tag
            end,
        {Time, ok} = timer:tc(fun await/1,
                              [sets:from_list([F(Router) || Router <- Routers])]),
        io:format("Test completed in ~p μs.~n", [Time]),
        erlang:halt(0)
    end.

%% internal functions

-spec parse_args([string], #options{}) -> #options{}.
parse_args([], Opts) ->
    Opts;
%parse_args(["-h" | _], _Opts) ->
%    io:format("TODO Help Message", []),
%    erlang:halt(0);
parse_args(["-t", Arg | Rest], Opts) ->
    case Arg of
        "Line" ->
            parse_args(Rest, Opts#options{topology = line});
        "Ring" ->
            parse_args(Rest, Opts#options{topology = ring});
        "Star" ->
            parse_args(Rest, Opts#options{topology = star});
        "Fully_Connected" ->
            parse_args(Rest, Opts#options{topology = fully_connected});
        "Hypercube" ->
            parse_args(Rest, Opts#options{topology = hypercube});
        "Butterfly" ->
            parse_args(Rest, Opts#options{topology = butterfly});
        "Wrap_Around_Butterfly" ->
            parse_args(Rest, Opts#options{topology = butterfly_wrap});
        "Torus" ->
            parse_args(Rest, Opts#options{topology = torus});
        "Tree" ->
            parse_args(Rest, Opts#options{topology = tree});
        _ ->
            io:format("Unrecognised topology ~p.~n", [Arg]),
            erlang:halt(1)
    end;
parse_args(["-s", Arg | Rest], Opts) ->
    case string:to_integer(Arg) of
        {Size, ""} when Size > 0 ->
            parse_args(Rest, Opts#options{size = Size});
        _ ->
            io:format("Invalid size ~p.~n", [Arg]),
            erlang:halt(1)
    end;
parse_args(["-d", Arg | Rest], Opts) ->
    case string:to_integer(Arg) of
        {Dimension, ""} when Dimension >= 0 ->
            parse_args(Rest, Opts#options{dimension = Dimension});
        _ ->
            io:format("Invalid dimension ~p.~n", [Arg]),
            erlang:halt(1)
    end;
parse_args(["-g", Arg | Rest], Opts) ->
    case string:to_integer(Arg) of
        {Children, ""} when Children > 0 ->
            parse_args(Rest, Opts#options{children = Children});
        _ ->
            io:format("Invalid child count ~p.~n", [Arg]),
            erlang:halt(1)
    end;
parse_args(["-p", Arg | Rest], Opts) ->
    case string:to_integer(Arg) of
        {Depth, ""} when Depth >= 0 ->
            parse_args(Rest, Opts#options{depth = Depth});
        _ ->
            io:format("Invalid depth ~p.~n", [Arg]),
            erlang:halt(1)
    end;
parse_args(["-w", Arg | Rest], Opts) ->
    case string:to_float(Arg) of
        {Warmup, ""} when Warmup >= 0 ->
            parse_args(Rest, Opts#options{warmup = round(1000 * Warmup)});
        _ ->
            io:format("Invalid depth ~p.~n", [Arg]),
            erlang:halt(1)
    end;
parse_args(["-m", Arg | Rest], Opts) ->
    case Arg of
        "One_to_All" ->
            parse_args(Rest, Opts#options{test_mode = one_to_all});
        "All_to_One" ->
            parse_args(Rest, Opts#options{test_mode = all_to_one});
        _ ->
          io:format("Invalid test mode ~p.~n", [Arg]),
          erlang:halt(1)
    end;
parse_args([Arg | _], _Opts) ->
    io:format("Unrecognised argument ~p.~n", [Arg]),
    erlang:halt(1).

-spec await(sets:set(pid())) -> 'ok'.
await(Refs) ->
    case sets:is_empty(Refs) of
        true ->
            ok;
        false ->
            ok,
            receive
                {Ref, {ok, _Hops}} ->
                    case sets:is_element(Ref, Refs) of
                        true ->
                            await(sets:del_element(Ref, Refs));
                        false ->
                            io:format("FIXME: received an unexpected ref ~p~n",
                                      [Ref]),
                            await(Refs)
                    end
            end
    end.
