-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UINameCardView
-- Date: 2023-04-11 10:10:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UINameCardView = class("UINameCardView")

local SOCIAL_PANEL_APPLY = 1
local SET_MAX = 12
function UINameCardView:OnEnter(szGlobalID,tbRoleEntryInfo, attraction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szGlobalID = szGlobalID or UI_GetClientPlayerGlobalID()
    self.bMyself = self.szGlobalID == UI_GetClientPlayerGlobalID()
    self.bSetShow = false
    self.tbRoleEntryInfo = tbRoleEntryInfo or FellowshipData.GetRoleEntryInfo(self.szGlobalID)
    self.dwSkinID = self.tbRoleEntryInfo.nSkinID
    self.attraction = attraction
    -- self:ApplyMyselfCard()
    if self.bMyself then
        self.nMapID = g_pClientPlayer.GetMapID()
    else
        self.nMapID = FellowshipData.GetFellowshipMapID(self.szGlobalID)
    end

    FellowshipData.ApplyRoleMapID(self.szGlobalID)

    self:GetNameCard()
    if self.bMyself then
        self:InitMyselfSkin()
    else
        self:InitOtherSkin()
    end
    self:InitPlayerInfo()
end

function UINameCardView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UINameCardView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose,EventType.OnClick,function ()
        UIMgr.Close(self)
    end)

    --配置展示
    UIHelper.BindUIEvent(self.BtnShow,EventType.OnClick,function ()
        self:UpdateSetShow(true)
    end)

    --取消
    UIHelper.BindUIEvent(self.BtnCancel,EventType.OnClick,function ()
        self:UpdateSetShow(false)
    end)

    --确定
    UIHelper.BindUIEvent(self.BtnConfirm,EventType.OnClick,function ()
        self:UpdateSetShow(false)
        self:ClickSetSkin()
    end)

    --使用
    UIHelper.BindUIEvent(self.BtnUse,EventType.OnClick,function ()
        self:ClickChangeSkin()
    end)
end

function UINameCardView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self,"LOADING_END",function (arg0)
        if CheckPlayerIsRemote() then
			UIMgr.Close(self)
		end
    end)

    --设置展示结果
    Event.Reg(self,"SET_NAME_CARD_SKIN_RESPOND",function (arg0)
        if arg0 == NAME_CARD_ERROR_CODE.SUCCESS then
            self.tSetSkinList = GetSocialManagerClient().GetNameCard(self.szGlobalID)
            self.tMyHaveSkin = GetSocialManagerClient().GetNameCardList()
			self:GetNameCard()
            self:SortSkinList(self.tAllSkinList)
            self:UpdateSkinList()
		end
        TipsHelper.ShowNormalTip(g_tStrings.STR_SET_SKIN_NOTIFY[arg0])
    end)

    --获取名帖信息
    Event.Reg(self,"GET_NAME_CARD_RESPOND",function (arg0)
        local SMClient = GetSocialManagerClient()
	    if not SMClient then return end
        if self.bMyself then
            self.tSetSkinList = SMClient.GetNameCard(self.szGlobalID)
            self.tMyHaveSkin = SMClient.GetNameCardList()
            self:SortSkinList(self.tAllSkinList)
            self:UpdateSkinList()
        else
            self:InitOtherSkin()
        end
    end)

    Event.Reg(self, "APPLY_ROLE_MAP_ID_RESPOND", function (szGlobalID, dwMapID)
        if szGlobalID == self.szGlobalID then
            self.nMapID = dwMapID
            UIHelper.SetString(self.LabelCity, UIHelper.GBKToUTF8(Table_GetMapName(dwMapID)))
        end
    end)

    Event.Reg(self, "SET_CARD_SKIN", function (wSkinID)
        self.dwSkinID = wSkinID
        TipsHelper.ShowNormalTip(g_tStrings.STR_PLAYER_SET_SKIN_SUCCESS)
        self:UpdateSkinList()
        self:SetGrayBtn()
    end)
end

function UINameCardView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UINameCardView:GetNameCard()
    local SMClient = GetSocialManagerClient()
	if not SMClient then
		return
	end
	SMClient.GetNameCardRequest(self.szGlobalID)
end

function UINameCardView:InitMyselfSkin()
    local tAllList = Table_GetAllFriendSkin()

    local SMClient = GetSocialManagerClient()
	if not SMClient then return end
    self.tSetSkinList = SMClient.GetNameCard(self.szGlobalID)
	self.tMyHaveSkin = SMClient.GetNameCardList()

    self:SortSkinList(tAllList)
    self:InitSkinList()
    self:UpdateSkinList()
end

function UINameCardView:InitOtherSkin()
    self.tAllSkinList = {}
    UIHelper.SetVisible(self.BtnShow,false)

    local SMClient = GetSocialManagerClient()
	if not SMClient then return end
    local tSetSkinList = SMClient.GetNameCard(self.szGlobalID)
    for _,dwID in pairs(tSetSkinList) do
        if dwID ~= 0 then
            table.insert(self.tAllSkinList,dwID)
        end
    end

    self:InitSkinList()
    self:UpdateOtherSkinList()
end

--排序：展示，拥有，未拥有
function UINameCardView:SortSkinList(tAllList)
    table.sort(tAllList,function (left,right)
        local bHave_l = self:DectTableValue(self.tMyHaveSkin, left.dwID) or false
        local bHave_r = self:DectTableValue(self.tMyHaveSkin, right.dwID) or false
        if left.dwID == 0 then bHave_l = true end
        if right.dwID == 0 then bHave_r = true end

        if bHave_l and bHave_r then
            local bSet_l = self:DectTableValue(self.tSetSkinList, left.dwID) or false
            local bSet_r = self:DectTableValue(self.tSetSkinList, right.dwID) or false
            if left.dwID == 0 then bSet_l = true end
            if right.dwID == 0 then bSet_r = true end

            if (bSet_l and not bSet_r) or (not bSet_l and bSet_r) then
                return bSet_l
            else
                return left.dwID < right.dwID
            end
        elseif (bHave_l and not bHave_r) or (not bHave_l and bHave_r) then
            return bHave_l
        else
            return left.dwID < right.dwID
        end
    end)
    self.tAllSkinList = tAllList
end

function UINameCardView:InitPlayerInfo()
    local tbRoleEntryInfo = self.tbRoleEntryInfo
    local headScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108,self.WidgetPlayerHead_108)
    if headScript and tbRoleEntryInfo then
        headScript:SetHeadInfo(nil, tbRoleEntryInfo.dwMiniAvatarID or 0, tbRoleEntryInfo.nRoleType, tbRoleEntryInfo.nForceID)
        headScript:SetTouchEnabled(false)
    end

    headScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead,self.WidgetPlayerHead)
    if headScript and tbRoleEntryInfo then
        headScript:SetHeadInfo(nil, tbRoleEntryInfo.dwMiniAvatarID or 0, tbRoleEntryInfo.nRoleType, tbRoleEntryInfo.nForceID)
        headScript:SetTouchEnabled(false)
    end

    for i = 1,2 do
        UIHelper.SetString(self.tbLableName[i], UIHelper.GBKToUTF8(tbRoleEntryInfo.szName))
        UIHelper.SetSpriteFrame(self.tbImgSchool[i], PlayerForceID2SchoolImg2[tbRoleEntryInfo.nForceID])
        UIHelper.SetString(self.tbLabelLevel[i], tbRoleEntryInfo.nLevel)
    end

    UIHelper.SetString(self.LableCamp,g_tStrings.STR_GUILD_CAMP_NAME[tbRoleEntryInfo.nCamp])
    local szMapName = FellowshipData.GetWhereDesc(self.nMapID, tbRoleEntryInfo or {}, self.attraction)
    UIHelper.SetString(self.LabelCity, szMapName, 5)
    local nCount, str = UIHelper.TruncateString(UIHelper.GBKToUTF8(tbRoleEntryInfo.szSignature), 14, "...")
    UIHelper.SetString(self.LableSignature, str)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCardDetaiks)
end

--先加载好位置
function UINameCardView:InitSkinList()
    self.tAllNameCardList = {}
    self.tSetShow = {}
    UIHelper.RemoveAllChildren(self.ScrollViewCard)
    local nCount = self:GetLength(self.tAllSkinList)
    if not self.bMyself then nCount = SET_MAX end
    for i = 1,nCount  do
        local cardCellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetCardCell,self.ScrollViewCard)
        if cardCellScript then
            UIHelper.ToggleGroupAddToggle(self.togglegroup,cardCellScript.TogCard)
            UIHelper.BindUIEvent(cardCellScript.TogCard,EventType.OnSelectChanged,function (toggle,bSelected)
                UIHelper.SetVisible(cardCellScript.ImgBgCheck, self.bSetShow)
                if self.bSetShow or not bSelected then
                    self:ClickCardCell(i,toggle,bSelected)
                end
            end)

            UIHelper.BindUIEvent(cardCellScript.TogCard, EventType.OnClick, function ()
                UIHelper.SetVisible(cardCellScript.ImgBgCheck, self.bSetShow)
                if not self.bSetShow then
                    for _,v in ipairs(self.tAllNameCardList) do
                        UIHelper.SetVisible(v.ImgSelect, v == cardCellScript)
                    end
                    self:ClickCardCell(i,cardCellScript.TogCard,true)
                end
            end)

            self.tAllNameCardList[i] = cardCellScript
            UIHelper.SetVisible(cardCellScript.ImgBgCheck, self.bSetShow)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCard)
end

function UINameCardView:ClickCardCell(i,toggle,bSelected)
    if bSelected then
        if not self.bSetShow then
            local nCount = self:GetLength(self.tAllSkinList)
            if i > nCount then
                Timer.AddFrame(self,1,function ()
                    UIHelper.SetSelected(toggle,false)
                end)
                return
            end
            self.nCurIndex = i
            if self.bMyself then
                self:UpdateSkin()
            else
                self:UpdateOtherSkin()
            end
        else
            local nCount = self:GetLength(self.tSetShow)
            local bHave = self:DectTableValue(self.tMyHaveSkin,self.tAllSkinList[i].dwID)
            if self.tAllSkinList[i].dwID == 0 then
                TipsHelper.ShowNormalTip(g_tStrings.STR_PLAYER_VISIT_SKIN_SET_CLICK_ERROR)
                Timer.AddFrame(self,1,function ()
                    UIHelper.SetSelected(toggle,false)
                end)
            elseif nCount >= SET_MAX then
                TipsHelper.ShowNormalTip(FormatString(g_tStrings.STR_PLAYER_VISIT_SKIN_SET_ERROR, SET_MAX))
                Timer.AddFrame(self,1,function ()
                    UIHelper.SetSelected(toggle,false)
                end)
            elseif not bHave then
                TipsHelper.ShowNormalTip(g_tStrings.STR_SET_SKIN_NOTIFY[NAME_CARD_ERROR_CODE.DO_NOT_HAVE_SKIN])
                Timer.AddFrame(self,1,function ()
                    UIHelper.SetSelected(toggle,false)
                end)
            else
                self.tSetShow[self.tAllSkinList[i].dwID] = true
            end
        end
    else
        if self.bSetShow then
            self.tSetShow[self.tAllSkinList[i].dwID] = nil
        end
        if not self.bFirstSelected then
            for k,v in ipairs(self.tAllNameCardList) do
                if k ~= i then
                    UIHelper.SetVisible(v.ImgSelect,false)
                end
            end
            self.bFirstSelected = true
        end
    end
    self:UpdateSetShowNumber()
end

function UINameCardView:DectTableValue(T, value)
    if  type(T) ~= "table" then
		return
	end

    for key, v in pairs(T) do
		if value == v then
			return true, key
		end
	end
	return false
end

--展示选中效果
function UINameCardView:UpdateSkin()
    local i = self.nCurIndex
    local tCardInfo = UINameCardTab[self.tAllSkinList[i].dwID]
    if tCardInfo then
        UIHelper.SetString(self.LabelTitle,tCardInfo["szName"])
        UIHelper.SetTexture(self.ImgBgTop1, tCardInfo["szVisitCardPath"])
        UIHelper.SetTexture(self.ImgBgTop2, tCardInfo["szVisitCardPath"])
    end

    UIHelper.UpdateMask(self.MaskImgNameCard)

    local bSet = self:DectTableValue(self.tSetSkinList, self.tAllSkinList[i].dwID)
    if self.tAllSkinList[i].dwID == 0 then bSet = false end
    UIHelper.SetVisible(self.LabelTag,bSet)
    self:UpdateNameCardDesc()
    self:SetGrayBtn()
end

--展示好友选中效果
function UINameCardView:UpdateOtherSkin()
    local i = self.nCurIndex
    local tCardInfo = UINameCardTab[self.tAllSkinList[i]]
    if not tCardInfo and self.tbPlayerCard then
        tCardInfo = UINameCardTab[self.tbPlayerCard.nSkinID]
    end
    if tCardInfo then
        UIHelper.SetString(self.LabelTitle,tCardInfo["szName"])
        UIHelper.SetTexture(self.ImgBgTop1, tCardInfo["szVisitCardPath"])
        UIHelper.SetTexture(self.ImgBgTop2, tCardInfo["szVisitCardPath"])
    end
    UIHelper.SetVisible(self.BtnUse,false)
    self:UpdateOtherNameCardDesc()
end

function UINameCardView:SetGrayBtn()
    local bHave = self:DectTableValue(self.tMyHaveSkin,self.tAllSkinList[self.nCurIndex].dwID)
    if self.tAllSkinList[self.nCurIndex].dwID == 0 then bHave = true end
    UIHelper.SetVisible(self.BtnUse,true)
    if self.dwSkinID == self.tAllSkinList[self.nCurIndex].dwID then
        UIHelper.SetButtonState(self.BtnUse,BTN_STATE.Disable)
        UIHelper.SetString(self.LabelUse, g_tStrings.STR_SKIN_BTN_STATE[1])
    elseif bHave then
        UIHelper.SetButtonState(self.BtnUse,BTN_STATE.Normal)
        UIHelper.SetString(self.LabelUse,g_tStrings.STR_SKIN_BTN_STATE[2])
    else
        UIHelper.SetButtonState(self.BtnUse,BTN_STATE.Disable)
        UIHelper.SetString(self.LabelUse,g_tStrings.STR_SKIN_BTN_STATE[3])
    end
end

function UINameCardView:UpdateOtherNameCardDesc()
    UIHelper.RemoveAllChildren(self.LayoutDescribe)
    if self.tAllSkinList[self.nCurIndex] then
        local tLine = Table_GetFriendSkin(self.tAllSkinList[self.nCurIndex])
        if tLine then
            UIHelper.AddPrefab(PREFAB_ID.WidgetDescribe,self.LayoutDescribe,tLine.szSource,true)
            UIHelper.AddPrefab(PREFAB_ID.WidgetDescribe,self.LayoutDescribe,tLine.szTip)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutDescribe)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCardDetaiks)
end

function UINameCardView:UpdateNameCardDesc()
    UIHelper.RemoveAllChildren(self.LayoutDescribe)
    if self.tAllSkinList[self.nCurIndex].dwID == 0 then return end
    UIHelper.AddPrefab(PREFAB_ID.WidgetDescribe,self.LayoutDescribe,self.tAllSkinList[self.nCurIndex].szSource,true)
    UIHelper.AddPrefab(PREFAB_ID.WidgetDescribe,self.LayoutDescribe,self.tAllSkinList[self.nCurIndex].szTip)
    UIHelper.LayoutDoLayout(self.LayoutDescribe)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCardDetaiks)
end

--更新排列顺序
function UINameCardView:UpdateSkinList()
    for i,v in ipairs(self.tAllNameCardList) do
        local cardCellScript = v
        UIHelper.SetString(cardCellScript.LabelTitle,UIHelper.GBKToUTF8(self.tAllSkinList[i].szName))
        local bHave = self:DectTableValue(self.tMyHaveSkin, self.tAllSkinList[i].dwID)
        if self.tAllSkinList[i].dwID == 0 then bHave = true end
        UIHelper.SetVisible(cardCellScript.ImgLock,not bHave)
        local bSet = self:DectTableValue(self.tSetSkinList, self.tAllSkinList[i].dwID)
        if self.tAllSkinList[i].dwID == 0 then bSet = false end
        UIHelper.SetVisible(cardCellScript.ImgSee,bSet)
        UIHelper.SetVisible(cardCellScript.WidgetPossessed,self.dwSkinID == self.tAllSkinList[i].dwID and not self.bSetShow)
        if not self.bSetShow then
            UIHelper.SetVisible(cardCellScript.ImgSelect,self.dwSkinID == self.tAllSkinList[i].dwID)
        end
        if self.dwSkinID == self.tAllSkinList[i].dwID then
            self:ClickCardCell(i, cardCellScript.TogCard, true)
        end
        local tCardInfo = UINameCardTab[self.tAllSkinList[i].dwID]
        if tCardInfo then
            UIHelper.SetTexture(cardCellScript.ImgCardBg, tCardInfo["szVisitCardPath"])
        end
    end

    self:UpdateSkin()
end

function UINameCardView:UpdateOtherSkinList()
    for i,v in ipairs(self.tAllNameCardList) do
        local cardCellScript = v
        if self.tAllSkinList[i] then
            local tLine = Table_GetFriendSkin(self.tAllSkinList[i])
            UIHelper.SetString(cardCellScript.LabelTitle, UIHelper.GBKToUTF8(tLine.szName))
            local tCardInfo = UINameCardTab[self.tAllSkinList[i]]
            if tCardInfo then
                UIHelper.SetTexture(cardCellScript.ImgCardBg, tCardInfo.szVisitCardPath)
            end
        else
            UIHelper.SetVisible(cardCellScript.WidgetTitle,false)
            UIHelper.SetVisible(cardCellScript.TogCard,false)
            UIHelper.SetVisible(cardCellScript.ImgEmptyBg,true)
            UIHelper.SetString(self.LabelTag, "当前穿戴")
        end
        UIHelper.SetVisible(cardCellScript.ImgLock,false)
        UIHelper.SetVisible(cardCellScript.ImgSee,false)
    end
    self:UpdateOtherSkin()
end

function UINameCardView:UpdateSetShow(bSet)
    self.bSetShow = bSet
    if bSet then
        UIHelper.ToggleGroupRemoveAllToggle(self.togglegroup)
        for k,v in ipairs(self.tAllNameCardList) do
            local bSet_l = self:DectTableValue(self.tSetSkinList, self.tAllSkinList[k].dwID)
            if self.tAllSkinList[k].dwID == 0 then bSet_l = false end
            UIHelper.SetSelected(v.TogCard,bSet_l)
        end
    else
        for k,v in ipairs(self.tAllNameCardList) do
            UIHelper.ToggleGroupAddToggle(self.togglegroup,v.TogCard)
            UIHelper.SetVisible(v.ImgBgCheck, self.bSetShow)
        end
    end
    UIHelper.SetVisible(self.WidgetBtns,self.bSetShow)
    UIHelper.SetVisible(self.WidgetTxt,self.bSetShow)
    UIHelper.SetVisible(self.WidgetBtn,not self.bSetShow)
    UIHelper.SetVisible(self.BtnShow,not self.bSetShow)
    UIHelper.SetVisible(self.WidgetClose,not self.bSetShow)
    UIHelper.SetVisible(self.LayoutDescribe,not self.bSetShow)
    UIHelper.SetVisible(self.LableHint, self.bSetShow)
    UIHelper.SetString(self.LabelPageTitle, self.bSetShow and "配置展示" or "侠士名帖")
    self:UpdateSkinList()
end

function UINameCardView:UpdateSetShowNumber()
    local number = self:GetSetSkin()
    UIHelper.SetString(self.LabelTxt, FormatString(g_tStrings.STR_PLAYER_VISIT_SKIN_NUM,number))
end

--点击使用名帖
function UINameCardView:ClickChangeSkin()
    local SMClient = GetSocialManagerClient()
	if not SMClient then
		return
	end
	SMClient.SetSkin(self.tAllSkinList[self.nCurIndex].dwID)
end

--点击提交展示
function UINameCardView:ClickSetSkin()
    local nCount, tList = self:GetSetSkin()
	if nCount > SET_MAX then return end
    local SMClient = GetSocialManagerClient()
	if not SMClient then
		return
	end
	SMClient.SetNameCardSkinList(tList)
end

function UINameCardView:GetSetSkin()
    local nCount = 0
	local aTab = {}
	for dwID, _ in pairs(self.tSetShow) do
		nCount = nCount + 1
		table.insert(aTab, dwID)
	end
	table.sort(aTab)
	for i = #aTab + 1, SET_MAX do
		table.insert(aTab, 0)
	end
	return nCount, aTab
end

function UINameCardView:GetLength(t)
    local nCount = 0
    for k,v in pairs(t) do
        nCount = nCount + 1
    end
    return nCount
end

return UINameCardView