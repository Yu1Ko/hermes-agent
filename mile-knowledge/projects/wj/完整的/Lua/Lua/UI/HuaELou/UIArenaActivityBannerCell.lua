-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaActivityBannerCell
-- Date: 2026-03-17 00:00:00
-- Desc: 竞技群英赛宣传图/视频 Cell（参考 UICoinShopNewBannerItem）
-- ---------------------------------------------------------------------------------

local UIArenaActivityBannerCell = class("UIArenaActivityBannerCell")

function UIArenaActivityBannerCell:OnEnter(tData, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tData = tData
    self.nIndex = nIndex
    self:UpdateInfo()
end

function UIArenaActivityBannerCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIArenaActivityBannerCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBannerCell, EventType.OnClick, function()
        if self.szVideoUrl and self.szVideoUrl ~= "" then
            MovieMgr.PlayVideo(self.szVideoUrl, {bNet = true, bShop = true}, nil, false)
        end
    end)
end

function UIArenaActivityBannerCell:RegEvent()
end

function UIArenaActivityBannerCell:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIArenaActivityBannerCell:UpdateInfo()
    local szPath = self.tData.szImagePath
    if szPath and szPath ~= "" then
        szPath = string.gsub(szPath, "\\ui\\Image", "Resource")
        szPath = string.gsub(szPath, "/ui/Image", "Resource")
        szPath = string.gsub(szPath, "ui\\Image", "Resource")
        szPath = string.gsub(szPath, "ui/Image", "Resource")
        szPath = string.gsub(szPath, ".tga", ".png")
        UIHelper.SetTexture(self.ImgBanner, szPath)
    end

    self.szVideoUrl = nil
    local dwGoodID = self.tData.dwGoodID
    if dwGoodID and dwGoodID ~= 0 then
        local tbVideoList = CoinShop_GetAllLimitVideo(dwGoodID)
        if tbVideoList and #tbVideoList > 0 then
            self.szVideoUrl = MovieMgr.ParseStaticUrl(tbVideoList[1].szUrl, true)
        end
    end

    -- 有视频才显示播放按钮
    UIHelper.SetVisible(self.BtnBannerCell, self.szVideoUrl ~= nil and self.szVideoUrl ~= "")

    UIHelper.SetActiveAndCache(self, self.WidgetTipBG, false)
end

return UIArenaActivityBannerCell
