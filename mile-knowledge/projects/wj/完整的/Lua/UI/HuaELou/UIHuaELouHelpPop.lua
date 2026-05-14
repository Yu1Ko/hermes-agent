-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHuaELouHelpPop
-- Date: 2023-08-29 17:17:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHuaELouHelpPop = class("UIHuaELouHelpPop")

local nContentPrefabID = PREFAB_ID.WidgetHelpContentCelll
local nTitlePrefabID = PREFAB_ID.WidgetRuleTitleCell

function UIHuaELouHelpPop:OnEnter(dwOperatActID, szTitle, szActivityExplain)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwOperatActID = dwOperatActID
    self.szActivityExplain = szActivityExplain

    local szText = ParseTextHelper.ConvertRichTextFormat(UIHelper.GBKToUTF8(self.szActivityExplain), true)

    local cell = UIHelper.AddPrefab(nTitlePrefabID, self.ScrollViewActivityHelp)
    if cell then
        cell:OnEnter(szTitle)
    end
    cell = UIHelper.AddPrefab(nContentPrefabID, self.ScrollViewActivityHelp)
    if cell then
        cell:OnEnter(szText)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActivityHelp)
end

function UIHuaELouHelpPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHuaELouHelpPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIHuaELouHelpPop:RegEvent()
    Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
        szUrl = Base64_Decode(szUrl)
        szUrl = string.gsub(szUrl, "\\", "/")
        local szLinkEvent, szLinkArg = szUrl:match("(%w+)/(.*)")
        if szLinkEvent == "ItemLinkInfo" then
            local szType, szID = szLinkArg:match("(%d+)/(%d+)")
            local dwType       = tonumber(szType)
            local dwID         = tonumber(szID)

            TipsHelper.ShowItemTips(node, dwType, dwID)
        else
            HuaELouData.HandleJump(szUrl, false)
            UIMgr.Close(self)
        end
    end)
end

function UIHuaELouHelpPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHuaELouHelpPop:UpdateInfo()

end


return UIHuaELouHelpPop