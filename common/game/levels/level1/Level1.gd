extends "res://common/game/levels/LevelInfo.gd"

func _ready():
	colorDic[0] = createTeamColor("red", "981D1D")
	colorDic[1] = createTeamColor("green", "40883C")
	colorDic[2] = createTeamColor("blue", "3F28A7")
	colorDic[3] = createTeamColor("orange", "B75923")

	teamColors = [Color("981D1D"), Color("40883C"), Color("3F28A7"), Color("B75923")]
	playersPerTeam = 1
	teamsInLevel = 4
