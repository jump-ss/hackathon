IRB::Inspector.def_inspector([:test]) { |v| nil if v.include?('RestClient') }
