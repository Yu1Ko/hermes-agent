-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UILoginCreateRoleIntroduce
-- Date: 2022-12-28 14:27:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UILoginCreateRoleIntroduce = class("UILoginCreateRoleIntroduce")
local NAME_TO_IMAGE = {
    ["输出"] = "UIAtlas2_Login_NewCharacter_Tag_ShuChu",
    ["防御"] = "UIAtlas2_Login_NewCharacter_Tag_FangYu",
    ["治疗"] = "UIAtlas2_Login_NewCharacter_Tag_ZhiLiao",
}

function UILoginCreateRoleIntroduce:OnEnter(nForceID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if nForceID then
        self:Init(nForceID)
        self:UpdateInfo()
        self:UpadteXinFaName()
    end
end

function UILoginCreateRoleIntroduce:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UILoginCreateRoleIntroduce:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChange, EventType.OnClick, function()
        -- self.nCur
        self.nCurRouteIndex = self.nCurRouteIndex + 1
        if self.nCurRouteIndex > self.nRouteName then
            self.nCurRouteIndex = 1
        end
        self:UpadteXinFaName()
        self:UpdateAttribute()
    end)
end

function UILoginCreateRoleIntroduce:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

end

function UILoginCreateRoleIntroduce:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILoginCreateRoleIntroduce:Init(nForceID)

    self.nCurRouteIndex = 1

    self.nForceID = nForceID
    self.moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)

    local tbRouteParam = self.moduleRole.GetCreateRoleParam(self.nForceID)

    local function GetRouteName(nIndex)
        local szRouteName = tbRouteParam["szRouteMobile" .. nIndex .. "Name"]
        szRouteName = UIHelper.GBKToUTF8(szRouteName)
        return szRouteName or ""
    end

    local function GetRouteValue(nIndex)
        local szRouteValue = tbRouteParam["szRoute" .. nIndex .. "Value"]
        szRouteValue = UIHelper.GBKToUTF8(szRouteValue)
        return szRouteValue or ""
    end

    local function GetTypeName(nIndex)
        local szTypeName = tbRouteParam["szKungfuTypeName" .. nIndex]
        szTypeName = UIHelper.GBKToUTF8(szTypeName)
        return szTypeName or ""
    end

    local szRouteName1 = GetRouteName(1)
    local szRouteName2 = GetRouteName(2)
    self.szWeaponName = UIHelper.GBKToUTF8(tbRouteParam.szWeaponName)
    self.tbRouteName = {}
    self.tbRouteValue = {}
    self.tbTypeName = {}
    self.nRouteName = 0

    if szRouteName1 ~= "" then
        table.insert(self.tbRouteName, szRouteName1)
        table.insert(self.tbRouteValue, GetRouteValue(self.nRouteName + 1))
        table.insert(self.tbTypeName, GetTypeName(1))
        self.nRouteName = self.nRouteName + 1
    end

    if szRouteName2 then
        table.insert(self.tbRouteName, szRouteName2)
        table.insert(self.tbRouteValue, GetRouteValue(self.nRouteName + 1))
        table.insert(self.tbTypeName, GetTypeName(2))
        self.nRouteName = self.nRouteName + 1
    end
end

function UILoginCreateRoleIntroduce:UpdateInfo()
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelSchoolSelect)
    UIHelper.PlayAni(scriptView, self.AniSchool, "AniSchoolShow", function() 
    end)
    self:UpdateName()
    self:UpdateIntroduce()
    -- self:UpdateAttribute()
end

function UILoginCreateRoleIntroduce:UpdateName()
    local szImgName = PlayerKungfuID2SchoolImgName[self.nForceID]
    local szImgSchool = PlayerKungfuID2SchoolImg_2[self.nForceID]
    local szImgPoem = PlayerKungfuID2SchoolImgPoem[self.nForceID]
    -- UIHelper.SetSpriteFrame(self.ImgSchoolName, szImgName)
    UIHelper.SetSpriteFrame(self.ImgSchoolBg, szImgSchool)
    UIHelper.SetSpriteFrame(self.ImgSchoolPoem, szImgPoem)
end

function UILoginCreateRoleIntroduce:UpdateIntroduce()
    local szContent1, szContent2 = self.moduleRole.GetSchoolSpecialty(self.nForceID)

    local szContent = ""
    
    if #self.tbTypeName == 1 then
        szContent = "<color=#D7F6FF>单心法：</c>" .. string.format("<img src='%s' width='68' height='24' />", NAME_TO_IMAGE[self.tbTypeName[1]])
    else
        szContent = "<color=#D7F6FF>双心法：</c>" .. string.format("<img src='%s' width='68' height='24' />", NAME_TO_IMAGE[self.tbTypeName[1]])
        .."<img src='0' width='5' height='0' />"..string.format("<img src='%s' width='68' height='24' />",NAME_TO_IMAGE[self.tbTypeName[2]])
    end

    local szText =  "<img src='UIAtlas2_Login_NewCharacter_Dot' width='18' height='18' />"
                    .."<img src='0' width='5' height='0' />"
                    ..string.format("<color=#D7F6FF>%s</c>", self.szWeaponName).."\n"
                    .."<img src='UIAtlas2_Login_NewCharacter_Dot' width='18' height='18' />"
                    ..string.format("<color=#D7F6FF> %s</c>", szContent1).."\n"
                    .."<img src='UIAtlas2_Login_NewCharacter_Dot' width='18' height='18' />"
                    ..string.format("<color=#D7F6FF> %s</c>", szContent2).."\n"
                    .."<img src='UIAtlas2_Login_NewCharacter_Dot' width='18' height='18' />"
                    .."<img src='0' width='5' height='0' />"..szContent
    UIHelper.SetRichText(self.RichTextlDes, szText)
    UIHelper.LayoutDoLayout(self.WidgetLabel)

end

function UILoginCreateRoleIntroduce:UpdateAttribute()

    -- local szRouteName = self.tbRouteName[self.nCurRouteIndex]
    -- UIHelper.SetVisible(self.BtnChange, self.nRouteName == 2)
    -- UIHelper.SetVisible(self.ImgChange, self.nRouteName == 2)
    -- UIHelper.SetSpriteFrame(self.ImgTypeIcon, NAME_TO_IMAGE[self.tbTypeName[self.nCurRouteIndex]])

    -- local bVisible = szRouteName and szRouteName ~= ""
    -- if bVisible then
        -- UIHelper.SetString(self.LabelIntroduce3, szRouteName)

        local tValue = string.split(self.tbRouteValue[self.nCurRouteIndex], ";")
        for i = 1, #tValue do
            local value = tonumber(tValue[i])
            -- local nStarNum = value / 10
            local scriptView = UIHelper.GetBindScript(self.tbAttribute[i])
            if scriptView then
                scriptView:OnEnter(value)
            end
            UIHelper.SetVisible(self.tbAttribute[i], true)
        end

        for i = #tValue + 1, 6 do
            UIHelper.SetVisible(self.tbAttribute[i], false)
        end
    -- end
    -- UIHelper.SetVisible(self.LabelIntroduce3, bVisible)
    -- UIHelper.SetVisible(self.WidgetAttribute, bVisible)
    -- UIHelper.LayoutDoLayout(self.LayoutXinFa)

end

function UILoginCreateRoleIntroduce:UpadteXinFaName()
    local szRouteName = self.tbRouteName[self.nCurRouteIndex]
    UIHelper.SetString(self.LabelIntroduce3, szRouteName)
    UIHelper.SetSpriteFrame(self.ImgTypeIcon, NAME_TO_IMAGE[self.tbTypeName[self.nCurRouteIndex]])

    UIHelper.SetVisible(self.BtnChange, self.nRouteName == 2)
    UIHelper.SetVisible(self.ImgChange, self.nRouteName == 2)

    UIHelper.LayoutDoLayout(self.LayoutXinFa)
end

return UILoginCreateRoleIntroduce