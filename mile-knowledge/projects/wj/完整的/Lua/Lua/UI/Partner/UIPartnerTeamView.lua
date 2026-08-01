-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerTeamView
-- Date: 2023-11-02 15:14:16
-- Desc: 侠客编队
-- Prefab: PanelPartnerTeam
-- ---------------------------------------------------------------------------------

---@class UIPartnerTeamView
local UIPartnerTeamView = class("UIPartnerTeamView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerTeamView:_LuaBindList()
    self.BtnClose               = self.BtnClose --- 关闭

    self.ScrollViewLeftCard     = self.ScrollViewLeftCard --- 侠客列表的scroll view

    self.BtnPartnerDetail       = self.BtnPartnerDetail --- 角色详情按钮

    self.BtnAddOrRemove         = self.BtnAddOrRemove --- 加入/移除按钮
    self.LabelAddOrRemove       = self.LabelAddOrRemove --- 加入/移除的按钮文字

    self.MiniScene              = self.MiniScene --- 供共鸣配置和助战配置界面使用的MiniScene

    self.BtnScreen              = self.BtnScreen --- 筛选按钮

    self.LabelTitle             = self.LabelTitle --- 标题

    self.ScrollQuickTeamZhuZhan = self.ScrollQuickTeamZhuZhan --- 助战的快捷编队专用的scroll view
    self.LabelSoloHint          = self.LabelSoloHint --- 单人模式的提示

    self.WidgetRoleInfo         = self.WidgetRoleInfo --- 当前选择的侠客信息
    self.ImgName01              = self.ImgName01 --- 心法类型图标
    self.LabelName01            = self.LabelName01 --- 名称
    self.LabelLevel01           = self.LabelLevel01 --- 等级
    self.LabelStrength1         = self.LabelStrength1 --- 体力
    self.LabelFight1            = self.LabelFight1 --- 战力
end

function UIPartnerTeamView:OnEnter(nSelTeamType, bQuickSetTeam, nCurrentSlotIndex, shared_hModelViewList)
    self.nSelTeamType          = nSelTeamType
    self.bQuickSetTeam         = bQuickSetTeam

    -- 单选模式的参数
    self.nCurrentSlotIndex     = nCurrentSlotIndex

    -- 当前选中的侠客ID列表，初始值为当前已配置的侠客ID列表
    self.tSelTeamTypeList      = self:GetSelTeamTypeList()

    -- 快捷编队模式的参数
    -- 复用 UIPartnerFetter 的场景实例，从而无需再次创建，看起来更连贯
    self.shared_hModelViewList = shared_hModelViewList

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()

        PartnerData.InitFilterDef()
        FilterDef.Partner.Reset()

        self.bInit = true
    end
    self:UpdateInfo()
end

function UIPartnerTeamView:OnExit()
    self.bInit = false

    self:CleanUpModelView()

    self:UnRegEvent()
end

function UIPartnerTeamView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPartnerDetail, EventType.OnClick, function()
        local tShowPartnerIDList = {}
        local tAllPartnerList    = self:GetFilterPartnerList()
        if tAllPartnerList then
            for _, tInfo in ipairs(tAllPartnerList) do
                table.insert(tShowPartnerIDList, tInfo.dwID)
            end
        end

        UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, self.hModelView, VIEW_ID.PanelPartnerDetails, function()
            self:UpdateNpcModel()
        end)
        UIMgr.Open(VIEW_ID.PanelPartnerDetails, self.dwSelectedPartnerID, tShowPartnerIDList)
    end)

    UIHelper.BindUIEvent(self.BtnAddOrRemove, EventType.OnClick, function()
        if not self.bQuickSetTeam then
            self:AddOrRemove()
        else
            self:ConfirmQuickSetTeam()
        end
    end)

    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreen, TipsLayoutDir.TOP_RIGHT, FilterDef.Partner)
    end)

    if self.bQuickSetTeam then
        -- 快捷编队状态右下角的按钮需要调整下
        UIHelper.SetVisible(self.BtnPartnerDetail, false)
        UIHelper.SetString(self.LabelAddOrRemove, "确定")
    end
end

function UIPartnerTeamView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nResultCode, nArg0, nArg1, nArg2)
        if nResultCode == NPC_ASSISTED_RESULT_CODE.SET_ASSISTED_LIST_SUCCESS then
            --设置助战列表成功
            UIMgr.Close(self)
        elseif nResultCode == NPC_ASSISTED_RESULT_CODE.SET_MORPH_LIST_SUCCESS then
            --设置幻化列表成功
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.Partner.Key then
            return
        end

        self.tShowPartnerIDList = PartnerData.GetFilteredPartnerIDList(tbInfo)
        self:UpdateInfo()
    end)
end

function UIPartnerTeamView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerTeamView:UpdateInfo()
    local szTitle = string.format("%s编队", self:GetSelTeamTypeName())
    UIHelper.SetString(self.LabelTitle, szTitle)

    self:UpdateCardList()

    local uiLabelSoloHint = UIHelper.GetChildByName(UIHelper.GetParent(self.ScrollQuickTeamZhuZhan), "LabelSoloHint")
    if uiLabelSoloHint then
        UIHelper.SetVisible(uiLabelSoloHint, self.bQuickSetTeam)
    end
end

function UIPartnerTeamView:UpdateCardList()
    local bIsAssistQuickSetTeam = self:IsAssistQuickSetTeam()
    UIHelper.SetVisible(self.ScrollViewLeftCard, not bIsAssistQuickSetTeam)
    UIHelper.SetVisible(self.ScrollQuickTeamZhuZhan, bIsAssistQuickSetTeam)

    local scrollView = self:GetPartnerScrollView()

    UIHelper.RemoveAllChildren(scrollView)

    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local tFilterList = self:GetFilterPartnerList()

    for _, tInfo in ipairs(tFilterList) do
        ---@type UIRoleItem
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetRoleItem, scrollView)
        script:OnEnter(tInfo)
    end

    local tSelTeamTypeList   = self:GetSelTeamTypeList()
    local tOtherTeamTypeList = self:GetOtherTeamTypeList()

    local dwDefaultSelectPartnerID
    if tSelTeamTypeList and tSelTeamTypeList[self.nCurrentSlotIndex] and tSelTeamTypeList[self.nCurrentSlotIndex] ~= 0 then
        dwDefaultSelectPartnerID = tSelTeamTypeList[self.nCurrentSlotIndex]
    end

    for idx, cell in ipairs(UIHelper.GetChildren(scrollView)) do
        ---@type UIRoleItem
        local script  = UIHelper.GetBindScript(cell)
        local dwID    = script.tInfo.dwID

        -- 当前类别的已配置的角色标记序号
        local bChosen = table.contain_value(self.tSelTeamTypeList, dwID)
        script:UpdateSelectedIndex(self.tSelTeamTypeList)

        UIHelper.BindUIEvent(script.BtnChosenPartner, EventType.OnClick, function()
            --- todo: 编队和召请点这个按钮后的逻辑似乎有很多相同的部分，看看能否整合到 UIRoleItem 里，方便后续维护
            UIHelper.SetVisible(script.ImgSelectNum, not UIHelper.GetVisible(script.ImgSelectNum))

            script:UnNewAddPartner()

            if self.bQuickSetTeam and script.tInfo.bHave then
                -- 快捷编队状态已拥有侠客可以调整打钩状态

                -- 最多可以勾选3个
                local bCurrentSelected = UIHelper.GetVisible(script.ImgSelectNum)
                if bCurrentSelected then
                    local nSelectedCount = 0
                    for _, aCell in ipairs(UIHelper.GetChildren(scrollView)) do
                        local aScript = UIHelper.GetBindScript(aCell)
                        if UIHelper.GetVisible(aScript.ImgSelectNum) then
                            nSelectedCount = nSelectedCount + 1
                        end
                    end

                    if nSelectedCount > self:GetMaxTeamSize() then
                        TipsHelper.ShowNormalTip(string.format("%s侠客数量已到上限", self:GetSelTeamTypeName()))
                        UIHelper.SetVisible(script.ImgSelectNum, false)
                        bCurrentSelected = false
                    end
                end

                -- 一键选择时，实际上也可以选择另一类别的侠客，若勾选了，则暂时隐藏其类别标记
                local bOtherChosen = table.contain_value(tOtherTeamTypeList, dwID)
                if bOtherChosen then
                    if bCurrentSelected then
                        -- 勾选时，隐藏另外标记
                        UIHelper.SetVisible(script.ImgMark, false)
                    else
                        -- 若取消勾选，则还原标记
                        UIHelper.SetVisible(script.ImgMark, true)
                    end
                end

                --- 更新选中列表数据
                if bCurrentSelected then
                    --- 勾选时放入空位，或者放到末尾
                    local nIndex = table.get_key(self.tSelTeamTypeList, 0)
                    if nIndex then
                        self.tSelTeamTypeList[nIndex] = dwID
                    else
                        table.insert(self.tSelTeamTypeList, dwID)
                    end
                else
                    --- 取消勾选时将该位置空出来
                    local nIndex                  = table.get_key(self.tSelTeamTypeList, dwID)
                    if nIndex then
                        self.tSelTeamTypeList[nIndex] = 0
                    end
                end
                for _, _cell in ipairs(UIHelper.GetChildren(scrollView)) do
                    ---@type UIRoleItem
                    local scriptCell = UIHelper.GetBindScript(_cell)
                    scriptCell:UpdateSelectedIndex(self.tSelTeamTypeList)
                end

                return
            end

            -- 这个选项不应受点击影响，但toggle目前没有禁用点击的接口，所以这里强行修改为逻辑上的状态
            UIHelper.SetVisible(script.ImgSelectNum, bChosen)
        end)

        -- 其他类别的已配置的角色则显示左下角小图标
        local bOtherChosen = table.contain_value(tOtherTeamTypeList, dwID)
        UIHelper.SetVisible(script.ImgMark, bOtherChosen)
        if bOtherChosen then
            -- 非当前类别对应的图标
            local szImgOtherTeamType
            if self.nSelTeamType == PARTNER_TEAM_TYPE.ASSIST then
                -- 当前为助战，则另一类别为 共鸣
                szImgOtherTeamType = "UIAtlas2_Partner_Partner_iconMark1.png"
            else
                -- 否则，另一类别为 助战
                szImgOtherTeamType = "UIAtlas2_Partner_Partner_iconMark2.png"
            end

            UIHelper.SetSpriteFrame(script.ImgMark, szImgOtherTeamType)
        end

        UIHelper.SetToggleGroupIndex(script.ToggleCurrentSelect, ToggleGroupIndex.PartnerSelectRole)

        if not self.bQuickSetTeam then
            UIHelper.SetEnable(script.BtnChosenPartner, false)

            -- 单选模式
            UIHelper.BindUIEvent(script.ToggleCurrentSelect, EventType.OnClick, function()
                script:UnNewAddPartner()

                self:OnClickSelectPartnerIcon(dwID)
            end)

            if (dwDefaultSelectPartnerID ~= nil and dwID == dwDefaultSelectPartnerID) or (dwDefaultSelectPartnerID == nil and idx == 1) then
                -- 当点击已选择的侠客进入选择模式，自动选中该槽位的侠客。否则默认选中第一个
                UIHelper.SetSelected(script.ToggleCurrentSelect, true)
                self:OnClickSelectPartnerIcon(dwID)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(scrollView)

    if self.bQuickSetTeam then
        -- 快捷编队
        self:UpdateNpcModel()
    end
end

function UIPartnerTeamView:OnClickSelectPartnerIcon(dwID)
    self.dwSelectedPartnerID = dwID

    self:UpdateNpcModel()

    local dwReplacedID     = self:GetCurrentSlotPartnerID()
    local dwAssistedID     = self.dwSelectedPartnerID

    local tSelTeamTypeList = self:GetSelTeamTypeList()
    local bChosen          = table.contain_value(tSelTeamTypeList, dwAssistedID)

    if bChosen and dwReplacedID == dwAssistedID then
        UIHelper.SetString(self.LabelAddOrRemove, "换下" .. self:GetSelTeamTypeName())
    else
        UIHelper.SetString(self.LabelAddOrRemove, "加入" .. self:GetSelTeamTypeName())
    end

    local tInfo = Table_GetPartnerNpcInfo(dwAssistedID)
    UIHelper.SetVisible(self.LabelSoloHint, tInfo.bTryOut)

    local tPartner = Partner_GetPartnerInfo(dwAssistedID)
    local bHave    = tPartner ~= nil
    UIHelper.SetVisible(self.WidgetRoleInfo, bHave)

    if bHave then
        local szName       = UIHelper.GBKToUTF8(tInfo.szName)
        local nKungfuIndex = tInfo.nKungfuIndex

        UIHelper.SetString(self.LabelName01, szName)
        UIHelper.SetSpriteFrame(self.ImgName01, PartnerKungfuIndexToImg[nKungfuIndex])

        local layoutKungfuAndName = UIHelper.GetParent(self.LabelName01)
        UIHelper.LayoutDoLayout(layoutKungfuAndName)

        UIHelper.SetString(self.LabelLevel01, tPartner.nLevel .. "级")

        --- 单人侠客不显示以下部分
        local bShowOtherInfo = not tInfo.bTryOut

        UIHelper.SetVisible(UIHelper.GetParent(self.LabelFight1), bShowOtherInfo)
        UIHelper.SetVisible(UIHelper.GetParent(self.LabelStrength1), bShowOtherInfo)

        if bShowOtherInfo then
            local dwStanima    = tPartner.dwStamina
            local dwMaxStanima = GetMaxStamina()
            UIHelper.SetString(self.LabelStrength1, string.format("%d/%d", dwStanima, dwMaxStanima))

            self:UpdateScoreInfo(dwAssistedID)
        end
    end
end

function UIPartnerTeamView:UpdateScoreInfo()
    if not self.dwSelectedPartnerID then
        return
    end

    local layoutFight = UIHelper.GetParent(self.LabelFight1)
    PartnerData.UpdateScoreInfo(nil, self.dwSelectedPartnerID, self.LabelFight1, layoutFight)
end

function UIPartnerTeamView:CleanUpModelView()
    if self.hModelView then
        self.hModelView:release()
        self.hModelView = nil
    end

    self.m_scene = nil
end

function UIPartnerTeamView:UpdateNpcModel()
    if not self.bQuickSetTeam then
        self:UpdateNpcModelForCurrentSelectRole()
    else
        self:UpdateNpcModelListInQuickSetTeamMode()
    end
end

function UIPartnerTeamView:UpdateNpcModelForCurrentSelectRole()
    -- 初始化 model view
    local hModelView = self.hModelView

    if PartnerData.bNotMgrSceneByNpcModelView and not self.m_scene then
        self.m_scene = PartnerData.GetOrCreateScene()
    end

    if not hModelView then
        hModelView = NpcModelView.CreateInstance(NpcModelView)
        hModelView:ctor()
        hModelView:init(self.m_scene, PartnerData.bNotMgrSceneByNpcModelView, true, PartnerData.szSceneFilePath, "PartnerCurrentSelect" .. self.nSelTeamType)
        self.MiniScene:SetScene(hModelView.m_scene)

        -- 使用同一个场景实例
        self.m_scene    = hModelView.m_scene

        self.hModelView = hModelView
    end

    -- 加载模型
    local dwPartnerID  = self.dwSelectedPartnerID
    local tRepresentID = Partner_GetEquippedRepresentID(dwPartnerID)
    local tNpcModel    = Partner_GetNpcModelInfo(dwPartnerID)
    tRepresentID       = NpcAssited_TransformDefaultResource(tNpcModel.nRoleType, GetNpcAssistedTemplateID(dwPartnerID), 0, tRepresentID)

    hModelView:LoadNpcRes(tNpcModel.dwOrigModelID, false, tNpcModel.nRoleType, false, tNpcModel.bSheath, tRepresentID)
    local fBasePosX, fBasePosY, fBasePosZ = table.unpack(Const.MiniScene.PartnerView.tbTeamBasePos)
    local fBaseYaw                        = Const.MiniScene.PartnerView.fTeamBaseYaw

    -- npc初始朝向角度，增大会往左转，减小会往右转
    local fNpcYaw                         = fBaseYaw

    -- 每个npc往不同的横轴位置站，数值越小越靠右
    local fPosZ                           = fBasePosZ

    hModelView:UnloadModel()
    hModelView:LoadModel()
    hModelView:PlayAnimation("Idle", "loop")
    hModelView:SetCamera(Const.MiniScene.PartnerView.tbTeamCamera)
    hModelView:SetTranslation(fBasePosX, fBasePosY, fPosZ)
    hModelView:SetYaw(fNpcYaw)
    hModelView:SetScaling(tNpcModel.fScale)
end

function UIPartnerTeamView:GetCurrentSlotPartnerID()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local tSelTeamTypeList = self:GetSelTeamTypeList()

    local dwID             = 0
    if tSelTeamTypeList and tSelTeamTypeList[self.nCurrentSlotIndex] ~= nil then
        dwID = tSelTeamTypeList[self.nCurrentSlotIndex]
    end

    return dwID
end

function UIPartnerTeamView:GetFilterPartnerList()
    local tList = Partner_GetAllPartnerList()

    ---@type PartnerNpcInfo[]
    local tRes

    if self.tShowPartnerIDList then
        tRes = {}

        --- 快捷编队模式下，首先放入当前已勾选的侠客
        if self.bQuickSetTeam then
            for _, tInfo in ipairs(tList) do
                if table.contain_value(self.tSelTeamTypeList, tInfo.dwID) and not table.contain_value(tRes, tInfo) then
                    table.insert(tRes, tInfo)
                end
            end
        end

        --- 再放入筛选后的侠客中未包含的部分
        for _, tInfo in ipairs(tList) do
            if table.contain_value(self.tShowPartnerIDList, tInfo.dwID) and not table.contain_value(tRes, tInfo) then
                table.insert(tRes, tInfo)
            end
        end
    else
        tRes = tList
    end

    -- 编队界面的排序规则有所不同，特殊处理下
    self:SortPartnerList(tRes)

    -- 过滤掉一些不符合条件的侠客
    do
        --local BUFF_UI    = 27896--剧情模式标识
        --local bStoryMode = g_pClientPlayer.IsHaveBuff(BUFF_UI, 1)

        local tFinalList = {}
        for _, tInfo in ipairs(tRes) do
            local bOK = true

            if self.nSelTeamType == PARTNER_TEAM_TYPE.MORPH and not tInfo.bCanMorph then
                -- 幻化界面，过滤掉不可幻化的侠客
                bOK = false
                --elseif self.nSelTeamType == PARTNER_TEAM_TYPE.ASSIST and not bStoryMode and tInfo.bTryOut then
                --    -- 助战界面，非剧情模式下，过滤掉剧情模式的侠客
                --    bOK = false
            end

            if bOK then
                table.insert(tFinalList, tInfo)
            end
        end

        tRes = tFinalList
    end

    return tRes
end

function UIPartnerTeamView:SortPartnerList(tPartnerList)
    -- 排序顺序: 是否已拥有>已配置当前类型(按配置列表的顺序)>未配置>等级(仅已拥有时有)>稀有度>id>已配置其他类型
    local tSelTeamTypeList   = self.tSelTeamTypeList
    local tOtherTeamTypeList = self:GetOtherTeamTypeList()

    local nPriorityCurrent   = 3
    local nPriorityNotSet    = 2
    local nPriorityOther     = 1

    local function fnInTeamTypeToSortPriority(dwID)
        local bInCurrent = table.contain_value(tSelTeamTypeList, dwID)
        local bInOther   = table.contain_value(tOtherTeamTypeList, dwID)

        -- 已配置当前类型(3)>未配置(2)>已配置其他类型(1)
        if bInCurrent then
            return nPriorityCurrent
        elseif bInOther then
            return nPriorityOther
        else
            return nPriorityNotSet
        end
    end

    ---@param tNpcInfo1 PartnerNpcInfo
    ---@param tNpcInfo2 PartnerNpcInfo
    local function fnSort(tNpcInfo1, tNpcInfo2)
        if tNpcInfo1.bHave ~= tNpcInfo2.bHave then
            return tNpcInfo1.bHave
        end

        local nPriority1 = fnInTeamTypeToSortPriority(tNpcInfo1.dwID)
        local nPriority2 = fnInTeamTypeToSortPriority(tNpcInfo2.dwID)
        if nPriority1 ~= nPriority2 then
            return nPriority1 > nPriority2
        end

        if nPriority1 == nPriorityCurrent then
            --- 当前配置类型按照配置列表的顺序排序
            return table.get_key(tSelTeamTypeList, tNpcInfo1.dwID) < table.get_key(tSelTeamTypeList, tNpcInfo2.dwID)
        end

        if tNpcInfo1.bHave then
            if tNpcInfo1.nLevel ~= tNpcInfo2.nLevel then
                return tNpcInfo1.nLevel > tNpcInfo2.nLevel
            end
        end

        local nQuality1 = tNpcInfo1.nQuality or 0
        local nQuality2 = tNpcInfo2.nQuality or 0
        if nQuality1 ~= nQuality2 then
            return nQuality1 > nQuality2
        end

        return tNpcInfo1.dwID < tNpcInfo2.dwID
    end

    table.sort(tPartnerList, fnSort)
end

function UIPartnerTeamView:GetSelTeamTypeName()
    if self.nSelTeamType == PARTNER_TEAM_TYPE.ASSIST then
        return g_tStrings.STR_PARTNER_ASSIST
    else
        return g_tStrings.STR_PARTNER_MORPH
    end
end

function UIPartnerTeamView:GetSelTeamTypeList()
    if self.nSelTeamType == PARTNER_TEAM_TYPE.ASSIST then
        return PartnerData.GetAssistedList()
    else
        return PartnerData.GetMorphList()
    end
end

--- 返回当前类别以外的已配置角色列表
function UIPartnerTeamView:GetOtherTeamTypeList()
    if self.nSelTeamType == PARTNER_TEAM_TYPE.ASSIST then
        return PartnerData.GetMorphList()
    else
        return PartnerData.GetAssistedList()
    end
end

function UIPartnerTeamView:SetSelTeamTypeList(dwAssistedID, dwReplacedID)
    if self.nSelTeamType == PARTNER_TEAM_TYPE.ASSIST then
        local tIndexAndIDList = {
            {
                self.nCurrentSlotIndex,
                dwAssistedID,
            }
        }
        
        g_pClientPlayer.SetAssistedList(tIndexAndIDList)
    else
        g_pClientPlayer.SetMorphList(dwAssistedID, dwReplacedID)
    end
end

--- 判断是否可以使用对应侠客快速编队
function UIPartnerTeamView:CheckCanQuickSetSelTeamTypeList(dwAssistedID)
    local tPartnerInfo = Partner_GetPartnerInfo(dwAssistedID)
    local tInfo        = Table_GetPartnerNpcInfo(dwAssistedID)

    -- 是否已拥有
    if tPartnerInfo == nil then
        return false, FormatString(g_tStrings.STR_PARTNER_NOT_HAVE, self:GetSelTeamTypeName())
    end

    if self.nSelTeamType == PARTNER_TEAM_TYPE.MORPH then
        -- 是否可幻化
        if not tInfo.bCanMorph then
            return false, g_tStrings.tNpcAssistedFailureReason[NPC_ASSISTED_RESULT_CODE.NPC_CAN_NOT_MORPH]
        end
    end

    return true, ""
end

function UIPartnerTeamView:AddOrRemove()
    local bHave = Partner_GetPartnerInfo(self.dwSelectedPartnerID) ~= nil

    if not bHave then
        local szMsg = FormatString(g_tStrings.STR_PARTNER_NOT_HAVE, self:GetSelTeamTypeName())
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        return
    end

    local dwReplacedID     = self:GetCurrentSlotPartnerID()
    local dwAssistedID     = self.dwSelectedPartnerID

    local tSelTeamTypeList = self:GetSelTeamTypeList()

    -- 需要确保其他槽位中的侠客，没有与当前新选择的侠客的名称相同的
    do
        local tSelectedInfo = Table_GetPartnerNpcInfo(dwAssistedID)
        for _, nID in ipairs(tSelTeamTypeList) do
            if nID ~= dwReplacedID and nID ~= dwAssistedID then
                local tInfo = Table_GetPartnerNpcInfo(nID)
                if tInfo.szName == tSelectedInfo.szName then
                    OutputMessage("MSG_ANNOUNCE_NORMAL", string.format("当前配置已存在同名侠客(%s)，无法加入助战编队", UIHelper.GBKToUTF8(tInfo.szName)))
                    return
                end
            end
        end
    end

    local bChosen = table.contain_value(tSelTeamTypeList, dwAssistedID)
    if bChosen and dwReplacedID == dwAssistedID then
        -- 若新点击的是已选中的当前槽位角色的话，点击则是换下该侠客
        dwAssistedID = 0
    end

    local tOtherTeamTypeList = self:GetOtherTeamTypeList()

    if dwAssistedID ~= 0 and table.contain_value(tOtherTeamTypeList, dwAssistedID) then
        -- 如果是已配置在其他类别中，则需要弹一个二次确认框
        local tSelectedInfo  = Table_GetPartnerNpcInfo(dwAssistedID)
        local szPartnerName  = UIHelper.GBKToUTF8(tSelectedInfo.szName)
        local szTeamTypeName = self:GetSelTeamTypeName()
        local szTip          = string.format("【%s】将转为%s，是否确认配置", szPartnerName, szTeamTypeName)
        UIHelper.ShowConfirm(szTip, function()
            self:SetSelTeamTypeList(dwAssistedID, dwReplacedID)
        end)
    else
        -- 否则，照常替换或添加即可
        self:SetSelTeamTypeList(dwAssistedID, dwReplacedID)
    end
end

function UIPartnerTeamView:ConfirmQuickSetTeam()
    local tNewIDList = self.tSelTeamTypeList
    local tOldIDList = self:GetSelTeamTypeList()

    -- 需要确保新的配置中，没有名字相同的侠客
    do
        local tSameNameList = {}
        for i = 1, #tNewIDList do
            for j = i + 1, #tNewIDList do
                if tNewIDList[i] ~= 0 and tNewIDList[j] ~= 0 then
                    local tInfo1 = Table_GetPartnerNpcInfo(tNewIDList[i])
                    local tInfo2 = Table_GetPartnerNpcInfo(tNewIDList[j])
                    if tInfo1.szName == tInfo2.szName then
                        table.insert(tSameNameList, UIHelper.GBKToUTF8(tInfo1.szName))
                        break
                    end
                end
            end
        end

        if table.get_len(tSameNameList) > 0 then
            local szSameNameList = table.concat(tSameNameList, ", ")
            OutputMessage("MSG_ANNOUNCE_NORMAL", string.format("当前配置中存在同名侠客(%s)，无法加入助战编队", szSameNameList))
            return
        end
    end

    -- 计算两个列表去除相同的部分后，剩余部分
    local tUniqueNewIDList = clone(tNewIDList)
    local tUniqueOldIDList = clone(tOldIDList)

    for _, nID in ipairs(tNewIDList) do
        if table.contain_value(tOldIDList, nID) then
            -- 从两边移除掉相同的部分
            table.remove_value(tUniqueNewIDList, nID)
            table.remove_value(tUniqueOldIDList, nID)
        end
    end

    -- 因为当前已配置的必定符合条件，所以只需要检查新增的部分
    for _, nID in ipairs(tUniqueNewIDList) do
        if nID ~= 0 then
            local bOK, szMsg = self:CheckCanQuickSetSelTeamTypeList(nID)
            if not bOK then
                OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
                return
            end
        end
    end

    if self.nSelTeamType == PARTNER_TEAM_TYPE.ASSIST then
        -- 若有差异，则进行替换
        local bSame = IsTableEqual(tNewIDList, tOldIDList)
        if bSame then
            UIMgr.Close(self)
            return
        end

        local tIndexAndIDList = {}
        for nIndex = 1, self:GetMaxTeamSize() do
            table.insert(tIndexAndIDList, {
                nIndex, 
                tNewIDList[nIndex] or 0,
            })
        end

        g_pClientPlayer.SetAssistedList(tIndexAndIDList)
    else
        -- 替换差异部分
        local nCount = math.max(#tUniqueNewIDList, #tUniqueOldIDList)
        if nCount == 0 then
            UIMgr.Close(self)
            return
        end

        for i = 1, nCount do
            local nID         = tUniqueNewIDList[i] or 0
            local nReplacedID = tUniqueOldIDList[i] or 0

            g_pClientPlayer.SetMorphList(nID, nReplacedID)
        end
    end
end

function UIPartnerTeamView:UpdateNpcModelListInQuickSetTeamMode()
    if self:IsAssistQuickSetTeam() then
        -- 助战的快捷编队需要特殊处理下，显示下场景就可以了
        self:UpdateMiniSceneForAssistQuickSetTeam()
        return
    end
    local tSelTeamTypeList = self:GetSelTeamTypeList()

    for i = 1, self:GetMaxTeamSize() do
        self:UpdateNpcModelInPosition(i, tSelTeamTypeList[i])
    end
end

function UIPartnerTeamView:UpdateMiniSceneForAssistQuickSetTeam()
    -- 初始化 model view
    local hModelView = self.hModelView

    if PartnerData.bNotMgrSceneByNpcModelView and not self.m_scene then
        self.m_scene = PartnerData.GetOrCreateScene()
    end

    if not hModelView then
        hModelView = NpcModelView.CreateInstance(NpcModelView)
        hModelView:ctor()
        hModelView:init(self.m_scene, PartnerData.bNotMgrSceneByNpcModelView, true, PartnerData.szSceneFilePath, "PartnerTeamAssistQuickSetTeam")
        self.MiniScene:SetScene(hModelView.m_scene)

        -- 确保三个model view都使用同一个场景实例
        self.m_scene    = hModelView.m_scene

        self.hModelView = hModelView
    end

    -- 不论是否加载模型，都要确保镜头参数位置一样
    hModelView:SetCamera(Const.MiniScene.PartnerView.tbTeamCamera)
end

function UIPartnerTeamView:UpdateNpcModelInPosition(idx, dwID)
    -- note: 初始化流程由 UIPartnerFetter 确保，这里直接使用
    local hModelView = self.shared_hModelViewList[idx]

    -- 绑定ModelView的场景到MiniScene组件
    self.MiniScene:SetScene(hModelView.m_scene)
    local fBasePosX, fBasePosY, fBasePosZ = table.unpack(Const.MiniScene.PartnerView.tbQuickSetTeamBasePos)
    local fBaseYaw                        = Const.MiniScene.PartnerView.fTeamBaseYaw

    -- 加载模型
    if dwID then
        -- 由于根据需求，加载的模型列表与 UIPartnerFetter 处完全一致，所以这里仅需要调整位置和朝向即可
        -- npc初始朝向角度，增大会往左转，减小会往右转
        local fNpcYaw = fBaseYaw + Const.MiniScene.PartnerView.fTeamOffsetYaw * (idx - 2)

        -- 每个npc往不同的横轴位置站，数值越小越靠右
        local fPosZ   = fBasePosZ + Const.MiniScene.PartnerView.fTeamOffsetPosZ * (idx - 1)

        hModelView:SetTranslation(fBasePosX, fBasePosY, fPosZ)
        hModelView:SetYaw(fNpcYaw)
    end
end

function UIPartnerTeamView:IsAssistQuickSetTeam()
    return self.nSelTeamType == PARTNER_TEAM_TYPE.ASSIST and self.bQuickSetTeam
end

function UIPartnerTeamView:GetPartnerScrollView()
    -- 助战的快捷编队使用更宽的scroll view，其他情况则使用左侧的scroll view
    if self:IsAssistQuickSetTeam() then
        return self.ScrollQuickTeamZhuZhan
    else
        return self.ScrollViewLeftCard
    end
end

function UIPartnerTeamView:GetMaxTeamSize()
    if self.nSelTeamType == PARTNER_TEAM_TYPE.ASSIST then
        return 9
    else
        return 3
    end
end

return UIPartnerTeamView