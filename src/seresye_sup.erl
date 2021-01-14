%%%-------------------------------------------------------------------
%%%  SERESYE, a Swarm oriented ERlang Expert SYstem Engine
%%%
%%% @copyright (C) 2005-2010, Francesca Gangemi, Corrado Santoro
%%% All rights reserved.
%%% Copyright (c) 2011, Afiniate, Inc.
%%% Updated by Miloud Eloumri, 18. Nov 2020 10:56 AM
%%% You may use this file under the terms of the BSD License. See the
%%% license distributed with this project or
%%% http://www.opensource.org/licenses/bsd-license.php
%%%
%%% @doc seresye top level supervisor
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(seresye_sup).
-author("Francesca Gangemi").
-author("Corrado Santoro").

-behaviour(supervisor).

%% API
-export([start_link/0, start_engine/0, start_engine/1, start_engine/2]).

%% Supervisor callbacks
-export([init/1]).
% -export([stop/0]).

-define(SERVER, ?MODULE).

%%%===================================================================
%%% API functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc Starts the supervisor.
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() -> {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
  supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%--------------------------------------------------------------------
%% @doc Stops the supervisor.
%%
%% @end
%%--------------------------------------------------------------------
% stop() ->
%  exit(whereis(?MODULE), shutdown).

%%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_engine() -> any()).
start_engine() ->
  supervisor:start_child(?SERVER, []).

%%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_engine(Name :: term()) -> any()).
start_engine(Name) ->
  supervisor:start_child(?SERVER, [Name]).

%%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_engine(Name :: term(), ClientState :: term()) -> any()).
start_engine(Name, ClientState) ->
  supervisor:start_child(?SERVER, [Name, ClientState]).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc Whenever a supervisor is started using supervisor:start_link/[2,3],
%% this function is called by the new process to find out about
%% restart strategy, maximum restart frequency and child
%% specifications.
%%
%% @end
%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
  {ok, {SupFlags :: {RestartStrategy :: supervisor:strategy(),
    MaxR :: non_neg_integer(), MaxT :: non_neg_integer()},
    [ChildSpec :: supervisor:child_spec()]}}
  | ignore | {error, Reason :: term()}).
init([]) ->
  % process_flag(trap_exit, true),

  % restart strategy types: one_for_one, one_for_all, rest_for_one, simple_one_for_one
  % restart strategy determines what happens to running children in the same supervision tree if one of them is crashed
  % one_for_all: all children are restarted (dependent children case)
  % one_for_one: only the crashed child is restarted (independent children case)
  % rest_for_one: children started after the crashed child are restarted (partial dependent children started in order)
  % simple_one_for_one: used with dynamic children (children of the same type added dynamically at runtime, not at startup)
  RestartStrategy = simple_one_for_one,
  % maximum number of restarts (intensity) all children are allowed to do in
  % MaxTime in seconds (period)
  MaxRestarts = 1000, % 1000 restarts are allowed in the period of 3600 seconds (1 hour)
  MaxSecondsBetweenRestarts = 3600, % 3600 seconds (1 hour)
  SupFlags = #{strategy => RestartStrategy, % simple_one_for_one
    intensity => MaxRestarts, % 1000
    period => MaxSecondsBetweenRestarts}, % 3600 seconds
  % child specifications list returned from the call to the internal function: child(seresye)
  ChildSpecs = [child(seresye)],
  {ok, {SupFlags, ChildSpecs}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Returns a child specifications map
%% which is saved in ChildSpecslist defined in init function.
%%
%% @end
%%--------------------------------------------------------------------
-spec(child(Module :: term()) -> map()).
child(Module) ->
  UniqueIdentifier = Module, % mandatory
  ChildStartFunctionAndLinkChildToSupervisor = {Module, start_link, []}, % mandatory - link, spawn and start the child - return {ok, Pid} in normal cases
  % child restart type: permanent, temporary, transient
  % child restart type: determines how the supervisor reacts to the terminated child
  % permanent: a child is always restarted regardless of normal exit or abnormal crash
  % temporary: a child is never restarted regardless of normal exit or abnormal crash
  % transient: a child is restarted only when it is terminated abnormally (crashed)
  ChildRestartType = transient,   % suitable for dynamic children (child worker life-cycle end)
  % a time in milliseconds, or the atom infinity or brutal_kill
  % the maximum time allowed to pass between the supervisor issuing the EXIT signal and
  % the terminate callback function returning (maximum time allowed to execute in the terminate function)
  % If the child takes longer time, the supervisor unconditionally terminates it.
  % terminate is called only if the child process is trapping exits.
  % infinity: a child takes all its time to terminate (not encouraged)
  % infinity is commonly used for children of type supervisor
  % brutal_kill: the supervisor kills a child unconditionally without executing the child terminate function
  MillisecondsToWaitForChildToShutDown = 2000,
  % worker or supervisor
  ChildType = worker,
  % the list of modules implementing the child behavior or the atom dynamic
  % dynamic is used when the modules  are unknown at compile time or what is running during a software upgrade
  CallbackModuleImplementingChild = [Module],
  #{id => UniqueIdentifier,
    start => ChildStartFunctionAndLinkChildToSupervisor,
    restart => ChildRestartType,
    shutdown => MillisecondsToWaitForChildToShutDown,
    type => ChildType,
    modules => CallbackModuleImplementingChild}.
