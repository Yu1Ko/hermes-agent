-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelProrequestTaskPop
-- Date: 2025-04-01 19:51:44
-- Desc: ?
-- ---------------------------------------------------------------------------------
local HEIGHT_THRESHOLD_VALUE = 156
local UIPanelProrequestTaskPop = class("UIPanelProrequestTaskPop")

function UIPanelProrequestTaskPop:OnEnter(tbMsg, tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbMsg = tbMsg
    self.tbInfo = tbInfo
    self.szContent = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(self.tbInfo.szMsg), false)
    self:UpdateInfo()
end

function UIPanelProrequestTaskPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelProrequestTaskPop:BindUIEvent()
    
end

function UIPanelProrequestTaskPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelProrequestTaskPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelProrequestTaskPop:GetTitleIcon()
    local szImage = self.tbInfo.szIconFile
	local nIconFrame = self.tbInfo.nIconFrame
    local tbText = string.split(szImage, "/")
    local szImgPath = ""
    if #tbText > 1 then
        szImage =  string.gsub(tbText[#tbText], ".UITex", "")
        szImgPath = "Resource_RevivePanel_RevivePanel01_" .. szImage .. "_" .. tostring(nIconFrame) .. ".png"
    end
    return szImgPath
end

function UIPanelProrequestTaskPop:UpdateInfo()
    local szContent = self.szContent
    if  self.tbMsg.szMsg then
        szContent = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(self.tbMsg.szMsg), false)
    end
    local szTitle = self.tbInfo.szTitle
    local szTitleIcon = self:GetTitleIcon()

    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(szTitle))
    UIHelper.SetSpriteFrame(self.ImgIcon, szTitleIcon)

    UIHelper.SetRichText(self.RichTextContent01, szContent)
    UIHelper.SetRichText(self.RichTextContent02, szContent)
    local nContentHeight = UIHelper.GetHeight(self.RichTextContent01)
    UIHelper.SetVisible(self.ScrollViewContent, nContentHeight > HEIGHT_THRESHOLD_VALUE)
    UIHelper.SetVisible(self.RichTextContent01, nContentHeight <= HEIGHT_THRESHOLD_VALUE)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)

    self.RichText = nContentHeight > HEIGHT_THRESHOLD_VALUE and self.RichTextContent02 or self.RichTextContent01
    self:SetContentCountDown()

    self:UpdateItemList()
    self:UpdateBtns()
    UIHelper.LayoutDoLayout(self.WidgetAnchorContent)
end

function UIPanelProrequestTaskPop:UpdateItemList()
    local tbItemList = self.tbMsg.tItemList
    if not tbItemList then
        return
    end

    UIHelper.RemoveAllChildren(self.LayoutItemShell)

    self.tbItemIcon      = {}

    local container = self.LayoutItemShell
    for index, item in ipairs(tbItemList) do
        ---@type UIItemIcon
        local itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, container)
        if bUseScrollView then
            UIHelper.SetAnchorPoint(itemIcon._rootNode, 0, 0)
        end

        if item.dwTabType ~= "COIN" then
            itemIcon:OnInitWithTabID(item.dwTabType, item.dwIndex)
            itemIcon:SetLabelCount(item.nStackNum)
        else
            itemIcon:OnInitCurrency(item.dwIndex, item.nStackNum)
        end

        itemIcon:SetClickCallback(function()
            local scriptItemTip
            if item.dwTabType ~= "COIN" then
                _, scriptItemTip = TipsHelper.ShowItemTips(itemIcon._rootNode, item.dwTabType, item.dwIndex, false)
            else
                _, scriptItemTip = TipsHelper.ShowCurrencyTips(itemIcon._rootNode, item.dwIndex, item.nStackNum)
            end
            scriptItemTip:SetBtnState({})
       
        end)
        UIHelper.SetTouchDownHideTips(itemIcon.ToggleSelect, false)
        table.insert(self.tbItemIcon, itemIcon)
    end

    UIHelper.LayoutDoLayout(container)
end

function UIPanelProrequestTaskPop:UpdateBtns()
    local tMsg = self.tbMsg
    for index, button in ipairs(self.tbBtns) do
        local szText = UIHelper.GBKToUTF8(self.tbInfo["szButtonText" .. index])
        if szText and  szText ~= "" then
            UIHelper.SetVisible(button, true)
            UIHelper.BindUIEvent(button, EventType.OnClick, function()
                local BtnData = tMsg.tBtn and tMsg.tBtn[index] and tMsg.tBtn[index].BtnData or nil
                RemoteCallToServer("On_MessageBoxPro_Request", self.tbMsg.nMessageID, index, self.tbMsg.UserData, BtnData)
                UIMgr.Close(self)
            end)
            UIHelper.SetString(UIHelper.GetChildByName(button, "LabelContent"), szText)
        else
            UIHelper.SetVisible(button, false)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutButton)
    self:UpdateBtnCountDown()
end

function UIPanelProrequestTaskPop:UpdateBtnCountDown()
    local dwStartTime = GetTickCount()
    local function UpdateCountDown()
        for index, button in ipairs(self.tbBtns) do
            local szText = UIHelper.GBKToUTF8(self.tbInfo["szButtonText" .. index])
            if szText and  szText ~= "" then
               local nCountDown = self.tbMsg.tBtn and self.tbMsg.tBtn[index] and self.tbMsg.tBtn[index].nCountDownTime or nil
               if nCountDown then
                    local nSeconds = nCountDown - (GetTickCount() -dwStartTime) / 1000
                    nSeconds = math.floor(nSeconds + 0.5)
                    if nSeconds < 0 then
                        nSeconds = 0
                    end
                    UIHelper.SetString(UIHelper.GetChildByName(button, "LabelContent"), FormatString(g_tStrings.MSG_BRACKET, szText, nSeconds))
                    if nSeconds == 0 then
                        UIMgr.Close(self)
                    end
               end
            end
        end
    end
    Timer.AddCycle(self, 1, UpdateCountDown)
end

function UIPanelProrequestTaskPop:SetContentCountDown()
    local pattern = "{%$([^%s]+)%s*([^%s]*)%s*([^%s]*)}"
    local bCountDown = false
    local szContent = self.szContent:gsub(pattern, function(key, arg0, arg1)
        if key == "countdown_s" or key == "countdown_ms" then
            bCountDown = true
            if arg1 == "" then
                return "{$" .. key .. " " .. arg0 .. " " .. GetCurrentTime() .. "}"
            end
        end
    end)
    if not bCountDown then
        return
    end
    Timer.DelTimer(self, self.nContentCDTimerID)
    self.nContentCDTimerID = Timer.AddCycle(self, 0.1, function()
        local szNewContent = szContent:gsub(pattern, gsubMessage)
        UIHelper.SetRichText(self.RichText, szNewContent)
    end)
end

return UIPanelProrequestTaskPop