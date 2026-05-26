-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExaminationView
-- Date: 2023-03-13 10:14:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIExaminationView = class("UIExaminationView")

local EXAM_TYPE = {
	SIMPLE_SELECTION = 1,
	MULTIPLE_SELECTION = 2,
	GAP_FILLING = 3,
	IMAGE_SELECTION = 4,
}
local EXAM_TYPE_STR = {
	"单选题：",
	"多选题：",
}

function UIExaminationView:OnEnter(szQuestionList, nPromoteTime, nTestType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nQuestionIndex = 0
    self.szQuestionList = szQuestionList or ""
    self.nPromoteTime = nPromoteTime
    self.nTestType = nTestType
    self:InitQuestionList()
    self:UpdateInfo()
end

function UIExaminationView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExaminationView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose,EventType.OnClick,function ()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnPrev,EventType.OnClick,function ()
        if self.nQuestionIndex <= 1 then
            return
        end
        Event.Dispatch(EventType.OnSelectQuestion,self.nQuestionIndex - 1)
    end)
    UIHelper.BindUIEvent(self.BtnNext,EventType.OnClick,function ()
        if self.nQuestionIndex >= #self.szQuestionList then
            return
        end
        Event.Dispatch(EventType.OnSelectQuestion,self.nQuestionIndex + 1)
    end)
    UIHelper.BindUIEvent(self.BtnOver,EventType.OnClick,function ()
        UIHelper.ShowConfirm(g_tStrings.STR_EXAM_SUBMIT,function ()
            RemoteCallToServer("On_Exam_FinishExam")
            self.bFinishExam = true
        end)
    end)
    UIHelper.BindUIEvent(self.BtnCopy,EventType.OnClick,function ()
        local utfText = UIHelper.GBKToUTF8(self.tExamContentList[self.nQuestionIndex].szContent)
        for k,v in ipairs(EXAM_TYPE_STR) do
            utfText = string.gsub(utfText,v, "")
        end

        SetClipboard( UIHelper.UTF8ToGBK(utfText))

        TipsHelper.ShowNormalTip(g_tStrings.STR_COPY_SUCESS)
    end)
end

function UIExaminationView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self,EventType.OnSelectQuestion,function (nQuestionIndex)
        if self.nQuestionIndex == nQuestionIndex then return end
        self.nQuestionIndex = nQuestionIndex
        for k,v in ipairs(self.tbTogQuestionNum) do
            UIHelper.SetSelected(v,k == self.nQuestionIndex)
            UIHelper.SetVisible(self.tbTogSelQuestionText[k], self.nQuestionIndex == k)
        end
        if self.nQuestionIndex < 3 then
            UIHelper.ScrollToTop(self.ScrollviewQuestion,0)
        else
            UIHelper.ScrollToIndex(self.ScrollviewQuestion,self.nQuestionIndex - 2,0)
        end
        self:UpdateLabelText()
        self:RequestQuestionContent()
    end)
    Event.Reg(self,EventType.OnSelectAnswer,function (nAnswerID,bSelected)
        self:UpdateSelectAnswer(nAnswerID,bSelected)
    end)
    Event.Reg(self,"SynExamContent",function (nQuestionIndex,tExamContents)
        self.tExamContentList[nQuestionIndex] = tExamContents
        self:RequestQuestionContent()
    end)
    Event.Reg(self,"SendExamAnswer",function ()
        RemoteCallToServer("OnReceiveExamAnswer", self:CloneAnswerTable())
        UIMgr.Close(self)
    end)
    Event.Reg(self,"OnCloseExamPanel",function ()
        if not self.bFinishExam then
            UIMgr.Close(self)
        end
    end)
end

function UIExaminationView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExaminationView:UpdateInfo()

end

function UIExaminationView:InitQuestionList()
    self:UpdateTitle()
    self.tExamContentList = {}
    self.tbTogQuestionNum = {}
    self.tbTogSelQuestionText = {}
    self.tbTogNormalQuestion = {}
    self.tbTogFinishQuestion = {}
    self.tbTogFinishQuestionText = {}

    for i = 1, #self.szQuestionList do
        local nType = tonumber(self.szQuestionList:sub(i, i))
		self.tExamContentList[i] = {}
		self.tExamContentList[i].nType = nType
		self.tExamContentList[i].bFinished = false
        --UIHelper.SetVisible(self.tbTogQuestionNum[i],true)
        local nodescript = UIHelper.AddPrefab(PREFAB_ID.WidgetExaminationQuestion,self.ScrollviewQuestion,i)
        table.insert(self.tbTogQuestionNum,nodescript.TogQuestion)
        table.insert(self.tbTogSelQuestionText,nodescript.LabelQuestionSelect)
        table.insert(self.tbTogNormalQuestion,nodescript.ImgNormalQuestion)
        table.insert(self.tbTogFinishQuestion,nodescript.ImgFinishQuestionBg)
        table.insert(self.tbTogFinishQuestionText,nodescript.LabelQuestionFinish)
    end
    self:RequestQuestionContent()
    UIHelper.ScrollViewDoLayout(self.ScrollviewQuestion)
    UIHelper.ScrollToTop(self.ScrollviewQuestion,0)
end

function UIExaminationView:UpdateTitle(bIsRequesting)
    UIHelper.SetString(self.LabelExaminationSession,"第"..self:ConversionNumber(self.nPromoteTime).."期")
    UIHelper.SetString(self.LabelExamination,g_tStrings.EXAM_TITLES.TYPE[self.nTestType])
end

function UIExaminationView:ConversionNumber(nPromoteTime)
    local szNum = tostring(nPromoteTime)
    local tCharNum = g_tStrings.DIGTABLE.tCharNum
	local tCharDiL = g_tStrings.DIGTABLE.tCharDiL
    if nPromoteTime == 0 then
        return tCharNum[nPromoteTime]
    end
    local szTitle = ""
    for i = 1,#szNum,1 do
        local nNum = tonumber(string.sub(szNum, i, i))
        szTitle = szTitle..tCharNum[nNum]..tCharDiL[#szNum-i+1]
    end
    return szTitle
end

function UIExaminationView:UpdateExamContent()
    local szNum = "("..self.nQuestionIndex.."/"..#self.tExamContentList..") "
    local utfText = UIHelper.GBKToUTF8(self.tExamContentList[self.nQuestionIndex].szContent)
    for k,v in ipairs(EXAM_TYPE_STR) do
        utfText = string.gsub(utfText,v, "")
    end
    UIHelper.SetString(self.LabelQuestionNum, szNum..g_tStrings.STR_DRAMA_QA_TYPE[self.tExamContentList[self.nQuestionIndex].nType])
    UIHelper.SetString(self.LabelQuestionInfo, utfText) -- 题目内容

    if not self.tExamContentList[self.nQuestionIndex].tSelectionAnswer then
        self.tExamContentList[self.nQuestionIndex].tSelectionAnswer = {false, false, false, false}
    end
    UIHelper.RemoveAllChildren(self.LayoutOption)
    local nType = self.tExamContentList[self.nQuestionIndex].nType
    if nType == EXAM_TYPE.SIMPLE_SELECTION or nType == EXAM_TYPE.MULTIPLE_SELECTION then
        for k,v in ipairs(self.tExamContentList[self.nQuestionIndex].tSelections) do
            UIHelper.AddPrefab(PREFAB_ID.WidgetExaminationOptionItem,self.LayoutOption,nType,k,UIHelper.GBKToUTF8(v),self.tExamContentList[self.nQuestionIndex].tSelectionAnswer[k])
        end
        UIHelper.LayoutDoLayout(self.LayoutOption)
    end
end

function UIExaminationView:FillContent(szContents)
    szContents = szContents or ""
    return szContents
end

function UIExaminationView:UpdateSelectAnswer(nAnswerID,bSelected)
    local nType = self.tExamContentList[self.nQuestionIndex].nType
    UIHelper.SetVisible(self.tbTogFinishQuestion[self.nQuestionIndex],true)
    UIHelper.SetVisible(self.tbTogNormalQuestion[self.nQuestionIndex],false)
    UIHelper.SetVisible(self.tbTogFinishQuestionText[self.nQuestionIndex],true)

    if nType == EXAM_TYPE.SIMPLE_SELECTION then
        for k,_ in ipairs(self.tExamContentList[self.nQuestionIndex].tSelectionAnswer) do
            if k == nAnswerID then
                self.tExamContentList[self.nQuestionIndex].tSelectionAnswer[k] = true
            else
                self.tExamContentList[self.nQuestionIndex].tSelectionAnswer[k] = false
            end
        end
    elseif nType == EXAM_TYPE.MULTIPLE_SELECTION then
        self.tExamContentList[self.nQuestionIndex].tSelectionAnswer[nAnswerID] = bSelected
    end
end

function UIExaminationView:RequestQuestionContent()
    if self.nQuestionIndex < 1 then
		return
	end
    if self.tExamContentList[self.nQuestionIndex].szContent then
		self:UpdateExamContent()
	else
		RemoteCallToServer("OnExamContentRequest", self.nQuestionIndex)
	end
    self:UpdateExamIconsList()
end

function UIExaminationView:UpdateExamIconsList()
    if not self.tExamContentList or #self.tExamContentList == 0 then return end
    for i = 1,10,1 do
        local bSkip = true
        if self.tExamContentList[i].tSelectionAnswer then
            for k,v in ipairs(self.tExamContentList[i].tSelectionAnswer) do
                if v == true then
                    bSkip = false
                end
            end
        end
        UIHelper.SetVisible(self.tbTogFinishQuestion[i],not bSkip)
        UIHelper.SetVisible(self.tbTogNormalQuestion[i], bSkip)
    end
end

function UIExaminationView:UpdateLabelText()
    UIHelper.SetVisible(self.BtnOver,self.nQuestionIndex == #self.szQuestionList)
    UIHelper.SetVisible(self.BtnNext,self.nQuestionIndex ~= #self.szQuestionList)
end

function UIExaminationView:CloneAnswerTable()
    local tClone = {}
	for i = 1, #self.tExamContentList do
		tClone[i] = {}
		if self.tExamContentList[i] and self.tExamContentList[i].tSelectionAnswer then
			tClone[i].tSelectionAnswer = {}
			for j = 1, 4 do
				tClone[i].tSelectionAnswer[j] = self.tExamContentList[i].tSelectionAnswer[j]
			end
		end
		-- if self.tExamContentList[i] and self.tExamContentList[i].szFillAnswer then
		-- 	tClone[i].dwFillAnswerHash = GetFileNameHash(self.tExamContentList[i].szFillAnswer)
		-- end
	end
	return tClone
end

return UIExaminationView