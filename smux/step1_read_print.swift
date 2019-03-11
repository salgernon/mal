import Foundation;

class Slisp {
	func READ(_ s: String) -> String {
		return s;
	}

	func EVAL(_ s: String) -> String {
		return s;
	}

	func PRINT(_ s: String) -> Void {
		print("\(s)");
	}

	func rep(_ s: String) -> Void {
		PRINT(EVAL(READ(s)));
	}

	func runt(_ s: String) -> Void {
		let m = Reader.read_str(s);
		Printer.pr_str(m);
	}
	
	func run() -> Void {
		while (true) {
			print("user> ", terminator:"");
			let s = readLine(strippingNewline:true);
			if (s != nil) {
				runt(s!);
			} else {
				print("! empty string, exiting");
				break;
			}
		}
	}
}
