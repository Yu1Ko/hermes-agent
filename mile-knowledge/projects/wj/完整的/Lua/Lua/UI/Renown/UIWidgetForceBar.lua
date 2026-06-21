local UIWidgetForceBar = class("UIWidgetForceBar")

local Level2IconPath = {
    [0]     = "UIAtlas2_Renown_Renown1_chouhen.png",
    [1]     = "UIAtlas2_Renown_Renown1_dishi.png",
    [2]     = "UIAtlas2_Renown_Renown1_shuyuan.png",
    [3]     = "UIAtlas2_Renown_Renown1_zhongli.png",
    [4]     = "UIAtlas2_Renown_Renown1_youhao.png",
    [5]     = "UIAtlas2_Renown_Renown1_qinmi.png",
    [6]     = "UIAtlas2_Renown_Renown1_jingzhong.png",
    [7]     = "UIAtlas2_Renown_Renown1_zunjing.png",
    [8]     = "UIAtlas2_Renown_Renown1_qinpei.png",
    [9]     = "UIAtlas2_Renown_Renown1_qinpei.png",
    [10]    = "UIAtlas2_Renown_Renown1_qinpei.png",
    [11]    = "UIAtlas2_Renown_Renown1_qinpei.png",
    [12]    = "UIAtlas2_Renown_Renown1_qinpei.png",
}

function UIWidgetForceBar:OnEnter(nDlcID, dwForceID, szGroupName, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nDlcID = nDlcID
    self.dwForceID = dwForceID
    self.szGroupName = szGroupName
    self.fCallBack = fCallBack
    self:UpdateInfo()
end

function UIWidgetForceBar:OnExit()
    self.bInit = false
end

function UIWidgetForceBar:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            if self.fCallBack then
                self.fCallBack()
            end
        end
    end)
end

function UIWidgetForceBar:RegEvent()
    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelRenownUseItemPop then
            self:UpdateInfo()
        end
    end)
end

function UIWidgetForceBar:UpdateInfo()
    local player = GetClientPlayer()
    local tForceUIInfo = Table_GetReputationForceInfo(self.dwForceID)

    local szName = UIHelper.GBKToUTF8(tForceUIInfo.szName)
    self.szName = szName
    UIHelper.SetString(self.LabelForceNameDark, szName)
    UIHelper.SetString(self.LabelForceNameLight, szName)

    local dwReputationLevel = player.GetReputeLevel(self.dwForceID)
    local nReputation = player.GetReputation(self.dwForceID)
    local nReputeLimit = GetReputeLimit(dwReputationLevel)
    local nPercent = nReputation/nReputeLimit*100
    local szProgress = string.format("<color=#ffd778>%d</color>/%d", nReputation, nReputeLimit)
    UIHelper.SetRichText(self.LabelProgressDark, szProgress)
    UIHelper.SetRichText(self.LabelProgressLight, szProgress)
    UIHelper.SetProgressBarPercent(self.ProgressBarRenown, nPercent)

    local tReputInfo = Table_GetReputationLevelInfo(dwReputationLevel)
    local szReputName = UIHelper.GBKToUTF8(tReputInfo.szName)
    UIHelper.SetString(self.LabelRenownLevel, szReputName)
    local szReputPath = Level2IconPath[dwReputationLevel]
    if szReputPath then
        UIHelper.SetSpriteFrame(self.ImgRenownGradeBg, szReputPath)
    end

    local tbConfig = Table_GetReputationForceInfo(self.dwForceID)
    if tbConfig then
        UIHelper.SetTexture(self.ImgForceIcon, tbConfig.szIconPath)
    end
end

function UIWidgetForceBar:Resize()
    local parent = UIHelper.GetParent(self._rootNode)
    UIHelper.SetWidth(parent, UIHelper.GetWidth(UIHelper.GetParent(parent)))
    UIHelper.WidgetFoceDoAlign(self)
end

return UIWidgetForceBar