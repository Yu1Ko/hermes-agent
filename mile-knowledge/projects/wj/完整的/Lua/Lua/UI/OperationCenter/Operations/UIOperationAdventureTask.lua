-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationAdventureTask
-- Date: 2026-04-10 16:15:20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationAdventureTask = class("UIOperationAdventureTask")

local NAME_FONT_SIZE = 24
local NAME_WIDTH = 160

function UIOperationAdventureTask:OnEnter(tAdv, tPet)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tAdv = tAdv
    self.tPet = tPet
    self:UpdateInfo()
end

function UIOperationAdventureTask:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationAdventureTask:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnNote, EventType.OnClick, function()
        if self.tPet and self.tPet.nLinkID ~= 0 and self.tPet.nMapID ~= 0 then
            AdventureData.TeleportGoPet(self.tPet)
        else
            UIMgr.Open(VIEW_ID.PanelQiYu, nil, self.tAdv.dwID)
        end
    end)
end

function UIOperationAdventureTask:RegEvent()

end

function UIOperationAdventureTask:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationAdventureTask:UpdateInfo()
    local tAdv = self.tAdv
    local tPet = self.tPet

    local tBuffList = StringParse_Numbers(tAdv.szBuffList) or {}
    local bUpBuff   = false
    for _, tBuff in ipairs(tBuffList) do
        local bHave = Buff_Have(g_pClientPlayer, tBuff[1], tBuff[2])
        if bHave then
            bUpBuff = true
            break
        end
    end
    bUpBuff = bUpBuff or AdventureData.IsLuckyPet(tPet.dwPetIndex)

    UIHelper.SetTexture(self.ImgQiYuIcon, tAdv.szMobileNamePath)

    local szPetName = UIHelper.GBKToUTF8(tPet.szName)
    if tPet.nMapID ~= 0 then
        local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(tPet.nMapID))
        szPetName = szPetName .. "(" .. szMapName .. ")"
    end
    szPetName = string.format("<color=#5F4E3A>%s</c>", szPetName)
    for nFontSize = NAME_FONT_SIZE, 1, -1 do
        local width = UIHelper.GetUtf8RichTextWidth(szPetName, nFontSize)
        if width <= NAME_WIDTH then
            UIHelper.SetFontSize(self.LabelPetName, nFontSize)
            break
        end
    end
    UIHelper.SetRichText(self.LabelPetName, szPetName)

    UIHelper.SetVisible(self.ImgToday, bUpBuff)
    UIHelper.SetVisible(self.LabelToday, bUpBuff)
end


return UIOperationAdventureTask