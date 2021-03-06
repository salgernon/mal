import Foundation;

class SLisp3 {
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

	func eval_ast(_ ast:MalType, env:SEnv) throws -> MalType {
		if (isSymbolType(ast)) {
			let r = env.find(symbol:(ast as! MalSymbol));
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

	func EVAL(_ ast: MalType, env:SEnv) throws -> MalType {
		if (isCollectionType(ast) == false) {
			return try eval_ast(ast, env:env);
		}

		let asList = (ast as! MalCollection);
		if (asList.count() == 0) {
			return ast;
		}

		let firstElem = asList.car();
		if (isSymbolType(firstElem)) {
			let s = firstElem.toString();

			if (s.compare("def!") == ComparisonResult.orderedSame) {
				let defs = asList.cdr();
				let sym = (defs[0] as! MalSymbol);
				let val = try EVAL(defs[1], env:env);

				env.set(symbol: sym, value: val);

				return try EVAL(sym, env:env);
			}


			if (s.compare("let*") == ComparisonResult.orderedSame) {
				let nenv = SEnv(env);
				let kvs = (asList[1] as! MalCollection);

				let c = kvs.count();
				var i = 0;
				while (i < c) {
					let k = (kvs[i] as! MalSymbol);
					i += 1;
					let v = try EVAL(kvs[i], env:nenv);
					i += 1;
					nenv.set(symbol: k, value: v);
				}

				return try EVAL(asList[2], env:nenv);
			}
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

	func rep(_ s: String, env:SEnv) throws -> Void {
		try PRINT(EVAL(READ(s), env:env));
	}

	func runt(_ s: String, env:SEnv) -> Void {
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

		let env = SEnv(nil);

		env.set(symbol: MalString("+"), value: MalClosure_Add());
		env.set(symbol: MalString("-"), value: MalClosure_Sub());
		env.set(symbol: MalString("*"), value: MalClosure_Mul());
		env.set(symbol: MalString("/"), value: MalClosure_Div());

		while (running) {
			print("user> ", terminator:"");
			let s = readLine(strippingNewline:true);

			if (s == nil || s!.compare("quit") == ComparisonResult.orderedSame) {
				running = false;
			} else if (s!.compare("env?") == ComparisonResult.orderedSame) {
				print("Env: \(env)");
			} else {
				runt(s!, env:env);
			}
		}
	}
}
