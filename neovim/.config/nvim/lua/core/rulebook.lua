return {
	"chrisgrieser/nvim-rulebook",
	keys = {
		{ "<leader>li", function() require("rulebook").ignoreRule() end, desc = "ignore rule" },
		{ "<leader>lL", function() require("rulebook").lookupRule() end, desc = "lookup rule docs" },
		{ "<leader>lf", function() require("rulebook").suppressFormatter() end, mode = { "n", "x" }, desc = "suppress formatter" },
	},
	opts = {
		ignoreComments = {
			ty = {
				comment = "# ty: ignore[%s]",
				location = "sameLine",
				multiRuleIgnore = true,
				multiRuleSeparator = ", ",
			},
		},
	},
}
