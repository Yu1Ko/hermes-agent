-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerView
-- Date: 2023-03-28 10:51:10
-- Desc: 红尘侠影主界面
-- Prefab: PanelPartner
-- ---------------------------------------------------------------------------------

---@class UIPartnerView
local UIPartnerView = class("UIPartnerView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerView:_LuaBindList()
    self.BtnClose                 = self.BtnClose --- 关闭界面

    self.TogTabList               = self.TogTabList --- tab的列表集合，方便遍历，其实与下面分开的几个tab是一样的

    self.ScrollViewContent        = self.ScrollViewContent --- 左边tab的ScrollView
    self.TogTabPartner            = self.TogTabPartner --- 江湖侠客tab
    self.TogTabMorph              = self.TogTabMorph --- 共鸣配置tab
    self.TogTabAssist             = self.TogTabAssist --- 助战配置tab

    self.WidgetAniBottom          = self.WidgetAniBottom --- tab区域

    -- 点击对应tab后，在右边显示的界面通过下面这些节点来挂载
    self.WidgetPartnerCard        = self.WidgetPartnerCard --- 江湖侠客
    self.WidgetPartnerReactivity  = self.WidgetPartnerReactivity --- 共鸣配置
    self.WidgetPartnerAssist      = self.WidgetPartnerAssist --- 助战配置

    self.MiniScene                = self.MiniScene --- 供共鸣配置和助战配置界面使用的MiniScene

    self.TogTabTravel             = self.TogTabTravel --- 侠客委托tab
    self.WidgetPartnerTravel      = self.WidgetPartnerTravel --- 侠客委托
end

function UIPartnerView:OnEnter(dwPlayerID, nPartnerViewOpenType)
    self.dwPlayerID           = dwPlayerID
    ---@see PartnerViewOpenType
    self.nPartnerViewOpenType = nPartnerViewOpenType

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    -- 在这里统一释放侠客用到的场景
    local scene = PartnerData.GetScene()
    if scene then
        scene:RestoreCameraLight()
    end
    PartnerData.ReleaseScene()
end

function UIPartnerView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    for _, tog in ipairs(self.TogTabList) do
        UIHelper.SetToggleGroupIndex(tog, ToggleGroupIndex.PartnerTab)
    end

    UIHelper.BindUIEvent(self.TogTabPartner, EventType.OnClick, function()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.TogTabMorph, EventType.OnClick, function()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.TogTabAssist, EventType.OnClick, function()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.TogTabTravel, EventType.OnClick, function()
        self:UpdateInfo()
    end)
end

function UIPartnerView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
        UIHelper.ScrollToTop(self.ScrollViewContent, 0)
    end)

    Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
        if nProcess >= 100 then
            local scene = PartnerData.GetScene()
            if scene and not QualityMgr.bDisableCameraLight then
                scene:OpenCameraLight(QualityMgr.szCameraLightForUI)
            end
        end
    end)

    Event.Reg(self, "ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE", function()
        UIHelper.TempHidePlayerMiniSceneUntilNewViewClose(self, self.MiniScene, self.hModelView, VIEW_ID.PanelOutfitPreview)
    end)
end

function UIPartnerView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerView:UpdateInfo()
    self:InitOtherPlayerSettings()

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)

    -- 先将各个tab对应的子节点清空，还原初始状态
    UIHelper.RemoveAllChildren(self.WidgetPartnerCard)
    UIHelper.RemoveAllChildren(self.WidgetPartnerReactivity)
    UIHelper.RemoveAllChildren(self.WidgetPartnerAssist)
    UIHelper.RemoveAllChildren(self.WidgetPartnerTravel)

    if self.nPartnerViewOpenType == PartnerViewOpenType.Assist or self.nPartnerViewOpenType == PartnerViewOpenType.AssistQuickTeam then
        UIHelper.SetSelected(self.TogTabAssist, true)
    elseif self.nPartnerViewOpenType == PartnerViewOpenType.Morph or self.nPartnerViewOpenType == PartnerViewOpenType.MorphQuickTeam then
        UIHelper.SetSelected(self.TogTabMorph, true)
    elseif self.nPartnerViewOpenType == PartnerViewOpenType.Travel then
        UIHelper.SetSelected(self.TogTabTravel, true)
    end

    -- 是否显示MiniScene（放到这边可以避免显示的层级关系出问题）
    local bShowMiniScene = true
    UIHelper.SetVisible(self.MiniScene, bShowMiniScene)

    if UIHelper.GetSelected(self.TogTabPartner) then
        self:ShowPartnerList()
    elseif UIHelper.GetSelected(self.TogTabMorph) then
        self:ShowMorphList()
    elseif UIHelper.GetSelected(self.TogTabAssist) then
        self:ShowAssistList()
    elseif UIHelper.GetSelected(self.TogTabTravel) then
        self:ShowTravel()
    end

    -- 打开指定页面后，重置为默认值，避免后续点击其他tab时继续生效
    self.nPartnerViewOpenType = PartnerViewOpenType.Default
end

function UIPartnerView:ShowPartnerList()
    ---@see UIPartnerCard#OnEnter
    local script = UIMgr.AddPrefab(PREFAB_ID.WidgetPartnerCard, self.WidgetPartnerCard, self.dwPlayerID, self.MiniScene, self.nPartnerViewOpenType)
    UIHelper.WidgetFoceDoAlign(script)
    self.scriptPartnerCard = script
end

function UIPartnerView:ShowMorphList()
    ---@see UIPartnerFetter#OnEnter
    local script = UIMgr.AddPrefab(PREFAB_ID.WidgetPartnerFetter, self.WidgetPartnerReactivity, self.MiniScene, self.nPartnerViewOpenType == PartnerViewOpenType.MorphQuickTeam)
    UIHelper.WidgetFoceDoAlign(script)
end

function UIPartnerView:ShowAssistList()
    ---@see UIPartnerHelp#OnEnter
    local script = UIMgr.AddPrefab(PREFAB_ID.WidgetPartnerHelp, self.WidgetPartnerAssist, self.MiniScene, self.nPartnerViewOpenType == PartnerViewOpenType.AssistQuickTeam)
    UIHelper.WidgetFoceDoAlign(script)
end

function UIPartnerView:ShowTravel()
    ---@see UIPartnerTravelNew#OnEnter
    local script = UIMgr.AddPrefab(PREFAB_ID.WidgetPartnerTravel, self.WidgetPartnerTravel, self.MiniScene, self)
    UIHelper.WidgetFoceDoAlign(script)
end

function UIPartnerView:InitOtherPlayerSettings()
    -- 如果是查看他人的侠客，则隐藏部分组件
    if Partner_IsSelfPlayer(self.dwPlayerID) then
        return
    end

    UIHelper.SetVisible(self.WidgetAniBottom, false)
end

return UIPartnerView