# UCON-MODEL: 1791_BATH1_MEP
# 1791_99a: Bath 1 - Kohler Kallos K-2361 (dia 406 x 130) + Lusso 3D drawers (U cut-out in the upper one) + trap at P1.
S = { file: '1791_BATH1_MEP.skp', tag: 'BATH1', dw: 1575, xd: 632, zd: 587, top: 864, stone_under: 762,
      carcass: { x0: 349, x1: 911, z0: 254, z1: 273 },
      drawers: [{ name: 'upper', sx0: 354, sx1: 906, yf: -537, yb: -87, z0: 521, z1: 707, b0: 524, b1: 534, notch: [480, 780, -343] },
                { name: 'lower', sx0: 354, sx1: 906, yf: -537, yb: -87, z0: 271, z1: 457, b0: 274, b1: 284 }],
      bowl: { name: 'Kohler K-2361 Kallos', round: true, cx: 630, cy: -310, w: 406, h: 130, src: 'Kohler K-2361 Kallos 16 in round undermount, 5 1/8 in high (spec / First Supply)' } }
load File.expand_path('~/dev/ucon-cabinet-engine/tools/mep/probes/1791/1791_99_ptrap_model_body.rb')
