import * as p from "@clack/prompts";
import { spawn } from "node:child_process";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { defineCommand, runMain } from "citty";

const PACKAGES = ["brew", "macos", "home", "sudo"] as const;
type PackageId = (typeof PACKAGES)[number];

function readCliVersion(): string {
  try {
    const path = join(dirname(fileURLToPath(import.meta.url)), "..", "package.json");
    const pkg = JSON.parse(readFileSync(path, "utf8")) as { version?: string };
    return pkg.version ?? "0.0.0";
  } catch {
    return "0.0.0";
  }
}

/** Default `install` when no subcommand (e.g. bare `npm run start`). */
function normalizeArgv(argv: string[]): string[] {
  if (argv.length === 0) return ["install"];
  const first = argv[0]!;
  if (first === "install" || first === "sync" || first === "export") return argv;
  if (first.startsWith("-")) return ["install", ...argv];
  return argv;
}

function requireDotfilesRoot(): string {
  const root = process.env.DOTFILES_ROOT?.trim();
  if (!root) {
    console.error("DOTFILES_ROOT is not set. Run via ./bootstrap.sh from the repo root.");
    process.exit(1);
  }
  return root;
}

function isYesMode(args: { yes?: boolean }): boolean {
  return Boolean(args.yes);
}

function hasPackageEnvOverride(): boolean {
  return Boolean(process.env.DOTFILES_PACKAGES?.trim() || process.env.DOTFILES_SKIP?.trim());
}

function shouldPromptForPackages(args: { yes?: boolean }): boolean {
  return (
    !isYesMode(args) && Boolean(process.stdin.isTTY) && !hasPackageEnvOverride()
  );
}

async function pickPackagesInteractive(): Promise<Set<PackageId>> {
  const values = await p.multiselect<PackageId>({
    message: "Which packages should run? (space to toggle, enter to confirm)",
    options: PACKAGES.map((value) => ({ value, label: value })),
    initialValues: [...PACKAGES],
    required: false,
  });
  if (p.isCancel(values)) {
    p.cancel("Aborted.");
    process.exit(0);
  }
  return new Set(values);
}

function allPackagesSet(): Set<PackageId> {
  return new Set(PACKAGES);
}

function applyPackageSelectionToEnv(selected: Set<PackageId>): void {
  const skipped = PACKAGES.filter((id) => !selected.has(id));
  if (skipped.length === 0) {
    delete process.env.DOTFILES_SKIP;
    delete process.env.DOTFILES_PACKAGES;
    return;
  }
  process.env.DOTFILES_SKIP = skipped.join(",");
  delete process.env.DOTFILES_PACKAGES;
}

async function runInstallScript(root: string, name: PackageId): Promise<void> {
  const script = join(root, "packages", name, "install");
  await new Promise<void>((resolve, reject) => {
    const child = spawn(script, [], {
      cwd: root,
      stdio: "inherit",
      env: { ...process.env, DOTFILES_ROOT: root },
    });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`packages/${name}/install exited with code ${code}`));
    });
  });
}

async function runInstallFlow(args: { yes?: boolean }): Promise<void> {
  const root = requireDotfilesRoot();
  const interactive = shouldPromptForPackages(args);
  if (interactive) p.intro("Dotfiles bootstrap");

  let selected: Set<PackageId>;
  if (interactive) {
    selected = await pickPackagesInteractive();
  } else {
    const allow = process.env.DOTFILES_PACKAGES?.trim();
    if (allow) {
      const ids = allow.split(",").map((s) => s.trim()) as PackageId[];
      selected = new Set();
      for (const id of ids) {
        if ((PACKAGES as readonly string[]).includes(id)) selected.add(id as PackageId);
      }
      if (selected.size === 0) selected = allPackagesSet();
    } else {
      selected = allPackagesSet();
      const deny = process.env.DOTFILES_SKIP?.trim();
      if (deny) {
        const denySet = new Set(deny.split(",").map((s) => s.trim()));
        selected = new Set(PACKAGES.filter((id) => !denySet.has(id)));
      }
    }
  }

  applyPackageSelectionToEnv(selected);

  const order = PACKAGES.filter((id) => selected.has(id));
  for (const name of order) {
    if (interactive) p.log.step(`Running ${name}…`);
    else console.error(`==> dotfiles-cli: ${name}`);
    await runInstallScript(root, name);
  }

  if (interactive) p.outro("Bootstrap complete.");
  else console.error("Bootstrap complete.");
}

function exportForwardArgs(): string[] {
  const argv = process.argv;
  const i = argv.findIndex((a) => a === "sync" || a === "export");
  return i >= 0 ? argv.slice(i + 1) : [];
}

function runExportSh(root: string, forwardArgs: string[]): Promise<number> {
  return new Promise((resolve, reject) => {
    const exportScript = join(root, "export.sh");
    const child = spawn(exportScript, forwardArgs, {
      cwd: root,
      stdio: "inherit",
      env: { ...process.env, DOTFILES_ROOT: root },
    });
    child.on("error", reject);
    child.on("close", (code) => resolve(code ?? 1));
  });
}

const installCommand = defineCommand({
  meta: {
    name: "install",
    description: "Apply dotfiles packages (brew → macos → home → sudo unless skipped)",
  },
  args: {
    yes: {
      type: "boolean",
      description: "Non-interactive: skip Clack; respect DOTFILES_PACKAGES / DOTFILES_SKIP",
      alias: ["y"],
      default: false,
    },
  },
  async run({ args }) {
    try {
      await runInstallFlow({ yes: args.yes });
    } catch (e) {
      console.error(e instanceof Error ? e.message : e);
      process.exit(1);
    }
  },
});

const syncCommand = defineCommand({
  meta: {
    name: "sync",
    description: "Export live state into the repo (runs ./export.sh)",
    alias: ["export"],
  },
  async run() {
    const root = requireDotfilesRoot();
    const code = await runExportSh(root, exportForwardArgs());
    process.exit(code);
  },
});

const main = defineCommand({
  meta: {
    name: "dotfiles",
    version: readCliVersion(),
    description: "Dotfiles CLI — install (default) or sync",
  },
  subCommands: {
    install: installCommand,
    sync: syncCommand,
    export: syncCommand,
  },
});

const argv0 = process.argv.slice(0, 2);
const argvRest = normalizeArgv(process.argv.slice(2));
process.argv = [...argv0, ...argvRest];

await runMain(main, { rawArgs: argvRest });
