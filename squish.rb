require 'sketchup.rb'



def c_cube() #debug cube
	t1 = [100,0  ,0  ]
	t2 = [100,100,0  ]
	t3 = [0  ,100,0  ]
	t4 = [0  ,0  ,0  ]
	t5 = [100,0  ,100]
	t6 = [100,100,100]
	t7 = [0  ,100,100]
	t8 = [0  ,0  ,100]
	Sketchup.active_model.selection.add Sketchup.active_model.entities.add_face(t1, t2, t3, t4)
	Sketchup.active_model.selection.add Sketchup.active_model.entities.add_face(t5, t6, t7, t8)
	Sketchup.active_model.selection.add Sketchup.active_model.entities.add_face(t1, t2, t6, t5)
	Sketchup.active_model.selection.add Sketchup.active_model.entities.add_face(t2, t3, t7, t6)
	Sketchup.active_model.selection.add Sketchup.active_model.entities.add_face(t3, t4, t8, t7)
	Sketchup.active_model.selection.add Sketchup.active_model.entities.add_face(t4, t1, t5, t8)
	
	narr = [] # add edges to selection
	puts Sketchup.active_model.selection.size
	Sketchup.active_model.selection.each { |x| 
		#puts x
		if(x.is_a? Sketchup::Face) then
			narr.push(x.edges)
		end
		#if (x.is_a? Sketchup::Edge) then
		#	narr.push(x.edges)
		#end
	}
	Sketchup.active_model.selection.add narr
	puts "geometry created!"
end

def s_abnormal(vertex, radius) # determines normal of point
	faces = vertex.faces
	normy = Geom::Vector3d.new 0,0,0
	faces.each{ |f|
		normy = normy + f.normal
	}
	#return normy.normalize #maybe divide instead
	x=(normy[0] / faces.size) * radius
	y=(normy[1] / faces.size) * radius
	z=(normy[2] / faces.size) * radius
	return Geom::Vector3d.new x,y,z
end

def s_getPlane(face, radius)
		na = face.normal[0] * radius
		nb = face.normal[1] * radius
		nc = face.normal[2] * radius
		normnorm = Geom::Vector3d.new(na,nb,nc)
		plane = [face.vertices[0].position + normnorm, normnorm]
		return plane
end #s_getPlane

def squish(radius)
	squish_planar(radius)
end

def squish_vertexal(radius) # requires selection of faces #eventually approaches sphere if possible
	#0) prep - delete later debug
	#c_cube
	
	#1) stack of faces in selection
	stack = [] 
	Sketchup.active_model.selection.each { |e| 
		if (e.is_a? Sketchup::Face) then
			stack.push e
		end
	}
	selection = Sketchup.active_model.selection #in case the selection gets fudged later
	postselection =[];
	
	
	#2) construct
	stack.each{ |e|  #stack of faces
		#puts e
		##make substack of all vertices connected to faces
		##takes care of the special cases where more than three faces share a vertex
		#substack=[]
		#ssubstack=e.edges;
		#ssubstack.each{ |sss|
		#	substack.push sss.vertices
		#}
		#substack = substack & substack # condense duplicates
		#fstack = [] # local faces
		
		vstack = e.vertices #vertex stack
		for i in 2..(vstack.size-1)
			av = vstack[0  ].position + s_abnormal(vstack[0  ], radius) # point3d 
			bv = vstack[i-1].position + s_abnormal(vstack[i-1], radius) # point3d 
			cv = vstack[i  ].position + s_abnormal(vstack[i  ], radius) # point3d 
			
			#Sketchup.active_model.selection.add Sketchup.active_model.entities.add_face(av,bv,cv)
			thisface = Sketchup.active_model.entities.add_face(av,bv,cv)
			postselection.push thisface;
			postselection.push thisface.edges;
		end
	}
	
	#3) delete old model
	Sketchup.active_model.active_entities.erase_entities Sketchup.active_model.selection
	#Sketchup.active_model.active_entities.erase_entities selection
	Sketchup.active_model.selection.add postselection
end

def squish_planar(radius) # requires selection of faces
	#0) prep - delete later debug
	#c_cube
	
	#1) stack of faces in selection
	stack = [] 
	Sketchup.active_model.selection.each { |e| 
		if (e.is_a? Sketchup::Face) then
			stack.push e
		end
	}
	selection = Sketchup.active_model.selection #in case the selection gets fudged later
	postselection =[];
	
	
	#2) construct
	stack.each{ |e|  #stack of faces, e is a face
		
		
		vstack = e.vertices #vertex stack
		estack = e.edges # edge stack
		fstack = [] #stack of faces excluding self
		estack.each{ |edg|
			fstack.push((edg.faces - [e])[0]) #silent treatment. optionally insert warning
		}
		
		#1) identify main plane
		plane = s_getPlane(e,radius)

		
		newlines = []
		for i in 0..(estack.size-1) # intersect planes from faces to find lines parallel to edges
			ofa = (estack[i].faces - [e])[0]
			if (ofa.nil? or ofa.normal == e.normal) then #faces are on same plane, or no adjacent planes
				aleph = estack[i].other_vertex estack[i].end
				beth = estack[i].end
				
				lal = [aleph.position, e.normal]
				lbe = [beth.position, e.normal]
				
				pta = Geom.intersect_line_plane(lal, plane)
				ptb = Geom.intersect_line_plane(lbe, plane)
				
				newlines.push([pta, ptb])
				
			else #use plane intersects
				newlines.push(Geom.intersect_plane_plane(plane, s_getPlane(ofa, radius)))
			end
		end
		newverts = []
		for i in 0..(newlines.size-1) # intersect the lines
			newln = Geom.intersect_line_line(newlines[i], newlines[(i+1)%newlines.size])
			if !newln.nil? then # could be parallel if edge is subdivided
				newverts.push(newln)		
			end
		end
			
		thisface = Sketchup.active_model.entities.add_face(newverts)
		postselection.push thisface;
		postselection.push thisface.edges;
	}
	
	#3) delete old model
	Sketchup.active_model.active_entities.erase_entities Sketchup.active_model.selection
	#Sketchup.active_model.active_entities.erase_entities selection
	Sketchup.active_model.selection.add postselection
end

def squish_planar_old(radius) # requires selection of faces #yields strange splitting artifacts
	#0) prep - delete later debug
	#c_cube
	
	#1) stack of faces in selection
	stack = [] 
	Sketchup.active_model.selection.each { |e| 
		if (e.is_a? Sketchup::Face) then
			stack.push e
		end
	}
	selection = Sketchup.active_model.selection #in case the selection gets fudged later
	postselection =[];
	
	
	#2) construct
	stack.each{ |e|  #stack of faces
		
		
		vstack = e.vertices #vertex stack
		
		#na = e.normal[0] * e.edges[0].position[0] * radius
		#nb = e.normal[1] * e.edges[1].position[1] * radius
		#nc = e.normal[2] * e.edges[2].position[2] * radius
		
		na = e.normal[0] * radius
		nb = e.normal[1] * radius
		nc = e.normal[2] * radius
		
		normnorm = Geom::Vector3d.new(na,nb,nc)
		plane = [vstack[0].position + normnorm, normnorm]
		
		#setup plane
		#pa = vstack[0].position + e.normal.position
		#pb = vstack[1].position + e.normal.position
		#pc = vstack[2].position + e.normal.position
		
		newverts = []
		vstack = e.vertices #vertex stack
		for i in 0..(vstack.size-1)
			av = [vstack[i].position, s_abnormal(vstack[i], 1)] # geom.line 
			
			newverts.push(Geom.intersect_line_plane(av, plane))
			
		end
		thisface = Sketchup.active_model.entities.add_face(newverts)
		postselection.push thisface;
		postselection.push thisface.edges;
	}
	
	#3) delete old model
	Sketchup.active_model.active_entities.erase_entities Sketchup.active_model.selection
	#Sketchup.active_model.active_entities.erase_entities selection
	Sketchup.active_model.selection.add postselection
end
