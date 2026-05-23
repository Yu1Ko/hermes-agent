-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityActityCell
-- Date: 2024-01-18 16:54:47
-- Desc: ?
-- ---------------------------------------------------------------------------------
local szWeekImgBgPath = "UIAtlas2_HomeIdentify_HomeIdentify_Img_Order_Week.png"
local UIHomelandIdentityActityCell = class("UIHomelandIdentityActityCell")

function UIHomelandIdentityActityCell:OnEnter(tTaskData, tTaskInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tTaskData = tTaskData
    self.tTaskInfo = tTaskInfo
    self:UpdateInfo()
end

function UIHomelandIdentityActityCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityActityCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function(btn)
        local tTaskInfo         = self.tTaskInfo
        if string.is_nil(tTaskInfo.szLink) then
            return
        end

        FireUIEvent("EVENT_LINK_NOTIFY", tTaskInfo.szLink)

        if self.tTaskInfo.bWeekly then
            Event.Dispatch(EventType.OnHomeOrderSelectedCellIndex, 2)
        end
    end)

end

function UIHomelandIdentityActityCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandIdentityActityCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandIdentityActityCell:UpdateInfo()
    local tTaskData         = self.tTaskData
    local tTaskInfo         = self.tTaskInfo
    local nCurVal   = tTaskData.nCurVal or 0
    local nTotalVal = tTaskData.nTotal or 0
    local szName    = UIHelper.GBKToUTF8(tTaskInfo.szName) or ""
    if tTaskData.bFinish then
        UIHelper.SetVisible(self.LabelOrderNum, false)
        UIHelper.SetVisible(self.ImgComplete, true)
    end
    UIHelper.SetString(self.LabelOrder, szName)
    UIHelper.SetString(self.LabelOrderNum, nCurVal .. "/" .. nTotalVal)
    UIHelper.SetString(self.LabelTab, tTaskInfo.bWeekly and "周常" or "日常")
    if tTaskInfo.bWeekly then
        UIHelper.SetSpriteFrame(self.ImgTab, szWeekImgBgPath)
    end

    if string.is_nil(tTaskInfo.szLink) then
        UIHelper.SetVisible(self.BtnGo, false)
    else
        UIHelper.SetVisible(self.BtnGo, true)
    end
end


return UIHomelandIdentityActityCell