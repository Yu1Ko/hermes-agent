-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopDownloadBtn
-- Date: 2023-11-21 20:09:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopDownloadBtn = class("UICoinShopDownloadBtn")

function UICoinShopDownloadBtn:OnEnter(nType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nType = nType or 1
    UIHelper.SetVisible(self.BtnDownload, self.nType == 1)
    UIHelper.SetVisible(self.ImgDownload, self.nType == 2)
end

function UICoinShopDownloadBtn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopDownloadBtn:BindUIEvent()
end

function UICoinShopDownloadBtn:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopDownloadBtn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------


function UICoinShopDownloadBtn:UpdateInfo(tDownloadInfo)
    self.tDownloadInfo = tDownloadInfo

    if not self.tDownloadInfo.nDynamicID then
        self:SetVisible(false)
        return
    end

    self:SetVisible(true)

    local szAnim1 = "AniBtnDownloadSuspend"
    local szAnim2 = "AniImgDownload"

    if self.tDownloadInfo.bComplete then
        UIHelper.SetString(self.LabelPrograss, "已完成")
    elseif not self.tDownloadInfo.bStart then
        UIHelper.SetString(self.LabelPrograss, "未开始")
    else
        szAnim1 = "AniBtnDownloadContinue"
        local nDownloadedSize = self.tDownloadInfo.nDownloadedSize or 0
        local szProgress = string.format("%0.1f%%", nDownloadedSize/self.tDownloadInfo.nTotalSize)
        UIHelper.SetString(self.LabelPrograss, "下载中\n" .. szProgress)
    end

    UIHelper.SetPosition(self.LabelPrograss, 0, -10)

    if self.nType == 1 then
        self:PlayAnim(szAnim1)
    elseif self.nType == 2 then
        self:PlayAnim(szAnim2)
    end
end

function UICoinShopDownloadBtn:PlayAnim(szAnim)
    if szAnim and szAnim ~= self.szAnim then
        UIHelper.StopAni(self, self.Ani, self.szAnim)
        UIHelper.PlayAni(self, self.Ani, szAnim)
        self.szAnim = szAnim
    end
end

function UICoinShopDownloadBtn:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
end

return UICoinShopDownloadBtn