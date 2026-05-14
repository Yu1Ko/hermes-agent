-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIOperationNewInfoUpdate
-- Date: 2026-04-07 11:43:58
-- Desc: WidgetNewInfoUpdate
-- ---------------------------------------------------------------------------------

local UIOperationNewInfoUpdate = class("UIOperationNewInfoUpdate")

function UIOperationNewInfoUpdate:OnEnter(nOperationID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        -- self:InitUI()
    end

    self.nID = nID
    self.nOperationID = nOperationID
    self.tComponentContext = tComponentContext

    self:UpdateInfo()
end

function UIOperationNewInfoUpdate:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationNewInfoUpdate:BindUIEvent()
    
end

function UIOperationNewInfoUpdate:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationNewInfoUpdate:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- function UIOperationNewInfoUpdate:InitUI()
--     local nIndex = 1
--     local btn = UIHelper.GetChildByName(self.WidgetInfo, "ButtonMod" .. nIndex)
--     while btn do
--         local img = UIHelper.GetChildByName(btn, "ImgMod" .. nIndex)
--         local labelName = UIHelper.GetChildByName(btn, "LabelNameMod" .. nIndex)
--         local labelInfo = UIHelper.GetChildByName(btn, "LabelInfoMod" .. nIndex)
--         self["ButtonMod" .. nIndex] = btn
--         self["ImgMod" .. nIndex] = img
--         self["LabelNameMod" .. nIndex] = labelName
--         self["LabelInfoMod" .. nIndex] = labelInfo
--         nIndex = nIndex + 1
--         btn = UIHelper.GetChildByName(self.WidgetInfo, "ButtonMod" .. nIndex)
--     end
-- end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

-- self.tButtonMod
-- self.tImgMod
-- self.tLabelNameMod
-- self.tLabelInfoMod
function UIOperationNewInfoUpdate:UpdateInfo()
    -- ui/Scheme/Case/OperationActivity/SeasonUpdateOverview.txt
    local tOverviewInfo = Table_GetSeasonUpdateOverview(self.nOperationID)
    if not tOverviewInfo then
        return
    end

    local nZOrder = 0
    local nBtnCount = #self.tButtonMod
    for nIndex = 1, nBtnCount do
        local btn = self.tButtonMod[nIndex]
        local img = self.tImgMod[nIndex]
        local labelName = self.tLabelNameMod[nIndex]
        local labelInfo = self.tLabelInfoMod[nIndex]

        UIHelper.SetString(labelName, UIHelper.GBKToUTF8(tOverviewInfo["szTitle" .. nIndex]))
        UIHelper.SetString(labelInfo, UIHelper.GBKToUTF8(tOverviewInfo["szSubtitle" .. nIndex]))

        local szLink = tOverviewInfo["szLink" .. nIndex]
        UIHelper.UnBindUIEvent(btn, EventType.OnClick)
        UIHelper.UnBindUIEvent(btn, EventType.OnTouchBegan)
        UIHelper.BindUIEvent(btn, EventType.OnClick, function()
            Event.Dispatch("EVENT_LINK_NOTIFY", szLink)
        end)
        UIHelper.BindUIEvent(btn, EventType.OnTouchBegan, function()
            nZOrder = nZOrder + 1
            UIHelper.SetLocalZOrder(btn, nZOrder)
        end)
    end
end

return UIOperationNewInfoUpdate