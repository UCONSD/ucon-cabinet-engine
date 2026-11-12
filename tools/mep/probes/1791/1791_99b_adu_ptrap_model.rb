# UCON-MODEL: 1791_ADU_MEP
# 1791_99b: ADU Bath - Lacava 5451-001 (552 x 391 x 162) + Lusso 3D drawers (U cut-out in the upper one) + trap at P1.
S = { file: '1791_ADU_MEP.skp', tag: 'ADU', dw: 1600, xd: 1558, zd: 575, top: 864, stone_under: 825,
      carcass: { x0: 1277, x1: 1839, z0: 254, z1: 273 },
      drawers: [{ name: 'upper', sx0: 1282, sx1: 1834, yf: -540, yb: -90, z0: 487, z1: 673, b0: 490, b1: 500, notch: [1408, 1708, -346] },
                { name: 'lower', sx0: 1282, sx1: 1834, yf: -540, yb: -90, z0: 271, z1: 457, b0: 274, b1: 284 }],
      bowl: { name: 'Lacava 5451-001', round: false, cx: 1559, cy: -310, w: 552, d: 391, h: 162, src: 'Lacava 5451-001 exterior 552 x 391 x 162 (spec sheet)' } }
load File.expand_path('~/dev/ucon-cabinet-engine/tools/mep/probes/1791/1791_99_ptrap_model_body.rb')
