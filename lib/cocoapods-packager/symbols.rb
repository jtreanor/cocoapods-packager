module Symbols
  def symbols_from_library(library)
    syms = `nm -gU #{library}`.split("\n")
    classes = classes_from_symbols(syms)
    result = classes + constants_from_symbols(syms)

    global_syms = `nm -U #{library}`.split("\n")
    result = result + category_selectors_from_symbols(global_syms, classes)

    result.reject { |e| e == "llvm.cmdline" || e == "llvm.embedded.module" }
  end

  module_function :symbols_from_library

  :private

  def classes_from_symbols(syms)
    classes = syms.select { |klass| klass[/OBJC_CLASS_\$_/] }
    classes = classes.uniq
    classes.map! { |klass| klass.gsub(/^.*\$_/, '') }
  end

  def constants_from_symbols(syms)
    consts = syms.select { |const| const[/ S /] }
    consts = consts.select { |const| const !~ /OBJC|\.eh/ }
    consts = consts.uniq
    consts = consts.map! { |const| const.gsub(/^.* _/, '') }

    other_consts = syms.select { |const| const[/ T /] }
    other_consts = other_consts.uniq
    other_consts = other_consts.map! { |const| const.gsub(/^.* _/, '') }

    consts + other_consts
  end

  def category_selectors_from_symbols(global_syms, class_symbols)
    selectors = global_syms.select {|cat| cat[/ t (\+|\-)\[.*\(.*\) .*\]/]}
    class_symbols.each do |klass|
      #Reject selectors on non global classes
      selectors = selectors.reject { |sel| sel.include? klass }
    end
    selectors = selectors.map { |cat| cat.gsub(/.* t (\-|\+).* /, '') }
    selectors = selectors.map { |cat| cat.gsub(/(\]|:).*/, '')}
    selectors = selectors.reject { |cat| cat[/^set/]} #setters
    selectors.uniq
  end

  module_function :classes_from_symbols
  module_function :constants_from_symbols
  module_function :category_selectors_from_symbols
end
