/**
 * Toggleable Claude-style output prompts for Pi/OMP.
 *
 * Copy to one of:
 *   ~/.pi/agent/extensions/claude-output-styles.ts
 *   ~/.omp/agent/extensions/claude-output-styles.ts
 *
 * Required companion files under the same agent dir:
 *   output-styles/explanatory.md
 *   output-styles/learning.md
 *   output-style.json  // { "style": "off" | "explanatory" | "learning" }
 *
 * Import package:
 *   Pi:  import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
 *   OMP: import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
 */
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

type OutputStyle = "off" | "explanatory" | "learning";

// Change to ".pi/agent" for Pi.
const AGENT_DIR = path.join(os.homedir(), ".omp/agent");
const STATE_PATH = path.join(AGENT_DIR, "output-style.json");
const PROMPT_DIR = path.join(AGENT_DIR, "output-styles");
const VALID_STYLES = new Set<OutputStyle>(["off", "explanatory", "learning"]);

function normalizeStyle(raw: string | undefined): OutputStyle | undefined | null {
	const value = (raw ?? "").trim().toLowerCase();
	if (!value) return undefined;
	if (["off", "none", "default", "normal", "disable", "disabled"].includes(value)) return "off";
	if (["explain", "explanatory"].includes(value)) return "explanatory";
	if (["learn", "learning"].includes(value)) return "learning";
	return null;
}

function readStyle(): OutputStyle {
	try {
		const data = JSON.parse(fs.readFileSync(STATE_PATH, "utf8")) as { style?: unknown };
		return typeof data.style === "string" && VALID_STYLES.has(data.style as OutputStyle)
			? (data.style as OutputStyle)
			: "off";
	} catch {
		return "off";
	}
}

function writeStyle(style: OutputStyle): void {
	fs.mkdirSync(path.dirname(STATE_PATH), { recursive: true });
	fs.writeFileSync(STATE_PATH, `${JSON.stringify({ style }, null, 2)}\n`, "utf8");
}

function loadStylePrompt(style: OutputStyle): string | undefined {
	if (style === "off") return undefined;
	try {
		const prompt = fs.readFileSync(path.join(PROMPT_DIR, `${style}.md`), "utf8").trim();
		return prompt ? prompt : undefined;
	} catch {
		return undefined;
	}
}

function appendPrompt(systemPrompt: unknown, systemPromptAppend: string): string | string[] {
	if (Array.isArray(systemPrompt)) return [...systemPrompt.map(String), systemPromptAppend];
	const base = typeof systemPrompt === "string" ? systemPrompt : "";
	return base ? `${base}\n\n${systemPromptAppend}` : systemPromptAppend;
}

export default function claudeOutputStyles(pi: ExtensionAPI) {
	let activeStyle: OutputStyle = readStyle();

	async function setOrShowStyle(args: string | undefined, ctx: { ui?: { notify?: (message: string, level?: string) => void } }) {
		const parsed = normalizeStyle(args);
		if (parsed === undefined) {
			ctx.ui?.notify?.(`Claude output style: ${activeStyle}\nUsage: /output-style explanatory | learning | off`, "info");
			return;
		}
		if (parsed === null) {
			ctx.ui?.notify?.(`Unknown output style: ${(args ?? "").trim()}`, "warn");
			return;
		}
		activeStyle = parsed;
		writeStyle(activeStyle);
		ctx.ui?.notify?.(`Claude output style set to: ${activeStyle}`, "info");
	}

	pi.registerCommand("output-style", {
		description: "Set Claude-style output mode: explanatory, learning, or off",
		handler: setOrShowStyle,
	});
	pi.registerCommand("style", { description: "Alias for /output-style", handler: setOrShowStyle });
	pi.registerCommand("explanatory", { description: "Enable Claude Explanatory output style", handler: async (_args, ctx) => setOrShowStyle("explanatory", ctx) });
	pi.registerCommand("learning", { description: "Enable Claude Learning output style", handler: async (_args, ctx) => setOrShowStyle("learning", ctx) });
	pi.registerCommand("style-off", { description: "Disable Claude output style injection", handler: async (_args, ctx) => setOrShowStyle("off", ctx) });

	pi.on("before_agent_start", async (event) => {
		activeStyle = readStyle();
		const systemPromptAppend = loadStylePrompt(activeStyle);
		if (!systemPromptAppend) return undefined;
		return {
			// Kept for newer/older APIs that accept a literal append field.
			systemPromptAppend,
			// Current Pi/OMP versions use additive replacement of the built prompt.
			systemPrompt: appendPrompt((event as { systemPrompt?: unknown }).systemPrompt, systemPromptAppend),
		};
	});
}
