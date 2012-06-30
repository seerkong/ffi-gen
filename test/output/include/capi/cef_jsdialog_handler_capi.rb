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
  # 
  # = Fields:
  # :base ::
  #   (unknown) ///
  # :cont ::
  #   (FFI::Pointer(*)) ///
  class CefJsdialogCallbackT < FFI::Struct
    layout :base, :char,
           :cont, :pointer
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
  
  # ///
  # 
  # = Fields:
  # :base ::
  #   (unknown) ///
  # :on_jsdialog ::
  #   (FFI::Pointer(*)) ///
  # :on_before_unload_dialog ::
  #   (FFI::Pointer(*)) ///
  # :on_reset_dialog_state ::
  #   (FFI::Pointer(*)) ///
  class CefJsdialogHandlerT < FFI::Struct
    layout :base, :char,
           :on_jsdialog, :pointer,
           :on_before_unload_dialog, :pointer,
           :on_reset_dialog_state, :pointer
  end
  
end