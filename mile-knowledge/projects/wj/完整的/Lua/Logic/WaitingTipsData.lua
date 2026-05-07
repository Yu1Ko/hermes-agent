-- ---------------------------------------------------------------------------------
-- Author: luwenhao
-- Name: WaitingTipsData
-- Date: 2024-01-05 10:45:04
-- Desc: 等待提示通用接口
-- ---------------------------------------------------------------------------------

WaitingTipsData = WaitingTipsData or {className = "WaitingTipsData"}
local self = WaitingTipsData

function WaitingTipsData.Init()
    self.m = {}
    self.m.tMsgArr = {}

    self.RegEvent()
end

function WaitingTipsData.UnInit()
    self.StopUpdate()
    self.m = nil

    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function WaitingTipsData.RegEvent()
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelLoginLineUp then
            self.m.bPanelOpened = false
            Timer.AddFrame(self, 1, self.UpdateWaitingPanel)
        end
    end)
end

--[[
tMsg = {
    szType = "LoginWaiting",                -- 类型(用于排重)
    nPriority = 0,                          -- 显示优先级, 值越大越优先显示，默认为0
    szWaitingMsg = "Loading...",            -- 文本提示
    fnCancelCallback = fnCancelCallback,    -- 显示取消按钮及点击取消按钮后执行的事件
    bHidePage = false,                      -- 是否隐藏UI的Page层
    bSwallow = false,                       -- 是否吞噬点击事件，默认为false
}
--]]

function WaitingTipsData.PushWaitingTips(tMsg)
    if not tMsg then return end
    local arr = self.m and self.m.tMsgArr
    if not arr then return end

    -- 排重
    local tOld = self.GetMsgByType(tMsg.szType)
    if tOld and not tOld.bRemove then
        -- 刷新旧消息
        for k, v in pairs(tMsg) do
            tOld[k] = v
        end
    else
        table.insert(arr, tMsg)
    end

    -- sort
    Global.SortStably(arr, function (a, b)
        local nA = a.nPriority or 0
        local nB = b.nPriority or 0
        return nA <= nB
    end)

    self.UpdateWaitingPanel()

    self.StartUpdate()
end

function WaitingTipsData.RemoveWaitingTips(szType)
    local tMsg = self.GetMsgByType(szType)
    if tMsg then
        tMsg.bRemove = true
    end
end

function WaitingTipsData.RemoveAllWaitingTips()
    local arr = self.m and self.m.tMsgArr
    if not arr then return end
    for _, v in pairs(arr) do
        v.bRemove = true
    end
end

function WaitingTipsData.GetMsgByType(szType)
    local arr = self.m and self.m.tMsgArr
    if not arr then return end
    for _, v in pairs(arr) do
        if not v.bRemove and v.szType == szType then
            return v
        end
    end
end

function WaitingTipsData.StartUpdate()
	if not self.m.nCallId then
		self.m.nCallId = Timer.AddCycle(self, 0.3, self.OnUpdate)
	end
end
function WaitingTipsData.StopUpdate()
	if self.m.nCallId then
		Timer.DelTimer(self, self.m.nCallId)
		self.m.nCallId = nil
	end
end

function WaitingTipsData.OnUpdate()
    local arr = self.m and self.m.tMsgArr
    if not arr then return end
    local bHaveRemove = false
    for i = #arr, 1, -1 do
        local tMsg = arr[i]
        -- 移除被标记的消息
        if tMsg.bRemove then
            table.remove(arr, i)
            bHaveRemove = true
        end
    end

    --若等待界面还未打开，则等到打开再关掉
    if #arr == 0 and (not self.m.bPanelOpened or UIMgr.IsViewOpened(VIEW_ID.PanelLoginLineUp)) then
        UIMgr.Close(VIEW_ID.PanelLoginLineUp)
        self.StopUpdate()
    elseif bHaveRemove then
        self.UpdateWaitingPanel()
    end
end

function WaitingTipsData.UpdateWaitingPanel()
    local arr = self.m and self.m.tMsgArr
    if not arr then return end
    if #arr == 0 then
        return
    end

    local tMsg = arr[#arr]
    if not self.m.bPanelOpened then
        self.m.bPanelOpened = true
        UIMgr.Open(VIEW_ID.PanelLoginLineUp, tMsg)
    else
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelLoginLineUp)
        if scriptView then
            scriptView:UpdateInfo(tMsg)
        end
    end
end

function WaitingTipsData.GetCurWaitingTipsData()
    local arr = self.m and self.m.tMsgArr
    if not arr then return end
    return arr[#arr]
end