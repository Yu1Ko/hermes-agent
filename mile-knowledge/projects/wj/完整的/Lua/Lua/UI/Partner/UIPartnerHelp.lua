-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerHelp
-- Date: 2024-05-16 11:05:05
-- Desc: 侠客助战
-- Prefab: WidgetPartnerHelp
-- ---------------------------------------------------------------------------------

--- 助战的队伍最大人数变更为9
local TEAM_SIZE     = 9

---@class UIPartnerHelp
local UIPartnerHelp = class("UIPartnerHelp")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerHelp:_LuaBindList()
    self.BtnQuickSetTeam          = self.BtnQuickSetTeam --- 快捷编队
    self.BtnSummon                = self.BtnSummon --- 打开 召请侠客 页面

    self.tWidgetAssistPartnerList = self.tWidgetAssistPartnerList --- 助战侠客卡片列表

    self.LayoutBtn                = self.LayoutBtn --- 按钮上方的layout

    self.TogSettingGroupOption    = self.TogSettingGroupOption --- 进入秘境时推荐配置的toggle
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerHelp:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIPartnerHelp:OnEnter(MiniScene, bOpenQuickTeam)
    self.MiniScene      = MiniScene
    self.bOpenQuickTeam = bOpenQuickTeam

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerHelp:OnExit()
    self.bInit = false

    self:CleanUpModelView()

    self:UnRegEvent()
end

function UIPartnerHelp:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnQuickSetTeam, EventType.OnClick, function()
        self:QuickSetTeam()
    end)

    UIHelper.BindUIEvent(self.BtnSummon, EventType.OnClick, function()
        local bHideQuickTeam = true
        UIMgr.Open(VIEW_ID.PanelPartnerSummonPop, bHideQuickTeam)
    end)
    
    UIHelper.BindUIEvent(self.TogSettingGroupOption, EventType.OnClick, function()
        local bSelect = UIHelper.GetSelected(self.TogSettingGroupOption)
        Partner_SetShowRecommend(bSelect)
    end)
end

function UIPartnerHelp:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nResultCode, nArg0, nArg1, nArg2)
        if nResultCode == NPC_ASSISTED_RESULT_CODE.SET_ASSISTED_LIST_SUCCESS then
            --设置助战列表成功
            self:UpdateInfo()
        end
    end)
    
    Event.Reg(self, "OnPartnerShowRecommendChanged", function()
        UIHelper.SetSelected(self.TogSettingGroupOption, Partner_GetShowRecommend(), false)
    end)
end

function UIPartnerHelp:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerHelp:UpdateInfo()
    UIHelper.SetSelected(self.TogSettingGroupOption, Partner_GetShowRecommend())
    
    self:UpdatePartnerList()

    self:UpdateMiniScene()

    if self.bOpenQuickTeam then
        self:QuickSetTeam()

        -- 仅在打开页面后触发一次，避免刷新页面信息时，再次触发
        self.bOpenQuickTeam = false
    end
end

function UIPartnerHelp:QuickSetTeam()
    UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, nil, VIEW_ID.PanelPartnerTeam, function()
        self:UpdatePartnerList()
    end)

    ---@see UIPartnerTeamView#OnEnter
    UIMgr.Open(VIEW_ID.PanelPartnerTeam, PARTNER_TEAM_TYPE.ASSIST, true, nil, nil)
end

function UIPartnerHelp:UpdatePartnerList()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local tSelTeamTypeList = PartnerData.GetAssistedList()
    for i = 1, TEAM_SIZE do
        local tWidgetPartner = self.tWidgetAssistPartnerList[i]

        local bHasSetPartner = tSelTeamTypeList and tSelTeamTypeList[i] ~= nil and tSelTeamTypeList[i] ~= 0

        UIHelper.RemoveAllChildren(tWidgetPartner)

        ---@type UIRoleItem
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetRoleItem, tWidgetPartner)

        if not bHasSetPartner then
            -- 该位置未设置侠客
            script:OnEnter(nil)
        else
            -- 该位置设置了侠客
            local dwID     = tSelTeamTypeList[i]

            local tInfo    = Table_GetPartnerNpcInfo(dwID)

            local tPartner = Partner_GetPartnerInfo(dwID)
            if tPartner then
                tInfo.bHave             = true
                tInfo.nLevel            = tPartner.nLevel
                tInfo.bEquippedExterior = tPartner.bEquippedExterior
            end

            script:OnEnter(tInfo)

            UIHelper.SetVisible(script.ImgMark, false)
        end

        -- 处理点击事件
        UIHelper.SetSelected(script.ToggleCurrentSelect, false)
        UIHelper.BindUIEvent(script.ToggleCurrentSelect, EventType.OnClick, function()
            UIHelper.SetSelected(script.ToggleCurrentSelect, false)

            self:SelectPartnerOnSlot(i)
        end)
        UIHelper.BindUIEvent(script.BtnEmptyAdd, EventType.OnClick, function()
            self:SelectPartnerOnSlot(i)
        end)
    end

    self:UpdateShowMorphBtn()
end

function UIPartnerHelp:SelectPartnerOnSlot(idx)
    UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, nil, VIEW_ID.PanelPartnerTeam, function()
        self:UpdatePartnerList()
    end)

    UIMgr.Open(VIEW_ID.PanelPartnerTeam, PARTNER_TEAM_TYPE.ASSIST, false, idx, nil)
end

function UIPartnerHelp:UpdateShowMorphBtn()
    local tSelTeamTypeList  = PartnerData.GetAssistedList()

    local bHasSetAnyPartner = false
    for i = 1, TEAM_SIZE do
        local bHasSetPartner = tSelTeamTypeList and tSelTeamTypeList[i] ~= nil

        bHasSetAnyPartner    = bHasSetAnyPartner or bHasSetPartner
    end

    -- 助战模式下，配置了侠客时，显示召请侠客按钮
    UIHelper.SetVisible(self.BtnSummon, bHasSetAnyPartner)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIPartnerHelp:UpdateMiniScene()
    -- 初始化 model view
    local hModelView = self.hModelView

    if PartnerData.bNotMgrSceneByNpcModelView and not self.m_scene then
        self.m_scene = PartnerData.GetOrCreateScene()
    end

    if not hModelView then
        hModelView = NpcModelView.CreateInstance(NpcModelView)
        hModelView:ctor()
        hModelView:init(self.m_scene, PartnerData.bNotMgrSceneByNpcModelView, true, PartnerData.szSceneFilePath, "PartnerAssist")
        self.MiniScene:SetScene(hModelView.m_scene)

        -- 确保三个model view都使用同一个场景实例
        self.m_scene    = hModelView.m_scene

        self.hModelView = hModelView
    end

    -- 不论是否加载模型，都要确保镜头参数位置一样
    hModelView:SetCamera(Const.MiniScene.PartnerView.tbHelpCamera)
end

function UIPartnerHelp:CleanUpModelView()
    if self.hModelView then
        self.hModelView:release()
        self.hModelView = nil
    end

    self.m_scene = nil
end

return UIPartnerHelp