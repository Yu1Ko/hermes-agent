-- 竞技场排队相关的界面和逻辑
ServerRobotArena = ServerRobotArena or {}

BtnType =
{
    EdixtBox = 1,
    Dropdown = 2,
    Toggle = 3
}

-- 跨服PVP配置
local _PVPFieldSet = {
	dwMapID = 0,
	nCopyIndex = 0,
}

local _ArenaSet = {
	nArenaLevel = 0,
	nCorpsType = 0,
	szTip = "2VS2",
}


-- 战场配置
local _BattleFieldSet = {
	dwMapID = 0,
	szMapName = "",
	nTeam = 0,
}

function ServerRobotArena.GetPVPFieldSetting()
	return _PVPFieldSet.dwMapID, _PVPFieldSet.nCopyIndex
end

function ServerRobotArena.SetPVPFieldSetting(dwMapID, nCopyIndex)
	_PVPFieldSet.dwMapID = dwMapID
	_PVPFieldSet.nCopyIndex = nCopyIndex
end

function ServerRobotArena.GetArenaSetting()
	return _ArenaSet.nArenaLevel, _ArenaSet.nCorpsType, _ArenaSet.szTip
end


function ServerRobotArena.SetArenaSetting(nArenaLevel, nCorpsType, szTip)
	_ArenaSet.nArenaLevel = nArenaLevel
	_ArenaSet.nCorpsType = nCorpsType
	_ArenaSet.szTip = szTip
end

function ServerRobotArena.GetBattleFieldSetting()
	return _BattleFieldSet.dwMapID, _BattleFieldSet.nTeam, _BattleFieldSet.szMapName
end

function ServerRobotArena.SetBattleFieldSetting(dwMapID, nTeam, szMapName)
	_BattleFieldSet.dwMapID = dwMapID
	_BattleFieldSet.nTeam = nTeam
	_BattleFieldSet.szMapName = szMapName
end

ServerRobotArena.szTitle = "竞技战场"
ServerRobotArena.tbArenaQueueSetting = {
    {
        szlabel = "进行PVP跨服排队",
        bNeedBtn = true,
        tbSubPanel = {
            szTitle = "跨服PVP配置",
            tbPanelConfig = {
                {
                    szText = "地图ID:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "dwMapID",
                    szDefaultValue = 0
                },
                {
                    szText = "CopyIndex:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "nCopyIndex",
                    szDefaultValue = 0
                },
            },

        },
        tbCMDParams = {
            dwMapID = 0,
            nCopyIndex = 0,
        },
        fnCallBack = function (PVPField)
            local dwMapID =  PVPField.dwMapID
            local nCopyIndex = PVPField.nCopyIndex
            if dwMapID == 0 then
                OutputMessage("MSG_ANNOUNCE_RED", "请先设置需要排哪个战场！")
                return
            end
            local szMsg = string.format("custom:LY_JoinPVPFieldQueue(%d, %d)", dwMapID, nCopyIndex)
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
            ServerRobotArena.SetPVPFieldSetting(dwMapID, nCopyIndex)
        end
    },
    {
        szlabel = "离开PVP跨服排队",
        bNeedBtn = false,
        fnCallBack = function ()
            local dwMapID, nCopyIndex = ServerRobotArena.GetPVPFieldSetting()
            if dwMapID == 0 then
                OutputMessage("MSG_ANNOUNCE_RED", "请先设置需要排哪个战场！")
                return
            end
            local  szMsg = string.format("custom:LY_LeavePVPFieldQueue(%d, %d)", dwMapID, nCopyIndex)
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "退出PVP跨服地图",
        bNeedBtn = false,
        fnCallBack = function ()
            local  szMsg = string.format("custom:LY_LeavePVPField()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "帮会联赛报名",
        bNeedBtn = false,
        fnCallBack = function ()
            local szMsg = string.format("custom:SignUpBFTongLeague(0)")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "帮会联赛练习赛报名",
        bNeedBtn = false,
        fnCallBack = function ()
            local szMsg = string.format("custom:SignUpBFTongLeague(1)")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "帮会联赛退出地图",
        bNeedBtn = false,
        fnCallBack = function ()
            local szMsg =  string.format("custom:LeaveBattleField()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "结束帮会联赛",
        bNeedBtn = false,
        fnCallBack = function ()
            local szMsg =  string.format("g_m:ChangePQValue(player.GetScene().GetCustomInteger4(2),0,1)")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        --创建JJC个人ID，新号必须创建一次
        szlabel = "注册JJC_ID",
        bNeedBtn = false,
        fnCallBack = function ()
            local szMsg =  string.format("custom:CreateCorpsRoleSystemID()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "竞技场排队",
        bNeedBtn = true,
        tbSubPanel = {
            szTitle = "竞技场配置",
            tbPanelConfig = {
                {
                    szText = "匹配类型:",
                    nBtnType = BtnType.Dropdown,
                    tbDropdownSelect = {
                        {szlabel = "2VS2",  nValue = 0},
                        {szlabel = "3VS3",  nValue = 1},
                        {szlabel = "5VS5",  nValue = 2},
                        {szlabel = "大师赛2VS2", nValue = 3},
                        {szlabel = "大师赛3VS3", nValue = 4},
                        {szlabel = "大师赛5VS5", nValue = 5}
                    },
                    szKey = "dwJJCType",
                    szDefaultTitle = "3VS3",
                    szDefaultValue = 1
                },
                {
                    szText = "是否散排:",
                    nBtnType = BtnType.Toggle,
                    szKey = "bSingle",
                    szDefaultValue = false
                },
                {
                    szText = "竞技类型:",
                    nBtnType = BtnType.Dropdown,
                    tbDropdownSelect = {
                        {szlabel = "正式赛", nValue = 1},
                        {szlabel = "人机练习Lv1", nValue = 2},
                        {szlabel = "人机练习Lv2", nValue = 3},
                        {szlabel = "人机练习Lv3", nValue = 4}
                    },
                    szKey = "dwGameType",
                    szDefaultTitle = "正式赛",
                    szDefaultValue = 1
                },
                {
                    szText = "是否录像:",
                    nBtnType = BtnType.Toggle,
                    szKey = "bRecord",
                    szDefaultValue = false
                },
            },

        },
        tbCMDParams = {
            dwJJCType = 0,
            bSingle = false,
            dwGameType = 1,
            bRecord = false
        },
        fnCallBack = function (_ArenaQueueSet)
            
            local szMsg = string.format("custom:JoinArenaQueue(%d, %s, %d, %s)", _ArenaQueueSet.dwJJCType, tostring(_ArenaQueueSet.bSingle), _ArenaQueueSet.dwGameType, tostring(_ArenaQueueSet.bRecord))
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "退出竞技场排队",
        bNeedBtn = false,
        fnCallBack = function ()
            local szMsg = string.format("custom:LeaveArenaQueue()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },

    {
        szlabel = "竞技场拉黑目标",
        bNeedBtn = false,
        fnCallBack = function ()
            local player 			= player or GetClientPlayer()
            local eTargetType, dwID = player.GetTarget()
            if eTargetType ~= TARGET.PLAYER then
                OutputMessage('MSG_ANNOUNCE_RED', "没有设定拉黑玩家，AddArenaBlackList执行失败\n")
                return false
            end
            -- 目标已经获取到了，指定通过密聊频道，给机器人发送指令
            SetTarget(TARGET.NO_TARGET, 0)
            OutputMessage("MSG_SYS", "机器人密聊设置里，指定的机器人都可以收到该指令\n")
            local szMsg = string.format("g_m:AddPlayerToArenaBlackList(player.dwID, GetPlayer(%d).GetGlobalID())", dwID)
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
    {
        szlabel = "取消拉黑目标",
        bNeedBtn = false,
        tbCMDParams = {},
        fnCallBack = function ()
            local player 			= player or GetClientPlayer()
            local eTargetType, dwID = player.GetTarget()     
            if eTargetType ~= TARGET.PLAYER then
                OutputMessage('MSG_ANNOUNCE_RED', "没有设定反拉黑玩家，RemoveFromBlackList执行失败\n")
                return false
            end
            -- 目标已经获取到了，指定通过密聊频道，给机器人发送指令
            SetTarget(TARGET.NO_TARGET, 0)
            OutputMessage("MSG_SYS", "机器人密聊设置里，指定的机器人都可以收到该指令\n")
            local szCmd = string.format("RemoveFromBlackList('\" .. player.GetGlobalID().. \"', '\".. GetPlayer(%d).GetGlobalID() ..\"')", dwID)
            local szCmdtext = "g_m:GCCommand(\"SendGMCommondArenaServer(\\\""..szCmd.."\\\")\")"
            local szMsg = szCmdtext
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },

    {
        szlabel = "设置jjc段位",
        bNeedBtn = true,
        tbSubPanel = {
            szTitle = "竞技场段位配置",
            tbPanelConfig = {
                {
                    szText = "匹配类型:",
                    nBtnType = BtnType.Dropdown,
                    tbDropdownSelect = {
                        {szlabel = "2VS2",  nValue = 0},
                        {szlabel = "3VS3",  nValue = 1},
                        {szlabel = "5VS5",  nValue = 2},
                    },
                    szKey = "nCorpsType",
                    szDefaultTitle = "2VS2",
                    szDefaultValue = 0
                },
                {
                    szText = "段位:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "nArenaLevel",
                    szDefaultValue = 0
                },
            },
        },
        tbCMDParams = {
            nCorpsType = 0,
            nArenaLevel = 0,
        },
        fnCallBack = function (ArenaSetting)
            --0-2V2	1-3V3	2-5V5
            -- local nArenaLevel, nCorpsType, szTip = ServerRobotArena.GetArenaSetting()
            local nArenaLevel =  ArenaSetting.nArenaLevel
            local nCorpsType = ArenaSetting.nCorpsType
            if tonumber(nArenaLevel) < 0 or tonumber(nArenaLevel) > 11 then
                OutputMessage("MSG_ANNOUNCE_RED", "JJC段位区间为0-11！！！")
                return
            end
            local szMsg = string.format("custom:LY_SetArenaLevel(%d, %d)",nArenaLevel, nCorpsType)
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },

    {
        szlabel = "设置JJC赛季信息",
        bNeedBtn = false,
        tbCMDParams = {},
        fnCallBack = function ()
            local szMsg = string.format("custom:LY_RandomSetAllJJCArenaLevel()")
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },

    {
        szlabel = "战场排队",
        bNeedBtn = true,
        tbSubPanel = {
            szTitle = "战场配置",
            tbPanelConfig = {
                {
                    szText = "地图ID:",
                    nBtnType = BtnType.Dropdown,
                    tbDropdownSelect = {
                        -- 临时的几个图
                        {szlabel = "三国古战场",  nValue = 135},
                        {szlabel = "龙门寻宝",  nValue = 296},
                        {szlabel = "海岛绝境",  nValue = 410},
                        {szlabel = "白龙绝境",  nValue = 512},
                        {szlabel = "天原绝境",  nValue = 532},
                        {szlabel = "李渡城",  nValue = 322},
                        {szlabel = "列星岛",  nValue = 412},
                        {szlabel = "帮会联赛", nValue = 515},
                        {szlabel = "帮会联赛_练习赛",  nValue = 515},
                        {szlabel = "羊村大作战", nValue = 589},
                        {szlabel = "洱海绝境", nValue = 645},
                        {szlabel = "黑山林海", nValue = 709},
                        {szlabel = "黑山林海_纷争", nValue = 715},
                    },
                    szKey = "dwMapID",
                    szDefaultTitle = "三国古战场",
                    szDefaultValue = 135
                },
                {
                    szText = "是否队伍:",
                    nBtnType = BtnType.EdixtBox,
                    szKey = "nTeam",
                    szDefaultValue = 0
                }
            },

        },
        tbCMDParams = {
            dwMapID = 135,
            nTeam = 0
        },
        fnCallBack = function (BattleFieldSetting)
            -- local dwMapID, nTeam, szMapName = ServerRobotArena.GetBattleFieldSetting()
            local dwMapID = BattleFieldSetting.dwMapID
            local nTeam = BattleFieldSetting.nTeam
            -- local szMapName = BattleFieldSetting.szMapName
            if dwMapID == 0 then
                OutputMessage("MSG_ANNOUNCE_RED", "请先设置需要排哪个战场！")
                return
            end
            local szMsg = string.format("custom:JoinBattleFieldQueue(%d, 0, %d, 0)",dwMapID, nTeam)
            if dwMapID == 515 then
                szMsg = string.format("custom:JoinBattleFieldQueue(%d, 0, %d, 1)",dwMapID, nTeam)
            end
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
            ServerRobotArena.SetBattleFieldSetting(dwMapID, nTeam)
        end
    },
    {
        szlabel = "退出战场排队",
        bNeedBtn = false,
        fnCallBack = function ()
            local dwMapID, _ = ServerRobotArena.GetBattleFieldSetting()
            if dwMapID == 0 then
                OutputMessage("MSG_ANNOUNCE_RED", "请先设置需要排哪个战场！")
                return
            end
            local szMsg = string.format("custom:LeaveBattleFieldQueue(%d)", dwMapID)
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
            SearchRobot:SendCustomMessage(szMsg, 2)
        end
    },
}


