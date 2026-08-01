-- ---------------------------------------------------------------------------------
-- Name: UIElectionForemanCell
-- Prefab: WidgetCommandNum
-- Desc: 阵营 - 指挥竞选 - 头像点击 - 团长战绩 - 加载cell
-- ---------------------------------------------------------------------------------
local UIElectionForemanCell = class("UIElectionForemanCell")

function UIElectionForemanCell:OnEnter(tInfo)
    if not self.bInit then
        self.bInit = true
    end
    self:UpdateInfo(tInfo)
end

function UIElectionForemanCell:OnExit()
    self.bInit = false
end

function UIElectionForemanCell:BindUIEvent()
end

function UIElectionForemanCell:RegEvent()
end

function UIElectionForemanCell:UpdateInfo(tInfo)
    UIHelper.SetString(self.LabelCommandTitle, tInfo.szName)
    UIHelper.SetString(self.LabelCommandNum, tInfo.nValue)
    UIHelper.SetSpriteFrame(self.ImgCommandNumIcon, tInfo.Img)
    if tInfo.szTips and tInfo.szTips ~= "" then
        UIHelper.BindUIEvent(self.BtnTips, EventType.OnClick, function ()
            TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnTips, tInfo.szTips)
        end)
    else
        UIHelper.SetTouchEnabled(self.BtnTips, false)
    end
end

return UIElectionForemanCell