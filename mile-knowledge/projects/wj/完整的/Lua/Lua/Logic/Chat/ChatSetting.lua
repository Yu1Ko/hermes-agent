-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: ChatSetting
-- Date: 2023-07-26 11:13:08
-- Desc: 聊天设置 配置
-- ---------------------------------------------------------------------------------
local tbChannels2Index, tbIndex2Channels = (function()
    local t, r = {}, {}
    for i, v in ipairs({ -- 注意 新频道只能往后添加 不能随意更改顺序
        "全部频道","常用频道","密聊频道","队伍频道","帮会频道","阵营频道",
        "萌新频道","地图频道","门派频道","其他频道","系统频道","战斗频道",
        "近聊频道","世界频道","团队频道","房间频道","战场频道","李渡鬼域",
        "好友频道","拜师频道","同盟频道","弹幕频道","全服频道","NPC剧情",
        "玩家剧情","金钱","阅历","物品","声望","修为","称号","成就","精力",
        "好感度","威名点","师徒值","园宅币","侠行点","名剑币","帮会资金","烟花公告",
        "奇遇公告","招式命中","未命中","重伤","伤害技能","增益技能","击伤","附魔",
        "场景事件","单条提醒","双条提醒","NPC近聊","NPC大吼","NPC队聊","NPC密聊",
        "增益信息","受到伤害","受到治疗","减益信息","增益信息","武功技能","运功失败","开启免打扰",
        "语音频道"
    }) do
        t[v] = i
        r[i] = v
    end
    return t, r
end)()

ChatSetting =
{
    -- 频道显示 -------------------------------------------
    {
        szName = "频道显示",
        szUIChannel = UI_Chat_Channel.Display,
        bSettable = true,
        bVisible = true,
        bCanRename = false,
        tbRecvChannelIDs = {},
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Display,
                szName = "频道显示设置",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "全部频道", bDefaultSelect = true, bUnCheckAble = false, szUIChannel = UI_Chat_Channel.All},
                    {szName = "常用频道", bDefaultSelect = true, bUnCheckAble = true, szUIChannel = UI_Chat_Channel.Common},
                    {szName = "密聊频道", bDefaultSelect = true, bUnCheckAble = false, szUIChannel = UI_Chat_Channel.Whisper},
                    {szName = "侠缘频道", bDefaultSelect = true, bUnCheckAble = false, szUIChannel = UI_Chat_Channel.AINpc},
                    {szName = "队伍频道", bDefaultSelect = true, bUnCheckAble = false, szUIChannel = UI_Chat_Channel.Team},
                    {szName = "帮会频道", bDefaultSelect = true, bUnCheckAble = true, szUIChannel = UI_Chat_Channel.Tong},
                    {szName = "阵营频道", bDefaultSelect = true, bUnCheckAble = true, szUIChannel = UI_Chat_Channel.Camp},
                    {szName = "萌新频道", bDefaultSelect = true, bUnCheckAble = true, szUIChannel = UI_Chat_Channel.Identity},
                    {szName = "地图频道", bDefaultSelect = true, bUnCheckAble = true, szUIChannel = UI_Chat_Channel.SENCE},
                    {szName = "门派频道", bDefaultSelect = true, bUnCheckAble = true, szUIChannel = UI_Chat_Channel.Force},
                    {szName = "其他频道", bDefaultSelect = true, bUnCheckAble = true, szUIChannel = UI_Chat_Channel.Other},
                    {szName = "系统频道", bDefaultSelect = true, bUnCheckAble = false, szUIChannel = UI_Chat_Channel.System},
				    {szName = "战斗频道", bDefaultSelect = true, bUnCheckAble = true, szUIChannel = UI_Chat_Channel.Fight},
                }
            },
        }
    },


    -- 全部频道 -------------------------------------------
    {
        szName = "全部频道",
        szUIChannel = UI_Chat_Channel.All,
        bSettable = true,
        bVisible = true,
        bCanRename = false,
        tbRecvChannelIDs = {},
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Recv,
                szName = "接收消息",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "近聊频道", bDefaultSelect = true, tbChannelIDs = {1}},
                    {szName = "地图频道", bDefaultSelect = true, tbChannelIDs = {5}},
                    {szName = "世界频道", bDefaultSelect = true, tbChannelIDs = {32}},
                    {szName = "队伍频道", bDefaultSelect = true, tbChannelIDs = {2}},
                    {szName = "团队频道", bDefaultSelect = true, tbChannelIDs = {3}},
                    {szName = "房间频道", bDefaultSelect = true, tbChannelIDs = {50}},
                    {szName = "阵营频道", bDefaultSelect = true, tbChannelIDs = {34}},
                    {szName = "战场频道", bDefaultSelect = true, tbChannelIDs = {4}},
                    {szName = "李渡鬼域", bDefaultSelect = true, tbChannelIDs = {47}},
                    {szName = "密聊频道", bDefaultSelect = true, tbChannelIDs = {6}},
                    {szName = "好友频道", bDefaultSelect = true, tbChannelIDs = {36}},
                    {szName = "拜师频道", bDefaultSelect = true, tbChannelIDs = {35}},
                    {szName = "门派频道", bDefaultSelect = true, tbChannelIDs = {33}},
                    {szName = "帮会频道", bDefaultSelect = true, tbChannelIDs = {29,31}},
                    {szName = "同盟频道", bDefaultSelect = true, tbChannelIDs = {30}},
                    {szName = "萌新频道", bDefaultSelect = true, tbChannelIDs = {40}},
                    {szName = "弹幕频道", bDefaultSelect = true, tbChannelIDs = {52}},
                    {szName = "全服频道", bDefaultSelect = true, tbChannelIDs = {49}},
                    {szName = "系统频道", bDefaultSelect = true, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.System},
                    {szName = "语音频道", bDefaultSelect = true, tbChannelIDs = {51}},
                    {szName = "NPC剧情", bDefaultSelect = true, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.NPCStory},
                    {szName = "玩家剧情", bDefaultSelect = true, tbChannelIDs = {28}},
                }
            },
        }
    },

    -- 常用频道 -------------------------------------------
    {
        szName = "常用频道",
        szUIChannel = UI_Chat_Channel.Common,
        bSettable = true,
        bVisible = true,
        bCanRename = true,
        tbRecvChannelIDs = {},
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Recv,
                szName = "接收消息",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "近聊频道", bDefaultSelect = true, tbChannelIDs = {1}},
                    {szName = "地图频道", bDefaultSelect = true, tbChannelIDs = {5}},
                    {szName = "世界频道", bDefaultSelect = false, tbChannelIDs = {32}},
                    {szName = "队伍频道", bDefaultSelect = true, tbChannelIDs = {2}},
                    {szName = "团队频道", bDefaultSelect = true, tbChannelIDs = {3}},
                    {szName = "房间频道", bDefaultSelect = true, tbChannelIDs = {50}},
                    {szName = "阵营频道", bDefaultSelect = false, tbChannelIDs = {34}},
                    {szName = "战场频道", bDefaultSelect = true, tbChannelIDs = {4}},
                    {szName = "李渡鬼域", bDefaultSelect = true, tbChannelIDs = {47}},
                    {szName = "密聊频道", bDefaultSelect = true, tbChannelIDs = {6}},
                    {szName = "好友频道", bDefaultSelect = true, tbChannelIDs = {36}},
                    {szName = "拜师频道", bDefaultSelect = false, tbChannelIDs = {35}},
                    {szName = "门派频道", bDefaultSelect = false, tbChannelIDs = {33}},
                    {szName = "帮会频道", bDefaultSelect = true, tbChannelIDs = {29,31}},
                    {szName = "同盟频道", bDefaultSelect = true, tbChannelIDs = {30}},
                    {szName = "萌新频道", bDefaultSelect = true, tbChannelIDs = {40}},
                    {szName = "弹幕频道", bDefaultSelect = false, tbChannelIDs = {52}},
                    {szName = "全服频道", bDefaultSelect = true, tbChannelIDs = {49}},
                    {szName = "系统频道", bDefaultSelect = true, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.System},
                    {szName = "语音频道", bDefaultSelect = true, tbChannelIDs = {51}},
                    {szName = "NPC剧情", bDefaultSelect = true, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.NPCStory},
                    {szName = "玩家剧情", bDefaultSelect = true, tbChannelIDs = {28}},
                }
            },
        }
    },

    -- 密聊频道 -------------------------------------------
    {
        szName = "密聊频道",
        szUIChannel = UI_Chat_Channel.Whisper,
        bSettable = true,
        bVisible = true,
        bCanRename = false,
        tbRecvChannelIDs = {},
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Recv,
                szName = "接收消息",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "密聊频道", bDefaultSelect = true, tbChannelIDs = {6}},
                }
            },
            [2] =
            {
                szType = UI_Chat_Setting_Type.Whisper_Disturb,
                szName = "陌生人免打扰设置",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {-1},
                tbChannelList = {
                    {szName = "开启免打扰", bDefaultSelect = false}
                }
            }
        }
    },

    -- 侠缘频道 -------------------------------------------
    {
        szName = "侠缘频道",
        szUIChannel = UI_Chat_Channel.AINpc,
        bSettable = false,
        bVisible = true,
        bCanRename = false,
        tbRecvChannelIDs = {CLIENT_PLAYER_TALK_CHANNEL.AINPC},
    },

    -- 队伍频道 -------------------------------------------
    {
        szName = "队伍频道",
        szUIChannel = UI_Chat_Channel.Team,
        bSettable = true,
        bVisible = true,
        bCanRename = false,
        tbRecvChannelIDs = {},
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Recv,
                szName = "接收消息",
                nVersion = 2,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "近聊频道", bDefaultSelect = false, tbChannelIDs = {1}},
                    {szName = "地图频道", bDefaultSelect = false, tbChannelIDs = {5}},
                    {szName = "世界频道", bDefaultSelect = false, tbChannelIDs = {32}},
                    {szName = "队伍频道", bDefaultSelect = true, bUnCheckAble = false, tbChannelIDs = {2}},
                    {szName = "团队频道", bDefaultSelect = true, bUnCheckAble = false, tbChannelIDs = {3}},
                    {szName = "房间频道", bDefaultSelect = true, bUnCheckAble = false, tbChannelIDs = {50}},
                    {szName = "阵营频道", bDefaultSelect = false, tbChannelIDs = {34}},
                    {szName = "战场频道", bDefaultSelect = true, tbChannelIDs = {4}},
                    {szName = "李渡鬼域", bDefaultSelect = true, tbChannelIDs = {47}},
                    {szName = "密聊频道", bDefaultSelect = false, tbChannelIDs = {6}},
                    {szName = "好友频道", bDefaultSelect = false, tbChannelIDs = {36}},
                    {szName = "拜师频道", bDefaultSelect = false, tbChannelIDs = {35}},
                    {szName = "门派频道", bDefaultSelect = false, tbChannelIDs = {33}},
                    {szName = "帮会频道", bDefaultSelect = false, tbChannelIDs = {29,31}},
                    {szName = "同盟频道", bDefaultSelect = false, tbChannelIDs = {30}},
                    {szName = "萌新频道", bDefaultSelect = false, tbChannelIDs = {40}},
                    {szName = "弹幕频道", bDefaultSelect = false, tbChannelIDs = {52}},
                    {szName = "全服频道", bDefaultSelect = false, tbChannelIDs = {49}},
                    {szName = "系统频道", bDefaultSelect = false, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.System},
                    {szName = "NPC剧情", bDefaultSelect = false, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.NPCStory},
                    {szName = "玩家剧情", bDefaultSelect = false, tbChannelIDs = {28}},
                }
            }
        }
    },

    -- 帮会频道 -------------------------------------------
    {
        szName = "帮会频道",
        szUIChannel = UI_Chat_Channel.Tong,
        bSettable = true,
        bVisible = true,
        bCanRename = false,
        tbRecvChannelIDs = {},
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Recv,
                szName = "接收消息",
                nVersion = 2,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "近聊频道", bDefaultSelect = false, tbChannelIDs = {1}},
                    {szName = "地图频道", bDefaultSelect = false, tbChannelIDs = {5}},
                    {szName = "世界频道", bDefaultSelect = false, tbChannelIDs = {32}},
                    {szName = "队伍频道", bDefaultSelect = false, tbChannelIDs = {2}},
                    {szName = "团队频道", bDefaultSelect = false, tbChannelIDs = {3}},
                    {szName = "房间频道", bDefaultSelect = false, tbChannelIDs = {50}},
                    {szName = "阵营频道", bDefaultSelect = false, tbChannelIDs = {34}},
                    {szName = "战场频道", bDefaultSelect = false, tbChannelIDs = {4}},
                    {szName = "李渡鬼域", bDefaultSelect = false, tbChannelIDs = {47}},
                    {szName = "密聊频道", bDefaultSelect = false, tbChannelIDs = {6}},
                    {szName = "好友频道", bDefaultSelect = false, tbChannelIDs = {36}},
                    {szName = "拜师频道", bDefaultSelect = false, tbChannelIDs = {35}},
                    {szName = "门派频道", bDefaultSelect = false, tbChannelIDs = {33}},
                    {szName = "帮会频道", bDefaultSelect = true, bUnCheckAble = false, tbChannelIDs = {29,31}},
                    {szName = "同盟频道", bDefaultSelect = true, bUnCheckAble = false, tbChannelIDs = {30}},
                    {szName = "萌新频道", bDefaultSelect = false, tbChannelIDs = {40}},
                    {szName = "弹幕频道", bDefaultSelect = false, tbChannelIDs = {52}},
                    {szName = "全服频道", bDefaultSelect = false, tbChannelIDs = {49}},
                    {szName = "系统频道", bDefaultSelect = false, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.System},
                    {szName = "NPC剧情", bDefaultSelect = false, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.NPCStory},
                    {szName = "玩家剧情", bDefaultSelect = false, tbChannelIDs = {28}},
                }
            }
        }
    },

    -- 阵营频道 -------------------------------------------
    {
        szName = "阵营频道",
        szUIChannel = UI_Chat_Channel.Camp,
        bSettable = true,
        bVisible = true,
        bCanRename = false,
        tbRecvChannelIDs = {},
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Recv,
                szName = "接收消息",
                nVersion = 2,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "近聊频道", bDefaultSelect = true, tbChannelIDs = {1}},
                    {szName = "地图频道", bDefaultSelect = true, tbChannelIDs = {5}},
                    {szName = "世界频道", bDefaultSelect = false, tbChannelIDs = {32}},
                    {szName = "队伍频道", bDefaultSelect = false, tbChannelIDs = {2}},
                    {szName = "团队频道", bDefaultSelect = false, tbChannelIDs = {3}},
                    {szName = "房间频道", bDefaultSelect = false, tbChannelIDs = {50}},
                    {szName = "阵营频道", bDefaultSelect = true, bUnCheckAble = false, tbChannelIDs = {34}},
                    {szName = "战场频道", bDefaultSelect = false, tbChannelIDs = {4}},
                    {szName = "李渡鬼域", bDefaultSelect = false, tbChannelIDs = {47}},
                    {szName = "密聊频道", bDefaultSelect = false, tbChannelIDs = {6}},
                    {szName = "好友频道", bDefaultSelect = false, tbChannelIDs = {36}},
                    {szName = "拜师频道", bDefaultSelect = false, tbChannelIDs = {35}},
                    {szName = "门派频道", bDefaultSelect = false, tbChannelIDs = {33}},
                    {szName = "帮会频道", bDefaultSelect = true, tbChannelIDs = {29,31}},
                    {szName = "同盟频道", bDefaultSelect = true, tbChannelIDs = {30}},
                    {szName = "萌新频道", bDefaultSelect = false, tbChannelIDs = {40}},
                    {szName = "弹幕频道", bDefaultSelect = false, tbChannelIDs = {52}},
                    {szName = "全服频道", bDefaultSelect = false, tbChannelIDs = {49}},
                    {szName = "系统频道", bDefaultSelect = false, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.System},
                    {szName = "NPC剧情", bDefaultSelect = false, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.NPCStory},
                    {szName = "玩家剧情", bDefaultSelect = false, tbChannelIDs = {28}},
                }
            },
        }
    },


    -- 萌新频道 -------------------------------------------
    {
        szName = "萌新频道",
        szUIChannel = UI_Chat_Channel.Identity,
        bSettable = true,
        bVisible = true,
        bCanRename = false,
        tbRecvChannelIDs = {},
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Recv,
                szName = "接收消息",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "萌新频道", bDefaultSelect = true, tbChannelIDs = {40}},
                }
            },
        }
    },

    -- 地图频道 -------------------------------------------
    {
        szName = "地图频道",
        szUIChannel = UI_Chat_Channel.SENCE,
        bSettable = true,
        bVisible = true,
        bCanRename = false,
        tbRecvChannelIDs = {},
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Recv,
                szName = "接收消息",
                nVersion = 2,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "近聊频道", bDefaultSelect = true, bUnCheckAble = false, tbChannelIDs = {1}},
                    {szName = "地图频道", bDefaultSelect = true, bUnCheckAble = false, tbChannelIDs = {5}},
                    {szName = "世界频道", bDefaultSelect = false, tbChannelIDs = {32}},
                    {szName = "队伍频道", bDefaultSelect = false, tbChannelIDs = {2}},
                    {szName = "团队频道", bDefaultSelect = false, tbChannelIDs = {3}},
                    {szName = "房间频道", bDefaultSelect = false, tbChannelIDs = {50}},
                    {szName = "阵营频道", bDefaultSelect = false, tbChannelIDs = {34}},
                    {szName = "战场频道", bDefaultSelect = false, tbChannelIDs = {4}},
                    {szName = "李渡鬼域", bDefaultSelect = false, tbChannelIDs = {47}},
                    {szName = "密聊频道", bDefaultSelect = false, tbChannelIDs = {6}},
                    {szName = "好友频道", bDefaultSelect = false, tbChannelIDs = {36}},
                    {szName = "拜师频道", bDefaultSelect = false, tbChannelIDs = {35}},
                    {szName = "门派频道", bDefaultSelect = false, tbChannelIDs = {33}},
                    {szName = "帮会频道", bDefaultSelect = false, tbChannelIDs = {29,31}},
                    {szName = "同盟频道", bDefaultSelect = false, tbChannelIDs = {30}},
                    {szName = "萌新频道", bDefaultSelect = false, tbChannelIDs = {40}},
                    {szName = "弹幕频道", bDefaultSelect = false, tbChannelIDs = {52}},
                    {szName = "全服频道", bDefaultSelect = false, tbChannelIDs = {49}},
                    {szName = "系统频道", bDefaultSelect = false, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.System},
                    {szName = "NPC剧情", bDefaultSelect = false, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.NPCStory},
                    {szName = "玩家剧情", bDefaultSelect = false, tbChannelIDs = {28}},
                }
            },
        }
    },
    -- 门派频道 -------------------------------------------
    {
        szName = "门派频道",
        szUIChannel = UI_Chat_Channel.Force,
        bSettable = true,
        bVisible = true,
        bCanRename = true,
        tbRecvChannelIDs = {},
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Recv,
                szName = "接收消息",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "近聊频道", bDefaultSelect = false, tbChannelIDs = {1}},
                    {szName = "地图频道", bDefaultSelect = false, tbChannelIDs = {5}},
                    {szName = "世界频道", bDefaultSelect = false, tbChannelIDs = {32}},
                    {szName = "队伍频道", bDefaultSelect = false, tbChannelIDs = {2}},
                    {szName = "团队频道", bDefaultSelect = false, tbChannelIDs = {3}},
                    {szName = "房间频道", bDefaultSelect = false, tbChannelIDs = {50}},
                    {szName = "阵营频道", bDefaultSelect = false, tbChannelIDs = {34}},
                    {szName = "战场频道", bDefaultSelect = false, tbChannelIDs = {4}},
                    {szName = "李渡鬼域", bDefaultSelect = false, tbChannelIDs = {47}},
                    {szName = "密聊频道", bDefaultSelect = false, tbChannelIDs = {6}},
                    {szName = "好友频道", bDefaultSelect = false, tbChannelIDs = {36}},
                    {szName = "拜师频道", bDefaultSelect = false, tbChannelIDs = {35}},
                    {szName = "门派频道", bDefaultSelect = true, tbChannelIDs = {33}},
                    {szName = "帮会频道", bDefaultSelect = false, tbChannelIDs = {29,31}},
                    {szName = "同盟频道", bDefaultSelect = false, tbChannelIDs = {30}},
                    {szName = "萌新频道", bDefaultSelect = false, tbChannelIDs = {40}},
                    {szName = "弹幕频道", bDefaultSelect = false, tbChannelIDs = {52}},
                    {szName = "全服频道", bDefaultSelect = false, tbChannelIDs = {49}},
                    {szName = "系统频道", bDefaultSelect = false, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.System},
                    {szName = "NPC剧情", bDefaultSelect = false, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.NPCStory},
                    {szName = "玩家剧情", bDefaultSelect = false, tbChannelIDs = {28}},
                }
            },
        }
    },

    -- 其他频道 -------------------------------------------
    {
        szName = "其他频道",
        szUIChannel = UI_Chat_Channel.Other,
        bSettable = true,
        bVisible = true,
        bCanRename = true,
        tbRecvChannelIDs = {},
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Recv,
                szName = "接收消息",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "近聊频道", bDefaultSelect = true, tbChannelIDs = {1}},
                    {szName = "地图频道", bDefaultSelect = true, tbChannelIDs = {5}},
                    {szName = "世界频道", bDefaultSelect = false, tbChannelIDs = {32}},
                    {szName = "队伍频道", bDefaultSelect = false, tbChannelIDs = {2}},
                    {szName = "团队频道", bDefaultSelect = false, tbChannelIDs = {3}},
                    {szName = "房间频道", bDefaultSelect = false, tbChannelIDs = {50}},
                    {szName = "阵营频道", bDefaultSelect = true, tbChannelIDs = {34}},
                    {szName = "战场频道", bDefaultSelect = false, tbChannelIDs = {4}},
                    {szName = "李渡鬼域", bDefaultSelect = false, tbChannelIDs = {47}},
                    {szName = "密聊频道", bDefaultSelect = false, tbChannelIDs = {6}},
                    {szName = "好友频道", bDefaultSelect = true, tbChannelIDs = {36}},
                    {szName = "拜师频道", bDefaultSelect = true, tbChannelIDs = {35}},
                    {szName = "门派频道", bDefaultSelect = true, tbChannelIDs = {33}},
                    {szName = "帮会频道", bDefaultSelect = false, tbChannelIDs = {29,31}},
                    {szName = "同盟频道", bDefaultSelect = false, tbChannelIDs = {30}},
                    {szName = "萌新频道", bDefaultSelect = false, tbChannelIDs = {40}},
                    {szName = "弹幕频道", bDefaultSelect = false, tbChannelIDs = {52}},
                    {szName = "全服频道", bDefaultSelect = false, tbChannelIDs = {49}},
                    {szName = "系统频道", bDefaultSelect = false, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.System},
                    {szName = "NPC剧情", bDefaultSelect = false, tbChannelIDs = nil, szRelocateUIChannel = UI_Chat_Channel.NPCStory},
                    {szName = "玩家剧情", bDefaultSelect = false, tbChannelIDs = {28}},
                }
            },
        }
    },

    -- 系统频道 -------------------------------------------
    {
        szName = "系统频道",
        szUIChannel = UI_Chat_Channel.System,
        bSettable = true,
        bVisible = true,
        bCanRename = false,
        tbRecvChannelIDs = {7, 8, 9, 10, 11, 12, 13, 35, 37, 48, },
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Reward,
                szName = "通用奖励",
                nVersion = 5,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "金钱",       bDefaultSelect = true, szMsg = "MSG_MONEY"},
                    {szName = "阅历",       bDefaultSelect = true, szMsg = "MSG_EXP"},
                    {szName = "物品",       bDefaultSelect = true, szMsg = "MSG_ITEM"},
                    {szName = "声望",       bDefaultSelect = true, szMsg = "MSG_REPUTATION"},
                    {szName = "好感度",     bDefaultSelect = true, szMsg = "MSG_ATTRACTION"},
                    {szName = "威名点",     bDefaultSelect = true, szMsg = "MSG_PRESTIGE"},
                    {szName = "修为",       bDefaultSelect = true, szMsg = "MSG_TRAIN"},
                    {szName = "称号",       bDefaultSelect = true, szMsg = "MSG_DESGNATION"},
                    {szName = "成就",       bDefaultSelect = true, szMsg = "MSG_ACHIEVEMENT"},
                    {szName = "桃李值",     bDefaultSelect = true, szMsg = "MSG_MENTORAWARD"},
                    {szName = "精力",       bDefaultSelect = true, szMsg = "MSG_THEW_STAMINA"},
                    {szName = "帮会资金",   bDefaultSelect = true, szMsg = "MSG_TONG_FUND"},
                    {szName = "园宅币",     bDefaultSelect = true, szMsg = "MSG_ARCHITECTURE"},
                    {szName = "侠行点",     bDefaultSelect = true, szMsg = "MSG_JUSTICE"},
                    {szName = "休闲点",     bDefaultSelect = true, szMsg = "MSG_CONTRIBUTION"},
                    {szName = "大水南方令", bDefaultSelect = true, szMsg = "MSG_HOMELANDTOKEN"},
                    {szName = "奇境宝钞",   bDefaultSelect = true, szMsg = "MSG_EXAMPRINT"},
                    {szName = "飞沙令",     bDefaultSelect = true, szMsg = "MSG_SANDSTORMAWARD"},
                    {szName = "浪客笺",     bDefaultSelect = true, szMsg = "MSG_ROVER"},
                    {szName = "修罗之印",   bDefaultSelect = true, szMsg = "MSG_DUNGEONTOWERAWARD"},
                    {szName = "功勋点",     bDefaultSelect = true, szMsg = "MSG_TONGLEAGUEPOINT"},
                    {szName = "周行令",     bDefaultSelect = true, szMsg = "MSG_WEEKAWARD"},
                    {szName = "鸣铮玉",     bDefaultSelect = true, szMsg = "MSG_ARENATOWERAWARD"},
                }
            },

            [2] =
            {
                szType = UI_Chat_Setting_Type.Filter,
                szName = "系统公告",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {-1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "烟花公告", bDefaultSelect = true, tbKeyWords = {}},
                    {szName = "奇遇公告", bDefaultSelect = true, tbKeyWords = {"触发了奇遇", "触发奇遇", "完成奇遇"}},
                }
            },
        }
    },

    -- 战斗频道 -------------------------------------------
    {
        szName = "战斗频道",
        szUIChannel = UI_Chat_Channel.Fight,
        bSettable = true,
        bVisible = true,
        bCanRename = false,
        tbRecvChannelIDs = {CLIENT_PLAYER_TALK_CHANNEL.FIGHT},
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Fight_Others,
                szName = "其他玩家",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "招式命中",   bDefaultSelect = false, szMsg = "MSG_SKILL_OTHERS_SKILL"},
                    {szName = "未命中",     bDefaultSelect = false, szMsg = "MSG_SKILL_OTHERS_MISS"},
                    {szName = "重伤",       bDefaultSelect = true, szMsg = "MSG_OTHERS_DEATH"},
                    -- {szName = "伤害技能",   bDefaultSelect = true, szMsg = "MSG_SKILL_OTHERS_HARMFUL_SKILL"},
                    -- {szName = "增益技能",   bDefaultSelect = true, szMsg = "MSG_SKILL_OTHERS_BENEFICIAL_SKILL"},
                    -- {szName = "击伤",       bDefaultSelect = true, szMsg = "MSG_OTHERS_KILL"},
                }
            },

            [2] =
            {
                szType = UI_Chat_Setting_Type.Fight_Party,
                szName = "队友",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "伤害技能",   bDefaultSelect = true, szMsg = "MSG_SKILL_PARTY_HARMFUL_SKILL"},
                    {szName = "增益技能",   bDefaultSelect = true, szMsg = "MSG_SKILL_PARTY_BENEFICIAL_SKILL"},
                    {szName = "增益信息",   bDefaultSelect = false, szMsg = "MSG_SKILL_PARTY_BUFF"},
                    {szName = "受到伤害",   bDefaultSelect = true, szMsg = "MSG_SKILL_PARTY_BE_HARMFUL_SKILL"},
                    {szName = "受到治疗",   bDefaultSelect = true, szMsg = "MSG_SKILL_PARTY_BE_BENEFICIAL_SKILL"},
                    {szName = "减益信息",   bDefaultSelect = false, szMsg = "MSG_SKILL_PARTY_DEBUFF"},
                    {szName = "武功技能",   bDefaultSelect = true, szMsg = "MSG_SKILL_PARTY_SKILL"},
                    {szName = "未命中",     bDefaultSelect = false, szMsg = "MSG_SKILL_PARTY_MISS"},
                    {szName = "重伤",       bDefaultSelect = true, szMsg = "MSG_PARTY_DEATH"},
                    -- {szName = "击伤",       bDefaultSelect = true, szMsg = "MSG_PARTY_KILL"},
                }
            },

            [3] =
            {
                szType = UI_Chat_Setting_Type.Fight_Self,
                szName = "自己",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "伤害技能",   bDefaultSelect = true, szMsg = "MSG_SKILL_SELF_HARMFUL_SKILL"},
                    {szName = "增益技能",   bDefaultSelect = true, szMsg = "MSG_SKILL_SELF_BENEFICIAL_SKILL"},
                    {szName = "增益信息",   bDefaultSelect = true, szMsg = "MSG_SKILL_SELF_BUFF"},
                    {szName = "受到伤害",   bDefaultSelect = true, szMsg = "MSG_SKILL_SELF_BE_HARMFUL_SKILL"},
                    {szName = "受到治疗",   bDefaultSelect = true, szMsg = "MSG_SKILL_SELF_BE_BENEFICIAL_SKILL"},
                    {szName = "减益信息",   bDefaultSelect = true, szMsg = "MSG_SKILL_SELF_DEBUFF"},
                    {szName = "武功技能",   bDefaultSelect = true, szMsg = "MSG_SKILL_SELF_SKILL"},
                    {szName = "未命中",     bDefaultSelect = true, szMsg = "MSG_SKILL_SELF_MISS"},
                    {szName = "运功失败",   bDefaultSelect = false, szMsg = "MSG_SKILL_SELF_FAILED"},
                    {szName = "重伤",       bDefaultSelect = true, szMsg = "MSG_SELF_DEATH"},
                    -- {szName = "击伤",       bDefaultSelect = true, szMsg = "MSG_SELF_KILL"},
                }
            },

            [4] =
            {
                szType = UI_Chat_Setting_Type.Fight_Npc,
                szName = "NPC",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "招式命中",   bDefaultSelect = false, szMsg = "MSG_SKILL_NPC_SKILL"},
                    {szName = "未命中",     bDefaultSelect = false, szMsg = "MSG_SKILL_NPC_MISS"},
                    {szName = "重伤",       bDefaultSelect = true, szMsg = "MSG_NPC_DEATH"},
                    -- {szName = "伤害技能",   bDefaultSelect = true, szMsg = "MSG_SKILL_NPC_HARMFUL_SKILL"},
                    -- {szName = "增益技能",   bDefaultSelect = true, szMsg = "MSG_SKILL_NPC_BENEFICIAL_SKILL"},
                    -- {szName = "击伤",       bDefaultSelect = true, szMsg = "MSG_NPC_KILL"},
                }
            },

            [5] =
            {
                szType = UI_Chat_Setting_Type.Fight_Other,
                szName = "其他",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "附魔",       DefaultSelect = true, szMsg = "MSG_OTHER_ENCHANT"},
                    {szName = "场景事件",   DefaultSelect = true, szMsg = "MSG_OTHER_SCENE"},
                }
            },

        }
    },

    -- 消息提示
    {
        szName = "消息提示",
        szUIChannel = UI_Chat_Channel.Hint,
        bSettable = true,
        bVisible = true,
        bCanRename = false,
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.HintRecive,
                szName = "接收消息",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {-1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "密聊频道", bDefaultSelect = true, tbChannelIDs = {6}},
                    {szName = "队伍频道", bDefaultSelect = true, tbChannelIDs = {2}},
                    {szName = "团队频道", bDefaultSelect = true, tbChannelIDs = {3}},
                    {szName = "房间频道", bDefaultSelect = true, tbChannelIDs = {50}},
                    {szName = "帮会频道", bDefaultSelect = false, tbChannelIDs = {29,31}},
                    {szName = "同盟频道", bDefaultSelect = true, tbChannelIDs = {30}},
                }
            },

            [2] =
            {
                szType = UI_Chat_Setting_Type.HintCount,
                szName = "消息提醒数量",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {1, 1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "单条提醒", bDefaultSelect = true},
                    {szName = "双条提醒", bDefaultSelect = false},
                }
            },
        }
    },

    -- 快捷聊天 -------------------------------------------
    --[[
    {
        szName = "快捷聊天",
        szUIChannel = UI_Chat_Channel.Mini,
        bSettable = true,
        bVisible = true,
        bCanRename = false,
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Mini,
                szName = "快捷聊天设置",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {1, 4}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "全部频道", bDefaultSelect = true, szUIChannel = UI_Chat_Channel.All},
                    {szName = "常用频道", bDefaultSelect = true, szUIChannel = UI_Chat_Channel.Common},
                    {szName = "密聊频道", bDefaultSelect = true, szUIChannel = UI_Chat_Channel.Whisper},
                    {szName = "队伍频道", bDefaultSelect = true, szUIChannel = UI_Chat_Channel.Team},
                    {szName = "帮会频道", bDefaultSelect = false, szUIChannel = UI_Chat_Channel.Tong},
                    {szName = "阵营频道", bDefaultSelect = false, szUIChannel = UI_Chat_Channel.Camp},
                    {szName = "门派频道", bDefaultSelect = false, szUIChannel = UI_Chat_Channel.Force},
                    {szName = "其他频道", bDefaultSelect = false, szUIChannel = UI_Chat_Channel.Other},
                }
            },
        }
    },
    ]]

    -- NPC剧情 -------------------------------------------
    {
        szName = "NPC剧情",
        szUIChannel = UI_Chat_Channel.NPCStory,
        bSettable = true,
        bVisible = true,
        bCanRename = false,
        tbRecvChannelIDs = {},
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Recv,
                szName = "接收消息",
                nVersion = 1,
                bVisible = true,
                tbSelectedCount = {-1, -1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
                    {szName = "NPC近聊", bDefaultSelect = true, tbChannelIDs = {14,18,23,26}},
                    {szName = "NPC大吼", bDefaultSelect = true, tbChannelIDs = {16,19,24,27}},
                    {szName = "NPC队聊", bDefaultSelect = true, tbChannelIDs = {15}},
                    {szName = "NPC密聊", bDefaultSelect = true, tbChannelIDs = {17,25}},
                }
            },
        }
    },

    -- 动作表情 -------------------------------------------
    --[[
    {
        szName = "动作表情",
        szUIChannel = UI_Chat_Channel.Action,
        bSettable = true,
        bVisible = true,
        bCanRename = false,
        tbGroupList =
        {
            [1] =
            {
                szType = UI_Chat_Setting_Type.Action,
                szName = "发送消息",
                nVersion = 2,
                bVisible = true,
                tbSelectedCount = {1, 1}, -- 可选数量：第一个至少要选，第二个是最多可选，-1表示不限制
                tbChannelList =
                {
					{szName = "全部频道", bDefaultSelect = false, szUIChannel = UI_Chat_Channel.All},
                    {szName = "常用频道", bDefaultSelect = true, szUIChannel = UI_Chat_Channel.Common},
                    {szName = "队伍频道", bDefaultSelect = false, szUIChannel = UI_Chat_Channel.Team},
					{szName = "帮会频道", bDefaultSelect = false, szUIChannel = UI_Chat_Channel.Tong},
                    {szName = "阵营频道", bDefaultSelect = false, szUIChannel = UI_Chat_Channel.Camp},
                    {szName = "萌新频道", bDefaultSelect = false, szUIChannel = UI_Chat_Channel.Identity},
                    {szName = "地图频道", bDefaultSelect = false, szUIChannel = UI_Chat_Channel.SENCE},
					{szName = "门派频道", bDefaultSelect = false, szUIChannel = UI_Chat_Channel.Force},
					{szName = "其他频道", bDefaultSelect = false, szUIChannel = UI_Chat_Channel.Other},
                }
            },
        }
    },
    ]]


}

ChatSetting.GetChannels2IndexTab = function()
    return tbChannels2Index
end

ChatSetting.GetIndex2ChannelsTab = function()
    return tbIndex2Channels
end



-- 发送频道列表
ChatSetting.bSendChannelScrollEnable = false -- 发送频道是否可以滚动
ChatSetting.bMiniChatSwitchScrollEnable = true -- 迷你面板的切换是否可以滚动
ChatSetting.tbSendChannelIDList =
{
    PLAYER_TALK_CHANNEL.NEARBY,
    PLAYER_TALK_CHANNEL.WORLD,
    PLAYER_TALK_CHANNEL.SENCE,
    PLAYER_TALK_CHANNEL.TEAM,
    PLAYER_TALK_CHANNEL.RAID,
    PLAYER_TALK_CHANNEL.ROOM,
    PLAYER_TALK_CHANNEL.TONG,
    PLAYER_TALK_CHANNEL.TONG_ALLIANCE,
    PLAYER_TALK_CHANNEL.FORCE,
    PLAYER_TALK_CHANNEL.CAMP,
    PLAYER_TALK_CHANNEL.FRIENDS,
    PLAYER_TALK_CHANNEL.ALL_WORLD_CHAT,
    PLAYER_TALK_CHANNEL.IDENTITY,
    PLAYER_TALK_CHANNEL.BATTLE_FIELD,
    PLAYER_TALK_CHANNEL.BATTLE_FIELD_SIDE,
    PLAYER_TALK_CHANNEL.VOICE_ROOM,
    PLAYER_TALK_CHANNEL.DUNGEON_BULLET_SCREEN,
}


-- 版本号
ChatSetting.nVersion = 11

















--[[
PLAYER_TALK_CHANNEL.NEARBY                   = 1    -- 近聊
PLAYER_TALK_CHANNEL.TEAM                     = 2    -- 队伍
PLAYER_TALK_CHANNEL.RAID                     = 3    -- 团队
PLAYER_TALK_CHANNEL.BATTLE_FIELD             = 4    -- 战场
PLAYER_TALK_CHANNEL.SENCE                    = 5    -- 地图
PLAYER_TALK_CHANNEL.WHISPER                  = 6    -- 密聊
PLAYER_TALK_CHANNEL.FACE                     = 7    --
PLAYER_TALK_CHANNEL.GM_MESSAGE               = 8
PLAYER_TALK_CHANNEL.LOCAL_SYS                = 9
PLAYER_TALK_CHANNEL.GLOBAL_SYS               = 10
PLAYER_TALK_CHANNEL.GM_ANNOUNCE              = 11
PLAYER_TALK_CHANNEL.TO_TONG_GM_ANNOUNCE      = 12
PLAYER_TALK_CHANNEL.TO_PLAYER_GM_ANNOUNCE    = 13
PLAYER_TALK_CHANNEL.NPC_NEARBY               = 14   -- NPC相关
PLAYER_TALK_CHANNEL.NPC_PARTY                = 15
PLAYER_TALK_CHANNEL.NPC_SENCE                = 16
PLAYER_TALK_CHANNEL.NPC_WHISPER              = 17
PLAYER_TALK_CHANNEL.NPC_SAY_TO               = 18
PLAYER_TALK_CHANNEL.NPC_YELL_TO              = 19
PLAYER_TALK_CHANNEL.NPC_FACE                 = 20
PLAYER_TALK_CHANNEL.NPC_SAY_TO_ID            = 21
PLAYER_TALK_CHANNEL.NPC_SAY_TO_CAMP          = 22
PLAYER_TALK_CHANNEL.STORY_NPC                = 23   -- 剧情相关
PLAYER_TALK_CHANNEL.STORY_NPC_YELL           = 24
PLAYER_TALK_CHANNEL.STORY_NPC_WHISPER        = 25
PLAYER_TALK_CHANNEL.STORY_NPC_SAY_TO         = 26
PLAYER_TALK_CHANNEL.STORY_NPC_YELL_TO        = 27
PLAYER_TALK_CHANNEL.STORY_PLAYER             = 28
PLAYER_TALK_CHANNEL.TONG                     = 29   -- 帮会
PLAYER_TALK_CHANNEL.TONG_ALLIANCE            = 30   -- 帮会同盟
PLAYER_TALK_CHANNEL.TONG_SYS                 = 31   -- 帮会系统
PLAYER_TALK_CHANNEL.WORLD                    = 32   -- 世界
PLAYER_TALK_CHANNEL.FORCE                    = 33   -- 门派
PLAYER_TALK_CHANNEL.CAMP                     = 34   -- 阵营
PLAYER_TALK_CHANNEL.MENTOR                   = 35   -- 师徒
PLAYER_TALK_CHANNEL.FRIENDS                  = 36   -- 好友
PLAYER_TALK_CHANNEL.DEBUG_THREAT             = 37
PLAYER_TALK_CHANNEL.IDENTITY                 = 40   -- 萌新
PLAYER_TALK_CHANNEL.BULLET_SCREEN            = 42   -- 弹幕
PLAYER_TALK_CHANNEL.JJC_BULLET_SCREEN        = 43   -- 竞技场弹幕
PLAYER_TALK_CHANNEL.CAMP_FIGHT_BULLET_SCREEN = 44   -- 攻防弹幕
PLAYER_TALK_CHANNEL.BATTLE_FIELD_SIDE        = 47   -- 李渡鬼域
PLAYER_TALK_CHANNEL.SYSTEM_NOTICE            = 48   -- 系统
PLAYER_TALK_CHANNEL.ALL_WORLD_CHAT           = 49   -- 跨服
PLAYER_TALK_CHANNEL.ROOM                     = 50   -- 房间
PLAYER_TALK_CHANNEL.VOICE_ROOM               = 51   -- 语音房间
PLAYER_TALK_CHANNEL.DUNGEON_BULLET_SCREEN    = 52   -- 副本弹幕
]]
