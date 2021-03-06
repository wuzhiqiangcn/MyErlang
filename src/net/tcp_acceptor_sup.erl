%%%----------------------------------------------------------------------
%%% @author : zhongbinbin
%%% @date   : 2015.6.18
%%% @desc   : acceptor supervisor
%%%----------------------------------------------------------------------

-module(tcp_acceptor_sup).
-behaviour(supervisor).

-export([start/1]).

-export([start_link/0
        ,init/1]).

-include("common.hrl").

start(Sup) ->
    ChildSpec =
        {tcp_acceptor_sup
            ,{tcp_acceptor_sup, start_link, []}
            ,transient
            ,infinity
            ,supervisor
            ,[tcp_acceptor_sup]},
    {ok, _} = supervisor:start_child(Sup, ChildSpec),
    ok.

start_link() ->
    supervisor:start_link({local,?MODULE}, ?MODULE, []).

init([]) ->
    ChildSpec = 
        {tcp_acceptor
         ,{tcp_acceptor, start_link, []}
         ,transient
         ,brutal_kill
         ,worker
         ,[tcp_acceptor]},
    {ok, {{simple_one_for_one, 10, 10}, [ChildSpec]}}.
