local UIGMBallView = class("UIGMBallView")

function UIGMBallView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIGMBallView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGMBallView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGm, EventType.OnClick, function(btn)
        GMHelper.OpenGM()
    end)

    if IsKGPublish() then
        UIHelper.BindUIEvent(self.BtnGm, EventType.OnLongPress, function(_, x, y)
            LOG.INFO("[GMHelper]长按GM球")
            if GMHelper.GmDevLogin then
                TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnGm, TipsLayoutDir.BOTTOM_RIGHT, GMHelper.GmDevLogin)
            else
                GMHelper.ShowNormalTip("GMHelper.ParseConfigHttp解析出错")
            end
        end)
    end
end

function UIGMBallView:RegEvent()
    -- 以下两个按钮考虑迁移, 保持干净的对外逻辑
    Event.Reg(self, "ClearCDGMButton", function()
        local bState = UIHelper.GetVisible(self.BtnClearCD)
        UIHelper.SetVisible(self.BtnClearCD, not bState)
        UIHelper.BindUIEvent(self.BtnClearCD, EventType.OnClick, function()
            local szCMD = "if player.GetSkillLevel(613) == 0 then player.LearnSkill(613) else player.CastSkill(613,1) end"
            SendGMCommand(UIHelper.UTF8ToGBK(szCMD))
        end)
    end)

    Event.Reg(self, "KillTargetGMButton", function()
        local bState = UIHelper.GetVisible(self.BtnKillTarget)
        UIHelper.SetVisible(self.BtnKillTarget, not bState)
        UIHelper.BindUIEvent(self.BtnKillTarget, EventType.OnClick, function()
            local szCMD = "player.GetSelectCharacter().Die()"
            SendGMCommand(UIHelper.UTF8ToGBK(szCMD))
        end)
    end)

    if IsKGPublish() then
        Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
            if szKey == GMHelper.GmDevLogin.Key then
                local nFileOperate = tbSelected[GMHelper.UIConfig.FileOperation][1]
                if nFileOperate ~= GMHelper.FILE_OPERAtE.default then
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetFiltrateTip)
                    if nFileOperate == GMHelper.FILE_OPERAtE.view then
                        GMHelper.ViewConfigHttp()
                        return
                    elseif nFileOperate == GMHelper.FILE_OPERAtE.delete then
                        GMHelper.DeleteConfigHttp()
                    elseif nFileOperate == GMHelper.FILE_OPERAtE.backup then
                        GMHelper.BackupConfigHttp()
                    elseif nFileOperate == GMHelper.FILE_OPERAtE.restore then
                        GMHelper.ReStoreConfigHttp()
                    end
                    TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnGm, TipsLayoutDir.BOTTOM_RIGHT, GMHelper.GmDevLogin)
                    return
                end

                local nCustomFields = tbSelected[GMHelper.UIConfig.Etag][1]
                if nCustomFields ~= GMHelper.CUSTOM_FIELDS.default then
                    GMHelper.GmDevLogin[GMHelper.UIConfig.GmDevLogin].tbDefault = {1}
                    if nCustomFields == GMHelper.CUSTOM_FIELDS.update then
                        local szCustomFields
                        local fnCallBack = function(szText)
                            szCustomFields = szText
                            GMHelper.UpdateEtagSelf(szText)
                            GMHelper.GmDevLogin[GMHelper.UIConfig.Etag].tbList = {szCustomFields, "修改", "删除"}
                            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnGm, TipsLayoutDir.BOTTOM_RIGHT, GMHelper.GmDevLogin)
                        end
                        UIMgr.Open(VIEW_ID.PanelModifyNamePop, '输入自驾etag的ip', "" , fnCallBack)
                        return
                    elseif nCustomFields == GMHelper.CUSTOM_FIELDS.delete then
                        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetFiltrateTip)
                        GMHelper.DeleteDownloader1()
                        GMHelper.GmDevLogin[GMHelper.UIConfig.Etag].tbList = {'127.0.0.1', "修改", "删除"}
                        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnGm, TipsLayoutDir.BOTTOM_RIGHT, GMHelper.GmDevLogin)
                        return
                    end
                end

                local nGmDevOption = tbSelected[GMHelper.UIConfig.GmDevLogin][1]
                if GMHelper.nLastGmDevOpion ~= nGmDevOption then
                    GMHelper.GmDevLogin[GMHelper.UIConfig.Etag].tbList = {'127.0.0.1', "修改", "删除"}
                    if nGmDevOption == GMHelper.OPTION_FILTER_TYPE.default then
                        if GMHelper.DeleteDownloader1() then
                            GMHelper.nLastGmDevOpion = nGmDevOption
                            GMHelper.GmDevLogin[1].tbDefault = {1}
                        end
                    else
                        local szOption = GMHelper.OPTION_FILTER_TYPE[nGmDevOption]
                        if GMHelper.UpdateDownloaderKey(szOption) then
                            GMHelper.nLastGmDevOpion = nGmDevOption
                            GMHelper.GmDevLogin[GMHelper.UIConfig.GmDevLogin].tbDefault = {tonumber(nGmDevOption)}
                        end
                    end
                end

                local nUrlType = tbSelected[GMHelper.UIConfig.CDN][1]
                if GMHelper.nLastUrlType ~= nUrlType then
                    local bUpdateSuccess = GMHelper.UpdateCdnUrl(nUrlType==GMHelper.URL_FILTER_TYPE.extranet)
                    if bUpdateSuccess then
                        GMHelper.nLastUrlType = nUrlType
                        GMHelper.GmDevLogin[GMHelper.UIConfig.CDN].tbDefault = {tonumber(nUrlType)}
                    end
                end
                GMHelper.ShowNormalTip("confighttp.ini 修改完成, 请重启游戏")
            end
        end)
    end
end

function UIGMBallView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGMBallView:UpdateInfo()

end


return UIGMBallView