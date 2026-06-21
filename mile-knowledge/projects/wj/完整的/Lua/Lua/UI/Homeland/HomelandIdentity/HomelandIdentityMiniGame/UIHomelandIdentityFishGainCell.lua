-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityFishGainCell
-- Date: 2024-02-04 10:04:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandIdentityFishGainCell = class("UIHomelandIdentityFishGainCell")

function UIHomelandIdentityFishGainCell:OnEnter(tData, tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tData = tData
    self.tInfo = tInfo
    self:UpdateInfo()
end

function UIHomelandIdentityFishGainCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityFishGainCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRecord, EventType.OnClick, function()
        RemoteCallToServer("On_HomeLand_CheckFishRC", self.tData.nFishIndex, 1)
        self.bApplyRC = true
    end)
end

function UIHomelandIdentityFishGainCell:RegEvent()
    Event.Reg(self, EventType.OnGetFishGainRecordTips, function (tHolder)
        if not self.bApplyRC or tHolder.nFishIndex ~= self.tData.nFishIndex then
            return
        end
        local nX = UIHelper.GetWorldPositionX(self.BtnRecord)
        local nY = UIHelper.GetWorldPositionY(self.BtnRecord)
        TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetFishRecordTip, nX, nY, tHolder)
        self.bApplyRC = false
    end)
end

function UIHomelandIdentityFishGainCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandIdentityFishGainCell:UpdateInfo()
    local tInfo = self.tInfo
    local tData = self.tData
    local nStar = tData.nStar
    local szBgPath = HomelandFishGainCellQualityImg[tInfo.nQuality]
    local szWeight  = FormatString(g_tStrings.STR_HOMELAND_FISHWEIGHT, string.format("%.2f",(tData.nWeight / 100)))
    local bNewRecord = tData.bNewRecord
    local imgFish = tInfo.nFishType == 1 and self.ImgFishIcon or self.ImgFishBig
    local szPath = UIHelper.FixDXUIImagePath(tInfo.szPath)
    UIHelper.SetTexture(imgFish, szPath)
    -- imgFish:setTexture(szPath, false)
    -- if self.ImgFishIcon.getTexture then
    --     local tex = self.ImgFishIcon:getTexture()
    --     if tex and tex.getContentSize then
    --         local size = tex:getContentSize()
    --         UIHelper.SetContentSize(self.ImgFishIcon, size.width, size.height)
    --     end
    -- end
    UIHelper.SetSpriteFrame(self.ImgBg, szBgPath)
    UIHelper.SetString(self.LabelWeight, szWeight)
    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(tInfo.szName))
    UIHelper.SetVisible(self.ImgNew, bNewRecord)
    for index, img in ipairs(self.tbStarImg) do
        UIHelper.SetVisible(img, index <= nStar)
    end
end


return UIHomelandIdentityFishGainCell