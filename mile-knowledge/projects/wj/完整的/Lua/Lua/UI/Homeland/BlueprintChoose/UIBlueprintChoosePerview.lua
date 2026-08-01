-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBlueprintChoosePerview
-- Date: 2024-04-29 20:09:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBlueprintChoosePerview = class("UIBlueprintChoosePerview")

function UIBlueprintChoosePerview:OnEnter(tbConfig)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbConfig = tbConfig
    self:UpdateInfo()
end

function UIBlueprintChoosePerview:OnExit()
    self.bInit = false
end

function UIBlueprintChoosePerview:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSwitch, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        UIHelper.ShowConfirm(string.format("你确定要选择【%s】的蓝图【%s】吗？\n选择之后不可更换哦！", UIHelper.GBKToUTF8(self.tbConfig.szAuthor), UIHelper.GBKToUTF8(self.tbConfig.szName)), function()
            RemoteCallToServer("On_Item_BluePrint", self.tbConfig.nIndex)
            UIMgr.Close(self)
            UIMgr.Close(VIEW_ID.PanelBlueprintChoose)
        end)
    end)
end

function UIBlueprintChoosePerview:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBlueprintChoosePerview:UpdateInfo()
    local szPath = UIHelper.FixDXUIImagePath(self.tbConfig.szTipBigImgPath)
    UIHelper.SetTexture(self.ImgPic, szPath)

    UIHelper.SetString(self.LabelNameBlueprint, UIHelper.GBKToUTF8(self.tbConfig.szName))
    UIHelper.SetString(self.LabelNameAuthor, UIHelper.GBKToUTF8(self.tbConfig.szAuthor))

    local szDesc = UIHelper.GBKToUTF8(self.tbConfig.szTipText)
    szDesc = string.pure_text(szDesc)

    UIHelper.SetString(self.LabelDetail, szDesc)
end


return UIBlueprintChoosePerview