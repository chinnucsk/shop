%%%-------------------------------------------------------------------
%%% @author Russell Brown <russell@ossme.net>
%%% @copyright (C) 2010, Russell Brown
%%% @doc
%%% gen_server for authenticator, requires a auth module to be set
%%% @end
%%% Created : 24 Jul 2010 by Russell Brown <russell@ossme.net>
%%%-------------------------------------------------------------------
-module(store_authenticator).

-behaviour(gen_server).

%% API
-export([start_link/1, stop/0, authenticate/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 

-include("store.hrl").

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link(Env) -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link(Env) ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, Env, []).


%%--------------------------------------------------------------------
%% @doc stops the server
%% @spec stop() -> 
%% @end
%%--------------------------------------------------------------------
stop() ->
    gen_server:cast(?SERVER, stop).

%%--------------------------------------------------------------------
%% @doc authenticates the credentials passed against the configured scheme
%% @spec authenticate(Username::string(), Password::string()) -> {ok, User::user()} | fail | locked | admin_locked
%% @end
%%--------------------------------------------------------------------
authenticate(Username, Password) when is_list(Username), is_list(Password) ->
    gen_server:call(?SERVER, {authenticate, Username, Password}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init(Env) ->
    Authenticator = proplists:get_value(auth_module, Env),
    true = is_valid(Authenticator:module_info(exports)),
    {ok, {auth, Authenticator}}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call({authenticate, Username, Password}, _From, {auth, Auth}=State) ->
    Res = Auth:authenticate(Username, Password),
    {reply, Res, State};
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(stop, State) ->
    {stop, normal, State};
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc Checks that the passed module exports the required functions
%% @spec is_valid([export()]) -> true | false
%% @end
%%--------------------------------------------------------------------
is_valid([]) ->
    exit(bad_mod);
is_valid(Exports) ->
    lists:all( fun(X) -> lists:member(X, Exports) end, store_authenticator_behaviour:behaviour_info(callbacks)).
