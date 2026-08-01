-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerFetter
-- Date: 2023-04-20 19:46:18
-- Desc: 侠客-共鸣配置
-- Prefab: WidgetPartnerFetter
-- ---------------------------------------------------------------------------------

local TEAM_SIZE       = 3

---@class UIPartnerFetter
local UIPartnerFetter = class("UIPartnerFetter")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerFetter:_LuaBindList()
    self.BtnShowMorphInMainUI   = self.BtnShowMorphInMainUI --- 在主界面显示共鸣
    self.LabelShowMorphInMainUI = self.LabelShowMorphInMainUI --- 在主界面显示共鸣按钮的label
    self.BtnQuickSetTeam        = self.BtnQuickSetTeam --- 快捷编队
    self.LayoutBtn              = self.LayoutBtn --- 按钮上层的layout

    self.BtnFetterAdd01         = self.BtnFetterAdd01 --- 选择共鸣侠客按钮
    self.BtnBox01               = self.BtnBox01 --- 显示模型时的透明按钮，用于触发选择界面
    self.WidgetRole01           = self.WidgetRole01 --- 共鸣侠客组件
    self.LayoutName01           = self.LayoutName01 --- 心法图标和名字的layout
    self.ImgName01              = self.ImgName01 --- 心法图标
    self.LabelName01            = self.LabelName01 --- 名字
    self.LabelLevel01           = self.LabelLevel01 --- 等级
    self.LabelStaminaNum01      = self.LabelStaminaNum01 --- 体力
    self.ImgTestMask01          = self.ImgTestMask01 --- 试用图标
    self.LabelFight1            = self.LabelFight1 --- 战力

    self.BtnFetterAdd02         = self.BtnFetterAdd02 --- 选择共鸣侠客按钮
    self.BtnBox02               = self.BtnBox02 --- 显示模型时的透明按钮，用于触发选择界面
    self.WidgetRole02           = self.WidgetRole02 --- 共鸣侠客组件
    self.LayoutName02           = self.LayoutName02 --- 心法图标和名字的layout
    self.ImgName02              = self.ImgName02 --- 心法图标
    self.LabelName02            = self.LabelName02 --- 名字
    self.LabelLevel02           = self.LabelLevel02 --- 等级
    self.LabelStaminaNum02      = self.LabelStaminaNum02 --- 体力
    self.ImgTestMask02          = self.ImgTestMask02 --- 试用图标
    self.LabelFight2            = self.LabelFight2 --- 战力

    self.BtnFetterAdd03         = self.BtnFetterAdd03 --- 选择共鸣侠客按钮
    self.BtnBox03               = self.BtnBox03 --- 显示模型时的透明按钮，用于触发选择界面
    self.WidgetRole03           = self.WidgetRole03 --- 共鸣侠客组件
    self.LayoutName03           = self.LayoutName03 --- 心法图标和名字的layout
    self.ImgName03              = self.ImgName03 --- 心法图标
    self.LabelName03            = self.LabelName03 --- 名字
    self.LabelLevel03           = self.LabelLevel03 --- 等级
    self.LabelStaminaNum03      = self.LabelStaminaNum03 --- 体力
    self.ImgTestMask03          = self.ImgTestMask03 --- 试用图标
    self.LabelFight3            = self.LabelFight3 --- 战力
end

function UIPartnerFetter:OnEnter(MiniScene, bOpenQuickTeam)
    self.MiniScene      = MiniScene
    self.bOpenQuickTeam = bOpenQuickTeam

    -- 这个界面现在仅共鸣使用
    self.nSelTeamType   = PARTNER_TEAM_TYPE.MORPH

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerFetter:OnExit()
    self.bInit = false

    self:CleanUpModelView()

    self:UnRegEvent()
end

function UIPartnerFetter:BindUIEvent()
    local tBtnChooseList = {
        { self.BtnFetterAdd01, self.BtnBox01 },
        { self.BtnFetterAdd02, self.BtnBox02 },
        { self.BtnFetterAdd03, self.BtnBox03 },
    }

    for idx, tBtnList in ipairs(tBtnChooseList) do
        for _, btn in ipairs(tBtnList) do
            UIHelper.BindUIEvent(btn, EventType.OnClick, function()
                self:SelectPartnerOnSlot(idx)
            end)
        end
    end

    UIHelper.BindUIEvent(self.BtnShowMorphInMainUI, EventType.OnClick, function()
        PartnerData.bShowMorphInMainCity = not PartnerData.bShowMorphInMainCity
        self:UpdateShowMorphBtn()

        Event.Dispatch(EventType.UpdatePartnerMorphShowState)
    end)

    UIHelper.BindUIEvent(self.BtnQuickSetTeam, EventType.OnClick, function()
        self:QuickSetTeam()
    end)
end

function UIPartnerFetter:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nResultCode, nArg0, nArg1, nArg2)
        if nResultCode == NPC_ASSISTED_RESULT_CODE.SET_MORPH_LIST_SUCCESS then
            --设置幻化列表成功
            self:UpdateInfo()
        elseif nResultCode == NPC_ASSISTED_RESULT_CODE.NPC_ASSISTED_INFO_CHANGE then
            --数据变动
            self:UpdateInfo()
        end
    end)
end

function UIPartnerFetter:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerFetter:UpdateInfo()
    self:UpdatePartnerList()

    if self.bOpenQuickTeam then
        self:QuickSetTeam()

        -- 仅在打开页面后触发一次，避免刷新页面信息时，再次触发
        self.bOpenQuickTeam = false
    end
end

function UIPartnerFetter:UpdatePartnerList()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local tSelTeamTypeList   = PartnerData.GetMorphList()

    local tUIWidgetGroupList = {
        { self.BtnFetterAdd01, self.BtnBox01, self.WidgetRole01, self.LayoutName01, self.ImgName01, self.LabelName01, self.LabelLevel01, self.LabelStaminaNum01, self.ImgTestMask01, self.LabelFight1 },
        { self.BtnFetterAdd02, self.BtnBox02, self.WidgetRole02, self.LayoutName02, self.ImgName02, self.LabelName02, self.LabelLevel02, self.LabelStaminaNum02, self.ImgTestMask02, self.LabelFight2 },
        { self.BtnFetterAdd03, self.BtnBox03, self.WidgetRole03, self.LayoutName03, self.ImgName03, self.LabelName03, self.LabelLevel03, self.LabelStaminaNum03, self.ImgTestMask03, self.LabelFight3 },
    }

    for i = 1, TEAM_SIZE do
        local btnSelectRole, btnSelectRoleTransparent, widgetRole,
        layoutKungfuAndName, imgKungfu, labelName,
        labelLevel, labelStaminaNum, imgTestMask, labelFight = table.unpack(tUIWidgetGroupList[i])

        local bHasSetPartner                                 = tSelTeamTypeList and tSelTeamTypeList[i] ~= nil

        UIHelper.SetVisible(btnSelectRole, not bHasSetPartner)
        UIHelper.SetVisible(btnSelectRoleTransparent, bHasSetPartner)
        UIHelper.SetVisible(widgetRole, bHasSetPartner)

        if not bHasSetPartner then
            -- 该位置未设置侠客
            self:UpdateNpcModel(i, nil)
        else
            -- 该位置设置了侠客
            local dwID         = tSelTeamTypeList[i]

            local tInfo        = Table_GetPartnerNpcInfo(dwID)
            local tPartner     = Partner_GetPartnerInfo(dwID)

            local szName       = UIHelper.GBKToUTF8(tInfo.szName)
            local nKungfuIndex = tInfo.nKungfuIndex

            UIHelper.SetString(labelName, szName)
            UIHelper.SetSpriteFrame(imgKungfu, PartnerKungfuIndexToImg[nKungfuIndex])

            UIHelper.LayoutDoLayout(layoutKungfuAndName)

            UIHelper.SetString(labelLevel, tPartner.nLevel .. "级")

            UIHelper.SetVisible(imgTestMask, tInfo.bTryOut)

            local dwStanima    = tPartner.dwStamina
            local dwMaxStanima = GetMaxStamina()
            UIHelper.SetString(labelStaminaNum, string.format("%d/%d", dwStanima, dwMaxStanima))

            self:UpdateScoreInfo(dwID, labelFight)

            self:UpdateNpcModel(i, dwID)
        end
    end

    self:UpdateShowMorphBtn()

    -- 记录下上次的侠客列表
    self.tLastSelTeamTypeList = tSelTeamTypeList

    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIPartnerFetter:UpdateScoreInfo(dwID, labelFight)
    local layoutFight = UIHelper.GetParent(labelFight)
    PartnerData.UpdateScoreInfo(nil, dwID, labelFight, layoutFight)
end

function UIPartnerFetter:UpdateNpcModel(idx, dwID)
    -- 初始化 model view
    self.hModelViewList = self.hModelViewList or {}

    local hModelView    = self.hModelViewList[idx]

    if PartnerData.bNotMgrSceneByNpcModelView and not self.m_scene then
        self.m_scene = PartnerData.GetOrCreateScene()
    end

    if not hModelView then
        hModelView = NpcModelView.CreateInstance(NpcModelView)
        hModelView:ctor()
        hModelView:init(self.m_scene, PartnerData.bNotMgrSceneByNpcModelView, true, PartnerData.szSceneFilePath, "PartnerSelected" .. self.nSelTeamType .. idx)
        self.MiniScene:SetScene(hModelView.m_scene)

        -- 确保三个model view都使用同一个场景实例
        self.m_scene             = hModelView.m_scene

        self.hModelViewList[idx] = hModelView
    end

    if dwID then
        -- 加载模型
        local dwPartnerID  = dwID
        local tRepresentID = Partner_GetEquippedRepresentID(dwPartnerID)
        local tNpcModel    = Partner_GetNpcModelInfo(dwPartnerID)
        tRepresentID       = NpcAssited_TransformDefaultResource(tNpcModel.nRoleType, GetNpcAssistedTemplateID(dwPartnerID), 0, tRepresentID)

        hModelView:LoadNpcRes(tNpcModel.dwOrigModelID, false, tNpcModel.nRoleType, false, tNpcModel.bSheath, tRepresentID)
        local fBasePosX, fBasePosY, fBasePosZ = table.unpack(Const.MiniScene.PartnerView.tbFetterBasePos)
        local fBaseYaw                        = Const.MiniScene.PartnerView.fFetterBaseYaw

        -- npc初始朝向角度，增大会往左转，减小会往右转
        local fNpcYaw                         = fBaseYaw + Const.MiniScene.PartnerView.fFetterOffsetYaw * (idx - 2)

        -- 每个npc往不同的横轴位置站，数值越小越靠右
        local fPosZ                           = fBasePosZ + Const.MiniScene.PartnerView.fFetterOffsetPosZ * (idx - 1)

        local bIdxPartnerChanged              = (self.tLastSelTeamTypeList == nil) or (self.tLastSelTeamTypeList[idx] ~= dwID)
        if bIdxPartnerChanged then
            -- 仅在当前位置的侠客变动时重新卸载之前的模型
            hModelView:UnloadModel()
        end
        hModelView:LoadModel()
        hModelView:PlayAnimation("Idle", "loop")
        hModelView:SetTranslation(fBasePosX, fBasePosY, fPosZ)
        hModelView:SetYaw(fNpcYaw)
        hModelView:SetScaling(tNpcModel.fScale)
    else
        -- 若该位置的侠客被移除，则卸载模型
        hModelView:UnloadModel()
    end

    -- 不论是否加载模型，都要确保镜头参数位置一样
    hModelView:SetCamera(Const.MiniScene.PartnerView.tbFetterCamera)
end

function UIPartnerFetter:CleanUpModelView()
    if self.hModelViewList then
        for _, hModelView in ipairs(self.hModelViewList) do
            hModelView:release()
        end
        self.hModelViewList = nil
    end

    self.m_scene = nil
end

function UIPartnerFetter:SelectPartnerOnSlot(idx)
    self:ModelViewListShowModel(false)
    UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, nil, VIEW_ID.PanelPartnerTeam, function()
        self:ModelViewListShowModel(true)
        self:UpdatePartnerList()
    end)

    UIMgr.Open(VIEW_ID.PanelPartnerTeam, self.nSelTeamType, false, idx, nil)
end

function UIPartnerFetter:ModelViewListShowModel(bShow)
    if self.hModelViewList then
        for _, hModelView in ipairs(self.hModelViewList) do
            hModelView:ShowModel(bShow)
        end
    end
end

function UIPartnerFetter:QuickSetTeam()
    UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, nil, VIEW_ID.PanelPartnerTeam, function()
        self:UpdatePartnerList()
    end)

    UIMgr.Open(VIEW_ID.PanelPartnerTeam, self.nSelTeamType, true, nil, self.hModelViewList)
end

function UIPartnerFetter:UpdateShowMorphBtn()
    local tSelTeamTypeList  = PartnerData.GetMorphList()

    local bHasSetAnyPartner = false
    for i = 1, TEAM_SIZE do
        local bHasSetPartner = tSelTeamTypeList and tSelTeamTypeList[i] ~= nil

        bHasSetAnyPartner    = bHasSetAnyPartner or bHasSetPartner
    end

    -- 共鸣模式下，配置了侠客时，显示 主界面显示/隐藏共鸣 按钮
    UIHelper.SetVisible(self.BtnShowMorphInMainUI, bHasSetAnyPartner)

    if not bHasSetAnyPartner then
        -- 若无任何共鸣侠客，则关闭共鸣显示开关
        Event.Dispatch(EventType.HidePartnerMorph)
    end

    local szBtnText = PartnerData.bShowMorphInMainCity and "主界面隐藏共鸣" or "主界面显示共鸣"
    UIHelper.SetString(self.LabelShowMorphInMainUI, szBtnText)
end

return UIPartnerFetter