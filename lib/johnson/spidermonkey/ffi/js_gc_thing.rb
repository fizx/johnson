module Johnson
  module SpiderMonkey

    class JSGCThing
      include HasPointer

      def initialize(context, value)
        @context, @value = context, value
        @ptr_to_be_rooted = FFI::MemoryPointer.new(:pointer).write_pointer(value)
        @ptr = value
        @rooted = false
      end

      def root_rt(bind = nil, name = '')
        if add_root_rt(bind, name)
          @rooted = true
          retval = self
        end
        if block_given?
          retval = yield self
          unroot
        end
        retval
      end

      def unroot_rt
        remove_root_rt
        @rooted = false
        self
      end

      def root(bind = nil, name = '', &blk)
        if add_root(bind, name)
          @rooted = true
          retval = self
        end
        if block_given?
          retval = yield self
          unroot
        end
        retval
      end

      def unroot
        remove_root
        @rooted = false
        self
      end

      def rooted?
        @rooted == true
      end

      def unrooted?
        not rooted?
      end

      private

      def add_root(bind, name)
        SpiderMonkey.JS_AddNamedRoot(@context, @ptr_to_be_rooted, format_root_string(bind, name))
      end

      def add_root_rt(bind, name)
        SpiderMonkey.JS_AddNamedRootRT(@context.runtime, @ptr_to_be_rooted, format_root_string(bind, name)) == SpiderMonkey::JS_TRUE
      end

      def remove_root
        SpiderMonkey.JS_RemoveRoot(@context, @ptr_to_be_rooted)
      end

      def remove_root_rt
        SpiderMonkey.JS_RemoveRootRT(@context.runtime, @ptr_to_be_rooted)
      end

      def format_root_string(bind, name)
        format_name = name.empty? ? @value.inspect : name
        format_binding = bind if bind
        unless format_binding
          format_name
        else
          sprintf("%s[%d]:%s: %s", 
                  format_file(format_binding), 
                  format_line(format_binding), 
                  format_method(format_binding), 
                  format_name)
        end
      end

      def format_file(bind)
        eval('__FILE__', bind)
      end

      def format_line(bind)
        eval('__LINE__', bind)
      end

      def format_method(bind)
        begin
          eval('__method__', bind)
        rescue NameError
          warn 'WARNING: You should pass --1.9 option to jruby in order to use Kernel#__method__'
          'nomethod'
        end
      end

    end

  end
end
