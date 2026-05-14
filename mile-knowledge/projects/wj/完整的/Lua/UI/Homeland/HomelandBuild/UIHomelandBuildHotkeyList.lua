-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildHotkeyList
-- Date: 2024-04-10 10:37:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildHotkeyList = class("UIHomelandBuildHotkeyList")

function UIHomelandBuildHotkeyList:OnEnter(szHotKeyType)
    self.szHotKeyType = szHotKeyType
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIHomelandBuildHotkeyList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandBuildHotkeyList:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.ScrollViewList, false)
end

function UIHomelandBuildHotkeyList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildHotkeyList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandBuildHotkeyList:UpdateInfo()
    local tbHotkeyList = {}
    if self.szHotKeyType then
        if self.szHotKeyType == "Selfie" then
            tbHotkeyList = SelfieData.GetHomeBuildHotkeyList()
            UIHelper.SetString(self.LabelTitle , "拍照操作快捷键")
        end
    else
        tbHotkeyList = HomelandBulidHotkey.GetHomeBuildHotkeyList()
    end
    
    for index, tbKeys in ipairs(tbHotkeyList) do
        local nPrefabID = #tbKeys == 2 and PREFAB_ID.WidgetConstructionHotKeyCellDouble or PREFAB_ID.WidgetConstructionHotKeyCellSingle
        UIHelper.AddPrefab(nPrefabID, self.ScrollViewList, tbKeys)
    end
end


return UIHomelandBuildHotkeyList