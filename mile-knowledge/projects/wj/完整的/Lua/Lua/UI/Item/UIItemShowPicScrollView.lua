-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIItemShowPicScrollView
-- Date: 2023-11-06 10:28:11
-- Desc: 道具展示图画效果
-- ---------------------------------------------------------------------------------

local UIItemShowPicScrollView = class("UIItemShowPicScrollView")

function UIItemShowPicScrollView:OnEnter(nImageID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nImageID = nImageID
    self:UpdateInfo()
end

function UIItemShowPicScrollView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIItemShowPicScrollView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)
end

function UIItemShowPicScrollView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemShowPicScrollView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓�?
-- ----------------------------------------------------------

function UIItemShowPicScrollView:UpdateInfo()
    local tInfo = Table_GetHuaZhaoJieImageInfo(self.nImageID)
    local szImagePath = string.match(UIHelper.GBKToUTF8(tInfo.szImagePath), "([^/]*)$");
    local startIndex = string.find(szImagePath,"%.")
    szImagePath = string.sub(szImagePath , 0,startIndex)
    szImagePath = UIHelper.UTF8ToGBK(szImagePath)
    UIHelper.SetTexture(self.ImgContent, "Resource/JYPlay/PetPostcard_Card/"..szImagePath.."png")
    UIHelper.SetString(self.LabelTitle , UIHelper.GBKToUTF8(tInfo.szTitle))
end


return UIItemShowPicScrollView