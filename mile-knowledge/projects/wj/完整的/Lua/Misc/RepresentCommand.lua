RepresentFunction = RepresentFunction or {className = "RepresentFunction"}

-- 转发表现发来的的事件


local function OnGeneralRepresentCall()
	local szFunName = arg0
	OnRepresentCall(szFunName)
end

function OnRepresentCall(szFunName)
	if RepresentFunction[szFunName] then
		RepresentFunction[szFunName]()
    else
        LOG.ERROR(string.format("OnRepresentCall.%s not exist.", szFunName))
	end
end

function RepresentFunction.CreateProgressBar()
    GeneralProgressBarData.AddProgressBar(arg1, arg2, arg3, arg4, arg5, arg6, arg7)
end

function RepresentFunction.CloseProgressBar()
	GeneralProgressBarData.DeleteProgressBar(arg1)
end

Event.Reg(RepresentFunction, "REPRESENT_CALL", function()
    OnGeneralRepresentCall()
end)