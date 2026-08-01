-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipSplit
-- Date: 2023-11-21 10:44:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipSplit = class("UIItemTipSplit")

-- 限制拆分最大组数量，防止发送协议太多触发掉线
local MaxSplitCount = 100

function UIItemTipSplit:OnEnter(nBox, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nBox = nBox
    self.nIndex = nIndex

    local item = ItemData.GetItemByPos(self.nBox, self.nIndex)
    self.nStackNum = ItemData.GetItemStackNum(item)

    UIHelper.SetText(self.EditPaginateCount, "1")
    UIHelper.SetText(self.EditPaginateGroup, "1")

    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginateCount, TextHAlignment.CENTER)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginateGroup, TextHAlignment.CENTER)

    UIHelper.SetTouchDownHideTips(self.EditPaginateCount, false)
    UIHelper.SetTouchDownHideTips(self.EditPaginateGroup, false)
    UIHelper.SetTouchDownHideTips(self.BtnSplit, false)
    UIHelper.SetTouchDownHideTips(self.BtnCancel, false)

    self:UpdateInfo()
end

function UIItemTipSplit:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIItemTipSplit:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSplit, EventType.OnClick,function ()
        local nPreGroupNum = tonumber(UIHelper.GetText(self.EditPaginateCount))
        local nGroupCount = tonumber(UIHelper.GetText(self.EditPaginateGroup))

        if self.fnCallback then
            self.fnCallback(true, nPreGroupNum, nGroupCount)
        end
        
        Event.Dispatch(EventType.HideAllHoverTips) -- 拆分后背包不显示Itemtip
    end)
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        local nPreGroupNum = tonumber(UIHelper.GetText(self.EditPaginateCount))
        local nGroupCount = tonumber(UIHelper.GetText(self.EditPaginateGroup))

        if self.fnCallback then
            self.fnCallback(false, nPreGroupNum, nGroupCount)
        end
    end)

    local fnCorrectEditBoxNum = function ()
        local nPreGroupNum = tonumber(UIHelper.GetText(self.EditPaginateCount))
        local nGroupCount = tonumber(UIHelper.GetText(self.EditPaginateGroup))

        if not nPreGroupNum or not nGroupCount then
            return
        end

        if nPreGroupNum > self.nStackNum then
            nPreGroupNum = self.nStackNum
            UIHelper.SetText(self.EditPaginateCount, nPreGroupNum)
        end

        local maxGroupCount = math.floor(self.nStackNum / nPreGroupNum)
        maxGroupCount = math.min(maxGroupCount, MaxSplitCount)
        if nGroupCount > maxGroupCount then
            nGroupCount = maxGroupCount
            UIHelper.SetText(self.EditPaginateGroup, nGroupCount)
        end
    end

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginateGroup, function()
            fnCorrectEditBoxNum()
        end)
        UIHelper.RegisterEditBoxEnded(self.EditPaginateCount, function()
            fnCorrectEditBoxNum()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginateGroup, function()
            fnCorrectEditBoxNum()
        end)
        UIHelper.RegisterEditBoxReturn(self.EditPaginateCount, function()
            fnCorrectEditBoxNum()
        end)
    end
end



function UIItemTipSplit:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox == self.EditPaginateCount then
            UIHelper.SetEditBoxGameKeyboardRange(self.EditPaginateCount, 1, self.nStackNum)
        elseif editbox == self.EditPaginateGroup then
            local nPreGroupNum = tonumber(UIHelper.GetText(self.EditPaginateCount))
            UIHelper.SetEditBoxGameKeyboardRange(self.EditPaginateGroup, 1, math.floor(self.nStackNum / nPreGroupNum))
        end
    end)
end

function UIItemTipSplit:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIItemTipSplit:UpdateInfo()

end

function UIItemTipSplit:SetCallback(fnCallback)
    self.fnCallback = fnCallback
end

return UIItemTipSplit