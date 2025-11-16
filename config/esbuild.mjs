import esbuild from 'esbuild';

esbuild.build({
  entryPoints: ['app/javascript/*.*'],
  bundle: true,
  sourcemap: true,
  outdir: 'app/assets/builds',
  publicPath: '/assets',
}).catch(() => process.exit(1));
