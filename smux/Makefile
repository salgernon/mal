#
#http://notes.eatonphil.com/compiler-basics-lisp-to-assembly.html
#

obj/step0_repl.out: step0_repl.swift main.swift
	mkdir -p obj/
	swiftc -v -o $@ $< main.swift

obj/step1_read_print.out: step1_read_print.swift Reader.swift Types.swift Printer.swift main.swift
	mkdir -p obj/
	swiftc -v -o $@ $< Types.swift Reader.swift Printer.swift main.swift 

obj/step2_eval.out: step2_eval.swift Reader.swift Types.swift Printer.swift main.swift
	mkdir -p obj/
	swiftc -v -o $@ $< Types.swift Reader.swift Printer.swift main.swift 

clean:
	rm -rf obj/

