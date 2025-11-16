import esbuild from 'esbuild';
import { stimulusPlugin } from 'esbuild-plugin-stimulus';

esbuild.build({
  entryPoints: ['app/javascript/*.*'],
  bundle: true,
  sourcemap: true,
  outdir: 'app/assets/builds',
  publicPath: '/assets',
  plugins: [stimulusPlugin()],
}).catch(() => process.exit(1));
