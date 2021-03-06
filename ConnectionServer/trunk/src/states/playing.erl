-module(playing).

-include("protocol.hrl").
-include("state.hrl").
-include("charinfo.hrl").
-include("vec.hrl").

% States
-export([
    event/2
    ]).

event(tcp_closed, State) ->
    CharInfo = State#state.charinfo,
    % For now we logout the player if the connection is lost. Should
    % be changed to persist in case of reconnect.
	%CharInfo#charinfo.pid ! {execute, {from, self()}, {call, logout}, 
    %    {args, []}},
    %Pid = CharInfo#charinfo.pid, 
    %rpc:call(node(Pid), obj, async_call, [Pid, logout]),
    obj_call(CharInfo#charinfo.pid, logout),
    {noreply, playing, State};

event({terrain, Terrain}, State) ->
    %error_logger:info_report([{sending, ?TERRAIN, Terrain}]),
    TerrainBin = list_to_binary(Terrain),
    Len = byte_size(TerrainBin),
    {reply, <<?TERRAIN, Len, TerrainBin/binary>>, playing, State};

event({skybox, SkyBox}, State) ->
    SkyBoxBin = list_to_binary(SkyBox),
    Len = byte_size(SkyBoxBin),
    %Reply = <<?SKYBOX, Len, SkyBoxBin/binary>>,
    %error_logger:info_report([{sending, ?SKYBOX, SkyBox, 
    %    byte_size(Reply)}]),
    {reply, <<?SKYBOX, Len, SkyBoxBin/binary>>, playing, State};

event({new_pos, [Id, #vec{x=X, y=Y, z=Z}]}, State) ->
    IdLen = byte_size(Id),
    Reply = <<?NEW_POS, IdLen, Id/binary, 
        X/little-float, Y/little-float, Z/little-float>>,
    {reply, Reply, playing, State};

event({msg, Msg}, State) ->
    %error_logger:info_report([{sending, ?MSG, Msg}]),
    MsgBin = list_to_binary(Msg),
    Len = byte_size(MsgBin),
    {reply, <<?MSG, Len, MsgBin/binary>>, playing, State};

event({mesh, [Id, Mesh]}, State) ->
    IdLen = byte_size(Id),
    MeshBin = list_to_binary(Mesh),
    MeshLen = byte_size(MeshBin),
    %error_logger:info_report([{connsrv, playing, mesh, ?MESH, IdLen, Id, 
    %    MeshLen, MeshBin}]),
    {reply, <<?MESH, IdLen:8/little-integer, Id/binary, 
        MeshLen:8/little-integer, MeshBin/binary>>, playing, State};

event({billboard, [Id, Billboard]}, State) ->
    IdLen = byte_size(Id),
    BillboardBin = list_to_binary(Billboard),
    BillboardLen = byte_size(BillboardBin),
    %error_logger:info_report([{billboard, ?BILLBOARD, IdLen, Id, 
    %    BillboardLen, BillboardBin}]),
    {reply, <<?BILLBOARD, IdLen, Id/binary, BillboardLen, 
        BillboardBin/binary>>, playing, State};

event({scale, [Id, Scale]}, State) ->
    IdLen = byte_size(Id),
    %error_logger:info_report([{scale, ?SCALE, IdLen, Id, Scale}]),
    {reply, <<?SCALE, IdLen, Id/binary, Scale/little-float>>, playing, 
        State};

event({ambient_light, Value}, State) ->
    {reply, <<?AMBIENT_LIGHT, Value/little-float>>, playing, 
        State};

event({obj_pos, {id, Id}, {pos, #vec{x=X, y=Y, z=Z}}}, State) ->
    IdLen = byte_size(Id),
    %error_logger:info_report([{obj_dir, ?OBJ_DIR, IdLen, Id, X, Y, Z}]),
    {reply, <<?OBJ_POS, IdLen, Id/binary, X/little-float,
        Y/little-float, Z/little-float>>, playing, State};

event({obj_dir, {id, Id}, {dir, #vec{x=X, y=Y, z=Z}}}, State) ->
    IdLen = byte_size(Id),
    %error_logger:info_report([{obj_dir, ?OBJ_DIR, IdLen, Id, X, Y, Z}]),
    {reply, <<?OBJ_DIR, IdLen, Id/binary, X/little-float,
        Y/little-float, Z/little-float>>, playing, State};

event({obj_created, {id, Id}}, State) ->
    IdLen = byte_size(Id),
    error_logger:info_report([{obj_created, Id}]),
    {reply, <<?OBJ_CREATED, IdLen, Id/binary>>, 
        playing, State};

event({obj_leave, {id, Id}}, State) ->
    IdLen = byte_size(Id),
    {reply, <<?OBJ_LEAVE, IdLen, Id/binary>>, playing, State};

event({obj_enter, {id, Id}}, State) ->
    IdLen = byte_size(Id),
    {reply, <<?OBJ_ENTER, IdLen, Id/binary>>, playing, State};

event({obj_speed, {id, Id}, {speed, Speed}}, State) ->
    IdLen = byte_size(Id),
    {reply, <<?OBJ_SPEED, IdLen, Id/binary, Speed/little-float>>, 
        playing, State};

event({obj_anim, {id, Id}, {anim, Anim}, {repeat, Nr}}, State) ->
    IdLen = byte_size(Id),
    AnimBin = list_to_binary(Anim),
    AnimLen = byte_size(AnimBin),
    {reply, <<?OBJ_ANIM, IdLen, Id/binary, AnimLen, AnimBin/binary,
        Nr>>, playing, State};

event({obj_stop_anim, {id, Id}, {anim, Anim}}, State) ->
    IdLen = byte_size(Id),
    AnimBin = list_to_binary(Anim),
    AnimLen = byte_size(AnimBin),
    {reply, <<?OBJ_STOP_ANIM, IdLen, Id/binary, AnimLen, AnimBin/binary>>, 
        playing, State};

event({notify_name, {id, Id}, {name, Name}}, State) ->
    IdLen = byte_size(Id),
    %NameBin = list_to_binary(Name),
    %NameLen = byte_size(NameBin),
    NameLen = byte_size(Name),
    {reply, <<?NOTIFY_NAME, IdLen, Id/binary, NameLen, Name/binary>>, 
        playing, State};

event({{notify_flying, flying}, {id, Id}}, State) ->
    IdLen = byte_size(Id),
    {reply, <<?NOTIFY_FLYING, 1, IdLen, Id/binary>>, playing, State};

event({{notify_flying, not_flying}, {id, Id}}, State) ->
    IdLen = byte_size(Id),
    {reply, <<?NOTIFY_FLYING, 0, IdLen, Id/binary>>, playing, State};

event(enable_god_tool, State) ->
    {reply, <<?NOTIFY_ENABLE_GOD_TOOL>>, playing, State};

event(<<?MOVE_OBJ, IdLen/integer, Id:IdLen/binary, 
    X/little-float, Y/little-float, Z/little-float>>, State) ->
    error_logger:info_report([{move_obj, Id, X, Y, Z}]),
    CharInfo = State#state.charinfo,
	CharInfo#charinfo.pid ! {move_obj, [Id, {X, Y, Z}]},
    {noreply, playing, State};

event(<<?MOVE, X/little-float, _Y/little-float, Z/little-float>>, State) ->
    CharInfo = State#state.charinfo,
    Pid = CharInfo#charinfo.pid,
	rpc:call(node(Pid), obj, async_call, [Pid, set_dir, 
        [#vec{x=X, y=0, z=Z}]]),
    {noreply, playing, State};

event(<<?SET_FLY_DIR, X/little-float, Y/little-float, Z/little-float>>, 
    State) ->
    CharInfo = State#state.charinfo,
    Pid = CharInfo#charinfo.pid,
    error_logger:info_report([{fly_move, X, Y, Z}]),
	rpc:call(node(Pid), obj, async_call, [Pid, set_fly_dir, 
        [#vec{x=X, y=Y, z=Z}]]),
    {noreply, playing, State};

%event(<<?MOVE, Rest/binary>>, State) ->
%    CharInfo = State#state.charinfo,
%    error_logger:info_report([{move, Rest}]),
%	%CharInfo#charinfo.pid ! {move, [{X, Y, Z}]},
%    {noreply, playing, State};


event(<<?MSG, _Length:8/integer, MsgBin/binary>>, State) ->
    %error_logger:info_report([{msg, binary_to_list(MsgBin)}]),
    error_logger:info_report([{received, ?MSG, binary_to_list(MsgBin)}]),
    CharInfo = State#state.charinfo,
	CharInfo#charinfo.pid ! {send_msg, binary_to_list(MsgBin)},
    {noreply, playing, State};

%event(<<?BILLBOARD, IdLen:8/integer, Id/binary>>, State) ->
%    CharInfo = State#state.charinfo,
	%CharInfo#charinfo.pid ! {self(), get_mesh, Id},
    %{ok, [Billboard]} = rpc:call(node(CharInfo#charinfo.pid), std_funs, 
    %    get_billboard, [Id]),
    %BillboardBin = list_to_binary(Billboard),
    %BillboardLen = byte_size(BillboardBin),
    %error_logger:info_report([{billboard, ?BILLBOARD, IdLen, Id, 
    %    BillboardLen, BillboardBin}]),
   % {reply, <<?BILLBOARD, IdLen, Id/binary, BillboardLen, 
   %     BillboardBin/binary>>, playing, State};

event(<<?QUERY_ENTITY, _IdLen:8/integer, Id/binary>>, State) ->
    CharInfo = State#state.charinfo,
    obj_call(CharInfo#charinfo.pid, pulse, [Id]),
    {noreply, playing, State};

event(<<?PULSE>>, #state{charinfo=CharInfo} = State) ->
    %error_logger:info_report([{pulse}]),
    obj_call(CharInfo#charinfo.pid, pulse),
    {noreply, playing, State};

event(<<?SYNC_Y_MOVE, X/little-float, Y/little-float, Z/little-float>>, 
    State) ->
    error_logger:info_report([{sync_y_ugly_hack_for_player_pos, Y}]),
    CharInfo = State#state.charinfo,
	CharInfo#charinfo.pid ! {sync_y_move, {X, Y, Z}},
    {noreply, playing, State};

% Perhaps gods should have their own connection module?
event(<<?CREATE_OBJECT, 
    TypeLen:8/integer, Type:TypeLen/binary, 
    NameLen:8/integer, Name:NameLen/binary,
    MeshLen:8/integer, Mesh:MeshLen/binary,
    PosX/little-float, PosY/little-float, PosZ/little-float>>, 
    State) ->
    %error_logger:info_report([{Mesh, X, Y, Z}]),
    CharInfo = State#state.charinfo,
    Pid = CharInfo#charinfo.pid,
	rpc:call(node(Pid), obj, async_call, [Pid, god_tool_create, [
        {type, Type}, 
        {name, Name}, 
        {mesh, Mesh}, 
        {pos, #vec{x=PosX, y=PosY, z=PosZ}}]]),
    error_logger:info_report([{create_object, Type, Name, Mesh,
        PosX, PosY, PosZ}]),
    {noreply, playing, State};

event(<<?SET_MESH, IdLen:8/integer, Id:IdLen/binary, MeshLen:8/integer,
    Mesh:MeshLen/binary>>, State) ->
    CharInfo = State#state.charinfo,
	CharInfo#charinfo.pid ! {set_mesh, [Id, binary_to_list(Mesh)]},
    {noreply, playing, State};

event(<<?INCREASE_SPEED>>, State) ->
    %error_logger:info_report(increase_speed),
    CharInfo = State#state.charinfo,
    Pid = CharInfo#charinfo.pid,
	rpc:call(node(Pid), obj, async_call, [Pid, increase_speed]),
    {noreply, playing, State};

event(<<?DECREASE_SPEED>>, State) ->
    %error_logger:info_report(decrease_speed),
    CharInfo = State#state.charinfo,
    Pid = CharInfo#charinfo.pid,
	rpc:call(node(Pid), obj, async_call, [Pid, decrease_speed]),
    {noreply, playing, State};

event(<<?SET_DIR, X/little-float, Y/little-float, Z/little-float>>, 
    State) ->
    CharInfo = State#state.charinfo,
    Pid = CharInfo#charinfo.pid,
	rpc:call(node(Pid), obj, async_call, [Pid, set_dir, 
        [#vec{x=X, y=Y, z=Z}]]),
    {noreply, playing, State};

event(<<?SET_NAME, NameLen:8/integer, Name:NameLen/binary>>, State) ->
    CharInfo = State#state.charinfo,
    Pid = CharInfo#charinfo.pid,
    error_logger:info_report([{set_name, Name}]),
	rpc:call(node(Pid), obj, async_call, [Pid, set_name, [Name]]),
    {noreply, playing, State};

event(<<?GET_NAME, IdLen:8/integer, Id:IdLen/binary>>, State) ->
    CharInfo = State#state.charinfo,
    Pid = CharInfo#charinfo.pid,
	rpc:call(node(Pid), obj, async_call, [Pid, get_name, [Id]]),
    {noreply, playing, State};

event(<<?SAVE>>, State) ->
    CharInfo = State#state.charinfo,
    Pid = CharInfo#charinfo.pid,
	rpc:call(node(Pid), obj, async_call, [Pid, save, 
        [State#state.account]]),
    {noreply, playing, State};

event(<<?ENABLE_FLYING>>, State) ->
    CharInfo = State#state.charinfo,
    Pid = CharInfo#charinfo.pid,
	rpc:call(node(Pid), obj, async_call, [Pid, enable_flying]),
    {noreply, playing, State};

event(<<?DISABLE_FLYING>>, State) ->
    CharInfo = State#state.charinfo,
    Pid = CharInfo#charinfo.pid,
	rpc:call(node(Pid), obj, async_call, [Pid, disable_flying]),
    {noreply, playing, State};

event(Event, State) ->
    %CharInfo = State#state.charinfo,
	%CharInfo#charinfo.pid ! Event,
    error_logger:info_report([{unknown_event, Event}]),
    {noreply, playing, State}.

obj_call(Pid, Fun) ->
    rpc:call(node(Pid), obj, async_call, [Pid, Fun]).

obj_call(Pid, Fun, Args) ->
    rpc:call(node(Pid), obj, async_call, [Pid, Fun, Args]).

