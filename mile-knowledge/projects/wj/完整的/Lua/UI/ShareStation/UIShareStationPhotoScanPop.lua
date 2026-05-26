-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShareStationPhotoScanPop
-- Date: 2025-07-25 14:24:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIShareStationPhotoScanPop = class("UIShareStationPhotoScanPop")

function UIShareStationPhotoScanPop:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbData = tbData
    self:UpdateInfo()
end

function UIShareStationPhotoScanPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShareStationPhotoScanPop:BindUIEvent()
    UIHelper.BindUIEvent(self.ButtonClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIShareStationPhotoScanPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIShareStationPhotoScanPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShareStationPhotoScanPop:UpdateInfo()
    local tInfo = self.tbData
    local szCoverPath = tInfo.szCoverPath --封面路径
    local bHaveCover = szCoverPath and szCoverPath ~= "" and Lib.IsFileExist(szCoverPath, false)
    if bHaveCover then
        UIHelper.SetTexture(self.ImgScan, szCoverPath, false)
    end
    local nWidth, nHeight = ShareStationData.GetStandardSize(SHARE_DATA_TYPE.PHOTO, tInfo.nPhotoSizeType)
    UIHelper.SetContentSize(self.ImgScan, nWidth, nHeight)
end


return UIShareStationPhotoScanPop