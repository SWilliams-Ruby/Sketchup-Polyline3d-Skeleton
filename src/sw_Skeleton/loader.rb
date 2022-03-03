require File.join(SW::Skeleton::PLUGIN_DIR, 'skeleton.rb')

module SW
  module Skeleton
       
    #initialize menus
    if !file_loaded?("loader.rb")
      # UI.add_context_menu_handler do |menu|
        # if menu == nil then
          # UI.messagebox("Error settting context menu handler")
        # else
          # menu.add_item("Create Skeleton") {create_skeleton}
          # menu.add_item("Paint Skeleton") {paint_skeleton}
        # end	
      # end

      menu = UI.menu("Plugins").add_submenu('SW_Skeleton')
      menu.add_item("Create Skeleton from Group"){create_skeleton}
      menu.add_item("Paint Skeleton"){paint_skeleton}

    end
    
    file_loaded("loader.rb")
  end
  
end


