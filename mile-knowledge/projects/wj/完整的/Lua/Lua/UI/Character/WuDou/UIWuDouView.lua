local UIWuDouView = class("UIWuDouView")

local LEFT_RANK_NUM = 3
local MAX_RANK_SIZE = 200
local szDefaultTopPlayerTopFileName = "UIAtlas2_Public_PublicIcon_PublicIcon1_img_seal_01.png"
local nApplyType2Words = {
    [REAL_TIME_RANK_LIST_TYPE.KILLER] = {
        szScoreName = "当前敌对数",
        TopRankTitle = {
            "冷面阎罗","索命夺魂","铁血无情"
        }
    },
    [REAL_TIME_RANK_LIST_TYPE.HUNTER] = {
        szScoreName = "本周抓捕数",
        TopRankTitle = {
            "绝世神捕","盖世神捕","稀世神捕"
        }
    },
    [REAL_TIME_RANK_LIST_TYPE.WANTED] = {
        szRewardName = "赏金额度",
        szScoreName = "时间",
        TopRankTitle = {
            "万金莫求","贵不可言","身价不凡"
        }
    },
}

function UIWuDouView:OnEnter(bPrivate)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitWuDouView()
    self:UpdateInfo(bPrivate)
end

function UIWuDouView:OnExit()
    self.bInit = false
    local scriptView = UIMgr.GetView(VIEW_ID.PanelCharacter)
    if scriptView then
        UIHelper.SetVisible(scriptView.node, true)
    end
end

function UIWuDouView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelWuDou)
    end)

    UIHelper.BindUIEvent(self.BtnWants, EventType.OnClick, function ()
        self:OpenWantsPublish()
    end)

    UIHelper.BindUIEvent(self.BtnWudou, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnWudou, "武斗值是用来记录玩家恶意PK程度的数值。武斗值太高的侠士，被捕快捕捉或重伤后可能被关至大唐监狱。")
    end)

    UIHelper.BindUIEvent(self.TogWanted, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            UIHelper.SetString(self.LabelRankTitle, self.szWantedRankTitle)
            QueryWantedInfo()
        end
    end)

    UIHelper.BindUIEvent(self.TogKiller, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            UIHelper.SetString(self.LabelRankTitle, self.szKillerRankTitle)
            ApplyRealTimeRankList(REAL_TIME_RANK_LIST_TYPE.KILLER)
        end
    end)

    UIHelper.BindUIEvent(self.TogHunter, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            UIHelper.SetString(self.LabelRankTitle, self.szHunterRankTitle)
            ApplyRealTimeRankList(REAL_TIME_RANK_LIST_TYPE.HUNTER)
        end
    end)

    UIHelper.TableView_addCellAtIndexCallback(self.TableView, function(tableView, nIndex, script, node, cell)
        local tbRankInfo = self.RankInfoList[nIndex]
        if script and tbRankInfo then
            script:OnEnter(self.nApplyType, nIndex, tbRankInfo, self.bPrivateWanted)
            self.scriptVaildCells[nIndex] = script
        end
    end)

    UIHelper.BindUIEvent(self.TogPublic, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self.bPrivateWanted = false
            self:UpdateWantedInfo()
        end
    end)

    UIHelper.BindUIEvent(self.TogPrivacy, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self.bPrivateWanted = true
            self:UpdateWantedInfo()
        end
    end)

    UIHelper.BindUIEvent(self.TogDisplay, EventType.OnSelectChanged, function(_, bSelected)
        Storage.Wangted.bOnlyShowOnline = bSelected
        self:UpdateWantedInfo()
    end)
end

function UIWuDouView:RegEvent()
    Event.Reg(self, EventType.OnClickWantedRankCell, function (szName)
        self:OpenWantsPublish(szName, true)
    end)

    Event.Reg(self, EventType.OnClickHunterRankCell, function (szName)
        self:OpenWantsPublish(szName, false)
    end)

    Event.Reg(self, "REAL_TIME_RANK_UPDATE", function (nApplyType, nSum)
        self:OnRealTimeRankUpdate(nApplyType, nSum)
        self:UpdateWodouNum()
    end)

    Event.Reg(self, "ON_WANTED_MAN_RESPOND", function (nErrCode)
        if nErrCode == WANTED_MAN_RESULT_CODE.SUCCESS then
            QueryWantedInfo()
        end
    end)

    Event.Reg(self, "ON_GET_WANTED_MIN_MONEY_LIMIT", function (szName, nMinLimit, nMaxLimit)
        self:OnGetWantedMinMoney(szName, nMinLimit, nMaxLimit)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
        Timer.AddFrame(self, 1, function ()
            for _, scriptCell in pairs(self.scriptVaildCells) do
                scriptCell:Resize()
            end
            UIHelper.TableView_scrollToTop(self.TableView)
        end)
    end)

    Event.Reg(self, "ON_SYNC_WANTED_INFO", function ()
        if UIHelper.GetSelected(self.TogWanted) then
            self:UpdateWantedInfo()
        end
    end)
end

function UIWuDouView:InitWuDouView()
    self.bSyncKiller = false
	self.bSyncPolice = false
	self.bSyncWant = false
	self.nKillerSum = 0
	self.nPoliceSum = 0
	self.nWantSum = 0
    self.nApplyType = REAL_TIME_RANK_LIST_TYPE.WANTED
    self.scriptHead = {nil,nil,nil}
    self.scriptVaildCells = {} -- TableView中的部分节点处于不可见状态后，脚本就被休眠了
    self.bPrivateWanted = false

    self.szWantedRankTitle = UIHelper.GetString(self.LabelWanted)
    self.szKillerRankTitle = UIHelper.GetString(self.LabelKiller)
    self.szHunterRankTitle = UIHelper.GetString(self.LabelHunter)
    QueryWantedInfo()
end

function UIWuDouView:UpdateInfo(bPrivate)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupWuDouList)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupWuDouList, self.TogWanted)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupWuDouList, self.TogKiller)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupWuDouList, self.TogHunter)

    UIHelper.SetToggleGroupIndex(self.TogPublic, ToggleGroupIndex.OptionalBox)
    UIHelper.SetToggleGroupIndex(self.TogPrivacy, ToggleGroupIndex.OptionalBox)

    self:InitDisPlayOnline()
    self:DelaySelectPrivacy(bPrivate)
    self:UpdateWodouNum()
end

function UIWuDouView:DelaySelectPrivacy(bPrivate)
    if self.nTimer then 
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
    self.nTimer = Timer.AddFrame(self, 1, function ()
        if bPrivate then
            UIHelper.SetSelected(self.TogPrivacy, true)
        else
            UIHelper.SetSelected(self.TogPublic, true)
        end
        self.nTimer = nil
    end)
end

function UIWuDouView:InitDisPlayOnline()
    UIHelper.SetSelected(self.TogDisplay, Storage.Wangted.bOnlyShowOnline, false)
end

function UIWuDouView:UpdateLeft(nApplyType)
    if self.nApplyType ~= nApplyType then
        return
    end
	for i = 1, LEFT_RANK_NUM do
		local tLeft = {}
        if nApplyType == REAL_TIME_RANK_LIST_TYPE.WANTED then
            tLeft = self.tbWantedList[i]
        else
            if i <= self.nSum then
                tLeft = GetCacheRealTimeRank(nApplyType, i)
            end
        end
        local bNeedHide =  (not tLeft) or table_is_empty(tLeft)
        local bIsWanted = nApplyType == REAL_TIME_RANK_LIST_TYPE.WANTED
        UIHelper.SetVisible(self.LabelTopPlayerNameList[i], not bNeedHide)
        UIHelper.SetVisible(self.ImgTopPlayerSchoolList[i], not bNeedHide)
        --UIHelper.SetVisible(self.LabelTopPlayerRewardList[i], not bNeedHide)
        UIHelper.SetVisible(self.WidgetHeadList[i], not bNeedHide)
        UIHelper.SetVisible(self.LabelTopPlayerFundList[i], not bNeedHide)
        UIHelper.SetVisible(self.ImgTopPlayerMoneyIcon[i], not bNeedHide and bIsWanted)
        UIHelper.SetVisible(self.ImgTopHeadEmptys[i], bNeedHide)

        local tWord = nApplyType2Words[self.nApplyType]
        UIHelper.SetString(self.LabelRankDescList[i], tWord.TopRankTitle[i])

        if not bNeedHide then
            local szName = UIHelper.GBKToUTF8(tLeft.szName)
            UIHelper.SetString(self.LabelTopPlayerNameList[i], szName, 7)

            local szScore = UIHelper.GBKToUTF8(tLeft.nScore or tLeft.nMoney)
            UIHelper.SetString(self.LabelTopPlayerRewardList[i], szScore)

            local nForceID = tonumber(tLeft.dwForceID)
            local szImgName = PlayerForceID2SchoolImg2[nForceID]
            if szImgName then
                UIHelper.SetSpriteFrame(self.ImgTopPlayerSchoolList[i], szImgName)
            end

            if bIsWanted then
                UIHelper.SetString(self.LabelScoreNameList[i], tWord.szRewardName)
            else
                UIHelper.SetString(self.LabelScoreNameList[i], tWord.szScoreName)
            end

            local dwPlayerID = tonumber(tLeft.dwID)
            local dwMiniAvatarID = tonumber(tLeft.dwMiniAvatarID)
            local nRoleType = tonumber(tLeft.nRoleType)
            self.scriptHead[i] = self.scriptHead[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHeadList[i], dwPlayerID)
            if dwMiniAvatarID then
                self.scriptHead[i]:SetRankFlag(true, bIsWanted)
                self.scriptHead[i]:SetHeadInfo(dwPlayerID, dwMiniAvatarID, nRoleType, nForceID)
            else
                self.scriptHead[i]:SetHeadWithForceID(nForceID)
            end
        else
            UIHelper.SetString(self.LabelTopPlayerRewardList[i], "虚席以待")
            UIHelper.SetSpriteFrame(self.ImgTopPlayerTagList[i], szDefaultTopPlayerTopFileName)
        end

        local parent = UIHelper.GetParent(self.WidgetHeadList[i])
        UIHelper.CascadeDoLayoutDoWidget(parent, true, true)
	end
end

function UIWuDouView:UpdateRight(nApplyType)
    local tWord = nApplyType2Words[self.nApplyType]
    if tWord.szRewardName then
        UIHelper.SetString(self.LabelRewardName, tWord.szRewardName)
    else
        UIHelper.SetString(self.LabelRewardName, "")
    end
    UIHelper.SetString(self.LabelScoreName, tWord.szScoreName)
    UIHelper.SetVisible(self.LabelListPlayer2, self.bPrivateWanted and nApplyType == REAL_TIME_RANK_LIST_TYPE.WANTED)
    UIHelper.SetVisible(self.LabelScoreNamePublic, not self.bPrivateWanted and nApplyType == REAL_TIME_RANK_LIST_TYPE.WANTED)
    UIHelper.SetVisible(self.LabelScoreName, self.bPrivateWanted or nApplyType ~= REAL_TIME_RANK_LIST_TYPE.WANTED)

    self.RankInfoList = {}
    if nApplyType ~= REAL_TIME_RANK_LIST_TYPE.WANTED then
        for i = 1, self.nSum do
            local tRight = GetCacheRealTimeRank(nApplyType, i)
            if not tRight then
                break
            end
            table.insert(self.RankInfoList, tRight)
        end
    else
        self.RankInfoList = self.tbWantedList
    end
    self.scriptVaildCells = {}
    UIHelper.TableView_init(self.TableView, #self.RankInfoList, PREFAB_ID.WidgetWuDouListCell)
    UIHelper.TableView_reloadData(self.TableView)
end

function UIWuDouView:UpdateWodouNum()
    UIHelper.SetString(self.LabelWudouNum, tostring(PlayerData.GetPlayerKillPoints(g_pClientPlayer)))
    UIHelper.CascadeDoLayoutDoWidget(self.BtnWudou, true, true)
end

function UIWuDouView:UpdateWantedInfo()
    local tbWantedList = {}
    for nIndex, tbInfo in ipairs(GetWantedInfo(self.bPrivateWanted)) do
        if (not Storage.Wangted.bOnlyShowOnline) or (tbInfo.dwMapID and tbInfo.dwMapID > 0) then
            table.insert(tbWantedList, tbInfo)
        end
    end
    self.tbWantedList = tbWantedList
    local nSum = #self.tbWantedList
    self:OnRealTimeRankUpdate(REAL_TIME_RANK_LIST_TYPE.WANTED, nSum)
end

function UIWuDouView:OnRealTimeRankUpdate(nApplyType, nSum)
    self.nApplyType = nApplyType
    if nApplyType == REAL_TIME_RANK_LIST_TYPE.KILLER then
        self.bSyncKiller = true
        self.nKillerSum = nSum
    elseif nApplyType == REAL_TIME_RANK_LIST_TYPE.HUNTER then
        self.bSyncPolice = true
        self.nPoliceSum = nSum
    elseif nApplyType == REAL_TIME_RANK_LIST_TYPE.WANTED then
        self.bSyncWant = true
        self.nWantSum = nSum
    end
    if self.nApplyType == nApplyType then
        self.nSum = nSum
    end
    local bIsWanted = nApplyType == REAL_TIME_RANK_LIST_TYPE.WANTED
    UIHelper.SetVisible(self.BtnWants, bIsWanted)
    UIHelper.SetVisible(self.AniEmpty, nSum <= 0)
    UIHelper.SetVisible(self.WidgetToogle, nApplyType == REAL_TIME_RANK_LIST_TYPE.WANTED)
    UIHelper.SetVisible(self.ImgListLine01, nApplyType == REAL_TIME_RANK_LIST_TYPE.WANTED)
    UIHelper.SetVisible(self.TogDisplay, nApplyType == REAL_TIME_RANK_LIST_TYPE.WANTED)
    self:UpdateLeft(nApplyType)
    self:UpdateRight(nApplyType)
end

local function LimitMapType()
	local dwCurrentMapID = GetClientPlayer().GetMapID()
	local _, nMapType = GetMapParams(dwCurrentMapID)
	if nMapType == MAP_TYPE.BIRTH_MAP or nMapType == MAP_TYPE.NORMAL_MAP then
		return true
	end
	return false
end

function UIWuDouView:OpenWantsPublish(szName, bIsAppend)
    local hPlayer = GetClientPlayer()
	if not LimitMapType() then
        TipsHelper.ShowNormalTip(g_tStrings.WANT_PUBLISH_LIMIT_MAP_TYPE)
		return
	elseif CheckPlayerIsRemote() then
        TipsHelper.ShowNormalTip(g_tStrings.WANT_PUBLISH_SELF_REMOTE_LIMIT)
		return
	elseif hPlayer.bFreeLimitFlag then
        TipsHelper.ShowNormalTip(g_tStrings.WANT_PUBLISH_FREE_LIMIT)
		return
	elseif hPlayer.nLevel < 20 then
        TipsHelper.ShowNormalTip(g_tStrings.WANT_PUBLISH_LEVEL_LIMIT)
		return
	end

    UIMgr.Open(VIEW_ID.PanelReleaseRewardPop, szName, bIsAppend, self.bPrivateWanted)
end


function UIWuDouView:OnGetWantedMinMoney(szName, nMinLimit, nMaxLimit)
    if nMinLimit then
        local szMoreTip = ""
		local szTip = FormatString(g_tStrings.WANT_PUBLISH_MONEY_TIP, nMinLimit, nMaxLimit)
		if nMinLimit > GetWantedPlayerMinGoldLimit() then
			szMoreTip = g_tStrings.WANT_PUBLISH_MONYE_DOUBLE
		end

		self.nMinMoney = nMinLimit
        UIHelper.SetPlaceHolder(self.EditBoxMoney, szTip)
        UIHelper.SetEnable(self.EditBoxMoney, true)
	else
        TipsHelper.ShowNormalTip(g_tStrings.WANT_PUBLISH_PLAYER_NOT_EXIST)
        UIHelper.SetEnable(self.EditBoxMoney, false)
	end
end

return UIWuDouView