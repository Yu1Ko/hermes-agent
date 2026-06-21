-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: OutMap
-- Date: 2024-04-22 11:32:18
-- Desc: 搬运端游OutMap.lua低活跃度投票
-- ---------------------------------------------------------------------------------

OutMap = OutMap or {className = "OutMap"}
local self = OutMap

local tDelayShow = {}

function OutMap.Init()
    self.RegEvent()
end

function OutMap.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function OutMap.RegEvent()
    Event.Reg(self, "VOTE_CASTLE_FIGHT_ACTIVITY_LOW", function(dwPlayerID, szPlayerName, nLevel, nRoleType, nForce, nTongID, nGainTitlePoint, nPosX, nPosY, nPosZ, nTitleLevel, nScores)
        self.OpenOutMap(dwPlayerID, szPlayerName, nLevel, nRoleType, nForce, nTongID, nGainTitlePoint, nPosX, nPosY, nPosZ, nTitleLevel, nScores)
    end)
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelAnswerMapPop and #tDelayShow > 0 then
            for k, v in pairs(tDelayShow) do
                local dwPlayerID, szPlayerName, nLevel, nRoleType, nForce, nTongID, nGainTitlePoint, nPosX, nPosY, nPosZ, nTitleLevel, nScores = v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9], v[10], v[11], v[12]
                Timer.AddFrame(self, 1, function()
                    self.OpenOutMap(dwPlayerID, szPlayerName, nLevel, nRoleType, nForce, nTongID, nGainTitlePoint, nPosX, nPosY, nPosZ, nTitleLevel, nScores)
                end)
                table.remove(tDelayShow, k)
                break
            end
        end
    end)
end

function OutMap.OpenOutMap(dwPlayerID, szPlayerName, nLevel, nRoleType, nForce, nTongID, nGainTitlePoint, nPosX, nPosY, nPosZ, nTitleLevel, nScores)
    if UIMgr.IsViewOpened(VIEW_ID.PanelAnswerMapPop) then
        table.insert(tDelayShow, {dwPlayerID, szPlayerName, nLevel, nRoleType, nForce, nTongID, nGainTitlePoint, nPosX, nPosY, nPosZ, nTitleLevel, nScores})
        return
    end

    UIMgr.Open(VIEW_ID.PanelAnswerMapPop, dwPlayerID, szPlayerName, nLevel, nRoleType, nForce, nTongID, nGainTitlePoint, nPosX, nPosY, nPosZ, nTitleLevel, nScores)
end