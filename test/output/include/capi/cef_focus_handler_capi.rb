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
  class CefBrowserT < FFI::Struct
    layout :dummy, :char
  end
  
  # (Not documented)
  class CefBrowserT < FFI::Struct
    layout :dummy, :char
  end
  
  # (Not documented)
  class CefBrowserT < FFI::Struct
    layout :dummy, :char
  end
  
  # (Not documented)
  # 
  # = Fields:
  # :base ::
  #   (unknown) ///
  # :on_take_focus ::
  #   (FFI::Pointer(*)) ///
  # :on_set_focus ::
  #   (FFI::Pointer(*)) ///
  # :on_got_focus ::
  #   (FFI::Pointer(*)) ///
  class CefFocusHandlerT < FFI::Struct
    layout :base, :char,
           :on_take_focus, :pointer,
           :on_set_focus, :pointer,
           :on_got_focus, :pointer
  end
  
end