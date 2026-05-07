-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBirthdayCelebrateCardPop
-- Date: 2025-12-24 19:22:09
-- Desc: 生日贺卡弹窗
-- ---------------------------------------------------------------------------------
local DataModel = {}

function DataModel.Init(nYear)
    DataModel.nYear = nYear
    DataModel.tInfo = Table_GetBirthdayCarInfo(nYear)
end

function DataModel.UnInit()
    
end

local UIBirthdayCelebrateCardPop = class("UIBirthdayCelebrateCardPop")

function UIBirthdayCelebrateCardPop:OnEnter(nYear)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    DataModel.Init(nYear)
    self.bHaveShow = false -- 是否已经展开了
    self:UpdateInfo()
end

function UIBirthdayCelebrateCardPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBirthdayCelebrateCardPop:BindUIEvent()
    UIHelper.SetSwallowTouches(self.BtnOpen, false)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnOpen, EventType.OnClick, function()
        if not self.bHaveShow then
            self.bHaveShow = true
            UIHelper.SetVisible(self.Eff_Open, true)
            UIHelper.PlaySFX(self.Eff_Open)
            UIHelper.PlayAni(self, self.AniAll, "AniChampionshipRankPop2Show")
            UIHelper.SetVisible(self.BtnClose, true)
            Timer.Add(self, 0.5, function()
                UIHelper.SetVisible(self.Eff_Cover, false)
            end)
        end
    end)
end

function UIBirthdayCelebrateCardPop:RegEvent()

end

function UIBirthdayCelebrateCardPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBirthdayCelebrateCardPop:UpdateInfo()
    self:UpdateBg()
    self:UpdatePlayerName()
    self:UpdateContent()
    UIHelper.SetVisible(self.BtnClose, false)
end

function UIBirthdayCelebrateCardPop:UpdateBg()
    local tInfo = DataModel.tInfo
    if not tInfo then
        return
    end

    if tInfo.szMBContentImgPath and tInfo.szMBContentImgPath ~= "" then
        -- todo 封面替换
    end

    if tInfo.szCoverSfxPath and tInfo.szCoverSfxPath ~= "" then
        UIHelper.SetSFXPath(self.Eff_Cover, tInfo.szCoverSfxPath)
        UIHelper.PlaySFX(self.Eff_Cover)
    end

    if tInfo.szOpenSfxPath and tInfo.szOpenSfxPath ~= "" then
        UIHelper.SetSFXPath(self.Eff_Open, tInfo.szOpenSfxPath)
        -- UIHelper.PlaySFX(self.Eff_Open)
    end
end

function UIBirthdayCelebrateCardPop:UpdateContent()
    local tInfo = DataModel.tInfo
    if not tInfo then
        return
    end
end

function UIBirthdayCelebrateCardPop:UpdatePlayerName()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return 
    end
    -- local tInfo = DataModel.tInfo -- 暂时不需要修改称呼
    -- local szXiaShi = tInfo.szXiaShi or ""
    local szName = pPlayer.szName or ""
    szName = UIHelper.GBKToUTF8(szName)
    UIHelper.SetString(self.LabelName, szName)
end



return UIBirthdayCelebrateCardPop