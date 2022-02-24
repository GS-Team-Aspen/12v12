function WeakTeamNotification(data) {
	const panel = $.CreatePanel("Panel", $("#Norifications_TOP"), "");
	panel.BLoadLayoutSnippet("WeakTeamBonus");
	panel.FindChild("WeakHeader").SetDialogVariable("mmr_diff", data.mmrDiff);
	panel.FindChildTraverse("WeakBonusExpText").SetDialogVariable("exp_pct", data.expPct);
	panel.FindChildTraverse("WeakBonusGoldText").SetDialogVariable("gold_pct", data.goldPct);
	panel.SetHasClass("show", true);
	const closeEvent = function (panel) {
		panel.FindChildTraverse("WeakClose").SetPanelEvent("onactivate", () => {
			panel.SetHasClass("show", false);
		});
	};
	closeEvent(panel);
}
GameEvents.SubscribeProtected("WeakTeamNotification", WeakTeamNotification);
