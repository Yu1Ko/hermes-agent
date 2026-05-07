-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieCameraMoveSelect
-- Date: 
-- Desc: 运镜选择节点
-- ---------------------------------------------------------------------------------
local UISelfieCameraMoveSelect = class("UISelfieCameraMoveSelect")

function UISelfieCameraMoveSelect:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tInfo = tInfo
    self:UpdateInfo()
end

function UISelfieCameraMoveSelect:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieCameraMoveSelect:BindUIEvent()
    UIHelper.BindUIEvent(self.TogCameraMoveSelection , EventType.OnClick , function ()
        Event.Dispatch(EventType.OnSelfieCameraAniSelected, self.tInfo.nCameraAniID, self.bSelected)
    end)
end

function UISelfieCameraMoveSelect:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISelfieCameraMoveSelect:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UISelfieCameraMoveSelect:UpdateInfo()
    self:SetSelectState(false, 0)
    UIHelper.SetVisible(self.TogCameraMoveSelection, true)
    UIHelper.SetString(self.LabelCameraMoveSelection, UIHelper.GBKToUTF8(self.tInfo.szName))
    local szImgBgPath =  self.tInfo.szPreviewImgPath
    szImgBgPath = UIHelper.FixDXUIImagePath(szImgBgPath)
    if szImgBgPath and szImgBgPath ~= "" then
        UIHelper.SetTexture(self.ImgCameraMoveSelection, szImgBgPath)
    end
end

function UISelfieCameraMoveSelect:SetSelectState(bSelected, nPos)
    self.bSelected = bSelected

    UIHelper.SetVisible(self.WidgetSelected, self.bSelected)
    UIHelper.SetVisible(self.ImgNumber,bSelected and nPos > 0)
    if nPos > 0 then
        UIHelper.SetString(self.LabelCameraMoveNumber, nPos)
    end
end


return UISelfieCameraMoveSelect