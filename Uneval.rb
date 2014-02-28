#
# Don't be evil
#
# Artoria Seiran @ https://github.com/Artoria/Uneval
#
module Uneval
  module Live;          end # obj.object_id
  module Primitive;     end # obj.inspect
  module ArrayLike;     end # 0...obj.size
  module HashLike;      end # obj.keys     / obj[k]
  module StructLike;    end # obj.members  / obj.send :member
  module Clob      ;    end
  module Construct;     end
  module ReadableTable; end
  module MethodLike;    end
  module UMethodLike;   end  
  module Bound;         end
  def self.dumpdo(obj, io, indent = 0, binding = nil)
    case obj      
      when Bound
        raise "obj #{obj} must be String or Symbol" unless obj.respond_to?(:to_s)
        io << indent(indent) << " eval(#{obj.to_s.inspect}, ObjectSpace._id2ref(#{binding.object_id}))"
        io.instance_eval do
          @bindings ||= []
          @bindings << binding
        end
      when Live
        io << indent(indent) << " ObjectSpace._id2ref(#{obj.object_id})"
      when Primitive
        io << indent(indent) << obj.inspect
      when Clob
        io << indent(indent) << " #{obj.class}.from_clob(\n"
        io << dumpdo(obj.to_clob, io, indent+4) << "\n"
        io << indent(indent) << ")"
      when Construct
        io << indent(indent) << " #{obj.class}.new(\n"
        first = false
        obj.ctorparams.each{|x|
          io << (first ? ",\n" : "")
          first = true
          io << dumpdo(obj.send(x), io, indent+4) 
        }        
        io << indent(indent) << ")"
      when MethodLike
        io << indent(indent) << "ObjectSpace._id2ref(#{obj.receiver.object_id}).method(#{obj.name})"
      when UMethodLike
        io << indent(indent) << "#{obj.owner}.instance_method(#{obj.name})"      
      when ReadableTable
        begin
          x = obj[0,0,0]
          io << indent(indent) << "Table.new(#{obj.xsize}, #{obj.ysize}, #{obj.zsize}).tap{|obj|\n"
          obj.xsize.times{|x|
            obj.ysize.times{|y|
              obj.zsize.times{|z|
                io << indent(indent) <<"  obj[#{x}, #{y}, #{z}] = #{obj[x,y,z]}\n"
              }
            }
          }
          io << indent(indent) << "}"
        end rescue begin
          x = obj[0,0]
          io << indent(indent) << "Table.new(#{obj.xsize}, #{obj.ysize}).tap{|obj|\n"
          obj.xsize.times{|x|
            obj.ysize.times{|y|
              io << indent(indent) <<"  obj[#{x}, #{y}] = #{obj[x,y]}\n"
            }
          }          
          io << indent(indent) << "}"
        end rescue begin
          x = obj[0]
          io << indent(indent) << "Table.new(#{obj.xsize}).tap{|obj|\n"
          obj.xsize.times{|x|
              io << indent(indent) <<"  obj[#{x}] = #{obj[x]}\n"
          }          
          io << indent(indent) << "}"
        end
      when ArrayLike
        io << indent(indent) << "[\n"
        (0...obj.size).each{|x|
          io << indent(indent) << dumpdo(obj[x], io, indent+4) << ",\n" 
        }
        io << indent(indent) << " ]"
      when HashLike
        io << indent(indent) << "Hash[[\n"
        obj.keys.each{|k|
          io << indent(indent) << "[\n" 
          io << dumpdo(k, io, indent + 4)  << ",\n"
          io << dumpdo(obj[k], io, indent+4)
          io <<  "],\n" 
        }
        io << indent(indent) << " ]]"
      when StructLike
          classname = obj.class.to_s[/#/] ? "OpenStruct" : obj.class.to_s
          io << indent(indent) << "#{classname}.new.tap{|obj|\n"
          (obj.members).each{|x|
            io << indent(indent) << "   obj.#{x} = " << dumpdo(obj.send(x), io, indent+4) << "\n"
          }        
        io << indent(indent) << "}"
      
      else #Object
        io << indent(indent) << "#{obj.class.to_s}.new.tap{|obj|\n"
          (obj.methods-Object.methods).grep(/=/).each{|x|
            if obj.respond_to? x.to_s.chop
              io << indent(indent) << "  obj.#{x} " << dumpdo(obj.send(x.to_s.chop), io, indent+4) << "\n"
            end
          }
        io << indent(indent) << "}"
      
      end
      ""
  end
  
  def self.dump(obj, io = nil, binding = nil, &block)
    io ||= ""
    bind = block ? binding || block.binding : binding
    dumpdo obj, io, 0, bind
    io
  end
  
  def self.load(obj)
    eval obj
  end
  
  INDENT = {}
  def self.indent(x) 
    INDENT[x] ||= " "*x
  end
  
  [Range, Numeric, String, Regexp, Symbol, TrueClass, FalseClass, NilClass].each{|x|
     x.send :include, Primitive
  }
  
  Array.send      :include, ArrayLike  
  Hash.send       :include, HashLike  
  class ::OpenStruct
    include Uneval::StructLike 
    def members
      @table.keys
    end
  end
  
  set_methods = lambda{|x|
    x.send :include, StructLike
    members = x.instance_methods.grep(/[A-Za-z0-9_]+=/).map{|z| z.to_s.chop.to_sym}.sort
    x.send :define_method, :members, lambda{
       members
    }
    x.constants.grep(/Class/).each{|z|
       set_methods.call(x.const_get(z))
    }
  }
  set_methods.call(RPG) if defined?(RPG)
  set_methods.call(Font) if defined?(Font)
  set_methods.call(Viewport) if defined?(Viewport)
  
  class ::Method
    include MethodLike
  end
  
  class ::UMethod
    include UMethodLike
  end
  
  class ::Color
    include Uneval::Construct
    def ctorparams
      [:red, :green, :blue, :alpha]
    end
  end if defined?(Color)
  
  class ::Tone
    include Uneval::Construct
    def ctorparams
      [:red, :green, :blue, :gray]
    end
  end if defined?(Tone)
  
  class ::Rect
    include Uneval::Construct
    def ctorparams
      [:x, :y, :width, :height]
    end
  end if defined?(Rect)
  
  class RPG::EventCommand
    include Uneval::Construct
    def ctorparams
      [:code, :indent, :parameters]
    end
  end if defined?(RPG::EventCommand)
  
  [::Table].each{|x|
     x.class_eval "
       include Uneval::Clob
       def to_clob
         [Marshal.dump(self)].pack('M')
       end
       def self.from_clob(text)
         Marshal.load(text.unpack('M').first)
       end
    " if defined?(x)
  }
  
  
  class ::Bitmap
    include Uneval::Clob
    def to_clob
      {:width =>  width, 
       :height => height, 
       :font => font, 
       :data => [addr[0, width*height*4]].pack("M")
      }
    end
    def self.from_clob(io)
      width, height, font, clob = io.values_at :width, :height, :font, :data
      x = Bitmap.new(width, height)
      x.addr[0, width*height*4] = clob.unpack("M").first
      x.font = font
      x
    end
  end if defined?(::Bitmap)
  
end



