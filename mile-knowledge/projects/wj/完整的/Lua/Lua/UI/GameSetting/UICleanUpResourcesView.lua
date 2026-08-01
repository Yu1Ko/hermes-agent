-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UICleanUpResourcesView
-- Date: 2024-01-24 19:51:18
-- Desc: UICleanUpResourcesView 资源清理界面
-- ---------------------------------------------------------------------------------

local UICleanUpResourcesView = class("UICleanUpResourcesView")

local SettingType = {
    Resources = {
        tMainCategories = {
            RESOURCES.DYNAMIC, RESOURCES.MAP
        }
    },
}

local szCategory = SettingCategory.Resources

function UICleanUpResourcesView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    ResCleanData.RecordLoadCurrentMap()
    self:UpdateInfo()
    self:UpdateCleanInfo()
end

function UICleanUpResourcesView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICleanUpResourcesView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function()
        local bMultiInstance = PakDownload_HasMultiInstance()
        if bMultiInstance then
            TipsHelper.ShowNormalTip("当前启动了多个客户端，无法进行资源清理操作")
            return
        end

        ResCleanData.CleanDynDLC()
        ResCleanData.CleanMapDLC()
        self:UpdateCleanInfo()
        TipsHelper.ShowNormalTip("资源清理成功，重启游戏后释放存储空间")
    end)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UICleanUpResourcesView:RegEvent()
    Event.Reg(self, EventType.OnCleanResourcesUpdate, function()
        self:UpdateCleanInfo()
    end)
end

function UICleanUpResourcesView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICleanUpResourcesView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewContent)

    local tInfo = SettingType[szCategory]
    local tCategory = tInfo.tMainCategories
    for _, nMainCategory in pairs(tCategory) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetAutoCleanUpCell, self.ScrollViewContent, nMainCategory)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)
end

function UICleanUpResourcesView:UpdateCleanInfo()
    ResCleanData.UpdateDynTimeStamp()
    ResCleanData.UpdateMapTimeStamp()
    local dwTotalSize = ResCleanData.GetExpiredDynDLCSize() + ResCleanData.GetExpiredMapDLCSize()
    UIHelper.SetString(self.LabelAccept, "开始清理 (" .. PakDownloadMgr.FormatSize(dwTotalSize) .. ")")
    UIHelper.SetButtonState(self.BtnAccept, dwTotalSize > 0 and BTN_STATE.Normal or BTN_STATE.Disable)
end

return UICleanUpResourcesView