module FunnelEventsHelper
  
  def xdot_javascript
    f = IO.popen("dot -Txdot ", "w+")
    dotcode = render :partial=>'graph_dot'
    logger.debug dotcode
    f.write(dotcode + "\n")
    f.close_write
    xdot = f.read
    logger.debug xdot
    return escape_javascript(xdot)    
  end
  
end