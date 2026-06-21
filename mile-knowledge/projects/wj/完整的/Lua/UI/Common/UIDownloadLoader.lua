-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIDownloadLoader
-- Date: 2023-11-09 16:30:07
-- Desc: UIDownloadLoader WidgetDownloadBtn加载器
-- ---------------------------------------------------------------------------------

local UIDownloadLoader = class("UIDownloadLoader")

function UIDownloadLoader:OnEnter()
    -- 预制绑定常量：self.nType, 1: Btn, 2: Img, 3: FinishHint

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nType = tonumber(self.nType) or 1
    --self:InitUI(self.nType)
end

function UIDownloadLoader:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDownloadLoader:BindUIEvent()

end

function UIDownloadLoader:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDownloadLoader:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIDownloadLoader:InitUI(nType, tConfig)
    if not PakDownloadMgr.IsEnabled() then
        return
    end

    nType = tonumber(nType) or 1
    local nPrefabID = PREFAB_ID.WidgetDownloadBtn
    if tConfig and tConfig.bLong then
        nPrefabID = PREFAB_ID.WidgetDownloadBtnLong
    elseif tConfig and tConfig.bCoinShop then
        nPrefabID = PREFAB_ID.WidgetDownloadBtn_Shopping
    end
    self.scriptDownload = self.scriptDownload or UIHelper.AddPrefab(nPrefabID, self._rootNode, nType)
end

--单个资源信息显示，参数详见UIWidgetDownload.lua, tConfig.bLong表示使用长按钮
function UIDownloadLoader:OnInitWithPackID(nPackID, tConfig)
    self:InitUI(self.nType, tConfig)
    if self.scriptDownload then
        self.scriptDownload:OnInitWithPackID(nPackID, tConfig)
    end
end

--单个资源下载列表信息显示，参数详见UIWidgetDownload.lua, tConfig.bLong表示使用长按钮
function UIDownloadLoader:OnInitWithPackIDList(tPackIDList, tConfig)
    self:InitUI(self.nType, tConfig)
    if self.scriptDownload then
        self.scriptDownload:OnInitWithPackIDList(tPackIDList, tConfig)
    end
end

--带有多个资源下载列表的下拉框，参数详见UIWidgetDownload.lua
function UIDownloadLoader:OnInitWithPackIDListInfo(tPackIDListInfo, tConfig)
    self:InitUI(self.nType, tConfig)
    if self.scriptDownload then
        self.scriptDownload:OnInitWithPackIDListInfo(tPackIDListInfo, tConfig)
    end
end

--基础资源信息显示；
function UIDownloadLoader:OnInitBasic(tConfig)
    self:InitUI(self.nType, tConfig)
    if self.scriptDownload then
        self.scriptDownload:OnInitBasic(tConfig)
    end
end

--资源管理入口
function UIDownloadLoader:OnInitTotal(tConfig)
    self:InitUI(self.nType, tConfig)
    if self.scriptDownload then
        self.scriptDownload:OnInitTotal(tConfig)
    end
end

--资源下载完成提示资源列表，参数详见UIWidgetDownload.lua
function UIDownloadLoader:OnInitWithCompleteHintPackIDList(tCompleteHintPackIDList, tConfig)
    self:InitUI(self.nType, tConfig)
    if self.scriptDownload then
        self.scriptDownload:OnInitWithCompleteHintPackIDList(tCompleteHintPackIDList, tConfig)
    end
end

function UIDownloadLoader:OnInitWithHint(tConfig)
    self:InitUI(self.nType, tConfig)
    if self.scriptDownload then
        self.scriptDownload:OnInitWithHint(tConfig)
    end
end

function UIDownloadLoader:SetVisible(bVisible)
    if self.scriptDownload then
        self.scriptDownload:SetVisible(bVisible)
    end
end

function UIDownloadLoader:GetVisible()
    if self.scriptDownload then
        return self.scriptDownload:GetVisible()
    end
    return false
end

function UIDownloadLoader:SetDiscard(bDiscard)
    if self.scriptDownload then
        self.scriptDownload:SetDiscard(bDiscard)
    end
end

return UIDownloadLoader