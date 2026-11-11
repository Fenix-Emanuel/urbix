# Urbix · Movilidad eléctrica

Web cinematográfica de Ignis Studio para Urbix (monopatines, bicis y motos eléctricas).

- **Producción:** https://urbix-tau.vercel.app (proyecto `urbix` en Vercel)
- `site/` — la web publicada (HTML + imágenes clave + láminas de cuadros). Para volver a publicar: `cd site && npx vercel deploy --prod`
- `ignis-preview.html` — misma web en formato vista previa (Artifact)
- `index.html` — primera versión de la tienda (v1)
- `gen/` — imágenes clave generadas (16:9 `k1–k4`, 9:16 `m1–m4`)
- `seq/` — láminas de cuadros 2×2 de cada transición (`d*` escritorio, `m*` celular)
- `tools/frames.swift` — convierte un video en láminas de cuadros
- `tools/reel.swift` — arma los reels verticales con textos
- `img/` — fotos originales del cliente (no se usan en la web final)
