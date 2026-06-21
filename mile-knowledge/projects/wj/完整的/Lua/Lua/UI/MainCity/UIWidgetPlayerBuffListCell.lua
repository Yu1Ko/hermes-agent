-- WidgetMainCityBuff
local UIWidgetPlayerBuffListCell =  class("UIWidgetPlayerBuffListCell")

function UIWidgetPlayerBuffListCell:OnEnter()
end

function UIWidgetPlayerBuffListCell:OnExit()
end

function UIWidgetPlayerBuffListCell:UpdateBuffImage(dwBufferID, nLevel, player, tBuff)
    local tBuffList = {}
    if player then
        tBuffList = tBuff or BuffMgr.GetSortedBuff(player, true)
    end

    if self.dwBufferID ~= dwBufferID or self.nLevel ~= nLevel then
        local catalog = BuffMgr.GetBuffCatalog(dwBufferID, nLevel)
        --UIHelper.SetSpriteFrame(self.ImgBuffIcon, catalog.szFrame)
        local szIcon = TabHelper.GetBuffIconPath(dwBufferID, nLevel)
        local szPath = szIcon and string.format("Resource/icon/%s", szIcon)
        if szPath and Lib.IsFileExist(szPath) then
            UIHelper.SetTexture(self.ImgBuffIcon, szPath)
        end

        local bShowMark = #tBuffList > 1 and catalog.nType ~= 1 and catalog.nType ~= 2
        UIHelper.SetVisible(self.ImgBuffMark, bShowMark)
        UIHelper.SetVisible(self.ImgFrame, catalog.nType ~= 1 and catalog.nType ~= 2)

        if catalog.nID == 0 then
            UIHelper.SetActiveAndCache(self, self.SFXBuffIconLight, false)
        else
            local bDispel = BuffMgr.Buffer_IsDispelMobile(dwBufferID, nLevel)
            UIHelper.SetActiveAndCache(self, self.SFXBuffIconLight, bDispel)
        end
        self.dwBufferID = dwBufferID
        self.nLevel = nLevel


    end
end

function UIWidgetPlayerBuffListCell:UpdateBuffDefault()
    local catalog = UIBuffCatalogInfoTab[0]
    UIHelper.SetSpriteFrame(self.ImgBuffIcon, catalog.szFrame)
    UIHelper.SetVisible(self.SFXBuffIconLight, false)
end

function UIWidgetPlayerBuffListCell:ShowBuffLevel(nLevel)
    UIHelper.SetVisible(self.LabelBuffLevel, true)
    UIHelper.SetString(self.LabelBuffLevel, nLevel)
end

function UIWidgetPlayerBuffListCell:UpdateFakeBuffInfo(tbFakeBuffInfo)
    --local szIcon = TabHelper.GetBuffIconPath(tbFakeBuffInfo.dwBufferID, tbFakeBuffInfo.nLevel)
    local szPath = string.format("Resource/icon/%s", tbFakeBuffInfo)
    if szPath and Lib.IsFileExist(szPath) then
        UIHelper.SetTexture(self.ImgBuffIcon, szPath)
        UIHelper.SetVisible(self.ImgBuffMark, false)
        UIHelper.SetVisible(self.SFXBuffIconLight, false)
    end
end

function UIWidgetPlayerBuffListCell:UpdateArenaBuffImage(dwBufferID, nLevel, player)
    if self.dwBufferID ~= dwBufferID or self.nLevel ~= nLevel then
        local catalog = BuffMgr.GetBuffCatalog(dwBufferID, nLevel)
        local szPath = TabHelper.GetBuffIconPath(dwBufferID, nLevel)
        if szPath and Lib.IsFileExist(szPath) then
            UIHelper.SetTexture(self.ImgBuffIcon, szPath)
        end

        UIHelper.SetVisible(self.ImgBuffMark, false)
        UIHelper.SetVisible(self.ImgFrame, catalog.nType ~= 1 and catalog.nType ~= 2)

        if catalog.nID == 0 then
            UIHelper.SetActiveAndCache(self, self.SFXBuffIconLight, false)
        else
            local bDispel = BuffMgr.Buffer_IsDispelMobile(dwBufferID, nLevel)
            UIHelper.SetActiveAndCache(self, self.SFXBuffIconLight, bDispel)
        end
        self.dwBufferID = dwBufferID
        self.nLevel = nLevel
    end
end

return UIWidgetPlayerBuffListCell