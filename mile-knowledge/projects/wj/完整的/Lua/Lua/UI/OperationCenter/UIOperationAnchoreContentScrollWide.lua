-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationAnchoreContentScrollWide
-- Date: 2026-03-20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationAnchoreContentScrollWide = class("UIOperationAnchoreContentScrollWide")

function UIOperationAnchoreContentScrollWide:OnEnter(nOperationID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID

    local scriptPublicTitle = UIHelper.GetBindScript(self.WidgetLayOutWidgetPublicTitle)
    scriptPublicTitle:OnEnter(nOperationID, nID)

    local scriptLabelContent = UIHelper.GetBindScript(self.WidgetLabelContent)
    scriptLabelContent:OnEnter(nOperationID, nID)

    local scriptMiniTitle = UIHelper.GetBindScript(self.WidgetMiniTitle)
    scriptMiniTitle:OnEnter(nOperationID, nID)
    UIHelper.SetVisible(scriptMiniTitle._rootNode, false)

    UIHelper.LayoutDoLayout(self.LayoutContentTopTitle)

    self:UpdateInfo()
end

function UIOperationAnchoreContentScrollWide:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationAnchoreContentScrollWide:BindUIEvent()

end

function UIOperationAnchoreContentScrollWide:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationAnchoreContentScrollWide:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  --------------------------------------------------------

function UIOperationAnchoreContentScrollWide:UpdateInfo()
    if self.nOperationID then
        local tCheckBoxInfo = Table_GetOperationCheckBox(self.nOperationID)
        if tCheckBoxInfo then
            self:InitCheckBoxByConfig(tCheckBoxInfo)
        end
    end
end

function UIOperationAnchoreContentScrollWide:InitCheckBoxByConfig(tCheckBoxInfo)
    local nCheckBoxNum = tCheckBoxInfo.nCheckBoxNum or 0

    UIHelper.SetVisible(self.ScrollViewTopAnchoreContentList, false)
	UIHelper.SetVisible(self.ScrollViewTopAnchoreContentList2, true)

    local scrollview = self.ScrollViewTopAnchoreContentList2

    local function InitToggleGroup(widgetToggle, nNum)
        local scriptToggle = UIHelper.GetBindScript(widgetToggle)
        if not scriptToggle then
            return
        end

        UIHelper.SetVisible(widgetToggle, true)
        local scriptLabelContent = UIHelper.AddPrefab(PREFAB_ID.WidgetLabelContent, scrollview, self.nOperationID, self.nID)
        UIHelper.SetLocalZOrder(scriptLabelContent._rootNode, -1)

        local scriptQRCode = UIHelper.AddPrefab(PREFAB_ID.WidgetQRcode, scrollview, self.nOperationID, self.nID)
        UIHelper.SetLocalZOrder(scriptQRCode._rootNode, -1)

        for i = 1, nNum do
            local tContent = Table_GetCheckBoxContent(self.nOperationID, i)
            local szName = tContent and UIHelper.GBKToUTF8(tContent.szName) or ""
            scriptToggle:SetLabel(i, szName)
        end
        scriptToggle:SetSelectCallback(function(nIndex)
            if self.fnToggleSelectCallback then
                self.fnToggleSelectCallback(nIndex)
            end
            local tContent = Table_GetCheckBoxContent(self.nOperationID, nIndex)
            local szDsc = tContent and tContent.szDsc or ""
            szDsc = ParseTextHelper.ParseNormalText(szDsc, false)
            szDsc = UIHelper.GBKToUTF8(szDsc)
            scriptLabelContent:SetContent(szDsc)
            UIHelper.SetVisible(scriptLabelContent._rootNode, szDsc ~= "")
            -- 二维码（可选）
            local szQRCodePath = tContent.szQRCodePath
            if szQRCodePath ~= "" then
                scriptQRCode:UpdateByInfo({szQRCodePath = szQRCodePath, szQRCodeText = tContent.szQRCodeText })
            end
            scriptQRCode:UpdateVisible(szQRCodePath ~= "")
            UIHelper.ScrollViewDoLayoutAndToTop(scrollview)
        end)

        Timer.AddFrame(self, 2, function()
            scriptToggle:SetSelectIndex(1, true)
        end)
    end

    UIHelper.SetVisible(self.WidgetToggle2, false)
    UIHelper.SetVisible(self.WidgetToggle3, false)
    if nCheckBoxNum == 2 then
        InitToggleGroup(self.WidgetToggle2, 2)
    elseif nCheckBoxNum == 3 then
        InitToggleGroup(self.WidgetToggle3, 3)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(scrollview)
end

-- 设置Toggle选中回调（供父面板注入，参数为 nIndex）
function UIOperationAnchoreContentScrollWide:SetToggleSelectCallback(fnCallBack)
    self.fnToggleSelectCallback = fnCallBack
end


return UIOperationAnchoreContentScrollWide
