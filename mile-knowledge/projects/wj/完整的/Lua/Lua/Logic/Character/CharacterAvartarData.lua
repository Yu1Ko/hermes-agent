CharacterAvartarData = CharacterAvartarData or {className = "CharacterAvartarData"}

CharacterAvartarData.TITLE = 
{
    COLLECTION = 0,
	NORMAL = 1,
    DESIGNATIONDECORATION = 2,
}

local InitTitleType = CharacterAvartarData.TITLE.NORMAL


function CharacterAvartarData.SetInitTitle(title)
    InitTitleType = title
end

function CharacterAvartarData.GetInitTitle()
    return InitTitleType
end