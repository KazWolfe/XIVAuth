import esbuild from 'esbuild';
import { stimulusPlugin } from 'esbuild-plugin-stimulus';

let esbuildOptions = {
  entryPoints: ['app/javascript/*.*'],
  bundle: true,
  sourcemap: true,
  outdir: 'app/assets/builds',
  publicPath: '/assets',
  plugins: [stimulusPlugin()],
}

if (process.argv && process.argv.includes('--watch')) {
  console.log("watching")
  const ctx = await esbuild.context(esbuildOptions);
  await ctx.watch();
} else {
  esbuild.build(esbuildOptions).catch(() => process.exit(1));
}
