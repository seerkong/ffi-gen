module FFI::Gen::Clang
  # (Not documented)
  #
  # ## Fields:
  # :protocol ::
  #   (IdxEntityInfo)
  # :cursor ::
  #   (Cursor)
  # :loc ::
  #   (IdxLoc)
  class IdxObjCProtocolRefInfo < FFI::Struct
    layout :protocol, IdxEntityInfo.by_ref,
           :cursor, Cursor.by_value,
           :loc, IdxLoc.by_value
  end

end
