# 1791 shared D-sheet 'P-TRAP FIT' (2026-11-11): section scene from the model + elevation marks + notes. Loaded by the set
# probes after mep_drawing_set.rb; call inside DS.instance_eval: ptrap_page(skp, code, title, scene, xd, dw, marks, items, foot).
UCON::DrawingSet.define_singleton_method(:ptrap_page) do |skp, code, title, scene, xd, dw, marks, items, foot|
  pp = ->(x, y, z) { Geom::Point3d.new(x / 25.4, y / 25.4, z / 25.4) }
  next_page(title); header('SCALE 1:5 (SECTION AT THE DRAIN, FROM THE MODEL) · NOTES IN INCHES'); sheet_code(code)
  zx = self::WX - 0.3; zy = self::WY + 0.4; zw = 5.6; zh = 5.4
  vs = viewport(skp, scene, zx, zy, zw, zh, scale: 1.0 / 5, render: :vector)
  pa = vs.model_to_paper_point(pp.(xd, dw - 640, 230)); pb = vs.model_to_paper_point(pp.(xd, dw + 152, 900))
  ww = (pb.x - pa.x).abs; hh = (pb.y - pa.y).abs
  vs.transform!(Geom::Transformation2d.new([1, 0, 0, 1, zx + (zw - ww) / 2 - [pa.x, pb.x].min, zy + (zh - hh) / 2 - [pa.y, pb.y].min]))
  vs.render if vs.render_needed?
  sp = ->(y, z) { vs.model_to_paper_point(pp.(xd, y, z)) }
  rx = sp.(dw + 152, 0).x + 0.15
  last = nil
  marks.sort_by { |z, *_r| -z }.each do |z, t, c|
    q = sp.(dw, z)
    ty = q.y - 0.05
    ty = last + 0.13 if last && ty < last + 0.13
    last = ty
    line(q.x, q.y, rx + 0.2, q.y, @l_sheet, w: 0.35, c: c, dash: true)
    text(t, rx + 0.25, ty, @l_sheet, size: 6.5, font: self::MONO, c: c)
  end
  tx = self::WX + 8.85; ty = self::WY + 0.3; tw = self::WW - 8.9
  label('WHAT THE MODEL SHOWS', tx, ty, @l_sheet)
  line(tx, ty + 0.22, tx + tw, ty + 0.22, @l_sheet, w: 1.0)
  yy = ty + 0.35
  items.each do |h, t, red|
    text(h, tx, yy, @l_sheet, size: 8, bold: true, c: red ? self::RED : self::INK)
    box_text(t, tx, yy + 0.17, tw, 1.3, @l_sheet, size: 7.5, c: self::INK2)
    yy += 1.6
  end
  box_text(foot, self::WX, self::WY + self::WH - 0.75, self::WW, 0.7, @l_sheet, size: 7, c: self::INK2)
  @index << [code, title]
end
