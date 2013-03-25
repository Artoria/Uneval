module Uneval
  def self.indent(x)
    " "*x
  end
  def self.dumpdo(obj, io, indent = 0)
    case obj
      when Numeric, String, Regexp, Symbol, TrueClass, FalseClass, NilClass
        io << indent(indent) << obj.inspect
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
      when Array
        io << indent(indent) << "[\n"
        obj.each{|x|
          io << indent(indent) << dumpdo(x, io, indent+4) << ",\n" 
        }
        io << indent(indent) << " ]\n"
      when Hash
        io << indent(indent) << "Hash[[\n"
        obj.each{|k,v|
          io << indent(indent) << "[" << dumpdo(k, io, indent+4)  <<
                                  "," << dumpdo(v, io, indent+4)  <<
                                  "],\n"
          
        }
        io << indent(indent) << " ]]"
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
end


