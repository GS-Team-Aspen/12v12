let GIT_BUTTON;
const GIT_OPTIONS = $("#GitOptions");
function ShowGitOptions() {
	GIT_OPTIONS.SetHasClass("Show", true);
}
function HideGitOptions(delay) {
	$.Schedule(delay, () => {
		GIT_OPTIONS.SetHasClass(
			"Show",
			!GIT_BUTTON || GIT_BUTTON.BHasHoverStyle() || GIT_OPTIONS.BHasHoverStyle() || false,
		);
	});
}

(function () {
	if (FindDotaHudElement("CollectionTopButton") == undefined) {
		const collectionButton = _AddMenuButton("CollectionTopButton");
		CreateButtonInTopMenu(
			collectionButton,
			() => {
				boostGlow = false;
				ToggleMenu("CollectionDotaU");
			},
			() => {
				$.DispatchEvent("DOTAShowTextTooltip", collectionButton, "#TopMenuIcon_Collection_message");
			},
			() => {
				$.DispatchEvent("DOTAHideTextTooltip");
			},
		);
	}

	if (FindDotaHudElement("FeedbackButton") == undefined) {
		const feedbackButton = _AddMenuButton("FeedbackButton");
		CreateButtonInTopMenu(
			feedbackButton,
			() => {
				const feedbackMenu = FindDotaHudElement("FeedbackHeaderRoot").GetParent();
				feedbackMenu.ToggleClass("show");
			},
			() => {
				$.DispatchEvent("DOTAShowTextTooltip", feedbackButton, "#feedback_top_menu_hint");
			},
			() => {
				$.DispatchEvent("DOTAHideTextTooltip");
			},
		);
	}
	if (FindDotaHudElement("GitButton") == undefined) {
		GIT_BUTTON = _AddMenuButton("GitButton");
		CreateButtonInTopMenu(
			GIT_BUTTON,
			() => {
				$.DispatchEvent("ExternalBrowserGoToURL", "https://github.com/arcadia-redux/12v12");
			},
			() => {
				ShowGitOptions();
			},
			() => {
				HideGitOptions(0.2);
			},
		);
	}
})();
