module Layer3InterfacesHelper
  def node_column(record)
    link_to(h(record.layer2_interface.node.name), :action => :show, :controller => :nodes, :id => record.layer2_interface.node.id)
  end
end
