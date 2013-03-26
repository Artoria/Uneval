module Uneval
  module Live;       end # obj.object_id
  module Primitive;  end # obj.inspect
  module ArrayLike;  end # 0...obj.size
  module HashLike;   end # obj.keys     / obj[k]
  module StructLike; end # obj.members  / obj.send :member
  module Blob      ; end
  def self.dumpdo(obj, io, indent = 0)
    case obj      
      when Primitive
        io << indent(indent) << obj.inspect
      when Live
        io << indent(indent) << " ObjectSpace._id2ref(#{obj.object_id})"
      when Blob
        io << indent(indent) << " #{obj.class}.blob_load(#{obj.blob_dump.inspect})"
      when Table
        begin
          x = obj[0,0,0]
          io << indent(indent) << "Table.new(#{obj.xsize}, #{obj.ysize}, #{obj.zsize}).tap{|obj| obj.instance_eval{\n"
          obj.xsize.times{|x|
            obj.ysize.times{|y|
              obj.zsize.times{|z|
                io << indent(indent) <<"  self[#{x}, #{y}, #{z}] = #{obj[x,y,z]}\n"
              }
            }
          }
          io << indent(indent) <<"  }\n"
          io << indent(indent) << "}"
        end rescue begin
          x = obj[0,0]
          io << indent(indent) << "Table.new(#{obj.xsize}, #{obj.ysize}).tap{|obj| obj.instance_eval{\n"
          obj.xsize.times{|x|
            obj.ysize.times{|y|
              io << indent(indent) <<"  self[#{x}, #{y}] = #{obj[x,y]}\n"
            }
          }
          io << indent(indent) <<"  }\n"
          io << indent(indent) << "}"
        end rescue begin
          x = obj[0]
          io << indent(indent) << "Table.new(#{obj.xsize}).tap{|obj| obj.instance_eval{\n"
          obj.xsize.times{|x|
              io << indent(indent) <<"  self[#{x}] = #{obj[x]}\n"
          }
          io << indent(indent) <<"  }\n"
          io << indent(indent) << "}"
        end
      when ArrayLike
        io << indent(indent) << "[\n"
        (0...obj.size).each{|x|
          io << indent(indent) << dumpdo(obj[x], io, indent+4) << ",\n" 
        }
        io << indent(indent) << " ]\n"
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
          io << indent(indent) << "#{classname}.new.tap{|obj|obj.instance_eval{\n"
          (obj.members).each{|x|
            io << indent(indent) << "   self.#{x} = " << dumpdo(obj.send(x), io, indent+4) << "\n"
          }
        io << indent(indent) <<"  }\n"
        io << indent(indent) << "}"
      else #Object
        io << indent(indent) << "#{obj.class.to_s}.new.tap{|obj|obj.instance_eval{\n"
          (obj.methods-Object.methods).grep(/=/).each{|x|
            if obj.respond_to? x.to_s.chop
              io << indent(indent) << "  self.#{x} " << dumpdo(obj.send(x.to_s.chop), io, indent+4) << "\n"
            end
          }
        io << indent(indent) <<"  }\n"
        io << indent(indent) << "}"
      
      end
      ""
  end
  
  def self.dump(obj, io = nil)
    io = "" if io == nil
    dumpdo obj, io
    io
  end
  
  def self.load(obj)
    eval obj
  end
  
  INDENT = {}
  def self.indent(x) 
    INDENT[x] ||= " "*x
  end
  
  [Numeric, String, Regexp, Symbol, TrueClass, FalseClass, NilClass].each{|x|
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
  
  
  class ::Rect
    include Uneval::StructLike
    def members
      [:x, :y, :width, :height]
    end
  end
  
  class ::Color
    include Uneval::StructLike
    def members
      [:red, :blue, :green, :alpha]
    end
  end
  
  class ::Tone
    include Uneval::StructLike
    def members
      [:red, :blue, :green, :gray]
    end
  end
  
  set_methods = lambda{|x|
    x.send :include, StructLike
    members = x.methods.grep(/[A-Za-z0-9_]+=/).map{|z| z.chop.to_sym}
    x.send :define_method, :members, lambda{|y|
       members
    }
    x.constants.grep(/Class/).each{|z|
       set_methods.call(x.const_get(z))
    }
  }
  set_methods.call(RPG)

  
end

