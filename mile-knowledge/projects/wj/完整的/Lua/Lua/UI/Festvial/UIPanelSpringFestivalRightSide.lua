-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelSpringFestivalRightSide
-- Date: 2026-1-13 20:41:58
-- Desc: ?
-- ---------------------------------------------------------------------------------
local PER_WORD_COST = 200

local UIPanelSpringFestivalRightSide = class("UIPanelSpringFestivalRightSide")

function UIPanelSpringFestivalRightSide:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.tInfo = tInfo or {}
    end

    SoundMgr.PlaySound(SOUND.UI_SOUND, "UI_ChunJie_PaperOpen")
    if tInfo.nQuestItemIndex then
        UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutRightTopCurrency, 5, tInfo.nQuestItemIndex, true)
        local itemInfo = GetItemInfo(5, tInfo.nQuestItemIndex)
        if itemInfo then
            UIHelper.SetItemIconByItemInfo(self.ImgWeiMing, itemInfo, false, true)
        end
    end
    self:UpdateInfo()
end

function UIPanelSpringFestivalRightSide:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelSpringFestivalRightSide:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnChangeOver01, EventType.OnClick, function()
        if self.nTeachCurrentIndex then
            self:UpdateTeachImg(self.nTeachCurrentIndex - 1)
        end
    end)

    UIHelper.BindUIEvent(self.BtnChangeOver02, EventType.OnClick, function()
        if self.nTeachCurrentIndex then
            self:UpdateTeachImg(self.nTeachCurrentIndex + 1)
        end
    end)

    UIHelper.BindUIEvent(self.BtnScan, EventType.OnClick, function()
        local tData = self.tInfo.tActivityData

        UIMgr.Open(VIEW_ID.PanelSpringFestrivalActivityPop, 2, {
            tImgList = self.tTeachImgList,
            nCurIndex = self.nTeachCurrentIndex,
            szTitle = UIHelper.GBKToUTF8(tData.szName)
        })
    end)
end

function UIPanelSpringFestivalRightSide:RegEvent()
    Event.Reg(self, EventType.OnViewPlayHideAnimBegin, function(nViewID)
        if VIEW_ID.PanelSpringFestivalRightSide == nViewID then
            SoundMgr.PlaySound(SOUND.UI_SOUND, "UI_ChunJie_PaperOpen")
            if self.tInfo.fnClose then
                self.tInfo.fnClose()
            end
        end
    end)

    Event.Reg(self, "OnUnlockCouplet", function(tInfo)
        self:OnUnlock()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.DelAllTimer(self)
        Timer.AddFrame(self, 3, function()
            UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewContent, true, true)
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
        end)
    end)

    Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
        if string.is_nil(szUrl) then
            return
        end

        szUrl = Base64_Decode(szUrl)

        szUrl = string.gsub(szUrl, "\\", "/")
        local szLinkEvent, szLinkArg = szUrl:match("(%w+)/(.*)")

        if szLinkEvent == "ItemLinkInfo" then
            local szType, szID = szLinkArg:match("(%d+)/(%d+)")
            local dwType = tonumber(szType)
            local dwID = tonumber(szID)
            TipsHelper.ShowItemTips(node, dwType, dwID)
        end
    end)
end

function UIPanelSpringFestivalRightSide:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSpringFestivalRightSide:UpdateInfo()
    local tData = self.tInfo.tActivityData
    local bDone = self.tInfo.bDone
    local DataModel = self.tInfo.DataModel

    local nCost = 0
    if tData.nQuestItemCost ~= 0 and not bDone and not IsTableEmpty(tData.tCoupletList) then
        local nCount = 0
        for _, v in pairs(tData.tCoupletList) do
            if v and not DataModel.tCoupletState[v] then
                nCount = nCount + 1
            end
        end
        nCost = nCount * PER_WORD_COST
    end

    UIHelper.SetLabel(self.LabelTitle, UIHelper.GBKToUTF8(tData.szName))
    local szConverted = ParseTextHelper.ConvertRichTextFormat(UIHelper.GBKToUTF8(tData.szDesc), true)
    szConverted = string.gsub(szConverted, "E2F6FB", "4b4336") -- 黑色替换
    szConverted = string.gsub(szConverted, "79EAB4", "258a25") -- 绿色替换
    szConverted = string.gsub(szConverted, "89DFFF", "1a399e") -- 蓝色替换
    szConverted = string.gsub(szConverted, "FFE26E", "ad6e1a") -- 黄色替换1
    szConverted = string.gsub(szConverted, "F9B222", "1a399e") -- 蓝色替换
    UIHelper.SetLabel(self.RichTextDesc, szConverted)
    UIHelper.SetLabel(self.LabelCost, nCost)

    local tRewardList = tData.tRewardList
    if not IsTableEmpty(tRewardList) then
        UIHelper.RemoveAllChildren(self.LayoutAward)
        for _, v in ipairs(tRewardList) do
            local ScriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutAward)
            local dwTabType = v.dwTabType or v[1]
            local dwIndex = v.dwIndex or v[2]
            ScriptItem:OnInitWithTabID(dwTabType, dwIndex, v.nCount > 1 and v.nCount or nil)
            ScriptItem:SetClickNotSelected(true)
            ScriptItem:SetClickCallback(function(nItemType, nItemIndex)
                TipsHelper.ShowItemTips(ScriptItem._rootNode, dwTabType, dwIndex, false)
            end)
        end
        UIHelper.LayoutDoLayout(self.LayoutAward)
    end
    UIHelper.SetVisible(self.ImgRewardTitleBg, not IsTableEmpty(tRewardList))
    UIHelper.SetVisible(self.LayoutAward, not IsTableEmpty(tRewardList))

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewContent, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)

    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function()
        local tTargetList = HuaELouData.GetTargetList(nil, tData.szTPLink)
        if tTargetList and not IsTableEmpty(tTargetList) then
            local _, scriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicTraceTip, self.BtnGo, TipsLayoutDir.TOP_CENTER)
            if scriptView then
                scriptView:OnEnter(tTargetList)
            end
            return
        end
    end)

    local nCurrentTime = GetCurrentTime()
    local nStartTime = tData.nStartTime or 0
    local bStarted = nCurrentTime >= nStartTime
    if not bStarted then
        local function UpdateTime()
            local nCurrentTime1 = GetCurrentTime()
            local nDiff = nStartTime - nCurrentTime1
            local nDay = UIHelper.GetHeightestTwoTimeText(nDiff, false)
            UIHelper.SetString(self.LabelTime, nDay .. "后开启")

            if nDiff <= 0 then
                self:UpdateInfo()
            end
        end

        UpdateTime()
        Timer.AddCycle(self, 1, UpdateTime)
    else
        UIHelper.SetString(self.LabelTime, "")
    end

    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.SetVisible(self.WidgetDone, bStarted and bDone and tData.nQuestItemCost ~= 0)
    UIHelper.SetVisible(self.WidgetCost, bStarted and not bDone and tData.nQuestItemCost ~= 0)

    UIHelper.SetVisible(self.BtnGo, bStarted and tData.szTPLink ~= "")
    UIHelper.SetVisible(self.BtnDone, bStarted and not bDone and tData.nQuestItemCost ~= 0)
    UIHelper.BindUIEvent(self.BtnDone, EventType.OnClick, function()
        RemoteCallToServer("On_SpecialActUI_33CostCoin", tData.dwID)
    end)

    self:InitTeach()
end

function UIPanelSpringFestivalRightSide:InitTeach()
    local tData = self.tInfo.tActivityData
    self.tTeachImgList = {}
    for _, szPath in ipairs(tData.tTeachImgList) do
        table.insert(self.tTeachImgList, self:ProcessImgPath(szPath))
    end

    local nMaxNum = #self.tTeachImgList
    for nIndex, tog in ipairs(self.tTeachTogs) do
        UIHelper.SetVisible(tog, nMaxNum > 1 and nIndex <= nMaxNum) -- 单张图时不显示
        UIHelper.ToggleGroupAddToggle(self.TogGroupRewardItem, tog)
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(btn, bSel)
            if bSel then
                self:UpdateTeachImg(nIndex)
            end
        end)
    end

    UIHelper.LayoutDoLayout(self.LayoutRewardItem)
    self:UpdateTeachImg(1)

    if #self.tTeachImgList <= 1 then
        UIHelper.SetVisible(self.BtnChangeOver01, false) -- 单张图时不显示
        UIHelper.SetVisible(self.BtnChangeOver02, false)
    end
end

function UIPanelSpringFestivalRightSide:OnUnlock()
    local bDone = true
    local tData = self.tInfo.tActivityData
    UIHelper.SetVisible(self.WidgetDone, bDone and tData.nQuestItemCost ~= 0)
    UIHelper.SetVisible(self.WidgetCost, not bDone and tData.nQuestItemCost ~= 0)
    UIHelper.SetVisible(self.BtnDone, not bDone and tData.nQuestItemCost ~= 0)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIPanelSpringFestivalRightSide:UpdateTeachImg(nIndex)
    local nMaxNum = #self.tTeachImgList

    if not nIndex then
        return
    end

    nIndex = math.min(nMaxNum, nIndex)
    nIndex = math.max(1, nIndex)

    if not self.nTeachCurrentIndex or self.nTeachCurrentIndex ~= nIndex then
        self.nTeachCurrentIndex = nIndex
        local szPath = self:ProcessImgPath(self.tTeachImgList[self.nTeachCurrentIndex])
        UIHelper.SetTexture(self.ImgTeach, szPath)
        UIHelper.SetToggleGroupSelected(self.TogGroupRewardItem, nIndex - 1)
    end
end

function UIPanelSpringFestivalRightSide:ProcessImgPath(szOriginal)
    local szPath = UIHelper.GBKToUTF8(szOriginal)
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/NewYearTeachPic/Btn_5/焰火巡游", "Resource/SpringFestival/yanhuoxunyou/yhxy")
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/NewYearTeachPic/Btn_4/戏雪迎春", "Resource/SpringFestival/xixueyingchun/xxyc")
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/NewYearTeachPic/Btn_6/年夜盛宴", "Resource/SpringFestival/nianyefan/yysy")
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/NewYearTeachPic/Btn_4/戏雪迎春", "Resource/SpringFestival/zns/yhxy")
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/NewYearTeachPic/Btn_3/年年有鱼", "Resource/SpringFestival/niannianyouyu/nnyy")
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/NewYearTeachPic/Btn_1/砸年兽", "Resource/SpringFestival/zanianshou/zns")
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/NewYearTeachPic/Btn_2/接财纳福", "Resource/SpringFestival/jiecainafu/jcbf")
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/NewYearTeachPic/Btn_7/更多活动", "Resource/SpringFestival/gengduohuodong/gdhd")

    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/LanternFestivalTeachPic/Btn_8/sygyhcx", "Resource/LanternFestival/Shangyuanguyou/sygyhcx")
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/LanternFestivalTeachPic/Btn_9/hcyj", "Resource/LanternFestival/Huacheyoujie/hcyj")
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/LanternFestivalTeachPic/Btn_10/fyxx", "Resource/LanternFestival/Feiyuanxuxian/fyxx")
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/LanternFestivalTeachPic/Btn_12/yrxj", "Resource/LanternFestival/Youranxianju/yrxj")
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/LanternFestivalTeachPic/Btn_11/xlll", "Resource/LanternFestival/Xilelianlian/xlll")
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/LanternFestivalTeachPic/Btn_11/xlll", "Resource/LanternFestival/Xilelianlian/xlll")
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/LanternFestivalTeachPic/Btn_13/dz", "Resource/LanternFestival/Dazhan/dz")
    szPath = string.gsub(szPath, "ui/Image/UItimate/NewYearPanel/LanternFestivalTeachPic/Btn_13/xyhd", "Resource/LanternFestival/Xuyuanhuadeng/xyhd")
    szPath = string.gsub(szPath, ".tga", ".png")
    return szPath
end

return UIPanelSpringFestivalRightSide