-- ---------------------------------------------------------------------------------
-- Name: UIShowCardDataCell
-- Desc: 名片形象 - 展示数据cell(中间卡片的)
-- ---------------------------------------------------------------------------------

local UIShowCardDataCell = class("UIShowCardDataCell")

function UIShowCardDataCell:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIShowCardDataCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShowCardDataCell:BindUIEvent()
end

function UIShowCardDataCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIShowCardDataCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIShowCardDataCell:UpdateInfo(tData)
    if not tData then return end

    UIHelper.SetTexture(self.ImgIcon, tData.Img)
    UIHelper.SetString(self.LabelTitle, tData.szName)
    UIHelper.SetString(self.LableInfo, tData.nValue1)
end

return UIShowCardDataCell