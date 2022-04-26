# SW::Skeleton, an extension to convert all of the edges in 
# a selected group into their equivalent sketchup polyline3d 
# objects which will be ignored by the Sketchup inferencing 
# algorithm(s). A side effect is that after this conversion 
# the user can no longer easily apply a material to the group 
# with the paint bucket. To remedy this problem select the 
# skeletonized group in the outliner or via a left to right 
# select of the entire group and paint with the Paint Skeleton
# command.

# Usage :
# - select a group
# - in the (right click) context menu choose Create Skeleton
# - to change the material, select the skeleton and in the 
#    (right click) context menu choose Paint Skeleton


module SW
  module Skeleton
    @polyline_def = nil

    def self.create_skeleton()
      model = Sketchup.active_model
      sel = model.selection
      
      unless sel.length == 1 && sel[0].is_a?(Sketchup::Group)
        UI.messagebox 'Please select a group' 
      else
        # begin
          model.start_operation('Create Skeleton', true)

          # load the polyline definition
          @polyline_def = load_polyline() unless @polyline_def.is_a?(Sketchup::ComponentInstance)

          # make unique !groups are supposed to be unique anyway
          grp = sel[0]
          grp.make_unique
          
          # convert edges to polylines
          convert_edges(grp, @polyline_def)

          # remove the polyline definition if possible
          if Sketchup.version.to_i > 17
            model.definitions.remove(@polyline_def)
            @polyline_def = nil
          end

          model.commit_operation
          # sel.clear
          
        # rescue => exception
          # model.abort_operation
          # raise exception
        # end  
         
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
        
        # scale to the length of the edge and combine the 
        # rotations around the Y and Z axes
        tr = Geom::Transformation.scaling(ORIGIN, start_point.distance(end_point), 1, 1)
        tr = calc_transform(start_point, end_point) * tr 
        
        inst = ents.add_instance(component_def, tr)
        inst.explode
      }
      ents.erase_entities(edges)
    end 

    # Given a start point and an end point, calculate a
    # transformation that will rotate an edge lying on the
    # X axis to coincide with the line from the start point 
    # to the end point. 
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
        # Avoid the Error:
        # 'The entity at address f1e0c440 has an invalid id (0)  destroyed (0)'
        Sketchup.active_model.materials.current = nil
      end
    end
    
  end
end

nil


