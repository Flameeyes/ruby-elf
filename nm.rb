# bsd-nm implementation based on elf.rb (very limited)

require 'elf.rb'

f = Elf::File.new(ARGV[0])

addrsize = (f.elf_class == Elf::Class::Elf32 ? 8 : 16)

# Assume -D switch, just for now
f.sections['.dynsym'].symbols.each do |sym|
  addr = sprintf("%0#{addrsize}x", sym.value)

  addr = ' ' * addrsize unless sym.section

  flag = '?'
  if sym.idx == 0
    next
  elsif sym.bind == Elf::Symbol::Binding::Weak
    flag = sym.value != 0 ? 'W' : 'w'
  # The following are three 'reserved sections'
  elsif sym.section == Elf::Section::Undef
    flag = 'U'
  elsif sym.section == Elf::Section::Abs
    # Absolute symbols
    flag = 'A'
  elsif sym.section == Elf::Section::Common
    # Common symbols
    flag = 'C'
  elsif sym.section.is_a? Integer
    $stderr.puts sym.section.hex
    flag = '!'
  elsif sym.section.name == '.init'
    next
  else
    flag = case sym.section.name
           when ".text" then 'T'
           else '?'
           end
  end

  flag.downcase! if sym.bind == Elf::Symbol::Binding::Local

  if flag != 'A' and f.sections['.gnu.version']
    version_idx = f.sections['.gnu.version'][sym.idx]
    if version_idx >= 2
      if sym.section == nil
        version_name = f.sections['.gnu.version_r'][version_idx][:name]
      else
        if version_idx & (1 << 15) == 0
          version_name = f.sections['.gnu.version_d'][version_idx][:names][0]
        else
          version_idx = version_idx & ~(1 << 15)
          version_name = f.sections['.gnu.version_d'][version_idx][:names][1]
        end
      end

      version_name = "@@#{version_name}"
    end
  end

  puts "#{addr} #{flag} #{sym.name}#{version_name}"
end
