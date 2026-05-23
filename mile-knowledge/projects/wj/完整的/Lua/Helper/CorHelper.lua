CorHelper = CorHelper or {nCount = 1, tbCorMap = {}}
local self = CorHelper

local WaitType =
{
    UIOpen = 1,
    UIClose = 2,
    Event = 3,
    QuestCompleted = 4,
    AchievementCompleted = 5,
    Time = 6,
    Frame = 7,
}









--[[
    用法

    CorHelper.Start(function()
        CorHelper.Wait_UIOpen(VIEW_ID.PanelPetMap)
        -- TODO after PanelPetMap ui open
        CorHelper.Wait_Event(EventType.PlayAnimMainCityShow)
        -- TODO after PlayAnimMainCityShow event dispatched
        CorHelper.Wait_Time(0.3)
        -- TODO after 0.3s
        CorHelper.Wait_QuestCompleted(1011)
        -- TODO after quest 1011 completed
    end)
]]

--- 开启协程
function CorHelper.Start(func)
	local cor = coroutine.create(func)
    self.tbCorMap[cor] = {}

	local ok, err = CorHelper._resume(cor)
	if ok == false then
		LOG.ERROR("CorHelper Coroutine Error:%s, %s", err, debug.traceback())
	end

    return cor
end

--- 暂停协程
function CorHelper._yield(...)
	coroutine.yield(...)
end

--- 恢复协程
function CorHelper._resume(cor, ...)
    if not cor or coroutine.status(cor) ~= "suspended" then
        return
    end

	local ok, p1, p2 = coroutine.resume(cor, ...)
    if ok then
        if coroutine.status(cor) == "dead" then
            self.tbCorMap[cor] = nil
            return
        end

        local tb = self.tbCorMap[cor]
        if not tb then
            return
        end

        if p1 == WaitType.UIOpen then
            local nViewID = p2
            Event.Reg(tb, EventType.OnViewOpen, function(_nViewID)
                if nViewID == _nViewID then
                    Event.UnReg(tb, EventType.OnViewOpen)
                    CorHelper._resume(cor)
                end
            end)
        elseif p1 == WaitType.UIClose then
            local nViewID = p2
            Event.Reg(tb, EventType.OnViewClose, function(_nViewID)
                if nViewID == _nViewID then
                    Event.UnReg(tb, EventType.OnViewClose)
                    CorHelper._resume(cor)
                end
            end)
        elseif p1 == WaitType.Event then
            local szEventType = p2
            Event.Reg(tb, szEventType, function(...)
                Event.UnReg(tb, szEventType)
                CorHelper._resume(cor)
            end)
        elseif p1 == WaitType.QuestCompleted then
            local nQuestID = p2
            Event.Reg(tb, "QUEST_FINISHED", function(_nQuestID, bForceFinish, bAssist, nAddStamina, nAddThew)
                if nQuestID == _nQuestID then
                    Event.UnReg(tb, "QUEST_FINISHED")
                    CorHelper._resume(cor)
                end
            end)
        elseif p1 == WaitType.AchievementCompleted then
            local dwAchievement = p2
            Event.Reg(tb, "NEW_ACHIEVEMENT", function(_dwAchievement)
                if dwAchievement == _dwAchievement then
                    Event.UnReg(tb, "NEW_ACHIEVEMENT")
                    CorHelper._resume(cor)
                end
            end)
        elseif p1 == WaitType.Time then
            local nTime = p2
            Timer.DelAllTimer(tb)
            Timer.Add(tb, nTime, function()
                CorHelper._resume(cor)
            end)
        elseif p1 == WaitType.Frame then
            local nFrame = p2
            Timer.DelAllTimer(tb)
            Timer.Add(tb, nFrame, function()
                CorHelper._resume(cor)
            end)
        end
    else
		LOG.ERROR("CorHelper Coroutine Error:%s, %s", err, debug.traceback(cor) .. debug.traceback():sub(17))
        self.tbCorMap[cor] = nil
	end
	return ok, err
end







function CorHelper.Wait_UIOpen(nViewID)
    CorHelper._yield(WaitType.UIOpen, nViewID)
end

function CorHelper.Wait_UIClose(nViewID)
    CorHelper._yield(WaitType.UIClose, nViewID)
end

function CorHelper.Wait_Event(szEventType)
    CorHelper._yield(WaitType.Event, szEventType)
end

function CorHelper.Wait_QuestCompleted(nQuestID)
    CorHelper._yield(WaitType.QuestCompleted, nQuestID)
end

function CorHelper.Wait_AchievementCompleted(dwAchievement)
    CorHelper._yield(WaitType.AchievementCompleted, dwAchievement)
end

function CorHelper.Wait_Time(nTime)
    CorHelper._yield(WaitType.Time, nTime)
end

function CorHelper.Wait_Frame(nFrame)
    CorHelper._yield(WaitType.Frame, nFrame)
end