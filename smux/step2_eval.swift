import Foundation;

typealias SEnv2 = [ MalSymbol : MalClosure ];

class SLisp2 {
	func READ(_ s: String) throws -> MalType {
		return try Reader.read_str(s)
	}

	func isCollectionType(_ v: MalType) -> Bool {
		let tt = type(of:v);
		if (tt == MalList.self) {
			return true;
		}
		if (tt == MalVector.self) {
			return true;
		}
		if (tt == MalHash.self) {
			return true;
		}
		return false;
	}

	func isSymbolType(_ v: MalType) -> Bool {
		let tt = type(of:v);
		if (tt == MalString.self) {
			return true;
		}
		if (tt == MalKeyword.self) {
			return true;
		}
		return false;
	}

	func eval_ast(_ ast:MalType, env:SEnv2) throws -> MalType {
		if (isSymbolType(ast)) {
			let r = env[ast as! MalSymbol];
			guard (r != nil) else {
				throw ReaderError.undefinedSymbol(ast);
			}
			return r!;
		}

		if (isCollectionType(ast)) {
			let cc = ast as! MalCollection;
			let rr = cc.map2({ (v:MalType) throws -> MalType in
				return try EVAL(v, env:env);
			});
			return rr;
		}

		return ast;
	}

	func EVAL(_ ast: MalType, env:SEnv2) throws -> MalType {
		if (isCollectionType(ast) == false) {
			return try eval_ast(ast, env:env);
		}

		let asList = (ast as! MalCollection);
		if (asList.count() == 0) {
			return ast;
		}

		let newList = try eval_ast(asList, env:env);

		guard (isCollectionType(newList)) else {
			throw ReaderError.fatalError("expected list result in eval_ast of list \(ast), got \(newList)");
		}

		guard ((newList as! MalCollection).count() > 0) else {
			throw ReaderError.fatalError("Empty list from eval_ast");
		}

		let c = (newList as! MalCollection).car();
		let s = (c as? MalClosure);

		if (s == nil) {
			return newList;
		}

		let r = (newList as! MalCollection).cdr();

		return try s!.apply(r);
	}

	func PRINT(_ s: MalType) throws -> Void {
		Printer.pr_str(s);
	}

	func rep(_ s: String, env: SEnv2) throws -> Void {
		try PRINT(EVAL(READ(s), env:env));
	}

	func runt(_ s: String) -> Void {
		let env : SEnv2 = [
			MalString("+") : MalClosure_Add(),
			MalString("-") : MalClosure_Sub(),
			MalString("*") : MalClosure_Mul(),
			MalString("/") : MalClosure_Div()
		];

		do {
			// list { sym("+")  1 2 }
			try rep(s, env:env);
		} catch (ReaderError.emptyLine) {
			// just a line with a comment
		} catch (ReaderError.badForm(let r)) {
			print("Bad form: \(r)");
		} catch (ReaderError.fatalError(let s)) {
			print("Fatal error; \(s)");
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
