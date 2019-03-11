obj/step0_repl.out: step0_repl.swift main.swift
	mkdir -p obj/
	swiftc -v -o $@ $< main.swift

obj/step1_read_print.out: step1_read_print.swift Reader.swift main.swift
	mkdir -p obj/
	swiftc -v -o $@ $< Reader.swift main.swift

clean:
	rm -rf obj/

