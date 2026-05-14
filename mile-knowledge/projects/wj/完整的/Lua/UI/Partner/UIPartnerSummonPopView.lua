-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerSummonPopView
-- Date: 2023-04-26 11:03:16
-- Desc: 侠客-召唤侠客
-- Prefab: PanelPartnerSummonPop
-- ---------------------------------------------------------------------------------

---@class UIPartnerSummonPopView
local UIPartnerSummonPopView = class("UIPartnerSummonPopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerSummonPopView:_LuaBindList()
    self.BtnClose                      = self.BtnClose --- 关闭界面

    self.LabelTitle                    = self.LabelTitle --- 标题

    self.LayouPartnerCardCell          = self.LayouPartnerCardCell --- 配置的助战侠客的layout（<=5)
    self.ScrollViewPartnerCardCellMore = self.ScrollViewPartnerCardCellMore --- 配置的助战侠客的scroll view（>5）

    self.BtnSummon                     = self.BtnSummon --- 召唤/收回按钮
    self.LabelSummon                   = self.LabelSummon --- 按钮文本

    self.BtnOpenAssistQuickTeamPage    = self.BtnOpenAssistQuickTeamPage --- 打开助战快捷编队页面

    self.LayoutBtn                     = self.LayoutBtn --- 下方按钮的layout
    self.BtnSummonAll                  = self.BtnSummonAll --- 召唤全部

    self.WidgetEmpty                   = self.WidgetEmpty --- 空状态

    self.TogSettingGroupOption         = self.TogSettingGroupOption --- 进入秘境时推荐配置的toggle

    self.BtnScreening                  = self.BtnScreening --- 筛选按钮
end

function UIPartnerSummonPopView:OnEnter(bHideQuickTeam)
    --- 是否隐藏 前往配置 按钮，通过助战页面的入口进入时，由于本身助战页面已有快捷编队按钮，这里就隐藏掉，避免额外处理MiniScene切换的流程
    self.bHideQuickTeam                     = bHideQuickTeam or false

    self.nMaxCanSummonCount                 = PartnerData.GetMaxCanSummonCount()

    -- 当前选中的侠客ID列表，初始值为当前已配置的助战侠客ID列表
    self.tSelTeamTypeList                   = PartnerData.GetAssistedList()

    --- 默认不禁用召请/召唤后关闭界面的功能，仅在修改预设编队时设置这个，并在点击召请按钮时清除标记
    self.bAfterSyncAssistedListWithTeamPlan = false

    local BUFF_UI                           = 27896--剧情模式标识
    self.bStoryMode                         = g_pClientPlayer.IsHaveBuff(BUFF_UI, 1)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()

        PartnerData.InitFilterDef()
        FilterDef.Partner.Reset()

        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerSummonPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerSummonPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSummon, EventType.OnClick, function()
        --- 清除切换编队时临时设置的标记
        self.bAfterSyncAssistedListWithTeamPlan = false

        self:SetAsNewPartnerListAndSummonNewPart()
    end)

    UIHelper.BindUIEvent(self.BtnOpenAssistQuickTeamPage, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelPartner, nil, PartnerViewOpenType.AssistQuickTeam)

        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogSettingGroupOption, EventType.OnClick, function()
        local bSelect = UIHelper.GetSelected(self.TogSettingGroupOption)
        Partner_SetShowRecommend(bSelect)
    end)

    UIHelper.BindUIEvent(self.BtnScreening, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreening, TipsLayoutDir.TOP_LEFT, FilterDef.Partner)
    end)
end

function UIPartnerSummonPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nResultCode, nArg0, nArg1, nArg2)
        if nResultCode == NPC_ASSISTED_RESULT_CODE.SET_ASSISTED_LIST_SUCCESS then
            self:OnSetAssistedListSuccess()

            if self.bAfterSyncAssistedListWithTeamPlan then
                --- 修改预设编队导致助战列表变更时，刷新下界面，以新的编队来展示
                self.tSelTeamTypeList = PartnerData.GetAssistedList()
                self:UpdateInfo()
            end
        elseif nResultCode == NPC_ASSISTED_RESULT_CODE.SUMMON_SUCCESS or nResultCode == NPC_ASSISTED_RESULT_CODE.RECALL_SUCCESS then
            if not self.bAfterSyncAssistedListWithTeamPlan then
                UIMgr.Close(self)
            else
                --- 修改预设编队导致助战列表变更时，刷新下界面，展示新的是否已出战信息
                self:UpdateInfo()
            end
        end
    end)

    Event.Reg(self, "PartnerSyncAssistedListWithTeamPlan", function()
        --- 修改预设编队，导致助战列表调整而触发召请和召回时，不关闭本界面
        self.bAfterSyncAssistedListWithTeamPlan = true
    end)

    Event.Reg(self, "OnPartnerShowRecommendChanged", function()
        UIHelper.SetSelected(self.TogSettingGroupOption, Partner_GetShowRecommend(), false)
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.Partner.Key then
            return
        end

        self.tShowPartnerIDList = PartnerData.GetFilteredPartnerIDList(tbInfo)
        self:UpdateInfo()
    end)
end

function UIPartnerSummonPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerSummonPopView:UpdateInfo()
    local tPartnerIDList = self:GetPartnerIDList()

    UIHelper.SetString(self.LabelSummon, "确认召请")

    local bUseScrollViewMore = self:UseLayoutMore()
    UIHelper.SetVisible(self.LayouPartnerCardCell, not bUseScrollViewMore)
    UIHelper.SetVisible(self.ScrollViewPartnerCardCellMore, bUseScrollViewMore)

    local container = self:GetPartnerContainer()
    UIHelper.RemoveAllChildren(container)

    if tPartnerIDList then
        local tSummonedIDList = PartnerData.GetSummonedPartnerIDList()

        --- 默认勾选的数目不能超过当前地图允许召请的上限
        if table.get_len(self.tSelTeamTypeList) > self.nMaxCanSummonCount then
            local tFirstMaxCanSummon = {}

            for _, dwID in ipairs(self.tSelTeamTypeList) do
                if dwID > 0 then
                    table.insert(tFirstMaxCanSummon, dwID)

                    if table.get_len(tFirstMaxCanSummon) >= self.nMaxCanSummonCount then
                        break
                    end
                end
            end

            self.tSelTeamTypeList = tFirstMaxCanSummon
        end

        local tMorphIDList = PartnerData.GetMorphList()

        for idx, dwID in ipairs(tPartnerIDList) do
            ---@type UIRoleItem
            local script   = UIHelper.AddPrefab(PREFAB_ID.WidgetRoleItem, container, dwID)

            local tInfo    = Table_GetPartnerNpcInfo(dwID)

            local tPartner = Partner_GetPartnerInfo(dwID)
            if tPartner then
                tInfo.bHave             = true
                tInfo.nLevel            = tPartner.nLevel
                tInfo.bEquippedExterior = tPartner.bEquippedExterior
            end

            script:OnEnter(tInfo)

            UIHelper.SetToggleGroupIndex(script.ToggleCurrentSelect, ToggleGroupIndex.PartnerSelectRole)

            --- 默认勾选在当前助战编队的侠客（不超过当前地图的可召请数目上限）
            local bChosen = table.contain_value(self.tSelTeamTypeList, dwID)
            script:UpdateSelectedIndex(self.tSelTeamTypeList)

            local bSummoned = table.contain_value(tSummonedIDList, dwID)
            UIHelper.SetVisible(script.ImgInBattle, bSummoned)

            UIHelper.BindUIEvent(script.BtnChosenPartner, EventType.OnClick, function()
                --- todo: 编队和召请点这个按钮后的逻辑似乎有很多相同的部分，看看能否整合到 UIRoleItem 里，方便后续维护
                UIHelper.SetVisible(script.ImgSelectNum, not UIHelper.GetVisible(script.ImgSelectNum))

                -- 检查下是否勾选超过了当前地图的上限
                local bCurrentSelected = UIHelper.GetVisible(script.ImgSelectNum)
                if bCurrentSelected then
                    local nSelectedCount = table.get_len(self:GetSelectedPartnerIDList())
                    if nSelectedCount > self.nMaxCanSummonCount then
                        TipsHelper.ShowNormalTip("选择的侠客数量已到上限")
                        UIHelper.SetVisible(script.ImgSelectNum, false)
                        bCurrentSelected = false
                    end
                end

                -- 实际上也可以选择幻化列表中的侠客，若勾选了，则暂时隐藏其类别标记
                local bMorphChosen = table.contain_value(tMorphIDList, dwID)
                if bMorphChosen then
                    if bCurrentSelected then
                        -- 勾选时，隐藏另外标记
                        UIHelper.SetVisible(script.ImgMark, false)
                    else
                        -- 若取消勾选，则还原标记
                        UIHelper.SetVisible(script.ImgMark, true)
                    end
                end

                self:UpdateTitle()

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
                    local nIndex = table.get_key(self.tSelTeamTypeList, dwID)
                    if nIndex then
                        self.tSelTeamTypeList[nIndex] = 0
                    end
                end
                for _, _cell in ipairs(UIHelper.GetChildren(container)) do
                    ---@type UIRoleItem
                    local scriptCell = UIHelper.GetBindScript(_cell)
                    scriptCell:UpdateSelectedIndex(self.tSelTeamTypeList)
                end
            end)

            -- 其他类别的已配置的角色则显示左下角小图标
            local bMorphChosen = table.contain_value(tMorphIDList, dwID)
            UIHelper.SetVisible(script.ImgMark, bMorphChosen)
            if bMorphChosen then
                -- 非当前类别对应的图标
                UIHelper.SetSpriteFrame(script.ImgMark, "UIAtlas2_Partner_Partner_iconMark1.png")
            end
        end
    end

    if not bUseScrollViewMore then
        UIHelper.LayoutDoLayout(container)
    else
        UIHelper.ScrollViewDoLayoutAndToTop(container)
    end

    UIHelper.SetVisible(self.BtnOpenAssistQuickTeamPage, not self.bHideQuickTeam)

    --- 新的召请界面中，不再显示一键召唤按钮，所选的即为最终配置，并以此为基准全部一键召唤
    UIHelper.SetVisible(self.BtnOpenAssistQuickTeamPage, false)
    UIHelper.SetVisible(self.BtnSummonAll, false)

    local bHasPartner = table.get_len(tPartnerIDList) > 0
    UIHelper.SetVisible(self.WidgetEmpty, not bHasPartner)
    UIHelper.SetButtonState(self.BtnSummon, bHasPartner and BTN_STATE.Normal or BTN_STATE.Disable)

    UIHelper.LayoutDoLayout(self.LayoutBtn)

    self:UpdateTitle()

    UIHelper.SetSelected(self.TogSettingGroupOption, Partner_GetShowRecommend())
end

function UIPartnerSummonPopView:UpdateTitle()
    local tPartnerIDList = self:GetSelectedPartnerIDList()
    local nSelectedCount = table.get_len(tPartnerIDList)

    local szTitle        = string.format("请确认需要召请的侠客(%d/%d)", nSelectedCount, self.nMaxCanSummonCount)

    UIHelper.SetString(self.LabelTitle, szTitle)
end

--- 替换助战编队为新选择的阵容，并召唤多出来的侠客
function UIPartnerSummonPopView:SetAsNewPartnerListAndSummonNewPart()
    local fnConfirm = function()
        --- 先替换差异部分的助战编队
        self:SetAsNewPartnerList()

        --- @see UIPartnerSummonPopView#OnSetAssistedListSuccess
        --- 由于设置助战列表只能一次次调用，因此在全部请求都处理完后，在对应事件里再处理
    end

    -- 需要确保新的配置中，没有名字相同的侠客
    do
        local tNewIDList    = self.tSelTeamTypeList
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
            OutputMessage("MSG_ANNOUNCE_NORMAL", string.format("当前配置中存在同名侠客(%s)，无法召请", szSameNameList))
            return
        end
    end

    --- 在非剧情模式的副本中，如果当前选择的召请列表中有试用侠客，则提示一下这部分不会被召唤出来
    local tNeedConfirmTryOutPartnerNameList = { }
    if not self.bStoryMode then
        for _, dwID in ipairs(self.tSelTeamTypeList) do
            local tInfo = Table_GetPartnerNpcInfo(dwID)
            if tInfo and tInfo.bTryOut then
                table.insert(tNeedConfirmTryOutPartnerNameList, UIHelper.GBKToUTF8(tInfo.szName))
            end
        end
    end

    if table.get_len(tNeedConfirmTryOutPartnerNameList) == 0 then
        fnConfirm()
    else
        local szTryOutNameList = table.concat(tNeedConfirmTryOutPartnerNameList, "、")
        local nNormalCount     = table.get_len(self.tSelTeamTypeList) - table.get_len(tNeedConfirmTryOutPartnerNameList)
        local szMessage        = string.format("非单人模式下，单人侠客无法召请：%s（可在编队中进行调整）。\n是否召请当前编队其余%d个侠客？",
                                               szTryOutNameList, nNormalCount
        )
        local script           = UIHelper.ShowConfirm(szMessage, fnConfirm)

        script:SetButtonContent("Confirm", "确认召请")
    end
end

local fnGetNonEmptyPart = function(tIDList)
    local tNonEmptyPart = {}
    for _, nID in ipairs(tIDList) do
        if nID ~= 0 then
            table.insert(tNonEmptyPart, nID)
        end
    end
    return tNonEmptyPart
end

function UIPartnerSummonPopView:SetAsNewPartnerList()
    local tNewIDList       = self.tSelTeamTypeList
    local tOldIDList       = PartnerData.GetAssistedList()

    -- 计算两个列表的非空部位，在去除相同的部分后，剩余的部分
    local tUniqueNewIDList = fnGetNonEmptyPart(tNewIDList)
    local tUniqueOldIDList = fnGetNonEmptyPart(tOldIDList)

    for _, nID in ipairs(tNewIDList) do
        if table.contain_value(tOldIDList, nID) then
            -- 从两边移除掉相同的部分
            table.remove_value(tUniqueNewIDList, nID)
            table.remove_value(tUniqueOldIDList, nID)
        end
    end

    -- 替换差异部分
    local nCount = math.max(#tUniqueNewIDList, #tUniqueOldIDList)
    if nCount == 0 or #tUniqueNewIDList == 0 then
        -- 若没有差异，或者新选择的是当前助战配置的真子集，则不需要修改阵容，仅尝试召唤不在其中的侠客，并确保其中每个侠客都召请出来，使已召请列表与新列表一致
        self:MakeSureSummonedListSameAsNewSubset(tNewIDList)
        return
    end

    --- 先使用新接口修改编队，在收到设置编队成功的事件后，再尝试触发一键召唤
    local tIndexAndIDList = {}
    for nIndex = 1, 9 do
        table.insert(tIndexAndIDList, {
            nIndex,
            tNewIDList[nIndex] or 0,
        })
    end
    g_pClientPlayer.SetAssistedList(tIndexAndIDList)
    LOG.DEBUG("UIPartnerSummonPopView 需要修改助战编队\ntOldIDList=%s\ntIndexAndIDList=%s",
              var2str(tOldIDList), var2str(tIndexAndIDList)
    )
end

local function isSameList(left, right)
    local bSame = true

    if table.get_len(left) == table.get_len(right) then
        if table.get_len(left) ~= 0 then
            for _, dwLatestID in ipairs(left) do
                if not table.contain_value(right, dwLatestID) then
                    --- 有元素不同，说明分次发送的设置助战配置请求尚未全部处理完
                    bSame = false
                    break
                end
            end
        end
    else
        -- 数目不同
        bSame = false
    end

    return bSame
end

function UIPartnerSummonPopView:MakeSureSummonedListSameAsNewSubset(tSubsetIDList)
    --- 当前的助战配置
    local tLatestAssistedList = PartnerData.GetAssistedList()
    --- 当前的召请配置
    local tSummonedIDList     = PartnerData.GetSummonedPartnerIDList()

    --- 需要对齐的目标
    local tTargetIDList       = tLatestAssistedList
    if tSubsetIDList then
        tTargetIDList = clone(tSubsetIDList)
    end

    --- 非剧情模式下，若目标阵容中有单人侠客，则过滤掉这部分
    if not self.bStoryMode then
        local tBeforeFilter = clone(tTargetIDList)
        -- 在非剧情模式下，这种情况不尝试召唤单人侠客，将这部分侠客预先移除
        for _, nID in ipairs(tBeforeFilter) do
            local tInfo = Table_GetPartnerNpcInfo(nID)
            if tInfo and tInfo.bTryOut then
                table.remove_value(tTargetIDList, nID)
            end
        end
    end

    local bNeedSummon = not isSameList(fnGetNonEmptyPart(tTargetIDList), tSummonedIDList)
    if bNeedSummon then
        --- 全部设置完后，若当前新选择的助战配置与已召唤侠客列表不同

        --- 尝试召回不在选择列表中的侠客
        for _, dwPartnerID in ipairs(tSummonedIDList) do
            if not table.contain_value(tTargetIDList, dwPartnerID) then
                g_pClientPlayer.RecallNpcAssisted(dwPartnerID)
            end
        end

        --- 并召唤未召唤出的选择的侠客
        local tNotSummonIDList = {}
        for _, dwPartnerID in ipairs(tTargetIDList) do
            if dwPartnerID ~= 0 then
                if not table.contain_value(tSummonedIDList, dwPartnerID) then
                    table.insert(tNotSummonIDList, dwPartnerID)
                end
            end
        end
        if table.get_len(tNotSummonIDList) > 0 then
            RemoteCallToServer("On_Partner_BatchSummon", tNotSummonIDList)
        end
    else
        if not self.bAfterSyncAssistedListWithTeamPlan then
            -- 否则，直接关闭界面即可
            UIMgr.Close(self)
        end
    end
end

function UIPartnerSummonPopView:OnSetAssistedListSuccess()
    self:MakeSureSummonedListSameAsNewSubset()
end

---@return number[]
function UIPartnerSummonPopView:GetSelectedPartnerIDList()
    local tPartnerIDList = {}

    for _, widget in ipairs(UIHelper.GetChildren(self:GetPartnerContainer())) do
        ---@type UIRoleItem
        local script = UIHelper.GetBindScript(widget)

        if UIHelper.GetVisible(script.ImgSelectNum) then
            table.insert(tPartnerIDList, script.tInfo.dwID)
        end
    end

    return tPartnerIDList
end

function UIPartnerSummonPopView:UseLayoutMore()
    local tPartnerIDList = self:GetPartnerIDList()

    return table.get_len(tPartnerIDList) > 5
end

function UIPartnerSummonPopView:GetPartnerContainer()
    if not self:UseLayoutMore() then
        return self.LayouPartnerCardCell
    else
        return self.ScrollViewPartnerCardCellMore
    end
end

--- 非单人模式下显示已拥有侠客，单人模式下额外显示单人侠客。若设置了筛选条件，则非当前助战列表的部分将筛选一遍
function UIPartnerSummonPopView:GetPartnerIDList()
    local tPartnerIDList = {}
    
    --- 非单人模式下显示已拥有侠客，单人模式下额外显示单人侠客。助战列表中的部分均显示
    local tList          = Partner_GetAllPartnerList()
    self:SortPartnerList(tList)

    local tAssistedList = PartnerData.GetAssistedList()
    for _, tInfo in ipairs(tList) do
        local bOK = true

        if not tInfo.bHave then
            bOK = false
        elseif not self.bStoryMode and tInfo.bTryOut and not table.contain_value(tAssistedList, tInfo.dwID) then
            -- 非剧情模式下，过滤掉剧情模式的侠客（如果已经配置在助战列表中，为了方便玩家取消勾选，这部分例外显示出来）
            bOK = false
        end

        if bOK then
            table.insert(tPartnerIDList, tInfo.dwID)
        end
    end
    
    -- 如果设置了筛选条件，则额外筛选一遍
    if self.tShowPartnerIDList then
        local tRes = {}
        
        -- 当前已在助战列表中的侠客不受筛选影响
        for _, dwID in ipairs(tPartnerIDList) do
            if table.contain_value(tAssistedList, dwID) then
                table.insert(tRes, dwID)
            end
        end
        
        --- 再放入筛选后的侠客中未包含的部分
        for _, dwID in ipairs(tPartnerIDList) do
            if table.contain_value(self.tShowPartnerIDList, dwID) and not table.contain_value(tRes, dwID) then
                table.insert(tRes, dwID)
            end
        end
        
        tPartnerIDList = tRes
    end

    return tPartnerIDList
end

function UIPartnerSummonPopView:SortPartnerList(tPartnerList)
    -- 排序顺序: 是否已拥有>已配置当前类型(按配置列表的顺序)>未配置>等级(仅已拥有时有)>稀有度>id>已配置其他类型
    local tSelTeamTypeList   = PartnerData.GetAssistedList()
    local tOtherTeamTypeList = PartnerData.GetMorphList()

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

return UIPartnerSummonPopView