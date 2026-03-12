/**
 * Astro CLI wrapper that bypasses the #!/usr/bin/env node shebang.
 * On Termux, `node` is bionic-linked (reports process.platform === 'android'),
 * which breaks native binary resolution for rollup, lightningcss, etc.
 * Running via `bun run` ensures process.platform === 'linux' and glibc-linked
 * native binaries load correctly.
 */
import { cli } from '../node_modules/astro/dist/cli/index.js';
cli(process.argv);
