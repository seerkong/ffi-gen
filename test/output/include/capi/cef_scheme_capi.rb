# Generated by ffi-gen. Please do not change this file by hand.

require 'ffi'

module CEF
  extend FFI::Library
  ffi_lib 'cef'
  
  def self.attach_function(name, *_)
    begin; super; rescue FFI::NotFoundError => e
      (class << self; self; end).class_eval { define_method(name) { |*_| raise e } }
    end
  end
  
  # (Not documented)
  class CefSchemeHandlerFactoryT < FFI::Struct
    layout :dummy, :char
  end
  
  # (Not documented)
  # 
  # @method register_scheme_handler_factory(scheme_name, domain_name, factory)
  # @param [FFI::Pointer(*StringT)] scheme_name 
  # @param [FFI::Pointer(*StringT)] domain_name 
  # @param [CefSchemeHandlerFactoryT] factory 
  # @return [Integer] 
  # @scope class
  attach_function :register_scheme_handler_factory, :cef_register_scheme_handler_factory, [:pointer, :pointer, CefSchemeHandlerFactoryT], :int
  
  # (Not documented)
  # 
  # @method clear_scheme_handler_factories()
  # @return [Integer] 
  # @scope class
  attach_function :clear_scheme_handler_factories, :cef_clear_scheme_handler_factories, [], :int
  
  # ///
  # 
  # = Fields:
  # :base ::
  #   (unknown) ///
  # :add_custom_scheme ::
  #   (FFI::Pointer(*)) ///
  class CefSchemeRegistrarT < FFI::Struct
    layout :base, :char,
           :add_custom_scheme, :pointer
  end
  
  # (Not documented)
  class CefResourceHandlerT < FFI::Struct
    layout :dummy, :char
  end
  
  # (Not documented)
  class CefBrowserT < FFI::Struct
    layout :dummy, :char
  end
  
  # (Not documented)
  class CefFrameT < FFI::Struct
    layout :dummy, :char
  end
  
  # (Not documented)
  class CefRequestT < FFI::Struct
    layout :dummy, :char
  end
  
  # ///
  # 
  # = Fields:
  # :base ::
  #   (unknown) ///
  # :create ::
  #   (FFI::Pointer(*)) ///
  class CefSchemeHandlerFactoryT < FFI::Struct
    layout :base, :char,
           :create, :pointer
  end
  
end