-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: BuffMonitorData
-- Date: 2025-02-08 10:18:13
-- Desc: 类似茗伊插件的Buff监控插件，在jjc中角色名字那里显示
-- ---------------------------------------------------------------------------------

BuffMonitorData = BuffMonitorData or {className = "BuffMonitorData"}
local self = BuffMonitorData

local tMonitorBuffList = {
    70192, --定身
    70193, --眩晕
    70196, --锁足
    70199, --内功沉默
    70200, --外功沉默
    70201, --轻功沉默
    70202, --缴械
    70205, --禁疗
    70884, --倒地
}

local KNOCKED_DOWN_BUFF_ID = 70884 --倒地BuffID

BuffMonitorData.bEnableBuffMonitor = false

function BuffMonitorData.Init()
    self.RegEvent()

    self.tPlayerShownBuff = {}
    self._sortBuffList()

    Timer.AddFrameCycle(self, 1, function()
        self._updateBuffMonitor()
    end)
end

function BuffMonitorData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function BuffMonitorData.RegEvent()
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self.CheckEnableBuffMonitor()
    end)
    Event.Reg(self, "BUFF_UPDATE", function()
        local owner, bdelete, index, cancancel, id, stacknum, endframe, binit, level, srcid, isvalid, leftframe = arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11
        if IsPlayer(owner) and table.contain_value(tMonitorBuffList, id) then
            self._updateBuffMonitor()
        end
    end)
    Event.Reg(self, "PLAYER_LEAVE_SCENE", function(dwPlayerID)
        self.tPlayerShownBuff[dwPlayerID] = nil
    end)
    Event.Reg(EventType.OnChangeTopBuffSetting, function()
        self.CheckEnableBuffMonitor()
    end)
end

function BuffMonitorData._sortBuffList()
    table.sort(tMonitorBuffList, function(dwBuffID1, dwBuffID2)
        local tBuff1 = Table_GetBuff(dwBuffID1, 1) assert(tBuff1)
        local tBuff2 = Table_GetBuff(dwBuffID2, 1) assert(tBuff2)

        local tCatalog1 = UIBuffCatalogInfoTab[tBuff1.nCatalog] assert(tCatalog1)
        local tCatalog2 = UIBuffCatalogInfoTab[tBuff2.nCatalog] assert(tCatalog2)

        return tCatalog1.nPriority > tCatalog2.nPriority
    end)

    -- print_table(tMonitorBuffList)
end

function BuffMonitorData.CheckEnableBuffMonitor()
    if ArenaData.IsInArena() and GameSettingData.GetNewValue(UISettingKey.ShowArenaHeadBuff) then
        self.EnableBuffMonitor()
    else
        self.DisableBuffMonitor()
    end
end

function BuffMonitorData.EnableBuffMonitor()
    self.bEnableBuffMonitor = true
    self._updateBuffMonitor()
end

function BuffMonitorData.DisableBuffMonitor()
    self.bEnableBuffMonitor = false
    self._clearBuffMonitor()
end

function BuffMonitorData._clearBuffMonitor()
    local tAllPlayer = PlayerData.GetAllPlayer()
    for dwPlayerID, player in pairs(tAllPlayer or {}) do
        -- rlcmd("set caption extra text " .. dwPlayerID)
        rlcmd("set character display name " .. dwPlayerID)
        rlcmd("set plugin caption color " .. dwPlayerID .. " 0")
    end
    self.tPlayerShownBuff = {}
end

function BuffMonitorData._updateBuffMonitor()
    if not self.bEnableBuffMonitor then
        return
    end

    local hTeam = GetClientTeam()
    if not hTeam then
        return
    end
    local tMembers = {}
    hTeam.GetTeamMemberList(tMembers)

    local tAllPlayer = PlayerData.GetAllPlayer()
    for dwPlayerID, player in pairs(tAllPlayer or {}) do
        local bHaveBuff = false
        for _, dwBuffID in ipairs(tMonitorBuffList) do

            --NOTE: player.IsHaveBuff这个接口无法实时获取到未选中的目标身上的实际Buff状态，只有选中目标的时候这个状态才能正确同步下来
            if player.IsHaveBuff(dwBuffID, 0) then
                local szBuffName = Table_GetBuffName(dwBuffID, 1)
                local szText = szBuffName

                local nLeftTime

                local tBuffTimeData = {}
                Buffer_GetByID(player, dwBuffID, 0, tBuffTimeData)
                if tBuffTimeData.dwID and tBuffTimeData.nEndFrame then
                    nLeftTime = tBuffTimeData.nEndFrame and (BuffMgr.GetLeftFrame(tBuffTimeData) / GLOBAL.GAME_FPS)
                end

                --特殊处理，倒地要根据被击倒状态来获取
                if dwBuffID == KNOCKED_DOWN_BUFF_ID then
                    nLeftTime = player.nMoveState == MOVE_STATE.ON_KNOCKED_DOWN and player.nMoveFrameCounter / GLOBAL.GAME_FPS or 0
                end

                if nLeftTime then
                    szText = szBuffName .. "_" .. math.ceil(nLeftTime) .. "\""
                end

                bHaveBuff = true

                if self.tPlayerShownBuff[dwPlayerID] ~= szText then
                    self.tPlayerShownBuff[dwPlayerID] = szText

                    -- rlcmd("set caption extra text " .. dwPlayerID .. " " .. szText)
                    rlcmd("set character display name " .. dwPlayerID .. " " .. szText)
                    if table.contain_value(tMembers, dwPlayerID) or dwPlayerID == UI_GetClientPlayerID() then
                        rlcmd("set plugin caption color " .. dwPlayerID .. " 1 " .. 4294732799) --颜色16进制转10进制
                    end
                end

                break
            end
        end
        if not bHaveBuff and self.tPlayerShownBuff[dwPlayerID] then
            self.tPlayerShownBuff[dwPlayerID] = nil
            -- rlcmd("set caption extra text " .. dwPlayerID)
            rlcmd("set character display name " .. dwPlayerID)
            rlcmd("set plugin caption color " .. dwPlayerID .. " 0")
        end
    end
end