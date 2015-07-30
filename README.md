# squish
sketchup ruby script, 3D analogue to the 2D "Offset" tool 

put this in your scripts and call 'squish(float)', 'squish_planar(float)', or 'squish_vertexal(float)' after selecting the geometry you want to squish.

currently, squish_vertexal is more stable, but sometimes provides shitty results, especially when small faces meet big faces with many edges (like circles). it should however be perfect for organic surfaces

TODOS:
- improving the planar squish (critical) [faces sometimes detach]
- ensure proper unit conversion(mm/in)


differences between the methods:

- squish(float): same as squish_planar
- squish_vertexal(float): iterates through all vertices of the selected faces, and computes the mean normal. this mean normal is added to the vertex. it also subdivides all polygons into triangles. however, it works really reliably
- squish_planar(float): iterates through faces, and projects planes parallel to the faces at the offset. it computes the intersections of the relevant planes and draws new geometry from that. it should yield better results for mechanical applications, but still bugs out in some special cases (faces detatch). 
