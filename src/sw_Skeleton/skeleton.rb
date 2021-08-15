# SW::Skeleton an extension to convert all of the edges in a selected group into
# their equivalent sketchup polyline3d objects which will be ignored by Sketchup
# inferencing algorithm(s). A side effect is that after this conversion the user
# can no --- easily select---  longer apply a material to the group with the paint bucket.
# to remedy this problem ------
# paint
# which can be accessed through the outliner, drag L-R, or edit menu
#
#
# The entry point for the code is create_skeleton() where, we hope, the user
# has selected a Sketchup::Group beforehand.
#
# behind the scenes//// or internally what we are doing


module SW
  module Skeleton

    def self.create_skeleton()
      model = Sketchup.active_model
      sel = model.selection
      
      if sel.length != 1 || !sel[0].is_a?(Sketchup::Group)
        UI.messagebox 'Please select a group' 
      else
        begin
          model.start_operation('Create Skeleton', true)

          # load the polyline definition
          @polyline_def = load_polyline() unless @polyline_def.is_a?(Sketchup::ComponentInstance)

          # convert edges to polylines
          convert_edges(sel[0], @polyline_def)

          # remove the polyline definition if possible
          model.definitions.remove(@polyline_def) if Sketchup.version.to_i > 17

          model.commit_operation
          sel.clear
          
        rescue => exception
          model.abort_operation
          raise exception
         end  
         
      end
    end
      
    # Given a group, replace every edge in the group with
    # a scaled and exploded copy of the polyline3d component
    # definition. 
    #
    def self.convert_edges(grp, component_def)
      ents = grp.entities
      edges = ents.grep(Sketchup::Edge)
      edges.each {|edge|
      
        start_point = edge.start.position
        end_point = edge.end.position
        next if start_point == end_point # you never know
        
        # scale to the length of the edge
        tr = Geom::Transformation.scaling(ORIGIN, start_point.distance(end_point), 1, 1)
        
        # combine the rotations arond the Y and Z axes
        tr = calc_transform(start_point, end_point) * tr 
        
        inst = ents.add_instance(component_def, tr)
        inst.explode
      }
      ents.erase_entities(edges)
    end 

    # Given a start point and an end point, calculate a
    # transformation that will rotate an edge lying on the X axis
    # to coincide with the line from the start point to the
    # end point. 
    #
    def self.calc_transform(start_point, end_point)

      # a vector from start to end
      axis1 = start_point.vector_to(end_point) 

      # create a plane perpendicular to axis1
      plane1 = [start_point, axis1]

      # define a second plane parallel to the X_Y plane at Z height
      plane2 =  [[0, 0, end_point.z] , Z_AXIS]

      # find the intersection of the two planes and calculate the cross product.
      # Note that if we are drawing on the Z_axis we use the X_AXIS for axis2
      line = Geom.intersect_plane_plane(plane1, plane2)
      axis2 = line.nil? ? X_AXIS : line[1]
      axis3 = axis1 * axis2
      
      tr = Geom::Transformation.axes(ORIGIN, axis1, axis2.reverse, axis3.reverse)
      tr = Geom::Transformation.translation(start_point) * tr
      # returns tr
    end
    
    def self.load_polyline()
      path=File.join(SW::Skeleton::PLUGIN_DIR, 'components/polyline3d component 1 inch.skp')
      model = Sketchup.active_model
      definitions = model.definitions
      definitions.load path
    end
    
    def self.paint_skeleton()
      model = Sketchup.active_model
      sel = model.selection
      if sel.size != 1 || !sel[0].is_a?(Sketchup::Group)
        UI.messagebox 'Please select a group' 
      else
        model.start_operation('Paint Skeleton', true)
        sel[0].material = model.materials.current
        model.commit_operation
        sel.clear
      end
    end
    
  end
end

nil


