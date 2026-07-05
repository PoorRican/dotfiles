/**
 * Claude output-style selector for Pi/OMP.
 *
 * Commands:
 *   /output-style              Show current style
 *   /output-style explanatory  Enable Claude Explanatory style
 *   /output-style learning     Enable Claude Learning style
 *   /output-style off          Disable style injection
 *
 * Aliases:
 *   /style, /explanatory, /learning, /style-off
 *
 * Compatibility note: current Pi/OMP extension APIs receive the current
 * system prompt and expect a replacement. This extension still builds a
 * `systemPromptAppend` value, then appends it to the current prompt shape
 * so behavior matches systemPromptAppend without replacing base prompts.
 */
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

type OutputStyle = "off" | "explanatory" | "learning";

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
	fs.writeFileSync(STATE_PATH, `${JSON.stringify({ style }, null, 2)}
`, "utf8");
}

function stylePromptPath(style: Exclude<OutputStyle, "off">): string {
	return path.join(PROMPT_DIR, `${style}.md`);
}

function loadStylePrompt(style: OutputStyle): string | undefined {
	if (style === "off") return undefined;
	const promptPath = stylePromptPath(style);
	try {
		const prompt = fs.readFileSync(promptPath, "utf8").trim();
		return prompt ? prompt : undefined;
	} catch {
		return undefined;
	}
}

function usage(current: OutputStyle): string {
	return [
		`Claude output style: ${current}`,
		"Usage: /output-style explanatory | learning | off",
		"Alias: /style explanatory | learning | off",
	].join("\n");
}

function appendPrompt(systemPrompt: unknown, systemPromptAppend: string): string | string[] {
	if (Array.isArray(systemPrompt)) {
		return [...systemPrompt.map(String), systemPromptAppend];
	}
	const base = typeof systemPrompt === "string" ? systemPrompt : "";
	return base ? `${base}

${systemPromptAppend}` : systemPromptAppend;
}

export default function claudeOutputStyles(pi: ExtensionAPI) {
	let activeStyle: OutputStyle = readStyle();

	async function setOrShowStyle(args: string | undefined, ctx: { ui?: { notify?: (message: string, level?: string) => void } }) {
		const parsed = normalizeStyle(args);
		if (parsed === undefined) {
			ctx.ui?.notify?.(usage(activeStyle), "info");
			return;
		}
		if (parsed === null) {
			ctx.ui?.notify?.(`Unknown output style: ${(args ?? "").trim()}\n${usage(activeStyle)}`, "warn");
			return;
		}

		activeStyle = parsed;
		writeStyle(activeStyle);

		if (activeStyle !== "off" && !loadStylePrompt(activeStyle)) {
			ctx.ui?.notify?.(
				`Claude output style set to ${activeStyle}, but prompt file is missing: ${stylePromptPath(activeStyle)}`,
				"warn",
			);
			return;
		}

		ctx.ui?.notify?.(`Claude output style set to: ${activeStyle}`, "info");
	}

	pi.registerCommand("output-style", {
		description: "Set Claude-style output mode: explanatory, learning, or off",
		handler: setOrShowStyle,
	});

	pi.registerCommand("style", {
		description: "Alias for /output-style",
		handler: setOrShowStyle,
	});

	pi.registerCommand("explanatory", {
		description: "Enable Claude Explanatory output style",
		handler: async (_args, ctx) => setOrShowStyle("explanatory", ctx),
	});

	pi.registerCommand("learning", {
		description: "Enable Claude Learning output style",
		handler: async (_args, ctx) => setOrShowStyle("learning", ctx),
	});

	pi.registerCommand("style-off", {
		description: "Disable Claude output style injection",
		handler: async (_args, ctx) => setOrShowStyle("off", ctx),
	});

	pi.on("before_agent_start", async (event) => {
		activeStyle = readStyle();
		const systemPromptAppend = loadStylePrompt(activeStyle);
		if (!systemPromptAppend) return undefined;

		return {
			// Literal append payload for APIs/versions that support systemPromptAppend.
			systemPromptAppend,
			// Working additive prompt replacement for currently installed Pi/OMP versions.
			systemPrompt: appendPrompt((event as { systemPrompt?: unknown }).systemPrompt, systemPromptAppend),
		};
	});
}
