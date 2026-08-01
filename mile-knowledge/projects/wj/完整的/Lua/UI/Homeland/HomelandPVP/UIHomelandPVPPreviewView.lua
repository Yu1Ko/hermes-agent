-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandPVPPreviewView
-- Date: 2023-04-06 11:38:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandPVPPreviewView = class("UIHomelandPVPPreviewView")

function UIHomelandPVPPreviewView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandPVPPreviewView:OnExit()
    self.bInit = false
end

function UIHomelandPVPPreviewView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIHomelandPVPPreviewView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandPVPPreviewView:UpdateInfo()
    local bIndoor = true
    local tSuitInfo 	= HomelandPVPData.tSuit[HomelandPVPData.nCurrentSuit]
	local szPath, nFrame
	if bIndoor then
		szPath 			= tSuitInfo.szIndoorPath
		nFrame			= tSuitInfo.nIndoorFrame
	else
		szPath 			= tSuitInfo.szOutdoorPath
		nFrame			= tSuitInfo.nOutdoorFrame
	end

    if nFrame == -1 then
        szPath = string.gsub(szPath, "ui/Image", "mui/Resource")
        szPath = string.gsub(szPath, ".tga", ".png")
        szPath = string.gsub(szPath, ".Tga", ".png")
        UIHelper.SetTexture(self.ImgItem, szPath)
    end

    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(tSuitInfo.szName))
end


return UIHomelandPVPPreviewView