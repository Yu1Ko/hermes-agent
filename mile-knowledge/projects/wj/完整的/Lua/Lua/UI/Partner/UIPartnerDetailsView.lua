-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerDetailsView
-- Date: 2023-03-29 10:38:54
-- Desc: 侠客-详情
-- Prefab: PanelPartnerDetails
-- ---------------------------------------------------------------------------------

local szModelFrame         = "Partner"
local szModelFramePath     = "Partner"
local szModelName          = "Partner"

---@class UIPartnerDetailsView
local UIPartnerDetailsView = class("UIPartnerDetailsView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerDetailsView:_LuaBindList()
    self.BtnClose                  = self.BtnClose --- 关闭按钮

    self.LayoutDetails             = self.LayoutDetails --- 详情的最上层layout

    self.BtnLocation               = self.BtnLocation --- 未抽取：前往寻访，抽到但未做任务：追踪任务
    self.LabelLocation             = self.LabelLocation --- 前往寻访 / 追踪任务 的label

    self.LabelState                = self.LabelState --- 结交状态的label（未结交时显示，其他时候隐藏）

    self.LabelName                 = self.LabelName --- 名称
    self.ImgType                   = self.ImgType --- 心法类型的图片
    self.LabelStaminaNum           = self.LabelStaminaNum --- 体力
    self.LabelLevel                = self.LabelLevel --- 等级
    self.LabelLevelProgress        = self.LabelLevelProgress --- 等级经验进度

    self.WidgetBtnIntimacy         = self.WidgetBtnIntimacy --- 好感度按钮
    self.tAttractionLevelHeartList = self.tAttractionLevelHeartList --- 好感度的爱心图标列表

    self.tBasicAttributeWidgetList = self.tBasicAttributeWidgetList --- 基础属性的组件列表
    self.BtnAttribute              = self.BtnAttribute --- 查看详细属性

    self.BtnHistory                = self.BtnHistory --- 传记
    self.WidgetStaminaIntimacy     = self.WidgetStaminaIntimacy --- 体力与好感度组件
    self.WidgetLevelEquip          = self.WidgetLevelEquip --- 等级与装备组件（装备部分已废弃）
    self.WidgetAttribute           = self.WidgetAttribute --- 属性组件

    self.BtnLeft                   = self.BtnLeft --- 切换上一个侠客
    self.BtnRight                  = self.BtnRight --- 切换下一个侠客

    self.BtnAddLevel               = self.BtnAddLevel --- 打开升级心法界面

    self.WidgetAnchorLeftPop       = self.WidgetAnchorLeftPop --- 用于挂载左侧侧边栏界面的组件
    self.LayouttSkill              = self.LayouttSkill --- 武学招式的layout

    self.tStageBtnList             = self.tStageBtnList --- 武学境界的按钮列表
    self.tStageIconList            = self.tStageIconList --- 武学境界的图标列表
    self.tStageWidgetLockList      = self.tStageWidgetLockList --- 武学境界的未解锁组件列表

    self.BtnHistory                = self.BtnHistory --- 传记按钮

    self.MiniScene                 = self.MiniScene --- 摆放npc的场景组件

    self.LayoutCurrency            = self.LayoutCurrency --- 右上角货币的layout

    self.ImgAddLevel               = self.ImgAddLevel --- 升级按钮图片
    self.ImgAddLevelBg             = self.ImgAddLevelBg --- 升级按钮背景图片

    self.BtnExterior               = self.BtnExterior --- 外观按钮

    self.TouchContainer            = self.TouchContainer --- 用于实现模型旋转的组件

    self.ImgLock                   = self.ImgLock --- 试用侠客的装备栏显示锁定图标
    self.ImgTestMask               = self.ImgTestMask --- 试用图标
    self.ImgFrist                  = self.ImgFrist --- 首次寻访必得提示

    self.LayoutStaminaNum          = self.LayoutStaminaNum --- 体力值的layout
    self.LabelSoloHint             = self.LabelSoloHint --- 单人模式的提示

    self.LabelFight1               = self.LabelFight1 --- 战力

    self.SliderBarLevelUp          = self.SliderBarLevelUp --- 等级经验进度
    self.LayoutLevel               = self.LayoutLevel --- 等级的layout

    self.BtnLimit                  = self.BtnLimit --- 限定标记的按钮

    self.LabelXunFangNum           = self.LabelXunFangNum --寻访次数
end

function UIPartnerDetailsView:OnEnter(dwID, tShowPartnerIDList, dwPlayerID, nPartnerViewOpenType)
    self.dwID                 = dwID
    self.tShowPartnerIDList   = tShowPartnerIDList
    self.dwPlayerID           = dwPlayerID
    ---@see PartnerViewOpenType
    self.nPartnerViewOpenType = nPartnerViewOpenType

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit                     = true

        -- 是否需要播放入场动画和语音
        self.bNeedPlayEnterActAndVoice = true
    end

    if not Partner_IsSelfPlayer(self.dwPlayerID) then
        local player = GetPlayer(self.dwPlayerID)

        if player then
            self.szGlobalID = player.GetGlobalID()

            -- 与端游一样，dwCenterID取0，只查询当前服务器
            PeekOtherPlayerNpcAssistedInfo(0, self.szGlobalID, self.dwID)
        end
    end

    self:UpdateInfo()
end

function UIPartnerDetailsView:OnExit()
    self.bInit = false

    self:CleanUpModelView()

    self:UnRegEvent()

    UITouchHelper.UnBindModel()

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end
end

function UIPartnerDetailsView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAttribute, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelDetailedAttributePop, self.dwID, self.dwPlayerID)
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        local nIndex = self:GetCurrentIndex()
        if nIndex <= 1 then
            return
        end

        UIHelper.RemoveAllChildren(self.WidgetAnchorLeftPop)

        self.dwID                      = self.tShowPartnerIDList[nIndex - 1]

        self.bNeedPlayEnterActAndVoice = true

        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        local nIndex = self:GetCurrentIndex()
        if nIndex >= #self.tShowPartnerIDList then
            return
        end

        UIHelper.RemoveAllChildren(self.WidgetAnchorLeftPop)

        self.dwID                      = self.tShowPartnerIDList[nIndex + 1]

        self.bNeedPlayEnterActAndVoice = true

        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnAddLevel, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelPartnerUpPop, self.dwID)
    end)

    UIHelper.BindUIEvent(self.BtnHistory, EventType.OnClick, function()
        -- 复用这里的 ModelView，所以不需要隐藏起来
        UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, nil, VIEW_ID.PanelRoleVoice)
        UIMgr.Open(VIEW_ID.PanelRoleVoice, self.dwID, self.hModelView)
    end)

    UIHelper.BindUIEvent(self.BtnLocation, EventType.OnClick, function()
        self:OnClickBtnLocation()
    end)

    UIHelper.BindUIEvent(self.WidgetBtnIntimacy, EventType.OnClick, function()
        self:ShowIntimacyTips()
    end)

    UIHelper.BindUIEvent(self.BtnExterior, EventType.OnClick, function()
        -- 复用这里的 ModelView，所以不需要隐藏起来
        UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, nil, VIEW_ID.PanelPartnerAccessory, function()
            -- 回来后重新绑定转动
            UITouchHelper.BindModel(self.TouchContainer, self.hModelView, nil, nil)
        end)
        ---@see UIPartnerAccessoryView#OnEnter
        UIMgr.Open(VIEW_ID.PanelPartnerAccessory, self.dwID, self)
    end)

    UIHelper.BindUIEvent(self.BtnLimit, EventType.OnClick, function()
        local tInfo = Table_GetPartnerNpcInfo(self.dwID)

        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnLimit, TipsLayoutDir.BOTTOM_LEFT, UIHelper.GBKToUTF8(tInfo.szLimitTip))
    end)

    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
        ChatHelper.ChatAINpcTo(self.dwID)
    end)
end

function UIPartnerDetailsView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nRetCode, dwID)
        if nRetCode == NPC_ASSISTED_RESULT_CODE.NPC_ASSISTED_INFO_CHANGE then
            --数据变动
            self:UpdateInfo()
        end

        if not Partner_IsSelfPlayer(self.dwPlayerID) and self.dwPlayerID == dwID then
            -- 查看他人侠客时dwID为对应玩家ID
            if nRetCode == NPC_ASSISTED_RESULT_CODE.OTHER_PLAYER_NPC_ASSISTED_INFO_SYNC_OVER then
                -- 更新其他玩家的某个侠客详细信息结束
                self:UpdateInfo()
            end
        end
    end)

    -- 注册npc模型的必要事件，从而实现转动功能
    RegisterNpcModelEvent(szModelFrame)

    -- 点击关闭侧边栏时，取消勾选武学选中状态
    Event.Reg(self, EventType.OnClickToHide, function()
        for _, tWidgetSkillCell in ipairs(UIHelper.GetChildren(self.LayouttSkill)) do
            local script = UIHelper.GetBindScript(tWidgetSkillCell)
            UIHelper.SetSelected(script.TogSkill, false, false)
        end
    end)

    Event.Reg(self, "On_Partner_GetTaskID", function(dwTaskID)
        self:OpenPartnerTaskPanel(dwTaskID)
    end)

    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        if self.scriptDownload then
            self:UpdateMiniScene(self.tNpcRepresentID, self.scriptDownload)
        end
    end)
end

function UIPartnerDetailsView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerDetailsView:UpdateInfo()
    local tInfo = Table_GetPartnerNpcInfo(self.dwID)

    self.bHave  = Partner_GetPartnerInfo(self.dwID, self.dwPlayerID) ~= nil

    UIHelper.SetVisible(self.BtnHistory, self.bHave and not tInfo.bTryOut)
    UIHelper.SetVisible(self.WidgetStaminaIntimacy, self.bHave)
    UIHelper.SetVisible(self.WidgetBtnIntimacy, self.bHave)
    UIHelper.SetVisible(self.LayoutStaminaNum, self.bHave and not tInfo.bTryOut)
    UIHelper.SetVisible(self.WidgetLevelEquip, self.bHave)
    UIHelper.SetVisible(self.BtnExterior, self.bHave and Partner_IsSelfPlayer(self.dwPlayerID) and not tInfo.bTryOut)

    UIHelper.SetVisible(self.BtnLocation, not self.bHave)
    UIHelper.SetVisible(self.LabelState, not self.bHave)

    -- 如果是剧情侠客，则隐藏或禁用部分组件
    UIHelper.SetVisible(self.ImgTestMask, tInfo.bTryOut)

    UIHelper.SetEnable(self.BtnAddLevel, not tInfo.bTryOut)
    UIHelper.SetVisible(self.ImgAddLevel, not tInfo.bTryOut)
    UIHelper.SetVisible(self.ImgAddLevelBg, not tInfo.bTryOut)

    UIHelper.SetEnable(self.BtnExterior, not tInfo.bTryOut)

    UIHelper.SetEnable(self.BtnHistory, not tInfo.bTryOut)

    UIHelper.SetVisible(self.LabelSoloHint, tInfo.bTryOut)

    local nIndex = self:GetCurrentIndex()
    UIHelper.SetVisible(self.BtnLeft, 1 < nIndex and nIndex <= #self.tShowPartnerIDList)
    UIHelper.SetVisible(self.BtnRight, 1 <= nIndex and nIndex < #self.tShowPartnerIDList)

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tInfo.szName))

    local szLimitFrame = PartnerData.GetLimitedSpriteFrame(self.dwID, true)
    if not string.is_nil(szLimitFrame) then
        UIHelper.SetSpriteFrame(self.ImgBgBack, szLimitFrame)
    end
    UIHelper.SetVisible(self.BtnLimit, PartnerData.NeedShowLimitedTips(self.dwID))

    UIHelper.SetSpriteFrame(self.ImgType, PartnerKungfuIndexToImg[tInfo.nKungfuIndex])

    local bFirstDrawMustHit = PartnerData.IsFirstDrawMustMeet(self.dwID)
    UIHelper.SetVisible(self.ImgFrist, bFirstDrawMustHit)

    self:UpdateMiniScene()
    self:UpdateSkills()
    self:UpdateStage()
    self:UpdateAttributes()

    if self.bHave then
        self:UpdateHaveInfo()
    else
        self:UpdateNotHaveInfo()
    end

    self:InitOtherPlayerSettings()

    UIHelper.LayoutDoLayout(self.LayoutDetails)

    self:UpdateScoreInfo()
    self:UpdateMood()
end

function UIPartnerDetailsView:UpdateHaveInfo()
    local tInfo        = Table_GetPartnerNpcInfo(self.dwID)
    local tPartnerInfo = Partner_GetPartnerInfo(self.dwID, self.dwPlayerID)

    if tPartnerInfo then
        local dwStanima     = tPartnerInfo.dwStamina
        local dwMaxStanima  = GetMaxStamina()

        local nPartnerLevel = tPartnerInfo.nLevel
        local dwExp         = tPartnerInfo.dwExp
        local dwMaxExp      = 0
        local tLevelupData  = PartnerData.GetNpcAssistedLevelUpData(self.dwID, nPartnerLevel)
        if tLevelupData then
            dwMaxExp = tLevelupData.nExperience
        end

        local nMaxLevel = Partner_GetPartnerMaxLevel()

        UIHelper.SetString(self.LabelStaminaNum, string.format("%d/%d", dwStanima, dwMaxStanima))
        UIHelper.SetString(self.LabelLevel, string.format("%d/%d", nPartnerLevel, nMaxLevel))
        UIHelper.SetString(self.LabelLevelProgress, string.format("%d/%d", dwExp, dwMaxExp))

        UIHelper.SetProgressBarPercent(self.SliderBarLevelUp, 100 * dwExp / dwMaxExp)

        UIHelper.SetVisible(self.BtnAddLevel, nPartnerLevel < nMaxLevel)
        UIHelper.LayoutDoLayout(self.LayoutLevel)

        local nAttraction   = tPartnerInfo.dwFSExp
        local nLevel, fP, _ = GDAPI_GetHeroFSstar(nAttraction)

        for idx, uiImgHeart in ipairs(self.tAttractionLevelHeartList) do
            -- 仅显示已达成部分的红心
            UIHelper.SetVisible(uiImgHeart, (idx < nLevel) or (idx == nLevel and fP == 1.0))
        end

        UIHelper.SetVisible(self.LabelXunFangNum, false)
    end
end

function UIPartnerDetailsView:UpdateNotHaveInfo()
    -- note: 引导信息改为直接打开喝茶界面，无需再处理label和按钮的显示信息了
    local pPlayer = Partner_GetPlayer(self.dwPlayerID)
    if not pPlayer then
        return
    end

    local dwID        = self.dwID

    local szLabelText = ""
    local szTryText   = ""

    local nDrawState  = GDAPI_GetHeroState(dwID)
    if nDrawState == PartnerDrawState.NotMeet then
        szLabelText = "前往寻访"

        local nTry = pPlayer.GetNpcAssistedStagePoint(self.dwID)
        if Partner_IsSelfPlayer(self.dwPlayerID) and nTry > 0 then
            szTryText = "已寻访" .. nTry .. "次"
        end
    else
        --PartnerDrawState.InTask
        szLabelText = "追踪任务"
    end

    UIHelper.SetString(self.LabelLocation, szLabelText)
    UIHelper.SetString(self.LabelXunFangNum, szTryText)
    UIHelper.SetVisible(self.LabelXunFangNum, true)
end

function UIPartnerDetailsView:OnClickBtnLocation()
    if self.bHave then
        return
    end

    local dwID = self.dwID

    if dwID == 17 then
        --- 特殊处理费大劲，不属于抽卡和园宅币购买，直接引导到对应地图
        self:OnClickBtnLocationOpenMap()
        return
    end

    local nDrawState = GDAPI_GetHeroState(dwID)
    if nDrawState == PartnerDrawState.NotMeet then
        -- 打开喝茶界面
        RemoteCallToServer("On_Hero_OpenDrawPanel", dwID)

        -- 与端游一样，打开喝茶后，关闭侠客相关界面
        UIMgr.Close(self)
        UIMgr.Close(VIEW_ID.PanelPartner)
    else
        --PartnerDrawState.InTask
        -- 打开任务界面，不过需要先尝试请求任务ID（服务器会处理自动接取任务的流程）
        RemoteCallToServer("On_Hero_GetTaskID", dwID)
    end
end

function UIPartnerDetailsView:OnClickBtnLocationOpenMap()
    local dwID       = self.dwID

    local tTrackInfo = Table_GetPartnerTrackInfo(dwID)
    if not tTrackInfo then
        return
    end

    -- todo: 暂时只处理第一个引导信息
    local tLinkInfo = tTrackInfo[1]
    local tLink     = Table_GetCareerLinkNpcInfo(tLinkInfo.nLinkID, tLinkInfo.dwMapID)

    local tPoint    = { tLink.fX, tLink.fY, tLink.fZ }
    MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tLink.szNpcName), tLink.dwMapID, tPoint, nil, "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_else.png")
    UIMgr.Open(VIEW_ID.PanelMiddleMap, tLink.dwMapID, 0)
end

function UIPartnerDetailsView:OpenPartnerTaskPanel(dwTaskID)
    QuestData.SetTracingQuestID(dwTaskID)
    QuestData.RemoveProhibitTraceQuestID(dwTaskID)

    UIMgr.Open(VIEW_ID.PanelTask)
    UIMgr.Close(self)
    UIMgr.Close(VIEW_ID.PanelPartner)
end

function UIPartnerDetailsView:GetCurrentIndex()
    local nIndex = -1
    for idx, dwPartnerID in ipairs(self.tShowPartnerIDList) do
        if dwPartnerID == self.dwID then
            nIndex = idx
            break
        end
    end

    return nIndex
end

function UIPartnerDetailsView:CleanUpModelView()
    if self.hModelView then
        self.hModelView:release()
        self.hModelView = nil
    end

    self.m_scene = nil
end

function UIPartnerDetailsView:UpdateMiniScene(tPreviewRepresentID, scriptDownload)
    local pPlayer = Partner_GetPlayer(self.dwPlayerID)
    if not pPlayer then
        return
    end

    -- 初始化 model view
    local hModelView = self.hModelView

    if PartnerData.bNotMgrSceneByNpcModelView and not self.m_scene then
        self.m_scene = PartnerData.GetOrCreateScene()
    end

    if not hModelView then
        hModelView = NpcModelView.CreateInstance(NpcModelView)
        hModelView:ctor()
        hModelView:init(self.m_scene, PartnerData.bNotMgrSceneByNpcModelView, true, PartnerData.szSceneFilePath, "PartnerDetail")
        self.MiniScene:SetScene(hModelView.m_scene)

        -- 使用同一个场景实例
        self.m_scene    = hModelView.m_scene

        self.hModelView = hModelView
    end

    -- 加载模型
    local dwPartnerID = self.dwID

    local tRepresentID
    if Partner_IsSelfPlayer(self.dwPlayerID) then
        tRepresentID = Partner_GetEquippedRepresentID(dwPartnerID, self.dwPlayerID)
    else
        -- 获取模板
        local tNpcRepresentID = GetNpcAssistedTemplateRepresentID(dwPartnerID)
        tRepresentID          = PartnerView.NPCRepresentToPlayerRepresent(tNpcRepresentID)

        -- 将外观应用上去
        local tExteriorList   = Partner_GetEquippedExteriorList(self.dwPlayerID, dwPartnerID)
        for nType, tInfo in pairs(tExteriorList) do
            PartnerExterior.UpdateRepresentID(tRepresentID, nType, tInfo)
        end
    end

    if tPreviewRepresentID then
        tRepresentID = tPreviewRepresentID
    end
    self.tNpcRepresentID = clone(tRepresentID)
    self.scriptDownload = scriptDownload

    local tNpcModel = Partner_GetNpcModelInfo(dwPartnerID)
    local tbCamera  = UICameraTab["PartnerNpc"][self.dwID] or UICameraTab["PartnerNpc"]["default"]

    tRepresentID = NpcAssited_TransformDefaultResource(tNpcModel.nRoleType, GetNpcAssistedTemplateID(dwPartnerID), 0, tRepresentID)
    hModelView:LoadNpcRes(tNpcModel.dwOrigModelID, false, tNpcModel.nRoleType, false, tNpcModel.bSheath, tRepresentID)

    -- npc初始朝向角度，增大会往左转，减小会往右转
    local fNpcYaw        = tbCamera.nModelYaw

    hModelView.fTurnYaw  = math.pi / 200
    hModelView.dwModelID = tNpcModel.dwOrigModelID

    hModelView:UnloadModel()
    hModelView:LoadModel()
    hModelView:PlayAnimation("Idle", "loop")
    hModelView:SetCameraPos(unpack(tbCamera.tbCameraPos))
    hModelView:SetCameraLookPos(unpack(tbCamera.tbCameraLookPos))
    hModelView:SetCameraPerspective(unpack(tbCamera.tbCameraPerspective))
    hModelView:SetTranslation(unpack(tbCamera.tbModelTranslation))
    hModelView:SetYaw(tbCamera.nModelYaw)
    hModelView:SetScaling(tNpcModel.fScale)

    self.m_scene:SetMainPlayerPosition(unpack(tbCamera.tbModelTranslation))

    -- 注册一下，从而后面可以注册对应的事件
    local tNpcParam                                           = {
        szName = szModelName,
        szFrameName = szModelFrame,
        szFramePath = szModelFramePath,
        hNpcModelView = hModelView,
        Viewer = self.MiniScene,
        scene = hModelView.m_scene,
        bNotMgrScene = true,
        fNpcYaw = fNpcYaw,
    }
    NpcModelPreview.tResisterFrame[szModelFrame][szModelName] = tNpcParam
    --RegisterNpcModelPreview(tNpcParam)

    UITouchHelper.BindModel(self.TouchContainer, hModelView, nil, nil)

    if self.bNeedPlayEnterActAndVoice then
        self.bNeedPlayEnterActAndVoice = false

        self:OnPartnerActionEvent(self.dwID, 1)
    end

    self:UpdateDownloadEquipRes(tNpcModel.nRoleType, self.tNpcRepresentID, scriptDownload)
end

function UIPartnerDetailsView:UpdateSkills()
    UIHelper.RemoveAllChildren(self.LayouttSkill)

    local dwID     = self.dwID
    local tSkill   = Table_GetPartnerSkillInfo(dwID)
    local tPartner = Partner_GetPartnerInfo(dwID, self.dwPlayerID)
    local nStage   = 0
    if tPartner then
        nStage = tPartner.nStage
    end
    for _, tSkillInfo in ipairs(tSkill) do
        local dwSkillID   = tSkillInfo.dwSkillID
        local nSkillLevel = tSkillInfo.nSkillLevel

        local uiScript    = UIMgr.AddPrefab(PREFAB_ID.WidgetSkillCell, self.LayouttSkill, dwSkillID, nSkillLevel)
        UIHelper.BindUIEvent(uiScript.TogSkill, EventType.OnClick, function()
            UIHelper.RemoveAllChildren(self.WidgetAnchorLeftPop)
            UIHelper.SetVisible(self.WidgetAnchorLeftPop, true)
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerDetailsSkillLeftPop, self.WidgetAnchorLeftPop, dwSkillID, nSkillLevel)
            UIHelper.WidgetFoceDoAlign(script)
            UIHelper.BindUIEvent(script.BtnCloseLeft, EventType.OnClick, function()
                UIHelper.RemoveAllChildren(self.WidgetAnchorLeftPop)
            end)
        end)
    end

    UIHelper.LayoutDoLayout(self.LayouttSkill)
end

function UIPartnerDetailsView:UpdateStage()
    local dwID          = self.dwID
    local tPartnerInfo  = Partner_GetPartnerInfo(dwID, self.dwPlayerID)
    local nPartnerStage = 0
    if tPartnerInfo then
        nPartnerStage = tPartnerInfo.nStage
    end
    local tStageInfoList = Table_GetPartnerStageInfo(dwID)

    for _, tStageInfo in ipairs(tStageInfoList) do
        local nStage = tStageInfo.nStage

        if nStage > 0 then
            local bLocked = nPartnerStage < nStage

            local nIconID = Table_GetSkillIconID(tStageInfo.dwSkillID, tStageInfo.nLevel)

            UIHelper.SetVisible(self.tStageWidgetLockList[nStage], bLocked)

            UIHelper.SetItemIconByIconID(self.tStageIconList[nStage], nIconID)
            UIHelper.UpdateMask(UIHelper.GetParent(self.tStageIconList[nStage]))

            UIHelper.BindUIEvent(self.tStageBtnList[nStage], EventType.OnClick, function()
                UIHelper.RemoveAllChildren(self.WidgetAnchorLeftPop)

                local tGiftInfo = Table_GetPartnerGiftInfo(dwID)
                if tGiftInfo == nil or #tGiftInfo == 0 then
                    -- 当该角色未配置领悟武学境界所需材料时，点击不显示侧边栏
                    return
                end

                UIHelper.SetVisible(self.WidgetAnchorLeftPop, true)
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerDetailsSkillUpLeftPop, self.WidgetAnchorLeftPop, dwID, nStage, self.dwPlayerID)
                UIHelper.WidgetFoceDoAlign(script)
                UIHelper.BindUIEvent(script.BtnCloseLeft, EventType.OnClick, function()
                    UIHelper.RemoveAllChildren(self.WidgetAnchorLeftPop)
                end)
            end)
        end
    end
end

function UIPartnerDetailsView:UpdateAttributes()
    local pPlayer = Partner_GetPlayer(self.dwPlayerID)
    if not pPlayer then
        return
    end

    local nLevel       = 1
    local nStage       = 0

    local tPartnerInfo = Partner_GetPartnerInfo(self.dwID, self.dwPlayerID)
    if tPartnerInfo then
        nLevel = tPartnerInfo.nLevel
        nStage = tPartnerInfo.nStage
    end

    local tPartnerAttribute = GDAPI_GetHeroAttributes(pPlayer, self.dwID, nLevel, nStage)
    for idx, uiWidget in ipairs(self.tBasicAttributeWidgetList) do
        local labelName, labelValue = table.unpack(UIHelper.GetChildren(uiWidget))

        local szName                = g_tStrings.STR_PARTNER_ATTRIBUTE[idx]

        local nAttributeIndex       = PartnerData.tAttributeIndex[idx]
        local nValue                = tPartnerAttribute[nAttributeIndex]

        UIHelper.SetString(labelName, szName)
        UIHelper.SetString(labelValue, nValue)
    end

    -- 不论是否获取，都显示角色属性信息
    UIHelper.SetVisible(self.WidgetAttribute, true)
end

function UIPartnerDetailsView:ShowIntimacyTips()
    local tPartnerInfo = Partner_GetPartnerInfo(self.dwID, self.dwPlayerID)
    if not tPartnerInfo then
        return
    end

    local nAttraction           = tPartnerInfo.dwFSExp
    local nLevel, _, fAddCombat = GDAPI_GetHeroFSstar(nAttraction)
    local szDesc                = g_tStrings.STR_PARTNER_ATTRACTION_LEVEL[nLevel]
    local nAddCombatScale       = fAddCombat * 100
    local szTip                 = FormatString(g_tStrings.STR_PARTNER_ATTRACTION_TIP, szDesc, nAttraction, nAddCombatScale)

    local nX                    = UIHelper.GetWorldPositionX(self.WidgetBtnIntimacy)
    local nY                    = UIHelper.GetWorldPositionY(self.WidgetBtnIntimacy)
    local _, scriptTips         = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetPublicLabelTips, nX, nY)
    scriptTips:OnEnter(szTip)
end

--dwEventID:
--1-动作待机；
--2-升级；
--3-进阶；
--4-装备强化；
function UIPartnerDetailsView:OnPartnerActionEvent(dwPartnerID, dwEventID)
    local dwID = self.dwID
    if dwID ~= dwPartnerID then
        return
    end
    local tPartnerInfo = Table_GetPartnerNpcInfo(dwPartnerID)
    if not tPartnerInfo then
        return
    end

    NpcModelPreview.PlayAni(szModelFrame, szModelName, tPartnerInfo.nDefaultActID, "loop")

    local tActSetting = Table_GetPartnerActSetting(dwPartnerID, dwEventID)
    if not tActSetting then
        return
    end
    local tActList = StringParse_PointList(tActSetting.szActIndex)
    if #tActList > 1 then
        local nRate    = tActSetting.fRate * 100
        local nRandom1 = math.random(1, 100)
        if nRandom1 < nRate then
            local nCount       = #tActList
            local nRandomIndex = math.random(1, nCount)
            local nActIndex    = tActList[nRandomIndex]
            local tActInfo     = Table_GetPartnerActVoiceInfo(nActIndex)
            self:PartnerPlayAction(tActInfo.dwActID)
            self:PartnerPlaySound(tActInfo.szVoicePath)
        end
    else
        local nIndex = tActList[1]
        local tLine  = Table_GetPartnerActVoiceInfo(nIndex)
        self:PartnerPlayAction(tLine.dwActID)
        self:PartnerPlaySound(tLine.szVoicePath)
    end
end

function UIPartnerDetailsView:PartnerPlayAction(dwActID)
    NpcModelPreview.PlayAni(szModelFrame, szModelName, dwActID, "once")
end

function UIPartnerDetailsView:PartnerPlaySound(szVoicePath)
    local dwLastPlaySoundID = Partner_GetLastPlaySoundID()
    if dwLastPlaySoundID then
        SoundMgr.StopSound(dwLastPlaySoundID, true)
    end
    Partner_SetPlayingSoundPath(szVoicePath)
    SoundMgr.PlaySound(SOUND.CHARACTER_SPEAK, szVoicePath)
end

function UIPartnerDetailsView:InitOtherPlayerSettings()
    -- 如果是查看他人的侠客，则隐藏部分组件
    if Partner_IsSelfPlayer(self.dwPlayerID) then
        return
    end

    UIHelper.SetVisible(self.LayoutCurrency, false)

    UIHelper.SetVisible(self.LabelLocation, false)
    UIHelper.SetVisible(self.BtnLocation, false)

    UIHelper.SetVisible(self.BtnHistory, false)

    UIHelper.SetEnable(self.BtnAddLevel, false)
    UIHelper.SetVisible(self.ImgAddLevel, false)
    UIHelper.SetVisible(self.ImgAddLevelBg, false)
    UIHelper.SetVisible(self.LabelXunFangNum, false)
end

function UIPartnerDetailsView:UpdateScoreInfo()
    local layoutFight = UIHelper.GetParent(self.LabelFight1)
    PartnerData.UpdateScoreInfo(self.dwPlayerID, self.dwID, self.LabelFight1, layoutFight)
end

function UIPartnerDetailsView:UpdateMood()
    UIHelper.SetVisible(self.BtnChat, false)
    if not ChatAINpcMgr.IsOpen() then
        return
    end

    local tInfo = Table_GetPartnerNpcInfo(self.dwID)
    local bTryOut = tInfo and tInfo.bTryOut
    local bAIChat = tInfo and tInfo.bAIChat
    if not self.bHave or bTryOut or not bAIChat then
        return
    end

    UIHelper.SetVisible(self.BtnChat, true)

    local nMood = ChatAINpcMgr.GetNpcMood(self.dwID)
    UIHelper.SetString(self.LabelMood, string.format(g_tStrings.STR_NPC_MOOD, nMood))
    UIHelper.SetVisible(self.LabelMood, ChatAINpcMgr.IsShowMood())
end

function UIPartnerDetailsView:UpdateDownloadEquipRes(nRoleType, tRepresentID, scriptDownload)
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    if not scriptDownload then
        return
    end
    local tEquipList, tEquipSfxList = PakEquipResData.GetRepresentPakResource(nRoleType, 0, tRepresentID)
    local tConfig = {}
    tConfig.bLong = true
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    CoinShopPreview.UpdateSimpleDownloadBtn(scriptDownload, self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

return UIPartnerDetailsView