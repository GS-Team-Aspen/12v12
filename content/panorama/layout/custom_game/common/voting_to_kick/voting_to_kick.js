let bVotingIsNow = false;
const report_button = $("#ReportButton");

function VotingToKickShowVoting(data) {
	$.Msg("SHOW VOTING");
	$("#HideVotingWrap").SetHasClass("show", true);
	let votingPanel = $("#VotingToKickVoting");
	let timerVoting = $.CreatePanel("Panel", votingPanel, "VotingToKickCountdown");
	timerVoting.AddClass("Active");
	votingPanel.AddClass("Slide");
	let targetPlayer = Game.GetPlayerInfo(data.playerId);

	votingPanel.SetHasClass("Hide", false);
	$("#HideVotingWrap").SetHasClass("Reverse", false);

	$("#VotingToKickVotingReasonText").text =
		$.Localize("#voting_to_kick_reason_tooltip") + ": " + $.Localize("#voting_to_kick_reason_" + data.reason);

	let votingPanelHideText = $("#VotingToKickVotingHeadText");
	votingPanelHideText.html = true;
	votingPanelHideText.text =
		$.Localize("#voting_to_kick_tooltip") +
		" " +
		"<font color='#ed1313'>" +
		targetPlayer.player_name +
		"</font>" +
		" ?";

	$.CreatePanelWithProperties(`DOTAScenePanel`, $("#VotingToKickModelPanel"), "VotingToKickVotingHeroModel", {
		style: `width:210px;height:210px;`,
		unit: `${targetPlayer.player_selected_hero}`,
		particleonly: `false`,
	});

	$("#VotingToKickKDA").html = true;
	$("#VotingToKickKDA").text =
		$.Localize("#voting_to_kick_kda_tooltip") +
		"\u00A0".repeat(8) +
		Players.GetKills(data.playerId) +
		" / " +
		Players.GetDeaths(data.playerId) +
		" / " +
		Players.GetAssists(data.playerId);

	const not_local_player = Game.GetLocalPlayerID() != data.playerIdInit;

	$("#VotingToKickVotingYes").visible = not_local_player;
	$("#VotingToKickVotingNo").visible = not_local_player;
	report_button.visible = not_local_player;

	if (data.playerVoted != null) {
		$("#VotingToKickVotingYes").visible = false;
		$("#VotingToKickVotingNo").visible = false;
	}
}
// VotingToKickShowVoting({
// 	playerIdInit: 1,
// 	playerId: 0,
// 	reason: "afk",
// });

function ToggleVotingPanel() {
	$("#VotingToKickVoting").ToggleClass("Hide");
	const hideButton = $("#HideVotingWrap");
	hideButton.ToggleClass("Reverse");

	hideButton.SetPanelEvent("onmouseover", function () {
		$.DispatchEvent(
			"DOTAShowTextTooltip",
			hideButton,
			$.Localize(hideButton.BHasClass("Reverse") ? "show_voting" : "hide_voting"),
		);
	});
	hideButton.SetPanelEvent("onmouseout", function () {
		$.DispatchEvent("DOTAHideTextTooltip");
	});
}
function VotingToKickHideVoting() {
	$.Msg("HIDE VOTING");
	$("#HideVotingWrap").SetHasClass("show", false);
	$("#VotingToKickVotingYes").visible = false;
	$("#VotingToKickVotingNo").visible = false;
	$("#VotingToKickCountdown").DeleteAsync(0);

	let votingPanel = $("#VotingToKickVoting");
	votingPanel.RemoveClass("Slide");
}

function VotingToKickVoteYes(data) {
	$.Msg("YES VOTING");
	GameEvents.SendCustomGameEventToServer("voting_to_kick_vote_yes", {});
	$("#VotingToKickVotingYes").visible = false;
	$("#VotingToKickVotingNo").visible = false;
}

function VotingToKickVoteNo(data) {
	$.Msg("NO VOTING");
	GameEvents.SendCustomGameEventToServer("voting_to_kick_vote_no", {});
	$("#VotingToKickVotingYes").visible = false;
	$("#VotingToKickVotingNo").visible = false;
}

function VotingToKickHideReason() {
	$.Msg("HIDE REASON");
	let reasonPanel = $("#VotingToKickReasonPanel");
	reasonPanel.RemoveClass("Slide");
}
function VotingToKickShowReason(data) {
	$.Msg("SHOW REASON");
	let reasonPanel = $("#VotingToKickReasonPanel");
	reasonPanel.AddClass("Slide");

	let reasonPanelHideText = $("#VotingToKickReasonHeadPanelText");
	reasonPanelHideText.html = true;
	let targetPlayer = Game.GetPlayerInfo(data.target_id);
	reasonPanelHideText.text =
		$.Localize("#voting_to_kick_choose_reason_tooltip") +
		" " +
		"<font color='#23d923'>" +
		targetPlayer.player_name +
		"</font>";
}
function VotingToKickInitVoting(reason) {
	$.Msg("PICK REASON");
	GameEvents.SendCustomGameEventToServer("voting_to_kick_reason_is_picked", { reason: reason });
}
function VotingToKickDebugPrint(data) {
	let playerVoted = Game.GetPlayerInfo(data.playerVotedId);
	$.Msg(playerVoted.player_name + " VOTE: " + data.vote + "NEED TOTAL: " + data.total);
}
function ReportVoting() {
	report_button.visible = false;
	GameEvents.SendCustomGameEventToServer("voting_to_kick_report", {});
}
function VotingToKickInit() {
	GameEvents.SendCustomGameEventToServer("voting_to_kick_check_voting_state", {});
	GameEvents.SubscribeProtected("voting_to_kick_show_reason", VotingToKickShowReason);
	GameEvents.SubscribeProtected("voting_to_kick_hide_reason", VotingToKickHideReason);

	GameEvents.SubscribeProtected("voting_to_kick_show_voting", VotingToKickShowVoting);
	GameEvents.SubscribeProtected("voting_to_kick_hide_voting", VotingToKickHideVoting);

	GameEvents.SubscribeProtected("voting_to_kick_debug_print", VotingToKickDebugPrint);
}
VotingToKickInit();
