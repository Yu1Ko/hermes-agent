-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFacePageTog
-- Date: 2024-02-28 16:31:59
-- Desc: ?
-- ---------------------------------------------------------------------------------
local DECORATION_ARENA_ID = 5
local UIBuildFacePageTog = class("UIBuildFacePageTog")

function UIBuildFacePageTog:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIBuildFacePageTog:OnExit()
    self.bInit = false
end

function UIBuildFacePageTog:BindUIEvent()

end

function UIBuildFacePageTog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBuildFacePageTog:UpdateInfo()
    UIHelper.SetString(self.LabelFace, self.tbInfo.szName)
    UIHelper.SetString(self.LabelFaceSelected, self.tbInfo.szName)
    UIHelper.SetSpriteFrame(self.ImgIcon, string.format("%s_1", self.tbInfo.szIcon))
    UIHelper.SetSpriteFrame(self.ImgIcon2, string.format("%s_2", self.tbInfo.szIcon))

    local bDis = false
    local bNew = false

    if BuildFaceData.bPrice then
        if self.tbInfo.nPageType == 2 then
            -- Makeup
            local tFaceDecalList = BuildFaceData.tDecalClassList
            for _, tbConfig in pairs(tFaceDecalList) do
                local nLabel = tbConfig.nLabel
                if tbConfig.nAreaID == DECORATION_ARENA_ID  then
                    nLabel = kmath.orOperator(nLabel, BuildFaceData.GetDecorationLabel())
                end

                if nLabel then
                    if kmath.andOperator(nLabel, NEWFACE_LABEL.DISCOUNT) ~= 0 then
                        bDis = true
                    elseif kmath.andOperator(nLabel, NEWFACE_LABEL.NEW) ~= 0 then
                        bNew = true
                    end
                end
            end
        elseif self.tbInfo.nPageType == 7 then
            -- MakeupOld
            local tDecalList = Table_GetDecorationList(BuildFaceData.nRoleType)
            if tDecalList then
                local nLabel = BuildFaceData.GetOldDecorationLabel(tDecalList)
                if nLabel == EXTERIOR_LABEL.NEW then
                    bNew = true
                end
            end

            local tFaceDecalList = BuildFaceData.tOldDecalClassList
            for _, tbConfig in pairs(tFaceDecalList) do
                if tbConfig.dwClassID and tbConfig.dwClassID > 0 then
                    local _, nLabel = BuildFaceData.GetOldDecalList(BuildFaceData.nRoleType, tbConfig.dwClassID)
                    if nLabel == EXTERIOR_LABEL.NEW then
                        bNew = true
                    end
                end
            end
        end
    end

    local szPath = "UIAtlas2_Shopping_ShoppingIcon_img_new"
    if bDis then
        szPath = "UIAtlas2_Shopping_ShoppingIcon_img_discount"
    end
    UIHelper.SetVisible(self.ImgNew, bNew or bDis)
    UIHelper.SetSpriteFrame(self.ImgNew, szPath)
end


return UIBuildFacePageTog