FIX_SVG_UNITS=sed -i 's/svg width="\([0-9]\+\)" height="\([0-9]\+\)"/svg width="\1mm" height="\2mm"/'

clean:
	rm -f *.stl *.gcode *.dxf *.ps *.eps clockers-*.svg

hourgears: clockers-hourgears.stl

minutegears: clockers-minutegears.stl

secondgears: clockers-secondgears.stl

topbracket: clockers-topbracket.stl

bottombracket: clockers-bottombracket.stl

clockers-hourgears.stl: movement.scad parts.scad
	openscad -o $@ -D 'mode="hourgears"' parts.scad

clockers-minutegears.stl: movement.scad parts.scad
	openscad -o $@ -D 'mode="minutegears"' parts.scad

clockers-secondgears.stl: movement.scad parts.scad
	openscad -o $@ -D 'mode="secondgears"' parts.scad

clockers-topbracket.stl: movement.scad parts.scad
	openscad -o $@ -D 'mode="topbracket"' parts.scad

clockers-bottombracket.stl: movement.scad parts.scad
	openscad -o $@ -D 'mode="bottombracket"' parts.scad

clockers-sensorclamps.stl: sensorclamp.scad parts.scad
	openscad -o $@ -D 'mode="sensorclamps"' parts.scad

clockers-pimount.stl: sensorclamp.scad parts.scad
	openscad -o $@ -D 'mode="pimount"' parts.scad

clockers-motodriversmount.stl: sensorclamp.scad parts.scad
	openscad -o $@ -D 'mode="motordriversmount"' parts.scad

clockers-hourhand.stl: hand.scad hour_hand.dxf
	openscad -o $@ -D 'dohand="hour"' $<

clockers-minutehand.stl: hand.scad minute_hand.dxf
	openscad -o $@ -D 'dohand="minute"' $<

clockers-secondhand.stl: hand.scad second_hand.dxf
	openscad -o $@ -D 'dohand="second"' $<

%.ps: %.svg
	inkscape -P $@ $<

%.dxf: %.ps
	pstoedit -xscale 100 -yscale 100 -dt -f dxf:-polyaslines $< $@

# SVGs

clockers-rearlayout.svg: movement.scad parts.scad
	openscad -o $@ -D 'mode="rearlayoutsvg"' parts.scad
	$(FIX_SVG_UNITS) $@
