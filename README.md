## TODO (in no specific order...)

 - Get available plugins sorted alphabetically
 - Read in defaults from user configs - DONE by scrapcoder, 5/13/09
 - Convert all the plugins for gosh sakes!
 - Implement DataMapper tagging - DONE by scrapcoder, 5/11/09
 - Test DataMapper validations - DONE by scrapcoder, 5/13/09
 - Fix address functions in ip_interface and ip_network models - DONE by scrapcoder, 5/11/09
 - Modify framework class to avoid loading all plugins if not necessary
 - Decide on tagging contexts for individual model (each model currently only has a generic 'tags' context)
 - Add attribute accessors for each tag context in models
 - See if a parent model class can be created to roll up the following:
   - storage_names[:default] = <model name>
   - property :id, Serial
   - has_tags_on :tags
   - attribute accessor for generic 'tags' context
 - Create gemspec (don't forget about all the dm-* gem requirements!!!)
 - Make sure ANTFARM and user-specified plugins don't clash
   - First try - when loading a plugin, check to see if it's already defined.  If so, raise an error (be specific with the error!).
 - Convert underscores in plugin names to hyphens for command line usage
 - Figure out why :constraint => :destroy isn't working (needed for Layer3Network#merge) - DONE by scrapcoder, 5/28/09
 - Create initializer for each class that strips out junk to be used for creating classes each class belongs to.
   - What about a centalized DataStore? Models can check it to see if anything is set that they care about. Could make it thread safe with Mutex stuff if need be.
 - Utilize new Bundler gem environment solution being used by Heroku and others
 - Ditzify! This helps to support CHANGELOGs and such.
   - Is it possible to update GitHub Issues with Ditz information? Would be cool...
 - Lots of other TODO's I'm sure...

## Current Bugs:

  - For some reason, the 'before :create' hook isn't getting ran when a new Layer 3 Interface is created.  This keeps a Layer 2 Interface from being created, which causes validations to fail.
  - Along those same lines, the 'before :create' is now getting called, but the Layer2Interface being created isn't getting set in Layer3Interface's layer2_interface_id column...
    - Forced hacks to get around this:
      - Create Layer2Interface in IpInterfce and add it to DataStore
  - Cannot use rake task to run tests because the bundler lib cannot be found the second time around
    - Try running it to see what I mean...
    - This seems to be due to the spawned rake task running after Bundler has mangled rubygems to only use
      bundled gems. If bundler is added to the testing group, the error goes away, but a new one appears.
      It now has trouble loading another rspec file.
    - Removed loading of config/boot in Rakefile. Still have issue of loading other rspec mock file. Just
      using 'spec test/models/node_spec.rb' for now.

## Structure of ANTFARM Database:

Note: direction of arrow identifies 'belongs to' relationship (i.e. IpInterface belongs to Layer3Interface)

Layer3Network <-------- IpNetwork --------> PrivateNetwork

 /\
/__\
 ||
 ||
 ||
 ||
 ||

Layer3Interface <-------- IpInterface

 ||
 ||
 ||
 ||
_||_
\  / 
 \/

Layer2Interface <-------- EthernetInterface

 ||
 ||
 ||
 ||
_||_
\  / 
 \/

Node

### Object Creation Lifecycle

When *something* is created, whatever models it belongs to must be created as well
When *something* is destroyed, whatever models it owns must be destroyed as well

Also, when an IP Interface is created, an IP Network needs to be created as well

This causes the following problem:

  - When an IP Interface is created, it creates a Layer 3 Interface
  - When a Layer 3 Interface is created, it creates a Layer 3 Network
  - When an IP Interface is created, it creates an IP Network
  - When an IP Network is created, it creates a Layer 3 Network

Problem: How do we make sure the Layer 3 Interface and the IP Network get associated with the same Layer 3 Network?

Solution:
Create the IP Network first, then get its corresponding Layer 3 Network. Then create the Layer 3 Interface, passing it the correct Layer 3 Network.
Note: the same should apply *if* one happens to create an Ethernet Interface when creating the IP Interface.