-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuickOperationBagNormalView
-- Date: 2023-03-31 14:32:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIQuickOperationBagNormalView = class("UIQuickOperationBagNormalView")

function UIQuickOperationBagNormalView:OnEnter(bIsPet, nFirstSelectId)
    self.nFirstSelectId = nFirstSelectId

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if bIsPet then
        self:InitPetList()
        self:UpdatePetList()
    else
        self:UpdateInfo()
    end
end

function UIQuickOperationBagNormalView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    ToyBoxData.UnInit()

    RedpointHelper.ToyBox_ClearAll()
end

function UIQuickOperationBagNormalView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBg,EventType.OnClick,function ()
        UIMgr.Close(self)
    end)
end

function UIQuickOperationBagNormalView:RegEvent()
    Event.Reg(self, "BUFF_UPDATE", function()
        local owner, bdelete, index, cancancel, id  , stacknum, endframe, binit, level, srcid, isvalid, leftframe
		= arg0 , arg1   , arg2 , arg3     , arg4, arg5    , arg6    , arg7 , arg8 , arg9 , arg10  , arg11
        if binit and id == 24692 then
            UIMgr.Close(self)
        end
        for i, v in ipairs(self.tbWaitUpdateBuffList) do
            if v.nbuff == id then
                self.tbScript[self.tbWaitUpdateBuffList[i].nCellIndex]:SetRecallVisible(not bdelete)
                table.remove(self.tbWaitUpdateBuffList , i)
                break
            end
        end
    end)
end

function UIQuickOperationBagNormalView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
-- ----------------------------------------------------------
-- 宠物
-- ----------------------------------------------------------
function UIQuickOperationBagNormalView:InitPetList()
    local tPets = Table_GetAllFellowPet()
    self.tHavePets = {}
    for k,v in ipairs(tPets) do
        local bHave = g_pClientPlayer.IsFellowPetAcquired(v.dwPetIndex)
        if bHave then
            table.insert(self.tHavePets,v)
        end
    end
    table.sort(self.tHavePets, function (left, right)
        local id_l = left.dwPetIndex
        local score_l = GetFellowPetScore(id_l)
        local id_r = right.dwPetIndex
        local score_r = GetFellowPetScore(id_r)
        if score_l == score_r then
            local limit_l, limit_r = 0, 0
            if left.bLimitTime then
                limit_l = 1
            end
            if right.bLimitTime then
                limit_r = 1
            end
            return limit_l < limit_r
        end
        return score_l > score_r
    end)
end

function UIQuickOperationBagNormalView:UpdatePetList()
    UIHelper.RemoveAllChildren(self.ScrollCell)
    local bEmpty = table_is_empty(self.tHavePets)
    UIHelper.SetVisible(self.WidgetEmpty,bEmpty)
    for k,v in ipairs(self.tHavePets) do
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.ScrollCell) assert(itemScript)
        itemScript:OnInitWithIconID(v.nIconID, v.nQuality)
        itemScript:SetClickCallback(function ()
            local dwPetIndex = self.tHavePets[k].dwPetIndex
            local hPlayer = g_pClientPlayer
            if not hPlayer or dwPetIndex <= 0 then
                return
            end
            hPlayer.CreateFellowPetRequest(dwPetIndex)
            JiangHuData.bPeFirstCall = true
            UIMgr.Close(self)
            UIMgr.Close(VIEW_ID.PanelQuickOperation)
        end)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollCell)
    UIHelper.ScrollToTop(self.ScrollCell,0)
end

function UIQuickOperationBagNormalView:CallPet()

end

-- ----------------------------------------------------------
-- 玩具箱
-- ----------------------------------------------------------
function UIQuickOperationBagNormalView:UpdateInfo()
    UIHelper.SetVisible(self.LabelHint,false)
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
    if not pPlayer.RemoteDataAutodownFinish() then
		OutputMessage("MSG_SYS", g_tStrings.STR_TOYBOX_ERROR_MSG)
		return
	end
    ToyBoxData.Init()
    ToyBoxData.UpdateStatus()
    self:UpdateFilter(true)
end

function UIQuickOperationBagNormalView:UpdateFilter(bIsHaveFilter)
	local bIsAllSele = true
	for k, v in pairs(ToyBoxData.tSelectSource) do
		if not v then
			bIsAllSele = false
		end
	end
	ToyBoxData.bSourceAll = bIsAllSele

	local bIsAllSele = true
	for k, v in pairs(ToyBoxData.tSelectDLC) do
		if not v then
			bIsAllSele = false
		end
	end
	ToyBoxData.bDLCAll = bIsAllSele


	local szText = ''

	local tShowBoxInfo = ToyBoxData.GetShowBoxInfo(szText, ToyBoxData.szChooseHave)

    table.sort(tShowBoxInfo , function (a,b)
        if a.nQuality == b.nQuality then
            return a.nIcon > b.nIcon
        else
            return a.nQuality > b.nQuality
        end
    end)
    local tbNewBoxInfo = {}
    for i = table.get_len(tShowBoxInfo), 1 , -1  do --已拥有玩具置前
        if tShowBoxInfo[i].bIsHave then
            table.insert(tbNewBoxInfo , tShowBoxInfo[i])
            table.remove(tShowBoxInfo , i)
        end
    end
    table.sort(tbNewBoxInfo , function (a,b)
        local bIsNewA = RedpointHelper.ToyBox_IsNew(a.dwID)
        local bIsNewB = RedpointHelper.ToyBox_IsNew(b.dwID)
        if bIsNewA ~= bIsNewB then
            return bIsNewA
        end

        if a.nQuality == b.nQuality then
            return a.nIcon > b.nIcon
        else
            return a.nQuality > b.nQuality
        end
    end)
    table.insert_tab(tbNewBoxInfo , tShowBoxInfo)

	self:Update(tbNewBoxInfo,bIsHaveFilter)
	self:UpdateTitle()
end

function UIQuickOperationBagNormalView:Update(tShowBoxInfo, bIsHaveFilter)
    if table.get_len(tShowBoxInfo) == 0 then
        --空空如也
        UIHelper.SetVisible(self.WidgetEmpty,true)
        return
    end
    UIHelper.SetVisible(self.WidgetEmpty,false)
    local loadIndex = 0
    local loadCount = table.get_len(tShowBoxInfo)

    self.tbScript = {}
    local nScrollToIndex = nil
    local selectItem = nil
    self.nFrameCycleTimerID = Timer.AddFrameCycle(self , 1 , function ()
        for i = 1,10, 1 do
            loadIndex = loadIndex + 1
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100,self.ScrollCell)
            local boxInfo = tShowBoxInfo[loadIndex]
            boxInfo.bShowShare = true
            UIHelper.SetSwallowTouches(itemScript.BtnRecall, true)
            boxInfo.nCellIndex = loadIndex
            if boxInfo.dwID == self.nFirstSelectId then
                nScrollToIndex = loadIndex
                selectItem = itemScript
                self.nFirstSelectId = nil
            end
            if itemScript then
                itemScript:OnInitWithIconID(boxInfo.nIcon ,boxInfo.nQuality)
                UIHelper.ToggleGroupAddToggle(self.TogGroup,itemScript.ToggleSelect)
                itemScript:SetSelected(false)
                itemScript:SetClickCallback(function()
                   self:UpdateSelectedItemDetails(boxInfo) --打开tips
                end)
                if boxInfo.bIsHave then
                    itemScript:UpdateCDProgressBySkill(boxInfo.nSkillID, boxInfo.nSkillLevel)
                    itemScript:SetRecallVisible(GetClientPlayer().IsHaveBuff(boxInfo.nbuff, boxInfo.nbuffLevel))
                    itemScript:SetRecallCallback(function (boxInfo)
                        self:WaitUpdateBuff(boxInfo)
                        self:UseToySkill(boxInfo) --使用玩具
                    end , boxInfo)

                    local bIsNew = RedpointHelper.ToyBox_IsNew(boxInfo.dwID)
                    if bIsNew then
                        itemScript:SetNewItemFlag(true)
                    end
                end
                self.tbScript[loadIndex] = itemScript
                UIHelper.SetNodeGray(itemScript._rootNode, not boxInfo.bIsHave , true)
            end
            if loadIndex == loadCount then
                Timer.DelTimer(self , self.nFrameCycleTimerID)

                if nScrollToIndex then
                    Timer.AddFrame(self, 1, function()
                        local nPercent = ((nScrollToIndex / loadCount) % 5) * 100
                        UIHelper.ScrollToPercent(self.ScrollCell, nPercent)
                        UIHelper.SetToggleGroupSelectedToggle(self.TogGroup, selectItem.ToggleSelect)
                        self:UpdateSelectedItemDetails(tShowBoxInfo[nScrollToIndex])
                    end)
                end
                break
            end
        end
        UIHelper.ScrollViewDoLayout(self.ScrollCell)
        UIHelper.ScrollToTop(self.ScrollCell)
    end)

end

function UIQuickOperationBagNormalView:UpdateTitle()
    local nCount = Table_GetToyBoxCount()
    UIHelper.SetString(self.LabelTitle,FormatString(g_tStrings.STR_TOYBOX_TITLE, ToyBoxData.nHaveNum, nCount))
end

function UIQuickOperationBagNormalView:UpdateSelectedItemDetails(boxInfo , loadIndex) --添加玩具通用提示
    if not self.scriptItemTip then
        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetAniLeft)
    end
    UIHelper.SetVisible(self.scriptItemTip._rootNode , true)
    self.scriptItemTip:OnInitOperationBoxItem(boxInfo , function (useboxInfo)
        self:WaitUpdateBuff(useboxInfo)
        self:UseToySkill(useboxInfo) --使用玩具
        UIHelper.SetVisible(self.scriptItemTip._rootNode , false)
    end)
end

function UIQuickOperationBagNormalView:WaitUpdateBuff(useboxInfo )
    self.tbWaitUpdateBuffList = self.tbWaitUpdateBuffList or {}
    local bIsAdd = true
    for k, v in pairs(self.tbWaitUpdateBuffList) do
        if v.nbuff == useboxInfo.nbuff then
            bIsAdd = false
            break
        end
    end
    if bIsAdd then
        table.insert(self.tbWaitUpdateBuffList , useboxInfo)
    end
end

function UIQuickOperationBagNormalView:UseToySkill(boxInfo) --使用玩具
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local hasBuff = GetClientPlayer().IsHaveBuff(boxInfo.nbuff, boxInfo.nbuffLevel)
    if hasBuff then
        local buffList = BuffMgr.GetVisibleBuff(GetClientPlayer())
        for i, buffInfo in ipairs(buffList) do
            if buffInfo.dwID == boxInfo.nbuff then
                GetClientPlayer().CancelBuff(buffInfo.nIndex)
                break
            end
        end
    else
        if (boxInfo.bIsHave and boxInfo.nToyType ~= ToyBoxData.TOY_TYPE.COUNT) then
            SkillData.CastSkill(pPlayer,boxInfo.nSkillID, boxInfo.nSkillLevel)
        end
    end
end

return UIQuickOperationBagNormalView