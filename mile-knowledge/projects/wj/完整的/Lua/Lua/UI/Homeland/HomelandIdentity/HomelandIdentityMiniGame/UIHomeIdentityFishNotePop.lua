-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityFishNotePop
-- Date: 2024-01-25 11:20:32
-- Desc: ?
-- ---------------------------------------------------------------------------------
local UIHomeIdentityFishNotePop = class("UIHomeIdentityFishNotePop")

function UIHomeIdentityFishNotePop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIHomeIdentityFishNotePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeIdentityFishNotePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function(btn)
        self:Close()
    end)
end

function UIHomeIdentityFishNotePop:RegEvent()

end

function UIHomeIdentityFishNotePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeIdentityFishNotePop:OpenFishDetails(tInfo, nWeight, nStar)
    if table_is_empty(tInfo) then
        return
    end
    self:Open()
    UIHelper.SetVisible(self.WidgetAnchorDetails, true)
    UIHelper.SetVisible(self.WidgetAnchorRank, false)
    self.tInfo = tInfo
    self.nWeight = nWeight
    self.nStar = nStar
    self:UpdateFishDetailsInfo()
end

function UIHomeIdentityFishNotePop:OpenFishRankList(tbInfo)
    if table_is_empty(tbInfo) then
        return
    end
    self:Open()
    UIHelper.SetVisible(self.WidgetAnchorRank, true)
    UIHelper.SetVisible(self.WidgetAnchorDetails, false)
    self.tbInfo = tbInfo
    self:UpdateRankInfo()
end

function UIHomeIdentityFishNotePop:UpdateFishDetailsInfo()
    local tInfo = self.tInfo
    local nWeight = self.nWeight
    local nStar = self.nStar
    local tbContentList = {
        UIHelper.GBKToUTF8(tInfo.szRegion),
        UIHelper.GBKToUTF8(tInfo.szUse),
        UIHelper.GBKToUTF8(tInfo.szDesc),
    }

    self.scriptFish = self.scriptFish or UIHelper.AddPrefab(PREFAB_ID.WidgetFishDetails, self.ScrollViewDetailsList)
    self.scriptFish:OnEnter(tInfo, nWeight, nStar)

    self.scriptHolder = self.scriptHolder or UIHelper.AddPrefab(PREFAB_ID.WidgetTipsLabelList, self.ScrollViewDetailsList)
    self.scriptHolder:InitWithFishHolder(tInfo, nWeight, nStar)

    for index, szDesc in ipairs(tbContentList) do
        local tbTips = {
            szTitle = g_tStrings.tbFishDetailContentList[index],
            tbTip = {{szName = "", szContent = szDesc, bFish = true}},
        }
        self["scriptDetail"..index] = self["scriptDetail"..index] or UIHelper.AddPrefab(PREFAB_ID.WidgetTipsLabelList, self.ScrollViewDetailsList)
        self["scriptDetail"..index]:OnEnter(tbTips)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDetailsList)
end

function UIHomeIdentityFishNotePop:SetOpenAni(fnOpenAni)
    self.fnOpenAni = fnOpenAni
end

function UIHomeIdentityFishNotePop:SetCloseAni(fnCloseAni)
    self.fnCloseAni = fnCloseAni
end

function UIHomeIdentityFishNotePop:Open()
    UIHelper.SetVisible(self._rootNode, true)
    if self.fnOpenAni then
        self.fnOpenAni()
    end
end

function UIHomeIdentityFishNotePop:Close()
    if self.fnCloseAni then
        self.fnCloseAni()
    end
end

function UIHomeIdentityFishNotePop:UpdateHolderInfo(tHolder)
    if tHolder and not table_is_empty(tHolder) then
        self.scriptFish:UpdateHolderInfo(tHolder)
        self.scriptHolder:UpdateHolderInfo(tHolder)
    end
end

function UIHomeIdentityFishNotePop:UpdateRankInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewRankList)

    for index, tbInfo in ipairs(self.tbInfo) do
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetFishRankCell, self.ScrollViewRankList)
        scriptCell:OnEnter(index, tbInfo)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRankList)
end

return UIHomeIdentityFishNotePop