$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

Dir["#{File.dirname(__FILE__)}/wycats/*.rb"].each do |element|
   require File.expand_path(element)
end

module Rewrite
  
  # For the past few weeks, I've been thinking that it would be nice to be able to do something
  # like:
  # 
  #   special_def foo(path)
  #     File.expand_path(path)
  #   end
  # 
  #   def heyo(path)
  #     File.read(foo(path))
  #   end
  # 
  # which would be converted into:
  # 
  #   def heyo(path)
  #     File.read(File.expand_path(path))
  #   end
  # 
  # This is a stupid example, but the real-life implications are profound. In Merb (which I
  # maintain) we do a lot of method calls purely for DRYness. Unfortunately, Ruby method calls are
  # dog slow. It would be nice to get the benefits of DRYness without giving up efficiency.
  # 
  # It seems like it might be possible to torture your rewrite into doing something like this, but I
  # didn't want to dive in and give it a look without asking you whether I'm barking up the wrong
  # tree first. One obvious problem would be stack-traces providing questionable information (same
  # problem as C macros), but it might be worth it.
  # 
  # Another interesting possibility would be using rewrite to provide debug-style warnings in
  # development mode that could be coverted to no-ops in production:
  # 
  #   if Merb.env == "development"
  #     special_def enforce(opts)
  #         opts.each do |k,v|
  #           raise ArgumentError, "#{k.inspect} doesn't quack like #{v.inspect}" unless k.quacks_like?(v)
  #         end
  #     end
  #   else
  #     special_def enforce(opts)
  #       no_op
  #     end
  #   end
  # 
  # which would convert a method like:
  # 
  #     def add_mime_type(key, transform_method, mimes, new_response_headers = {}, &block) 
  #       enforce!(key => Symbol, mimes => Array)
  #       ResponderMixin::TYPES.update(key => 
  #         {:accepts           => mimes, 
  #          :transform_method  => transform_method,
  #          :response_headers  => new_response_headers,
  #          :response_block    => block })
  # 
  #       Merb::RenderMixin.class_eval <<-EOS, __FILE__, __LINE__
  #         def render_#{key}(thing = nil, opts = {})
  #           self.content_type = :#{key}
  #           render thing, opts
  #         end
  #       EOS
  #     end
  # 
  # into
  # 
  #     def add_mime_type(key, transform_method, mimes, new_response_headers = {}, &block) 
  #      {key => Symbol, mimes => Array}.each do |k,v|
  #         raise ArgumentError, "#{k.inspect} doesn't quack like #{v.inspect}" unless k.quacks_like?(v)
  #       end
  # 
  #       ResponderMixin::TYPES.update(key => 
  #         {:accepts           => mimes, 
  #          :transform_method  => transform_method,
  #          :response_headers  => new_response_headers,
  #          :response_block    => block })
  # 
  #       Merb::RenderMixin.class_eval <<-EOS, __FILE__, __LINE__
  #         def render_#{key}(thing = nil, opts = {})
  #           self.content_type = :#{key}
  #           render thing, opts
  #         end
  #       EOS
  #     end
  # 
  # in development mode, but:
  # 
  #     def add_mime_type(key, transform_method, mimes, new_response_headers = {}, &block) 
  #       ResponderMixin::TYPES.update(key => 
  #         {:accepts           => mimes, 
  #          :transform_method  => transform_method,
  #          :response_headers  => new_response_headers,
  #          :response_block    => block })
  # 
  #       Merb::RenderMixin.class_eval <<-EOS, __FILE__, __LINE__
  #         def render_#{key}(thing = nil, opts = {})
  #           self.content_type = :#{key}
  #           render thing, opts
  #         end
  #       EOS
  #     end
  # 
  # in production mode.
  module Wycats
    
  end
  
end