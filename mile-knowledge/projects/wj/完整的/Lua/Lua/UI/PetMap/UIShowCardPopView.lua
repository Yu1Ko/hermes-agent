-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShowCardPopView
-- Date: 2023-03-24 15:08:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIShowCardPopView = class("UIShowCardPopView")

function UIShowCardPopView:OnEnter(node)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetString(self.LabelPetName,UIHelper.GBKToUTF8(node.szName))
    local nScore = GetFellowPetScore(node.dwPetIndex)
    UIHelper.SetString(self.LabelBeltPetScore,nScore)
    UIHelper.SetString(self.LabelPoint,nScore)
    for i = 1,5,1 do
        UIHelper.SetVisible(self.tbImgStarLight[i], i <= node.nStar)
    end
    UIHelper.SetSpriteFrame(self.ImgPetBoxBg, PetImgQuality[node.nQuality])
    UIHelper.SetSpriteFrame(self.ImgLevelBg, PetImgQualityTab[node.nQuality])
    local szPath = node.szBgPath

    local szImgName = string.match(szPath, "\\([^\\]+)tga")
    if not szImgName then
        szImgName = string.match(szPath, "/([^/]+)tga")
    end
    if szImgName then
        szPath = "Resource/Pets/"..szImgName.."png"
    end
    UIHelper.SetTexture(self.ImgFrame, szPath)
end

function UIShowCardPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShowCardPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIShowCardPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIShowCardPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShowCardPopView:UpdateInfo()

end


return UIShowCardPopView