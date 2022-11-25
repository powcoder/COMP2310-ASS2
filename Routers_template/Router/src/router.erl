https://powcoder.com
代写代考加微信 powcoder
Assignment Project Exam Help
Add WeChat powcoder
-module(router).
-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2]).

-define(SERVER, ?MODULE).

% Add anything else you'd like to keep track of between calls to this record.
-record(state, {neighbours = [] :: [pid()], dv = maps:new()}).

-record(envelope, {dest     :: pid(),
                   hops = 0 :: non_neg_integer(),
                   message  :: term()}).

%% API

-spec start_link() -> {ok, pid()} | ignore | {error, term()}.
start_link() ->
    gen_server:start_link(?MODULE, [], []).

%% gen_server callbacks

init([]) ->
    {ok, #state{}}.

neis_to_dv(Neighbours) ->
    Lst = lists:map(fun(X) -> {X, {X,1}} end, Neighbours),
    maps:from_list(Lst).

merge_div(MyDiv, Nei, NeiDIV) ->
    case NeiDIV of
        [] -> [];

        [{Dest, {_NextHop, Cost}}| T] -> 
           {_Nh, CurCost} = maps:get(Dest, MyDiv, {Dest, 10000}),
           if Cost + 1 <  CurCost -> [{Dest, {Nei, Cost + 1}} | merge_div(MyDiv, Nei, T)];
                             true -> merge_div(MyDiv, Nei, T)
           end
    end.

merge_div_main(MyDiv, Nei, NeiDIVMap) ->
     NeiDIV = maps:to_list(NeiDIVMap),
     UpLst = merge_div(MyDiv, Nei, NeiDIV),
     UpMap = maps:from_list(UpLst),
     {UpLst == [], maps:merge(MyDiv,UpMap)}.

choose_next(_Neis, DV, Dest) ->
    % io:fwrite(io:format("~s\n", DV)),
    {Next, _Cost} = maps:get(Dest, DV, {Dest, 10000}),
    Next.


handle_call({neighbours, Neighbours}, From, State) ->
    DV = neis_to_dv(Neighbours),
    gen_server:reply(From, ok),
    % forwardAll(Neighbours, #envelope{dest = self(), hops = 0, message = {dv, self(), DV}}),
    {noreply, State#state{neighbours=Neighbours, dv=DV}};

handle_call({test, Dest}, From, State) ->
    Envelope = #envelope{dest = Dest, hops = 0, message = {test, From}},
    {reply, ok, State1} = handle_call(Envelope, From, State),
    {noreply, State1};
handle_call(E, _From, State) when is_record(E, envelope) ->
    Self = self(),
    case E#envelope.dest of
        Self ->
            case E#envelope.message of
                {test, From} ->
                    gen_server:reply(From, {ok, E#envelope.hops}),
                    {reply, ok, State};

                % Deal with other kinds of message by adding cases here
                {dv, From, DV} -> 

                    % {reply, ok, State}
                    gen_server:reply(From, {ok, E#envelope.hops}),

                    {Changed, NewDV} = merge_div_main(State#state.dv, From, DV),
                    if Changed -> 
                         Envelope = #envelope{dest = From , message = {dv, Self, NewDV}},
                         forwardAll(State#state.neighbours, Envelope),
                         
                         {noreply, State#state{dv = NewDV}};

                         % {reply, ok, State#state{dv = NewDV}};

                       true -> 
                          {noreply, State#state{dv = NewDV}}
                          % {reply, ok, State}

                     % {noreply, State}
                    end



            end;
        Dest ->
            % Deal with forwarding a message to another node here
            Next = choose_next(State#state.neighbours, State#state.dv, Dest),
            forward(Next, E),
            {reply, ok, State}
    end.

forwardAll(Neis, Envelope) ->
    case Neis of
        [] -> ok;

        [F|T] -> 
           forward(F, Envelope#envelope{dest = F}),  
           forwardAll(T, Envelope)
    end.


% You can ignore this - "casts" are gen_server's asynchronous calls.
% For this assignment, passing messages between different routers with
% asynchronous casts is cheating - stick to synchronous calls (when you're
% communicating between routers, that is. For worker tasks or similar that you
% create, go nuts.)
handle_cast(_Request, State) ->
    {noreply, State}.

%% internal functions

-spec forward(pid(), #envelope{}) -> term().
forward(Next, Envelope) ->
    gen_server:call(Next, Envelope#envelope{hops = Envelope#envelope.hops + 1}).

