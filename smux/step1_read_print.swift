import Foundation;

class S0lisp {
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
		do {
			let m : MalType;

			try m = Reader.read_str(s);

			Printer.pr_str(m);
		} catch (ReaderError.emptyLine) {
			// just a line with a comment
		} catch (ReaderError.badForm(let r)) {
			print("Bad form: \(r)");
		} catch (ReaderError.fatalError) {
			print("Fatal error");
		} catch (ReaderError.unexepectedEOF(let missing)) {
			print("Unspected EOF, missing \(missing)");
		} catch {
			print("Utter failure evaluating \(s)");
		}
	}
	
	func run() -> Void {
		var running = true;

		while (running) {
			print("user> ", terminator:"");
			let s = readLine(strippingNewline:true);

			if (s == nil || s!.compare("quit") == ComparisonResult.orderedSame) {
				running = false;
			} else {
				runt(s!);
			}
		}
	}
}
