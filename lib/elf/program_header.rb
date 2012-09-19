module Elf
  class ProgramHeader
    attr_reader :idx, :type, :offset, :virtual_address, :physical_address,
                :file_size, :memory_size, :flags, :alignment

    def initialize(data)
      @idx = data[:idx]
      @type = data[:type_id]
      @offset = data[:offset]
      @virtual_address = data[:virtual_address]
      @physical_address = data[:physical_address]
      @file_size = data[:file_size]
      @memory_size = data[:memory_size]
      @flags = data[:flags]
      @alignment = data[:alignment]
    end
  end
end
