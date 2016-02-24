%%%----------------------------------------------------------------------
%%% @author : zhongbinbin <binbinjnu@163.com>
%%% @date   : 2016.02.23
%%% @desc   : 打包并发送
%%%----------------------------------------------------------------------

-module(game_pack_send).

-include("common.hrl").
-include("record.hrl").
-include("tpl_map.hrl").

-export([send_to_self/2
        ,send_to_self/3
        ,send_to_one/3
        ,nodelay_send_to_one/2
        ,nodelay_send_to_one/3
        ,send_to_users/3
        ,nodelay_send_to_users/3
        ,send_to_all/2
        ,cross_send_to_all/2
        ,send_to_map_all/3
        ,map_send_to_all/3
        ,send_to_map_area/5
        ,map_send_to_area/5
    ]).

%% @doc 玩家进程内发送消息给自己socket，尽量带上#user{}调用send_to_self/3
send_to_self(#user{} = User, Cmd, Data) ->
    {ok, Bin} = pack(1, Cmd, Data),
    user_send:delay_send(User, Bin).
send_to_self(Cmd, Data) ->  %% 如果没有带上#user{},给自己进程发消息获取#user{}
    {ok, Bin} = pack(1, Cmd, Data),
    srv_user:cast_state_apply(self(), {user_send, delay_send, [Bin]}).


%% @doc 给某个玩家发送消息
%% 如果是当前节点，可以使用user_id，如果不确定节点，只能使用user_pid
send_to_one(UserX, Bin) ->
    srv_user:cast_state_apply(UserX, {user_send, send_to_self, [Bin]}).
send_to_one(UserX, Cmd, Data) ->
    {ok, Bin} = pack(1, Cmd, Data),
    send_to_one(UserX, Bin).


%% @doc 给玩家直接发消息(地图等)
%% 如果是当前节点，可以使用user_id，如果不确定节点，只能使用user_pid
nodelay_send_to_one(UserX, Bin) ->
    srv_user:cast_state_apply(UserX, {user_send, nodelay_send, [Bin]}).
nodelay_send_to_one(UserX, Cmd, Data) ->
    {ok, Bin} = pack(1, Cmd, Data),
    nodelay_send_to_one(UserX, Bin).


%% @doc 发送给多个玩家
%% 如果是当前节点，可以使用user_id，如果不确定节点，只能使用user_pid
send_to_users(UserXList, Cmd, Data) ->
    {ok, Bin} = pack(length(UserXList), Cmd, Data),
    [send_to_one(UserX, Bin) || UserX <- UserXList].

%% @doc 给多个玩家直接发消息，一般用于地图中
nodelay_send_to_users(UserXList, Cmd, Data) ->
    {ok, Bin} = pack(length(UserXList), Cmd, Data),
    [nodelay_send_to_one(UserX, Bin) || UserX <- UserXList].


%% @doc 队伍广播
%% @doc 公会广播


%% @doc 当前节点给所有人发消息
send_to_all(Cmd, Data) ->
    {ok, Bin} = pack(2, Cmd, Data), %% 默认广播至少2个人
    L = ets:tab2list(?ETS_USER_ONLINE),
    [send_to_one(Pid, Bin) || #user_online{pid = Pid} <- L].

%% @doc 在跨服节点给所有节点广播
cross_send_to_all(Cmd, Data) ->
    %% TODO 获取所有连接节点
    NodeList = [],  
    [rpc:cast(Node, ?MODULE, send_to_all, [Cmd, Data]) || Node <- NodeList].


%% @doc 非地图进程发消息给所有人
send_to_map_all(MapPid, Cmd, Data) ->
    srv_map:cast_state_apply(MapPid, {?MODULE, map_send_to_all, [Cmd, Data]}).

%% @doc 在地图进程中发送消息给所有人
map_send_to_all(#map{map_id = MapID, user_dict = UserDict}, Cmd, Data) ->
    Size = dict:size(UserDict),
    {ok, Bin} = pack(Size, Cmd, Data),
    case data_map:get(MapID) of
        #tpl_map{map_cross_type = 0} -> %% 非跨服地图
            [nodelay_send_to_one(E, Bin) || #map_user{user_pid = E} <- dict:to_list(UserDict)];
        _ ->        %% TODO 跨服地图，看是否需要把不同节点的玩家区分出来，先发送到对应节点在
            [nodelay_send_to_one(E, Bin) || #map_user{user_pid = E} <- dict:to_list(UserDict)]
    end.


%% @doc 非地图进程发消息给某个区域内的人
send_to_map_area(MapPid, X, Y, Cmd, Data) ->
    srv_map:cast_state_apply(MapPid, {?MODULE, map_send_to_area, [X, Y, Cmd, Data]}).

%% @doc 在地图进程中发送消息给某个区域的人
map_send_to_area(#map{map_id = MapID, aoi = Aoi}, X, Y, Cmd, Data) ->
    %% 根据x,y获取区域内9宫格
    GridList = map_aoi:get_grids(X, Y),
    AoiObjList = map_aoi:get_grids_object(Aoi, GridList, ?AOI_OBJ_TYPE_USER),
    Len = length(AoiObjList),
    {ok, Bin} = pack(Len, Cmd, Data),
    case data_map:get(MapID) of
        #tpl_map{map_cross_type = 0} -> %% 非跨服地图
            [nodelay_send_to_one(E, Bin) || #aoi_obj{pid = E} <- AoiObjList];
        _ ->        %% TODO 跨服地图，看是否需要把不同节点的玩家区分出来，先发送到对应节点在
            [nodelay_send_to_one(E, Bin) || #aoi_obj{pid = E} <- AoiObjList]
    end.


%% @doc TODO 地图中阵营广播(涉及到地图的阵营)

%% @doc 打包
%% @return {ok, IoList}|any
%% TODO binary在进程之间共享内存，如果该信息是要发给多个玩家的，最好把iolist转成binary
pack(0, _Cmd, _Data) ->   %% 没有需要发送的对象，不进行打包
    {ok, <<>>};
pack(N, Cmd, Data) ->
    case game_protobuf:encode_package(Cmd, Data) of
        {ok, IoList} when N == 1 ->  
            {ok, IoList};
        {ok, IoList} ->
            {ok, erlang:iolist_to_binary(IoList)};
        R ->
            R   
    end.


