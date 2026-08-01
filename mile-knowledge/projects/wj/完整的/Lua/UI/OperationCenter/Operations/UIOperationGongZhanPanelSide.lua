-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationGongZhanPanelSide
-- Date: 2026-03-25
-- Desc: PanelGongZhanSide
-- ---------------------------------------------------------------------------------

local UIOperationGongZhanPanelSide = class("UIOperationGongZhanPanelSide")

local function IsTaskCompleted(tInfo)
    local bFinished = CollectionData.GetFinishState(tInfo)
    local bOpen = true
    if tInfo.nClass1 == CLASS_MODE.DEFAULT
        and not CollectionData.IsDailyDungeon(tInfo.dwMapID) then
        bOpen = false
    end
    if bOpen then
        if tInfo.szActivity then
            bOpen = CollectionData.GetGuideIsOpen(tInfo)
        elseif tInfo.bOpen ~= nil then
            bOpen = tInfo.bOpen
        end
    end
    return bOpen and bFinished
end

local function IsTaskShow(tData, tInfo)
    local bShow = true
    if tInfo.nClass1 == CLASS_MODE.DEFAULT and not CollectionData.IsDailyDungeon(tInfo.dwMapID) then
        bShow = false
    end
    return bShow
end

function UIOperationGongZhanPanelSide:OnEnter(nCat, nType, tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCat  = nCat
    self.nType = nType or 1

    FellowshipData.ApplyMasterInfo()

    self:UpdateData(tData)
    self:UpdateInfo()
end

function UIOperationGongZhanPanelSide:OnExit()
    self.bInit = false
end

function UIOperationGongZhanPanelSide:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function(btn)
		UIMgr.Close(self)
	end)

    UIHelper.BindUIEvent(self.BtnMaster, EventType.OnClick, function(btn)
		UIMgr.Open(VIEW_ID.PanelApprenticeNew)
	end)

end

function UIOperationGongZhanPanelSide:RegEvent()
    Event.Reg(self, "ON_GET_MENTOR_LIST", function (dwDstPlayerID, MentorList, bGradute)
        if dwDstPlayerID == g_pClientPlayer.dwID then
            self.tbMyMaster = MentorList or {}
            self.bGraduate = false
            if not bGradute and #self.tbMyMaster == 0 then
                self.bGraduate = true
                self.tbMyMaster = {}
            else
                table.sort(self.tbMyMaster, function (a, b) return a.nCreateTime < b.nCreateTime end)
            end
        end
        self.tbMyMaster = FellowshipData.GetMyMasterList(self.tbMyMaster or {}, false)
        self:UpdateMentorBtn()
    end)

    --获得亲传师父列表
    Event.Reg(self, "ON_GET_DIRECT_MENTOR_LIST", function (dwPlayerID,aMyDirectMaster)
        if g_pClientPlayer.dwID == dwPlayerID then
            self.tbMyDirectMaster = aMyDirectMaster
            table.sort(self.tbMyDirectMaster, function (a, b) return a.nCreateTime < b.nCreateTime end)
        end
        self.tbMyDirectMaster = FellowshipData.GetMyMasterList(self.tbMyDirectMaster or {}, true)
        self:UpdateMentorBtn()
    end)
end

-- ----------------------------------------------------------
-- Please write your own code below  -----------------------------------
function UIOperationGongZhanPanelSide:UpdateData(tData)
    if tData == nil then
        local tAllData = Table_GetGongZhanActInfo()
        tData = tAllData[self.nCat][self.nType]
    end
    self.tRowData = tData

    self.tTaskList = {}
    if tData and tData.tGuildID then
        for _, dwID in ipairs(tData.tGuildID) do
            local tGuide = Table_GetGameGuideByID(dwID)
            if tGuide and IsTaskShow(tData, tGuide) then
                table.insert(self.tTaskList, {
                    dwID       = dwID,
                    szName     = tGuide.szName or "",
                    szTime     = tGuide.szTimeDesc or "",
                    bShowArrow = true,
                    tInfo      = tGuide,
                })
            end
        end
    end

    table.sort(self.tTaskList, function(a, b)
        local bACompleted = IsTaskCompleted(a.tInfo)
        local bBCompleted = IsTaskCompleted(b.tInfo)
        if bACompleted ~= bBCompleted then
            return not bACompleted
        end
        return a.dwID < b.dwID
    end)
end

function UIOperationGongZhanPanelSide:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewTaskList)

    if self.nCat == 1 then
        -- 每日奖励：只有推荐活动列表，无规则说明
        self:SetTitle("推荐活动")
        self:AppendTaskCells()
    elseif self:IsMentorDouble() then
        -- 师徒双赢：规则说明 + 推荐活动
        local szTitle = UIHelper.GBKToUTF8(string.pure_text(self.tRowData.szType))
        self:SetTitle(szTitle)
        self:AppendRuleDesc()
        self:AppendRecommendTitle(self.tRowData.nCoin ~= nil)

        self.tTaskList = {
            {
                szName     = UIHelper.UTF8ToGBK(g_tStrings.STR_GZ_PAGE_FB),
                szTime     = UIHelper.UTF8ToGBK(g_tStrings.STR_GZ_PAGE_FB_SUB),
                bShowArrow = true,
                bShowIcon  = true,
                tInfo = {
                    nClass1 = 1,
                    bOpen = false,
                    szMobileFunction = "OpenRoadChivalrousPVE",
                }
            },
            {
                szName     = UIHelper.UTF8ToGBK(g_tStrings.STR_GZ_PAGE_CAMP),
                szTime     = UIHelper.UTF8ToGBK(g_tStrings.STR_GZ_MENTOR_RELATED_SUB),
                bShowArrow = true,
                bShowIcon  = true,
                tInfo = {
                    nClass1 = 2,
                    bOpen = false,
                    szMobileFunction = "OpenRoadChivalrousPVP2",
                }
            },
            {
                szName     = UIHelper.UTF8ToGBK(g_tStrings.STR_GZ_PAGE_CONTEST),
                szTime     = UIHelper.UTF8ToGBK(g_tStrings.STR_GZ_MENTOR_RELATED_SUB),
                bShowArrow = true,
                bShowIcon  = true,
                tInfo = {
                    nClass1 = 3,
                    bOpen = false,
                    szMobileFunction = "OpenRoadChivalrousPVP1",
                }
            },
        }

        self:AppendTaskCells()
    else
        -- 普通活动：规则说明 + 推荐活动
        local szTitle = UIHelper.GBKToUTF8(string.pure_text(self.tRowData.szType))
        self:SetTitle(szTitle)
        self:AppendRuleDesc()
        self:AppendRecommendTitle(self.tRowData.nCoin ~= nil)
        self:AppendTaskCells()
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTaskList)
    self:UpdateMentorBtn()
end

function UIOperationGongZhanPanelSide:IsMentorDouble()
    if not self.tRowData then return false end
    local szPureType = string.pure_text(self.tRowData.szType or "")
    szPureType = UIHelper.GBKToUTF8(szPureType)
    return szPureType == g_tStrings.STR_GZ_MENTOR_DOUBLE
end

function UIOperationGongZhanPanelSide:UpdateMentorBtn()
    if self.tbMyMaster and self.tbMyDirectMaster and (self.bGraduate or #self.tbMyMaster > 0 or #self.tbMyDirectMaster > 0) then
        UIHelper.SetString(self.LabelMaster, "邀请师傅")
    else
        UIHelper.SetString(self.LabelMaster, "前往拜师")
    end
    UIHelper.SetVisible(self.BtnMaster, self:IsMentorDouble())
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIOperationGongZhanPanelSide:AppendRuleDesc()
    local scriptTopTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetMiniTitle, self.ScrollViewTaskList)
    scriptTopTitle:UpdateOnlyTitle("规则说明")

    local scriptTip = UIHelper.AddPrefab(PREFAB_ID.WidgetLabelContent, self.ScrollViewTaskList)

    local szDecs = UIHelper.GBKToUTF8(ParseTextHelper.ParseNormalText(self.tRowData.szDsc, false))
    scriptTip:SetContent(szDecs)
end

function UIOperationGongZhanPanelSide:AppendRecommendTitle(bHasBonus)
    local scriptMiddleTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetMiniTitle, self.ScrollViewTaskList)
    if bHasBonus then
        scriptMiddleTitle:UpdateOnlyTitle("推荐活动", "以下活动已含增益效果显示")
    else
        scriptMiddleTitle:UpdateOnlyTitle("推荐活动")
    end
end

function UIOperationGongZhanPanelSide:AppendTaskCells()
    for _, tTask in ipairs(self.tTaskList) do
        tTask.fnOnClick = function(tInfo)
            CollectionData.OnClickCard(tInfo)
        end
        local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetGongZhanTaskCell, self.ScrollViewTaskList, tTask)
    end
end

function UIOperationGongZhanPanelSide:SetTitle(szTitle)
    UIHelper.SetString(self.LabelTitle, szTitle)
end

return UIOperationGongZhanPanelSide
