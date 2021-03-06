-ifndef(RD_USER_HRL).
-define(RD_USER_HRL,"rd_user.hrl").


-record(user_misc, {key         = 0
                   ,value1      = 0
                   ,value2      = 0
                   ,value3      = 0
                   ,value_text  = []    %% 自定义信息存储
                   ,is_dirty    = 1     %% 是否脏数据，一般放record最后一个字段
    }).

%% 玩家在进程中的临时数据和其他一些数据
-record(user_other, {is_loop        = 0     %% 前端发送协议确认正式登录完成后，才开始loop
                    ,pid
                    ,socket
                    ,map_id
                    ,map_index_id
                    ,map_pid
                    ,bag                    %% 背包
                    ,mail                   %% 邮件
                    ,misc           = []    %% 需要持久化的杂项信息 对应user_misc
                    ,temp_misc      = []    %% 无需持久化的杂项信息 对应user_misc

                    ,msg_list       = []    %% 用于存储每次前段发协议上来处理时需要反馈给前端的协议信息
                    ,log_list       = []    %% 用于存储玩家日志
                    ,event_list     = []    %% 用于存储玩家事件
    }).

%    ,map_pid
%    ,next_map_pid
%    ,map_inst_id                    %%  所在地图实例ID {map_id,line,index}
%    ,old_map_pos                    %%  {map_inst_id, pos_x, pos_y}  
%    ,attr_list = []                 %%  [{?ATTR_CHGTYPE, ATTR_LIST},....]
%    ,total_attr                     %%  #user_attr{}
%    ,passive_skill_list = []        %%  [{?ATTR_CHGTYPE, SKILL_LIST},....]
%    ,infant_state = 1               %%  0:未知  1:成年  2:登记但未成年 3未登记
%    ,real_stop_timer = undefined
%    ,revive_timer = undefined
%    ,login_state = 1                %%  0-等待重连 1-正常登陆 2-登录完成 3-重连登陆
%    ,misc_dict = dict:new()         %%  user_misc对应的字典
%    ,local_misc_dict = dict:new()   %%  内部字典
%    ,clothes_id = 0                 %%  衣服
%    ,weapon_id = 0                  %%  武器
%    ,weapon_stren = 0               %%  武器强化等级
%    ,stren_suit = 0                 %%  全身强化等级
%    ,is_transform = 0               %%  是否变身
%    ,team_pid                       %%  队伍进程PID
%    ,skill_info                     %%  技能信息
%    ,grow_dict = dict:new()         %%  成长系统
%    ,vestment_info                  %%  圣衣系统
%    ,vestment_id = 0                %%  圣衣ID
%    ,grow_shape = []                %%  成长系统外形
%    ,escort                         %%  护送
%    ,battle_time = 0                %%  pvp战斗时间
%    ,pve_battle_time = 0            %%  pve战斗时间
%    ,loop_task = []                 %%  日常任务    [{Type,#user_loop_task{}},....]
%    ,msg_list = []                  %%  未处理消息列表  [#user_msg{},....]
%    ,title_dict = dict:new()        %%  称号信息
%    ,title_list = []                %%  所选称号列表
%    ,honor_level = 0                %%  头衔等级
%    ,dup_tpl_id = 0                 %%  所处的副本模板ID
%    ,camp = 0 
%    ,fashion_weapon_id = 0          %%  时装武器ID
%    ,fashion_clothes_id = 0         %%  时装衣服ID
%    ,dup_room = {0,0}               %%  多人副本房间信息{RoomId,CreateUserId}
%    ,temp_hp = 0 
%    ,dup_exp = {0,0}                %%  {金币鼓舞次数,钻石鼓舞次数}
%    ,team_id = 0                    %%  挂机队伍
%    ,team_member_num = 0 
%    ,team_member_ids = []
%    ,meditation = 0                 %% 冥想状态
%    ,buff_list = []                 %% 玩家buff 经验药水等
%    ,statistic_dict = dict:new()    %% 玩家统计类数据
%    ,server_no_string               %% 玩家服务器
%    ,logout_code = 0                %% 玩家离线code
%    ,logout_reason = ""             %% 玩家离线reason
%    ,activity_list = []             %% 玩家活动数据
%    ,platform_info = #user_platform{}
%    ,platform_login_param = #platform_login_param{}
%    ,battle_3v3 = #user_battle_3v3{}
%    ,is_hook = 0                    %% 0 否 1 挂机状态
%    ,hook = none
%    ,heart_time = 0                 %% 13100 初始化 60001 更新


%% 需要存库的数据
-record(user, {user_id          = 0
              ,acc_name         = <<"">>
              ,name             = <<"">>
              ,server_id        = 1         %% 玩家当前server_id(config中的)
              ,reg_server_id    = 1         %% 玩家注册的server_id(注册时所在服的config中的)
              ,user_type        = 0         %% 玩家类型:0、普通玩家，1、新手指导员，2、GM
              ,ip               = <<"">>

              ,reg_time         = 0
              ,online_time      = 0         %% 在线时间
              ,total_online_time= 0         %% 累计在线时间
              ,login_time       = 0
              ,last_online_time = 0 
              ,last_update_time = 0         %% save db time
              ,logout_type      = 0         %% 下线类型

              ,coin             = 0

              ,map_id           = 0
              ,pos_x            = 0
              ,pos_y            = 0

              ,gender           = 1
              ,career           = 1
              ,lv               = 1
              ,exp              = 0

              ,hp               = 0
              ,mp               = 0

              ,guild_id         = 0         %% 帮派id

              ,other_data       = #user_other{}    %% 存库时该字段清空
    }).

-record(user_online, {user_id = 0
                      ,pid
    }).

-record(account_info, {acc_name = <<>>
                      ,user_ids = []
    }).

-record(user_item, {item_id     = 0
                    ,tpl_id     = 0
                    ,user_id    = 0
                    ,location   = 0
                    ,is_dirty   = 1
    }).

-endif.
