var hasPatreonStatus = true;
var isPatron = false;
var patreonLevel = 0;
var patreonPerks = [];
var offPatreonButton = true;
var offVOIconButton = true;
var giftNotificationRemainingTime = 0;
var giftNotificationScheduler = false;
var paymentTargetID = Game.GetLocalPlayerID();
var lastConfirmedDonationTarget = Game.GetLocalPlayerID();
var donation_target_dropdown = false;

GameEvents.SubscribeProtected("is_local_server", function () {
	$("#LocalServerWarningContainer").style.visibility = "visible";
	$("#LocalServerWarningContainer").style.opacity = "1.0";
});

function CloseLocalServerWarning() {
	$("#LocalServerWarningContainer").style.visibility = "collapse";
}

var shouldHideNewMethodsAnnouncement = false;
function hideNewMethodsAnnouncement() {
	shouldHideNewMethodsAnnouncement = true;
	updatePatreonButton();
}

function updatePatreonButton() {
	var minimizePatreonButton = true;
	$("#PatreonButtonPanel").visible = hasPatreonStatus;
	$("#PatreonButton").visible = !minimizePatreonButton;
	if (offPatreonButton) {
		$("#PatreonButtonSmallerImage").visible = minimizePatreonButton;
	}
	// Show icon only when chat wheel is loaded as it's not a common module yet
	if (offVOIconButton) {
		$("#VOIcon").visible =
			Boolean(GameUI.CustomUIConfig().chatWheelLoaded) && Game.GetDOTATime(false, false) <= 120;
	}
	if (Game.GetDOTATime(false, false) > 120) {
		$("#CloseVOIconButton").visible = false;
	}
	$("#NewMethodsAnnouncement").visible =
		!shouldHideNewMethodsAnnouncement &&
		!isPatron &&
		$.Language() !== "russian" &&
		Game.GetDOTATime(false, false) <= 120;
}

function OpenShop() {
	GameEvents.SendEventClientSideProtected("battlepass_inventory:open_specific_collection", {
		category: "Treasures",
		boostGlow: true,
	});
}

function SetPatreonLevel(level) {
	patreonLevel = level;
}

function ClosePatreonButton() {
	$("#PatreonButtonSmallerImage").visible = false;
	$("#ClosePatreonButton").visible = false;
	offPatreonButton = false;
	$("#CloseVOIconButton").style.marginRight = "0px";
}

function ShowClosePatreonButton() {
	$("#ClosePatreonButton").visible = true;
}

function HideClosePatreonButton() {
	$("#ClosePatreonButton").visible = false;
}

function ShowVOIconButton() {
	var panel = $("#VOIcon");
	$.DispatchEvent("DOTAShowTextTooltip", panel, $.Localize("#votooltip"));
	$("#CloseVOIconButton").visible = true;
}

function HideVOIconButton() {
	var panel = $("#VOIcon");
	$.DispatchEvent("DOTAHideTextTooltip", panel);
	$("#CloseVOIconButton").visible = false;
}

function CloseVOIconButton() {
	$("#VOIcon").visible = false;
	$("#CloseVOIconButton").visible = false;
	offVOIconButton = false;
}

SetPatreonLevel(0);

SubscribeToNetTableKey("game_state", "patreon_bonuses", function (data) {
	var status = data[Game.GetLocalPlayerID()];
	if (!status) return;

	hasPatreonStatus = true;
	isPatron = status.level > 0;
	$.GetContextPanel().SetHasClass("IsPatron", isPatron);
	updatePatreonButton();

	SetPatreonLevel(status.level);
});

setInterval(updatePatreonButton, 1000);
