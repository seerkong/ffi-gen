class FFI::Gen
  def generate_rb
    writer = Writer.new "  ", "# "
    writer.puts "require 'ffi'"
    writer.puts "require '#{@require_path}/enums'"
    writer.puts ''
    writer.puts "module #{@module_name}"
    writer.indent do
      writer.puts "extend FFI::Library"
      writer.puts "ffi_lib_flags #{@ffi_lib_flags.map(&:inspect).join(', ')}" if @ffi_lib_flags
      writer.puts "ffi_lib #{@ffi_lib}", "" if @ffi_lib

      @full_dir = File.expand_path(@output + '/../' + File.basename(@output, '.*'))
      Dir.mkdir(@full_dir) unless File.exist?(@full_dir)
      @base_dir = File.basename(@full_dir)

      # Let's write type autoload
      declarations.each do |declaration|
        next unless declaration.kind_of?(StructOrUnion)

        writer.puts "autoload :#{declaration.name.to_ruby_classname}, '#{@require_path}/#{declaration.name.to_ruby_downcase}'"
      end
      writer.puts ''

      generate_struct_rb
      generate_enums_rb

      declarations.select(&:is_callback).each do |declaration|
        declaration.write_ruby writer
        declarations.delete declaration
      end

      declarations.each do |declaration|
        declaration.write_ruby writer
      end

    end
    writer.puts "end"
    writer.output
  end

  def generate_enums_rb
    writer = Writer.new "  ", "# "
    writer.puts "module #{@module_name}"
    writer.indent do
      writer.puts "extend FFI::Library"
      empty = !declarations.any?{ |d| d.kind_of?(Enum) }
      while not empty
        empty = true
        declarations.each do |declaration|
          next unless declaration.kind_of?(Enum)
          declaration.write_ruby writer
          declarations.delete declaration
          empty = false
        end
      end
    end
    writer.puts 'end'
    File.write("#{@full_dir}/enums.rb", writer.output)
  end

  def generate_struct_rb
    empty = !declarations.any?{ |d| d.kind_of?(StructOrUnion) }
    while not empty
      empty = true
      declarations.each do |declaration|
        next unless declaration.kind_of?(StructOrUnion)
        writer = Writer.new "  ", "# "
        writer.puts "module #{@module_name}"
        writer.indent { declaration.write_ruby(writer) }
        writer.puts "end"
        declarations.delete declaration
        File.write("#{@full_dir}/#{declaration.name.to_ruby_downcase}.rb", writer.output)
        empty = false
      end
    end
  end

  class Name
    RUBY_KEYWORDS = %w{alias and begin break case class def defined do else elsif end ensure false for if in module next nil not or redo rescue retry return self super then true undef unless until when while yield BEGIN END}

    def to_ruby_downcase
      format :downcase, :underscores, RUBY_KEYWORDS
    end

    def to_ruby_classname
      format :camelcase, RUBY_KEYWORDS
    end

    def to_ruby_constant
      format :upcase, :underscores, RUBY_KEYWORDS
    end
  end

  class Type
    def ruby_description
      ruby_name
    end
  end

  class Enum
    def write_ruby(writer)
      return if @name.nil?
      shorten_names

      @constants.each do |constant|
        constant[:symbol] = ":#{constant[:name].to_ruby_downcase}"
      end

      writer.comment do
        writer.write_description @description
        writer.puts "", "## Options:"
        @constants.each do |constant|
          writer.puts "#{constant[:symbol]} ::"
          writer.write_description constant[:comment], false, "  ", "  "
        end
        writer.puts "", "@method `enum_#{ruby_name}`", "@return [Symbol]", "@scope class", ""
      end

      writer.puts "enum :#{ruby_name}, ["
      writer.indent do
        writer.write_array @constants, "," do |constant|
          "#{constant[:symbol]}, #{constant[:value]}"
        end
      end
      writer.puts "]", ""
    end

    def ruby_name
      @ruby_name ||= @name.to_ruby_downcase
    end

    def ruby_ffi_type
      ":#{ruby_name}"
    end

    def ruby_description
      "Symbol from `enum_#{ruby_name}`"
    end
  end

  class StructOrUnion
    def write_ruby(writer)
      writer.comment do
        writer.write_description @description
        unless @fields.empty?
          writer.puts "", "## Fields:"
          @fields.each do |field|
            writer.puts ":#{field[:name].to_ruby_downcase} ::"
            writer.write_description field[:comment], false, "  (#{field[:type].ruby_description}) ", "  "
          end
        end
      end

      @fields << { name: Name.new(["dummy"]), type: PrimitiveType.new(:char_s) } if @fields.empty?

      unless @oo_functions.empty?
        writer.puts "module #{ruby_name}Wrappers"
        writer.indent do
          @oo_functions.each_with_index do |(name, function), index|
            parameter_names = function.parameters[1..-1].map { |parameter| parameter[:name].to_ruby_downcase }
            fn_name = name.to_ruby_downcase
            fn_name = function.ruby_name if fn_name.empty?
            writer.puts "" unless index == 0
            writer.comment do
              function.parameters[1..-1].each do |parameter|
                writer.write_description parameter[:description], false, "@param [#{parameter[:type].ruby_description}] #{parameter[:name].to_ruby_downcase} ", "  "
              end
              return_type = function.return_type.is_a?(StructOrUnion) ? function.return_type.ruby_name : function.return_type.ruby_description
              writer.write_description function.return_value_description, false, "@return [#{return_type}] ", "  "
            end
            writer.puts "def #{fn_name}(#{parameter_names.join(', ')})"
            writer.indent do
              cast = function.return_type.is_a?(StructOrUnion) ? "#{function.return_type.ruby_name}.new " : ""
              writer.puts "#{cast}#{@generator.module_name}.#{function.ruby_name}(#{(["self"] + parameter_names).join(', ')})"
            end
            writer.puts "end"
          end
        end
        writer.puts "end", ""
      end

      writer.puts "class #{ruby_name} < #{@is_union ? 'FFI::Union' : 'FFI::Struct'}"
      writer.indent do
        writer.puts "include #{ruby_name}Wrappers" unless @oo_functions.empty?
        writer.write_array @fields, ",", "layout ", "       " do |field|
          ":#{field[:name].to_ruby_downcase}, #{field[:type].ruby_ffi_type}"
        end
      end
      writer.puts "end", ""
    end

    def ruby_name
      @name.to_ruby_classname
    end

    def ruby_ffi_type
      # ruby_name
      "#{ruby_name}.by_ref"
    end

    def ruby_description
      ruby_name
    end
  end

  class FunctionOrCallback
    def write_ruby(writer)
      writer.puts "@blocking = true" if @blocking
      writer.comment do
        writer.write_description @function_description
        writer.puts "", "@method #{@is_callback ? "`callback_#{ruby_name}`" : ruby_name}(#{@parameters.map{ |p| p[:name].to_ruby_downcase if p[:name]}.join(', ')})"
        @parameters.each do |p|
          writer.write_description p[:description], false, "@param [#{p[:type].ruby_description}] #{p[:name].to_ruby_downcase if p[:name]} ", "  "
        end
        writer.write_description @return_value_description, false, "@return [#{@return_type.ruby_description}] ", "  "
        writer.puts "@scope class", ""
      end

      ffi_signature = "[#{@parameters.map{ |parameter| parameter[:type].ruby_ffi_type }.join(', ')}], #{@return_type.ruby_ffi_type}"
      if @is_callback
        writer.puts "callback :#{ruby_name}, #{ffi_signature}", ""
      else
        writer.puts "attach_function :#{ruby_name}, :#{@name.raw}, #{ffi_signature}", ""
      end
    end

    def ruby_name
      @name.to_ruby_downcase
    end

    def ruby_ffi_type
      ":#{ruby_name}"
    end

    def ruby_description
      "Proc(callback_#{ruby_name})"
    end
  end

  class Define
    def write_ruby(writer)
      parts = @value.map { |v|
        if v.is_a? Array
          case v[0]
          when :method then v[1].to_ruby_downcase
          when :constant then v[1].to_ruby_constant
          else raise ArgumentError
          end
        else
          v
        end
      }
      if @parameters
        writer.puts "def #{@name.to_ruby_downcase}(#{@parameters.join(", ")})"
        writer.indent do
          writer.puts parts.join
        end
        writer.puts "end", ""
      else
        writer.puts "#{@name.to_ruby_constant} = #{parts.join}", ""
      end
    end
  end

  class PrimitiveType
    def ruby_name
      case @clang_type
      when :void
        "nil"
      when :bool
        "Boolean"
      when :u_char, :u_short, :u_int, :u_long, :u_long_long, :char_s, :s_char, :short, :int, :long, :long_long
        "Integer"
      when :float, :double
        "Float"
      end
    end

    def ruby_ffi_type
      case @clang_type
      when :void            then ":void"
      when :bool            then ":bool"
      when :u_char          then ":uchar"
      when :u_short         then ":ushort"
      when :u_int           then ":uint"
      when :u_long          then ":ulong"
      when :u_long_long     then ":ulong_long"
      when :char_s, :s_char then ":char"
      when :short           then ":short"
      when :int             then ":int"
      when :long            then ":long"
      when :long_long       then ":long_long"
      when :float           then ":float"
      when :double          then ":double"
      end
    end
  end

  class StringType
    def ruby_name
      "String"
    end

    def ruby_ffi_type
      ":string"
    end
  end

  class ByValueType
    def ruby_name
      @inner_type.ruby_name
    end

    def ruby_ffi_type
      if @inner_type.is_a?(StructOrUnion)
        @inner_type.ruby_name
      else
        @inner_type.ruby_ffi_type
      end + ".by_value"
    end
  end

  class TypedefType
    def ruby_name
      parent.to_ruby_downcase
    end

    def ruby_ffi_type
      parent.to_ruby_classname
    end

    def write_ruby(writer)
    end

  end

  class PointerType
    def ruby_name
      @pointee_name.to_ruby_downcase
    end

    def ruby_ffi_type
      ":pointer"
    end

    def ruby_description
      "FFI::Pointer(#{'*' * @depth}#{@pointee_name ? @pointee_name.to_ruby_classname : ''})"
    end
  end

  class ArrayType
    def ruby_name
      "array"
    end

    def ruby_ffi_type
      if @constant_size
        "[#{@element_type.ruby_ffi_type}, #{@constant_size}]"
      else
        ":pointer"
      end
    end

    def ruby_description
      "Array<#{@element_type.ruby_description}>"
    end
  end

  class UnknownType
    def ruby_name
      name.to_ruby_downcase
    end

    def ruby_ffi_type
      ":#{ruby_name}"
    end
  end

end
